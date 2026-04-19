from database import engine
from sqlalchemy import text

def fix_sequences():
    with engine.begin() as conn:
        conn.execute(text("SELECT setval('users_id_seq', COALESCE((SELECT MAX(id)+1 FROM users), 1), false);"))
        conn.execute(text("SELECT setval('daily_stats_id_seq', COALESCE((SELECT MAX(id)+1 FROM daily_stats), 1), false);"))
        conn.execute(text("SELECT setval('food_logs_id_seq', COALESCE((SELECT MAX(id)+1 FROM food_logs), 1), false);"))
    print("Sequences fixed!")

if __name__ == "__main__":
    fix_sequences()
