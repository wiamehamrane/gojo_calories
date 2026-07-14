from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from sqlalchemy.exc import SQLAlchemyError
from typing import List, Optional
from datetime import datetime
import json
import logging
import os
import re

from openai import OpenAI, OpenAIError, RateLimitError

from database import get_db
from models import User, Event, EventParticipant
from security import get_current_user
from pydantic import BaseModel, HttpUrl

logger = logging.getLogger(__name__)

_OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
_OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5.4-mini")

try:
    _openai_client = OpenAI(api_key=_OPENAI_API_KEY) if _OPENAI_API_KEY else None
except Exception as _e:
    logger.error(f"Failed to initialise OpenAI client for events: {_e}")
    _openai_client = None

router = APIRouter()

_VALID_AUDIENCES = {"female", "male", "mixed"}


class EventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    event_type: str
    audience: str = "mixed"  # female | male | mixed
    location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    start_time: datetime
    whatsapp_link: str
    max_participants: Optional[int] = None

class EventResponse(BaseModel):
    id: str
    creator_id: str
    title: str
    description: Optional[str]
    event_type: str
    audience: str
    location_name: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    start_time: datetime
    whatsapp_link: Optional[str]
    image_url: Optional[str]
    image_urls: List[str] = []
    max_participants: Optional[int]
    created_at: datetime
    participants_count: int
    is_joined: bool

    class Config:
        from_attributes = True


def _normalize_audience(audience: Optional[str]) -> str:
    value = (audience or "mixed").strip().lower()
    if value not in _VALID_AUDIENCES:
        raise HTTPException(
            status_code=400,
            detail="Audience must be one of: female, male, mixed",
        )
    return value


def _user_can_join(event_audience: str, user_gender: Optional[str]) -> bool:
    audience = (event_audience or "mixed").lower()
    if audience == "mixed":
        return True
    gender = (user_gender or "").strip().lower()
    return gender == audience


_WHATSAPP_GROUP_LINK_RE = re.compile(
    r'^https?://chat\.whatsapp\.com/[A-Za-z0-9_-]+(\?[^\s#]*)?$',
    re.IGNORECASE,
)
_MAX_EVENT_IMAGES = 10
_BIDI_AND_ZERO_WIDTH_RE = re.compile(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069\ufeff]')


def normalize_whatsapp_link(link: str) -> str:
    value = _BIDI_AND_ZERO_WIDTH_RE.sub('', (link or '').strip())
    if not value:
        return value
    if not value.lower().startswith(('http://', 'https://')):
        value = f'https://{value}'
    return value


def is_valid_whatsapp_link(link: str) -> bool:
    normalized = normalize_whatsapp_link(link)
    if not normalized:
        return False
    return _WHATSAPP_GROUP_LINK_RE.match(normalized) is not None


def _event_image_keys(event: Event) -> list[str]:
    """Raw stored entries: S3 keys for new uploads, full URLs for legacy events."""
    if event.image_urls and isinstance(event.image_urls, list):
        return [url for url in event.image_urls if isinstance(url, str) and url.strip()]
    if event.image_url:
        return [event.image_url]
    return []


def _resolve_event_image_url(entry: str) -> str:
    """Turn a stored entry into a URL that is valid right now.

    New entries are S3 keys that get a fresh presigned URL on every read, so
    event images never expire. Legacy entries are old presigned URLs whose
    signatures have expired: re-extract the key and re-sign them too.
    """
    from s3_utils import presign_s3_key, extract_s3_key_from_url
    if entry.startswith('http'):
        key = extract_s3_key_from_url(entry)
        if key:
            return presign_s3_key(key)
        return entry
    if entry.startswith('/'):
        return entry  # local /uploads path
    return presign_s3_key(entry)


def _event_image_display_urls(event: Event) -> list[str]:
    return [_resolve_event_image_url(entry) for entry in _event_image_keys(event)]

