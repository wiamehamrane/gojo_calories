from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
import datetime
import logging
from sqlalchemy import or_, and_
from database import get_db
from models import ExerciseLog, DailyStats
from security import get_current_user_id

logger = logging.getLogger(__name__)

router = APIRouter()

class ExerciseCreate(BaseModel):
    name: str
    duration_minutes: int
    calories_burned: int
    local_date: Optional[str] = None

class ExerciseResponse(BaseModel):
    id: str
    name: str
    duration_minutes: int
    calories_burned: int
    date: datetime.datetime
    log_date: Optional[datetime.date] = None

class ExerciseAnalyzeRequest(BaseModel):
    description: str

class ExerciseAnalyzeResponse(BaseModel):
    name: str
    duration_minutes: int
    calories_burned: int

def _resolve_log_date(local_date: Optional[str]) -> datetime.date:
    if local_date:
        try:
            return datetime.datetime.strptime(local_date, "%Y-%m-%d").date()
        except ValueError:
            pass
    return datetime.datetime.utcnow().date()

def _serialize_exercise(ex: ExerciseLog) -> dict:
    return {
        "id": ex.id,
        "name": ex.name,
        "duration_minutes": ex.duration_minutes,
        "calories_burned": ex.calories_burned,
        "date": ex.date,
        "log_date": ex.log_date.isoformat() if ex.log_date else None,
    }

@router.post("/analyze", response_model=ExerciseAnalyzeResponse)
def analyze_exercise_description(
    body: ExerciseAnalyzeRequest,
    current_user_id: str = Depends(get_current_user_id),
):
    description = body.description.strip()
    if not description:
        raise HTTPException(status_code=422, detail="Description is required.")

    from routes.vision import _generate_food_json

    prompt = f"""
You are a fitness and calorie estimation expert for a calorie-tracking app.

The user describes their workout in natural language:
"{description}"

Estimate the total workout and respond ONLY with a raw JSON object. No markdown, no code fences, no explanations.

Rules:
- "name": a short label for the workout (e.g. "Basketball + Push-ups")
- "duration_minutes": total active time in minutes (integer, at least 1)
- "calories_burned": estimated calories burned for a typical adult (integer, at least 1)
- If multiple activities are described, combine them into one entry with summed duration and calories
- Be realistic based on intensity cues in the description (e.g. "intense", "light walk")

Schema:
{{"name": "Activity Name", "duration_minutes": 45, "calories_burned": 320}}
"""

    logger.info("Calling OpenAI exercise analysis for user %s", current_user_id)
    data, _raw = _generate_food_json(prompt)

    if data.get("error"):
        raise HTTPException(
            status_code=422,
            detail="Could not understand the exercise description. Please try again.",
        )

    name = str(data.get("name") or "Workout").strip() or "Workout"
    duration = int(data.get("duration_minutes") or 0)
    calories = int(data.get("calories_burned") or 0)

    if duration < 1 or calories < 1:
        raise HTTPException(
            status_code=422,
            detail="AI could not estimate this workout. Try adding duration and intensity.",
        )

    return {
        "name": name,
        "duration_minutes": duration,
        "calories_burned": calories,
    }

@router.post("/", response_model=ExerciseResponse)
def log_exercise(exercise: ExerciseCreate, current_user_id: str = Depends(get_current_user_id)):
    log_date = _resolve_log_date(exercise.local_date)

    with next(get_db()) as db:
        new_exercise = ExerciseLog(
            user_id=current_user_id,
            name=exercise.name,
            duration_minutes=exercise.duration_minutes,
            calories_burned=exercise.calories_burned,
            log_date=log_date,
        )
        db.add(new_exercise)
        
        from utils.stats_utils import get_or_create_daily_stats
        stat = get_or_create_daily_stats(db, current_user_id, log_date)
        stat.calorie_budget += exercise.calories_burned
        
        db.commit()
        db.refresh(new_exercise)
        
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{log_date.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass
            
        return _serialize_exercise(new_exercise)

@router.get("/", response_model=List[ExerciseResponse])
def get_exercises(
    date: Optional[str] = Query(None, description="User local date YYYY-MM-DD"),
    tz_offset: Optional[int] = Query(0, description="Timezone offset in minutes"),
    current_user_id: str = Depends(get_current_user_id),
):
    with next(get_db()) as db:
        query = db.query(ExerciseLog).filter(ExerciseLog.user_id == current_user_id)

        if date:
            try:
                target_date = datetime.datetime.strptime(date, "%Y-%m-%d").date()
                offset = tz_offset or 0
                local_midnight = datetime.datetime.combine(target_date, datetime.time.min)
                window_start = local_midnight - datetime.timedelta(minutes=offset)
                window_end = window_start + datetime.timedelta(days=1)
                query = query.filter(
                    or_(
                        ExerciseLog.log_date == target_date,
                        and_(
                            ExerciseLog.log_date.is_(None),
                            ExerciseLog.date >= window_start,
                            ExerciseLog.date < window_end,
                        ),
                    )
                )
            except ValueError:
                pass

        exercises = query.order_by(ExerciseLog.date.desc()).limit(50).all()
        return [_serialize_exercise(ex) for ex in exercises]

@router.delete("/{exercise_id}")
def delete_exercise(exercise_id: str, current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        ex = db.query(ExerciseLog).filter(ExerciseLog.id == exercise_id, ExerciseLog.user_id == current_user_id).first()
        if not ex:
            raise HTTPException(status_code=404, detail="Exercise not found")

        budget_date = ex.log_date or ex.date.date()
        stat = db.query(DailyStats).filter(
            DailyStats.user_id == current_user_id,
            DailyStats.date >= datetime.datetime.combine(budget_date, datetime.time.min),
            DailyStats.date < datetime.datetime.combine(budget_date + datetime.timedelta(days=1), datetime.time.min)
        ).first()
        
        if stat:
            stat.calorie_budget = max(0, stat.calorie_budget - ex.calories_burned)
            
        db.delete(ex)
        db.commit()
        
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{budget_date.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass
            
        return {"status": "success"}
