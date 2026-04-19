from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from database import get_db
from models import Group, GroupMember, User, FoodLog
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from security import get_current_user_id

router = APIRouter()

class GroupCreate(BaseModel):
    name: str
    description: Optional[str] = None

class FeedItem(BaseModel):
    user_name: str
    meal_name: str
    calories: int
    group_name: str
    created_at: datetime
    
class GroupResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    member_count: int

@router.post("/", response_model=GroupResponse)
def create_group(group: GroupCreate, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    if db.query(Group).filter(Group.name == group.name).first():
        raise HTTPException(status_code=400, detail="Group name already exists")
    
    new_group = Group(name=group.name, description=group.description)
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    
    # Auto-join the creator
    member = GroupMember(group_id=new_group.id, user_id=current_user_id)
    db.add(member)
    db.commit()
    
    return {"id": new_group.id, "name": new_group.name, "description": new_group.description, "member_count": 1}

@router.post("/{group_id}/join")
def join_group(group_id: int, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    if db.query(GroupMember).filter(GroupMember.group_id == group_id, GroupMember.user_id == current_user_id).first():
        return {"status": "success", "message": "Already a member"}
        
    member = GroupMember(group_id=group_id, user_id=current_user_id)
    db.add(member)
    db.commit()
    return {"status": "success"}

@router.get("/my", response_model=List[GroupResponse])
def get_my_groups(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    memberships = db.query(GroupMember).filter(GroupMember.user_id == current_user_id).all()
    group_ids = [m.group_id for m in memberships]
    groups = db.query(Group).filter(Group.id.in_(group_ids)).all()
    
    res = []
    for g in groups:
        count = db.query(GroupMember).filter(GroupMember.group_id == g.id).count()
        res.append({"id": g.id, "name": g.name, "description": g.description, "member_count": count})
    return res

@router.get("/discover", response_model=List[GroupResponse])
def discover_groups(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    memberships = db.query(GroupMember).filter(GroupMember.user_id == current_user_id).all()
    joined_ids = [m.group_id for m in memberships]
    
    groups = db.query(Group).filter(~Group.id.in_(joined_ids)).limit(20).all()
    res = []
    for g in groups:
        count = db.query(GroupMember).filter(GroupMember.group_id == g.id).count()
        res.append({"id": g.id, "name": g.name, "description": g.description, "member_count": count})
    return res

@router.get("/feed", response_model=List[FeedItem])
def get_community_feed(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    # Feed represents recent food logs of users who share a group with me
    memberships = db.query(GroupMember).filter(GroupMember.user_id == current_user_id).all()
    my_group_ids = [m.group_id for m in memberships]
    
    if not my_group_ids:
        return []
        
    # Get all users in those groups
    peer_memberships = db.query(GroupMember).filter(GroupMember.group_id.in_(my_group_ids)).all()
    peer_ids = list(set([m.user_id for m in peer_memberships]))
    
    recent_logs = db.query(FoodLog).filter(FoodLog.user_id.in_(peer_ids)).order_by(desc(FoodLog.created_at)).limit(20).all()
    
    feed = []
    for log in recent_logs:
        user = db.query(User).filter(User.id == log.user_id).first()
        # Find which group we share
        shared_group = db.query(GroupMember).filter(GroupMember.user_id == log.user_id, GroupMember.group_id.in_(my_group_ids)).first()
        group_name = "Community"
        if shared_group:
            g = db.query(Group).filter(Group.id == shared_group.group_id).first()
            if g:
                group_name = g.name
                
        feed.append({
            "user_name": user.name if user else "Anonymous",
            "meal_name": log.name,
            "calories": log.calories,
            "group_name": group_name,
            "created_at": log.created_at
        })
        
    return feed
