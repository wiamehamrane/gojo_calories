import random
import string
import os
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import HTMLResponse
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
from services import email_service

router = APIRouter()

GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_WEB_CLIENT_ID", "dummy_if_not_set")
GOOGLE_IOS_CLIENT_ID = "980076580409-4d78u72lc8o7aqfuoinvd72dk2tr27co.apps.googleusercontent.com"

def _generate_code(length: int = 6) -> str:
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


class UserCreate(BaseModel):
    email: str
    name: Optional[str] = None
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
    referral_code: Optional[str] = None

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
    current_password: Optional[str] = None
    new_password: Optional[str] = None
    daily_calories: Optional[int] = None
    protein_target: Optional[int] = None
    carbs_target: Optional[int] = None
    fat_target: Optional[int] = None
    phone: Optional[str] = None
    share_phone: Optional[bool] = None

class UserLogin(BaseModel):
    email: str
    password: str

@router.post("/register")
def register(user: UserCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)
    name = user.name or user.email.split("@")[0]

    while True:
        new_code = _generate_code()
        if not db.query(User).filter(User.referral_code == new_code).first():
            break

    new_user = User(
        email=user.email,
        name=name,
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
    
    new_user.is_email_verified = True
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
    if not body.id_token:
        raise HTTPException(status_code=400, detail="Missing Google id_token")

    # Try verifying against web client ID first, then iOS client ID as fallback.
    # iOS devices issue tokens with the iOS client ID as the audience.
    info = None
    last_error = None
    for audience in [GOOGLE_WEB_CLIENT_ID, GOOGLE_IOS_CLIENT_ID]:
        try:
            info = id_token.verify_oauth2_token(body.id_token, g_requests.Request(), audience)
            break  # verification succeeded
        except ValueError as e:
            last_error = e
    if info is None:
        raise HTTPException(status_code=401, detail=f"Invalid Google token: {last_error}")

    email = info.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Google token does not contain an email address")
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

class AppleLoginBody(BaseModel):
    identity_token: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None

@router.post("/apple")
async def apple_login(body: AppleLoginBody, db: Session = Depends(get_db)):
    if not body.identity_token:
        raise HTTPException(status_code=400, detail="Missing identity token")

    try:
        async with httpx.AsyncClient() as client:
            keys_response = await client.get("https://appleid.apple.com/auth/keys", timeout=10.0)
        keys_response.raise_for_status()
        jwks = keys_response.json()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to fetch Apple public keys: {str(e)}")

    try:
        header = jwt.get_unverified_header(body.identity_token)
        matching_key = next(
            (k for k in jwks["keys"] if k["kid"] == header["kid"]),
            None
        )
        if matching_key is None:
            raise HTTPException(status_code=401, detail="Apple token key not found in JWKS")
        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(matching_key)
        claims = jwt.decode(
            body.identity_token, 
            public_key,
            algorithms=["RS256"],
            audience=["com.gojocalories.gojocalories", "com.gojocalories.gojocalories.web"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Apple token: {str(e)}")

    email = claims.get("email")
    if not email:
        sub = claims.get("sub")
        if not sub:
            raise HTTPException(status_code=400, detail="Apple token missing email and sub")
        email = f"apple_{sub}@privaterelay.appleid.com"

    given_name = body.given_name or ""
    family_name = body.family_name or ""
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

@router.get("/me")
def get_me(db: Session = Depends(get_db), current_user_id: str = Depends(get_current_user_id)):
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
        "subscription_source": getattr(user, 'subscription_source', None),
        "referral_code": user.referral_code,
        "is_email_verified": getattr(user, 'is_email_verified', False),
        "phone": user.phone,
        "share_phone": user.share_phone,
    }

@router.put("/me/profile")
def update_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
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
    
    # Manual Nutrition Overrides
    if profile_data.daily_calories is not None:
        user.manual_calories = profile_data.daily_calories
    if profile_data.protein_target is not None:
        user.manual_protein = profile_data.protein_target
    if profile_data.carbs_target is not None:
        user.manual_carbs = profile_data.carbs_target
    if profile_data.fat_target is not None:
        user.manual_fat = profile_data.fat_target
    if profile_data.phone is not None:
        user.phone = profile_data.phone
    if profile_data.share_phone is not None:
        user.share_phone = profile_data.share_phone

    db.commit()
    db.refresh(user)
    return {"status": "success", "name": user.name, "email": user.email, "age": user.age}

@router.delete("/me")
def delete_account(db: Session = Depends(get_db), current_user_id: str = Depends(get_current_user_id)):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")



    db.delete(user)
    db.commit()
    return {"status": "success", "message": "Account deleted"}

@router.put("/me/weight")
def update_weight(
    weight_data: UserWeightUpdate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
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
        
    if weight_data.referral_code and not user.referred_by:
        referrer = db.query(User).filter(User.referral_code == weight_data.referral_code.upper()).first()
        if referrer and referrer.id != user.id:
            user.referred_by = referrer.id
            referrer.referral_balance = round(referrer.referral_balance + 1.0, 2)
            referral_record = Referral(
                referrer_id=referrer.id,
                referred_user_id=user.id,
                amount=1.0,
            )
            db.add(referral_record)

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
