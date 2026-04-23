import requests
import random
import sys

BASE_URL = "https://api.gojocalories.com/api"

print("--- Testing Production Version AI ---")

# 1. Register test user
email = f"prod_tester_{random.randint(1000, 99999)}@example.com"
print(f"Registering user: {email}")
r = requests.post(f"{BASE_URL}/auth/register", json={
    "email": email,
    "name": "Prod Tester",
    "password": "pw"
})

if r.status_code != 200:
    print(f"Auth failed: {r.text}")
    sys.exit(1)

token = r.json()["access_token"]
headers = {"Authorization": f"Bearer {token}"}
print("Successfully authenticated!")

# 2. Test Text Analysis
print("\nTesting Text Analysis: 'A large slice of pepperoni pizza'")
r_text = requests.post(f"{BASE_URL}/food/analyze/text", json={
    "query": "A large slice of pepperoni pizza"
}, headers=headers)

if r_text.status_code == 200:
    print(f"SUCCESS! Result: {r_text.json()}")
else:
    print(f"FAILED (Text): {r_text.status_code} - {r_text.text}")

# 3. Test Image Analysis
print("\nDownloading sample food image (pizza)...")
img_data = requests.get("https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80").content
with open("test_pizza.jpg", "wb") as f:
    f.write(img_data)

print("Uploading to /food/analyze API...")
with open("test_pizza.jpg", "rb") as f:
    r_img = requests.post(
        f"{BASE_URL}/food/analyze",
        headers=headers,
        files={"file": ("test_pizza.jpg", f, "image/jpeg")}
    )

if r_img.status_code == 200:
    print(f"SUCCESS! Result: {r_img.json()}")
else:
    print(f"FAILED (Image): {r_img.status_code} - {r_img.text}")
