"""
Google Play In-App Purchase verification and Real-Time Developer Notifications.

Endpoints:
  POST /verify-purchase  — Validate a purchase token from the Android app
  POST /webhook           — Handle Google Play RTDN (Pub/Sub push format)
"""

import base64
import datetime
import json
import logging
import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
import models
from security import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter()

PACKAGE_NAME = os.getenv("GOOGLE_PLAY_PACKAGE_NAME", "com.gojocalories.gojocalories")
GOOGLE_PLAY_SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

VALID_PRODUCT_IDS = {
    "gojo_pro_monthly",
    "gojo_pro_yearly",
}

# Canceled subscriptions remain active until expiry.
ACTIVE_SUBSCRIPTION_STATES = {
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_CANCELED",
    "SUBSCRIPTION_STATE_ON_HOLD",
}


class VerifyPurchaseRequest(BaseModel):
    purchase_token: str
    product_id: str


class GooglePurchaseResponse(BaseModel):
    status: str
    subscription_active: bool
    expires_at: Optional[str] = None
    product_id: Optional[str] = None


def _get_android_publisher_service():
    """Build Google Play Developer API client from service account credentials."""
    creds_json = os.getenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "")
    if not creds_json:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Play billing is not configured on the server",
        )
    try:
        info = json.loads(creds_json)
    except json.JSONDecodeError as exc:
        logger.error("Invalid GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Play billing configuration is invalid",
        ) from exc

    credentials = service_account.Credentials.from_service_account_info(
        info,
        scopes=GOOGLE_PLAY_SCOPES,
    )
    return build(
        "androidpublisher",
        "v3",
        credentials=credentials,
        cache_discovery=False,
    )


def _verify_purchase_token(purchase_token: str, product_id: str) -> dict:
    """Fetch subscription state from Google Play."""
    if product_id not in VALID_PRODUCT_IDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid product ID",
        )

    service = _get_android_publisher_service()
    try:
        return (
            service.purchases()
            .subscriptionsv2()
            .get(packageName=PACKAGE_NAME, token=purchase_token)
            .execute()
        )
    except HttpError as exc:
        logger.warning(f"Google Play API error: {exc}")
        if exc.resp.status == 404:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Purchase not found or invalid",
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to verify purchase with Google Play",
        ) from exc


def _parse_subscription(
    subscription: dict,
    product_id: str,
) -> tuple[bool, datetime.datetime, str, str]:
    """Return (is_active, expires_at, order_id, resolved_product_id)."""
    state = subscription.get("subscriptionState", "")
    line_items = subscription.get("lineItems") or []
    if not line_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid subscription found in purchase",
        )

    line_item = next(
        (item for item in line_items if item.get("productId") == product_id),
        line_items[0],
    )

    resolved_product_id = line_item.get("productId", product_id)
    if resolved_product_id not in VALID_PRODUCT_IDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid subscription found in purchase",
        )

    expiry_raw = line_item.get("expiryTime")
    if not expiry_raw:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid subscription found in purchase",
        )

    expires_at = datetime.datetime.fromisoformat(
        expiry_raw.replace("Z", "+00:00"),
    ).replace(tzinfo=None)
    now = datetime.datetime.utcnow()
    is_active = state in ACTIVE_SUBSCRIPTION_STATES and expires_at > now
    if state == "SUBSCRIPTION_STATE_EXPIRED":
        is_active = False

    order_id = (
        subscription.get("latestOrderId")
        or line_item.get("latestSuccessfulOrderId")
        or ""
    )
    if not order_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid subscription found in purchase",
        )

    return is_active, expires_at, order_id, resolved_product_id


