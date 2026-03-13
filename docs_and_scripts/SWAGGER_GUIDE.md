# 🚀 Swagger API Testing Guide

## 📚 Swagger UI URLs

All three microservices now have Swagger UI enabled for easy API testing:

### 1️⃣ Auth Service (Port 8083)
- **Swagger UI**: http://localhost:8083/auth/swagger-ui/index.html
- **API Docs**: http://localhost:8083/auth/v3/api-docs
- **Endpoints**: Authentication, Customer Management (CIF), KYC

### 2️⃣ Account Service (Port 8081)
- **Swagger UI**: http://localhost:8081/swagger-ui/index.html
- **API Docs**: http://localhost:8081/v3/api-docs
- **Endpoints**: Account Management, Credit/Debit Operations

### 3️⃣ Transaction Service (Port 8082)
- **Swagger UI**: http://localhost:8082/swagger-ui/index.html
- **API Docs**: http://localhost:8082/v3/api-docs
- **Endpoints**: Money Transfer, Transaction History

---

## 🔐 Authentication Flow in Swagger

### Step 1: Register a New User
1. Open **Auth Service Swagger UI**
2. Expand `POST /api/auth/register`
3. Click "Try it out"
4. Use this JSON:
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "Password123!"
}
```
5. Click "Execute"
6. You should get a 201 Created response

### Step 2: Login to Get JWT Token
1. Expand `POST /api/auth/login`
2. Click "Try it out"
3. Use this JSON:
```json
{
  "username": "testuser",
  "password": "Password123!"
}
```
4. Click "Execute"
5. **Copy the JWT token** from the response

### Step 3: Authorize Swagger with JWT
1. Click the **"Authorize" button** (🔓 icon) at the top right of Swagger UI
2. Paste your JWT token (just the token, no "Bearer" prefix)
3. Click **"Authorize"**
4. Click **"Close"**
5. All subsequent API calls will include your JWT token automatically! 🎉

---

## 🏦 Complete Banking Flow Testing

### Flow 1: User → Customer (CIF) → KYC → Account

#### 1. Create Customer Profile (CIF)
```http
POST /api/customers?userId=1
```
```json
{
  "fullName": "John Doe",
  "phone": "+1234567890",
  "address": "123 Main Street",
  "city": "New York",
  "state": "NY",
  "postalCode": "10001",
  "country": "USA",
  "dateOfBirth": "1990-01-15",
  "panNumber": "ABCDE1234F",
  "aadhaarNumber": "123456789012"
}
```
**Response**: CIF Number (e.g., `CIF12345678`)

#### 2. View Customer Details
```http
GET /api/customers/cif/CIF12345678
```

#### 3. Update KYC Status (Admin)
```http
PUT /api/customers/cif/CIF12345678/kyc?adminUsername=admin
```
```json
{
  "kycStatus": "VERIFIED"
}
```

#### 4. Create Bank Account (Account Service)
```http
POST /api/accounts
```
```json
{
  "userId": 1,
  "customerId": 1,
  "accountType": "SAVINGS",
  "branchCode": "NYC001",
  "initialDeposit": 1000.00
}
```
**Response**: Account Number (e.g., `ACC12345678`)

### Flow 2: Account Operations

#### 1. Credit Money
```http
PUT /api/accounts/ACC12345678/credit
```
```json
{
  "senderAccount": "ACC12345678",
  "amount": 500.00,
  "description": "Deposit"
}
```

#### 2. Debit Money
```http
PUT /api/accounts/ACC12345678/debit
```
```json
{
  "senderAccount": "ACC12345678",
  "amount": 200.00,
  "description": "Withdrawal"
}
```

#### 3. View Account Details
```http
GET /api/accounts/ACC12345678
```

#### 4. View All Accounts
```http
GET /api/accounts
```

### Flow 3: Transactions

#### 1. Transfer Money (Transaction Service)
```http
POST /api/transactions/transfer
```
```json
{
  "fromAccountNumber": "ACC12345678",
  "toAccountNumber": "ACC87654321",
  "amount": 300.00,
  "description": "Payment for services"
}
```

#### 2. View Transaction History
```http
GET /api/transactions/account/ACC12345678
```

---

## 🎯 Quick Access Script

Run this command anytime to open all Swagger UIs:
```bash
bash /home/inba/SIA_BANK/open-swagger.sh
```

---

## 📋 Available Endpoints by Service

### Auth Service Endpoints
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT token
- `POST /api/customers` - Create customer profile (CIF)
- `GET /api/customers` - Get all customers
- `GET /api/customers/user/{userId}` - Get customer by user ID
- `GET /api/customers/cif/{cifNumber}` - Get customer by CIF
- `PUT /api/customers/cif/{cifNumber}/kyc` - Update KYC status
- `GET /api/customers/user/{userId}/active` - Check if customer is active

### Account Service Endpoints
- `POST /api/accounts` - Create new account
- `GET /api/accounts` - Get all accounts
- `GET /api/accounts/{accountNumber}` - Get account by number
- `GET /api/accounts/customer/{customerId}` - Get accounts by customer
- `PUT /api/accounts/{accountNumber}/credit` - Credit account
- `PUT /api/accounts/{accountNumber}/debit` - Debit account
- `GET /api/accounts/health` - Health check

### Transaction Service Endpoints
- `POST /api/transactions/transfer` - Transfer money between accounts
- `GET /api/transactions/account/{accountNumber}` - Get transaction history
- `GET /api/transactions/health` - Health check

---

## 💡 Pro Tips

1. **Authentication Required**: Most endpoints require JWT token. Always login first!

2. **Authorization Button**: Use the green "Authorize" button at the top to set your token globally

3. **Try It Out**: Click "Try it out" on any endpoint to test it interactively

4. **Response Codes**:
   - 200/201: Success
   - 400: Bad request (check your JSON)
   - 401: Unauthorized (need to login/authorize)
   - 404: Not found
   - 500: Server error (check service logs)

5. **Schema Examples**: Swagger shows example request/response schemas - use them as templates!

6. **Model Definitions**: Click on model names to see their full structure

7. **Multiple Services**: You can have all three Swagger UIs open in different tabs

---

## 🔧 Troubleshooting

### Cannot Access Swagger UI
```bash
# Check if services are running
pgrep -f spring-boot

# Restart services
bash /home/inba/SIA_BANK/start-services.sh
```

### 401 Unauthorized Error
- Make sure you've clicked "Authorize" and entered your JWT token
- Token might be expired - login again to get a new token

### 404 Not Found
- Check the service URL (auth service has `/auth` prefix)
- Verify the endpoint path is correct

---

## 📱 Test with Real UI
After testing in Swagger, try the complete flow in the web UI:
```bash
# Open test UI
xdg-open /home/inba/SIA_BANK/test-ui-complete.html
```

---

**Happy Testing! 🎉**

For any issues, check service logs:
- `/home/inba/SIA_BANK/auth/auth-service.log`
- `/home/inba/SIA_BANK/account-service/account-service.log`
- `/home/inba/SIA_BANK/transaction-service/transaction-service.log`
