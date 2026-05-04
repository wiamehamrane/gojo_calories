import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Use hardcoded default localhost since it's local docker
try:
    conn = psycopg2.connect("postgresql://user:password@localhost:5432/gojocalories")
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS alembic_version;")
    conn.commit()
    print("Dropped alembic_version table.")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
