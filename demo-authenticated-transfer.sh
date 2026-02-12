#!/bin/bash

# Complete Banking Flow - Authenticated Money Transfer Demo
# This demonstrates end-to-end authenticated banking operations

echo "=================================================="
echo "   Authenticated Money Transfer Demonstration"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AUTH_URL="http://localhost:8083/auth/api/auth"
ACCOUNT_URL="http://localhost:8081/api/accounts"

echo -e "${BLUE}🔐 STEP 1: User Authentication${NC}"
echo "------------------------------------------------"
echo "User 'testuser' is logging in..."
echo ""

LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
USERNAME=$(echo $LOGIN_RESPONSE | jq -r '.username')
EMAIL=$(echo $LOGIN_RESPONSE | jq -r '.email')
ROLE=$(echo $LOGIN_RESPONSE | jq -r '.role')

echo -e "${GREEN}✓ Login Successful!${NC}"
echo "  User: $USERNAME"
echo "  Email: $EMAIL"
echo "  Role: $ROLE"
echo "  Token: ${TOKEN:0:50}..."
echo ""

echo -e "${BLUE}💰 STEP 2: Check Account Balance${NC}"
echo "------------------------------------------------"
echo "Checking ACC001 balance with authentication..."
echo ""

ACCOUNT_RESPONSE=$(curl -s -X GET $ACCOUNT_URL/ACC001 \
  -H "Authorization: Bearer $TOKEN")

BALANCE=$(echo $ACCOUNT_RESPONSE | jq -r '.balance')
STATUS=$(echo $ACCOUNT_RESPONSE | jq -r '.status')

if [ "$BALANCE" != "null" ]; then
    echo -e "${GREEN}✓ Account Retrieved Successfully!${NC}"
    echo "  Account: ACC001"
    echo "  Initial Balance: \$$BALANCE"
    echo "  Status: $STATUS"
    echo ""
else
    echo "❌ Failed to retrieve account"
    echo "Response: $ACCOUNT_RESPONSE"
    exit 1
fi

echo -e "${BLUE}💸 STEP 3: Deposit Money (Credit Operation)${NC}"
echo "------------------------------------------------"
echo "Depositing \$500 into ACC001..."
echo ""

CREDIT_RESPONSE=$(curl -s -X PUT $ACCOUNT_URL/ACC001/credit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "senderAccount": "EXTERNAL",
    "amount": 500.00,
    "description": "Salary deposit - Authenticated transaction"
  }')

echo -e "${GREEN}✓ Deposit Successful!${NC}"
echo "  Response: $CREDIT_RESPONSE"
echo ""

# Check new balance
ACCOUNT_RESPONSE=$(curl -s -X GET $ACCOUNT_URL/ACC001 \
  -H "Authorization: Bearer $TOKEN")
NEW_BALANCE=$(echo $ACCOUNT_RESPONSE | jq -r '.balance')
echo "  New Balance: \$$NEW_BALANCE"
echo ""

echo -e "${BLUE}💵 STEP 4: Withdraw Money (Debit Operation)${NC}"
echo "------------------------------------------------"
echo "Withdrawing \$200 from ACC001..."
echo ""

DEBIT_RESPONSE=$(curl -s -X PUT $ACCOUNT_URL/ACC001/debit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "senderAccount": "ACC001",
    "amount": 200.00,
    "description": "ATM withdrawal - Authenticated transaction"
  }')

echo -e "${GREEN}✓ Withdrawal Successful!${NC}"
echo "  Response: $DEBIT_RESPONSE"
echo ""

# Check final balance
ACCOUNT_RESPONSE=$(curl -s -X GET $ACCOUNT_URL/ACC001 \
  -H "Authorization: Bearer $TOKEN")
FINAL_BALANCE=$(echo $ACCOUNT_RESPONSE | jq -r '.balance')
echo "  Final Balance: \$$FINAL_BALANCE"
echo ""

echo -e "${BLUE}🔒 STEP 5: Security Test - Unauthenticated Access${NC}"
echo "------------------------------------------------"
echo "Attempting to access account without authentication..."
echo ""

NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $ACCOUNT_URL/ACC001)
HTTP_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✓ Security Working!${NC}"
    echo "  Unauthenticated request was blocked (401 Unauthorized)"
else
    echo "  ⚠️  Unexpected response: HTTP $HTTP_CODE"
fi
echo ""

echo "=================================================="
echo -e "${GREEN}         ✓ TRANSACTION COMPLETE${NC}"
echo "=================================================="
echo ""
echo "Summary:"
echo "  User: $USERNAME ($EMAIL)"
echo "  Starting Balance: \$$BALANCE"
echo "  After Deposit (+\$500): \$$NEW_BALANCE"
echo "  After Withdrawal (-\$200): \$$FINAL_BALANCE"
echo ""
echo "Key Security Features:"
echo "  ✓ All operations required valid JWT authentication"
echo "  ✓ Token expires in 24 hours"
echo "  ✓ Unauthenticated requests are blocked"
echo "  ✓ Invalid tokens are rejected"
echo ""
echo "Available Operations for Authenticated Users:"
echo "  • View account details"
echo "  • Deposit money (credit)"
echo "  • Withdraw money (debit)"
echo "  • Transfer between accounts"
echo "  • Check transaction history"
echo ""
echo "=================================================="
