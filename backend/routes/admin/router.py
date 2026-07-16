import datetime
import os
from typing import List, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import desc, func, or_
from sqlalchemy.orm import Session

from database import get_db
from models import (
    DailyStats,
    Event,
    EventParticipant,
    ExerciseLog,
    FoodLog,
    Friendship,
    Group,
    GroupMember,
    Influencer,
    Memory,
    Post,
    PostLike,
    PromoCode,
    PromoRedemption,
    Referral,
    User,
    Withdrawal,
)
from security import (
    create_access_token,
    get_current_user,
    get_password_hash,
    require_admin_user,
    verify_password,
)
from services import email_service

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────


class AdminLoginRequest(BaseModel):
    email: str
    password: str


class AdminUserCreate(BaseModel):
    email: str
    password: str
    name: Optional[str] = None
    is_email_verified: bool = False
    has_paid: bool = False
    is_admin: bool = False
    is_banned: bool = False
    subscription_source: Optional[str] = None
    current_weight: Optional[float] = None
    goal_weight: Optional[float] = None
    weight_unit: Optional[str] = "kg"
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
    phone: Optional[str] = None


class AdminUserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    has_paid: Optional[bool] = None
    is_admin: Optional[bool] = None
    is_banned: Optional[bool] = None
    is_email_verified: Optional[bool] = None
    subscription_source: Optional[str] = None
    subscription_expires_at: Optional[datetime.datetime] = None
    referral_balance: Optional[float] = None
    current_weight: Optional[float] = None
    goal_weight: Optional[float] = None
    weight_unit: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
    phone: Optional[str] = None


class SubscriptionUpdate(BaseModel):
    has_paid: bool
    subscription_source: Optional[str] = None
    subscription_expires_at: Optional[datetime.datetime] = None


class WithdrawalUpdate(BaseModel):
    status: str  # "pending" | "paid"


class NotificationRequest(BaseModel):
    subject: str
    body: str
    target_users: str = "all"
    emails: Optional[List[str]] = None


# ── Helpers ───────────────────────────────────────────────────────────────────


def _user_summary(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "is_email_verified": user.is_email_verified,
        "is_admin": user.is_admin,
        "is_banned": user.is_banned,
        "has_paid": user.has_paid,
        "subscription_source": user.subscription_source,
        "subscription_expires_at": (
            user.subscription_expires_at.isoformat()
            if user.subscription_expires_at
            else None
        ),
        "current_weight": user.current_weight,
        "goal_weight": user.goal_weight,
        "referral_code": user.referral_code,
        "referral_balance": user.referral_balance,
        "stripe_customer_id": user.stripe_customer_id,
        "created_at": None,
    }


def _paginate(query, page: int, page_size: int):
    total = query.count()
    items = (
        query.offset((page - 1) * page_size).limit(page_size).all()
    )
    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": max(1, (total + page_size - 1) // page_size),
    }


# ── Auth ──────────────────────────────────────────────────────────────────────


@router.post("/auth/login")
def admin_login(body: AdminLoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if not user or not user.hashed_password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if user.is_banned:
        raise HTTPException(status_code=403, detail="Account suspended")

    role = "admin"
    if user.is_admin:
        pass
    elif user.is_influencer:
        influencer = (
            db.query(Influencer)
            .filter(Influencer.user_id == user.id, Influencer.is_active == True)
            .first()
        )
        if not influencer or not influencer.panel_access:
            raise HTTPException(status_code=403, detail="Panel access required")
        role = "influencer"
    else:
        raise HTTPException(status_code=403, detail="Admin access required")

    token = create_access_token({"sub": user.id, "admin": True, "role": role})
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": role,
        "user": _user_summary(user),
    }


@router.get("/auth/me")
def admin_me(user: User = Depends(get_current_user)):
    if not user.is_admin and not user.is_influencer:
        raise HTTPException(status_code=403, detail="Access denied")
    return _user_summary(user)


# ── Dashboard ─────────────────────────────────────────────────────────────────


