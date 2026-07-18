"""Private body progress photos.

Only the owning user can list, create, or delete their photos.
Images are stored as S3 keys in Postgres (never public).
"""

from datetime import date, datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import ProgressPhoto, User
from s3_utils import upload_image_to_s3_key, resolve_media_url
from security import get_current_user

router = APIRouter()

# The four standardized capture angles used by the guided flow.
VALID_POSES = {"front", "left", "right", "back"}


class ProgressPhotoResponse(BaseModel):
    id: str
    image_url: str
    note: Optional[str]
    pose: Optional[str]
    photo_date: date
    created_at: datetime

    class Config:
        from_attributes = True


def _photo_view(photo: ProgressPhoto) -> dict:
    return {
        "id": photo.id,
        "image_url": resolve_media_url(photo.image_url),
        "note": photo.note,
        "pose": photo.pose,
        "photo_date": photo.photo_date.isoformat() if photo.photo_date else None,
        "created_at": photo.created_at.isoformat() if photo.created_at else None,
    }


@router.get("", response_model=List[ProgressPhotoResponse])
def list_my_progress_photos(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    photos = (
        db.query(ProgressPhoto)
        .filter(ProgressPhoto.user_id == current_user.id)
        .order_by(ProgressPhoto.photo_date.desc(), ProgressPhoto.created_at.desc())
        .limit(1500)  # ~1 year of 4 daily poses
        .all()
    )
    return [_photo_view(p) for p in photos]


@router.post("", response_model=ProgressPhotoResponse, status_code=status.HTTP_201_CREATED)
async def create_progress_photo(
    note: Optional[str] = Form(None),
    photo_date: Optional[str] = Form(None),
    pose: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Photo is empty")

    parsed_date = date.today()
    if photo_date:
        try:
            parsed_date = date.fromisoformat(photo_date.strip())
        except ValueError as exc:
            raise HTTPException(
                status_code=400, detail="photo_date must be YYYY-MM-DD"
            ) from exc

    parsed_pose = None
    if pose:
        parsed_pose = pose.strip().lower()
        if parsed_pose not in VALID_POSES:
            raise HTTPException(
                status_code=400,
                detail="pose must be one of: front, left, right, back",
            )

    image_key = upload_image_to_s3_key(
        contents, file.content_type or "image/jpeg", prefix="progress_photos/"
    )

    # Guided capture is one-per-pose-per-day: replace an existing shot for the
    # same day + pose so re-taking overwrites instead of piling up duplicates.
    if parsed_pose:
        existing = (
            db.query(ProgressPhoto)
            .filter(
                ProgressPhoto.user_id == current_user.id,
                ProgressPhoto.photo_date == parsed_date,
                ProgressPhoto.pose == parsed_pose,
            )
            .first()
        )
        if existing:
            db.delete(existing)
            db.flush()

    photo = ProgressPhoto(
        user_id=current_user.id,
        image_url=image_key,
        note=(note or "").strip() or None,
        pose=parsed_pose,
        photo_date=parsed_date,
    )
    db.add(photo)
    db.commit()
    db.refresh(photo)
    return _photo_view(photo)


@router.delete("/{photo_id}")
def delete_progress_photo(
    photo_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    photo = db.query(ProgressPhoto).filter(ProgressPhoto.id == photo_id).first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    if photo.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    db.delete(photo)
    db.commit()
    return {"status": "success"}
