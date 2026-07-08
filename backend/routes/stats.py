from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import DailyStats, User, WeighIn
from pydantic import BaseModel
from typing import List, Optional
from security import get_current_user_id
import json
from redis_client import redis_db
import datetime as dt
import models

router = APIRouter()

class StatsResponse(BaseModel):
    user_id: str
    calorie_budget: int
    calories_consumed: int
    protein_consumed: int
    carbs_consumed: int
    fat_consumed: int
    protein_target: int = 150
    carbs_target: int = 200
    fat_target: int = 65

@router.get("/", response_model=List[StatsResponse])
def get_user_stats(
    date: Optional[str] = None,
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db), 
    current_user_id: str = Depends(get_current_user_id)
):
    """Returns daily stats computed live from FoodLog (source of truth) for the requested date."""
    import datetime as dt
    from models import FoodLog

    # Determine the target date
    if date:
        try:
            target_date = dt.datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            target_date = dt.datetime.utcnow().date()
    else:
        target_date = dt.datetime.utcnow().date()

    # Get or create DailyStats for budget/targets (these are set by user profile)
    from utils.stats_utils import get_or_create_daily_stats
    stat = get_or_create_daily_stats(db, current_user_id, target_date)

    # Compute actual consumed macros by summing FoodLog entries for that local date
    # Convert local date window to UTC window using tz_offset
    offset = tz_offset or 0
    local_midnight = dt.datetime.combine(target_date, dt.time.min)
    window_start = local_midnight - dt.timedelta(minutes=offset)
    window_end = window_start + dt.timedelta(days=1)

    logs = db.query(FoodLog).filter(
        FoodLog.user_id == current_user_id,
        FoodLog.created_at >= window_start,
        FoodLog.created_at < window_end,
    ).all()

    calories_consumed = sum(log.calories or 0 for log in logs)
    protein_consumed = sum(log.protein or 0 for log in logs)
    carbs_consumed = sum(log.carbs or 0 for log in logs)
    fat_consumed = sum(log.fat or 0 for log in logs)

    # Update DailyStats so streak/history stays accurate
    if stat.calories_consumed != calories_consumed:
        stat.calories_consumed = calories_consumed
        stat.protein_consumed = protein_consumed
        stat.carbs_consumed = carbs_consumed
        stat.fat_consumed = fat_consumed
        db.commit()
        db.refresh(stat)

    result = [{
        "user_id": stat.user_id,
        "calorie_budget": stat.calorie_budget,
        "calories_consumed": calories_consumed,
        "protein_consumed": protein_consumed,
        "carbs_consumed": carbs_consumed,
        "fat_consumed": fat_consumed,
        "protein_target": stat.protein_target,
        "carbs_target": stat.carbs_target,
        "fat_target": stat.fat_target,
    }]

    return result


