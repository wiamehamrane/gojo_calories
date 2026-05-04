import requests
import uuid
import json
import os

BASE_URL = "https://api.gojocalories.com/api"
IMAGE_PATH = "test_pizza.jpg"

def print_result(name, is_success, details=""):
    status = "✅ PASS" if is_success else "❌ FAIL"
    print(f"[{status}] {name}")
    if not is_success and details:
        print(f"       → {details}")

def run_tests():
    print(f"=== GojoCalories — Final Production Audit ===\n")
    print(f"Target: {BASE_URL}")

    uid = str(uuid.uuid4())[:8]
    email = f"prod_test_{uid}@example.com"
    password = "ProdPassword123"

    # 1. AUTH
    print("\n--- [1] AUTHENTICATION ---")
    r = requests.post(f"{BASE_URL}/auth/register", json={"email": email, "name": "Prod Auditor", "password": password})
    print_result("POST /auth/register", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    ok = r.status_code == 200
    print_result("POST /auth/login", ok, f"HTTP {r.status_code}: {r.text[:100]}")
    if not ok: return
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. TEXT SCAN
    print("\n--- [2] TEXT SCAN (GEMINI) ---")
    r = requests.post(f"{BASE_URL}/food/analyze/text", headers=headers, json={"query": "1 bowl of oatmeal with blueberries"})
    print_result("POST /food/analyze/text", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:150]}")

    # 3. IMAGE SCAN (GEMINI + S3)
    print("\n--- [3] IMAGE SCAN (GEMINI + S3) ---")
    if os.path.exists(IMAGE_PATH):
        with open(IMAGE_PATH, 'rb') as f:
            files = {'file': ('apple.jpg', f, 'image/jpeg')}
            r = requests.post(f"{BASE_URL}/food/analyze", headers=headers, files=files)
            
        ok = r.status_code == 200
        details = f"HTTP {r.status_code}: {r.text[:150]}"
        if ok:
            data = r.json()
            image_url = data.get('image_url', '')
            if 'amazonaws.com' in image_url:
                details = f"Success! Image uploaded to S3: {image_url}"
                print_result("POST /food/analyze", True, details)
            else:
                print_result("POST /food/analyze", False, f"Success but image URL is not S3: {image_url}")
        else:
            print_result("POST /food/analyze", False, details)
    else:
        print_result("POST /food/analyze", False, f"Test image not found at {IMAGE_PATH}")

    # 4. BARCODE SCAN (OPEN FOOD FACTS)
    print("\n--- [4] BARCODE SCAN (OFF) ---")
    barcode = "3017620422003" # Nutella
    r = requests.get(f"{BASE_URL}/food/barcode/{barcode}", headers=headers)
    ok = r.status_code == 200
    details = f"HTTP {r.status_code}: {r.text[:150]}"
    if ok:
        data = r.json()
        print_result(f"GET /food/barcode/{barcode}", True, f"Found: {data.get('name')} - {data.get('calories')} kcal")
    else:
        print_result(f"GET /food/barcode/{barcode}", False, details)

    # 5. PAYMENTS (STRIPE)
    print("\n--- [5] PAYMENTS (STRIPE) ---")
    r = requests.post(f"{BASE_URL}/payments/create-checkout-session", headers=headers)
    ok = r.status_code == 200
    details = f"HTTP {r.status_code}: {r.text[:150]}"
    if ok:
        data = r.json()
        print_result("POST /payments/create-checkout-session", True, f"Session URL: {data.get('url')[:60]}...")
    else:
        print_result("POST /payments/create-checkout-session", False, details)

    print("\n=== Production Audit Complete ===")

if __name__ == "__main__":
    run_tests()
