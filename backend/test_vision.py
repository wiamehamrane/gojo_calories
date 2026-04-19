from fastapi.testclient import TestClient
from main import app
import random

client = TestClient(app)

def test_analyze_text():
    # 1. Register a user dynamically
    email = f"vision_tester_{random.randint(1000, 99999)}@example.com"
    r = client.post("/api/auth/register", json={
        "email": email,
        "name": "Vision Tester",
        "password": "pw"
    })
    token = r.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Assert text analysis
    r = client.post("/api/food/analyze/text", json={
        "query": "A small glass of water"
    }, headers=headers)
    
    assert r.status_code == 200
    data = r.json()
    assert "calories" in data
    assert "protein" in data
