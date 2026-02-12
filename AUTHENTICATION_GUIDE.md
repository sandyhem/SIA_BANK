# Authenticated Banking Microservices - Integration Guide

## Overview

The banking microservices system now implements **JWT-based authentication** across all services. Only authenticated users with valid JWT tokens can perform banking operations like sending money, checking balances, or managing accounts.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                  User / Client                      │
│                                                     │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ 1. Login Request
                   ▼
        ┌──────────────────────┐
        │   Auth Service       │
        │   Port: 8083         │
        │   /auth/api/auth/*   │
        └──────────┬───────────┘
                   │
                   │ 2. Returns JWT Token
                   ▼
        ┌──────────────────────┐
        │  User stores token   │
        └──────────┬───────────┘
                   │
                   │ 3. Requests with Bearer Token
                   │
        ┌──────────┴────────────┬──────────────────┐
        │                       │                  │
        ▼                       ▼                  ▼
┌───────────────┐      ┌────────────────┐  ┌──────────────┐
│ Account       │      │ Transaction    │  │ Other        │
│ Service       │      │ Service        │  │ Services     │
│ Port: 8081    │      │ Port: 8082     │  │ (Future)     │
│               │      │                │  │              │
│ JWT Validated │      │ JWT Validated  │  │ JWT Validated│
└───────────────┘      └────────────────┘  └──────────────┘
        │                       │                  │
        │                       │                  │
        └───────────────────────┴──────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   MySQL     │
                    │  Database   │
                    └─────────────┘
```

---

## Authentication Flow

### Step 1: User Registration (One-time)

**Endpoint:** `POST http://localhost:8083/auth/api/auth/register`

**Request:**
```json
{
  "username": "john_doe",
  "password": "secure123",
  "email": "john@banking.com",
  "role": "USER"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "type": "Bearer",
  "username": "john_doe",
  "email": "john@banking.com",
  "role": "USER"
}
```

### Step 2: User Login

**Endpoint:** `POST http://localhost:8083/auth/api/auth/login`

**Request:**
```json
{
  "username": "testuser",
  "password": "test123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0dXNlciIsImlhdCI6MTc3MDkxODMwNiwiZXhwIjoxNzcxMDA0NzA2fQ.FVRva1NFI18h2V2_suKlJK9xJIQA7rWBaG0lWKBq6nE",
  "type": "Bearer",
  "username": "testuser",
  "email": "testuser@banking.com",
  "role": "USER"
}
```

### Step 3: Use Token for Operations

All subsequent requests to account-service and transaction-service **MUST** include the JWT token in the Authorization header:

**Header:** `Authorization: Bearer <token>`

---

## Banking Operations (Authenticated)

### Check Account Balance

**Endpoint:** `GET http://localhost:8081/api/accounts/{accountNumber}`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
  "accountNumber": "ACC001",
  "customerId": 1,
  "balance": 5000.00,
  "status": "ACTIVE",
  "createdAt": "2026-01-31T13:42:46",
  "updatedAt": "2026-02-12T23:23:48"
}
```

### Deposit Money (Credit Account)

**Endpoint:** `PUT http://localhost:8081/api/accounts/{accountNumber}/credit`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

**Request:**
```json
{
  "senderAccount": "EXTERNAL",
  "amount": 1000.00,
  "description": "Salary deposit"
}
```

**Response:**
```
Credit successful
```

### Withdraw Money (Debit Account)

**Endpoint:** `PUT http://localhost:8081/api/accounts/{accountNumber}/debit`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

**Request:**
```json
{
  "senderAccount": "ACC001",
  "amount": 500.00,
  "description": "ATM withdrawal"
}
```

**Response:**
```
Debit successful
```

---

## Security Features

### 🔐 JWT Token Security

- **Algorithm:** HS256 (HMAC with SHA-256)
- **Token Expiration:** 24 hours
- **Refresh Token:** 7 days (configured, not yet implemented)
- **Secret Key:** Shared across all services (must be identical)

### 🛡️ Protection Mechanisms

1. **Authentication Required:** All account and transaction operations require valid JWT tokens
2. **Token Validation:** Tokens are validated on every request
3. **Expired Token Rejection:** Expired tokens are automatically rejected
4. **Invalid Token Rejection:** Malformed or invalid tokens return 401
5. **Password Encryption:** BCrypt hashing with salt
6. **Stateless Sessions:** No server-side session storage

---

## Error Responses

### 401 Unauthorized (No Token)

**Request:** No Authorization header

**Response:**
```json
{
  "timestamp": "2026-02-12T17:54:51.640+00:00",
  "status": 401,
  "error": "Unauthorized",
  "path": "/api/accounts/ACC001"
}
```

### 401 Unauthorized (Invalid Token)

**Request:** Invalid or expired token

**Response:**
```json
{
  "timestamp": "2026-02-12T17:54:52.401+00:00",
  "status": 401,
  "error": "Unauthorized",
  "path": "/api/accounts/ACC001"
}
```

### 400 Bad Request (Invalid Credentials)

**Request:** Wrong username/password

**Response:**
```json
{
  "status": 401,
  "message": "Invalid username or password",
  "timestamp": "2026-02-12T23:16:38.682171765"
}
```

### 409 Conflict (Duplicate User)

**Request:** Username or email already exists

**Response:**
```json
{
  "status": 409,
  "message": "Username already exists",
  "timestamp": "2026-02-12T23:16:43.31469522"
}
```

---

## Testing the System

### Quick Test Script

Save this as `test-auth-flow.sh`:

```bash
#!/bin/bash

# 1. Login and get token
TOKEN=$(curl -s -X POST http://localhost:8083/auth/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "test123"}' | jq -r '.token')

# 2. Check account with authentication
curl -X GET http://localhost:8081/api/accounts/ACC001 \
  -H "Authorization: Bearer $TOKEN"

# 3. Deposit money
curl -X PUT http://localhost:8081/api/accounts/ACC001/credit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "senderAccount": "EXTERNAL",
    "amount": 1000.00,
    "description": "Test deposit"
  }'
```

### Using cURL

```bash
# Login
curl -X POST http://localhost:8083/auth/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123"
  }'

# Save the token from response
TOKEN="eyJhbGciOiJIUzI1NiJ9..."

# Use token for operations
curl -X GET http://localhost:8081/api/accounts/ACC001 \
  -H "Authorization: Bearer $TOKEN"
```

### Using Postman

1. **Login:**
   - Method: POST
   - URL: `http://localhost:8083/auth/api/auth/login`
   - Body (JSON):
     ```json
     {
       "username": "testuser",
       "password": "test123"
     }
     ```
   - Copy the `token` from response

2. **Use Token:**
   - Method: GET
   - URL: `http://localhost:8081/api/accounts/ACC001`
   - Headers:
     - Key: `Authorization`
     - Value: `Bearer <paste-token-here>`

---

## Service Configuration

### Auth Service (Port 8083)

**application.yml:**
```yaml
jwt:
  secret: 5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437
  expiration: 86400000  # 24 hours
  refresh-expiration: 604800000  # 7 days
```

### Account Service (Port 8081)

**application.yml:**
```yaml
jwt:
  secret: 5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437
```

### Transaction Service (Port 8082)

**application.yml:**
```yaml
jwt:
  secret: 5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437
```

⚠️ **Important:** All services MUST use the same JWT secret for token validation to work.

---

## Developer Integration Guide

### For Frontend Developers

1. **Login Flow:**
   ```javascript
   // Login
   const response = await fetch('http://localhost:8083/auth/api/auth/login', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({
       username: 'testuser',
       password: 'test123'
     })
   });
   
   const data = await response.json();
   const token = data.token;
   
   // Store token (localStorage, sessionStorage, or state management)
   localStorage.setItem('authToken', token);
   ```

2. **Authenticated Requests:**
   ```javascript
   const token = localStorage.getItem('authToken');
   
   const response = await fetch('http://localhost:8081/api/accounts/ACC001', {
     headers: {
       'Authorization': `Bearer ${token}`
     }
   });
   
   const account = await response.json();
   ```

3. **Handle Token Expiration:**
   ```javascript
   if (response.status === 401) {
     // Token expired or invalid
     // Redirect to login
     localStorage.removeItem('authToken');
     window.location.href = '/login';
   }
   ```

### For Backend Developers

To add authentication to a new endpoint:

1. **Endpoint is automatically protected** if path matches pattern in SecurityConfig
2. **Get authenticated username** in controller:
   ```java
   @GetMapping("/profile")
   public ResponseEntity<?> getProfile(Authentication authentication) {
       String username = authentication.getName();
       // Use username to fetch user data
       return ResponseEntity.ok(userData);
   }
   ```

---

## Running All Services

```bash
# Terminal 1: Start Auth Service
cd auth
java -jar target/auth-service-1.0.0.jar

# Terminal 2: Start Account Service
cd account-service
java -jar target/account-service-1.0.0.jar

# Terminal 3: Start Transaction Service
cd transaction-service
java -jar target/transaction-service-1.0.0.jar
```

---

## Test Users

| Username | Password | Email | Role |
|----------|----------|-------|------|
| testuser | test123 | testuser@banking.com | USER |

You can register more users using the `/auth/api/auth/register` endpoint.

---

## Next Steps

### Implemented ✅
- [x] User registration and login
- [x] JWT token generation and validation
- [x] Account operations with authentication
- [x] Transaction operations with authentication
- [x] Token expiration handling
- [x] Security error responses

### Future Enhancements 🚀
- [ ] Token refresh mechanism
- [ ] Role-based access control (RBAC)
- [ ] Multi-factor authentication (MFA)
- [ ] OAuth2 integration
- [ ] API rate limiting
- [ ] Audit logging
- [ ] Password reset functionality
- [ ] Email verification

---

## Support & Documentation

- **Design Document:** [DESIGN_DOCUMENT.md](DESIGN_DOCUMENT.md)
- **Auth Test Results:** [AUTH_TEST_RESULTS.md](AUTH_TEST_RESULTS.md)
- **Run Guide:** [RUN_GUIDE.md](RUN_GUIDE.md)
- **Test Scripts:**
  - [test-authentication.sh](test-authentication.sh)
  - [demo-authenticated-transfer.sh](demo-authenticated-transfer.sh)

---

**Last Updated:** February 12, 2026  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