@router.get("/weekly")
def get_weekly_stats(
    local_today: Optional[str] = Query(None, description="User's local today date YYYY-MM-DD"),
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Returns 7 days of aggregated stats (by local date), derived from FoodLog (source of truth).
    DailyStats rows can be timezone-misaligned; FoodLog.created_at is always accurate."""
    from models import FoodLog

    if local_today:
        try:
            today = dt.datetime.strptime(local_today, "%Y-%m-%d").date()
        except ValueError:
            today = dt.datetime.utcnow().date()
    else:
        today = dt.datetime.utcnow().date()

    start = today - dt.timedelta(days=6)

    # Fetch all food logs in the 8-day window (±1 day for timezone safety)
    window_start = dt.datetime.combine(start - dt.timedelta(days=1), dt.time.min)
    window_end = dt.datetime.combine(today + dt.timedelta(days=2), dt.time.min)
    logs = db.query(FoodLog).filter(
        FoodLog.user_id == current_user_id,
        FoodLog.created_at >= window_start,
        FoodLog.created_at < window_end,
    ).all()

    from collections import defaultdict
    day_totals: dict = defaultdict(lambda: {"calories_consumed": 0, "protein_consumed": 0, "carbs_consumed": 0, "fat_consumed": 0})

    for log in logs:
        # Shift UTC to local date using the provided offset
        local_dt = log.created_at + dt.timedelta(minutes=tz_offset or 0)
        local_date = local_dt.date()
        if start <= local_date <= today:
            day_totals[local_date]["calories_consumed"] += log.calories or 0
            day_totals[local_date]["protein_consumed"] += log.protein or 0
            day_totals[local_date]["carbs_consumed"] += log.carbs or 0
            day_totals[local_date]["fat_consumed"] += log.fat or 0

    result = []
    for i in range(7):
        day = start + dt.timedelta(days=i)
        totals = day_totals.get(day, {})
        result.append({
            "date": day.isoformat(),
            "calories_consumed": totals.get("calories_consumed", 0),
            "protein_consumed": totals.get("protein_consumed", 0),
            "carbs_consumed": totals.get("carbs_consumed", 0),
            "fat_consumed": totals.get("fat_consumed", 0),
        })

    return result


@router.get("/calendar-progress")
def get_calendar_progress(
    end_date: Optional[str] = Query(None, description="Last day in range YYYY-MM-DD"),
    days: int = Query(366, ge=1, le=366),
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Per-day calorie budget vs consumed for the scrollable home calendar."""
    from models import FoodLog
    from utils.nutrition import calculate_daily_targets
    from collections import defaultdict

    if end_date:
        try:
            end = dt.datetime.strptime(end_date, "%Y-%m-%d").date()
        except ValueError:
            end = dt.datetime.utcnow().date()
    else:
        end = dt.datetime.utcnow().date()

    start = end - dt.timedelta(days=days - 1)
    offset = tz_offset or 0

    user = db.query(User).filter(User.id == current_user_id).first()
    default_budget = 2200
    if user:
        if user.manual_calories:
            default_budget = user.manual_calories
        else:
            weight_kg = user.current_weight or 70.0
            goal_weight_kg = user.goal_weight or 70.0
            targets = calculate_daily_targets(
                weight_kg=weight_kg,
                height_cm=user.height or 170,
                age=user.age or 30,
                gender=user.gender or "male",
                activity_level=user.activity_level or "sedentary",
                goal_weight_kg=goal_weight_kg,
            )
            default_budget = targets["calorie_budget"]

    stats_rows = db.query(DailyStats).filter(
        DailyStats.user_id == current_user_id,
        DailyStats.date >= dt.datetime.combine(start, dt.time.min),
        DailyStats.date < dt.datetime.combine(end + dt.timedelta(days=1), dt.time.min),
    ).all()

    budget_by_date: dict = {}
    for stat in stats_rows:
        stat_day = stat.date.date() if hasattr(stat.date, "date") else stat.date
        budget_by_date[stat_day] = stat.calorie_budget

    window_start = (
        dt.datetime.combine(start, dt.time.min) - dt.timedelta(minutes=offset)
    )
    window_end = (
        dt.datetime.combine(end + dt.timedelta(days=1), dt.time.min)
        - dt.timedelta(minutes=offset)
    )
    logs = db.query(FoodLog).filter(
        FoodLog.user_id == current_user_id,
        FoodLog.created_at >= window_start,
        FoodLog.created_at < window_end,
    ).all()

    consumed_by_date: dict = defaultdict(int)
    for log in logs:
        local_date = (log.created_at + dt.timedelta(minutes=offset)).date()
        if start <= local_date <= end:
            consumed_by_date[local_date] += log.calories or 0

    result = []
    for i in range(days):
        day = start + dt.timedelta(days=i)
        budget = budget_by_date.get(day, default_budget)
        consumed = consumed_by_date.get(day, 0)
        result.append({
            "date": day.isoformat(),
            "calorie_budget": budget,
            "calories_consumed": consumed,
        })

    return result


@router.get("/streak")
def get_streak(
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """Return the user's current logging streak computed from FoodLog (source of truth).
    A day counts if at least one food item was logged on that local date."""
    import datetime as dt
    from models import FoodLog

    offset = tz_offset or 0
    today_local = (dt.datetime.utcnow() + dt.timedelta(minutes=offset)).date()

    streak = 0
    check_date = today_local
    # Allow today to not count yet (don't break the streak if user hasn't logged today)
    skip_today_check = True

    while True:
        # Build UTC window for this local date
        local_midnight = dt.datetime.combine(check_date, dt.time.min)
        window_start = local_midnight - dt.timedelta(minutes=offset)
        window_end = window_start + dt.timedelta(days=1)

        count = db.query(FoodLog).filter(
            FoodLog.user_id == current_user_id,
            FoodLog.created_at >= window_start,
            FoodLog.created_at < window_end,
        ).count()

        if count > 0:
            streak += 1
            skip_today_check = False
            check_date -= dt.timedelta(days=1)
        elif skip_today_check:
            # Today hasn't been logged yet — check yesterday before giving up
            skip_today_check = False
            check_date -= dt.timedelta(days=1)
        else:
            break

        # Safety: stop after 365 days
        if (today_local - check_date).days > 365:
            break

    return {"streak": streak}


@router.get("/history")
def get_user_history(
    date: Optional[str] = None,
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes (e.g. 60 for UTC+1)"),
    db: Session = Depends(get_db), 
    current_user_id: str = Depends(get_current_user_id)
):
    from models import FoodLog
    query = db.query(FoodLog).filter(FoodLog.user_id == current_user_id)
    
    if date:
        try:
            target_date = dt.datetime.strptime(date, "%Y-%m-%d").date()
            # Calculate UTC window for this local date
            # local 00:00 = UTC 00:00 - offset
            local_midnight = dt.datetime.combine(target_date, dt.time.min)
            window_start = local_midnight - dt.timedelta(minutes=tz_offset or 0)
            window_end = window_start + dt.timedelta(days=1)
            
            query = query.filter(
                FoodLog.created_at >= window_start,
                FoodLog.created_at < window_end,
            )
        except ValueError:
            pass

    logs = query.order_by(FoodLog.created_at.desc()).limit(50).all()
    res = []
    for log in logs:
        res.append({
            "id": log.id,
            "meal_name": log.name,
            "name_en": log.name_en,
            "name_fr": log.name_fr,
            "name_ar": log.name_ar,
            "calories": log.calories,
            "image_url": log.image_url,
            "protein": log.protein,
            "carbs": log.carbs,
            "fat": log.fat,
            "ingredients": log.ingredients,
            "created_at": log.created_at.isoformat() + "Z",
        })
    return res


@router.get("/progress/weigh-ins")
def get_weigh_ins(db: Session = Depends(get_db), current_user_id: str = Depends(get_current_user_id)):
    records = db.query(WeighIn).filter(WeighIn.user_id == current_user_id).order_by(WeighIn.date.asc()).all()
    res = []
    for r in records:
        res.append({
            "weight": r.weight,
            "date": r.date.isoformat()
        })
    return res


def _log_macro_with_date(
    calories: int,
    protein: int,
    carbs: int,
    fat: int,
    db: Session,
    current_user_id: str,
    local_date: "dt.date | None" = None,
):
    """Update DailyStats for the given local date (or UTC today as fallback)."""
    import datetime

    today = local_date or datetime.datetime.utcnow().date()

    stat = db.query(DailyStats).filter(
        DailyStats.user_id == current_user_id,
        DailyStats.date >= datetime.datetime.combine(today, datetime.time.min),
        DailyStats.date < datetime.datetime.combine(today + datetime.timedelta(days=1), datetime.time.min),
    ).first()

    if not stat:
        from utils.stats_utils import get_or_create_daily_stats
        stat = get_or_create_daily_stats(db, current_user_id, today)

    stat.calories_consumed += calories
    stat.protein_consumed += protein
    stat.carbs_consumed += carbs
    stat.fat_consumed += fat

    db.commit()
    db.refresh(stat)

    # Invalidate cache
    try:
        redis_db.delete(f"stats_{current_user_id}")
        redis_db.delete(f"stats_{current_user_id}_{today.isoformat()}")
        redis_db.delete(f"stats_{current_user_id}_latest")
    except Exception:
        pass

    return stat


@router.post("/log")
def log_macro(
    calories: int,
    protein: int,
    carbs: int,
    fat: int,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    stat = _log_macro_with_date(
        calories=calories,
        protein=protein,
        carbs=carbs,
        fat=fat,
        db=db,
        current_user_id=current_user_id,
    )
    return {"status": "success", "consumed": stat.calories_consumed}
