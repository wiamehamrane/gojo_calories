from fastapi import APIRouter, Depends, HTTPException, Request, Header, status
from sqlalchemy.orm import Session
from database import get_db
import models
from security import get_current_user
import logging
import os
import stripe

logger = logging.getLogger(__name__)
router = APIRouter()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/webhook")
async def stripe_webhook(request: Request, stripe_signature: str = Header(None), db: Session = Depends(get_db)):
    if not stripe_signature:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing Stripe signature")

    payload = await request.body()

    try:
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, STRIPE_WEBHOOK_SECRET
        )
    except ValueError as e:
        logger.error(f"Invalid payload: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid payload")
    except stripe.SignatureVerificationError as e:
        logger.error(f"Invalid signature: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid signature")

    event_type = event['type']
    data_object = event['data']['object']

    try:
        if event_type == 'checkout.session.completed':
            # Extract user ID passed via client_reference_id in the Payment Link
            client_reference_id = data_object.get('client_reference_id')
            customer_id = data_object.get('customer')
            
            if client_reference_id:
                try:
                    user_id = int(client_reference_id)
                    user = db.query(models.User).filter(models.User.id == user_id).first()
                    if user:
                        user.stripe_customer_id = customer_id
                        user.has_paid = True
                        db.commit()
                        logger.info(f"User {user_id} subscribed via Stripe Checkout. Customer ID: {customer_id}")
                    else:
                        logger.warning(f"Webhook checkout.session.completed: User {user_id} not found.")
                except ValueError:
                    logger.warning(f"Webhook checkout.session.completed: Invalid client_reference_id {client_reference_id}")
            else:
                logger.warning("Webhook checkout.session.completed: Missing client_reference_id")

        elif event_type in ['customer.subscription.updated', 'customer.subscription.deleted']:
            customer_id = data_object.get('customer')
            status_val = data_object.get('status')
            
            if customer_id:
                user = db.query(models.User).filter(models.User.stripe_customer_id == customer_id).first()
                if user:
                    # active, trialing = paid. incomplete, incomplete_expired, past_due, canceled, unpaid = unpaid
                    is_active = status_val in ['active', 'trialing']
                    if user.has_paid != is_active:
                        user.has_paid = is_active
                        db.commit()
                        logger.info(f"User {user.id} subscription status updated to {is_active} (Stripe status: {status_val})")
                else:
                    logger.warning(f"Webhook {event_type}: No user found for stripe_customer_id {customer_id}")

        return {"status": "success"}

    except Exception as e:
        logger.error(f"Stripe Webhook Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal webhook error")


@router.post("/create-portal-session")
async def create_portal_session(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.stripe_customer_id:
        # If the user doesn't have a Stripe customer ID, they haven't checked out yet.
        # So we cannot open the portal.
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No active Stripe customer found.")
        
    try:
        session = stripe.billing_portal.Session.create(
            customer=current_user.stripe_customer_id,
            # We assume the app is hosted somewhere, or we can use the main site URL
            return_url="https://gojocalories.com" 
        )
        return {"url": session.url}
    except Exception as e:
        logger.error(f"Error creating Stripe portal session: {str(e)}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

