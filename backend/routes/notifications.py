import os
import requests
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from database import get_db
from models import User
from services import email_service

router = APIRouter()

ADMIN_API_KEY = os.getenv("ADMIN_API_KEY", "change-me-in-production")

# ─── OneSignal push (gender-aware smart notifications) ──────────────────────
ONESIGNAL_APP_ID = os.getenv("ONESIGNAL_APP_ID", "60019fa3-3a1b-4c1e-a4dc-22ac49dc32de")
ONESIGNAL_REST_API_KEY = os.getenv("ONESIGNAL_REST_API_KEY", "")
ONESIGNAL_API_URL = "https://onesignal.com/api/v1/notifications"
ONESIGNAL_BATCH_SIZE = 2000

# Message templates keyed by reminder type, phrased per gender.
SMART_MESSAGES = {
    "drink_water": {
        "male": ("Hydration reminder 💧", "Please sir, drink water. Your body will thank you."),
        "female": ("Hydration reminder 💧", "Please madam, make sure to drink water. Your body will thank you."),
        "neutral": ("Hydration reminder 💧", "Please make sure to drink water. Your body will thank you."),
    },
    "move": {
        "male": ("Time to move 🚶", "Sir, you forgot to move a bit today. Let's go on a walk now, for your health."),
        "female": ("Time to move 🚶", "Madam, you forgot to move a bit today. Let's go on a walk now, for your health."),
        "neutral": ("Time to move 🚶", "You forgot to move a bit today. Let's go on a walk now, for your health."),
    },
    "log_meal": {
        "male": ("Don't forget to log 🍽️", "Sir, please remember to log your meals today to stay on track."),
        "female": ("Don't forget to log 🍽️", "Madam, please remember to log your meals today to stay on track."),
        "neutral": ("Don't forget to log 🍽️", "Please remember to log your meals today to stay on track."),
    },
}


def send_onesignal_push(external_ids: List[str], title: str, body: str):
    """Send a push to users identified by their external id (our user id)."""
    if not ONESIGNAL_REST_API_KEY or not external_ids:
        return
    auth = (
        f"Key {ONESIGNAL_REST_API_KEY}"
        if ONESIGNAL_REST_API_KEY.startswith("os_v2_")
        else f"Basic {ONESIGNAL_REST_API_KEY}"
    )
    headers = {
        "Authorization": auth,
        "Content-Type": "application/json",
    }
    for i in range(0, len(external_ids), ONESIGNAL_BATCH_SIZE):
        batch = external_ids[i : i + ONESIGNAL_BATCH_SIZE]
        payload = {
            "app_id": ONESIGNAL_APP_ID,
            "include_aliases": {"external_id": batch},
            "target_channel": "push",
            "headings": {"en": title},
            "contents": {"en": body},
        }
        try:
            requests.post(ONESIGNAL_API_URL, json=payload, headers=headers, timeout=15)
        except requests.RequestException:
            # Push delivery is best-effort; don't crash the background task.
            pass


def send_smart_pushes_by_gender(users_by_gender: dict, reminder_type: str):
    messages = SMART_MESSAGES[reminder_type]
    for gender, user_ids in users_by_gender.items():
        title, body = messages.get(gender, messages["neutral"])
        send_onesignal_push(user_ids, title, body)

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


class SmartNotificationPayload(BaseModel):
    reminder_type: str  # "drink_water" | "move" | "log_meal"
    target_users: str = "all"  # "all" or restrict to specific emails
    emails: Optional[List[str]] = None
    admin_key: str


@router.post("/smart")
def send_smart_notification(
    payload: SmartNotificationPayload,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """Send a gender-aware smart push notification via OneSignal.

    Users are addressed as sir/madam based on the gender stored on their
    profile. Call this from a cron job (e.g. hourly) to build reminder
    schedules like "drink water at 10:00" or "walk reminder at 17:00".
    """
    if payload.admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")
    if payload.reminder_type not in SMART_MESSAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown reminder_type. Use one of: {', '.join(SMART_MESSAGES)}",
        )
    if not ONESIGNAL_REST_API_KEY:
        raise HTTPException(status_code=500, detail="ONESIGNAL_REST_API_KEY is not configured")

    query = db.query(User).filter(User.is_email_verified == True)
    if payload.target_users != "all":
        if not payload.emails:
            raise HTTPException(status_code=400, detail="No target emails provided")
        query = query.filter(User.email.in_(payload.emails))
    users = query.all()
    if not users:
        raise HTTPException(status_code=400, detail="No target users found")

    users_by_gender = {"male": [], "female": [], "neutral": []}
    for user in users:
        gender = (user.gender or "").lower()
        bucket = gender if gender in ("male", "female") else "neutral"
        users_by_gender[bucket].append(str(user.id))

    background_tasks.add_task(send_smart_pushes_by_gender, users_by_gender, payload.reminder_type)

    return {
        "status": "success",
        "message": f"Smart '{payload.reminder_type}' push queued for {len(users)} users",
        "breakdown": {k: len(v) for k, v in users_by_gender.items()},
    }


# ─── Smart nutrition check (personalized, per-user) ──────────────────────────

class NutritionCheckPayload(BaseModel):
    admin_key: str


@router.post("/nutrition-check")
def trigger_nutrition_check(payload: NutritionCheckPayload, db: Session = Depends(get_db)):
    """Manually trigger the smart nutrition notification pass.

    The same pass runs automatically every SMART_NOTIF_INTERVAL_HOURS via the
    in-process scheduler (see main.py). Each active user gets at most one
    personalized push per run: missed-breakfast reminder, protein-gap dinner
    reminder, overeating -> workout suggestion, or a good-job progress update.
    """
    if payload.admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")
    from services.smart_nutrition_service import run_nutrition_check
    return run_nutrition_check(db)


# ─── Progress-photo evening reminder ─────────────────────────────────────────

@router.post("/progress-photo-check")
def trigger_progress_photo_check(payload: NutritionCheckPayload, db: Session = Depends(get_db)):
    """Manually trigger the evening body-photo reminder pass.

    The same pass runs automatically at PROGRESS_PHOTO_REMINDER_HOUR local time
    via the in-process scheduler (see main.py). Each active user who hasn't
    completed today's 4 guided poses gets one nudge.
    """
    if payload.admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")
    from services.progress_reminder_service import run_progress_photo_reminder
    return run_progress_photo_reminder(db)
