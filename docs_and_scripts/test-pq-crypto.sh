#!/bin/bash

# Test Post-Quantum Cryptography Integration
# ===========================================

BASE_URL="http://localhost:8083/auth"

echo "==================================="
echo "PQ Crypto Integration Test Script"
echo "==================================="
echo

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Test 1: Health Check - PQ Crypto System
echo -e "${BLUE}Test 1: PQ Crypto Health Check${NC}"
RESPONSE=$(curl -s ${BASE_URL}/api/crypto/health)
echo "Response: $RESPONSE"

if echo $RESPONSE | grep -q "UP"; then
    print_result 0 "PQ Crypto system is UP"
else
    print_result 1 "PQ Crypto system is DOWN"
fi
echo

# Test 2: Generate ML-DSA-65 Key Pair
echo -e "${BLUE}Test 2: Generate ML-DSA-65 Key Pair${NC}"
KEY_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/crypto/generate-keys)
echo "Generated keys (truncated):"
echo "$KEY_RESPONSE" | head -c 200
echo "..."

PUBLIC_KEY=$(echo $KEY_RESPONSE | jq -r '.publicKey')
PRIVATE_KEY=$(echo $KEY_RESPONSE | jq -r '.privateKey')

if [ ! -z "$PUBLIC_KEY" ] && [ "$PUBLIC_KEY" != "null" ]; then
    print_result 0 "ML-DSA-65 key pair generated successfully"
    echo "  Public key length: ${#PUBLIC_KEY} characters"
    echo "  Private key length: ${#PRIVATE_KEY} characters"
else
    print_result 1 "Failed to generate ML-DSA-65 key pair"
fi
echo

# Test 3: Get Server's ML-KEM-768 Public Key
echo -e "${BLUE}Test 3: Get Server ML-KEM-768 Public Key${NC}"
KEM_RESPONSE=$(curl -s ${BASE_URL}/api/crypto/server-kem-public-key)
echo "KEM Key (truncated):"
echo "$KEM_RESPONSE" | head -c 200
echo "..."

SERVER_KEM_KEY=$(echo $KEM_RESPONSE | jq -r '.publicKey')

if [ ! -z "$SERVER_KEM_KEY" ] && [ "$SERVER_KEM_KEY" != "null" ]; then
    print_result 0 "Retrieved ML-KEM-768 public key"
    echo "  Key length: ${#SERVER_KEM_KEY} characters"
else
    print_result 1 "Failed to retrieve ML-KEM-768 public key"
fi
echo

# Test 4: Sign Data with ML-DSA-65
echo -e "${BLUE}Test 4: Sign Data with ML-DSA-65${NC}"

if [ ! -z "$PRIVATE_KEY" ] && [ "$PRIVATE_KEY" != "null" ]; then
    SIGN_REQUEST=$(cat <<EOF
{
  "privateKey": "$PRIVATE_KEY",
  "sessionId": "test-session-123",
  "serverNonce": "dGVzdC1ub25jZQ=="
}
EOF
)
    
    SIGN_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/crypto/sign \
        -H "Content-Type: application/json" \
        -d "$SIGN_REQUEST")
    
    SIGNATURE=$(echo $SIGN_RESPONSE | jq -r '.signature')
    
    if [ ! -z "$SIGNATURE" ] && [ "$SIGNATURE" != "null" ]; then
        print_result 0 "Data signed with ML-DSA-65"
        echo "  Signature length: ${#SIGNATURE} characters"
    else
        print_result 1 "Failed to sign data"
        echo "  Response: $SIGN_RESPONSE"
    fi
else
    echo "  Skipping (no private key from previous test)"
fi
echo

# Test 5: Encapsulate with ML-KEM-768
echo -e "${BLUE}Test 5: Encapsulate with ML-KEM-768${NC}"

if [ ! -z "$SERVER_KEM_KEY" ] && [ "$SERVER_KEM_KEY" != "null" ]; then
    ENCAP_REQUEST=$(cat <<EOF
{
  "serverPublicKey": "$SERVER_KEM_KEY"
}
EOF
)
    
    ENCAP_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/crypto/encapsulate \
        -H "Content-Type: application/json" \
        -d "$ENCAP_REQUEST")
    
    CIPHERTEXT=$(echo $ENCAP_RESPONSE | jq -r '.ciphertext')
    
    if [ ! -z "$CIPHERTEXT" ] && [ "$CIPHERTEXT" != "null" ]; then
        print_result 0 "Key encapsulated with ML-KEM-768"
        echo "  Ciphertext length: ${#CIPHERTEXT} characters"
    else
        print_result 1 "Failed to encapsulate"
        echo "  Response: $ENCAP_RESPONSE"
    fi
else
    echo "  Skipping (no server KEM key from previous test)"
fi
echo

# Test 6: Register User with PQ-JWT
echo -e "${BLUE}Test 6: Register User with PQ-signed JWT${NC}"
REGISTER_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{
        "username": "pqtest",
        "email": "pqtest@example.com",
        "password": "Test123!",
        "role": "USER"
    }')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')

if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    print_result 0 "User registered with PQ-signed JWT"
    echo "  JWT length: ${#TOKEN} characters"
    echo "  JWT (first 50 chars): ${TOKEN:0:50}..."
    
    # Check if it's a PQ token (should be larger than standard JWT)
    if [ ${#TOKEN} -gt 500 ]; then
        echo -e "  ${GREEN}Token appears to be PQ-signed (${#TOKEN} chars > 500)${NC}"
    else
        echo -e "  ${RED}Token might be standard JWT (${#TOKEN} chars < 500)${NC}"
        echo "  Note: Set jwt.use-post-quantum=true in application.yml"
    fi
else
    # User might already exist, try login instead
    LOGIN_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{
            "username": "pqtest",
            "password": "Test123!"
        }')
    
    TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
    
    if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        print_result 0 "User logged in with PQ-signed JWT"
        echo "  JWT length: ${#TOKEN} characters"
    else
        print_result 1 "Failed to get PQ-signed JWT"
    fi
fi
echo

# Test 7: Validate PQ-JWT
echo -e "${BLUE}Test 7: Validate PQ-signed JWT${NC}"

if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    VALIDATE_RESPONSE=$(curl -s ${BASE_URL}/api/auth/validate \
        -H "Authorization: Bearer $TOKEN")
    
    IS_VALID=$(echo $VALIDATE_RESPONSE | jq -r '.valid')
    
    if [ "$IS_VALID" = "true" ]; then
        print_result 0 "PQ-signed JWT validated successfully"
    else
        print_result 1 "PQ-signed JWT validation failed"
        echo "  Response: $VALIDATE_RESPONSE"
    fi
else
    echo "  Skipping (no token from previous test)"
fi
echo

echo "==================================="
echo "Test Suite Complete"
echo "==================================="
echo
echo "Note: Ensure the auth service is running with:"
echo "  cd /home/inba/SIA_BANK/auth"
echo "  mvn spring-boot:run"
echo
echo "To enable PQ-signed JWTs, set in application.yml:"
echo "  jwt.use-post-quantum: true"
