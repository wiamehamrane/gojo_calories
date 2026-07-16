from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import desc
from sqlalchemy.orm import Session

from database import get_db
from models import Influencer, User
from security import get_password_hash, get_current_user, require_admin_user
from services.subscription_service import grant_subscription, revoke_subscription

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


# ── Helpers ───────────────────────────────────────────────────────────────────


def _influencer_summary(influencer: Influencer, db: Session) -> dict:
    user = influencer.user
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
        "created_at": influencer.created_at.isoformat() if influencer.created_at else None,
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
    return _influencer_summary(influencer, db)


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

    return _influencer_summary(influencer, db)