@router.get("/dashboard")
def dashboard_stats(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    now = datetime.datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - datetime.timedelta(days=7)

    total_users = db.query(func.count(User.id)).scalar() or 0
    verified_users = (
        db.query(func.count(User.id))
        .filter(User.is_email_verified == True)
        .scalar()
        or 0
    )
    paid_users = (
        db.query(func.count(User.id)).filter(User.has_paid == True).scalar() or 0
    )
    banned_users = (
        db.query(func.count(User.id)).filter(User.is_banned == True).scalar() or 0
    )

    subscription_breakdown = (
        db.query(User.subscription_source, func.count(User.id))
        .filter(User.has_paid == True)
        .group_by(User.subscription_source)
        .all()
    )

    return {
        "total_users": total_users,
        "verified_users": verified_users,
        "paid_users": paid_users,
        "banned_users": banned_users,
        "total_food_logs": db.query(func.count(FoodLog.id)).scalar() or 0,
        "total_exercises": db.query(func.count(ExerciseLog.id)).scalar() or 0,
        "total_events": db.query(func.count(Event.id)).scalar() or 0,
        "total_posts": db.query(func.count(Post.id)).scalar() or 0,
        "total_memories": db.query(func.count(Memory.id)).scalar() or 0,
        "total_groups": db.query(func.count(Group.id)).scalar() or 0,
        "pending_withdrawals": (
            db.query(func.count(Withdrawal.id))
            .filter(Withdrawal.status == "pending")
            .scalar()
            or 0
        ),
        "total_influencers": db.query(func.count(Influencer.id)).scalar() or 0,
        "active_influencers": (
            db.query(func.count(Influencer.id))
            .filter(Influencer.is_active == True)
            .scalar()
            or 0
        ),
        "total_promo_redemptions": (
            db.query(func.count(PromoRedemption.id)).scalar() or 0
        ),
        "active_promo_codes": (
            db.query(func.count(PromoCode.id))
            .filter(PromoCode.is_active == True)
            .scalar()
            or 0
        ),
        "subscription_breakdown": {
            (src or "unknown"): count for src, count in subscription_breakdown
        },
    }


def _get_user_detail(user: User, db: Session) -> dict:
    user_id = user.id
    return {
        **_user_summary(user),
        "height": user.height,
        "height_unit": user.height_unit,
        "age": user.age,
        "gender": user.gender,
        "activity_level": user.activity_level,
        "weight_unit": user.weight_unit,
        "manual_calories": user.manual_calories,
        "manual_protein": user.manual_protein,
        "manual_carbs": user.manual_carbs,
        "manual_fat": user.manual_fat,
        "phone": user.phone,
        "apple_original_transaction_id": user.apple_original_transaction_id,
        "google_order_id": user.google_order_id,
        "counts": {
            "food_logs": db.query(func.count(FoodLog.id))
            .filter(FoodLog.user_id == user_id)
            .scalar(),
            "exercises": db.query(func.count(ExerciseLog.id))
            .filter(ExerciseLog.user_id == user_id)
            .scalar(),
            "events_created": db.query(func.count(Event.id))
            .filter(Event.creator_id == user_id)
            .scalar(),
            "posts": db.query(func.count(Post.id))
            .filter(Post.user_id == user_id)
            .scalar(),
            "memories": db.query(func.count(Memory.id))
            .filter(Memory.user_id == user_id)
            .scalar(),
            "referrals": db.query(func.count(Referral.id))
            .filter(Referral.referrer_id == user_id)
            .scalar(),
        },
    }


def _apply_user_updates(user: User, updates: dict, db: Session, admin: User):
    if "email" in updates and updates["email"] != user.email:
        existing = (
            db.query(User)
            .filter(User.email == updates["email"], User.id != user.id)
            .first()
        )
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = updates.pop("email")

    if "password" in updates:
        password = updates.pop("password")
        if password:
            user.hashed_password = get_password_hash(password)

    if user.id == admin.id and updates.get("is_admin") is False:
        raise HTTPException(status_code=400, detail="Cannot remove your own admin access")

    for key, value in updates.items():
        setattr(user, key, value)


# ── Users ─────────────────────────────────────────────────────────────────────


@router.post("/users")
def create_user(
    body: AdminUserCreate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already in use")

    user = User(
        email=body.email,
        name=body.name,
        hashed_password=get_password_hash(body.password),
        is_email_verified=body.is_email_verified,
        has_paid=body.has_paid,
        is_admin=body.is_admin,
        is_banned=body.is_banned,
        subscription_source=body.subscription_source,
        current_weight=body.current_weight,
        goal_weight=body.goal_weight,
        weight_unit=body.weight_unit or "kg",
        age=body.age,
        gender=body.gender,
        activity_level=body.activity_level,
        phone=body.phone,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _get_user_detail(user, db)


@router.get("/users")
def list_users(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    has_paid: Optional[bool] = None,
    is_banned: Optional[bool] = None,
):
    query = db.query(User).order_by(desc(User.email))
    if search:
        term = f"%{search}%"
        query = query.filter(
            or_(User.email.ilike(term), User.name.ilike(term))
        )
    if has_paid is not None:
        query = query.filter(User.has_paid == has_paid)
    if is_banned is not None:
        query = query.filter(User.is_banned == is_banned)

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [_user_summary(u) for u in result["items"]],
    }


@router.get("/users/{user_id}")
def get_user(
    user_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return _get_user_detail(user, db)


@router.patch("/users/{user_id}")
def update_user(
    user_id: str,
    body: AdminUserUpdate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    updates = body.model_dump(exclude_unset=True)
    _apply_user_updates(user, updates, db, admin)
    db.commit()
    db.refresh(user)
    return _get_user_detail(user, db)


@router.delete("/users/{user_id}")
def delete_user(
    user_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)
    db.commit()
    return {"status": "deleted", "user_id": user_id}


# ── Subscriptions ─────────────────────────────────────────────────────────────


@router.get("/subscriptions")
def list_subscriptions(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    source: Optional[str] = None,
):
    query = db.query(User).filter(User.has_paid == True).order_by(desc(User.email))
    if source:
        query = query.filter(User.subscription_source == source)

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [_user_summary(u) for u in result["items"]],
    }


@router.patch("/subscriptions/{user_id}")
def update_subscription(
    user_id: str,
    body: SubscriptionUpdate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.has_paid = body.has_paid
    if body.subscription_source is not None:
        user.subscription_source = body.subscription_source
    if body.subscription_expires_at is not None:
        user.subscription_expires_at = body.subscription_expires_at
    db.commit()
    db.refresh(user)
    return _user_summary(user)


# ── Food Logs ─────────────────────────────────────────────────────────────────


@router.get("/food-logs")
def list_food_logs(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_id: Optional[str] = None,
    search: Optional[str] = None,
):
    query = db.query(FoodLog).order_by(desc(FoodLog.created_at))
    if user_id:
        query = query.filter(FoodLog.user_id == user_id)
    if search:
        query = query.filter(FoodLog.name.ilike(f"%{search}%"))

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": log.id,
                "user_id": log.user_id,
                "name": log.name,
                "calories": log.calories,
                "protein": log.protein,
                "carbs": log.carbs,
                "fat": log.fat,
                "image_url": log.image_url,
                "created_at": log.created_at.isoformat() if log.created_at else None,
            }
            for log in result["items"]
        ],
    }


@router.delete("/food-logs/{log_id}")
def delete_food_log(
    log_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    log = db.query(FoodLog).filter(FoodLog.id == log_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Food log not found")
    db.delete(log)
    db.commit()
    return {"status": "deleted"}


# ── Events ────────────────────────────────────────────────────────────────────


@router.get("/events")
def list_events(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
):
    query = db.query(Event).order_by(desc(Event.start_time))
    if search:
        query = query.filter(Event.title.ilike(f"%{search}%"))

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": e.id,
                "creator_id": e.creator_id,
                "title": e.title,
                "event_type": e.event_type,
                "audience": e.audience,
                "location_name": e.location_name,
                "start_time": e.start_time.isoformat() if e.start_time else None,
                "max_participants": e.max_participants,
                "participant_count": len(e.participants),
                "image_url": e.image_url,
                "created_at": e.created_at.isoformat() if e.created_at else None,
            }
            for e in result["items"]
        ],
    }


