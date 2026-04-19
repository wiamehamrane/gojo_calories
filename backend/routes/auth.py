import random
import string
import os
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User, Referral, WeighIn, DailyStats
from pydantic import BaseModel
from typing import Optional
from security import get_password_hash, verify_password, create_access_token, get_current_user_id
import datetime

router = APIRouter()


def _generate_code(length: int = 6) -> str:
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


class UserCreate(BaseModel):
    email: str
    name: str
    password: str
    referral_code: Optional[str] = None

class UserWeightUpdate(BaseModel):
    current_weight: float
    goal_weight: float
    weight_unit: str
    age: Optional[int] = None

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    age: Optional[int] = None
    current_password: Optional[str] = None
    new_password: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)

    while True:
        new_code = _generate_code()
        if not db.query(User).filter(User.referral_code == new_code).first():
            break

    new_user = User(
        email=user.email,
        name=user.name,
        hashed_password=hashed_password,
        referral_code=new_code,
        referral_balance=0.0,
    )

    referrer = None
    if user.referral_code:
        referrer = db.query(User).filter(User.referral_code == user.referral_code.upper()).first()
        if referrer:
            new_user.referred_by = referrer.id

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if referrer:
        referrer.referral_balance = round(referrer.referral_balance + 1.0, 2)
        referral_record = Referral(
            referrer_id=referrer.id,
            referred_user_id=new_user.id,
            amount=1.0,
        )
        db.add(referral_record)
        db.commit()
    
    access_token = create_access_token(data={"sub": str(new_user.id)})
    return {
        "status": "success",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": new_user.id,
        "name": new_user.name,
        "referral_code": new_user.referral_code,
    }

@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": str(db_user.id)})
    return {
        "status": "success",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": db_user.id,
        "name": db_user.name
    }

@router.get("/me")
def get_me(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "user_id": user.id,
        "email": user.email,
        "name": user.name,
        "age": user.age,
        "has_paid": user.has_paid,
        "current_weight": user.current_weight,
        "goal_weight": user.goal_weight,
        "weight_unit": user.weight_unit,
        "stripe_customer_id": user.stripe_customer_id,
        "referral_code": user.referral_code,
    }

@router.put("/me/profile")
def update_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if profile_data.name:
        user.name = profile_data.name
    if profile_data.age is not None:
        user.age = profile_data.age
    if profile_data.email:
        existing = db.query(User).filter(User.email == profile_data.email, User.id != current_user_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = profile_data.email
    if profile_data.new_password:
        if not profile_data.current_password or not verify_password(profile_data.current_password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Current password is incorrect")
        user.hashed_password = get_password_hash(profile_data.new_password)

    db.commit()
    db.refresh(user)
    return {"status": "success", "name": user.name, "email": user.email, "age": user.age}

@router.delete("/me")
def delete_account(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Cancel Stripe subscription if exists
    if user.stripe_customer_id:
        try:
            import stripe
            stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
            subscriptions = stripe.Subscription.list(customer=user.stripe_customer_id, status="active", limit=5)
            for sub in subscriptions.data:
                stripe.Subscription.cancel(sub.id)
        except Exception:
            pass  # Don't block account deletion if Stripe fails

    db.delete(user)
    db.commit()
    return {"status": "success", "message": "Account deleted"}

@router.put("/me/weight")
def update_weight(
    weight_data: UserWeightUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.current_weight = weight_data.current_weight
    user.goal_weight = weight_data.goal_weight
    user.weight_unit = weight_data.weight_unit
    if weight_data.age is not None:
        user.age = weight_data.age
    
    # Log Weigh In
    weigh_in_weight = weight_data.current_weight
    if weight_data.weight_unit.lower() == "lbs":
        weigh_in_weight = weight_data.current_weight * 0.453592
        
    weigh_in_record = WeighIn(user_id=current_user_id, weight=weigh_in_weight, date=datetime.datetime.utcnow())
    db.add(weigh_in_record)
    
    # Recalculate BMR / TDEE using real age (Mifflin-St Jeor)
    age = weight_data.age or user.age or 30
    bmr = (10 * weigh_in_weight) + (6.25 * 170) - (5 * age) + 5
    tdee = bmr * 1.2  # Sedentary multiplier
    
    goal_kg = weight_data.goal_weight
    if weight_data.weight_unit.lower() == "lbs":
        goal_kg = weight_data.goal_weight * 0.453592
        
    calorie_budget = int(tdee)
    if goal_kg < weigh_in_weight - 1.0:
        calorie_budget -= 500  # Cut
    elif goal_kg > weigh_in_weight + 1.0:
        calorie_budget += 500  # Bulk
        
    # Macros
    protein_target = int(weigh_in_weight * 2.0)
    fat_target = int((calorie_budget * 0.25) / 9)
    carbs_target = int((calorie_budget - (protein_target * 4) - (fat_target * 9)) / 4)
    if carbs_target < 0:
        carbs_target = 0
    
    # Update DailyStats
    stat = db.query(DailyStats).filter(DailyStats.user_id == current_user_id).order_by(DailyStats.date.desc()).first()
    if not stat or stat.date.date() != datetime.datetime.utcnow().date():
        stat = DailyStats(
            user_id=current_user_id, 
            date=datetime.datetime.utcnow(), 
            calorie_budget=calorie_budget,
            protein_target=protein_target,
            carbs_target=carbs_target,
            fat_target=fat_target
        )
        db.add(stat)
    else:
        stat.calorie_budget = calorie_budget
        stat.protein_target = protein_target
        stat.carbs_target = carbs_target
        stat.fat_target = fat_target

    db.commit()
    db.refresh(user)
    
    return {
        "status": "success",
        "message": "Weight updated, daily targets recalculated",
        "calorie_budget": calorie_budget,
        "protein_target": protein_target,
        "carbs_target": carbs_target,
        "fat_target": fat_target,
    }
