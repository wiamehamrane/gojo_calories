import os
import urllib.parse
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
import models
import logging
from fastapi.staticfiles import StaticFiles

logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO").upper(), logging.INFO),
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
logger = logging.getLogger(__name__)
load_dotenv()

os.makedirs("uploads", exist_ok=True)

from routes import vision, auth, stats, groups, referrals, payments, notifications, exercises, recipes, events, apple_iap, memories, feed, friends

if os.getenv("WIPE_DB") == "true":
    logger.warning("WIPE_DB is true. Dropping all tables via SCHEMA wipe...")
    with engine.begin() as conn:
        from sqlalchemy import text
        conn.execute(text("DROP SCHEMA public CASCADE;"))
        conn.execute(text("CREATE SCHEMA public;"))
        conn.execute(text("GRANT ALL ON SCHEMA public TO public;"))
    logger.warning("Database wiped successfully.")

Base.metadata.create_all(bind=engine)

# Auto-migrate production database
try:
    with engine.begin() as conn:
        from sqlalchemy import text
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS has_paid BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code VARCHAR(6);"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code_expires_at TIMESTAMP;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS current_weight FLOAT;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS goal_weight FLOAT;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS weight_unit VARCHAR DEFAULT 'kg';"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER DEFAULT 25;"))
        # Height columns (added for accurate BMR calculation)
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS height FLOAT;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS height_unit VARCHAR DEFAULT 'cm';"))
        # Manual nutrition override columns (used by profile update endpoint)
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS manual_calories INTEGER;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS manual_protein INTEGER;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS manual_carbs INTEGER;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS manual_fat INTEGER;"))
        # Gender and activity level columns (added for BMR/TDEE calculation)
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS activity_level VARCHAR;"))
        # Referred by column (referral system)
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by VARCHAR;"))
        # Apple IAP columns
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_source VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_original_transaction_id VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP;"))
        # Social & Privacy
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS share_phone BOOLEAN DEFAULT FALSE;"))
        # Multilingual food names
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_en VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_fr VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_ar VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS image_url VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS ingredients JSON;"))
        conn.execute(text("ALTER TABLE exercise_logs ADD COLUMN IF NOT EXISTS log_date DATE;"))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS exercise_logs (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                name VARCHAR NOT NULL,
                duration_minutes INTEGER NOT NULL,
                calories_burned INTEGER NOT NULL,
                date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                log_date DATE
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS saved_foods (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                name VARCHAR,
                name_en VARCHAR,
                name_fr VARCHAR,
                name_ar VARCHAR,
                image_url VARCHAR,
                calories INTEGER,
                protein INTEGER,
                carbs INTEGER,
                fat INTEGER,
                ingredients JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS weigh_ins (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                weight FLOAT NOT NULL,
                date DATE NOT NULL
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS memories (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                image_url VARCHAR NOT NULL,
                caption VARCHAR,
                is_private BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS posts (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                content TEXT,
                image_url VARCHAR,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS post_likes (
                id VARCHAR(36) PRIMARY KEY,
                post_id VARCHAR(36) NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS friendships (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                friend_id VARCHAR(36) NOT NULL REFERENCES users(id),
                status VARCHAR DEFAULT 'accepted',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        # Ensure daily_stats has all expected columns
        conn.execute(text("""
            DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_stats' AND column_name='protein_target') THEN
                    ALTER TABLE daily_stats ADD COLUMN protein_target INTEGER DEFAULT 150;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_stats' AND column_name='carbs_target') THEN
                    ALTER TABLE daily_stats ADD COLUMN carbs_target INTEGER DEFAULT 200;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_stats' AND column_name='fat_target') THEN
                    ALTER TABLE daily_stats ADD COLUMN fat_target INTEGER DEFAULT 65;
                END IF;
            END $$;
        """))
except Exception as e:
    print(f"Migration schema update error: {e}")

app = FastAPI(title="GojoCalories Backend API")

# ── Request logging ────────────────────────────────────────────────────────────

import time

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    client = request.client.host if request.client else "unknown"
    logger.info(">> %s %s from %s", request.method, request.url.path, client)
    try:
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000
        logger.info(
            "<< %s %s %s (%.0fms)",
            request.method,
            request.url.path,
            response.status_code,
            elapsed_ms,
        )
        return response
    except Exception:
        elapsed_ms = (time.perf_counter() - start) * 1000
        logger.exception(
            "!! %s %s failed (%.0fms)",
            request.method,
            request.url.path,
            elapsed_ms,
        )
        raise

# ── Global Exception Handlers ──────────────────────────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception on {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred. Please try again later."},
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = [f"{' → '.join(str(l) for l in e['loc'])}: {e['msg']}" for e in exc.errors()]
    logger.warning("Validation error on %s %s: %s", request.method, request.url.path, "; ".join(errors))
    return JSONResponse(
        status_code=422,
        content={"detail": "; ".join(errors)},
    )

# ──────────────────────────────────────────────────────────────────────────────

allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def read_root():
    return {"status": "GojoCalories MVP API is running natively."}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])
app.include_router(apple_iap.router, prefix="/api/payments/apple", tags=["Apple IAP"])

# Hard Paywall temporarily suspended for AWS testing mode
app.include_router(vision.router, prefix="/api/food", tags=["Food Vision AI"])
app.include_router(stats.router, prefix="/api/stats", tags=["Daily Stats"])
app.include_router(groups.router, prefix="/api/groups", tags=["Social Groups"])
app.include_router(referrals.router, prefix="/api/referrals", tags=["Referrals"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(exercises.router, prefix="/api/exercises", tags=["Exercises"])
app.include_router(recipes.router, prefix="/api/recipes", tags=["Recipes"])
app.include_router(events.router, prefix="/api/events", tags=["Events"])
app.include_router(memories.router, prefix="/api/memories", tags=["Memories"])
app.include_router(feed.router, prefix="/api/feed", tags=["Feed"])
app.include_router(friends.router, prefix="/api/friends", tags=["Friends"])

# Apple Sign-In callback — must be at root path to match the redirectUri
# configured in the Flutter app: https://api.gojocalories.com/callbacks/sign_in_with_apple
@app.post("/callbacks/sign_in_with_apple")
async def apple_callback(request: Request):
    form = await request.form()
    query_string = urllib.parse.urlencode(dict(form))
    intent_url = (
        f"intent://callback?{query_string}"
        "#Intent;package=com.gojocalories.gojocalories;scheme=signinwithapple;end"
    )
    return RedirectResponse(url=intent_url)

