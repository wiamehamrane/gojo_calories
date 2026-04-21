from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
import datetime
from database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    hashed_password = Column(String)

    # Profile / Health data
    current_weight = Column(Float, nullable=True)
    goal_weight = Column(Float, nullable=True)
    weight_unit = Column(String, default="kg")
    height = Column(Float, nullable=True)         # in cm internally
    height_unit = Column(String, default="cm")   # "cm" or "ft"
    age = Column(Integer, nullable=True)

    # Stripe Payments
    stripe_customer_id = Column(String, unique=True, nullable=True, index=True)
    has_paid = Column(Boolean, default=False, nullable=False)

    # Referral system
    referral_code = Column(String, unique=True, nullable=True, index=True)
    referral_balance = Column(Float, default=0.0, nullable=False)
    referred_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    daily_stats = relationship("DailyStats", back_populates="user")
    weigh_ins = relationship("WeighIn", back_populates="user", cascade="all, delete-orphan")
    food_logs = relationship("FoodLog", back_populates="user")
    referrals_given = relationship("Referral", foreign_keys="Referral.referrer_id", back_populates="referrer")
    withdrawals = relationship("Withdrawal", back_populates="user")

class DailyStats(Base):
    __tablename__ = "daily_stats"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
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
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String, index=True)
    image_url = Column(String, nullable=True)
    
    calories = Column(Integer)
    protein = Column(Integer)
    carbs = Column(Integer)
    fat = Column(Integer)
    
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="food_logs")

class WeighIn(Base):
    __tablename__ = "weigh_ins"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    weight = Column(Float, nullable=False)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="weigh_ins")

class Group(Base):
    __tablename__ = "groups"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    members = relationship("GroupMember", back_populates="group")

class GroupMember(Base):
    __tablename__ = "group_members"
    
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    group = relationship("Group", back_populates="members")
    user = relationship("User")


class Referral(Base):
    __tablename__ = "referrals"

    id = Column(Integer, primary_key=True, index=True)
    referrer_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    referred_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    amount = Column(Float, default=1.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    referrer = relationship("User", foreign_keys=[referrer_id], back_populates="referrals_given")
    referred_user = relationship("User", foreign_keys=[referred_user_id])


class Withdrawal(Base):
    __tablename__ = "withdrawals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    method = Column(String, default="PayPal")   # "PayPal" | "Bank Transfer"
    status = Column(String, default="pending")  # "pending" | "paid"
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="withdrawals")
