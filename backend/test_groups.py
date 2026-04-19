from fastapi.testclient import TestClient
from main import app
import random

client = TestClient(app)

def test_groups_flow():
    # 1. Register a user dynamically
    email = f"group_test_{random.randint(1000, 99999)}@example.com"
    r = client.post("/api/auth/register", json={
        "email": email,
        "name": "Group Tester",
        "password": "pw"
    })
    token = r.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Create a Group
    group_name = f"Test Group {random.randint(1000, 99999)}"
    r = client.post("/api/groups/", json={
        "name": group_name,
        "description": "A group for test"
    }, headers=headers)
    assert r.status_code == 200
    group_id = r.json()["id"]
    
    # 3. List my groups
    r = client.get("/api/groups/my", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) >= 1
    
    # 4. Fetch Discover
    r = client.get("/api/groups/discover", headers=headers)
    assert r.status_code == 200
    
    # 5. Fetch Feeds
    r = client.get("/api/groups/feed", headers=headers)
    assert r.status_code == 200
    assert isinstance(r.json(), list)
