"""Community shared meals.

Users share meals they prepared — a photo of the final product, macros,
ingredients, and cooking instructions. Supports stars (save), likes, and
top-level comments (no replies). Comment authors can be opened if their
profile is public.
"""

import json
import logging
from typing import Dict, List, Optional, Set

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.orm import Session

from database import get_db
from models import (
    SharedMeal,
    SharedMealComment,
    SharedMealCommentLike,
    SharedMealLike,
    SharedMealStar,
    User,
)
from s3_utils import (
    MediaUploadError,
    extract_s3_key_from_url,
    resolve_media_url,
    upload_image_to_s3_key,
)
from security import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()

_MAX_MEALS_RETURNED = 50
_MAX_COMMENT_LENGTH = 500


class CommentCreate(BaseModel):
    body: str = Field(..., min_length=1, max_length=_MAX_COMMENT_LENGTH)


def _meal_view(
    meal: SharedMeal,
    author_name: Optional[str],
    *,
    is_starred: bool = False,
    is_liked: bool = False,
    likes_count: int = 0,
    comments_count: int = 0,
    author_profile_public: bool = True,
) -> dict:
    ingredients = meal.ingredients if isinstance(meal.ingredients, list) else []
    return {
        "id": meal.id,
        "user_id": meal.user_id,
        "author_name": author_name or "Gojo member",
        "author_profile_public": author_profile_public,
        "name": meal.name,
        "image_url": resolve_media_url(meal.image_url),
        "ingredients": ingredients,
        "instructions": meal.instructions,
        "calories": meal.calories or 0,
        "protein": meal.protein or 0,
        "carbs": meal.carbs or 0,
        "fat": meal.fat or 0,
        "is_starred": is_starred,
        "is_liked": is_liked,
        "likes_count": likes_count,
        "comments_count": comments_count,
        "comments_enabled": bool(getattr(meal, "comments_enabled", True)),
        "created_at": meal.created_at.isoformat() if meal.created_at else None,
    }


def _starred_ids_for_user(db: Session, user_id: str, meal_ids: List[str]) -> Set[str]:
    if not meal_ids:
        return set()
    rows = (
        db.query(SharedMealStar.shared_meal_id)
        .filter(
            SharedMealStar.user_id == user_id,
            SharedMealStar.shared_meal_id.in_(meal_ids),
        )
        .all()
    )
    return {row[0] for row in rows}


def _liked_ids_for_user(db: Session, user_id: str, meal_ids: List[str]) -> Set[str]:
    if not meal_ids:
        return set()
    rows = (
        db.query(SharedMealLike.shared_meal_id)
        .filter(
            SharedMealLike.user_id == user_id,
            SharedMealLike.shared_meal_id.in_(meal_ids),
        )
        .all()
    )
    return {row[0] for row in rows}


def _counts_for_meals(db: Session, meal_ids: List[str]) -> tuple[Dict[str, int], Dict[str, int]]:
    likes: Dict[str, int] = {mid: 0 for mid in meal_ids}
    comments: Dict[str, int] = {mid: 0 for mid in meal_ids}
    if not meal_ids:
        return likes, comments

    for meal_id, count in (
        db.query(SharedMealLike.shared_meal_id, func.count(SharedMealLike.id))
        .filter(SharedMealLike.shared_meal_id.in_(meal_ids))
        .group_by(SharedMealLike.shared_meal_id)
        .all()
    ):
        likes[meal_id] = int(count)

    for meal_id, count in (
        db.query(SharedMealComment.shared_meal_id, func.count(SharedMealComment.id))
        .filter(SharedMealComment.shared_meal_id.in_(meal_ids))
        .group_by(SharedMealComment.shared_meal_id)
        .all()
    ):
        comments[meal_id] = int(count)

    return likes, comments


def _comment_view(
    comment: SharedMealComment,
    author: User,
    *,
    likes_count: int,
    is_liked: bool,
    profile_public: bool,
) -> dict:
    return {
        "id": comment.id,
        "meal_id": comment.shared_meal_id,
        "user_id": comment.user_id,
        "author_name": author.name or "Gojo member",
        "author_avatar_url": resolve_media_url(getattr(author, "avatar_url", None)),
        "body": comment.body,
        "likes_count": likes_count,
        "is_liked": is_liked,
        "profile_public": profile_public,
        "created_at": comment.created_at.isoformat() if comment.created_at else None,
    }


