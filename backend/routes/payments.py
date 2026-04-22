from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from database import get_db
import models
from security import get_current_user_id
import stripe
import os
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
ENDPOINT_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/create-checkout-session")
def create_checkout_session(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    try:
        if not user.stripe_customer_id:
            customer = stripe.Customer.create(
                email=user.email,
                metadata={'user_id': user.id}
            )
            user.stripe_customer_id = customer.id
            db.commit()
            
        ephemeral_key = stripe.EphemeralKey.create(
            customer=user.stripe_customer_id,
            stripe_version='2024-06-20',
        )

        price_id = os.getenv("STRIPE_PRICE_ID", "price_1TNI87GkYdm9mdqzKlsMmOqt")
        
        # Create Subscription first with default_incomplete
        subscription = stripe.Subscription.create(
            customer=user.stripe_customer_id,
            items=[{'price': price_id}],
            trial_period_days=3,
            payment_behavior='default_incomplete',
            expand=['pending_setup_intent'],
            metadata={'user_id': str(user.id)}
        )

        setup_intent_secret = None
        if subscription.pending_setup_intent:
            setup_intent_secret = subscription.pending_setup_intent.client_secret

        if not setup_intent_secret:
            raise HTTPException(status_code=400, detail="Failed to initialize setup intent for trial")

        return {
            "setupIntent": setup_intent_secret,
            "ephemeralKey": ephemeral_key.secret,
            "customer": user.stripe_customer_id,
            "publishableKey": os.getenv("STRIPE_PUBLISHABLE_KEY"),
            "subscriptionId": subscription.id
        }

    except Exception as e:
        logger.error(f"Stripe Create Checkout Session Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/confirm-setup")
def confirm_setup(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    try:
        price_id = os.getenv("STRIPE_PRICE_ID", "price_1TNI87GkYdm9mdqzKlsMmOqt")

        # --- Idempotency guard: skip if subscription already exists ---
        if user.stripe_customer_id:
            existing_subs = stripe.Subscription.list(customer=user.stripe_customer_id, limit=1)
            if existing_subs.data:
                existing_status = existing_subs.data[0].get("status")
                if existing_status in ["trialing", "active"]:
                    logger.info(f"User {user.email} already has a {existing_status} subscription — skipping creation.")
                    if not user.has_paid:
                        user.has_paid = True
                        db.commit()
                    return {"status": "success", "message": "Subscription already active."}

        subscriptions = stripe.Subscription.list(customer=user.stripe_customer_id, status="all", limit=5)
        active_sub = next((sub for sub in subscriptions.data if sub.status in ['trialing', 'active']), None)

        if not active_sub:
            raise HTTPException(status_code=400, detail="Subscription is not active yet. Please try again or check your payment method.")

        if not user.has_paid:
            user.has_paid = True
            db.commit()

        logger.info(f"User {user.email} trial subscription verified via confirm-setup.")
        return {"status": "success", "message": "Free trial started!"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Confirm Setup Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, ENDPOINT_SECRET)
    except ValueError as e:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.SignatureVerificationError as e:
        raise HTTPException(status_code=400, detail="Invalid signature")

    if event['type'] == 'setup_intent.succeeded':
        setup_intent = event['data']['object']
        customer_id = setup_intent.get('customer')
        payment_method_id = setup_intent.get('payment_method')
        metadata = setup_intent.get('metadata', {})
        price_id = metadata.get('price_id', os.getenv("STRIPE_PRICE_ID", "price_1TNI87GkYdm9mdqzKlsMmOqt"))

        if customer_id and payment_method_id:
            try:
                stripe.PaymentMethod.attach(payment_method_id, customer=customer_id)
                stripe.Customer.modify(customer_id, invoice_settings={'default_payment_method': payment_method_id})

                stripe.Subscription.create(
                    customer=customer_id,
                    items=[{'price': price_id}],
                    trial_period_days=3,
                    default_payment_method=payment_method_id,
                    metadata=metadata,
                )

                user = db.query(models.User).filter(models.User.stripe_customer_id == customer_id).first()
                if user and not user.has_paid:
                    user.has_paid = True
                    db.commit()
                    logger.info(f"User {user.email} started free trial.")
            except Exception as e:
                logger.error(f"Error creating subscription after SetupIntent: {e}", exc_info=True)

    elif event['type'] in ['customer.subscription.created', 'customer.subscription.updated']:
        subscription = event['data']['object']
        customer_id = subscription.get('customer')
        status = subscription.get('status')
        if status in ['trialing', 'active'] and customer_id:
            user = db.query(models.User).filter(models.User.stripe_customer_id == customer_id).first()
            if user and not user.has_paid:
                user.has_paid = True
                db.commit()
                logger.info(f"User {user.email} subscription is {status}.")
        elif status in ['canceled', 'unpaid', 'past_due'] and customer_id:
            user = db.query(models.User).filter(models.User.stripe_customer_id == customer_id).first()
            if user:
                user.has_paid = False
                db.commit()
                logger.info(f"User {user.email} subscription {status} — paywall re-enabled.")

    elif event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        customer_id = payment_intent.get('customer')
        if customer_id:
            user = db.query(models.User).filter(models.User.stripe_customer_id == customer_id).first()
            if user:
                user.has_paid = True
                db.commit()

    return {"status": "success"}

@router.get("/subscription")
def get_subscription(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    """Return current subscription status from Stripe."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not user.stripe_customer_id:
        return {"status": "none", "has_subscription": False}

    try:
        subscriptions = stripe.Subscription.list(customer=user.stripe_customer_id, limit=1)
        if not subscriptions.data:
            return {"status": "none", "has_subscription": False}

        sub = subscriptions.data[0]
        current_period_end = sub.get("current_period_end")
        next_billing = None
        if current_period_end:
            import datetime as dt
            next_billing = dt.datetime.utcfromtimestamp(current_period_end).strftime("%B %d, %Y")

        plan_name = "GojoCalories Pro"
        if sub.get("items") and sub["items"]["data"]:
            price = sub["items"]["data"][0].get("price", {})
            if price.get("nickname"):
                plan_name = price["nickname"]

        return {
            "has_subscription": True,
            "status": sub.get("status", "unknown"),
            "plan_name": plan_name,
            "next_billing_date": next_billing,
            "cancel_at_period_end": sub.get("cancel_at_period_end", False),
            "subscription_id": sub.get("id"),
        }
    except Exception as e:
        logger.error(f"Get subscription error: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/cancel-subscription")
def cancel_subscription(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    """Cancel subscription at period end."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user or not user.stripe_customer_id:
        raise HTTPException(status_code=404, detail="No subscription found")

    try:
        subscriptions = stripe.Subscription.list(customer=user.stripe_customer_id, status="active", limit=1)
        if not subscriptions.data:
            subscriptions = stripe.Subscription.list(customer=user.stripe_customer_id, status="trialing", limit=1)
        if not subscriptions.data:
            raise HTTPException(status_code=404, detail="No active subscription found")

        stripe.Subscription.modify(subscriptions.data[0].id, cancel_at_period_end=True)
        return {"status": "success", "message": "Subscription will be cancelled at period end"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Cancel subscription error: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/create-portal-session")
def create_portal_session(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    """Create a Stripe Customer Portal session URL."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user or not user.stripe_customer_id:
        raise HTTPException(status_code=404, detail="No billing account found")

    try:
        session = stripe.billing_portal.Session.create(
            customer=user.stripe_customer_id,
            return_url="https://gojocalories.app",
        )
        return {"url": session.url}
    except Exception as e:
        logger.error(f"Portal session error: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))
