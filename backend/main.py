import os
import urllib.parse
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, RedirectResponse, HTMLResponse
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

from routes import vision, auth, stats, groups, referrals, payments, notifications, exercises, recipes, events, apple_iap, google_iap, memories, feed, friends, promo, clan, shares
from routes.admin import router as admin_router

# Durable media storage check — local /uploads is wiped on every ECS redeploy.
_bucket = os.getenv("AWS_BUCKET_NAME")
if _bucket:
    logger.info("Media uploads will use S3 bucket: %s", _bucket)
else:
    logger.warning(
        "AWS_BUCKET_NAME is not set — uploads fall back to local /uploads and "
        "WILL disappear on container redeploy."
    )

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
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_order_id VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_purchase_token VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP;"))
        # Social & Privacy
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS share_phone BOOLEAN DEFAULT FALSE;"))
        # Join date (used by the app to limit calendar history)
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;"))
        # Backfill: accounts that predate the created_at column got stamped
        # with the migration date. Use their earliest food log as the real
        # join date so history goes back to when they actually subscribed.
        conn.execute(text("""
            UPDATE users SET created_at = LEAST(
                users.created_at,
                COALESCE((SELECT MIN(f.created_at) FROM food_logs f WHERE f.user_id = users.id), users.created_at)
            );
        """))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_influencer BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS influencers (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id),
                display_name VARCHAR NOT NULL,
                handle VARCHAR,
                platform VARCHAR,
                notes TEXT,
                commission_rate FLOAT,
                panel_access BOOLEAN DEFAULT TRUE,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS promo_codes (
                id VARCHAR(36) PRIMARY KEY,
                influencer_id VARCHAR(36) NOT NULL REFERENCES influencers(id) ON DELETE CASCADE,
                code VARCHAR NOT NULL UNIQUE,
                plan_type VARCHAR NOT NULL,
                max_redemptions INTEGER,
                redemption_count INTEGER DEFAULT 0,
                is_active BOOLEAN DEFAULT TRUE,
                expires_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS promo_redemptions (
                id VARCHAR(36) PRIMARY KEY,
                promo_code_id VARCHAR(36) NOT NULL REFERENCES promo_codes(id) ON DELETE CASCADE,
                user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id),
                plan_granted VARCHAR NOT NULL,
                redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_promo_codes_influencer ON promo_codes (influencer_id);"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_promo_redemptions_code ON promo_redemptions (promo_code_id);"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_discount_used BOOLEAN DEFAULT FALSE;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS clan_id VARCHAR(36);"))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS clans (
                id VARCHAR(36) PRIMARY KEY,
                owner_user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id),
                plan_id VARCHAR NOT NULL DEFAULT 'monthly',
                stripe_subscription_id VARCHAR,
                status VARCHAR DEFAULT 'active',
                max_members INTEGER DEFAULT 5,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS clan_members (
                id VARCHAR(36) PRIMARY KEY,
                clan_id VARCHAR(36) NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
                user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id),
                role VARCHAR DEFAULT 'member',
                addon_active BOOLEAN DEFAULT FALSE,
                joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS clan_invites (
                id VARCHAR(36) PRIMARY KEY,
                clan_id VARCHAR(36) NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
                email VARCHAR NOT NULL,
                token VARCHAR NOT NULL UNIQUE,
                status VARCHAR DEFAULT 'pending',
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_clan_members_clan ON clan_members (clan_id);"))
        conn.execute(text("ALTER TABLE promo_codes ADD COLUMN IF NOT EXISTS platform VARCHAR DEFAULT 'internal';"))
        conn.execute(text("ALTER TABLE promo_codes ADD COLUMN IF NOT EXISTS store_product_id VARCHAR;"))
        conn.execute(text("ALTER TABLE promo_codes ADD COLUMN IF NOT EXISTS notes TEXT;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_promo_code_id VARCHAR(36);"))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS share_grants (
                id VARCHAR(36) PRIMARY KEY,
                owner_user_id VARCHAR(36) REFERENCES users(id),
                viewer_user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                invite_email VARCHAR,
                token VARCHAR NOT NULL UNIQUE,
                status VARCHAR DEFAULT 'pending',
                scopes VARCHAR DEFAULT 'nutrition,exercises',
                expires_at TIMESTAMP NOT NULL,
                accepted_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_share_grants_viewer ON share_grants (viewer_user_id);"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_share_grants_owner ON share_grants (owner_user_id);"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_share_grants_token ON share_grants (token);"))
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
        # Events — ensure table/columns exist on prod without relying on Alembic
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS events (
                id VARCHAR(36) PRIMARY KEY,
                creator_id VARCHAR(36) NOT NULL REFERENCES users(id),
                title VARCHAR NOT NULL,
                description TEXT,
                event_type VARCHAR NOT NULL,
                location_name VARCHAR,
                latitude FLOAT,
                longitude FLOAT,
                start_time TIMESTAMP NOT NULL,
                whatsapp_link VARCHAR,
                image_url VARCHAR,
                max_participants INTEGER,
                audience VARCHAR NOT NULL DEFAULT 'mixed',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS image_url VARCHAR;"))
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS image_urls JSON;"))
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS max_participants INTEGER;"))
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS audience VARCHAR DEFAULT 'mixed';"))
        conn.execute(text("UPDATE events SET audience = 'mixed' WHERE audience IS NULL;"))
        conn.execute(text("""
            DO $$ BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'events' AND column_name = 'audience'
                ) THEN
                    ALTER TABLE events ALTER COLUMN audience SET DEFAULT 'mixed';
                END IF;
            END $$;
        """))
        conn.execute(text("""
            CREATE INDEX IF NOT EXISTS ix_events_audience ON events (audience);
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS event_participants (
                id VARCHAR(36) PRIMARY KEY,
                event_id VARCHAR(36) NOT NULL REFERENCES events(id) ON DELETE CASCADE,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id),
                joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    import logging
    logging.getLogger(__name__).error("Migration schema update error: %s", e, exc_info=True)

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

_raw_origins = os.getenv("ALLOWED_ORIGINS", "*")
allowed_origins = [
    origin.strip()
    for part in _raw_origins.replace("\n", ",").split(",")
    for origin in [part.strip()]
    if origin
]

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


@app.get("/share/join")
def share_join_landing(token: str = ""):
    """Public landing page for share invites (web domain is not live yet)."""
    safe_token = urllib.parse.quote(token or "", safe="")
    # Escape for HTML text / attribute contexts
    display = (
        (token or "missing token")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )
    app_link = f"gojocalories:///share/join?token={safe_token}"
    app_link_js = app_link.replace("\\", "\\\\").replace("'", "\\'")
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>GojoCalories — Share invite</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;
      margin: 0; padding: 24px; background: #f4f7f8; color: #122026; }}
    .card {{ max-width: 420px; margin: 40px auto; background: #fff; border-radius: 16px;
      padding: 24px; box-shadow: 0 8px 24px rgba(0,0,0,.06); }}
    h1 {{ font-size: 22px; margin: 0 0 8px; }}
    p {{ color: #5b6b73; line-height: 1.45; }}
    .code {{ word-break: break-all; background: #eef3f4; padding: 12px; border-radius: 10px;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; }}
    a.btn, button.btn {{ display: block; width: 100%; box-sizing: border-box; text-align: center;
      background: #0d9488; color: #fff; text-decoration: none; border: 0; border-radius: 12px;
      padding: 14px 16px; font-size: 16px; font-weight: 600; margin-top: 16px; cursor: pointer; }}
    button.btn.secondary {{ background: #334155; }}
    .hint {{ font-size: 13px; margin-top: 16px; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>Diary invite</h1>
    <p>Someone invited you to share access in GojoCalories. Open the app to accept.</p>
    <a class="btn" href="{app_link}">Open in GojoCalories</a>
    <button class="btn secondary" type="button" id="copyBtn">Copy invite code</button>
    <p class="hint">Or open GojoCalories → Profile → Share Access → paste this code:</p>
    <div class="code" id="token">{display}</div>
  </div>
  <script>
    var token = document.getElementById('token').textContent;
    document.getElementById('copyBtn').onclick = function () {{
      navigator.clipboard.writeText(token);
    }};
    setTimeout(function () {{
      window.location.href = '{app_link_js}';
    }}, 400);
  </script>
</body>
</html>"""
    return HTMLResponse(content=html)


app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])
app.include_router(promo.router, prefix="/api/payments", tags=["Promo"])
app.include_router(clan.router, prefix="/api/clan", tags=["Clan"])
app.include_router(shares.router, prefix="/api/shares", tags=["Share Access"])
app.include_router(apple_iap.router, prefix="/api/payments/apple", tags=["Apple IAP"])
app.include_router(google_iap.router, prefix="/api/payments/google", tags=["Google IAP"])

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
app.include_router(admin_router.router, prefix="/api/admin", tags=["Admin"])

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


# ── Smart nutrition notification scheduler ────────────────────────────────────
# Runs the personalized nutrition check at fixed LOCAL times each day
# (default 10:00, 12:00, 14:00, 16:00, 18:00, 20:00 — first reminder at 10am,
# then every 2 hours). Local time = UTC + SMART_NOTIF_TZ_OFFSET_MIN.
# The check itself enforces quiet hours and per-user daily caps.
SMART_NOTIF_ENABLED = os.getenv("SMART_NOTIF_ENABLED", "true").lower() in ("1", "true", "yes")
SMART_NOTIF_LOCAL_HOURS = os.getenv("SMART_NOTIF_LOCAL_HOURS", "10,12,14,16,18,20")

_scheduler = None


@app.on_event("startup")
def _start_smart_notification_scheduler():
    global _scheduler
    if not SMART_NOTIF_ENABLED:
        logger.info("Smart nutrition scheduler disabled (SMART_NOTIF_ENABLED=false)")
        return
    if not os.getenv("ONESIGNAL_REST_API_KEY"):
        logger.warning("Smart nutrition scheduler not started: ONESIGNAL_REST_API_KEY not set")
        return
    try:
        from apscheduler.schedulers.background import BackgroundScheduler
        from services.smart_nutrition_service import TZ_OFFSET_MIN, run_nutrition_check_job

        local_hours = [int(h) for h in SMART_NOTIF_LOCAL_HOURS.split(",") if h.strip()]
        # Convert local wall-clock times to UTC slots (scheduler runs in UTC).
        utc_slots = {}
        for h in local_hours:
            total = (h * 60 - TZ_OFFSET_MIN) % (24 * 60)
            utc_slots.setdefault(total % 60, []).append(total // 60)

        _scheduler = BackgroundScheduler(daemon=True, timezone="UTC")
        for minute, hours in utc_slots.items():
            _scheduler.add_job(
                run_nutrition_check_job,
                "cron",
                hour=",".join(str(h) for h in sorted(hours)),
                minute=minute,
                id=f"smart_nutrition_check_{minute}",
                max_instances=1,
                coalesce=True,
            )
        _scheduler.start()
        logger.info(
            "Smart nutrition scheduler started (local hours %s, tz offset %d min)",
            local_hours, TZ_OFFSET_MIN,
        )
    except Exception:
        logger.exception("Failed to start smart nutrition scheduler")


@app.on_event("shutdown")
def _stop_smart_notification_scheduler():
    if _scheduler:
        _scheduler.shutdown(wait=False)
