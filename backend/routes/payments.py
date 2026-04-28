from fastapi import APIRouter, Depends, HTTPException, Request, Header
from sqlalchemy.orm import Session
from database import get_db
import models
import logging
import os

logger = logging.getLogger(__name__)
router = APIRouter()

# Optional: Add a webhook authorization header check
REVENUECAT_WEBHOOK_AUTH_TOKEN = os.getenv("REVENUECAT_WEBHOOK_AUTH_TOKEN")

@router.post("/revenuecat-webhook")
async def revenuecat_webhook(
    request: Request,
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    # If an auth token is set in the environment, verify it
    if REVENUECAT_WEBHOOK_AUTH_TOKEN and authorization != REVENUECAT_WEBHOOK_AUTH_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized webhook")

    try:
        payload = await request.json()
        event = payload.get("event", {})
        event_type = event.get("type")
        app_user_id = event.get("app_user_id")

        if not app_user_id or not event_type:
            return {"status": "ignored", "reason": "Missing required fields"}

        # Try to parse the user_id (it should be the integer ID we passed via Purchases.logIn)
        try:
            user_id = int(app_user_id)
        except ValueError:
            logger.warning(f"RevenueCat webhook received non-integer app_user_id: {app_user_id}")
            return {"status": "ignored", "reason": "Invalid app_user_id format"}

        user = db.query(models.User).filter(models.User.id == user_id).first()
        if not user:
            logger.warning(f"RevenueCat webhook user not found: {user_id}")
            return {"status": "ignored", "reason": "User not found"}

        # RevenueCat Event Types that grant/revoke access
        # INITIAL_PURCHASE, RENEWAL, NON_RENEWING_PURCHASE, UNCANCELLATION
        # EXPIRATION, TRANSFER, BILLING_ISSUE, SUBSCRIPTION_PAUSED
        
        # We check expiration in case it's a cancellation that has now expired
        if event_type in ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "NON_RENEWING_PURCHASE"]:
            if not user.has_paid:
                user.has_paid = True
                db.commit()
                logger.info(f"User {user_id} subscription granted via RevenueCat {event_type}.")
        
        elif event_type in ["EXPIRATION", "BILLING_ISSUE", "SUBSCRIPTION_PAUSED", "TRANSFER"]:
            if user.has_paid:
                user.has_paid = False
                db.commit()
                logger.info(f"User {user_id} subscription revoked via RevenueCat {event_type}.")

        return {"status": "success"}

    except Exception as e:
        logger.error(f"RevenueCat Webhook Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

