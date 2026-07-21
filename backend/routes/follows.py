from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database import get_db
import models
from security import get_current_user
from services import coach_service
from s3_utils import resolve_media_url

router = APIRouter()


def _serialize_user_card(user: models.User) -> dict:
    return {
        "id": user.id,
        "name": user.name,
        "avatar_url": resolve_media_url(user.avatar_url) if user.avatar_url else None,
        "is_coach": bool(user.is_coach),
    }


@router.post("/{user_id}")
def follow_user(
    user_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot follow yourself")

    target = db.query(models.User).filter(models.User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    existing = (
        db.query(models.UserFollow)
        .filter(
            models.UserFollow.follower_id == current_user.id,
            models.UserFollow.following_id == user_id,
        )
        .first()
    )
    if existing:
        return {
            "ok": True,
            "following": True,
            "followers_count": coach_service.follower_count(db, user_id),
            "following_count": coach_service.following_count(db, current_user.id),
        }

    db.add(
        models.UserFollow(
            follower_id=current_user.id,
            following_id=user_id,
        )
    )
    db.commit()
    return {
        "ok": True,
        "following": True,
        "followers_count": coach_service.follower_count(db, user_id),
        "following_count": coach_service.following_count(db, current_user.id),
    }


@router.delete("/{user_id}")
def unfollow_user(
    user_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = (
        db.query(models.UserFollow)
        .filter(
            models.UserFollow.follower_id == current_user.id,
            models.UserFollow.following_id == user_id,
        )
        .first()
    )
    if row:
        db.delete(row)
        db.commit()
    return {
        "ok": True,
        "following": False,
        "followers_count": coach_service.follower_count(db, user_id),
        "following_count": coach_service.following_count(db, current_user.id),
    }


@router.get("/{user_id}/status")
def follow_status(
    user_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return {
        "user_id": user_id,
        "is_following": coach_service.is_following(db, current_user.id, user_id),
        "followers_count": coach_service.follower_count(db, user_id),
        "following_count": coach_service.following_count(db, user_id),
    }


@router.get("/{user_id}/followers")
def list_followers(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=50),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del current_user
    target = db.query(models.User).filter(models.User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    query = (
        db.query(models.UserFollow)
        .filter(models.UserFollow.following_id == user_id)
        .order_by(models.UserFollow.created_at.desc())
    )
    total = query.count()
    rows = query.offset((page - 1) * page_size).limit(page_size).all()
    users: List[dict] = []
    for row in rows:
        u = db.query(models.User).filter(models.User.id == row.follower_id).first()
        if u:
            users.append(_serialize_user_card(u))
    return {
        "items": users,
        "page": page,
        "page_size": page_size,
        "total": total,
        "has_more": (page * page_size) < total,
    }


@router.get("/{user_id}/following")
def list_following(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=50),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del current_user
    target = db.query(models.User).filter(models.User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    query = (
        db.query(models.UserFollow)
        .filter(models.UserFollow.follower_id == user_id)
        .order_by(models.UserFollow.created_at.desc())
    )
    total = query.count()
    rows = query.offset((page - 1) * page_size).limit(page_size).all()
    users: List[dict] = []
    for row in rows:
        u = db.query(models.User).filter(models.User.id == row.following_id).first()
        if u:
            users.append(_serialize_user_card(u))
    return {
        "items": users,
        "page": page,
        "page_size": page_size,
        "total": total,
        "has_more": (page * page_size) < total,
    }