@router.get("")
def list_shared_meals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Latest community meals, newest first."""
    rows = (
        db.query(SharedMeal, User)
        .join(User, User.id == SharedMeal.user_id)
        .order_by(SharedMeal.created_at.desc())
        .limit(_MAX_MEALS_RETURNED)
        .all()
    )
    meal_ids = [meal.id for meal, _ in rows]
    starred = _starred_ids_for_user(db, current_user.id, meal_ids)
    liked = _liked_ids_for_user(db, current_user.id, meal_ids)
    likes_map, comments_map = _counts_for_meals(db, meal_ids)
    return [
        _meal_view(
            meal,
            author.name,
            is_starred=meal.id in starred,
            is_liked=meal.id in liked,
            likes_count=likes_map.get(meal.id, 0),
            comments_count=comments_map.get(meal.id, 0),
            author_profile_public=bool(getattr(author, "profile_public", True)),
        )
        for meal, author in rows
    ]


@router.get("/starred")
def list_starred_meals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Meals the current user has starred, newest stars first."""
    rows = (
        db.query(SharedMeal, User)
        .join(SharedMealStar, SharedMealStar.shared_meal_id == SharedMeal.id)
        .join(User, User.id == SharedMeal.user_id)
        .filter(SharedMealStar.user_id == current_user.id)
        .order_by(SharedMealStar.created_at.desc())
        .limit(_MAX_MEALS_RETURNED)
        .all()
    )
    meal_ids = [meal.id for meal, _ in rows]
    liked = _liked_ids_for_user(db, current_user.id, meal_ids)
    likes_map, comments_map = _counts_for_meals(db, meal_ids)
    return [
        _meal_view(
            meal,
            author.name,
            is_starred=True,
            is_liked=meal.id in liked,
            likes_count=likes_map.get(meal.id, 0),
            comments_count=comments_map.get(meal.id, 0),
            author_profile_public=bool(getattr(author, "profile_public", True)),
        )
        for meal, author in rows
    ]


@router.post("", status_code=201)
async def share_meal(
    name: str = Form(...),
    ingredients: str = Form("[]"),
    instructions: str = Form(""),
    calories: int = Form(0),
    protein: int = Form(0),
    carbs: int = Form(0),
    fat: int = Form(0),
    file: Optional[UploadFile] = File(None),
    source_image_url: str = Form(""),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    name = name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Meal name is required")

    try:
        parsed = json.loads(ingredients)
        ingredient_list = parsed if isinstance(parsed, list) else []
    except (ValueError, TypeError):
        raw = ingredients.replace(",", "\n")
        ingredient_list = [line.strip() for line in raw.split("\n") if line.strip()]
    ingredient_list = [str(i).strip() for i in ingredient_list if str(i).strip()][:40]

    image_key: Optional[str] = None
    if file is not None:
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="The uploaded photo is empty")
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
    elif source_image_url.strip():
        entry = source_image_url.strip()
        if entry.startswith("http"):
            image_key = extract_s3_key_from_url(entry)
        elif not entry.startswith("/"):
            image_key = entry
        if not image_key:
            raise HTTPException(
                status_code=400,
                detail="Could not reuse the existing photo. Please pick a new one.",
            )
    else:
        raise HTTPException(status_code=400, detail="A photo of the meal is required")

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

    return _meal_view(
        meal,
        current_user.name,
        is_starred=False,
        is_liked=False,
        likes_count=0,
        comments_count=0,
    )


