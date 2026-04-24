import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_barcode_standard_product():
    # 0049000028904 is Coca Cola which has energy-kcal in 100g or serving
    # Note: tests against live external API
    # Since auth is required, we mock current_user_id by overriding dependency if needed
    from security import get_current_user_id
    app.dependency_overrides[get_current_user_id] = lambda: 1
    
    response = client.get("/api/food/barcode/0049000028904")
    
    assert response.status_code == 200
    data = response.json()
    assert "calories" in data
    assert "name" in data
    
    app.dependency_overrides.clear()

def test_barcode_missing_product():
    from security import get_current_user_id
    app.dependency_overrides[get_current_user_id] = lambda: 1
    
    # Random invalid barcode
    response = client.get("/api/food/barcode/99999999999999")
    
    assert response.status_code == 404
    data = response.json()
    assert "Product not found" in data["detail"]
    
    app.dependency_overrides.clear()
