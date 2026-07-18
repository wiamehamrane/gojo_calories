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


class ProgressPhotoResponse(BaseModel):
    id: str
    image_url: str
    note: Optional[str]
    photo_date: date
    created_at: datetime

    class Config:
        from_attributes = True


def _photo_view(photo: ProgressPhoto) -> dict:
    return {
        "id": photo.id,
        "image_url": resolve_media_url(photo.image_url),
        "note": photo.note,
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
        .limit(365)
        .all()
    )
    return [_photo_view(p) for p in photos]


@router.post("", response_model=ProgressPhotoResponse, status_code=status.HTTP_201_CREATED)
async def create_progress_photo(
    note: Optional[str] = Form(None),
    photo_date: Optional[str] = Form(None),
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

    image_key = upload_image_to_s3_key(
        contents, file.content_type or "image/jpeg", prefix="progress_photos/"
    )

    photo = ProgressPhoto(
        user_id=current_user.id,
        image_url=image_key,
        note=(note or "").strip() or None,
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
