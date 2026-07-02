from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from typing import List, Optional
from datetime import datetime
import re

from database import get_db
from models import User, Event, EventParticipant
from security import get_current_user
from pydantic import BaseModel, HttpUrl

router = APIRouter()

class EventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    event_type: str
    location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    start_time: datetime
    whatsapp_link: Optional[str] = None
    max_participants: Optional[int] = None

class EventResponse(BaseModel):
    id: str
    creator_id: str
    title: str
    description: Optional[str]
    event_type: str
    location_name: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    start_time: datetime
    whatsapp_link: Optional[str]
    image_url: Optional[str]
    max_participants: Optional[int]
    created_at: datetime
    participants_count: int
    is_joined: bool

    class Config:
        from_attributes = True

def is_valid_whatsapp_link(link: str) -> bool:
    if not link:
        return True
    pattern = r'^https?://chat\.whatsapp\.com/[a-zA-Z0-9]+$'
    return re.match(pattern, link) is not None

@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(event: EventCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if event.whatsapp_link and not is_valid_whatsapp_link(event.whatsapp_link):
        raise HTTPException(status_code=400, detail="Invalid WhatsApp group link. Must be a chat.whatsapp.com URL.")
    
    new_event = Event(
        creator_id=current_user.id,
        title=event.title,
        description=event.description,
        event_type=event.event_type,
        location_name=event.location_name,
        latitude=event.latitude,
        longitude=event.longitude,
        start_time=event.start_time,
        whatsapp_link=event.whatsapp_link,
        max_participants=event.max_participants
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    
    # Add creator as a participant automatically
    participant = EventParticipant(event_id=new_event.id, user_id=current_user.id)
    db.add(participant)
    db.commit()

    return {
        **new_event.__dict__,
        "participants_count": 1,
        "is_joined": True
    }

@router.get("", response_model=List[EventResponse])
def get_events(
    search: Optional[str] = Query(None, description="Search by title or description"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radius_km: Optional[float] = 10.0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Event).filter(Event.start_time >= datetime.utcnow())
    
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Event.title.ilike(search_pattern),
                Event.description.ilike(search_pattern)
            )
        )
    
    if event_type:
        query = query.filter(Event.event_type == event_type)
    
    # Distance filtering could be done here if needed (e.g. Haversine formula in Postgres using earthdistance)
    # For simplicity, we just return the events and sort/filter by time
    events = query.order_by(Event.start_time.asc()).limit(50).all()
    
    result = []
    for event in events:
        participants_count = db.query(func.count(EventParticipant.id)).filter(EventParticipant.event_id == event.id).scalar()
        is_joined = db.query(EventParticipant).filter(
            EventParticipant.event_id == event.id,
            EventParticipant.user_id == current_user.id
        ).first() is not None
        
        event_data = {
            **event.__dict__,
            "participants_count": participants_count,
            "is_joined": is_joined,
            "whatsapp_link": event.whatsapp_link if is_joined else None  # Only show link if joined
        }
        result.append(event_data)
        
    return result

@router.get("/{event_id}", response_model=EventResponse)
def get_event(event_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
        
    participants_count = db.query(func.count(EventParticipant.id)).filter(EventParticipant.event_id == event.id).scalar()
    is_joined = db.query(EventParticipant).filter(
        EventParticipant.event_id == event.id,
        EventParticipant.user_id == current_user.id
    ).first() is not None
    
    return {
        **event.__dict__,
        "participants_count": participants_count,
        "is_joined": is_joined,
        "whatsapp_link": event.whatsapp_link if is_joined else None
    }

@router.post("/{event_id}/join")
def join_event(event_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
        
    existing = db.query(EventParticipant).filter(
        EventParticipant.event_id == event_id,
        EventParticipant.user_id == current_user.id
    ).first()
    
    if existing:
        return {"status": "success", "message": "Already joined", "whatsapp_link": event.whatsapp_link}
        
    participant = EventParticipant(event_id=event_id, user_id=current_user.id)
    db.add(participant)
    db.commit()
    
    return {"status": "success", "message": "Joined event", "whatsapp_link": event.whatsapp_link}

@router.delete("/{event_id}/leave")
def leave_event(event_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    participant = db.query(EventParticipant).filter(
        EventParticipant.event_id == event_id,
        EventParticipant.user_id == current_user.id
    ).first()
    
    if not participant:
        raise HTTPException(status_code=400, detail="Not joined to this event")
        
    # Creator cannot leave their own event
    event = db.query(Event).filter(Event.id == event_id).first()
    if event and event.creator_id == current_user.id:
        raise HTTPException(status_code=400, detail="Creator cannot leave their own event. Delete the event instead.")
        
    db.delete(participant)
    db.commit()
    
    return {"status": "success", "message": "Left event"}

from fastapi import File, UploadFile
from s3_utils import upload_image_to_s3

@router.post("/{event_id}/image")
async def upload_event_image(
    event_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if event.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the creator can upload images")
        
    contents = await file.read()
    image_url = upload_image_to_s3(contents, file.content_type)
    
    event.image_url = image_url
    db.commit()
    
    return {"status": "success", "image_url": image_url}
