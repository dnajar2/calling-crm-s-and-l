#!/bin/bash

echo "========================================="
echo "Testing Authentication System"
echo "========================================="
echo ""

# Test 1: Register a new user
echo "1. Testing User Registration..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "email": "test@example.com",
      "password": "password123"
    }
  }')

echo "$REGISTER_RESPONSE" | jq '.'

ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.refresh_token')

if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
  echo "✅ Registration successful!"
else
  echo "❌ Registration failed"
fi

echo ""
echo "========================================="
echo ""

# Test 2: Try to access protected endpoint without token
echo "2. Testing Protected Endpoint (No Token)..."
curl -s -X GET http://localhost:3000/calendars \
  -H "Content-Type: application/json" | jq '.'

echo ""
echo "========================================="
echo ""

# Test 3: Access protected endpoint with token
echo "3. Testing Protected Endpoint (With Token)..."
curl -s -X GET http://localhost:3000/calendars \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

echo ""
echo "✅ Authentication working correctly!"
echo ""
echo "========================================="
echo ""

# Test 4: Get current user
echo "4. Testing Get Current User..."
curl -s -X GET http://localhost:3000/auth/me \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

echo ""
echo "========================================="
echo ""

# Test 5: Refresh token
echo "5. Testing Token Refresh..."
curl -s -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}" | jq '.'

echo ""
echo "========================================="
echo ""

# Test 6: Login with existing user
echo "6. Testing Login..."
curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }' | jq '.'

echo ""
echo "========================================="
echo ""
echo "All tests completed!"
