import math
import re
from typing import Any, Dict, List, Optional, Tuple

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


def serialize_public(
    coach: models.Coach,
    user: Optional[models.User] = None,
    *,
    distance_km: Optional[float] = None,
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
    return payload


def serialize_owner(coach: models.Coach, user: models.User) -> Dict[str, Any]:
    payload = serialize_public(coach, user)
    payload.update(
        {
            "phone": coach.phone,
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


def serialize_post_media(item: models.CoachPostMedia) -> Dict[str, Any]:
    from s3_utils import resolve_media_url

    return {
        "id": item.id,
        "media_type": item.media_type,
        "url": resolve_media_url(item.url),
        "thumbnail_url": (
            resolve_media_url(item.thumbnail_url) if item.thumbnail_url else None
        ),
        "role": item.role,
        "sort_order": item.sort_order,
    }


def serialize_post(post: models.CoachPost) -> Dict[str, Any]:
    media = sorted(list(getattr(post, "media", None) or []), key=lambda m: m.sort_order)
    return {
        "id": post.id,
        "coach_id": post.coach_id,
        "post_type": post.post_type,
        "caption": post.caption,
        "created_at": post.created_at.isoformat() if post.created_at else None,
        "media": [serialize_post_media(m) for m in media],
    }


def follower_count(db, user_id: str) -> int:
    return (
        db.query(models.UserFollow)
        .filter(models.UserFollow.following_id == user_id)
        .count()
    )


def following_count(db, user_id: str) -> int:
    return (
        db.query(models.UserFollow)
        .filter(models.UserFollow.follower_id == user_id)
        .count()
    )


def is_following(db, follower_id: str, following_id: str) -> bool:
    if not follower_id or not following_id or follower_id == following_id:
        return False
    return (
        db.query(models.UserFollow)
        .filter(
            models.UserFollow.follower_id == follower_id,
            models.UserFollow.following_id == following_id,
        )
        .first()
        is not None
    )


def posts_count(db, coach_id: str) -> int:
    return (
        db.query(models.CoachPost)
        .filter(models.CoachPost.coach_id == coach_id)
        .count()
    )


def serialize_social_profile(
    db,
    coach: models.Coach,
    viewer: models.User,
    *,
    include_light_info: bool = True,
) -> Dict[str, Any]:
    """Instagram-style profile header payload (counts + light info)."""
    owner = coach.user
    base = serialize_public(coach, owner)
    base.update(
        {
            "posts_count": posts_count(db, coach.id),
            "followers_count": follower_count(db, coach.user_id),
            "following_count": following_count(db, coach.user_id),
            "is_following": is_following(db, viewer.id, coach.user_id),
            "is_owner": viewer.id == coach.user_id,
        }
    )
    if not include_light_info:
        # Keep payload lean if needed later.
        for key in (
            "experience_years",
            "latitude",
            "longitude",
            "languages",
            "coaching_mode",
            "gender",
        ):
            base.pop(key, None)
    return base
