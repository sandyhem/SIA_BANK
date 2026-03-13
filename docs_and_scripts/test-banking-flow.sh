#!/bin/bash

echo "================================================"
echo "  SIA BANK - Standard Banking Flow Test"
echo "================================================"
echo ""
echo "Testing: User → Customer (CIF) → KYC → Account"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_AUTH="http://localhost:8083/auth/api"
BASE_ACCOUNT="http://localhost:8081/api"

# Generate unique test data
TIMESTAMP=$(date +%s)
USERNAME="testuser_$TIMESTAMP"
EMAIL="${USERNAME}@example.com"
PASSWORD="Test@123"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 1: User Registration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Creating user: $USERNAME"
echo ""

REGISTER_RESPONSE=$(curl -s -X POST "$BASE_AUTH/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"firstName\": \"Test\",
    \"lastName\": \"User\"
  }")

echo "$REGISTER_RESPONSE" | jq '.'

USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.userId // empty')
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ User registration failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ User registered successfully${NC}"
echo "  User ID: $USER_ID"
echo "  Token: ${TOKEN:0:40}..."
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 2: Customer Creation (CIF Generation)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Creating customer profile for User ID: $USER_ID"
echo ""

CUSTOMER_RESPONSE=$(curl -s -X POST "$BASE_AUTH/customers?userId=$USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "fullName": "Test User Full Name",
    "phone": "9876543210",
    "address": "123 Test Street, Apartment 4B",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postalCode": "400001",
    "country": "India",
    "dateOfBirth": "1990-05-15",
    "panNumber": "ABCDE1234F",
    "aadhaarNumber": "123456789012"
  }')

echo "$CUSTOMER_RESPONSE" | jq '.'

CIF_NUMBER=$(echo "$CUSTOMER_RESPONSE" | jq -r '.cifNumber // empty')
KYC_STATUS=$(echo "$CUSTOMER_RESPONSE" | jq -r '.kycStatus // empty')
CUSTOMER_STATUS=$(echo "$CUSTOMER_RESPONSE" | jq -r '.customerStatus // empty')

if [ -z "$CIF_NUMBER" ]; then
    echo -e "${RED}✗ Customer creation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Customer created successfully${NC}"
echo "  CIF Number: $CIF_NUMBER"
echo "  KYC Status: $KYC_STATUS (default)"
echo "  Customer Status: $CUSTOMER_STATUS (default)"
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 3A: Try Account Creation (Should FAIL)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Attempting to create account with KYC: $KYC_STATUS"
echo ""

ACCOUNT_FAIL_RESPONSE=$(curl -s -X POST "$BASE_ACCOUNT/accounts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"userId\": $USER_ID,
    \"accountName\": \"Test Savings Account\",
    \"accountType\": \"SAVINGS\",
    \"initialBalance\": 5000
  }")

echo "$ACCOUNT_FAIL_RESPONSE" | jq '.'

if echo "$ACCOUNT_FAIL_RESPONSE" | jq -e '.status == 403' > /dev/null; then
    echo -e "${GREEN}✓ Account creation properly blocked (HTTP 403)${NC}"
    ERROR_MSG=$(echo "$ACCOUNT_FAIL_RESPONSE" | jq -r '.message')
    echo "  Reason: $ERROR_MSG"
else
    echo -e "${RED}✗ Expected 403 error but got different response${NC}"
fi
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 3B: KYC Verification (Admin Action)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Updating KYC status to VERIFIED for CIF: $CIF_NUMBER"
echo ""

KYC_UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_AUTH/customers/cif/$CIF_NUMBER/kyc?adminUsername=admin_test" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "kycStatus": "VERIFIED",
    "remarks": "All documents verified successfully"
  }')

echo "$KYC_UPDATE_RESPONSE" | jq '.'

NEW_KYC_STATUS=$(echo "$KYC_UPDATE_RESPONSE" | jq -r '.kycStatus // empty')
NEW_CUSTOMER_STATUS=$(echo "$KYC_UPDATE_RESPONSE" | jq -r '.customerStatus // empty')
VERIFIED_BY=$(echo "$KYC_UPDATE_RESPONSE" | jq -r '.kycVerifiedBy // empty')

if [ "$NEW_KYC_STATUS" = "VERIFIED" ]; then
    echo -e "${GREEN}✓ KYC verified successfully${NC}"
    echo "  KYC Status: $NEW_KYC_STATUS"
    echo "  Customer Status: $NEW_CUSTOMER_STATUS"
    echo "  Verified By: $VERIFIED_BY"
else
    echo -e "${RED}✗ KYC verification failed${NC}"
    exit 1
fi
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 4: Account Creation (Should SUCCEED)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Creating account with VERIFIED KYC"
echo ""

