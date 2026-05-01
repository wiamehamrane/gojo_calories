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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
load_dotenv()

os.makedirs("uploads", exist_ok=True)

from routes import vision, auth, stats, groups, referrals, payments, notifications, exercises, recipes

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
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by INTEGER;"))
        # Multilingual food names
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_en VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_fr VARCHAR;"))
        conn.execute(text("ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS name_ar VARCHAR;"))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS weigh_ins (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                weight FLOAT NOT NULL,
                date DATE NOT NULL
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

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])

# Hard Paywall temporarily suspended for AWS testing mode
app.include_router(vision.router, prefix="/api/food", tags=["Food Vision AI"])
app.include_router(stats.router, prefix="/api/stats", tags=["Daily Stats"])
app.include_router(groups.router, prefix="/api/groups", tags=["Social Groups"])
app.include_router(referrals.router, prefix="/api/referrals", tags=["Referrals"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(exercises.router, prefix="/api/exercises", tags=["Exercises"])
app.include_router(recipes.router, prefix="/api/recipes", tags=["Recipes"])

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