@router.delete("/events/{event_id}")
def delete_event(
    event_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    db.delete(event)
    db.commit()
    return {"status": "deleted"}


# ── Posts ─────────────────────────────────────────────────────────────────────


@router.get("/posts")
def list_posts(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    query = db.query(Post).order_by(desc(Post.created_at))
    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": p.id,
                "user_id": p.user_id,
                "content": p.content,
                "image_url": p.image_url,
                "like_count": len(p.likes),
                "created_at": p.created_at.isoformat() if p.created_at else None,
            }
            for p in result["items"]
        ],
    }


@router.delete("/posts/{post_id}")
def delete_post(
    post_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    db.delete(post)
    db.commit()
    return {"status": "deleted"}


# ── Memories ──────────────────────────────────────────────────────────────────


@router.get("/memories")
def list_memories(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    query = db.query(Memory).order_by(desc(Memory.created_at))
    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": m.id,
                "user_id": m.user_id,
                "caption": m.caption,
                "image_url": m.image_url,
                "is_private": m.is_private,
                "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in result["items"]
        ],
    }


@router.delete("/memories/{memory_id}")
def delete_memory(
    memory_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    memory = db.query(Memory).filter(Memory.id == memory_id).first()
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")
    db.delete(memory)
    db.commit()
    return {"status": "deleted"}


# ── Groups ────────────────────────────────────────────────────────────────────


@router.get("/groups")
def list_groups(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    query = db.query(Group).order_by(desc(Group.created_at))
    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": g.id,
                "name": g.name,
                "description": g.description,
                "member_count": len(g.members),
                "created_at": g.created_at.isoformat() if g.created_at else None,
            }
            for g in result["items"]
        ],
    }


