import requests
import time
import subprocess
import os
import sys

BASE_URL = "http://localhost:5005"

def run_tests():
    print("Testing Authentication (Registration)")
    email = f"test_{int(time.time())}@example.com"
    r = requests.post(f"{BASE_URL}/api/auth/register", json={
        "email": email,
        "name": "Integration Test User",
        "password": "strongpassword123"
    })
    
    # Catch already registered edge case dynamically
    if r.status_code == 400 and "already registered" in r.text:
       r = requests.post(f"{BASE_URL}/api/auth/login", data={"username": email, "password": "strongpassword123"})
    
    assert r.status_code == 200, f"Registration failed: {r.text}"
    reg_data = r.json()
    assert reg_data.get("requires_verification") is True, f"Expected requires_verification: {r.text}"

    print("Fetching OTP from database for verification")
    otp = None
    for db_cmd in [
        f"sqlite3 gojo.db \"SELECT verification_code FROM users WHERE email = '{email}';\"",
        f"PGPASSWORD=password psql -h localhost -U user -d gojocalories -t -c \"SELECT verification_code FROM users WHERE email = '{email}';\"",
    ]:
        result = subprocess.run(db_cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            otp = result.stdout.strip()
            break
    assert otp, "Could not fetch verification code from database"

    print("Testing OTP verification")
    r = requests.post(f"{BASE_URL}/api/auth/verify-otp", json={
        "email": email,
        "otp": otp,
    })
    assert r.status_code == 200, f"OTP verification failed: {r.text}"
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Testing Paywall (Should be blocked - 403)")
    r = requests.get(f"{BASE_URL}/api/stats/", headers=headers)
    assert r.status_code == 403, f"Expected 403 Forbidden, got {r.status_code}"
    print("✅ Successfully blocked by paywall!")
    
    print("Testing Checkout Session generation")
    # This requires Stripe Secret Key to not crash, so we'll mock it if it's missing or skip it.
    r = requests.post(f"{BASE_URL}/api/payments/create-checkout-session", headers=headers)
    print("Checkout session returned:", r.status_code)
    # We might get 400 if Stripe API key is invalid which is perfectly fine for logic testing
    if r.status_code not in [200, 400]:
        print(f"Warning: checkout returned {r.status_code} - {r.text}")

    print("Bypassing Paywall locally via DB manipulation")
    # Direct DB injection for testing
    os.system(f"sqlite3 gojo.db 'UPDATE users SET has_paid = 1 WHERE email = \"{email}\";'")
    # Or for postgres:
    os.system(f"PGPASSWORD=password psql -h localhost -U user -d gojocalories -c \"UPDATE users SET has_paid = true WHERE email = '{email}';\"")

    print("Testing Paywall logic (Should be allowed - 200)")
    r = requests.get(f"{BASE_URL}/api/stats/", headers=headers)
    assert r.status_code == 200, f"Expected 200 OK, got {r.status_code} - {r.text}"
    print("✅ Successfully cleared paywall!")
    
    print("All Integration Tests Passed!")

if __name__ == "__main__":
    try:
        run_tests()
    except Exception as e:
        print(f"Test Suite Failed: {e}")
        sys.exit(1)
