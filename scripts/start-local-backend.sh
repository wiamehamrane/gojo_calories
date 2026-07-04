#!/usr/bin/env bash
# Start local Postgres (Docker or Homebrew) and the FastAPI backend.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
PORT="${PORT:-8000}"

echo "==> Local backend on port $PORT (macOS AirPlay uses 5000 — avoid it)"

if command -v docker >/dev/null 2>&1; then
  echo "==> Starting Postgres + Redis via Docker..."
  docker compose -f "$BACKEND/docker-compose.yml" up -d
  echo "==> Waiting for Postgres..."
  for i in {1..30}; do
    if docker compose -f "$BACKEND/docker-compose.yml" exec -T db pg_isready -U user -d gojocalories >/dev/null 2>&1; then
      echo "    Postgres is ready."
      break
    fi
    sleep 1
    if [[ $i -eq 30 ]]; then
      echo "Postgres did not become ready in time."
      exit 1
    fi
  done
else
  echo "==> Docker not found — using local Postgres (brew services start postgresql@14)"
  if ! pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    echo "    Postgres is not running. Start it with: brew services start postgresql@14"
    exit 1
  fi
  echo "    Postgres is ready."
fi

cd "$BACKEND"

if [[ ! -d venv ]]; then
  echo "==> Creating Python venv..."
  python3 -m venv venv
fi

echo "==> Installing Python dependencies..."
source venv/bin/activate
if ! pip install -q -r requirements.txt 2>/dev/null; then
  echo "    Full requirements failed (Python 3.9?) — installing core packages..."
  pip install -q fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv \
    passlib bcrypt PyJWT python-multipart httpx redis stripe boto3 pillow openai
fi

LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'YOUR_MAC_IP')"
echo ""
echo "==> API running at:"
echo "    http://127.0.0.1:$PORT/health"
echo "    http://127.0.0.1:$PORT/api/"
echo "    http://$LAN_IP:$PORT/api/  (physical iPhone — set API_URL in .env)"
export LOG_LEVEL="${LOG_LEVEL:-DEBUG}"
echo "    Logs: LOG_LEVEL=$LOG_LEVEL (every request is printed below)"
echo ""
exec python -m uvicorn main:app --host 0.0.0.0 --port "$PORT" --reload \
  --log-level debug --access-log
