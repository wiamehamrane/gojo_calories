from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import DailyStats, User, WeighIn
from pydantic import BaseModel
from typing import List
from security import get_current_user_id
import json
from redis_client import redis_db

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
def get_user_stats(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    try:
        cache_key = f"stats_{current_user_id}"
        cached_stats = redis_db.get(cache_key)
        if cached_stats:
            return json.loads(cached_stats)
    except Exception:
        pass  # Redis unavailable in this env, proceed without cache

    # Get last 7 days of stats
    stats = db.query(DailyStats).filter(DailyStats.user_id == current_user_id).order_by(DailyStats.date.desc()).limit(7).all()
    if not stats:
        return []
    
    # Cache result before returning
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

@router.get("/streak")
def get_streak(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    """Return the user's current logging streak (consecutive days with calories_consumed > 0)."""
    import datetime as dt
    today = dt.datetime.utcnow().date()
    streak = 0
    check_date = today

    while True:
        # We need to query for the day's record using the date portion
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
def get_user_history(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    from models import FoodLog
    logs = db.query(FoodLog).filter(FoodLog.user_id == current_user_id).order_by(FoodLog.created_at.desc()).limit(10).all()
    res = []
    for log in logs:
        res.append({
            "meal_name": log.name,
            "calories": log.calories,
            "created_at": log.created_at
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

@router.post("/log")
def log_macro(calories: int, protein: int, carbs: int, fat: int, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    import datetime
    stat = db.query(DailyStats).filter(DailyStats.user_id == current_user_id).order_by(DailyStats.date.desc()).first()
    
    today = datetime.datetime.utcnow().date()
    # Check if a stat exists for today, else create a new one
    if not stat or stat.date.date() != today:
        user = db.query(User).filter(User.id == current_user_id).first()
        weigh_in_weight = user.current_weight or 70.0
        goal_wt = user.goal_weight or 70.0
        age = user.age or 30
        
        bmr = (10 * weigh_in_weight) + (6.25 * 170) - (5 * age) + 5
        calorie_budget = int(bmr * 1.2)
        if goal_wt < weigh_in_weight - 1.0: calorie_budget -= 500
        elif goal_wt > weigh_in_weight + 1.0: calorie_budget += 500
            
        protein_t = int(weigh_in_weight * 2.0)
        fat_t = int((calorie_budget * 0.25) / 9)
        carbs_t = int((calorie_budget - (protein_t * 4) - (fat_t * 9)) / 4)
        if carbs_t < 0: carbs_t = 0
            
        new_stat = DailyStats(
            user_id=current_user_id, 
            date=datetime.datetime.utcnow(), 
            calorie_budget=calorie_budget,
            protein_target=protein_t,
            carbs_target=carbs_t,
            fat_target=fat_t,
            calories_consumed=0, protein_consumed=0, carbs_consumed=0, fat_consumed=0
        )
        db.add(new_stat)
        db.commit()
        db.refresh(new_stat)
        stat = new_stat
        
    stat.calories_consumed += calories
    stat.protein_consumed += protein
    stat.carbs_consumed += carbs
    stat.fat_consumed += fat
    
    db.commit()
    db.refresh(stat)
    
    # Invalidate cache
    try:
        redis_db.delete(f"stats_{current_user_id}")
    except Exception:
        pass

    return {"status": "success", "consumed": stat.calories_consumed}
