"""
Apple In-App Purchase receipt validation and Server-to-Server notification handling.

Endpoints:
  POST /verify-receipt  — Validate a receipt from the iOS app and unlock premium
  POST /webhook         — Handle Apple S2S notifications (renewal, expiry, refund)
"""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
import models
from security import get_current_user
import logging
import os
import httpx
import datetime
import json
import base64

logger = logging.getLogger(__name__)
router = APIRouter()

# Apple verification endpoints
APPLE_PRODUCTION_VERIFY_URL = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_SANDBOX_VERIFY_URL = "https://sandbox.itunes.apple.com/verifyReceipt"

# Shared secret from App Store Connect (In-App Purchase → Shared Secret)
APPLE_SHARED_SECRET = os.getenv("APPLE_SHARED_SECRET", "")

# Our product identifiers
VALID_PRODUCT_IDS = {
    "gojo_pro_monthly",
    "gojo_pro_yearly",
}


class VerifyReceiptRequest(BaseModel):
    receipt_data: str  # Base64-encoded receipt from StoreKit
    product_id: str | None = None


class AppleReceiptResponse(BaseModel):
    status: str
    subscription_active: bool
    expires_at: str | None = None
    product_id: str | None = None


async def _verify_with_apple(receipt_data: str, use_sandbox: bool = False) -> dict:
    """Send receipt to Apple for verification."""
    url = APPLE_SANDBOX_VERIFY_URL if use_sandbox else APPLE_PRODUCTION_VERIFY_URL
    payload = {
        "receipt-data": receipt_data,
        "password": APPLE_SHARED_SECRET,
        "exclude-old-transactions": True,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload)
        response.raise_for_status()
        return response.json()


def _extract_latest_subscription(receipt_response: dict) -> dict | None:
    """
    Extract the latest active subscription info from Apple's receipt response.
    Returns the most recent transaction for our subscription products.
    """
    latest_receipt_info = receipt_response.get("latest_receipt_info", [])
    if not latest_receipt_info:
        # Fallback to in_app for non-renewable
        latest_receipt_info = (
            receipt_response.get("receipt", {}).get("in_app", [])
        )

    # Filter to our known product IDs and sort by expires_date_ms descending
    our_subs = [
        txn for txn in latest_receipt_info
        if txn.get("product_id") in VALID_PRODUCT_IDS
    ]

    if not our_subs:
        return None

    # Sort by expiration date, most recent first
    our_subs.sort(
        key=lambda x: int(x.get("expires_date_ms", "0")),
        reverse=True,
    )

    return our_subs[0]


