#!/usr/bin/env python3
"""Seed demo coaches for local development.

Usage (from backend/):
    ./venv/bin/python scripts/seed_coaches.py
"""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import User, Coach
from security import get_password_hash

# Around Casablanca
_BASE_LAT = 33.5731
_BASE_LNG = -7.5898

_SEED = [
    {
        "email": "sara.coach@example.com",
        "name": "Sara Benali",
        "gender": "female",
        "bio": "Coach nutrition & perte de poids. Plans simples, résultats durables.",
        "specialties": ["nutrition", "weight_loss"],
        "experience_years": 6,
        "phone": "+212612000001",
        "city": "Casablanca",
        "languages": ["fr", "ar"],
        "coaching_mode": "both",
        "lat_offset": 0.01,
        "lng_offset": 0.008,
    },
    {
        "email": "youssef.coach@example.com",
        "name": "Youssef Amrani",
        "gender": "male",
        "bio": "Prise de muscle et force. Séances en salle ou en ligne.",
        "specialties": ["muscle", "general"],
        "experience_years": 8,
        "phone": "+212612000002",
        "city": "Casablanca",
        "languages": ["fr", "en"],
        "coaching_mode": "in_person",
        "lat_offset": -0.012,
        "lng_offset": 0.015,
    },
    {
        "email": "amina.coach@example.com",
        "name": "Amina Kadiri",
        "gender": "female",
        "bio": "Cardio, endurance et reprise du sport après pause.",
        "specialties": ["cardio", "general"],
        "experience_years": 4,
        "phone": "+212612000003",
        "city": "Casablanca",
        "languages": ["fr", "ar", "en"],
        "coaching_mode": "both",
        "lat_offset": 0.018,
        "lng_offset": -0.01,
    },
    {
        "email": "karim.coach@example.com",
        "name": "Karim Tazi",
        "gender": "male",
        "bio": "Nutrition sportive pour athlètes et busy professionals.",
        "specialties": ["nutrition", "muscle"],
        "experience_years": 10,
        "phone": "+212612000004",
        "city": "Casablanca",
        "languages": ["fr"],
        "coaching_mode": "online",
        "lat_offset": -0.02,
        "lng_offset": -0.014,
    },
    {
        "email": "lina.coach@example.com",
        "name": "Lina Cherkaoui",
        "gender": "female",
        "bio": "Transformation douce : habitudes, sommeil, alimentation.",
        "specialties": ["weight_loss", "nutrition"],
        "experience_years": 5,
        "phone": "+212612000005",
        "city": "Rabat",
        "languages": ["fr", "ar"],
        "coaching_mode": "online",
        "lat_offset": 0.35,
        "lng_offset": 0.12,
    },
    {
        "email": "omar.coach@example.com",
        "name": "Omar El Fassi",
        "gender": "male",
        "bio": "HIIT, cardio et conditioning pour retrouver l’énergie.",
        "specialties": ["cardio", "weight_loss"],
        "experience_years": 7,
        "phone": "+212612000006",
        "city": "Casablanca",
        "languages": ["ar", "fr"],
        "coaching_mode": "in_person",
        "lat_offset": 0.006,
        "lng_offset": -0.02,
    },
    {
        "email": "nadia.coach@example.com",
        "name": "Nadia Berrada",
        "gender": "female",
        "bio": "Coach globale : mobilité, force légère et nutrition.",
        "specialties": ["general", "nutrition"],
        "experience_years": 3,
        "phone": "+212612000007",
        "city": "Casablanca",
        "languages": ["fr", "en"],
        "coaching_mode": "both",
        "lat_offset": -0.008,
        "lng_offset": 0.022,
    },
    {
        "email": "mehdi.coach@example.com",
        "name": "Mehdi Saadi",
        "gender": "male",
        "bio": "Hypertrophie et technique. Suivi clair semaine par semaine.",
        "specialties": ["muscle"],
        "experience_years": 9,
        "phone": "+212612000008",
        "city": "Casablanca",
        "languages": ["fr", "ar"],
        "coaching_mode": "in_person",
        "lat_offset": 0.025,
        "lng_offset": 0.005,
    },
]


def upsert_coach(db, data: dict) -> None:
    user = db.query(User).filter(User.email == data["email"]).first()
    if not user:
        user = User(
            id=str(uuid.uuid4()),
            email=data["email"],
            name=data["name"],
            hashed_password=get_password_hash("CoachTest123!"),
            is_email_verified=True,
            has_paid=True,
            is_coach=True,
            gender=data["gender"],
        )
        db.add(user)
        db.flush()
    else:
        user.name = data["name"]
        user.has_paid = True
        user.is_coach = True
        user.is_email_verified = True
        user.gender = data["gender"]

    coach = db.query(Coach).filter(Coach.user_id == user.id).first()
    if not coach:
        coach = Coach(id=str(uuid.uuid4()), user_id=user.id)
        db.add(coach)

    coach.bio = data["bio"]
    coach.specialties = data["specialties"]
    coach.gender = data["gender"]
    coach.experience_years = data["experience_years"]
    coach.phone = data["phone"]
    coach.city = data["city"]
    coach.languages = data["languages"]
    coach.coaching_mode = data["coaching_mode"]
    coach.latitude = _BASE_LAT + data["lat_offset"]
    coach.longitude = _BASE_LNG + data["lng_offset"]
    coach.is_active = True


def main() -> None:
    db = SessionLocal()
    try:
        for row in _SEED:
            upsert_coach(db, row)
        db.commit()
        print(f"Seeded {len(_SEED)} coaches around Casablanca.")
        print("Password for all seed accounts: CoachTest123!")
    except Exception as exc:
        db.rollback()
        print(f"Seed failed: {exc}")
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
