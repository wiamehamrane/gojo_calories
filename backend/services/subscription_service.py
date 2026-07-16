import datetime
from typing import Optional

from models import User


def expires_at_for_plan(plan_type: str, from_time: Optional[datetime.datetime] = None) -> Optional[datetime.datetime]:
    """Return expiry datetime for a plan type. Lifetime returns None."""
    now = from_time or datetime.datetime.utcnow()

    if plan_type == "monthly":
        return now + datetime.timedelta(days=30)
    if plan_type == "six_month":
        return now + datetime.timedelta(days=182)
    if plan_type == "yearly":
        return now + datetime.timedelta(days=365)
    if plan_type == "trial_7d":
        return now + datetime.timedelta(days=7)
    if plan_type == "lifetime":
        return None
    raise ValueError(f"Unknown plan type: {plan_type}")


def grant_subscription(
    user: User,
    plan_type: str,
    source: str = "admin_grant",
) -> None:
    """Activate or extend a subscription on a user account."""
    user.has_paid = True
    user.subscription_source = source
    user.subscription_plan = plan_type
    user.subscription_expires_at = expires_at_for_plan(plan_type)


def sync_subscription_expiry(user: User, expires_at: Optional[datetime.datetime]) -> None:
    user.subscription_expires_at = expires_at


def revoke_subscription(user: User) -> None:
    user.has_paid = False
    user.subscription_source = None
    user.subscription_plan = None
    user.subscription_expires_at = None
    user.clan_id = None


def apply_referral_iap_credit(
    user: User,
    plan_type: str,
    *,
    pay_percent: int,
    duration_periods: int,
) -> None:
    """
    For IAP purchases where the store charges full price, extend access to
    approximate the referral discount (pay X% for N periods).
    """
    if user.referral_discount_used:
        return

    base_expires = user.subscription_expires_at or expires_at_for_plan(plan_type)
    if base_expires is None:
        return

    # Extra days ≈ (100 - pay_percent) / pay_percent × N periods
    if plan_type == "monthly":
        period_days = 30
    elif plan_type == "six_month":
        period_days = 182
    elif plan_type == "yearly":
        period_days = 365
    else:
        return

    discount_fraction = max(0, 100 - pay_percent) / max(pay_percent, 1)
    bonus_days = int(round(period_days * duration_periods * discount_fraction))
    user.subscription_expires_at = base_expires + datetime.timedelta(days=bonus_days)
    user.referral_discount_used = True
