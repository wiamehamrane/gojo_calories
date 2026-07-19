import datetime
import math
import re
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException

import models

_EARTH_RADIUS_KM = 6371.0
_PHONE_DIGITS_RE = re.compile(r"\D+")


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    rlat1, rlon1, rlat2, rlon2 = map(math.radians, (lat1, lon1, lat2, lon2))
    dlat = rlat2 - rlat1
    dlon = rlon2 - rlon1
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlon / 2) ** 2
    )
    return _EARTH_RADIUS_KM * 2 * math.asin(math.sqrt(a))


def normalize_phone_digits(phone: Optional[str]) -> str:
    if not phone:
        return ""
    digits = _PHONE_DIGITS_RE.sub("", phone.strip())
    if digits.startswith("00"):
        digits = digits[2:]
    return digits


def whatsapp_url(phone: Optional[str]) -> Optional[str]:
    digits = normalize_phone_digits(phone)
    if not digits:
        return None
    return f"https://wa.me/{digits}"


def call_uri(phone: Optional[str]) -> Optional[str]:
    raw = (phone or "").strip()
    if not raw:
        return None
    digits = normalize_phone_digits(raw)
    if not digits:
        return None
    if raw.startswith("+"):
        return f"tel:+{digits}"
    return f"tel:{digits}"


def as_str_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if v is not None and str(v).strip()]
    if isinstance(value, str) and value.strip():
        return [value.strip()]
    return []


def coach_subscription_active(coach: models.Coach, *, allow_skip: bool) -> bool:
    if allow_skip:
        return True
    if not coach.subscription_expires_at:
        return False
    return coach.subscription_expires_at > datetime.datetime.utcnow()


def get_or_create_coach_row(db, user: models.User) -> models.Coach:
    coach = (
        db.query(models.Coach)
        .filter(models.Coach.user_id == user.id)
        .first()
    )
    if coach:
        return coach
    coach = models.Coach(user_id=user.id, is_active=False)
    db.add(coach)
    db.flush()
    return coach


def apply_coach_subscription(
    db,
    user: models.User,
    *,
    product_id: str,
    plan_id: Optional[str],
    expires_at: datetime.datetime,
    is_active: bool,
    source: str,
    apple_original_transaction_id: Optional[str] = None,
    google_order_id: Optional[str] = None,
    google_purchase_token: Optional[str] = None,
) -> Dict[str, Any]:
    """Persist coach IAP state. Does not auto-list the coach (activate still required)."""
    if apple_original_transaction_id:
        conflict = (
            db.query(models.Coach)
            .filter(
                models.Coach.apple_original_transaction_id
                == apple_original_transaction_id,
                models.Coach.user_id != user.id,
            )
            .first()
        )
        if conflict:
            raise HTTPException(
                status_code=400,
                detail="This subscription is already associated with another account.",
            )

    if google_order_id:
        conflict = (
            db.query(models.Coach)
            .filter(
                models.Coach.google_order_id == google_order_id,
                models.Coach.user_id != user.id,
            )
            .first()
        )
        if conflict:
            raise HTTPException(
                status_code=400,
                detail="This subscription is already associated with another account.",
            )

    coach = get_or_create_coach_row(db, user)
    coach.subscription_plan = plan_id
    coach.subscription_expires_at = expires_at
    coach.subscription_source = source
    if apple_original_transaction_id:
        coach.apple_original_transaction_id = apple_original_transaction_id
    if google_order_id:
        coach.google_order_id = google_order_id
    if google_purchase_token:
        coach.google_purchase_token = google_purchase_token

    if not is_active:
        coach.is_active = False
        user.is_coach = False

    coach.updated_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(coach)

    return {
        "status": "success",
        "subscription_active": is_active,
        "expires_at": expires_at.isoformat(),
        "product_id": product_id,
        "type": "coach",
    }


def serialize_work(work: models.CoachWork) -> Dict[str, Any]:
    from s3_utils import resolve_media_url

    return {
        "id": work.id,
        "before_url": resolve_media_url(work.before_url),
        "after_url": resolve_media_url(work.after_url),
        "caption": work.caption,
        "created_at": work.created_at.isoformat() if work.created_at else None,
    }


def serialize_public(
    coach: models.Coach,
    user: Optional[models.User] = None,
    *,
    distance_km: Optional[float] = None,
    include_works: bool = False,
) -> Dict[str, Any]:
    from s3_utils import resolve_media_url

    owner = user or coach.user
    raw_avatar = coach.photo_url or (owner.avatar_url if owner else None)
    payload: Dict[str, Any] = {
        "id": coach.id,
        "user_id": coach.user_id,
        "name": owner.name if owner else None,
        "avatar_url": resolve_media_url(raw_avatar) if raw_avatar else None,
        "bio": coach.bio,
        "specialties": as_str_list(coach.specialties),
        "gender": coach.gender,
        "experience_years": coach.experience_years,
        "latitude": coach.latitude,
        "longitude": coach.longitude,
        "city": coach.city,
        "languages": as_str_list(coach.languages),
        "coaching_mode": coach.coaching_mode,
        "is_active": bool(coach.is_active),
        "created_at": coach.created_at.isoformat() if coach.created_at else None,
    }
    if distance_km is not None:
        payload["distance_km"] = round(distance_km, 2)
    if include_works:
        works = list(getattr(coach, "works", None) or [])
        payload["works"] = [serialize_work(w) for w in works]
    return payload


def serialize_owner(coach: models.Coach, user: models.User) -> Dict[str, Any]:
    payload = serialize_public(coach, user)
    payload.update(
        {
            "phone": coach.phone,
            "subscription_plan": coach.subscription_plan,
            "subscription_expires_at": (
                coach.subscription_expires_at.isoformat()
                if coach.subscription_expires_at
                else None
            ),
            "subscription_source": coach.subscription_source,
            "user_is_coach": bool(user.is_coach),
            "user_has_paid": bool(user.has_paid),
        }
    )
    return payload


def serialize_contact(coach: models.Coach) -> Dict[str, Any]:
    return {
        "coach_id": coach.id,
        "phone": coach.phone,
        "call_uri": call_uri(coach.phone),
        "whatsapp_url": whatsapp_url(coach.phone),
    }


def profile_ready_for_activation(coach: models.Coach) -> Tuple[bool, Optional[str]]:
    if not (coach.phone or "").strip():
        return False, "Phone number is required"
    if coach.latitude is None or coach.longitude is None:
        return False, "Location is required"
    return True, None
