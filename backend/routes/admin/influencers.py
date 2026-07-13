import datetime
import random
import string
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from database import get_db
from models import Influencer, PromoCode, PromoRedemption, User
from security import get_password_hash, get_current_user, require_admin_user
from services.subscription_service import grant_subscription, revoke_subscription
from services.promo_redemption_service import PLAN_TO_STORE_PRODUCT

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────


class InfluencerCreate(BaseModel):
    email: str
    password: str
    name: Optional[str] = None
    display_name: str
    handle: Optional[str] = None
    platform: Optional[str] = None
    notes: Optional[str] = None
    commission_rate: Optional[float] = None
    panel_access: bool = True
    grant_plan: Optional[str] = None  # monthly | yearly | lifetime | trial_7d


class InfluencerUpdate(BaseModel):
    display_name: Optional[str] = None
    handle: Optional[str] = None
    platform: Optional[str] = None
    notes: Optional[str] = None
    commission_rate: Optional[float] = None
    panel_access: Optional[bool] = None
    is_active: Optional[bool] = None


class GrantSubscriptionRequest(BaseModel):
    plan_type: str  # monthly | yearly | lifetime | trial_7d


class PromoCodeCreate(BaseModel):
    code: Optional[str] = None
    platform: str = "internal"  # internal | apple | google
    plan_type: str
    max_redemptions: Optional[int] = None
    expires_at: Optional[datetime.datetime] = None
    notes: Optional[str] = None


class AppleBatchPromoCreate(BaseModel):
    plan_type: str
    number_of_codes: int = 10
    expiration_date: str  # YYYY-MM-DD
    environment: str = "production"


class PromoCodeUpdate(BaseModel):
    plan_type: Optional[str] = None
    max_redemptions: Optional[int] = None
    is_active: Optional[bool] = None
    expires_at: Optional[datetime.datetime] = None


# ── Helpers ───────────────────────────────────────────────────────────────────


def _generate_code(length: int = 8) -> str:
    chars = string.ascii_uppercase + string.digits
    return "".join(random.choices(chars, k=length))


def _influencer_summary(influencer: Influencer, db: Session) -> dict:
    user = influencer.user
    total_codes = (
        db.query(func.count(PromoCode.id))
        .filter(PromoCode.influencer_id == influencer.id)
        .scalar()
        or 0
    )
    total_redemptions = (
        db.query(func.count(PromoRedemption.id))
        .join(PromoCode)
        .filter(PromoCode.influencer_id == influencer.id)
        .scalar()
        or 0
    )
    active_codes = (
        db.query(func.count(PromoCode.id))
        .filter(
            PromoCode.influencer_id == influencer.id,
            PromoCode.is_active == True,
        )
        .scalar()
        or 0
    )

    return {
        "id": influencer.id,
        "user_id": influencer.user_id,
        "email": user.email if user else None,
        "name": user.name if user else None,
        "display_name": influencer.display_name,
        "handle": influencer.handle,
        "platform": influencer.platform,
        "notes": influencer.notes,
        "commission_rate": influencer.commission_rate,
        "panel_access": influencer.panel_access,
        "is_active": influencer.is_active,
        "has_paid": user.has_paid if user else False,
        "subscription_source": user.subscription_source if user else None,
        "subscription_expires_at": (
            user.subscription_expires_at.isoformat()
            if user and user.subscription_expires_at
            else None
        ),
        "total_codes": total_codes,
        "active_codes": active_codes,
        "total_redemptions": total_redemptions,
        "created_at": influencer.created_at.isoformat() if influencer.created_at else None,
    }


def _promo_summary(promo: PromoCode, db: Session) -> dict:
    platform = promo.platform or "internal"
    return {
        "id": promo.id,
        "code": promo.code,
        "platform": platform,
        "plan_type": promo.plan_type,
        "store_product_id": promo.store_product_id,
        "notes": promo.notes,
        "max_redemptions": promo.max_redemptions,
        "redemption_count": promo.redemption_count,
        "is_active": promo.is_active,
        "expires_at": promo.expires_at.isoformat() if promo.expires_at else None,
        "created_at": promo.created_at.isoformat() if promo.created_at else None,
        "remaining": (
            promo.max_redemptions - promo.redemption_count
            if promo.max_redemptions is not None
            else None
        ),
        "redeem_url": (
            f"https://play.google.com/redeem?code={promo.code}"
            if platform == "google"
            else None
        ),
    }


# ── Influencer CRUD ───────────────────────────────────────────────────────────


@router.get("/influencers")
def list_influencers(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    search: Optional[str] = None,
    active_only: bool = False,
):
    query = db.query(Influencer).order_by(desc(Influencer.created_at))
    if active_only:
        query = query.filter(Influencer.is_active == True)
    if search:
        term = f"%{search}%"
        query = query.join(User).filter(
            (Influencer.display_name.ilike(term))
            | (Influencer.handle.ilike(term))
            | (User.email.ilike(term))
        )

    influencers = query.all()
    return {
        "items": [_influencer_summary(i, db) for i in influencers],
        "total": len(influencers),
    }


