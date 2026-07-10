import datetime
import random
import string

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from database import get_db
from models import Influencer, PromoCode, PromoRedemption, User
from security import get_current_user
from services.subscription_service import grant_subscription

router = APIRouter()


class RedeemPromoRequest(BaseModel):
    code: str


@router.post("/redeem-promo")
def redeem_promo(
    body: RedeemPromoRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    code_str = body.code.strip().upper()
    if not code_str:
        raise HTTPException(status_code=400, detail="Promo code is required")

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
        "plan": promo.plan_type,
        "has_paid": user.has_paid,
        "subscription_expires_at": (
            user.subscription_expires_at.isoformat()
            if user.subscription_expires_at
            else None
        ),
    }
