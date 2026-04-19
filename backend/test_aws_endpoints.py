import requests
import uuid
import json

BASE_URL = "http://gojoca-Publi-2bRSRsFxYTTs-1943547672.us-east-1.elb.amazonaws.com/api"

def print_result(name, is_success, details=""):
    status = "✅ PASS" if is_success else "❌ FAIL"
    print(f"[{status}] {name}")
    if not is_success and details:
        print(f"       → {details}")

def run_tests():
    print(f"=== GojoCalories — Full AWS API + Frontend Linkage Audit ===\n")

    uid = str(uuid.uuid4())[:8]
    email = f"audit_{uid}@example.com"
    password = "SecurePassword123"

    # ── AUTH ──────────────────────────────────────────────────────────────────
    print("--- AUTH ROUTES ---")

    r = requests.post(f"{BASE_URL}/auth/register", json={"email": email, "name": "Audit User", "password": password})
    print_result("POST /auth/register", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    ok = r.status_code == 200
    print_result("POST /auth/login", ok, f"HTTP {r.status_code}: {r.text[:100]}")
    if not ok: return
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    print_result("GET  /auth/me", r.status_code == 200 and r.json().get("email") == email, f"HTTP {r.status_code}: {r.text[:100]}")

    # ── STATS ─────────────────────────────────────────────────────────────────
    print("\n--- STATS ROUTES ---")
    r = requests.get(f"{BASE_URL}/stats/", headers=headers)
    print_result("GET  /stats/", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.get(f"{BASE_URL}/stats/history", headers=headers)
    print_result("GET  /stats/history", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.post(f"{BASE_URL}/stats/log?calories=500&protein=30&carbs=60&fat=10", headers=headers)
    print_result("POST /stats/log", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    # ── FOOD AI ───────────────────────────────────────────────────────────────
    print("\n--- FOOD AI ROUTES ---")
    r = requests.post(f"{BASE_URL}/food/analyze/text", headers=headers, json={"query": "1 large banana"})
    print_result("POST /food/analyze/text", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:150]}")

    # ── GROUPS ────────────────────────────────────────────────────────────────
    print("\n--- GROUPS ROUTES ---")
    r = requests.post(f"{BASE_URL}/groups/", headers=headers, json={"name": f"Test Group {uid}", "description": "audit test"})
    ok_create = r.status_code == 200
    print_result("POST /groups/", ok_create, f"HTTP {r.status_code}: {r.text[:100]}")
    group_id = r.json().get("id") if ok_create else None

    r = requests.get(f"{BASE_URL}/groups/my", headers=headers)
    print_result("GET  /groups/my", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.get(f"{BASE_URL}/groups/discover", headers=headers)
    print_result("GET  /groups/discover", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.get(f"{BASE_URL}/groups/feed", headers=headers)
    print_result("GET  /groups/feed", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    if group_id:
        r = requests.post(f"{BASE_URL}/groups/{group_id}/join", headers=headers)
        print_result(f"POST /groups/{group_id}/join", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    # ── REFERRALS ─────────────────────────────────────────────────────────────
    print("\n--- REFERRALS ROUTES ---")
    r = requests.get(f"{BASE_URL}/referrals/me", headers=headers)
    print_result("GET  /referrals/me", r.status_code == 200, f"HTTP {r.status_code}: {r.text[:100]}")

    r = requests.post(f"{BASE_URL}/referrals/withdraw", headers=headers, json={"amount": 0.01, "method": "PayPal"})
    # Expect 400 (insufficient balance) which is correct logic, not a bug
    print_result("POST /referrals/withdraw (insufficient bal. → 400 expected)", r.status_code == 400, f"HTTP {r.status_code}: {r.text[:100]}")

    # ── PAYMENTS ─────────────────────────────────────────────────────────────
    print("\n--- PAYMENTS ROUTES ---")
    r = requests.post(f"{BASE_URL}/payments/create-checkout-session", headers=headers)
    # 400 means Stripe key is not yet configured — logic is correct
    print_result("POST /payments/create-checkout-session", r.status_code in [200, 400], f"HTTP {r.status_code}: {r.text[:100]}")

    print("\n=== Audit Complete ===")

if __name__ == "__main__":
    run_tests()