@router.delete("/groups/{group_id}")
def delete_group(
    group_id: str,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    db.delete(group)
    db.commit()
    return {"status": "deleted"}


# ── Referrals & Withdrawals ───────────────────────────────────────────────────


@router.get("/referrals")
def list_referrals(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    query = db.query(Referral).order_by(desc(Referral.created_at))
    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": r.id,
                "referrer_id": r.referrer_id,
                "referrer_email": r.referrer.email if r.referrer else None,
                "referred_user_id": r.referred_user_id,
                "referred_email": r.referred_user.email if r.referred_user else None,
                "amount": r.amount,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in result["items"]
        ],
    }


@router.get("/withdrawals")
def list_withdrawals(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
):
    query = db.query(Withdrawal).order_by(desc(Withdrawal.created_at))
    if status:
        query = query.filter(Withdrawal.status == status)

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": w.id,
                "user_id": w.user_id,
                "user_email": w.user.email if w.user else None,
                "amount": w.amount,
                "method": w.method,
                "status": w.status,
                "created_at": w.created_at.isoformat() if w.created_at else None,
            }
            for w in result["items"]
        ],
    }


@router.patch("/withdrawals/{withdrawal_id}")
def update_withdrawal(
    withdrawal_id: str,
    body: WithdrawalUpdate,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    withdrawal = db.query(Withdrawal).filter(Withdrawal.id == withdrawal_id).first()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")

    if body.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail="Invalid status")

    withdrawal.status = body.status
    db.commit()
    db.refresh(withdrawal)
    return {
        "id": withdrawal.id,
        "status": withdrawal.status,
        "amount": withdrawal.amount,
    }


# ── Notifications ─────────────────────────────────────────────────────────────


def _send_bulk_emails(subject: str, body: str, emails: List[str]):
    for email in emails:
        email_service.send_email(email, subject, body)


@router.post("/notifications/send")
def send_notification(
    body: NotificationRequest,
    background_tasks: BackgroundTasks,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    target_emails: List[str] = []
    if body.target_users == "all":
        users = db.query(User).filter(User.is_email_verified == True).all()
        target_emails = [u.email for u in users if u.email]
    elif body.emails:
        target_emails = body.emails

    if not target_emails:
        raise HTTPException(status_code=400, detail="No target emails found")

    background_tasks.add_task(
        _send_bulk_emails, body.subject, body.body, target_emails
    )
    return {
        "status": "success",
        "message": f"Notifications queued for {len(target_emails)} users",
    }


class PushNotificationRequest(BaseModel):
    title: str
    message: str
    target_users: str = "custom"  # "all" or "custom"
    emails: Optional[List[str]] = None


@router.post("/notifications/push")
def send_push_notification(
    body: PushNotificationRequest,
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
):
    """Send an OneSignal push to specific users (by email) or all verified users.

    Sends synchronously and returns a per-user delivery report, so admins can
    immediately see whether a device is linked/subscribed — useful for testing.
    """
    from services.smart_nutrition_service import _send_push

    if body.target_users == "all":
        users = db.query(User).filter(User.is_email_verified == True).all()  # noqa: E712
    else:
        emails = [e.strip().lower() for e in (body.emails or []) if e.strip()]
        if not emails:
            raise HTTPException(status_code=400, detail="No target emails provided")
        users = db.query(User).filter(func.lower(User.email).in_(emails)).all()

    if not users:
        raise HTTPException(status_code=404, detail="No matching users found")

    results = []
    sent = 0
    for user in users:
        ok, err = _send_push(str(user.id), body.title, body.message)
        if ok:
            sent += 1
        results.append({
            "email": user.email,
            "delivered": ok,
            "error": err or None,
        })

    return {
        "status": "success",
        "sent": sent,
        "total": len(users),
        "results": results,
    }


# ── Exercises ─────────────────────────────────────────────────────────────────


@router.get("/exercises")
def list_exercises(
    admin: User = Depends(require_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_id: Optional[str] = None,
):
    query = db.query(ExerciseLog).order_by(desc(ExerciseLog.date))
    if user_id:
        query = query.filter(ExerciseLog.user_id == user_id)

    result = _paginate(query, page, page_size)
    return {
        **result,
        "items": [
            {
                "id": e.id,
                "user_id": e.user_id,
                "name": e.name,
                "duration_minutes": e.duration_minutes,
                "calories_burned": e.calories_burned,
                "date": e.date.isoformat() if e.date else None,
            }
            for e in result["items"]
        ],
    }


from routes.admin.influencers import router as influencers_router

router.include_router(influencers_router)
