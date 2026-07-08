from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey, Text, Boolean, JSON
from sqlalchemy.orm import relationship
import datetime
import uuid
from database import Base

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    hashed_password = Column(String)
    is_email_verified = Column(Boolean, default=False, nullable=False)
    verification_code = Column(String(6), nullable=True)
    verification_code_expires_at = Column(DateTime, nullable=True)

    # Profile / Health data
    current_weight = Column(Float, nullable=True)
    goal_weight = Column(Float, nullable=True)
    weight_unit = Column(String, default="kg")
    height = Column(Float, nullable=True)         # in cm internally
    height_unit = Column(String, default="cm")   # "cm" or "ft"
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)        # "male" | "female"
    activity_level = Column(String, default="sedentary")  # "sedentary" | "light" | "moderate" | "active" | "very_active"
    phone = Column(String, nullable=True)
    share_phone = Column(Boolean, default=False)
    
    # Manual overrides for nutrition goals
    manual_calories = Column(Integer, nullable=True)
    manual_protein = Column(Integer, nullable=True)
    manual_carbs = Column(Integer, nullable=True)
    manual_fat = Column(Integer, nullable=True)

    # Stripe Payments
    stripe_customer_id = Column(String, unique=True, nullable=True, index=True)
    has_paid = Column(Boolean, default=False, nullable=False)

    # Subscription source tracking ("apple" | "google" | "stripe" | None)
    subscription_source = Column(String, nullable=True)
    # Apple In-App Purchase
    apple_original_transaction_id = Column(String, nullable=True, index=True)
    # Google Play In-App Purchase
    google_order_id = Column(String, nullable=True, index=True)
    google_purchase_token = Column(String, nullable=True, index=True)
    subscription_expires_at = Column(DateTime, nullable=True)

    # Referral system
    referral_code = Column(String, unique=True, nullable=True, index=True)
    referral_balance = Column(Float, default=0.0, nullable=False)
    referred_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    
    daily_stats = relationship("DailyStats", back_populates="user")
    weigh_ins = relationship("WeighIn", back_populates="user", cascade="all, delete-orphan")
    food_logs = relationship("FoodLog", back_populates="user")
    referrals_given = relationship("Referral", foreign_keys="Referral.referrer_id", back_populates="referrer")
    withdrawals = relationship("Withdrawal", back_populates="user")
    exercise_logs = relationship("ExerciseLog", back_populates="user")
    recipes = relationship("Recipe", back_populates="user")
    saved_foods = relationship("SavedFood", back_populates="user")
    created_events = relationship("Event", back_populates="creator")
    joined_events = relationship("EventParticipant", back_populates="user")
    memories = relationship("Memory", back_populates="user", cascade="all, delete-orphan")
    posts = relationship("Post", back_populates="user", cascade="all, delete-orphan")

class DailyStats(Base):
    __tablename__ = "daily_stats"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"))
    date = Column(DateTime, default=datetime.datetime.utcnow)
    
    calorie_budget = Column(Integer, default=2200)
    calories_consumed = Column(Integer, default=0)
    protein_consumed = Column(Integer, default=0)
    carbs_consumed = Column(Integer, default=0)
    fat_consumed = Column(Integer, default=0)
    
    protein_target = Column(Integer, default=150)
    carbs_target = Column(Integer, default=200)
    fat_target = Column(Integer, default=65)
    
    user = relationship("User", back_populates="daily_stats")

class FoodLog(Base):
    __tablename__ = "food_logs"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"))
    name = Column(String, index=True)
    name_en = Column(String, nullable=True)
    name_fr = Column(String, nullable=True)
    name_ar = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    
    calories = Column(Integer)
    protein = Column(Integer)
    carbs = Column(Integer)
    fat = Column(Integer)
    ingredients = Column(JSON, nullable=True)
    
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="food_logs")

class WeighIn(Base):
    __tablename__ = "weigh_ins"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"))
    weight = Column(Float, nullable=False)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="weigh_ins")

class Group(Base):
    __tablename__ = "groups"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    members = relationship("GroupMember", back_populates="group")

class GroupMember(Base):
    __tablename__ = "group_members"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    group_id = Column(String(36), ForeignKey("groups.id"))
    user_id = Column(String(36), ForeignKey("users.id"))
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    group = relationship("Group", back_populates="members")
    user = relationship("User")

class Referral(Base):
    __tablename__ = "referrals"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    referrer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    referred_user_id = Column(String(36), ForeignKey("users.id"), nullable=False, unique=True)
    amount = Column(Float, default=1.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    referrer = relationship("User", foreign_keys=[referrer_id], back_populates="referrals_given")
    referred_user = relationship("User", foreign_keys=[referred_user_id])

class Withdrawal(Base):
    __tablename__ = "withdrawals"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    method = Column(String, default="PayPal")   # "PayPal" | "Bank Transfer"
    status = Column(String, default="pending")  # "pending" | "paid"
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="withdrawals")

class ExerciseLog(Base):
    __tablename__ = "exercise_logs"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    calories_burned = Column(Integer, nullable=False)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    log_date = Column(Date, nullable=True, index=True)
    
    user = relationship("User", back_populates="exercise_logs")

class Recipe(Base):
    __tablename__ = "recipes"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    ingredients = Column(JSON, nullable=False)
    instructions = Column(Text, nullable=True)
    is_public = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="recipes")

class SavedFood(Base):
    __tablename__ = "saved_foods"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, index=True)
    name_en = Column(String, nullable=True)
    name_fr = Column(String, nullable=True)
    name_ar = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    
    calories = Column(Integer)
    protein = Column(Integer)
    carbs = Column(Integer)
    fat = Column(Integer)
    ingredients = Column(JSON, nullable=True)
    
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="saved_foods")

class TrialFingerprint(Base):
    __tablename__ = "trial_fingerprints"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    fingerprint = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User")

class Event(Base):
    __tablename__ = "events"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    creator_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=True)
    event_type = Column(String, nullable=False, index=True) # e.g. soccer, marathon, walk
    audience = Column(String, nullable=False, default="mixed", index=True)  # "female" | "male" | "mixed"
    location_name = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    start_time = Column(DateTime, nullable=False)
    whatsapp_link = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    max_participants = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    creator = relationship("User", back_populates="created_events")
    participants = relationship("EventParticipant", back_populates="event", cascade="all, delete-orphan")

class EventParticipant(Base):
    __tablename__ = "event_participants"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    event_id = Column(String(36), ForeignKey("events.id"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    event = relationship("Event", back_populates="participants")
    user = relationship("User", back_populates="joined_events")

class Memory(Base):
    __tablename__ = "memories"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    image_url = Column(String, nullable=False)
    caption = Column(String, nullable=True)
    is_private = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="memories")

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    content = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="posts")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")

class PostLike(Base):
    __tablename__ = "post_likes"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    post_id = Column(String(36), ForeignKey("posts.id"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    post = relationship("Post", back_populates="likes")
    user = relationship("User")

class Friendship(Base):
    __tablename__ = "friendships"
    
    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    friend_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    status = Column(String, default="accepted") # pending, accepted
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", foreign_keys=[user_id])
    friend = relationship("User", foreign_keys=[friend_id])
