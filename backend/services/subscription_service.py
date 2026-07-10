import datetime
from typing import Optional

from models import User


def grant_subscription(
    user: User,
    plan_type: str,
    source: str = "promo",
) -> None:
    """Activate or extend a subscription on a user account."""
    now = datetime.datetime.utcnow()

    if plan_type == "monthly":
        expires_at = now + datetime.timedelta(days=30)
    elif plan_type == "yearly":
        expires_at = now + datetime.timedelta(days=365)
    elif plan_type == "trial_7d":
        expires_at = now + datetime.timedelta(days=7)
    elif plan_type == "lifetime":
        expires_at = None
    else:
        raise ValueError(f"Unknown plan type: {plan_type}")

    user.has_paid = True
    user.subscription_source = source
    user.subscription_expires_at = expires_at


def revoke_subscription(user: User) -> None:
    user.has_paid = False
    user.subscription_source = None
    user.subscription_expires_at = None
