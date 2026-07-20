"""
Server-driven subscription catalog.

Prices and copy are configured via environment variables so the mobile app
never hardcodes plan amounts. Store product IDs must match App Store Connect
and Google Play Console.
"""

import os
from typing import Any, Optional


def _int_env(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or raw.strip() == "":
        return default
    return int(raw)


def _float_env(name: str, default: float) -> float:
    raw = os.getenv(name)
    if raw is None or raw.strip() == "":
        return default
    return float(raw)


# ── Plan definitions (cents) ────────────────────────────────────────────────

PLAN_MONTHLY_CENTS = _int_env("PLAN_MONTHLY_CENTS", 599)
PLAN_SIX_MONTH_CENTS = _int_env("PLAN_SIX_MONTH_CENTS", 1499)
PLAN_YEARLY_CENTS = _int_env("PLAN_YEARLY_CENTS", 1999)

CLAN_ADDON_MONTHLY_CENTS = _int_env("CLAN_ADDON_MONTHLY_CENTS", 199)
CLAN_ADDON_SIX_MONTH_CENTS = _int_env("CLAN_ADDON_SIX_MONTH_CENTS", 399)
CLAN_ADDON_YEARLY_CENTS = _int_env("CLAN_ADDON_YEARLY_CENTS", 699)

COACH_MONTHLY_CENTS = _int_env("COACH_MONTHLY_CENTS", 500)  # $5.00
# Yearly = 12 × monthly with 20% off → $48.00
COACH_YEARLY_CENTS = _int_env("COACH_YEARLY_CENTS", 4800)

CLAN_MAX_MEMBERS = _int_env("CLAN_MAX_MEMBERS", 5)

REFERRAL_PAY_PERCENT = _int_env("REFERRAL_PAY_PERCENT", 60)
REFERRAL_DURATION_PERIODS = _int_env("REFERRAL_DURATION_PERIODS", 2)

# Stripe Price IDs (create in Stripe Dashboard → Products)
STRIPE_PRICE_MONTHLY = os.getenv("STRIPE_PRICE_MONTHLY", "")
STRIPE_PRICE_SIX_MONTH = os.getenv("STRIPE_PRICE_SIX_MONTH", "")
STRIPE_PRICE_YEARLY = os.getenv("STRIPE_PRICE_YEARLY", "")
STRIPE_PRICE_CLAN_ADDON_MONTHLY = os.getenv("STRIPE_PRICE_CLAN_ADDON_MONTHLY", "")
STRIPE_PRICE_CLAN_ADDON_SIX_MONTH = os.getenv("STRIPE_PRICE_CLAN_ADDON_SIX_MONTH", "")
STRIPE_PRICE_CLAN_ADDON_YEARLY = os.getenv("STRIPE_PRICE_CLAN_ADDON_YEARLY", "")

STRIPE_REFERRAL_COUPON_ID = os.getenv("STRIPE_REFERRAL_COUPON_ID", "")

# Store product IDs
PRODUCT_MONTHLY = "gojo_pro_monthly"
PRODUCT_SIX_MONTH = "gojo_pro_six_month"
PRODUCT_YEARLY = "gojo_pro_yearly"
PRODUCT_CLAN_ADDON_MONTHLY = "gojo_clan_addon_monthly"
PRODUCT_CLAN_ADDON_SIX_MONTH = "gojo_clan_addon_six_month"
PRODUCT_CLAN_ADDON_YEARLY = "gojo_clan_addon_yearly"
PRODUCT_COACH_MONTHLY = "gojo_coach_monthly"
PRODUCT_COACH_YEARLY = "gojo_coach_yearly"

ALL_PRODUCT_IDS = {
    PRODUCT_MONTHLY,
    PRODUCT_SIX_MONTH,
    PRODUCT_YEARLY,
    PRODUCT_CLAN_ADDON_MONTHLY,
    PRODUCT_CLAN_ADDON_SIX_MONTH,
    PRODUCT_CLAN_ADDON_YEARLY,
    PRODUCT_COACH_MONTHLY,
    PRODUCT_COACH_YEARLY,
}

BASE_PRODUCT_IDS = {
    PRODUCT_MONTHLY,
    PRODUCT_SIX_MONTH,
    PRODUCT_YEARLY,
}

CLAN_ADDON_PRODUCT_IDS = {
    PRODUCT_CLAN_ADDON_MONTHLY,
    PRODUCT_CLAN_ADDON_SIX_MONTH,
    PRODUCT_CLAN_ADDON_YEARLY,
}

COACH_PRODUCT_IDS = {
    PRODUCT_COACH_MONTHLY,
    PRODUCT_COACH_YEARLY,
}

PLAN_BY_PRODUCT = {
    PRODUCT_MONTHLY: "monthly",
    PRODUCT_SIX_MONTH: "six_month",
    PRODUCT_YEARLY: "yearly",
}

COACH_PLAN_BY_PRODUCT = {
    PRODUCT_COACH_MONTHLY: "monthly",
    PRODUCT_COACH_YEARLY: "yearly",
}

CLAN_ADDON_BY_PLAN = {
    "monthly": PRODUCT_CLAN_ADDON_MONTHLY,
    "six_month": PRODUCT_CLAN_ADDON_SIX_MONTH,
    "yearly": PRODUCT_CLAN_ADDON_YEARLY,
}

STRIPE_PRICE_BY_PLAN = {
    "monthly": STRIPE_PRICE_MONTHLY,
    "six_month": STRIPE_PRICE_SIX_MONTH,
    "yearly": STRIPE_PRICE_YEARLY,
}

STRIPE_CLAN_ADDON_BY_PLAN = {
    "monthly": STRIPE_PRICE_CLAN_ADDON_MONTHLY,
    "six_month": STRIPE_PRICE_CLAN_ADDON_SIX_MONTH,
    "yearly": STRIPE_PRICE_CLAN_ADDON_YEARLY,
}


def _discounted_cents(price_cents: int, pay_percent: int) -> int:
    return max(1, round(price_cents * pay_percent / 100))


def _plan_entry(
    plan_id: str,
    name: str,
    tagline: str,
    price_cents: int,
    interval: str,
    interval_count: int,
    store_product_id: str,
    badge: Optional[str] = None,
    referral_eligible: bool = False,
) -> dict[str, Any]:
    """Build a plan row for the catalog API.

    Do not embed formatted USD strings — the app must show App Store /
    Play Billing localized prices (e.g. MAD in Morocco). Keep cents for
    Stripe/admin only.
    """
    equivalent_monthly = round(price_cents / max(interval_count, 1))
    entry: dict[str, Any] = {
        "id": plan_id,
        "name": name,
        "tagline": tagline,
        "price_cents": price_cents,
        "price_currency": "USD",  # reference currency for price_cents only
        "interval": interval,
        "interval_count": interval_count,
        "equivalent_monthly_cents": equivalent_monthly,
        "store_product_id": store_product_id,
    }
    if badge:
        entry["badge"] = badge
    if referral_eligible:
        discounted = _discounted_cents(price_cents, REFERRAL_PAY_PERCENT)
        entry["referral_price_cents"] = discounted
    return entry


def build_catalog(*, referral_eligible: bool = False) -> dict[str, Any]:
    """Build the full subscription catalog for API responses."""
    plans = [
        _plan_entry(
            "monthly",
            "Monthly",
            "Pay per month. Best for regular users.",
            PLAN_MONTHLY_CENTS,
            "month",
            1,
            PRODUCT_MONTHLY,
            referral_eligible=referral_eligible,
        ),
        _plan_entry(
            "six_month",
            "6-Month",
            "Billed every six months.",
            PLAN_SIX_MONTH_CENTS,
            "month",
            6,
            PRODUCT_SIX_MONTH,
            badge="POPULAR",
            referral_eligible=referral_eligible,
        ),
        _plan_entry(
            "yearly",
            "Yearly",
            "Billed once per year.",
            PLAN_YEARLY_CENTS,
            "year",
            1,
            PRODUCT_YEARLY,
            badge="BEST VALUE",
            referral_eligible=referral_eligible,
        ),
    ]

    clan_addons = {
        "monthly": {
            "price_cents": CLAN_ADDON_MONTHLY_CENTS,
            "price_currency": "USD",
            "store_product_id": PRODUCT_CLAN_ADDON_MONTHLY,
            "description": "Add a family member to your monthly plan",
        },
        "six_month": {
            "price_cents": CLAN_ADDON_SIX_MONTH_CENTS,
            "price_currency": "USD",
            "store_product_id": PRODUCT_CLAN_ADDON_SIX_MONTH,
            "description": "Add a family member to your 6-month plan",
        },
        "yearly": {
            "price_cents": CLAN_ADDON_YEARLY_CENTS,
            "price_currency": "USD",
            "store_product_id": PRODUCT_CLAN_ADDON_YEARLY,
            "description": "Add a family member to your yearly plan",
        },
    }

    referral_offer: Optional[dict[str, Any]] = None
    if referral_eligible:
        referral_offer = {
            "eligible": True,
            "pay_percent": REFERRAL_PAY_PERCENT,
            "duration_periods": REFERRAL_DURATION_PERIODS,
            "headline": (
                f"Referral offer: pay {REFERRAL_PAY_PERCENT}% for your first "
                f"{REFERRAL_DURATION_PERIODS} billing periods"
            ),
        }

    coach_plans = [
        _plan_entry(
            "monthly",
            "Coach Monthly",
            "List yourself as a coach each month.",
            COACH_MONTHLY_CENTS,
            "month",
            1,
            PRODUCT_COACH_MONTHLY,
        ),
        _plan_entry(
            "yearly",
            "Coach Yearly",
            "12 months with 20% off versus monthly.",
            COACH_YEARLY_CENTS,
            "year",
            1,
            PRODUCT_COACH_YEARLY,
            badge="20% OFF",
        ),
    ]

    return {
        "plans": plans,
        "clan_addons": clan_addons,
        "coach_plans": coach_plans,
        "clan_max_members": CLAN_MAX_MEMBERS,
        "referral_offer": referral_offer,
        "default_plan_id": "yearly",
        "default_coach_plan_id": "yearly",
    }


def plan_id_from_product(product_id: str) -> Optional[str]:
    return PLAN_BY_PRODUCT.get(product_id)


def coach_plan_id_from_product(product_id: str) -> Optional[str]:
    return COACH_PLAN_BY_PRODUCT.get(product_id)


def clan_addon_product_for_plan(plan_id: str) -> Optional[str]:
    return CLAN_ADDON_BY_PLAN.get(plan_id)