def _optional_str(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    stripped = value.strip()
    return stripped or None


def _event_to_response(
    event: Event,
    *,
    participants_count: int,
    is_joined: bool,
    include_whatsapp: bool = True,
) -> dict:
    """Build a clean API payload (never use ORM __dict__ directly)."""
    return {
        "id": event.id,
        "creator_id": event.creator_id,
        "title": event.title,
        "description": event.description,
        "event_type": event.event_type,
        "audience": event.audience or "mixed",
        "location_name": event.location_name,
        "latitude": event.latitude,
        "longitude": event.longitude,
        "start_time": event.start_time,
        "whatsapp_link": event.whatsapp_link if include_whatsapp else None,
        "image_url": _event_image_display_urls(event)[0] if _event_image_keys(event) else None,
        "image_urls": _event_image_display_urls(event),
        "max_participants": event.max_participants,
        "created_at": event.created_at,
        "participants_count": participants_count,
        "is_joined": is_joined,
    }


@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(event: EventCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not event.whatsapp_link or not event.whatsapp_link.strip():
        raise HTTPException(status_code=400, detail="WhatsApp link is required.")
    whatsapp_link = normalize_whatsapp_link(event.whatsapp_link)
    if not is_valid_whatsapp_link(whatsapp_link):
        raise HTTPException(
            status_code=400,
            detail="Invalid WhatsApp link. Use a chat.whatsapp.com group invite link.",
        )
    if not event.event_type or not event.event_type.strip():
        raise HTTPException(status_code=400, detail="Event category is required.")

    audience = _normalize_audience(event.audience)

    try:
        new_event = Event(
            creator_id=current_user.id,
            title=event.title.strip(),
            description=_optional_str(event.description),
            event_type=event.event_type.strip().lower(),
            audience=audience,
            location_name=_optional_str(event.location_name),
            latitude=event.latitude,
            longitude=event.longitude,
            start_time=event.start_time,
            whatsapp_link=whatsapp_link,
            max_participants=event.max_participants,
        )
        db.add(new_event)
        db.flush()

        participant = EventParticipant(event_id=new_event.id, user_id=current_user.id)
        db.add(participant)
        db.commit()
        db.refresh(new_event)

        return _event_to_response(
            new_event,
            participants_count=1,
            is_joined=True,
            include_whatsapp=True,
        )
    except HTTPException:
        raise
    except SQLAlchemyError as exc:
        db.rollback()
        logger.exception("create_event failed for user %s: %s", current_user.id, exc)
        detail = str(exc.orig) if getattr(exc, "orig", None) else str(exc)
        if "audience" in detail.lower() and "does not exist" in detail.lower():
            raise HTTPException(
                status_code=503,
                detail="Events database is being updated. Please try again in a minute.",
            ) from exc
        raise HTTPException(
            status_code=500,
            detail="Failed to create event. Please try again.",
        ) from exc

@router.get("", response_model=List[EventResponse])
def get_events(
    search: Optional[str] = Query(None, description="Search by title or description"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    audience: Optional[str] = Query(None, description="Filter by audience: female, male, or mixed"),
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

    if audience:
        query = query.filter(Event.audience == _normalize_audience(audience))
    
    # Distance filtering could be done here if needed (e.g. Haversine formula in Postgres using earthdistance)
    # For simplicity, we just return the events and sort/filter by time
    events = query.order_by(Event.start_time.asc()).limit(50).all()
    
    # Show mixed events + events matching the user's gender
    user_gender = (current_user.gender or "").strip().lower()
    visible = []
    for event in events:
        event_audience = (event.audience or "mixed").lower()
        if event_audience == "mixed" or event_audience == user_gender:
            visible.append(event)

    result = []
    for event in visible:
        participants_count = db.query(func.count(EventParticipant.id)).filter(EventParticipant.event_id == event.id).scalar()
        is_joined = db.query(EventParticipant).filter(
            EventParticipant.event_id == event.id,
            EventParticipant.user_id == current_user.id
        ).first() is not None
        
        event_data = _serialize_event(event, db, current_user)
        result.append(event_data)
        
    return result

@router.get("/mine", response_model=List[EventResponse])
def get_my_events(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """All events created by the current user (upcoming and past)."""
    events = (
        db.query(Event)
        .filter(Event.creator_id == current_user.id)
        .order_by(Event.start_time.desc())
        .all()
    )
    result = []
    for event in events:
        participants_count = db.query(func.count(EventParticipant.id)).filter(
            EventParticipant.event_id == event.id
        ).scalar()
        result.append(
            _event_to_response(
                event,
                participants_count=participants_count,
                is_joined=True,
                include_whatsapp=True,
            )
        )
    return result


class EventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    event_type: Optional[str] = None
    audience: Optional[str] = None
    location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    start_time: Optional[datetime] = None
    whatsapp_link: Optional[str] = None
    max_participants: Optional[int] = None


@router.patch("/{event_id}", response_model=EventResponse)
def update_event(
    event_id: str,
    updates: EventUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the creator can edit this event")

    data = updates.model_dump(exclude_unset=True)

    if "title" in data:
        if not (data["title"] or "").strip():
            raise HTTPException(status_code=400, detail="Title cannot be empty.")
        data["title"] = data["title"].strip()
    if "event_type" in data:
        if not (data["event_type"] or "").strip():
            raise HTTPException(status_code=400, detail="Event category cannot be empty.")
        data["event_type"] = data["event_type"].strip().lower()
    if "audience" in data:
        data["audience"] = _normalize_audience(data["audience"])
    if "whatsapp_link" in data:
        link = normalize_whatsapp_link(data["whatsapp_link"] or "")
        if not link:
            raise HTTPException(status_code=400, detail="WhatsApp link is required.")
        if not is_valid_whatsapp_link(link):
            raise HTTPException(
                status_code=400,
                detail="Invalid WhatsApp link. Use a chat.whatsapp.com group invite link.",
            )
        data["whatsapp_link"] = link

    for field, value in data.items():
        setattr(event, field, value)
    db.commit()
    db.refresh(event)

    return _serialize_event(event, db, current_user)


@router.delete("/{event_id}")
def delete_event(
    event_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the creator can delete this event")

    db.query(EventParticipant).filter(EventParticipant.event_id == event_id).delete()
    db.delete(event)
    db.commit()

    return {"status": "success", "message": "Event deleted"}


class AISearchRequest(BaseModel):
    query: str


def _serialize_event(event: Event, db: Session, current_user: User) -> dict:
    participants_count = db.query(func.count(EventParticipant.id)).filter(
        EventParticipant.event_id == event.id
    ).scalar()
    is_joined = db.query(EventParticipant).filter(
        EventParticipant.event_id == event.id,
        EventParticipant.user_id == current_user.id
    ).first() is not None
    return _event_to_response(
        event,
        participants_count=participants_count,
        is_joined=is_joined,
        include_whatsapp=is_joined,
    )


@router.post("/search/ai", response_model=List[EventResponse])
def ai_search_events(
    body: AISearchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """AI-powered event search.

    The user can send a keyword, a sport name, or a free-form prompt describing
    the event they want (e.g. "I wanna go for a run this weekend"). We send the
    query together with the list of upcoming events to OpenAI, which returns the
    IDs of the most relevant events, ordered by relevance.
    """
    query_text = body.query.strip()
    if not query_text:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    user_gender = (current_user.gender or "").strip().lower()
    all_upcoming = (
        db.query(Event)
        .filter(Event.start_time >= datetime.utcnow())
        .order_by(Event.start_time.asc())
        .limit(100)
        .all()
    )
    upcoming = [
        e for e in all_upcoming
        if (e.audience or "mixed").lower() in ("mixed", user_gender)
    ]

    if not upcoming:
        return []

    def _sql_fallback() -> list:
        pattern = f"%{query_text}%"
        matches = [
            e for e in upcoming
            if query_text.lower() in (e.title or "").lower()
            or query_text.lower() in (e.description or "").lower()
            or query_text.lower() in (e.event_type or "").lower()
            or query_text.lower() in (e.audience or "").lower()
        ]
        return [_serialize_event(e, db, current_user) for e in (matches or upcoming)[:20]]

    if _openai_client is None:
        logger.warning("OPENAI_API_KEY not configured; falling back to keyword search for events.")
        return _sql_fallback()

    events_catalog = [
        {
            "id": e.id,
            "title": e.title,
            "description": (e.description or "")[:300],
            "event_type": e.event_type,
            "audience": e.audience or "mixed",
            "location": e.location_name,
            "start_time": e.start_time.isoformat(),
        }
        for e in upcoming
    ]

    prompt = f"""You are an event-matching assistant for a fitness & social app.

The user is searching for events. Their search input may be a single keyword, a sport name, or a natural-language prompt describing the kind of event they want (in any language).

USER SEARCH: "{query_text}"

AVAILABLE EVENTS (JSON):
{json.dumps(events_catalog, ensure_ascii=False)}

TASK:
Return the IDs of the events most relevant to the user's search, ordered from most to least relevant.
- Understand intent, not just keywords (e.g. "I wanna go for a run" matches running/jogging events; "something chill in the morning" matches walks or yoga in the morning).
- Consider event type, audience (female/male/mixed), title, description, location and start time.
- Only include events that are genuinely relevant. If nothing matches well, return an empty list.
- Include at most 20 event IDs.

Respond with ONLY a raw JSON object, no markdown, exactly like:
{{"event_ids": ["id1", "id2"]}}"""

    try:
        response = _openai_client.chat.completions.create(
            model=_OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
        )
        raw = (response.choices[0].message.content or "").replace("```json", "").replace("```", "").strip()
        matched_ids = json.loads(raw).get("event_ids", [])
    except RateLimitError as e:
        logger.warning("OpenAI rate limit on event search: %s", e)
        return _sql_fallback()
    except (OpenAIError, json.JSONDecodeError, KeyError) as e:
        logger.error("AI event search failed: %s", e)
        return _sql_fallback()

    events_by_id = {e.id: e for e in upcoming}
    ordered = [events_by_id[eid] for eid in matched_ids if eid in events_by_id]
    return [_serialize_event(e, db, current_user) for e in ordered[:20]]


@router.get("/{event_id}", response_model=EventResponse)
def get_event(event_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    return _serialize_event(event, db, current_user)

@router.post("/{event_id}/join")
def join_event(event_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    if not _user_can_join(event.audience or "mixed", current_user.gender):
        raise HTTPException(
            status_code=403,
            detail=f"This event is for {(event.audience or 'mixed')} attendees only.",
        )
        
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
from s3_utils import upload_image_to_s3_key, MediaUploadError

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
    if not contents:
        raise HTTPException(status_code=400, detail="Image file is empty")

    # Store the stable S3 key; presigned URLs are generated fresh on every
    # read so event images never expire.
    try:
        image_key = upload_image_to_s3_key(
            contents, file.content_type or "image/jpeg", prefix="events/"
        )
    except MediaUploadError as e:
        logger.error("Event image upload failed for event %s: %s", event_id, e)
        raise HTTPException(
            status_code=503,
            detail="Image upload failed. Media storage is temporarily unavailable.",
        ) from e

    # Guard against ephemeral local paths being treated as durable uploads.
    if isinstance(image_key, str) and image_key.startswith("/uploads/"):
        logger.error(
            "Event image was saved to ephemeral local disk (%s). "
            "Fix AWS_BUCKET_NAME / IAM so images persist across deploys.",
            image_key,
        )
        raise HTTPException(
            status_code=503,
            detail="Image upload failed. Media storage is misconfigured.",
        )

    existing_keys = _event_image_keys(event)
    if len(existing_keys) >= _MAX_EVENT_IMAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum of {_MAX_EVENT_IMAGES} images per event.",
        )

    updated_keys = [*existing_keys, image_key]
    event.image_urls = updated_keys
    event.image_url = updated_keys[0]
    db.commit()

    return {
        "status": "success",
        "image_url": _resolve_event_image_url(image_key),
        "image_urls": [_resolve_event_image_url(k) for k in updated_keys],
    }
