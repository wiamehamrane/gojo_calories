from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from database import get_db
from models import User, Memory
from security import get_current_user
from pydantic import BaseModel
from s3_utils import upload_image_to_s3_key, resolve_media_url

router = APIRouter()

class MemoryResponse(BaseModel):
    id: str
    user_id: str
    image_url: str
    caption: Optional[str]
    is_private: bool
    created_at: datetime

    class Config:
        from_attributes = True

@router.post("", response_model=MemoryResponse, status_code=status.HTTP_201_CREATED)
async def create_memory(
    caption: Optional[str] = None,
    is_private: bool = True,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    contents = await file.read()
    image_url = upload_image_to_s3_key(contents, file.content_type, prefix="memories/")
    
    new_memory = Memory(
        user_id=current_user.id,
        image_url=image_url,
        caption=caption,
        is_private=is_private
    )
    db.add(new_memory)
    db.commit()
    db.refresh(new_memory)

    return _memory_view(new_memory)


def _memory_view(memory: Memory) -> dict:
    """Serialize a memory with a freshly signed image URL (keys never expire)."""
    return {
        "id": memory.id,
        "user_id": memory.user_id,
        "image_url": resolve_media_url(memory.image_url),
        "caption": memory.caption,
        "is_private": memory.is_private,
        "created_at": memory.created_at,
    }


@router.get("", response_model=List[MemoryResponse])
def get_my_memories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    memories = (
        db.query(Memory)
        .filter(Memory.user_id == current_user.id)
        .order_by(Memory.created_at.desc())
        .all()
    )
    return [_memory_view(m) for m in memories]

@router.delete("/{memory_id}")
def delete_memory(
    memory_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    memory = db.query(Memory).filter(Memory.id == memory_id).first()
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")
    
    if memory.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this memory")
    
    db.delete(memory)
    db.commit()
    
    return {"status": "success", "message": "Memory deleted"}
