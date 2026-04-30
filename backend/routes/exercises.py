from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import datetime
from database import get_db
from models import ExerciseLog, DailyStats
from security import get_current_user_id
import uuid

router = APIRouter()

class ExerciseCreate(BaseModel):
    name: str
    duration_minutes: int
    calories_burned: int

class ExerciseResponse(BaseModel):
    id: str
    name: str
    duration_minutes: int
    calories_burned: int
    date: datetime.datetime

@router.post("/", response_model=ExerciseResponse)
def log_exercise(exercise: ExerciseCreate, current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        new_exercise = ExerciseLog(
            user_id=current_user_id,
            name=exercise.name,
            duration_minutes=exercise.duration_minutes,
            calories_burned=exercise.calories_burned
        )
        db.add(new_exercise)
        
        # Increase daily calorie budget
        today = datetime.datetime.utcnow().date()
        stat = db.query(DailyStats).filter(
            DailyStats.user_id == current_user_id,
            DailyStats.date >= datetime.datetime.combine(today, datetime.time.min),
            DailyStats.date < datetime.datetime.combine(today + datetime.timedelta(days=1), datetime.time.min)
        ).first()
        
        if not stat:
            stat = DailyStats(user_id=current_user_id, date=datetime.datetime.utcnow())
            db.add(stat)
            
        # Add burned calories to the budget
        stat.calorie_budget += exercise.calories_burned
        
        db.commit()
        db.refresh(new_exercise)
        
        # Invalidate Redis cache
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{today.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass
            
        return {
            "id": new_exercise.id,
            "name": new_exercise.name,
            "duration_minutes": new_exercise.duration_minutes,
            "calories_burned": new_exercise.calories_burned,
            "date": new_exercise.date
        }

@router.get("/", response_model=List[ExerciseResponse])
def get_exercises(current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        exercises = db.query(ExerciseLog).filter(ExerciseLog.user_id == current_user_id).order_by(ExerciseLog.date.desc()).all()
        return [
            {
                "id": ex.id,
                "name": ex.name,
                "duration_minutes": ex.duration_minutes,
                "calories_burned": ex.calories_burned,
                "date": ex.date
            } for ex in exercises
        ]

@router.delete("/{exercise_id}")
def delete_exercise(exercise_id: str, current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        ex = db.query(ExerciseLog).filter(ExerciseLog.id == exercise_id, ExerciseLog.user_id == current_user_id).first()
        if not ex:
            raise HTTPException(status_code=404, detail="Exercise not found")
            
        # Remove calories from budget
        ex_date = ex.date.date()
        stat = db.query(DailyStats).filter(
            DailyStats.user_id == current_user_id,
            DailyStats.date >= datetime.datetime.combine(ex_date, datetime.time.min),
            DailyStats.date < datetime.datetime.combine(ex_date + datetime.timedelta(days=1), datetime.time.min)
        ).first()
        
        if stat:
            stat.calorie_budget = max(0, stat.calorie_budget - ex.calories_burned)
            
        db.delete(ex)
        db.commit()
        
        # Invalidate Redis cache
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{ex_date.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass
            
        return {"status": "success"}
