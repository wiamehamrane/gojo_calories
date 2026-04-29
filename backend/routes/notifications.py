import os
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from database import get_db
from models import User
from services import email_service

router = APIRouter()

ADMIN_API_KEY = os.getenv("ADMIN_API_KEY", "change-me-in-production")

class NotificationPayload(BaseModel):
    subject: str
    body: str
    target_users: str = "all"  # "all" or list of emails
    emails: Optional[List[str]] = None
    admin_key: str

def send_bulk_emails(subject: str, body: str, emails: List[str]):
    for email in emails:
        email_service.send_email(email, subject, body)

@router.post("/send")
def send_notification(payload: NotificationPayload, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    if payload.admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")

    target_emails = []
    if payload.target_users == "all":
        users = db.query(User).filter(User.is_email_verified == True).all()
        target_emails = [user.email for user in users if user.email]
    elif payload.emails:
        target_emails = payload.emails
    
    if not target_emails:
        raise HTTPException(status_code=400, detail="No target emails found")

    # Send in background to not block the response
    background_tasks.add_task(send_bulk_emails, payload.subject, payload.body, target_emails)

    return {"status": "success", "message": f"Notifications queued for {len(target_emails)} users"}
