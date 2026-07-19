"""Evening "body photo" reminder push.

Once per evening (20:00 local by default; scheduled in main.py) this checks
every recently-active user and, if they have NOT completed all four guided
body-photo angles (front, left, right, back) for TODAY, sends a single
OneSignal nudge addressed by first name, e.g.:

  "Mohamed, you still have 3 of today's 4 body photos to take. Snap them
   before bed so your timeline stays consistent!"

Design mirrors services/smart_nutrition_service.py:
  - Local time = UTC + PROGRESS_TZ_OFFSET_MIN (falls back to the nutrition
    scheduler's SMART_NOTIF_TZ_OFFSET_MIN so both stay in sync).
  - Fires at most once per user per day (Redis dedup, in-memory fallback).
  - Only users active in the last 7 days (recent DailyStats) are considered,
    so we never spam dormant accounts.
"""

import datetime as dt
import logging
import os
from typing import Tuple

from sqlalchemy.orm import Session

from models import User, DailyStats, ProgressPhoto

# Reuse the OneSignal delivery + dedup helpers already battle-tested there.
from services.smart_nutrition_service import (
    _send_push,
    _redis,
    _first_name,
    ACTIVE_USER_WINDOW_DAYS,
)

logger = logging.getLogger(__name__)

REQUIRED_POSES = {"front", "left", "right", "back"}

# Local timezone offset. Defaults to the nutrition scheduler's value so a single
# env var configures both, but can be overridden independently.
TZ_OFFSET_MIN = int(
    os.getenv("PROGRESS_TZ_OFFSET_MIN", os.getenv("SMART_NOTIF_TZ_OFFSET_MIN", "60"))
)


def _completed_poses_today(db: Session, user_id: str, local_today: dt.date) -> set:
    rows = (
        db.query(ProgressPhoto.pose)
        .filter(
            ProgressPhoto.user_id == user_id,
            ProgressPhoto.photo_date == local_today,
            ProgressPhoto.pose.isnot(None),
        )
        .all()
    )
    return {r[0] for r in rows if r[0] in REQUIRED_POSES}


def _build_message(user: User, remaining: int) -> Tuple[str, str]:
    name = _first_name(user)
    if remaining == 4:
        return (
            "Don't forget today's photos 📸",
            f"{name}, you haven't taken today's body photos yet. It only takes a "
            f"minute — front, sides and back — and keeps your progress timeline consistent.",
        )
    shots = "shot" if remaining == 1 else "shots"
    return (
        "Finish today's photos 📸",
        f"{name}, you still have {remaining} of today's 4 body {shots} to take. "
        f"Snap them before bed so your timeline stays consistent!",
    )


def _dedup_key(user_id: str, day: str) -> str:
    return f"progressphoto:reminder:{user_id}:{day}"


def _already_sent(r, user_id: str, day: str) -> bool:
    key = _dedup_key(user_id, day)
    if r:
        try:
            return bool(r.exists(key))
        except Exception:
            pass
    return key in _memory_state


def _mark_sent(r, user_id: str, day: str):
    key = _dedup_key(user_id, day)
    if r:
        try:
            r.setex(key, 60 * 60 * 20, "1")  # expires well before next evening
            return
        except Exception:
            pass
    _memory_state[key] = True


_memory_state = {}


def run_progress_photo_reminder(db: Session) -> dict:
    """Nudge each active user who hasn't finished today's 4 guided photos."""
    from services.smart_nutrition_service import ONESIGNAL_REST_API_KEY

    if not ONESIGNAL_REST_API_KEY:
        logger.warning("Progress photo reminder skipped: ONESIGNAL_REST_API_KEY not set")
        return {"status": "skipped", "reason": "ONESIGNAL_REST_API_KEY not configured"}

    now_local = dt.datetime.utcnow() + dt.timedelta(minutes=TZ_OFFSET_MIN)
    local_today = now_local.date()
    day_key = local_today.isoformat()
    r = _redis()

    activity_cutoff = dt.datetime.combine(
        local_today - dt.timedelta(days=ACTIVE_USER_WINDOW_DAYS), dt.time.min
    )
    active_ids = {
        row[0]
        for row in db.query(DailyStats.user_id)
        .filter(DailyStats.date >= activity_cutoff)
        .distinct()
        .all()
    }
    if not active_ids:
        return {"status": "success", "checked": 0, "sent": 0}

    users = (
        db.query(User)
        .filter(
            User.id.in_(active_ids),
            User.is_email_verified == True,  # noqa: E712
            User.is_banned == False,  # noqa: E712
        )
        .all()
    )

    sent = 0
    skipped_complete = 0
    skipped_dedup = 0
    failures = []
    for user in users:
        uid = str(user.id)
        if _already_sent(r, uid, day_key):
            skipped_dedup += 1
            continue

        done = _completed_poses_today(db, uid, local_today)
        remaining = len(REQUIRED_POSES - done)
        if remaining == 0:
            skipped_complete += 1
            continue

        title, body = _build_message(user, remaining)
        ok, err = _send_push(uid, title, body)
        if ok:
            _mark_sent(r, uid, day_key)
            sent += 1
        elif len(failures) < 5:
            failures.append({"user": user.email, "error": err})

    logger.info(
        "Progress photo reminder: %d checked, %d sent, %d already complete, %d deduped",
        len(users), sent, skipped_complete, skipped_dedup,
    )
    return {
        "status": "success",
        "checked": len(users),
        "sent": sent,
        "already_complete": skipped_complete,
        "skipped_already_reminded": skipped_dedup,
        "failures_sample": failures,
        "server_local_time": now_local.strftime("%H:%M"),
    }


def run_progress_photo_reminder_job():
    """Entry point for APScheduler — manages its own DB session."""
    from database import SessionLocal

    db = SessionLocal()
    try:
        run_progress_photo_reminder(db)
    except Exception:
        logger.exception("Progress photo reminder job failed")
    finally:
        db.close()
