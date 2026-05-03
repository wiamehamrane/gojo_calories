import json
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

def _build_database_url() -> str:
    """
    Prefer the Aurora secret injected by AWS Copilot (DB_SECRET) which is a
    JSON string containing host, port, username, password, and dbname.
    Falls back to the plain DATABASE_URL env var for local development.
    """
    db_secret = os.getenv("DB_SECRET")
    if db_secret:
        secret = json.loads(db_secret)
        user = secret["username"]
        password = secret["password"]
        host = secret["host"]
        port = secret.get("port", 5432)
        dbname = secret.get("dbname", "gojocalories")
        return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"

    return os.getenv(
        "DATABASE_URL",
        "postgresql://user:password@localhost:5432/gojocalories",
    )


DATABASE_URL = _build_database_url()

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