@router.post("/verify-receipt")
async def verify_receipt(
    request: VerifyReceiptRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Validate an Apple IAP receipt and unlock premium access.

    Flow:
    1. Send receipt to Apple production endpoint
    2. If Apple returns status 21007, retry against sandbox (for testing)
    3. Extract latest subscription transaction
    4. Check if subscription is active (not expired)
    5. Update user's payment status and subscription metadata
    """
    if not request.receipt_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing receipt data",
        )

    try:
        # Step 1: Verify with Apple production
        result = await _verify_with_apple(request.receipt_data, use_sandbox=False)

        # Step 2: If status 21007, receipt is from sandbox — retry
        if result.get("status") == 21007:
            logger.info("Receipt is sandbox, retrying with sandbox endpoint")
            result = await _verify_with_apple(request.receipt_data, use_sandbox=True)

        apple_status = result.get("status", -1)
        if apple_status != 0:
            logger.warning(f"Apple receipt verification failed with status {apple_status}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Apple receipt verification failed (status: {apple_status})",
            )

        # Step 3: Extract latest subscription
        latest_sub = _extract_latest_subscription(result)
        if not latest_sub:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid subscription found in receipt",
            )

        # Step 4: Check expiration
        expires_date_ms = int(latest_sub.get("expires_date_ms", "0"))
        expires_at = datetime.datetime.utcfromtimestamp(expires_date_ms / 1000)
        now = datetime.datetime.utcnow()
        is_active = expires_at > now

        original_transaction_id = latest_sub.get("original_transaction_id", "")
        product_id = latest_sub.get("product_id", "")

        # Step 5: Check if another user already owns this transaction
        existing_user = db.query(models.User).filter(
            models.User.apple_original_transaction_id == original_transaction_id,
            models.User.id != current_user.id,
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This subscription is already associated with another account.",
            )

        # Step 6: Update user
        current_user.has_paid = is_active
        current_user.subscription_source = "apple"
        current_user.apple_original_transaction_id = original_transaction_id
        current_user.subscription_expires_at = expires_at
        db.commit()

        logger.info(
            f"Apple receipt verified for user {current_user.id}: "
            f"product={product_id}, active={is_active}, expires={expires_at.isoformat()}"
        )

        return {
            "status": "success",
            "subscription_active": is_active,
            "expires_at": expires_at.isoformat(),
            "product_id": product_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Apple receipt verification error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify Apple receipt",
        )


@router.post("/webhook")
async def apple_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Handle Apple Server-to-Server Notifications (v2).

    Apple sends JWS-signed notifications for subscription lifecycle events:
    - DID_RENEW: Subscription renewed successfully
    - EXPIRED: Subscription expired
    - DID_CHANGE_RENEWAL_STATUS: User turned off auto-renew
    - REFUND: Apple issued a refund
    - REVOKE: Family sharing revoked

    For simplicity, we decode the signed payload and process the event.
    In production, you should verify the JWS signature against Apple's certificate.
    """
    try:
        body = await request.json()
        signed_payload = body.get("signedPayload", "")

        if not signed_payload:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing signedPayload",
            )

        # Decode the JWS payload (header.payload.signature)
        # In production, verify the signature using Apple's root certificate
        parts = signed_payload.split(".")
        if len(parts) != 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid JWS format",
            )

        # Decode the payload (second part), adding padding if needed
        payload_b64 = parts[1]
        padding = 4 - len(payload_b64) % 4
        if padding != 4:
            payload_b64 += "=" * padding
        payload_json = base64.urlsafe_b64decode(payload_b64)
        notification = json.loads(payload_json)

        notification_type = notification.get("notificationType", "")
        subtype = notification.get("subtype", "")

        logger.info(f"Apple S2S notification: type={notification_type}, subtype={subtype}")

        # Extract transaction info from the signed notification
        signed_transaction_info = notification.get("data", {}).get("signedTransactionInfo", "")
        if signed_transaction_info:
            # Decode the inner JWS for transaction info
            txn_parts = signed_transaction_info.split(".")
            if len(txn_parts) == 3:
                txn_b64 = txn_parts[1]
                txn_padding = 4 - len(txn_b64) % 4
                if txn_padding != 4:
                    txn_b64 += "=" * txn_padding
                txn_json = base64.urlsafe_b64decode(txn_b64)
                txn_info = json.loads(txn_json)

                original_transaction_id = txn_info.get("originalTransactionId", "")
                product_id = txn_info.get("productId", "")
                expires_date_ms = txn_info.get("expiresDate", 0)

                if original_transaction_id:
                    user = db.query(models.User).filter(
                        models.User.apple_original_transaction_id == original_transaction_id
                    ).first()

                    if user:
                        if notification_type in ("DID_RENEW", "SUBSCRIBED", "DID_CHANGE_RENEWAL_STATUS"):
                            if notification_type == "DID_RENEW" or subtype == "AUTO_RENEW_ENABLED":
                                user.has_paid = True
                                if expires_date_ms:
                                    user.subscription_expires_at = datetime.datetime.utcfromtimestamp(
                                        expires_date_ms / 1000
                                    )
                                logger.info(f"Apple subscription renewed for user {user.id}")

                        elif notification_type in ("EXPIRED", "REVOKE"):
                            user.has_paid = False
                            logger.info(f"Apple subscription expired/revoked for user {user.id}")

                        elif notification_type == "REFUND":
                            user.has_paid = False
                            logger.info(f"Apple subscription refunded for user {user.id}")

                        elif notification_type == "DID_CHANGE_RENEWAL_STATUS" and subtype == "AUTO_RENEW_DISABLED":
                            # User turned off auto-renew — still active until expiry
                            logger.info(f"Apple auto-renew disabled for user {user.id} (still active until expiry)")

                        db.commit()
                    else:
                        logger.warning(
                            f"Apple webhook: No user found for original_transaction_id={original_transaction_id}"
                        )

        return {"status": "ok"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Apple webhook processing error: {str(e)}", exc_info=True)
        # Return 200 to Apple to prevent retries for parse errors
        return {"status": "error", "detail": str(e)}
