"""Public user profiles (limited fields when profile_public is True)."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from database import get_db
from models import SharedMeal, User
from security import get_current_user

router = APIRouter()


@router.get("/{user_id}/profile")
def get_public_profile(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or user.is_banned:
        raise HTTPException(status_code=404, detail="User not found")

    is_self = user.id == current_user.id
    is_public = bool(getattr(user, "profile_public", True))

    if not is_public and not is_self:
        return {
            "id": user.id,
            "name": user.name or "Gojo member",
            "is_public": False,
            "is_self": False,
        }

    meals_count = (
        db.query(func.count(SharedMeal.id))
        .filter(SharedMeal.user_id == user.id)
        .scalar()
        or 0
    )

    return {
        "id": user.id,
        "name": user.name or "Gojo member",
        "is_public": True,
        "is_self": is_self,
        "age": user.age,
        "gender": user.gender,
        "meals_shared": int(meals_count),
        "phone": user.phone if (is_self or user.share_phone) else None,
        "created_at": user.created_at.isoformat() if getattr(user, "created_at", None) else None,
    }
