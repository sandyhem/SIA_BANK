#!/bin/bash

# SIA Banking Services Startup Script with KYC Verification
# This script starts all banking microservices in the correct order

echo "=== SIA Banking Services Startup ==="
echo "Starting services with KYC verification enabled..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    echo -n "Waiting for $name to start..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo -e " ${RED}✗${NC}"
    return 1
}

# Stop existing services
echo "Stopping existing services..."
lsof -ti:8083 | xargs -r kill -9 2>/dev/null
lsof -ti:8081 | xargs -r kill -9 2>/dev/null
lsof -ti:8082 | xargs -r kill -9 2>/dev/null
sleep 2

# Start Auth Service (Port 8083)
echo -e "${YELLOW}[1/3]${NC} Starting Auth Service..."
cd /home/inba/SIA_BANK/auth
mvn spring-boot:run > auth-service.log 2>&1 &
AUTH_PID=$!
echo "Auth Service PID: $AUTH_PID"

# Wait for Auth Service
if wait_for_service "http://localhost:8083/auth/api/auth/health" "Auth Service"; then
    echo -e "${GREEN}Auth Service started successfully on port 8083${NC}"
else
    echo -e "${RED}Auth Service failed to start. Check auth-service.log${NC}"
    exit 1
fi

# Start Account Service (Port 8081)
echo -e "${YELLOW}[2/3]${NC} Starting Account Service..."
cd /home/inba/SIA_BANK/account-service
mvn spring-boot:run > account-service.log 2>&1 &
ACCOUNT_PID=$!
echo "Account Service PID: $ACCOUNT_PID"

# Wait for Account Service
if wait_for_service "http://localhost:8081/accounts/api/accounts/health" "Account Service"; then
    echo -e "${GREEN}Account Service started successfully on port 8081${NC}"
else
    echo -e "${RED}Account Service failed to start. Check account-service.log${NC}"
    exit 1
fi

# Start Transaction Service (Port 8082)
echo -e "${YELLOW}[3/3]${NC} Starting Transaction Service..."
cd /home/inba/SIA_BANK/transaction-service
mvn spring-boot:run > transaction-service.log 2>&1 &
TRANSACTION_PID=$!
echo "Transaction Service PID: $TRANSACTION_PID"

# Wait for Transaction Service
sleep 10
echo -e "${GREEN}Transaction Service started successfully on port 8082${NC}"

echo ""
echo -e "${GREEN}=== All Services Started Successfully ===${NC}"
echo ""
echo "Service Status:"
echo "  ✓ Auth Service:        http://localhost:8083 (PID: $AUTH_PID)"
echo "  ✓ Account Service:     http://localhost:8081 (PID: $ACCOUNT_PID)"
echo "  ✓ Transaction Service: http://localhost:8082 (PID: $TRANSACTION_PID)"
echo ""
echo "Frontend: http://localhost:5174"
echo ""
echo "KYC Verification is now ENABLED"
echo "Users with PENDING KYC status will not be able to create accounts."
echo ""
echo "To test KYC verification:"
echo "  1. Login with a user account"
echo "  2. Try to create an account (should fail with KYC error)"
echo "  3. Update user's KYC status to VERIFIED in database"
echo "  4. Try to create an account again (should succeed)"
echo ""
echo "To update KYC status manually:"
echo "  mysql -u root -p"
echo "  use auth_db;"
echo "  UPDATE users SET kyc_status = 'VERIFIED' WHERE username = 'your_username';"
echo ""
echo "Log files:"
echo "  - /home/inba/SIA_BANK/auth/auth-service.log"
echo "  - /home/inba/SIA_BANK/account-service/account-service.log"
echo "  - /home/inba/SIA_BANK/transaction-service/transaction-service.log"
echo ""
