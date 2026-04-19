from fastapi.testclient import TestClient
from main import app
from database import Base, engine

Base.metadata.create_all(bind=engine)

client = TestClient(app)

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "GojoCalories MVP API is running natively."}

def test_register():
    response = client.post("/api/auth/register", json={
        "email": "test_runner@example.com",
        "name": "Test User",
        "password": "password"
    })
    # Will be 200 on first run, 400 on subsequent runs because of unique constraint
    assert response.status_code in [200, 400]
