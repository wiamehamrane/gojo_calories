#!/bin/bash
cd /home/zelghourfi/Documents/gojocalories/backend

echo "Starting PostgreSQL via docker-compose..."
docker-compose up -d

echo "Activating virtual environment if it exists and installing requirements..."
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Ensure requirements are installed
pip install -r requirements.txt || true
pip install uvicorn fastapi sqlalchemy psycopg2-binary || echo "Make sure to install requirements."

echo "Applying Alembic migrations..."
alembic upgrade head

echo "Starting FastAPI backend bound to 0.0.0.0:5000..."
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
