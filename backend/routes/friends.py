from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from datetime import datetime

from database import get_db
from models import User, Friendship
from security import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/friends", tags=["friends"])

class FriendResponse(BaseModel):
    id: str
    name: Optional[str]
    email: str
    
    class Config:
        from_attributes = True

class UserSearchResponse(BaseModel):
    id: str
    name: Optional[str]
    email: str
    is_friend: bool

@router.get("", response_model=List[FriendResponse])
def get_my_friends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Find all friendships where I am either user_id or friend_id
    friendships = db.query(Friendship).filter(
        or_(Friendship.user_id == current_user.id, Friendship.friend_id == current_user.id),
        Friendship.status == "accepted"
    ).all()
    
    friends = []
    for f in friendships:
        other_user = f.friend if f.user_id == current_user.id else f.user
        friends.append(other_user)
        
    return friends

@router.get("/search", response_model=List[UserSearchResponse])
def search_users(
    query: str = Query(..., min_length=2),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    search_pattern = f"%{query}%"
    users = db.query(User).filter(
        or_(User.email.ilike(search_pattern), User.name.ilike(search_pattern)),
        User.id != current_user.id
    ).limit(10).all()
    
    result = []
    for u in users:
        is_friend = db.query(Friendship).filter(
            or_(
                (Friendship.user_id == current_user.id) & (Friendship.friend_id == u.id),
                (Friendship.user_id == u.id) & (Friendship.friend_id == current_user.id)
            ),
            Friendship.status == "accepted"
        ).first() is not None
        
        result.append({
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "is_friend": is_friend
        })
        
    return result

@router.post("/add/{user_id}")
def add_friend(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself as a friend")
        
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    existing = db.query(Friendship).filter(
        or_(
            (Friendship.user_id == current_user.id) & (Friendship.friend_id == user_id),
            (Friendship.user_id == user_id) & (Friendship.friend_id == current_user.id)
        )
    ).first()
    
    if existing:
        return {"status": "success", "message": "Already friends or request pending"}
        
    new_friendship = Friendship(
        user_id=current_user.id,
        friend_id=user_id,
        status="accepted" # Auto-accept for now to make it easy to build "Circles"
    )
    db.add(new_friendship)
    db.commit()
    
    return {"status": "success", "message": "Friend added to your circle"}

@router.delete("/remove/{user_id}")
def remove_friend(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    friendship = db.query(Friendship).filter(
        or_(
            (Friendship.user_id == current_user.id) & (Friendship.friend_id == user_id),
            (Friendship.user_id == user_id) & (Friendship.friend_id == current_user.id)
        )
    ).first()
    
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found")
        
    db.delete(friendship)
    db.commit()
    
    return {"status": "success", "message": "Removed from your circle"}
