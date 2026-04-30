import datetime
from sqlalchemy.orm import Session
from models import DailyStats, User
from utils.nutrition import calculate_daily_targets

def get_or_create_daily_stats(db: Session, user_id: str, date: datetime.date = None) -> DailyStats:
    if date is None:
        date = datetime.datetime.utcnow().date()
        
    stat = db.query(DailyStats).filter(
        DailyStats.user_id == user_id,
        DailyStats.date >= datetime.datetime.combine(date, datetime.time.min),
        DailyStats.date < datetime.datetime.combine(date + datetime.timedelta(days=1), datetime.time.min),
    ).first()

    if not stat:
        user = db.query(User).filter(User.id == user_id).first()
        weight_kg = (user.current_weight or 70.0) if user else 70.0
        goal_weight_kg = (user.goal_weight or 70.0) if user else 70.0
        age = (user.age or 30) if user else 30
        height_cm = (user.height or 170) if user else 170
        gender = (user.gender or "male") if user else "male"
        activity = (user.activity_level or "sedentary") if user else "sedentary"

        targets = calculate_daily_targets(
            weight_kg=weight_kg,
            height_cm=height_cm,
            age=age,
            gender=gender,
            activity_level=activity,
            goal_weight_kg=goal_weight_kg,
        )

        stat = DailyStats(
            user_id=user_id,
            date=datetime.datetime.combine(date, datetime.time.min),
            calorie_budget=(user.manual_calories if user else None) or targets["calorie_budget"],
            protein_target=(user.manual_protein if user else None) or targets["protein_target"],
            carbs_target=(user.manual_carbs if user else None) or targets["carbs_target"],
            fat_target=(user.manual_fat if user else None) or targets["fat_target"],
            calories_consumed=0, protein_consumed=0, carbs_consumed=0, fat_consumed=0,
        )
        db.add(stat)
        db.flush()
        
    return stat
