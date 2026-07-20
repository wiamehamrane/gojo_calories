from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey, Text, Boolean, JSON, UniqueConstraint
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
    is_admin = Column(Boolean, default=False, nullable=False)
    is_influencer = Column(Boolean, default=False, nullable=False)
    is_banned = Column(Boolean, default=False, nullable=False)
    is_coach = Column(Boolean, default=False, nullable=False)
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
    # S3 key or local /uploads path for the user's profile photo.
    avatar_url = Column(String, nullable=True)
    # When True, other users can open a limited public profile from comments/meals.
    profile_public = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
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
    subscription_plan = Column(String, nullable=True)  # monthly | six_month | yearly | lifetime
    referral_discount_used = Column(Boolean, default=False, nullable=False)
    clan_id = Column(String(36), ForeignKey("clans.id"), nullable=True, index=True)

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
    progress_photos = relationship(
        "ProgressPhoto", back_populates="user", cascade="all, delete-orphan"
    )
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

class SharedMeal(Base):
    """A meal a user prepared and shared with the community.

    Shown as a horizontal row on the Events page: photo of the final
    product, macros, ingredients, and how to cook it.
    """
    __tablename__ = "shared_meals"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    image_url = Column(String, nullable=True)          # stable S3 key
    ingredients = Column(JSON, nullable=False)         # list[str]
    instructions = Column(Text, nullable=True)         # how to cook
    calories = Column(Integer, default=0)
    protein = Column(Integer, default=0)
    carbs = Column(Integer, default=0)
    fat = Column(Integer, default=0)
    comments_enabled = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    stars = relationship(
        "SharedMealStar", back_populates="meal", cascade="all, delete-orphan"
    )
    likes = relationship(
        "SharedMealLike", back_populates="meal", cascade="all, delete-orphan"
    )
    comments = relationship(
        "SharedMealComment", back_populates="meal", cascade="all, delete-orphan"
    )


