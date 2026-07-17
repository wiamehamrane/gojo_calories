"""Public user profiles (limited fields when profile_public is True)."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import SharedMeal, User
from routes.shared_meals import (
    _counts_for_meals,
    _liked_ids_for_user,
    _meal_view,
    _starred_ids_for_user,
)
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
            "meals": [],
        }

    meals = (
        db.query(SharedMeal)
        .filter(SharedMeal.user_id == user.id)
        .order_by(SharedMeal.created_at.desc())
        .limit(100)
        .all()
    )
    meal_ids = [m.id for m in meals]
    starred = _starred_ids_for_user(db, current_user.id, meal_ids)
    liked = _liked_ids_for_user(db, current_user.id, meal_ids)
    likes_map, comments_map = _counts_for_meals(db, meal_ids)
    author_public = bool(getattr(user, "profile_public", True))

    meal_views = [
        _meal_view(
            meal,
            user.name,
            is_starred=meal.id in starred,
            is_liked=meal.id in liked,
            likes_count=likes_map.get(meal.id, 0),
            comments_count=comments_map.get(meal.id, 0),
            author_profile_public=author_public,
        )
        for meal in meals
    ]

    return {
        "id": user.id,
        "name": user.name or "Gojo member",
        "is_public": True,
        "is_self": is_self,
        "age": user.age,
        "gender": user.gender,
        "meals_shared": len(meal_views),
        "meals": meal_views,
        "created_at": user.created_at.isoformat() if getattr(user, "created_at", None) else None,
    }