def _unlock_subscription_for_user(
    *,
    db: Session,
    current_user: models.User,
    order_id: str,
    purchase_token: str,
    product_id: str,
    expires_at: datetime.datetime,
    is_active: bool,
) -> dict:
    """Persist subscription state after Google Play validation."""
    existing_user = db.query(models.User).filter(
        models.User.google_order_id == order_id,
        models.User.id != current_user.id,
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This subscription is already associated with another account.",
        )

    current_user.has_paid = is_active
    current_user.subscription_source = "google"
    current_user.google_order_id = order_id
    current_user.google_purchase_token = purchase_token
    current_user.subscription_expires_at = expires_at
    db.commit()

    logger.info(
        f"Google subscription verified for user {current_user.id}: "
        f"product={product_id}, active={is_active}, expires={expires_at.isoformat()}"
    )

    return {
        "status": "success",
        "subscription_active": is_active,
        "expires_at": expires_at.isoformat(),
        "product_id": product_id,
    }


@router.post("/verify-purchase")
async def verify_purchase(
    request: VerifyPurchaseRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Validate a Google Play purchase token and unlock premium access.

    Flow:
    1. Call Google Play subscriptionsv2.get with the purchase token
    2. Parse subscription state and expiry
    3. Update user's payment status and subscription metadata
    """
    if not request.purchase_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing purchase token",
        )

    try:
        subscription = _verify_purchase_token(
            request.purchase_token,
            request.product_id,
        )
        is_active, expires_at, order_id, product_id = _parse_subscription(
            subscription,
            request.product_id,
        )
        return _unlock_subscription_for_user(
            db=db,
            current_user=current_user,
            order_id=order_id,
            purchase_token=request.purchase_token,
            product_id=product_id,
            expires_at=expires_at,
            is_active=is_active,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Google purchase verification error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify Google Play purchase",
        ) from e


def _apply_subscription_update(
    db: Session,
    purchase_token: str,
    product_id: str,
    notification_type: Optional[int] = None,
) -> None:
    """Re-verify a subscription from an RTDN event and update the user."""
    subscription = _verify_purchase_token(purchase_token, product_id)
    is_active, expires_at, order_id, resolved_product_id = _parse_subscription(
        subscription,
        product_id,
    )

    user = db.query(models.User).filter(
        (models.User.google_order_id == order_id)
        | (models.User.google_purchase_token == purchase_token)
    ).first()

    if not user:
        logger.warning(
            f"Google RTDN: No user found for order_id={order_id} "
            f"notification_type={notification_type}"
        )
        return

    # Revoked / expired notifications should deactivate immediately.
    if notification_type in (12, 13):  # REVOKED, EXPIRED
        is_active = False

    user.has_paid = is_active
    user.subscription_source = "google"
    user.google_order_id = order_id
    user.google_purchase_token = purchase_token
    user.subscription_expires_at = expires_at
    db.commit()

    logger.info(
        f"Google RTDN updated user {user.id}: active={is_active}, "
        f"product={resolved_product_id}, type={notification_type}"
    )


@router.post("/webhook")
async def google_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Handle Google Play Real-Time Developer Notifications (Pub/Sub push).

    Configure a Pub/Sub push subscription pointing to this endpoint.
    """
    try:
        body = await request.json()
        message = body.get("message", {})
        data_b64 = message.get("data", "")

        if not data_b64:
            return {"status": "ok", "detail": "no data"}

        padding = 4 - len(data_b64) % 4
        if padding != 4:
            data_b64 += "=" * padding

        notification = json.loads(base64.b64decode(data_b64))
        package_name = notification.get("packageName", PACKAGE_NAME)
        if package_name != PACKAGE_NAME:
            logger.warning(f"Google RTDN for unexpected package: {package_name}")
            return {"status": "ignored"}

        sub_notification = notification.get("subscriptionNotification")
        if not sub_notification:
            logger.info("Google RTDN: non-subscription notification ignored")
            return {"status": "ok"}

        purchase_token = sub_notification.get("purchaseToken", "")
        product_id = sub_notification.get("subscriptionId", "")
        notification_type = sub_notification.get("notificationType")

        if not purchase_token or not product_id:
            return {"status": "ok", "detail": "missing subscription fields"}

        _apply_subscription_update(
            db,
            purchase_token,
            product_id,
            notification_type,
        )
        return {"status": "ok"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Google webhook processing error: {str(e)}", exc_info=True)
        # Return 200 so Pub/Sub does not retry indefinitely on parse errors.
        return {"status": "error", "detail": str(e)}
