#!/bin/bash

echo "========================================="
echo "CORS Fix Test Script"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Step 1: Checking service status..."
echo ""

# Check Auth Service
echo -n "Auth Service: "
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/auth/api/auth/health)
if [ "$AUTH_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ UP${NC}"
else
    echo -e "${RED}✗ DOWN (HTTP $AUTH_STATUS)${NC}"
fi

# Check Account Service  
echo -n "Account Service: "
ACCOUNT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/accounts/health)
if [ "$ACCOUNT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ UP${NC}"
else
    echo -e "${RED}✗ DOWN (HTTP $ACCOUNT_STATUS)${NC}"
    echo -e "${YELLOW}Trying to start account service...${NC}"
    cd /home/inba/SIA_BANK/account-service
    mvn clean > /dev/null 2>&1
    nohup mvn spring-boot:run > account-service.log 2>&1 &
    echo "Waiting 25 seconds for startup..."
    sleep 25
    ACCOUNT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/accounts/health)
    if [ "$ACCOUNT_STATUS" = "200" ]; then
        echo -e "${GREEN}✓ NOW UP${NC}"
    else
        echo -e "${RED}✗ STILL DOWN - Check logs: tail -50 account-service/account-service.log${NC}"
    fi
fi

# Check Transaction Service
echo -n "Transaction Service: "
TRANS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/transactions/health)
if [ "$TRANS_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ UP${NC}"
else
    echo -e "${RED}✗ DOWN (HTTP $TRANS_STATUS)${NC}"
    echo -e "${YELLOW}Trying to start transaction service...${NC}"
    cd /home/inba/SIA_BANK/transaction-service
    mvn clean > /dev/null 2>&1
    nohup mvn spring-boot:run > transaction-service.log 2>&1 &
    echo "Waiting 25 seconds for startup..."
    sleep 25
    TRANS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/transactions/health)
    if [ "$TRANS_STATUS" = "200" ]; then
        echo -e "${GREEN}✓ NOW UP${NC}"
    else
        echo -e "${RED}✗ STILL DOWN - Check logs: tail -50 transaction-service/transaction-service.log${NC}"
    fi
fi

echo ""
echo "========================================="
echo "Step 2: Testing CORS Headers"
echo "========================================="
echo ""

# Test CORS on customer endpoint
echo "Testing POST /auth/api/customers (the failing endpoint)..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
  -H "Origin: null" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -X OPTIONS \
  http://localhost:8083/auth/api/customers

echo ""
echo "If you see HTTP 200 above, CORS is working!"
echo ""
echo "========================================="
echo "Step 3: Test Customer Creation"
echo "========================================="
echo ""
echo "Now open the test UI in your browser:"
echo "file:///home/inba/SIA_BANK/test-ui-complete.html"
echo ""
echo "Then:"
echo "1. Register a new user"
echo "2. Fill customer profile form"
echo "3. Click 'Create Customer Profile (CIF)'"
echo "4. Check browser console (F12) for detailed logs"
echo ""
echo "The CORS error should be FIXED!"
echo "========================================="
