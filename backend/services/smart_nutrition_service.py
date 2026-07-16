"""Smart nutrition push notifications.

Runs every 2-3 hours (APScheduler in main.py, or manual trigger via
POST /api/notifications/nutrition-check). For each active user it compares
today's DailyStats against their targets and sends ONE personalized
OneSignal push, addressed by first name, e.g.:

  "Good job Mohamed! You've eaten 80 g of protein — only 40 g left.
   Don't forget to prepare a high-protein dinner."

Rules (evaluated in priority order, local time):
  1. overeat          any time    calories > 110% of budget  -> suggest a workout
  2. no_food          11:00-14:00 nothing logged yet         -> morning-is-over reminder
  3. protein_evening  >= 18:00    protein < 75% of target    -> high-protein dinner reminder
  4. day_win          >= 18:00    protein hit & calories OK  -> congratulate
  5. on_track         12:00-18:00 ~half of budget eaten      -> praise + remaining protein

Anti-spam: max one push per run, each rule fires at most once per day per
user, and at most MAX_PER_DAY pushes per user per day. Quiet hours outside
10:00-22:00 local. Dedup state lives in Redis (falls back to in-memory).

Audience: users with DailyStats in the last 7 days. During the no_food
window (11:00-14:00) every verified non-banned user is also considered,
so people who never logged still get the missed-meal reminder.
"""

import datetime as dt
import logging
import os
from typing import List, Optional, Tuple

import requests
from sqlalchemy.orm import Session

from models import User, DailyStats

logger = logging.getLogger(__name__)

ONESIGNAL_APP_ID = os.getenv("ONESIGNAL_APP_ID", "60019fa3-3a1b-4c1e-a4dc-22ac49dc32de")
ONESIGNAL_REST_API_KEY = os.getenv("ONESIGNAL_REST_API_KEY", "")
ONESIGNAL_API_URL = "https://onesignal.com/api/v1/notifications"

# Local-time handling: users' devices pass tz_offset per request, but the
# scheduler has no request context. Configure the user base's timezone
# offset (in minutes from UTC) via env. Example: 60 = UTC+1.
TZ_OFFSET_MIN = int(os.getenv("SMART_NOTIF_TZ_OFFSET_MIN", "60"))

QUIET_START_HOUR = 22   # no pushes at/after 22:00 local
ACTIVE_START_HOUR = 10  # no pushes before 10:00 local
MAX_PER_DAY = 3         # hard cap of smart pushes per user per day
ACTIVE_USER_WINDOW_DAYS = 7  # only notify users with stats in the last week

# ── Dedup state (Redis with in-memory fallback) ──────────────────────────────
_memory_state = {}


def _redis():
    try:
        from redis_client import redis_db
        redis_db.ping()
        return redis_db
    except Exception:
        return None


def _already_sent(r, user_id: str, day: str, rule: str) -> bool:
    key = f"smartnotif:{user_id}:{day}:{rule}"
    if r:
        try:
            return bool(r.exists(key))
        except Exception:
            pass
    return key in _memory_state


def _sent_count(r, user_id: str, day: str) -> int:
    key = f"smartnotif:count:{user_id}:{day}"
    if r:
        try:
            return int(r.get(key) or 0)
        except Exception:
            pass
    return _memory_state.get(key, 0)


def _mark_sent(r, user_id: str, day: str, rule: str):
    rule_key = f"smartnotif:{user_id}:{day}:{rule}"
    count_key = f"smartnotif:count:{user_id}:{day}"
    if r:
        try:
            r.setex(rule_key, 60 * 60 * 36, "1")
            pipe = r.pipeline()
            pipe.incr(count_key)
            pipe.expire(count_key, 60 * 60 * 36)
            pipe.execute()
            return
        except Exception:
            pass
    _memory_state[rule_key] = True
    _memory_state[count_key] = _memory_state.get(count_key, 0) + 1


# ── Push delivery ────────────────────────────────────────────────────────────

def _send_push(user_id: str, title: str, body: str) -> bool:
    if not ONESIGNAL_REST_API_KEY:
        return False
    payload = {
        "app_id": ONESIGNAL_APP_ID,
        "include_aliases": {"external_id": [user_id]},
        "target_channel": "push",
        "headings": {"en": title},
        "contents": {"en": body},
    }
    headers = {
        "Authorization": f"Basic {ONESIGNAL_REST_API_KEY}",
        "Content-Type": "application/json",
    }
    try:
        resp = requests.post(ONESIGNAL_API_URL, json=payload, headers=headers, timeout=15)
        return resp.status_code < 400
    except requests.RequestException:
        return False


# ── Message building ─────────────────────────────────────────────────────────

def _first_name(user: User) -> str:
    if user.name and user.name.strip():
        return user.name.strip().split()[0].capitalize()
    return "there"


