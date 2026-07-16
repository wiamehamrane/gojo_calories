"""Community shared meals.

Users share meals they prepared — a photo of the final product, macros,
ingredients, and cooking instructions. The app shows them as a horizontal
row on the Events page.
"""

import json
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from database import get_db
from models import SharedMeal, User
from s3_utils import MediaUploadError, resolve_media_url, upload_image_to_s3_key
from security import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()

_MAX_MEALS_RETURNED = 50


def _meal_view(meal: SharedMeal, author_name: Optional[str]) -> dict:
    ingredients = meal.ingredients if isinstance(meal.ingredients, list) else []
    return {
        "id": meal.id,
        "user_id": meal.user_id,
        "author_name": author_name or "Gojo member",
        "name": meal.name,
        "image_url": resolve_media_url(meal.image_url),
        "ingredients": ingredients,
        "instructions": meal.instructions,
        "calories": meal.calories or 0,
        "protein": meal.protein or 0,
        "carbs": meal.carbs or 0,
        "fat": meal.fat or 0,
        "created_at": meal.created_at.isoformat() if meal.created_at else None,
    }


@router.get("")
def list_shared_meals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Latest community meals, newest first."""
    rows = (
        db.query(SharedMeal, User.name)
        .join(User, User.id == SharedMeal.user_id)
        .order_by(SharedMeal.created_at.desc())
        .limit(_MAX_MEALS_RETURNED)
        .all()
    )
    return [_meal_view(meal, author_name) for meal, author_name in rows]


@router.post("", status_code=201)
async def share_meal(
    name: str = Form(...),
    ingredients: str = Form("[]"),  # JSON array or newline/comma separated
    instructions: str = Form(""),
    calories: int = Form(0),
    protein: int = Form(0),
    carbs: int = Form(0),
    fat: int = Form(0),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    name = name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Meal name is required")

    # Accept a JSON array, or a newline/comma separated string.
    try:
        parsed = json.loads(ingredients)
        ingredient_list = parsed if isinstance(parsed, list) else []
    except (ValueError, TypeError):
        raw = ingredients.replace(",", "\n")
        ingredient_list = [line.strip() for line in raw.split("\n") if line.strip()]
    ingredient_list = [str(i).strip() for i in ingredient_list if str(i).strip()][:40]

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="A photo of the meal is required")

    try:
        image_key = upload_image_to_s3_key(
            contents, file.content_type or "image/jpeg", prefix="shared_meals/"
        )
    except MediaUploadError as e:
        logger.error("Shared meal image upload failed: %s", e)
        raise HTTPException(
            status_code=503,
            detail="Image upload failed. Media storage is temporarily unavailable.",
        ) from e

    meal = SharedMeal(
        user_id=current_user.id,
        name=name,
        image_url=image_key,
        ingredients=ingredient_list,
        instructions=instructions.strip() or None,
        calories=max(0, calories),
        protein=max(0, protein),
        carbs=max(0, carbs),
        fat=max(0, fat),
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)

    return _meal_view(meal, current_user.name)


@router.delete("/{meal_id}")
def delete_shared_meal(
    meal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
    if meal.user_id != current_user.id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="You can only delete your own meals")
    db.delete(meal)
    db.commit()
    return {"status": "success"}
