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
from google.oauth2 import id_token
from google.auth.transport import requests as g_requests
import jwt
import httpx

router = APIRouter()

GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_WEB_CLIENT_ID", "dummy_if_not_set")

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
    height: Optional[float] = None      # always stored internally in cm
    height_unit: Optional[str] = None   # "cm" or "ft"
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
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

# ── SOCIAL LOGIN ─────────────────────────────────────────────────────────────

class SocialLogin(BaseModel):
    id_token: str
    identity_token: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None
    
@router.post("/google")
def google_login(body: SocialLogin, db: Session = Depends(get_db)):
    try:
        info = id_token.verify_oauth2_token(body.id_token, g_requests.Request(), GOOGLE_WEB_CLIENT_ID)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    email = info["email"]
    name = info.get("name", email.split("@")[0])

    user = db.query(User).filter(User.email == email).first()
    if not user:
        while True:
            new_code = _generate_code()
            if not db.query(User).filter(User.referral_code == new_code).first():
                break

        user = User(
            email=email, 
            name=name, 
            hashed_password="", # No password for social login
            referral_code=new_code,
            referral_balance=0.0
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": access_token, "token_type": "bearer", "name": user.name}

@router.post("/apple")
async def apple_login(body: dict, db: Session = Depends(get_db)):
    identity_token = body.get("identity_token")
    if not identity_token:
        raise HTTPException(status_code=400, detail="Missing identity token")
        
    async with httpx.AsyncClient() as client:
        keys_response = await client.get("https://appleid.apple.com/auth/keys")
    jwks = keys_response.json()

    try:
        header = jwt.get_unverified_header(identity_token)
        matching_key = next(k for k in jwks["keys"] if k["kid"] == header["kid"])
        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(matching_key)
        claims = jwt.decode(
            identity_token, 
            public_key,
            algorithms=["RS256"],
            audience=["com.gojocalories.gojocalories", "com.gojocalories.gojocalories.web"]
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Apple token: {str(e)}")

    email = claims.get("email")
    if not email:
        email = f"apple_{claims['sub']}@privaterelay.appleid.com"
        
    given_name = body.get("given_name") or ""
    family_name = body.get("family_name") or ""
    name = f"{given_name} {family_name}".strip()
    if not name:
        name = email.split("@")[0]

    user = db.query(User).filter(User.email == email).first()
    if not user:
        while True:
            new_code = _generate_code()
            if not db.query(User).filter(User.referral_code == new_code).first():
                break

        user = User(
            email=email, 
            name=name, 
            hashed_password="",
            referral_code=new_code,
            referral_balance=0.0
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": access_token, "token_type": "bearer", "name": user.name}

# ─────────────────────────────────────────────────────────────────────────────
from fastapi import Request
from fastapi.responses import RedirectResponse
import urllib.parse

@router.post("/callbacks/sign_in_with_apple")
async def apple_callback_android(request: Request):
    form = await request.form()
    query_string = urllib.parse.urlencode(form)
    intent_url = f"intent://callback?{query_string}#Intent;package=com.gojocalories.gojocalories;scheme=signinwithapple;end"
    return RedirectResponse(url=intent_url)

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
        "height": user.height,
        "height_unit": user.height_unit,
        "gender": user.gender,
        "activity_level": user.activity_level,
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
    if profile_data.gender:
        user.gender = profile_data.gender.lower()
    if profile_data.activity_level:
        user.activity_level = profile_data.activity_level.lower()
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
    if weight_data.gender:
        user.gender = weight_data.gender.lower()
    if weight_data.activity_level:
        user.activity_level = weight_data.activity_level.lower()

    # Convert and store height in cm
    if weight_data.height is not None:
        height_cm = weight_data.height
        if weight_data.height_unit and weight_data.height_unit.lower() == 'ft':
            height_cm = weight_data.height * 30.48  # 1 foot = 30.48 cm
        user.height = round(height_cm, 1)
        user.height_unit = weight_data.height_unit or 'cm'
    
    # Log Weigh In
    weigh_in_weight = weight_data.current_weight
    if weight_data.weight_unit.lower() == "lbs":
        weigh_in_weight = weight_data.current_weight * 0.453592
        
    weigh_in_record = WeighIn(user_id=current_user_id, weight=weigh_in_weight, date=datetime.datetime.utcnow())
    db.add(weigh_in_record)
    
    # Recalculate BMR / TDEE using our standardized utility
    from utils.nutrition import calculate_daily_targets
    
    age = user.age or 30
    height_cm = user.height or 170
    gender = user.gender or "male"
    activity = user.activity_level or "sedentary"
    
    goal_kg = weight_data.goal_weight
    if weight_data.weight_unit.lower() == "lbs":
        goal_kg = weight_data.goal_weight * 0.453592
        
    targets = calculate_daily_targets(
        weight_kg=weigh_in_weight,
        height_cm=height_cm,
        age=age,
        gender=gender,
        activity_level=activity,
        goal_weight_kg=goal_kg
    )
    
    calorie_budget = targets["calorie_budget"]
    protein_target = targets["protein_target"]
    fat_target = targets["fat_target"]
    carbs_target = targets["carbs_target"]
    
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