class SharedMealStar(Base):
    """A user's star/favorite on a community shared meal."""
    __tablename__ = "shared_meal_stars"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    shared_meal_id = Column(
        String(36), ForeignKey("shared_meals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    meal = relationship("SharedMeal", back_populates="stars")
    user = relationship("User")


class SharedMealLike(Base):
    """A heart/like on a community shared meal."""
    __tablename__ = "shared_meal_likes"
    __table_args__ = (
        UniqueConstraint("user_id", "shared_meal_id", name="uq_shared_meal_likes_user_meal"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    shared_meal_id = Column(
        String(36), ForeignKey("shared_meals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    meal = relationship("SharedMeal", back_populates="likes")
    user = relationship("User")


class SharedMealComment(Base):
    """A top-level comment on a shared meal (no replies)."""
    __tablename__ = "shared_meal_comments"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    shared_meal_id = Column(
        String(36), ForeignKey("shared_meals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    body = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    meal = relationship("SharedMeal", back_populates="comments")
    user = relationship("User")
    likes = relationship(
        "SharedMealCommentLike", back_populates="comment", cascade="all, delete-orphan"
    )


class SharedMealCommentLike(Base):
    """A like on a shared-meal comment."""
    __tablename__ = "shared_meal_comment_likes"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    comment_id = Column(
        String(36),
        ForeignKey("shared_meal_comments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    comment = relationship("SharedMealComment", back_populates="likes")
    user = relationship("User")


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
    image_urls = Column(JSON, nullable=True)
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


class ProgressPhoto(Base):
    """Private daily body progress photo — visible only to the owner."""
    __tablename__ = "progress_photos"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    image_url = Column(String, nullable=False)  # stable S3 key
    note = Column(String, nullable=True)
    # Which of the four standardized angles this shot is: front | left | right | back.
    # Nullable for legacy rows created before guided capture existed.
    pose = Column(String(10), nullable=True, index=True)
    photo_date = Column(Date, nullable=False, default=datetime.date.today, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="progress_photos")


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


class Influencer(Base):
    __tablename__ = "influencers"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), unique=True, nullable=False, index=True)
    display_name = Column(String, nullable=False)
    handle = Column(String, nullable=True, index=True)
    platform = Column(String, nullable=True)  # instagram, tiktok, youtube, etc.
    notes = Column(Text, nullable=True)
    commission_rate = Column(Float, nullable=True)
    panel_access = Column(Boolean, default=True, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User")


class Clan(Base):
    __tablename__ = "clans"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    owner_user_id = Column(String(36), ForeignKey("users.id"), nullable=False, unique=True, index=True)
    plan_id = Column(String, nullable=False, default="monthly")  # monthly | six_month | yearly
    stripe_subscription_id = Column(String, nullable=True, index=True)
    status = Column(String, default="active", nullable=False)  # active | canceled
    max_members = Column(Integer, default=5, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", foreign_keys=[owner_user_id])
    members = relationship("ClanMember", back_populates="clan", cascade="all, delete-orphan")
    invites = relationship("ClanInvite", back_populates="clan", cascade="all, delete-orphan")


class ClanMember(Base):
    __tablename__ = "clan_members"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    clan_id = Column(String(36), ForeignKey("clans.id"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, unique=True, index=True)
    role = Column(String, default="member", nullable=False)  # owner | member
    addon_active = Column(Boolean, default=False, nullable=False)
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)

    clan = relationship("Clan", back_populates="members")
    user = relationship("User", foreign_keys=[user_id])


class ClanInvite(Base):
    __tablename__ = "clan_invites"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    clan_id = Column(String(36), ForeignKey("clans.id"), nullable=False, index=True)
    email = Column(String, nullable=False, index=True)
    token = Column(String, unique=True, nullable=False, index=True)
    status = Column(String, default="pending", nullable=False)  # pending | accepted | expired | canceled
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    clan = relationship("Clan", back_populates="invites")


class ShareGrant(Base):
    """Permission for a viewer (e.g. coach) to see an owner's diary/workouts."""

    __tablename__ = "share_grants"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    owner_user_id = Column(String(36), ForeignKey("users.id"), nullable=True, index=True)  # client
    viewer_user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)  # coach
    invite_email = Column(String, nullable=True, index=True)
    token = Column(String, unique=True, nullable=False, index=True)
    status = Column(String, default="pending", nullable=False)  # pending | active | revoked | expired | declined
    scopes = Column(String, default="nutrition,exercises", nullable=False)
    expires_at = Column(DateTime, nullable=False)
    accepted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", foreign_keys=[owner_user_id])
    viewer = relationship("User", foreign_keys=[viewer_user_id])


class Coach(Base):
    __tablename__ = "coaches"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, unique=True, index=True)
    bio = Column(Text, nullable=True)
    specialties = Column(JSON, nullable=True)
    gender = Column(String, nullable=True)
    experience_years = Column(Integer, nullable=True)
    photo_url = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    city = Column(String, nullable=True)
    languages = Column(JSON, nullable=True)
    coaching_mode = Column(String, nullable=True)
    is_active = Column(Boolean, default=False, nullable=False)
    subscription_plan = Column(String, nullable=True)
    subscription_expires_at = Column(DateTime, nullable=True)
    subscription_source = Column(String, nullable=True)
    apple_original_transaction_id = Column(String, nullable=True, index=True)
    google_order_id = Column(String, nullable=True, index=True)
    google_purchase_token = Column(String, nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", foreign_keys=[user_id])
    works = relationship(
        "CoachWork",
        back_populates="coach",
        cascade="all, delete-orphan",
        order_by="CoachWork.created_at.desc()",
    )


class CoachWork(Base):
    __tablename__ = "coach_works"

    id = Column(String(36), primary_key=True, default=generate_uuid, index=True)
    coach_id = Column(
        String(36), ForeignKey("coaches.id", ondelete="CASCADE"), nullable=False, index=True
    )
    before_url = Column(String, nullable=False)
    after_url = Column(String, nullable=False)
    caption = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    coach = relationship("Coach", back_populates="works")
