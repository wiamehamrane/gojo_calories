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
    user_id: int
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
    db: Session = Depends(get_db), 
    current_user_id: int = Depends(get_current_user_id)
):
    import datetime as dt
    try:
        cache_key = f"stats_{current_user_id}_{date or 'latest'}"
        cached_stats = redis_db.get(cache_key)
        if cached_stats:
            return json.loads(cached_stats)
    except Exception:
        pass

    query = db.query(DailyStats).filter(DailyStats.user_id == current_user_id)
    
    if date:
        try:
            target_date = dt.datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(
                DailyStats.date >= dt.datetime.combine(target_date, dt.time.min),
                DailyStats.date < dt.datetime.combine(target_date + dt.timedelta(days=1), dt.time.min)
            )
        except ValueError:
            pass
            
    stats = query.order_by(DailyStats.date.desc()).limit(7).all()
    
    # Check if we have today's record. If not, synthesize it (and maybe persist it)
    today_utc = dt.datetime.utcnow().date()
    has_today = any(s.date.date() == today_utc for s in stats)
    
    if not has_today:
        user = db.query(User).filter(User.id == current_user_id).first()
        if user:
            from utils.nutrition import calculate_daily_targets
            targets = calculate_daily_targets(
                weight_kg=user.current_weight or 70.0,
                height_cm=user.height or 170,
                age=user.age or 30,
                gender=user.gender or "male",
                activity_level=user.activity_level or "sedentary",
                goal_weight_kg=user.goal_weight or 70.0
            )
            
            # create the record for today so it exists in the DB
            new_stat = DailyStats(
                user_id=current_user_id,
                date=dt.datetime.combine(today_utc, dt.time.min),
                calorie_budget=user.manual_calories or targets["calorie_budget"],
                protein_target=user.manual_protein or targets["protein_target"],
                carbs_target=user.manual_carbs or targets["carbs_target"],
                fat_target=user.manual_fat or targets["fat_target"],
                calories_consumed=0, protein_consumed=0, carbs_consumed=0, fat_consumed=0
            )
            db.add(new_stat)
            try:
                db.commit()
                db.refresh(new_stat)
                stats.insert(0, new_stat)
            except Exception:
                db.rollback()
    
    stats_data = [{
        "user_id": s.user_id, 
        "calorie_budget": s.calorie_budget, 
        "calories_consumed": s.calories_consumed, 
        "protein_consumed": s.protein_consumed, 
        "carbs_consumed": s.carbs_consumed, 
        "fat_consumed": s.fat_consumed,
        "protein_target": s.protein_target,
        "carbs_target": s.carbs_target,
        "fat_target": s.fat_target
    } for s in stats]
    
    try:
        redis_db.setex(cache_key, 300, json.dumps(stats_data))
    except Exception:
        pass
    
    return stats_data


@router.get("/weekly")
def get_weekly_stats(
    local_today: Optional[str] = Query(None, description="User's local today date YYYY-MM-DD"),
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
):
    """Returns exactly 7 days of stats (local_today and 6 days back), zero-filling missing days."""
    if local_today:
        try:
            today = dt.datetime.strptime(local_today, "%Y-%m-%d").date()
        except ValueError:
            today = dt.datetime.utcnow().date()
    else:
        today = dt.datetime.utcnow().date()

    start = today - dt.timedelta(days=6)

    # Fetch any existing rows in this window
    rows = db.query(DailyStats).filter(
        DailyStats.user_id == current_user_id,
        DailyStats.date >= dt.datetime.combine(start, dt.time.min),
        DailyStats.date < dt.datetime.combine(today + dt.timedelta(days=1), dt.time.min),
    ).all()

    # Build a lookup keyed by date
    row_by_date = {r.date.date(): r for r in rows}

    result = []
    for i in range(7):
        day = start + dt.timedelta(days=i)
        row = row_by_date.get(day)
        result.append({
            "date": day.isoformat(),
            "calories_consumed": row.calories_consumed if row else 0,
            "protein_consumed": row.protein_consumed if row else 0,
            "carbs_consumed": row.carbs_consumed if row else 0,
            "fat_consumed": row.fat_consumed if row else 0,
        })

    return result


@router.get("/streak")
def get_streak(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    """Return the user's current logging streak (consecutive days with calories_consumed > 0)."""
    import datetime as dt
    today = dt.datetime.utcnow().date()
    streak = 0
    check_date = today

    while True:
        stat = db.query(DailyStats).filter(
            DailyStats.user_id == current_user_id,
            DailyStats.date >= dt.datetime.combine(check_date, dt.time.min),
            DailyStats.date < dt.datetime.combine(check_date + dt.timedelta(days=1), dt.time.min),
        ).first()

        if stat and stat.calories_consumed > 0:
            streak += 1
            check_date -= dt.timedelta(days=1)
        # If it's today and they haven't logged yet, don't break the streak from yesterday
        elif check_date == today:
            check_date -= dt.timedelta(days=1)
        else:
            break

    return {"streak": streak}


@router.get("/history")
def get_user_history(
    date: Optional[str] = None,
    db: Session = Depends(get_db), 
    current_user_id: int = Depends(get_current_user_id)
):
    from models import FoodLog
    query = db.query(FoodLog).filter(FoodLog.user_id == current_user_id)
    
    if date:
        try:
            target_date = dt.datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(
                FoodLog.created_at >= dt.datetime.combine(target_date, dt.time.min),
                FoodLog.created_at < dt.datetime.combine(target_date + dt.timedelta(days=1), dt.time.min)
            )
        except ValueError:
            pass

    logs = query.order_by(FoodLog.created_at.desc()).limit(10).all()
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
            "created_at": log.created_at,
        })
    return res


@router.get("/progress/weigh-ins")
def get_weigh_ins(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
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
    current_user_id: int,
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
        user = db.query(User).filter(User.id == current_user_id).first()
        weigh_in_weight = (user.current_weight or 70.0) if user else 70.0
        goal_wt = (user.goal_weight or 70.0) if user else 70.0
        age = (user.age or 30) if user else 30
        height_cm = (user.height or 170) if user else 170
        gender = (user.gender or "male") if user else "male"
        activity = (user.activity_level or "sedentary") if user else "sedentary"

        from utils.nutrition import calculate_daily_targets
        targets = calculate_daily_targets(
            weight_kg=weigh_in_weight,
            height_cm=height_cm,
            age=age,
            gender=gender,
            activity_level=activity,
            goal_weight_kg=goal_wt,
        )

        stat = DailyStats(
            user_id=current_user_id,
            date=datetime.datetime.combine(today, datetime.time.min),
            calorie_budget=(user.manual_calories if user else None) or targets["calorie_budget"],
            protein_target=(user.manual_protein if user else None) or targets["protein_target"],
            carbs_target=(user.manual_carbs if user else None) or targets["carbs_target"],
            fat_target=(user.manual_fat if user else None) or targets["fat_target"],
            calories_consumed=0, protein_consumed=0, carbs_consumed=0, fat_consumed=0,
        )
        db.add(stat)
        db.flush()

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
    current_user_id: int = Depends(get_current_user_id),
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
