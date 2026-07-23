"""Share Access — coach/peer diary viewing with explicit permission."""

import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from database import get_db
from s3_utils import resolve_media_url
import models
from security import get_current_user
from services import share_service
from utils.stats_utils import get_or_create_daily_stats

router = APIRouter()


class InviteRequest(BaseModel):
    email: Optional[str] = None
    scopes: Optional[List[str]] = None


class TokenRequest(BaseModel):
    token: str


def _scopes_str(scopes: Optional[List[str]]) -> str:
    if not scopes:
        return share_service.DEFAULT_SCOPES
    cleaned = []
    for s in scopes:
        if not s or not str(s).strip():
            continue
        token = str(s).strip().lower()
        if token not in share_service.VALID_SCOPES:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Invalid scope: {token}. Allowed: "
                    "nutrition, exercises, health_sync, body_journal"
                ),
            )
        if token not in cleaned:
            cleaned.append(token)
    if not cleaned:
        raise HTTPException(
            status_code=400,
            detail="Select at least one share category",
        )
    return ",".join(cleaned)


@router.post("/invite")
def invite(
    body: InviteRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Viewer (coach) creates an invite link for a client to accept."""
    grant = share_service.create_invite(
        db,
        viewer=user,
        email=body.email,
        scopes=_scopes_str(body.scopes),
    )
    return share_service.serialize_grant(grant)


@router.post("/accept")
def accept(
    body: TokenRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Owner (client) accepts the invite and grants diary access."""
    grant = share_service.accept_invite(db, owner=user, token=body.token)
    return share_service.serialize_grant(grant)


@router.post("/decline")
def decline(
    body: TokenRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    grant = db.query(models.ShareGrant).filter(models.ShareGrant.token == body.token).first()
    if not grant or grant.status != "pending":
        raise HTTPException(status_code=404, detail="Pending invite not found")
    if grant.invite_email and user.email and grant.invite_email.lower() != user.email.lower():
        raise HTTPException(status_code=403, detail="This invite was sent to a different email")
    grant.status = "declined"
    db.commit()
    return {"status": "declined"}


@router.get("/me")
def my_shares(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    as_viewer = (
        db.query(models.ShareGrant)
        .filter(
            models.ShareGrant.viewer_user_id == user.id,
            models.ShareGrant.status.in_(("pending", "active")),
        )
        .order_by(models.ShareGrant.created_at.desc())
        .all()
    )
    as_owner = (
        db.query(models.ShareGrant)
        .filter(
            models.ShareGrant.owner_user_id == user.id,
            models.ShareGrant.status == "active",
        )
        .order_by(models.ShareGrant.accepted_at.desc())
        .all()
    )
    return {
        "as_viewer": [share_service.serialize_grant(g) for g in as_viewer],
        "as_owner": [share_service.serialize_grant(g) for g in as_owner],
    }


@router.get("/preview")
def preview_invite(
    token: str = Query(...),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    grant = db.query(models.ShareGrant).filter(models.ShareGrant.token == token).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Invite not found")
    return {
        "status": grant.status,
        "scopes": [s.strip() for s in (grant.scopes or "").split(",") if s.strip()],
        "expires_at": grant.expires_at.isoformat() if grant.expires_at else None,
        "viewer_name": grant.viewer.name if grant.viewer else None,
        "viewer_email": grant.viewer.email if grant.viewer else None,
        "invite_email": grant.invite_email,
        "is_for_you": bool(
            not grant.invite_email
            or (user.email and grant.invite_email.lower() == user.email.lower())
        ),
    }


@router.delete("/{share_id}")
def revoke(
    share_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    grant = db.query(models.ShareGrant).filter(models.ShareGrant.id == share_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Share not found")
    if user.id not in (grant.viewer_user_id, grant.owner_user_id):
        raise HTTPException(status_code=403, detail="Not allowed")
    grant.status = "revoked"
    db.commit()
    return {"status": "revoked"}


@router.get("/{owner_id}/stats")
def shared_stats(
    owner_id: str,
    date: Optional[str] = None,
    tz_offset: Optional[int] = Query(0),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    share_service.require_active_share(
        db, viewer_id=user.id, owner_id=owner_id, scope="nutrition"
    )
    target_date, window_start, window_end = share_service.local_day_window(date, tz_offset or 0)
    stat = get_or_create_daily_stats(db, owner_id, target_date)

    logs = (
        db.query(models.FoodLog)
        .filter(
            models.FoodLog.user_id == owner_id,
            models.FoodLog.created_at >= window_start,
            models.FoodLog.created_at < window_end,
        )
        .all()
    )
    calories = sum(log.calories or 0 for log in logs)
    protein = sum(log.protein or 0 for log in logs)
    carbs = sum(log.carbs or 0 for log in logs)
    fat = sum(log.fat or 0 for log in logs)

    owner = db.query(models.User).filter(models.User.id == owner_id).first()
    return {
        "user_id": owner_id,
        "name": owner.name if owner else None,
        "date": target_date.isoformat(),
        "calorie_budget": stat.calorie_budget,
        "calories_consumed": calories,
        "protein_consumed": protein,
        "carbs_consumed": carbs,
        "fat_consumed": fat,
        "protein_target": stat.protein_target,
        "carbs_target": stat.carbs_target,
        "fat_target": stat.fat_target,
    }


@router.get("/{owner_id}/history")
def shared_history(
    owner_id: str,
    date: Optional[str] = None,
    tz_offset: Optional[int] = Query(0),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    share_service.require_active_share(
        db, viewer_id=user.id, owner_id=owner_id, scope="nutrition"
    )
    query = db.query(models.FoodLog).filter(models.FoodLog.user_id == owner_id)
    if date:
        _, window_start, window_end = share_service.local_day_window(date, tz_offset or 0)
        query = query.filter(
            models.FoodLog.created_at >= window_start,
            models.FoodLog.created_at < window_end,
        )
    logs = query.order_by(models.FoodLog.created_at.desc()).limit(50).all()
    return [
        {
            "id": log.id,
            "meal_name": log.name,
            "name_en": log.name_en,
            "name_fr": log.name_fr,
            "name_ar": log.name_ar,
            "calories": log.calories,
            "image_url": resolve_media_url(log.image_url),
            "protein": log.protein,
            "carbs": log.carbs,
            "fat": log.fat,
            "ingredients": log.ingredients,
            "created_at": log.created_at.isoformat() + "Z" if log.created_at else None,
        }
        for log in logs
    ]


@router.get("/{owner_id}/exercises")
def shared_exercises(
    owner_id: str,
    date: Optional[str] = None,
    tz_offset: Optional[int] = Query(0),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    share_service.require_active_share(
        db, viewer_id=user.id, owner_id=owner_id, scope="exercises"
    )
    query = db.query(models.ExerciseLog).filter(models.ExerciseLog.user_id == owner_id)
    if date:
        target_date, window_start, window_end = share_service.local_day_window(
            date, tz_offset or 0
        )
        query = query.filter(
            or_(
                models.ExerciseLog.log_date == target_date,
                and_(
                    models.ExerciseLog.log_date.is_(None),
                    models.ExerciseLog.date >= window_start,
                    models.ExerciseLog.date < window_end,
                ),
            )
        )
    exercises = query.order_by(models.ExerciseLog.date.desc()).limit(50).all()
    return [
        {
            "id": ex.id,
            "name": ex.name,
            "duration_minutes": ex.duration_minutes,
            "calories_burned": ex.calories_burned,
            "date": ex.date.isoformat() if ex.date else None,
            "log_date": ex.log_date.isoformat() if ex.log_date else None,
            "image_url": resolve_media_url(ex.image_url) if ex.image_url else None,
            "sets_summary": ex.sets_summary,
        }
        for ex in exercises
    ]


@router.get("/{owner_id}/progress-photos")
def shared_progress_photos(
    owner_id: str,
    date: Optional[str] = None,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Body Journal photos for a shared owner (requires body_journal scope)."""
    share_service.require_active_share(
        db, viewer_id=user.id, owner_id=owner_id, scope="body_journal"
    )
    query = db.query(models.ProgressPhoto).filter(
        models.ProgressPhoto.user_id == owner_id
    )
    if date:
        try:
            target = datetime.datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date") from None
        query = query.filter(models.ProgressPhoto.photo_date == target)

    photos = (
        query.order_by(
            models.ProgressPhoto.photo_date.desc(),
            models.ProgressPhoto.created_at.desc(),
        )
        .limit(200)
        .all()
    )
    return [
        {
            "id": p.id,
            "image_url": resolve_media_url(p.image_url),
            "note": p.note,
            "pose": p.pose,
            "photo_date": p.photo_date.isoformat() if p.photo_date else None,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        }
        for p in photos
    ]


@router.get("/{owner_id}/health")
def shared_health(
    owner_id: str,
    date: Optional[str] = None,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Health Sync snapshot for a shared owner (requires health_sync scope)."""
    share_service.require_active_share(
        db, viewer_id=user.id, owner_id=owner_id, scope="health_sync"
    )
    if date:
        try:
            day = datetime.datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date") from None
    else:
        day = datetime.datetime.utcnow().date()

    row = (
        db.query(models.HealthDay)
        .filter(
            models.HealthDay.user_id == owner_id,
            models.HealthDay.day == day,
        )
        .first()
    )
    if not row:
        return {
            "date": day.isoformat(),
            "steps": None,
            "active_calories": None,
            "weight_kg": None,
            "updated_at": None,
        }
    return {
        "date": row.day.isoformat() if row.day else day.isoformat(),
        "steps": row.steps,
        "active_calories": row.active_calories,
        "weight_kg": row.weight_kg,
        "updated_at": row.updated_at.isoformat() if row.updated_at else None,
    }