@router.post("/influencers")
def create_influencer(
    body: InfluencerCreate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    existing_user = db.query(User).filter(User.email == body.email).first()
    if existing_user:
        existing_inf = (
            db.query(Influencer)
            .filter(Influencer.user_id == existing_user.id)
            .first()
        )
        if existing_inf:
            raise HTTPException(status_code=400, detail="User is already an influencer")
        user = existing_user
        user.is_influencer = True
        if body.password:
            user.hashed_password = get_password_hash(body.password)
    else:
        user = User(
            email=body.email,
            name=body.name or body.display_name,
            hashed_password=get_password_hash(body.password),
            is_email_verified=True,
            is_influencer=True,
        )
        db.add(user)
        db.flush()

    influencer = Influencer(
        user_id=user.id,
        display_name=body.display_name,
        handle=body.handle,
        platform=body.platform,
        notes=body.notes,
        commission_rate=body.commission_rate,
        panel_access=body.panel_access,
    )
    db.add(influencer)

    if body.grant_plan:
        grant_subscription(user, body.grant_plan, source="admin_grant")

    db.commit()
    db.refresh(influencer)
    return _influencer_summary(influencer, db)


@router.get("/influencers/{influencer_id}")
def get_influencer(
    influencer_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer:
        raise HTTPException(status_code=404, detail="Influencer not found")

    promos = (
        db.query(PromoCode)
        .filter(PromoCode.influencer_id == influencer_id)
        .order_by(desc(PromoCode.created_at))
        .all()
    )
    redemptions = (
        db.query(PromoRedemption)
        .join(PromoCode)
        .filter(PromoCode.influencer_id == influencer_id)
        .order_by(desc(PromoRedemption.redeemed_at))
        .limit(50)
        .all()
    )

    return {
        **_influencer_summary(influencer, db),
        "promo_codes": [_promo_summary(p, db) for p in promos],
        "recent_redemptions": [
            {
                "id": r.id,
                "user_email": r.user.email if r.user else None,
                "code": r.promo_code.code if r.promo_code else None,
                "plan_granted": r.plan_granted,
                "redeemed_at": r.redeemed_at.isoformat() if r.redeemed_at else None,
            }
            for r in redemptions
        ],
    }


@router.patch("/influencers/{influencer_id}")
def update_influencer(
    influencer_id: str,
    body: InfluencerUpdate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer:
        raise HTTPException(status_code=404, detail="Influencer not found")

    updates = body.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(influencer, key, value)

    if body.is_active is False and influencer.user:
        influencer.user.is_influencer = False
    elif body.is_active is True and influencer.user:
        influencer.user.is_influencer = True

    if body.panel_access is False and influencer.user:
        influencer.user.is_influencer = False
    elif body.panel_access is True and influencer.user:
        influencer.user.is_influencer = True

    db.commit()
    db.refresh(influencer)
    return _influencer_summary(influencer, db)


@router.post("/influencers/{influencer_id}/grant-subscription")
def grant_influencer_subscription(
    influencer_id: str,
    body: GrantSubscriptionRequest,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer or not influencer.user:
        raise HTTPException(status_code=404, detail="Influencer not found")

    valid_plans = ("monthly", "yearly", "lifetime", "trial_7d")
    if body.plan_type not in valid_plans:
        raise HTTPException(status_code=400, detail=f"Plan must be one of: {valid_plans}")

    grant_subscription(influencer.user, body.plan_type, source="admin_grant")
    db.commit()
    db.refresh(influencer)
    return _influencer_summary(influencer, db)


@router.post("/influencers/{influencer_id}/revoke-subscription")
def revoke_influencer_subscription(
    influencer_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer or not influencer.user:
        raise HTTPException(status_code=404, detail="Influencer not found")

    revoke_subscription(influencer.user)
    db.commit()
    db.refresh(influencer)
    return _influencer_summary(influencer, db)


# ── Promo codes ───────────────────────────────────────────────────────────────


@router.post("/influencers/{influencer_id}/promo-codes")
def create_promo_code(
    influencer_id: str,
    body: PromoCodeCreate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer:
        raise HTTPException(status_code=404, detail="Influencer not found")

    valid_plans = ("monthly", "six_month", "yearly", "lifetime", "trial_7d")
    if body.plan_type not in valid_plans:
        raise HTTPException(status_code=400, detail=f"Plan must be one of: {valid_plans}")

    platform = (body.platform or "internal").lower()
    if platform not in ("internal", "apple", "google"):
        raise HTTPException(status_code=400, detail="Platform must be internal, apple, or google")

    code = (body.code or _generate_code()).strip().upper()
    existing = db.query(PromoCode).filter(PromoCode.code == code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Promo code already exists")

    store_product_id = None
    if platform in ("apple", "google"):
        store_product_id = PLAN_TO_STORE_PRODUCT.get(body.plan_type)
        if not store_product_id:
            raise HTTPException(
                status_code=400,
                detail=f"No store product mapped for plan {body.plan_type}",
            )
        if not body.code:
            raise HTTPException(
                status_code=400,
                detail="Store promo codes must be registered with the exact code from App Store Connect or Google Play Console",
            )

    promo = PromoCode(
        influencer_id=influencer_id,
        code=code,
        platform=platform,
        plan_type=body.plan_type,
        store_product_id=store_product_id,
        notes=body.notes,
        max_redemptions=body.max_redemptions,
        expires_at=body.expires_at,
    )
    db.add(promo)
    db.commit()
    db.refresh(promo)
    return _promo_summary(promo, db)


@router.post("/influencers/{influencer_id}/promo-codes/apple-batch")
def create_apple_batch_promo_codes(
    influencer_id: str,
    body: AppleBatchPromoCreate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    """Generate one-time offer codes via App Store Connect API and register each in our DB."""
    from services import apple_asc_service

    influencer = db.query(Influencer).filter(Influencer.id == influencer_id).first()
    if not influencer:
        raise HTTPException(status_code=404, detail="Influencer not found")

    valid_plans = ("monthly", "six_month", "yearly")
    if body.plan_type not in valid_plans:
        raise HTTPException(status_code=400, detail=f"Plan must be one of: {valid_plans}")

    if body.number_of_codes < 1 or body.number_of_codes > 500:
        raise HTTPException(status_code=400, detail="number_of_codes must be between 1 and 500")

    try:
        codes = apple_asc_service.generate_one_time_codes(
            plan_type=body.plan_type,
            number_of_codes=body.number_of_codes,
            expiration_date=body.expiration_date,
            environment=body.environment,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))

    store_product_id = PLAN_TO_STORE_PRODUCT.get(body.plan_type)
    created = []
    for raw_code in codes:
        code = raw_code.strip().upper()
        if db.query(PromoCode).filter(PromoCode.code == code).first():
            continue
        promo = PromoCode(
            influencer_id=influencer_id,
            code=code,
            platform="apple",
            plan_type=body.plan_type,
            store_product_id=store_product_id,
            notes=f"ASC batch {body.expiration_date}",
            max_redemptions=1,
        )
        db.add(promo)
        created.append(code)

    db.commit()
    promos = (
        db.query(PromoCode)
        .filter(PromoCode.influencer_id == influencer_id, PromoCode.code.in_(created))
        .all()
    )
    return {
        "generated_count": len(created),
        "codes": [_promo_summary(p, db) for p in promos],
    }


@router.patch("/influencers/{influencer_id}/promo-codes/{promo_id}")
def update_promo_code(
    influencer_id: str,
    promo_id: str,
    body: PromoCodeUpdate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    promo = (
        db.query(PromoCode)
        .filter(PromoCode.id == promo_id, PromoCode.influencer_id == influencer_id)
        .first()
    )
    if not promo:
        raise HTTPException(status_code=404, detail="Promo code not found")

    updates = body.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(promo, key, value)
    db.commit()
    db.refresh(promo)
    return _promo_summary(promo, db)


@router.get("/influencers/{influencer_id}/promo-codes/{promo_id}/redemptions")
def list_promo_redemptions(
    influencer_id: str,
    promo_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    promo = (
        db.query(PromoCode)
        .filter(PromoCode.id == promo_id, PromoCode.influencer_id == influencer_id)
        .first()
    )
    if not promo:
        raise HTTPException(status_code=404, detail="Promo code not found")

    redemptions = (
        db.query(PromoRedemption)
        .filter(PromoRedemption.promo_code_id == promo_id)
        .order_by(desc(PromoRedemption.redeemed_at))
        .all()
    )

    return {
        "code": promo.code,
        "items": [
            {
                "id": r.id,
                "user_id": r.user_id,
                "user_email": r.user.email if r.user else None,
                "plan_granted": r.plan_granted,
                "redeemed_at": r.redeemed_at.isoformat() if r.redeemed_at else None,
            }
            for r in redemptions
        ],
        "total": len(redemptions),
    }


# ── Influencer self-service (panel access) ────────────────────────────────────


@router.get("/influencer/me")
def influencer_me(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.is_admin:
        raise HTTPException(status_code=403, detail="Admins should use admin routes")

    influencer = (
        db.query(Influencer)
        .filter(Influencer.user_id == user.id, Influencer.is_active == True)
        .first()
    )
    if not influencer or not influencer.panel_access:
        raise HTTPException(status_code=403, detail="Influencer access required")

    promos = (
        db.query(PromoCode)
        .filter(PromoCode.influencer_id == influencer.id)
        .order_by(desc(PromoCode.created_at))
        .all()
    )
    redemptions = (
        db.query(PromoRedemption)
        .join(PromoCode)
        .filter(PromoCode.influencer_id == influencer.id)
        .order_by(desc(PromoRedemption.redeemed_at))
        .limit(50)
        .all()
    )

    return {
        **_influencer_summary(influencer, db),
        "promo_codes": [_promo_summary(p, db) for p in promos],
        "recent_redemptions": [
            {
                "id": r.id,
                "user_email": r.user.email if r.user else None,
                "code": r.promo_code.code if r.promo_code else None,
                "plan_granted": r.plan_granted,
                "redeemed_at": r.redeemed_at.isoformat() if r.redeemed_at else None,
            }
            for r in redemptions
        ],
    }