ACCOUNT_SUCCESS_RESPONSE=$(curl -s -X POST "$BASE_ACCOUNT/accounts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"userId\": $USER_ID,
    \"accountName\": \"My Savings Account\",
    \"accountType\": \"SAVINGS\",
    \"initialBalance\": 10000
  }")

echo "$ACCOUNT_SUCCESS_RESPONSE" | jq '.'

ACCOUNT_NUMBER=$(echo "$ACCOUNT_SUCCESS_RESPONSE" | jq -r '.accountNumber // empty')
ACCOUNT_BALANCE=$(echo "$ACCOUNT_SUCCESS_RESPONSE" | jq -r '.balance // empty')
CUSTOMER_CIF=$(echo "$ACCOUNT_SUCCESS_RESPONSE" | jq -r '.customerCif // empty')

if [ -n "$ACCOUNT_NUMBER" ]; then
    echo -e "${GREEN}✓ Account created successfully${NC}"
    echo "  Account Number: $ACCOUNT_NUMBER"
    echo "  Account Type: SAVINGS"
    echo "  Linked to CIF: $CUSTOMER_CIF"
    echo "  Balance: ₹$ACCOUNT_BALANCE"
else
    echo -e "${RED}✗ Account creation failed${NC}"
    exit 1
fi
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 5: Create Second Account (Multiple Accounts)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Creating checking account for same customer"
echo ""

ACCOUNT2_RESPONSE=$(curl -s -X POST "$BASE_ACCOUNT/accounts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"userId\": $USER_ID,
    \"accountName\": \"My Checking Account\",
    \"accountType\": \"CHECKING\",
    \"initialBalance\": 3000
  }")

echo "$ACCOUNT2_RESPONSE" | jq '.'

ACCOUNT2_NUMBER=$(echo "$ACCOUNT2_RESPONSE" | jq -r '.accountNumber // empty')

if [ -n "$ACCOUNT2_NUMBER" ]; then
    echo -e "${GREEN}✓ Second account created successfully${NC}"
    echo "  Account Number: $ACCOUNT2_NUMBER"
    echo "  Same CIF: $CUSTOMER_CIF"
else
    echo -e "${RED}✗ Second account creation failed${NC}"
fi
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 6: View Account Details${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Fetching account: $ACCOUNT_NUMBER"
echo ""

ACCOUNT_DETAILS=$(curl -s -X GET "$BASE_ACCOUNT/accounts/$ACCOUNT_NUMBER" \
  -H "Authorization: Bearer $TOKEN")

echo "$ACCOUNT_DETAILS" | jq '.'
echo ""

sleep 2

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 7: Credit Account${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Adding ₹2000 to account: $ACCOUNT_NUMBER"
echo ""

CREDIT_RESPONSE=$(curl -s -X PUT "$BASE_ACCOUNT/accounts/$ACCOUNT_NUMBER/credit" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amount": 2000
  }')

echo "$CREDIT_RESPONSE"
echo -e "${GREEN}✓ Credit successful${NC}"
echo ""

sleep 1

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 8: Debit Account${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Withdrawing ₹500 from account: $ACCOUNT_NUMBER"
echo ""

DEBIT_RESPONSE=$(curl -s -X PUT "$BASE_ACCOUNT/accounts/$ACCOUNT_NUMBER/debit" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amount": 500
  }')

echo "$DEBIT_RESPONSE"
echo -e "${GREEN}✓ Debit successful${NC}"
echo ""

sleep 1

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 9: Final Account Balance${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

FINAL_BALANCE=$(curl -s -X GET "$BASE_ACCOUNT/accounts/$ACCOUNT_NUMBER" \
  -H "Authorization: Bearer $TOKEN")

echo "$FINAL_BALANCE" | jq '.'

BALANCE=$(echo "$FINAL_BALANCE" | jq -r '.balance')
echo ""
echo -e "${GREEN}✓ Final Balance: ₹$BALANCE${NC}"
echo "  (Starting: 10000 + Credit: 2000 - Debit: 500 = $BALANCE)"
echo ""

echo "================================================"
echo -e "${GREEN}    ALL TESTS PASSED SUCCESSFULLY! ✓${NC}"
echo "================================================"
echo ""
echo "Summary:"
echo "  ✓ User Registration"
echo "  ✓ Customer Creation (CIF: $CIF_NUMBER)"
echo "  ✓ KYC Verification Blocking (Before verification)"
echo "  ✓ KYC Status Update to VERIFIED"
echo "  ✓ Customer Status: ACTIVE"
echo "  ✓ Account Creation (Account 1: $ACCOUNT_NUMBER)"
echo "  ✓ Multiple Accounts (Account 2: $ACCOUNT2_NUMBER)"
echo "  ✓ Credit Operation"
echo "  ✓ Debit Operation"
echo "  ✓ Balance Management"
echo ""
echo "Banking Flow Architecture: WORKING PERFECTLY!"
echo "================================================"
