from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from database import get_db
from models import User, Post, PostLike
from security import get_current_user
from pydantic import BaseModel
from s3_utils import upload_image_to_s3_key, resolve_media_url

router = APIRouter()

class PostUser(BaseModel):
    id: str
    name: Optional[str]
    
    class Config:
        from_attributes = True

class PostResponse(BaseModel):
    id: str
    user_id: str
    user: PostUser
    content: Optional[str]
    image_url: Optional[str]
    likes_count: int
    is_liked: bool
    created_at: datetime

    class Config:
        from_attributes = True

@router.post("/posts", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    content: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    image_url = None
    if file:
        contents = await file.read()
        image_url = upload_image_to_s3_key(contents, file.content_type, prefix="posts/")
    
    new_post = Post(
        user_id=current_user.id,
        content=content,
        image_url=image_url
    )
    db.add(new_post)
    db.commit()
    db.refresh(new_post)
    
    return {
        "id": new_post.id,
        "user_id": new_post.user_id,
        "user": current_user,
        "content": new_post.content,
        "image_url": resolve_media_url(new_post.image_url),
        "likes_count": 0,
        "is_liked": False,
        "created_at": new_post.created_at
    }

@router.get("", response_model=List[PostResponse])
def get_global_feed(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    posts = db.query(Post).order_by(Post.created_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for post in posts:
        likes_count = db.query(func.count(PostLike.id)).filter(PostLike.post_id == post.id).scalar()
        is_liked = db.query(PostLike).filter(
            PostLike.post_id == post.id,
            PostLike.user_id == current_user.id
        ).first() is not None
        
        result.append({
            "id": post.id,
            "user_id": post.user_id,
            "user": post.user,
            "content": post.content,
            "image_url": resolve_media_url(post.image_url),
            "likes_count": likes_count,
            "is_liked": is_liked,
            "created_at": post.created_at
        })
    
    return result

@router.post("/posts/{post_id}/like")
def toggle_like_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    existing_like = db.query(PostLike).filter(
        PostLike.post_id == post_id,
        PostLike.user_id == current_user.id
    ).first()
    
    if existing_like:
        db.delete(existing_like)
        db.commit()
        return {"status": "success", "message": "Unliked", "is_liked": False}
    else:
        new_like = PostLike(post_id=post_id, user_id=current_user.id)
        db.add(new_like)
        db.commit()
        return {"status": "success", "message": "Liked", "is_liked": True}

@router.delete("/posts/{post_id}")
def delete_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    
    db.delete(post)
    db.commit()
    
    return {"status": "success", "message": "Post deleted"}
