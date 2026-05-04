import psycopg2

try:
    conn = psycopg2.connect("postgresql://user:password@localhost:5432/gojocalories")
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("DROP SCHEMA public CASCADE;")
    cur.execute("CREATE SCHEMA public;")
    cur.execute("GRANT ALL ON SCHEMA public TO public;")
    cur.execute("GRANT ALL ON SCHEMA public TO \"user\";")
    print("Schema wiped.")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
