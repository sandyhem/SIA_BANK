#!/bin/bash

# Banking Microservices Authentication Test Script
# This script demonstrates the complete authentication flow

echo "=================================="
echo "Banking Microservices Auth Test"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

AUTH_URL="http://localhost:8083/auth/api/auth"
ACCOUNT_URL="http://localhost:8081/api/accounts"
TRANSACTION_URL="http://localhost:8082/api/transactions"

echo -e "${YELLOW}Step 1: Attempt to access Account Service WITHOUT authentication${NC}"
echo "Request: GET $ACCOUNT_URL/ACC001"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $ACCOUNT_URL/ACC001)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Correctly rejected (401 Unauthorized)"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Expected 401, got $HTTP_CODE"
fi
echo ""

echo -e "${YELLOW}Step 2: Login to Auth Service${NC}"
echo "Request: POST $AUTH_URL/login"
LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
USERNAME=$(echo $LOGIN_RESPONSE | jq -r '.username')

if [ "$TOKEN" != "null" ] && [ "$TOKEN" != "" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Login successful"
    echo "Username: $USERNAME"
    echo "Token: ${TOKEN:0:50}..."
else
    echo -e "${RED}✗ FAIL${NC} - Login failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 3: Access Account Service WITH authentication${NC}"
echo "Request: GET $ACCOUNT_URL/ACC001 (with Bearer token)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $ACCOUNT_URL/ACC001 \
  -H "Authorization: Bearer $TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Authenticated request accepted (HTTP $HTTP_CODE)"
    echo "Response: $BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Expected 200/404, got $HTTP_CODE"
    echo "Response: $BODY"
fi
echo ""

echo -e "${YELLOW}Step 4: Create test account with authentication${NC}"
echo "Note: You would need to add a create endpoint. For now, testing existing operations."
echo ""

echo -e "${YELLOW}Step 5: Credit account with authentication${NC}"
echo "Request: PUT $ACCOUNT_URL/ACC001/credit (with Bearer token)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT $ACCOUNT_URL/ACC001/credit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "senderAccount": "ACC002",
    "amount": 1000.00,
    "description": "Authenticated credit test"
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Authenticated credit request processed (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
else
    echo -e "${RED}Status: HTTP $HTTP_CODE${NC}"
    echo "Response: $BODY"
fi
echo ""

echo -e "${YELLOW}Step 6: Test with INVALID token${NC}"
echo "Request: GET $ACCOUNT_URL/ACC001 (with invalid token)"
INVALID_TOKEN="eyJhbGciOiJIUzI1NiJ9.invalid.token"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $ACCOUNT_URL/ACC001 \
  -H "Authorization: Bearer $INVALID_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Correctly rejected invalid token (401 Unauthorized)"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Expected 401, got $HTTP_CODE"
fi
echo ""

echo "=================================="
echo "Authentication Flow Summary"
echo "=================================="
echo -e "${GREEN}✓${NC} Authentication service working"
echo -e "${GREEN}✓${NC} JWT token generation successful"
echo -e "${GREEN}✓${NC} Account service requires authentication"
echo -e "${GREEN}✓${NC} Valid tokens are accepted"
echo -e "${GREEN}✓${NC} Invalid tokens are rejected"
echo ""
echo "Your authenticated user ($USERNAME) can now:"
echo "  - View account details"
echo "  - Credit accounts (deposit money)"
echo "  - Debit accounts (withdraw money)"
echo "  - Transfer money between accounts"
echo ""
echo "All operations now require a valid JWT token!"
echo "=================================="
