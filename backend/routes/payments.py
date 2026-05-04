from fastapi import APIRouter, Depends, HTTPException, Request, Header, status
from pydantic import BaseModel
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
                user = db.query(models.User).filter(models.User.id == client_reference_id).first()
                if user:
                    user.stripe_customer_id = customer_id
                    user.has_paid = True
                    db.commit()
                    logger.info(f"User {client_reference_id} subscribed via Stripe Checkout. Customer ID: {customer_id}")
                else:
                    logger.warning(f"Webhook checkout.session.completed: User {client_reference_id} not found.")
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

class CreateCheckoutSessionRequest(BaseModel):
    plan: str = "yearly"

@router.post("/create-checkout-session")
async def create_checkout_session(
    request: CreateCheckoutSessionRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        is_yearly = request.plan == "yearly"
        unit_amount = 1550 if is_yearly else 300
        interval = "year" if is_yearly else "month"
        
        checkout_session = stripe.checkout.Session.create(
            customer_email=current_user.email,
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'usd',
                        'product_data': {
                            'name': 'GojoCalories Premium',
                            'description': 'AI Nutrition Tracking & Analysis',
                        },
                        'unit_amount': unit_amount, 
                        'recurring': {'interval': interval},
                    },
                    'quantity': 1,
                },
            ],
            mode='subscription',
            subscription_data={
                'trial_period_days': 3,
            },
            success_url="https://gojocalories.com/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url="https://gojocalories.com/cancel",
            client_reference_id=current_user.id,
        )
        return {"url": checkout_session.url}
    except Exception as e:
        logger.error(f"Error creating Stripe checkout session: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

class CompleteCheckoutRequest(BaseModel):
    session_id: str

@router.post("/complete-checkout")
async def complete_checkout(
    request: CompleteCheckoutRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Retrieve the session with subscription and default_payment_method expanded
        session = stripe.checkout.Session.retrieve(
            request.session_id,
            expand=['subscription.default_payment_method', 'setup_intent.payment_method']
        )

        if session.client_reference_id != current_user.id:
            raise HTTPException(status_code=400, detail="Invalid session reference")
            
        if session.payment_status not in ['paid', 'no_payment_required'] and session.status != 'complete':
            raise HTTPException(status_code=400, detail="Payment not completed")

        fingerprint = None
        payment_method = None

        if session.subscription and getattr(session.subscription, 'default_payment_method', None):
            payment_method = session.subscription.default_payment_method
        elif session.setup_intent and getattr(session.setup_intent, 'payment_method', None):
            payment_method = session.setup_intent.payment_method

        if payment_method and hasattr(payment_method, 'card') and payment_method.card:
            fingerprint = payment_method.card.fingerprint

        if fingerprint:
            existing_trial = db.query(models.TrialFingerprint).filter(
                models.TrialFingerprint.fingerprint == fingerprint,
                models.TrialFingerprint.user_id != current_user.id
            ).first()

            if existing_trial:
                # Cancel the subscription immediately
                if session.subscription:
                    sub_id = session.subscription if isinstance(session.subscription, str) else session.subscription.id
                    stripe.Subscription.cancel(sub_id)
                raise HTTPException(
                    status_code=400, 
                    detail="This card has already been used for a free trial on another account."
                )

            # Record fingerprint if not exists for this user
            user_trial = db.query(models.TrialFingerprint).filter(
                models.TrialFingerprint.fingerprint == fingerprint,
                models.TrialFingerprint.user_id == current_user.id
            ).first()
            
            if not user_trial:
                new_trial = models.TrialFingerprint(
                    fingerprint=fingerprint,
                    user_id=current_user.id
                )
                db.add(new_trial)

        # Update user status
        current_user.has_paid = True
        
        # We might also want to set stripe_customer_id if it's not set
        if session.customer and not current_user.stripe_customer_id:
            current_user.stripe_customer_id = session.customer if isinstance(session.customer, str) else session.customer.id
            
        db.commit()

        return {"status": "success", "trialActive": True}

    except stripe.StripeError as e:
        logger.error(f"Stripe Error in complete-checkout: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing checkout session: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")
