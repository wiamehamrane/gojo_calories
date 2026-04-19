#!/bin/bash

# Ensure curl output is captured neatly
echo "=== 1. Registering User ==="
curl -s -X POST "http://localhost:5005/api/auth/register" -H "Content-Type: application/json" -d '{"email": "test_curl@gojocalories.com", "name": "cURL User", "password": "password123"}' > /dev/null

echo "=== 2. Logging In to get JWT ==="
RESPONSE=$(curl -s -X POST "http://localhost:5005/api/auth/login" -d "username=test_curl@gojocalories.com&password=password123")
TOKEN=$(echo $RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "Failed to get token! Response: $RESPONSE"
    exit 1
fi
echo "- Token received successfully."

echo "=== 3. Testing Paywall Rejection (EXPECTED 403) ==="
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X GET "http://localhost:5005/api/stats/" -H "Authorization: Bearer $TOKEN"

echo "=== 4. Bypassing Paywall manually in PostgreSQL ==="
PGPASSWORD=password psql -h localhost -U user -d gojocalories -c "UPDATE users SET has_paid = true WHERE email = 'test_curl@gojocalories.com';" > /dev/null

echo "=== 5. Testing Paywall Clearance (EXPECTED 200) ==="
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X GET "http://localhost:5005/api/stats/" -H "Authorization: Bearer $TOKEN"

echo "=== 6. Testing /api/payments/create-checkout-session ==="
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "http://localhost:5005/api/payments/create-checkout-session" -H "Authorization: Bearer $TOKEN" -d ''