def _build_message(rule: str, user: User, stats: dict) -> Tuple[str, str]:
    name = _first_name(user)
    cal = stats["calories"]
    budget = stats["budget"]
    protein = stats["protein"]
    protein_target = stats["protein_target"]
    protein_left = max(0, protein_target - protein)
    excess = max(0, cal - budget)

    if rule == "overeat":
        return (
            "Time to move 🏃",
            f"{name}, you've eaten {cal} kcal today — about {excess} kcal over your "
            f"{budget} kcal budget. A workout or a brisk walk would balance it out. You've got this!",
        )
    if rule == "no_food":
        return (
            "Don't skip your fuel 🍳",
            f"{name}, the morning is almost over and you haven't logged anything yet. "
            f"Eat something nutritious and log it — your body needs fuel to perform!",
        )
    if rule == "protein_evening":
        return (
            "Protein check 🥩",
            f"{name}, the day is ending and you're at {protein} g of protein out of "
            f"{protein_target} g. Only {protein_left} g to go — prepare a high-protein dinner!",
        )
    if rule == "day_win":
        return (
            "You crushed it today 🏆",
            f"Amazing work {name}! You hit {protein} g of protein and stayed within your "
            f"calorie budget ({cal}/{budget} kcal). Keep this streak going!",
        )
    # on_track
    return (
        "Good job, keep it up 💪",
        f"Good job {name}! You've eaten {protein} g of protein — only {protein_left} g "
        f"left to hit your goal. You're at {cal}/{budget} kcal, right on track. "
        f"Plan a high-protein meal for later!",
    )


# ── Core decision logic ──────────────────────────────────────────────────────

def _pick_rule(hour: int, stats: dict) -> Optional[str]:
    cal = stats["calories"]
    budget = max(1, stats["budget"])
    protein = stats["protein"]
    protein_target = max(1, stats["protein_target"])

    if cal > budget * 1.10:
        return "overeat"
    if 11 <= hour < 14 and cal == 0:
        return "no_food"
    if hour >= 18:
        if 0 < cal <= budget and protein >= protein_target:
            return "day_win"
        if cal > 0 and protein < protein_target * 0.75:
            return "protein_evening"
        return None
    if 12 <= hour < 18:
        good_pace = budget * 0.35 <= cal <= budget * 0.75
        if good_pace and protein > 0:
            return "on_track"
    return None


def _today_stats(db: Session, user_id: str, local_today: dt.date) -> dict:
    """DailyStats rows are keyed by local date at midnight (see routes/stats.py)."""
    start = dt.datetime.combine(local_today, dt.time.min)
    end = start + dt.timedelta(days=1)
    row = (
        db.query(DailyStats)
        .filter(DailyStats.user_id == user_id, DailyStats.date >= start, DailyStats.date < end)
        .first()
    )
    if row:
        return {
            "calories": row.calories_consumed or 0,
            "budget": row.calorie_budget or 2200,
            "protein": row.protein_consumed or 0,
            "protein_target": row.protein_target or 150,
        }
    return {"calories": 0, "budget": 2200, "protein": 0, "protein_target": 150}


def run_nutrition_check(db: Session) -> dict:
    """Evaluate every active user and send at most one smart push each."""
    if not ONESIGNAL_REST_API_KEY:
        logger.warning("Smart nutrition check skipped: ONESIGNAL_REST_API_KEY not set")
        return {"status": "skipped", "reason": "ONESIGNAL_REST_API_KEY not configured"}

    now_local = dt.datetime.utcnow() + dt.timedelta(minutes=TZ_OFFSET_MIN)
    hour = now_local.hour
    if hour < ACTIVE_START_HOUR or hour >= QUIET_START_HOUR:
        return {"status": "skipped", "reason": f"quiet hours (local {now_local:%H:%M})"}

    local_today = now_local.date()
    day_key = local_today.isoformat()
    r = _redis()

    # Users active in the last week (recent DailyStats rows).
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

    # During the no_food window, also include verified users with no recent
    # logs — otherwise the "nothing logged" reminder can never reach them.
    in_no_food_window = 11 <= hour < 14
    if in_no_food_window:
        users: List[User] = (
            db.query(User)
            .filter(User.is_email_verified == True, User.is_banned == False)  # noqa: E712
            .all()
        )
    else:
        if not active_ids:
            return {"status": "success", "checked": 0, "sent": 0, "breakdown": {}}
        users = (
            db.query(User)
            .filter(User.id.in_(active_ids), User.is_email_verified == True, User.is_banned == False)  # noqa: E712
            .all()
        )

    sent = 0
    breakdown = {}
    for user in users:
        uid = str(user.id)
        if _sent_count(r, uid, day_key) >= MAX_PER_DAY:
            continue

        stats = _today_stats(db, uid, local_today)
        rule = _pick_rule(hour, stats)
        if not rule or _already_sent(r, uid, day_key, rule):
            continue

        title, body = _build_message(rule, user, stats)
        if _send_push(uid, title, body):
            _mark_sent(r, uid, day_key, rule)
            sent += 1
            breakdown[rule] = breakdown.get(rule, 0) + 1

    logger.info("Smart nutrition check: %d users checked, %d pushes sent %s", len(users), sent, breakdown)
    return {"status": "success", "checked": len(users), "sent": sent, "breakdown": breakdown}


def run_nutrition_check_job():
    """Entry point for APScheduler — manages its own DB session."""
    from database import SessionLocal

    db = SessionLocal()
    try:
        run_nutrition_check(db)
    except Exception:
        logger.exception("Smart nutrition check job failed")
    finally:
        db.close()
