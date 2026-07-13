"""Shared promo code lookup and redemption helpers."""

import datetime
from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from models import Influencer, PromoCode, PromoRedemption, User
from services.subscription_service import grant_subscription

PLAN_TO_STORE_PRODUCT = {
    "monthly": "gojo_pro_monthly",
    "six_month": "gojo_pro_six_month",
    "yearly": "gojo_pro_yearly",
}


def normalize_code(code: str) -> str:
    return code.strip().upper()


def lookup_promo(db: Session, code_str: str) -> PromoCode:
    promo = (
        db.query(PromoCode)
        .filter(PromoCode.code == code_str)
        .first()
    )
    if not promo or not promo.is_active:
        raise HTTPException(status_code=404, detail="Invalid or inactive promo code")

    if promo.expires_at and promo.expires_at < datetime.datetime.utcnow():
        raise HTTPException(status_code=400, detail="This promo code has expired")

    if promo.max_redemptions is not None and promo.redemption_count >= promo.max_redemptions:
        raise HTTPException(status_code=400, detail="This promo code has reached its limit")

    influencer = db.query(Influencer).filter(Influencer.id == promo.influencer_id).first()
    if not influencer or not influencer.is_active:
        raise HTTPException(status_code=400, detail="This promo code is no longer valid")

    return promo


def promo_public_view(promo: PromoCode) -> dict:
    platform = promo.platform or "internal"
    store_product = promo.store_product_id or PLAN_TO_STORE_PRODUCT.get(promo.plan_type)
    view = {
        "code": promo.code,
        "platform": platform,
        "plan_type": promo.plan_type,
        "store_product_id": store_product,
        "description": promo.notes,
    }
    if platform == "google":
        view["redeem_url"] = f"https://play.google.com/redeem?code={promo.code}"
        view["instructions"] = (
            "Open Google Play, subscribe to Gojo Pro, and tap Redeem code on the payment screen. "
            "Or use the link to redeem in the Play Store app first."
        )
    elif platform == "apple":
        view["instructions"] = (
            "Tap Continue to open the App Store redemption sheet and enter this code. "
            "After redeeming, complete subscription in the App Store, then return here."
        )
    else:
        view["instructions"] = "This code grants free Pro access instantly."
    return view


def set_pending_promo(user: User, promo: PromoCode) -> None:
    user.pending_promo_code_id = promo.id


def finalize_pending_promo(db: Session, user: User, *, source: str) -> None:
    """Attribute a completed IAP purchase to a pending store promo code."""
    if not user.pending_promo_code_id:
        return

    promo = db.query(PromoCode).filter(PromoCode.id == user.pending_promo_code_id).first()
    if not promo or not promo.is_active:
        user.pending_promo_code_id = None
        return

    if promo.platform not in ("apple", "google"):
        user.pending_promo_code_id = None
        return

    existing = (
        db.query(PromoRedemption)
        .filter(PromoRedemption.user_id == user.id)
        .first()
    )
    if existing:
        user.pending_promo_code_id = None
        return

    redemption = PromoRedemption(
        promo_code_id=promo.id,
        user_id=user.id,
        plan_granted=promo.plan_type,
    )
    promo.redemption_count += 1
    db.add(redemption)
    user.pending_promo_code_id = None


def redeem_internal(db: Session, user: User, promo: PromoCode) -> dict:
    existing = (
        db.query(PromoRedemption)
        .filter(PromoRedemption.user_id == user.id)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=400,
            detail="You have already redeemed a promo code",
        )

    grant_subscription(user, promo.plan_type, source="promo")

    redemption = PromoRedemption(
        promo_code_id=promo.id,
        user_id=user.id,
        plan_granted=promo.plan_type,
    )
    promo.redemption_count += 1
    db.add(redemption)
    db.commit()
    db.refresh(user)

    return {
        "status": "success",
        "platform": "internal",
        "action": "granted",
        "plan": promo.plan_type,
        "has_paid": user.has_paid,
        "subscription_expires_at": (
            user.subscription_expires_at.isoformat()
            if user.subscription_expires_at
            else None
        ),
    }


def redeem_store_promo(db: Session, user: User, promo: PromoCode) -> dict:
    set_pending_promo(user, promo)
    db.commit()
    db.refresh(user)
    payload = promo_public_view(promo)
    payload.update({
        "status": "success",
        "action": "store_redeem",
        "has_paid": user.has_paid,
    })
    return payload