@router.post("/{meal_id}/star")
def toggle_star_meal(
    meal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    existing = (
        db.query(SharedMealStar)
        .filter(
            SharedMealStar.shared_meal_id == meal_id,
            SharedMealStar.user_id == current_user.id,
        )
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
        return {"status": "success", "is_starred": False}

    db.add(SharedMealStar(shared_meal_id=meal_id, user_id=current_user.id))
    db.commit()
    return {"status": "success", "is_starred": True}


@router.post("/{meal_id}/like")
def toggle_like_meal(
    meal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    existing = (
        db.query(SharedMealLike)
        .filter(
            SharedMealLike.shared_meal_id == meal_id,
            SharedMealLike.user_id == current_user.id,
        )
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
        db.expire_all()
        count = (
            db.query(func.count(SharedMealLike.id))
            .filter(SharedMealLike.shared_meal_id == meal_id)
            .scalar()
            or 0
        )
        return {"status": "success", "is_liked": False, "likes_count": int(count)}

    try:
        db.add(SharedMealLike(shared_meal_id=meal_id, user_id=current_user.id))
        db.commit()
    except Exception as exc:
        db.rollback()
        # Concurrent duplicate like — treat as already liked.
        existing = (
            db.query(SharedMealLike)
            .filter(
                SharedMealLike.shared_meal_id == meal_id,
                SharedMealLike.user_id == current_user.id,
            )
            .first()
        )
        if not existing:
            logger.exception("Failed to like shared meal %s: %s", meal_id, exc)
            raise HTTPException(status_code=500, detail="Could not like meal") from exc
    db.expire_all()
    count = (
        db.query(func.count(SharedMealLike.id))
        .filter(SharedMealLike.shared_meal_id == meal_id)
        .scalar()
        or 0
    )
    return {"status": "success", "is_liked": True, "likes_count": int(count)}


@router.get("/{meal_id}/comments")
def list_meal_comments(
    meal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    rows = (
        db.query(SharedMealComment, User)
        .join(User, User.id == SharedMealComment.user_id)
        .filter(SharedMealComment.shared_meal_id == meal_id)
        .order_by(SharedMealComment.created_at.asc())
        .limit(200)
        .all()
    )
    comment_ids = [c.id for c, _ in rows]
    liked_ids: Set[str] = set()
    likes_map: Dict[str, int] = {cid: 0 for cid in comment_ids}
    if comment_ids:
        liked_ids = {
            row[0]
            for row in db.query(SharedMealCommentLike.comment_id)
            .filter(
                SharedMealCommentLike.user_id == current_user.id,
                SharedMealCommentLike.comment_id.in_(comment_ids),
            )
            .all()
        }
        for cid, count in (
            db.query(SharedMealCommentLike.comment_id, func.count(SharedMealCommentLike.id))
            .filter(SharedMealCommentLike.comment_id.in_(comment_ids))
            .group_by(SharedMealCommentLike.comment_id)
            .all()
        ):
            likes_map[cid] = int(count)

    return [
        _comment_view(
            comment,
            author,
            likes_count=likes_map.get(comment.id, 0),
            is_liked=comment.id in liked_ids,
            profile_public=bool(getattr(author, "profile_public", True)),
        )
        for comment, author in rows
    ]


@router.post("/{meal_id}/comments", status_code=201)
def create_meal_comment(
    meal_id: str,
    payload: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
    if not bool(getattr(meal, "comments_enabled", True)):
        raise HTTPException(status_code=403, detail="Comments are turned off for this meal")

    body = payload.body.strip()
    if not body:
        raise HTTPException(status_code=400, detail="Comment cannot be empty")
    if len(body) > _MAX_COMMENT_LENGTH:
        raise HTTPException(status_code=400, detail="Comment is too long")

    comment = SharedMealComment(
        user_id=current_user.id,
        shared_meal_id=meal_id,
        body=body,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    return _comment_view(
        comment,
        current_user,
        likes_count=0,
        is_liked=False,
        profile_public=bool(getattr(current_user, "profile_public", True)),
    )


class CommentsEnabledUpdate(BaseModel):
    comments_enabled: bool


@router.patch("/{meal_id}/comments-enabled")
def set_meal_comments_enabled(
    meal_id: str,
    payload: CommentsEnabledUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
    if meal.user_id != current_user.id and not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only the meal owner can change comment settings",
        )

    meal.comments_enabled = bool(payload.comments_enabled)
    db.commit()
    db.refresh(meal)
    return {
        "status": "success",
        "comments_enabled": bool(meal.comments_enabled),
    }


@router.post("/{meal_id}/comments/{comment_id}/like")
def toggle_comment_like(
    meal_id: str,
    comment_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = (
        db.query(SharedMealComment)
        .filter(
            SharedMealComment.id == comment_id,
            SharedMealComment.shared_meal_id == meal_id,
        )
        .first()
    )
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")

    existing = (
        db.query(SharedMealCommentLike)
        .filter(
            SharedMealCommentLike.comment_id == comment_id,
            SharedMealCommentLike.user_id == current_user.id,
        )
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
        count = (
            db.query(func.count(SharedMealCommentLike.id))
            .filter(SharedMealCommentLike.comment_id == comment_id)
            .scalar()
            or 0
        )
        return {"status": "success", "is_liked": False, "likes_count": int(count)}

    db.add(SharedMealCommentLike(comment_id=comment_id, user_id=current_user.id))
    db.commit()
    count = (
        db.query(func.count(SharedMealCommentLike.id))
        .filter(SharedMealCommentLike.comment_id == comment_id)
        .scalar()
        or 0
    )
    return {"status": "success", "is_liked": True, "likes_count": int(count)}


@router.delete("/{meal_id}/comments/{comment_id}")
def delete_meal_comment(
    meal_id: str,
    comment_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = (
        db.query(SharedMealComment)
        .filter(
            SharedMealComment.id == comment_id,
            SharedMealComment.shared_meal_id == meal_id,
        )
        .first()
    )
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")

    meal = db.query(SharedMeal).filter(SharedMeal.id == meal_id).first()
    is_author = comment.user_id == current_user.id
    is_meal_owner = meal is not None and meal.user_id == current_user.id
    if not is_author and not is_meal_owner and not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="You can only delete your own comments",
        )

    db.delete(comment)
    db.commit()
    return {"status": "success"}


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
