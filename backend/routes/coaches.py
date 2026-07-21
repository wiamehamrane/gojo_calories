import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session, joinedload

from database import get_db
import models
from security import get_current_user
from services import coach_service
from s3_utils import MediaUploadError, delete_media, upload_image_to_s3_key, upload_media_to_s3_key

router = APIRouter()

_VALID_GENDERS = {"male", "female"}
_VALID_COACHING_MODES = {"in_person", "online", "both"}
_VALID_POST_TYPES = {"image", "video", "before_after"}
_MAX_PAGE_SIZE = 50
_MAX_COACH_WORKS = 12
_MAX_COACH_POSTS = 100
_MAX_UPLOAD_BYTES = 80 * 1024 * 1024  # 80 MB (videos)


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

    coach.is_active = True
    coach.updated_at = datetime.datetime.utcnow()
    user.is_coach = True
    db.commit()
    db.refresh(coach)
    return coach_service.serialize_owner(coach, user)


@router.post("/deactivate")
def deactivate_coach(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Hide the coach from search. Profile is kept; can activate again later."""
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")

    coach.is_active = False
    coach.updated_at = datetime.datetime.utcnow()
    # Keep user.is_coach so they can manage / re-list without re-onboarding.
    db.commit()
    db.refresh(coach)
    return coach_service.serialize_owner(coach, user)


async def _read_image_upload(file: UploadFile) -> bytes:
    content_type = (file.content_type or "").lower()
    if content_type and not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(contents) > _MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=400, detail="File too large")
    return contents


async def _read_media_upload(
    file: UploadFile,
    *,
    allow_image: bool = True,
    allow_video: bool = False,
) -> tuple[bytes, str, str]:
    content_type = (file.content_type or "").lower().strip() or "application/octet-stream"
    is_image = content_type.startswith("image/")
    is_video = content_type.startswith("video/")
    if is_image and not allow_image:
        raise HTTPException(status_code=400, detail="Image not allowed for this post type")
    if is_video and not allow_video:
        raise HTTPException(status_code=400, detail="Video not allowed for this post type")
    if not is_image and not is_video:
        raise HTTPException(status_code=400, detail="File must be an image or video")
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(contents) > _MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=400, detail="File too large")
    media_type = "video" if is_video else "image"
    return contents, content_type, media_type


@router.get("/me/works")
def list_my_coach_works(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")
    works = (
        db.query(models.CoachWork)
        .filter(models.CoachWork.coach_id == coach.id)
        .order_by(models.CoachWork.created_at.desc())
        .all()
    )
    return {"items": [coach_service.serialize_work(w) for w in works]}


@router.post("/me/works")
async def create_my_coach_work(
    before: UploadFile = File(...),
    after: UploadFile = File(...),
    caption: Optional[str] = Form(None),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")

    count = (
        db.query(models.CoachWork)
        .filter(models.CoachWork.coach_id == coach.id)
        .count()
    )
    if count >= _MAX_COACH_WORKS:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum of {_MAX_COACH_WORKS} portfolio items reached",
        )

    before_bytes = await _read_image_upload(before)
    after_bytes = await _read_image_upload(after)

    try:
        before_key = upload_image_to_s3_key(
            before_bytes,
            before.content_type or "image/jpeg",
            prefix="coach_works/",
        )
        after_key = upload_image_to_s3_key(
            after_bytes,
            after.content_type or "image/jpeg",
            prefix="coach_works/",
        )
    except MediaUploadError as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

    clean_caption = (caption or "").strip() or None
    work = models.CoachWork(
        coach_id=coach.id,
        before_url=before_key,
        after_url=after_key,
        caption=clean_caption,
    )
    db.add(work)
    db.commit()
    db.refresh(work)
    return coach_service.serialize_work(work)


@router.delete("/me/works/{work_id}")
def delete_my_coach_work(
    work_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")

    work = (
        db.query(models.CoachWork)
        .filter(
            models.CoachWork.id == work_id,
            models.CoachWork.coach_id == coach.id,
        )
        .first()
    )
    if not work:
        raise HTTPException(status_code=404, detail="Portfolio item not found")

    before_url = work.before_url
    after_url = work.after_url
    db.delete(work)
    db.commit()
    delete_media(before_url)
    delete_media(after_url)
    return {"ok": True}


@router.get("/me/posts")
def list_my_coach_posts(
    tab: Optional[str] = Query("all"),
    page: int = Query(1, ge=1),
    page_size: int = Query(18, ge=1, le=_MAX_PAGE_SIZE),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")
    return _list_coach_posts(db, coach.id, tab=tab, page=page, page_size=page_size)


@router.post("/me/posts")
async def create_my_coach_post(
    post_type: str = Form(...),
    caption: Optional[str] = Form(None),
    media: Optional[UploadFile] = File(None),
    thumbnail: Optional[UploadFile] = File(None),
    before: Optional[UploadFile] = File(None),
    after: Optional[UploadFile] = File(None),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")
    if not user.is_coach:
        raise HTTPException(status_code=403, detail="Activate your coach profile first")

    ptype = (post_type or "").strip().lower()
    if ptype not in _VALID_POST_TYPES:
        raise HTTPException(
            status_code=400,
            detail="post_type must be image, video, or before_after",
        )

    count = (
        db.query(models.CoachPost)
        .filter(models.CoachPost.coach_id == coach.id)
        .count()
    )
    if count >= _MAX_COACH_POSTS:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum of {_MAX_COACH_POSTS} posts reached",
        )

    clean_caption = (caption or "").strip() or None
    media_rows: List[models.CoachPostMedia] = []
    uploaded_keys: List[str] = []

    try:
        if ptype == "before_after":
            if before is None or after is None:
                raise HTTPException(
                    status_code=400,
                    detail="before and after images are required",
                )
            before_bytes = await _read_image_upload(before)
            after_bytes = await _read_image_upload(after)
            before_key = upload_image_to_s3_key(
                before_bytes,
                before.content_type or "image/jpeg",
                prefix="coach_posts/",
            )
            uploaded_keys.append(before_key)
            after_key = upload_image_to_s3_key(
                after_bytes,
                after.content_type or "image/jpeg",
                prefix="coach_posts/",
            )
            uploaded_keys.append(after_key)
            media_rows = [
                models.CoachPostMedia(
                    media_type="image",
                    url=before_key,
                    role="before",
                    sort_order=0,
                ),
                models.CoachPostMedia(
                    media_type="image",
                    url=after_key,
                    role="after",
                    sort_order=1,
                ),
            ]
        else:
            if media is None:
                raise HTTPException(status_code=400, detail="media file is required")
            allow_video = ptype == "video"
            allow_image = ptype == "image"
            raw, content_type, media_kind = await _read_media_upload(
                media,
                allow_image=allow_image,
                allow_video=allow_video,
            )
            if ptype == "video" and media_kind != "video":
                raise HTTPException(status_code=400, detail="Video file required")
            if ptype == "image" and media_kind != "image":
                raise HTTPException(status_code=400, detail="Image file required")
            key = upload_media_to_s3_key(
                raw,
                content_type,
                prefix="coach_posts/",
                default_ext="mp4" if media_kind == "video" else "jpg",
            )
            uploaded_keys.append(key)
            thumb_key = None
            if media_kind == "video" and thumbnail is not None:
                thumb_bytes = await _read_image_upload(thumbnail)
                thumb_key = upload_image_to_s3_key(
                    thumb_bytes,
                    thumbnail.content_type or "image/jpeg",
                    prefix="coach_posts/thumbs/",
                )
                uploaded_keys.append(thumb_key)
            media_rows = [
                models.CoachPostMedia(
                    media_type=media_kind,
                    url=key,
                    thumbnail_url=thumb_key,
                    role="single",
                    sort_order=0,
                )
            ]
    except MediaUploadError as e:
        for key in uploaded_keys:
            delete_media(key)
        raise HTTPException(status_code=500, detail=str(e)) from e
    except HTTPException:
        for key in uploaded_keys:
            delete_media(key)
        raise

    post = models.CoachPost(
        coach_id=coach.id,
        post_type=ptype,
        caption=clean_caption,
    )
    db.add(post)
    db.flush()
    for row in media_rows:
        row.post_id = post.id
        db.add(row)
    db.commit()
    db.refresh(post)
    post = (
        db.query(models.CoachPost)
        .options(joinedload(models.CoachPost.media))
        .filter(models.CoachPost.id == post.id)
        .first()
    )
    return coach_service.serialize_post(post)


@router.delete("/me/posts/{post_id}")
def delete_my_coach_post(
    post_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_own_coach(db, user.id)
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")

    post = (
        db.query(models.CoachPost)
        .options(joinedload(models.CoachPost.media))
        .filter(
            models.CoachPost.id == post_id,
            models.CoachPost.coach_id == coach.id,
        )
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    media_urls: List[str] = []
    for m in post.media or []:
        media_urls.append(m.url)
        if m.thumbnail_url:
            media_urls.append(m.thumbnail_url)
    db.delete(post)
    db.commit()
    for url in media_urls:
        delete_media(url)
    return {"ok": True}


def _list_coach_posts(
    db: Session,
    coach_id: str,
    *,
    tab: Optional[str],
    page: int,
    page_size: int,
):
    tab_key = (tab or "all").strip().lower()
    query = (
        db.query(models.CoachPost)
        .options(joinedload(models.CoachPost.media))
        .filter(models.CoachPost.coach_id == coach_id)
    )
    if tab_key == "images":
        query = query.filter(models.CoachPost.post_type.in_(["image", "before_after"]))
    elif tab_key == "videos":
        query = query.filter(models.CoachPost.post_type == "video")
    elif tab_key not in ("all", ""):
        raise HTTPException(status_code=400, detail="tab must be all, images, or videos")

    total = query.count()
    rows = (
        query.order_by(models.CoachPost.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return {
        "items": [coach_service.serialize_post(p) for p in rows],
        "page": page,
        "page_size": page_size,
        "total": total,
        "has_more": (page * page_size) < total,
    }


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


def _get_coach_for_viewer(
    db: Session, coach_id: str, viewer: models.User
) -> models.Coach:
    """Public listing OR own coach profile (even if soft-hidden)."""
    coach = (
        db.query(models.Coach)
        .options(joinedload(models.Coach.user))
        .filter(models.Coach.id == coach_id)
        .first()
    )
    if not coach or not coach.user:
        raise HTTPException(status_code=404, detail="Coach not found")
    if coach.user_id == viewer.id:
        return coach
    if coach.is_active and coach.user.is_coach:
        return coach
    raise HTTPException(status_code=404, detail="Coach not found")


@router.get("/{coach_id}/social")
def get_coach_social_profile(
    coach_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    coach = _get_coach_for_viewer(db, coach_id, user)
    return coach_service.serialize_social_profile(db, coach, user)


@router.get("/{coach_id}/posts")
def list_coach_posts(
    coach_id: str,
    tab: Optional[str] = Query("all"),
    page: int = Query(1, ge=1),
    page_size: int = Query(18, ge=1, le=_MAX_PAGE_SIZE),
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _get_coach_for_viewer(db, coach_id, user)
    return _list_coach_posts(db, coach_id, tab=tab, page=page, page_size=page_size)


@router.get("/{coach_id}")
def get_coach_public(
    coach_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del user
    coach = (
        db.query(models.Coach)
        .options(
            joinedload(models.Coach.user),
            joinedload(models.Coach.works),
        )
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
    return coach_service.serialize_public(
        coach, coach.user, include_works=True
    )


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
