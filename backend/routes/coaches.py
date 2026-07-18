import datetime
import os
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session, joinedload

from database import get_db
import models
from security import get_current_user
from services import coach_service

router = APIRouter()

DEV_MODE = os.getenv("DEV_MODE", "false").lower() == "true"
# Explicit only — does NOT follow DEV_MODE. Set true in .env to bypass coach IAP locally.
SKIP_COACH_PAYMENT = os.getenv("SKIP_COACH_PAYMENT", "false").lower() == "true"

_VALID_GENDERS = {"male", "female"}
_VALID_COACHING_MODES = {"in_person", "online", "both"}
_MAX_PAGE_SIZE = 50


class CoachProfileUpsert(BaseModel):
    bio: Optional[str] = None
    specialties: Optional[List[str]] = None
    gender: Optional[str] = None
    experience_years: Optional[int] = Field(default=None, ge=0, le=80)
    photo_url: Optional[str] = None
    phone: Optional[str] = None
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    city: Optional[str] = None
    languages: Optional[List[str]] = None
    coaching_mode: Optional[str] = None


def _normalize_gender(value: Optional[str]) -> Optional[str]:
    if value is None or not str(value).strip():
        return None
    gender = str(value).strip().lower()
    if gender not in _VALID_GENDERS:
        raise HTTPException(status_code=400, detail="gender must be male or female")
    return gender


def _normalize_coaching_mode(value: Optional[str]) -> Optional[str]:
    if value is None or not str(value).strip():
        return None
    mode = str(value).strip().lower()
    if mode not in _VALID_COACHING_MODES:
        raise HTTPException(
            status_code=400,
            detail="coaching_mode must be in_person, online, or both",
        )
    return mode


def _clean_str_list(values: Optional[List[str]]) -> Optional[List[str]]:
    if values is None:
        return None
    cleaned = [str(v).strip() for v in values if v is not None and str(v).strip()]
    return cleaned


def _get_own_coach(db: Session, user_id: str) -> Optional[models.Coach]:
    return (
        db.query(models.Coach)
        .options(joinedload(models.Coach.user))
        .filter(models.Coach.user_id == user_id)
        .first()
    )


def _require_active_listed_coach(db: Session, coach_id: str) -> models.Coach:
    coach = (
        db.query(models.Coach)
        .options(joinedload(models.Coach.user))
        .filter(models.Coach.id == coach_id)
        .first()
    )
    if (
        not coach
        or not coach.is_active
        or not coach.user
        or not coach.user.is_coach
    ):
        raise HTTPException(status_code=404, detail="Coach not found")
    return coach


@router.get("/me")
def get_my_coach_profile(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        return {
            "profile": None,
            "user_is_coach": bool(user.is_coach),
            "user_has_paid": bool(user.has_paid),
        }
    return {
        "profile": coach_service.serialize_owner(coach, user),
        "user_is_coach": bool(user.is_coach),
        "user_has_paid": bool(user.has_paid),
    }


@router.put("/me")
def upsert_my_coach_profile(
    body: CoachProfileUpsert,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not user.has_paid:
        raise HTTPException(
            status_code=403,
            detail="Pro subscription required to become a coach",
        )

    coach = _get_own_coach(db, user.id)
    if not coach:
        coach = models.Coach(user_id=user.id, is_active=False)
        db.add(coach)

    if body.bio is not None:
        coach.bio = body.bio.strip() or None
    if body.specialties is not None:
        coach.specialties = _clean_str_list(body.specialties)
    if body.gender is not None:
        coach.gender = _normalize_gender(body.gender)
    if body.experience_years is not None:
        coach.experience_years = body.experience_years
    if body.photo_url is not None:
        coach.photo_url = body.photo_url.strip() or None
    if body.phone is not None:
        coach.phone = body.phone.strip() or None
    if body.latitude is not None:
        coach.latitude = body.latitude
    if body.longitude is not None:
        coach.longitude = body.longitude
    if body.city is not None:
        coach.city = body.city.strip() or None
    if body.languages is not None:
        coach.languages = _clean_str_list(body.languages)
    if body.coaching_mode is not None:
        coach.coaching_mode = _normalize_coaching_mode(body.coaching_mode)

    coach.updated_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(coach)
    return coach_service.serialize_owner(coach, user)


@router.post("/activate")
def activate_coach(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not user.has_paid:
        raise HTTPException(
            status_code=403,
            detail="Pro subscription required to become a coach",
        )

    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=400, detail="Create a coach profile first")

    ready, reason = coach_service.profile_ready_for_activation(coach)
    if not ready:
        raise HTTPException(status_code=400, detail=reason)

    if not coach_service.coach_subscription_active(
        coach, allow_skip=SKIP_COACH_PAYMENT
    ):
        raise HTTPException(
            status_code=402,
            detail="Coach subscription required",
        )

    coach.is_active = True
    coach.updated_at = datetime.datetime.utcnow()
    user.is_coach = True
    db.commit()
    db.refresh(coach)
    return coach_service.serialize_owner(coach, user)


@router.get("/search")
def search_coaches(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(25, gt=0, le=500),
    specialty: Optional[str] = Query(None),
    gender: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(5, ge=1, le=_MAX_PAGE_SIZE),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del user
    gender_filter = _normalize_gender(gender) if gender else None
    specialty_filter = (specialty or "").strip().lower() or None

    rows = (
        db.query(models.Coach)
        .options(joinedload(models.Coach.user))
        .join(models.User, models.Coach.user_id == models.User.id)
        .filter(
            models.Coach.is_active.is_(True),
            models.User.is_coach.is_(True),
            models.Coach.latitude.isnot(None),
            models.Coach.longitude.isnot(None),
        )
        .all()
    )

    matched: List[tuple] = []
    for coach in rows:
        if gender_filter and (coach.gender or "").lower() != gender_filter:
            continue
        if specialty_filter:
            specs = [s.lower() for s in coach_service.as_str_list(coach.specialties)]
            if specialty_filter not in specs:
                continue
        distance = coach_service.haversine_km(
            lat, lng, float(coach.latitude), float(coach.longitude)
        )
        if distance > radius_km:
            continue
        matched.append((coach, distance))

    matched.sort(key=lambda item: item[1])
    total = len(matched)
    start = (page - 1) * page_size
    end = start + page_size
    page_rows = matched[start:end]

    return {
        "items": [
            coach_service.serialize_public(coach, coach.user, distance_km=distance)
            for coach, distance in page_rows
        ],
        "page": page,
        "page_size": page_size,
        "total": total,
        "has_more": end < total,
    }


@router.get("/{coach_id}")
def get_coach_public(
    coach_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del user
    coach = _require_active_listed_coach(db, coach_id)
    return coach_service.serialize_public(coach, coach.user)


@router.post("/{coach_id}/contact")
def contact_coach(
    coach_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del user
    coach = _require_active_listed_coach(db, coach_id)
    if not (coach.phone or "").strip():
        raise HTTPException(status_code=404, detail="Coach contact unavailable")
    return coach_service.serialize_contact(coach)
