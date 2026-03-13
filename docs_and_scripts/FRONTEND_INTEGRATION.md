# Frontend Integration Guide - Updated Backend API

## Overview
The backend has been updated to match the frontend (bankProject) data structure requirements. All user and account attributes now align with what the frontend expects.

## Updated User Model

### Registration Endpoint
**POST** `http://localhost:8083/auth/api/auth/register`

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "secure123",
  "email": "john.doe@email.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1 (555) 987-6543"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "type": "Bearer",
  "username": "johndoe",
  "email": "john.doe@email.com",
  "name": "John Doe",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1 (555) 987-6543",
  "customerId": "QB2026-5153",
  "kycStatus": "pending",
  "role": "USER"
}
```

### Login Endpoint
**POST** `http://localhost:8083/auth/api/auth/login`

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "secure123"
}
```

**Response:** (Same as registration response with all user details)

## User Fields Mapping

| Frontend Field | Backend Field | Description |
|---------------|---------------|-------------|
| `name` | `firstName + lastName` | Full name (computed) |
| `customerId` | `customerId` | Auto-generated (QB{YEAR}-{####}) |
| `email` | `email` | User email |
| `phone` | `phone` | Phone number |
| `memberSince` | `createdAt.year` | Derived from creation date |
| `kycStatus` | `kycStatus` | Default: "pending" |

## Updated Account Model

### Create Account Endpoint
**POST** `http://localhost:8081/api/accounts`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "customerId": 1,
  "initialBalance": 5000.00,
  "accountName": "Everyday Checking",
  "accountType": "Checking"
}
```

**Response:**
```json
{
  "accountNumber": "ACC8F5D0BD3",
  "accountName": "Everyday Checking",
  "accountType": "Checking",
  "customerId": 1,
  "balance": 5000.00,
  "status": "ACTIVE",
  "createdAt": "2026-02-14T12:17:32.999722541",
  "updatedAt": "2026-02-14T12:17:32.999726805"
}
```

### Get All Accounts
**GET** `http://localhost:8081/api/accounts`

**Response:** Array of account objects with all fields

## Account Fields Mapping

| Frontend Field | Backend Field | Description |
|---------------|---------------|-------------|
| `id` | `accountNumber` | Unique account identifier |
| `name` | `accountName` | Account nickname |
| `number` | `accountNumber` | Can be masked in frontend |
| `type` | `accountType` | Checking, Savings, Fixed, etc. |
| `balance` | `balance` | Current balance |
| `status` | `status` | ACTIVE, INACTIVE, etc. |

## New Features

### 1. Enhanced User Profile
- ✅ Full name support (firstName + lastName)
- ✅ Phone number field
- ✅ Auto-generated customer ID
- ✅ KYC status tracking
- ✅ Member since (from createdAt)

### 2. Detailed Account Information
- ✅ Account name/nickname
- ✅ Account type classification
- ✅ All existing account features preserved

### 3. Backward Compatibility
- ✅ Existing username-based authentication still works
- ✅ All previous API endpoints functional
- ✅ Additional fields are optional in some contexts

## Frontend Environment Configuration

Update your frontend `.env` file:

```env
VITE_API_BASE_URL=http://localhost:8083/auth
VITE_ACCOUNT_API_URL=http://localhost:8081
VITE_TRANSACTION_API_URL=http://localhost:8082
```

## Sample Frontend Integration

### User Registration
```javascript
const registerUser = async (userData) => {
  const response = await fetch('http://localhost:8083/auth/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: userData.username,
      password: userData.password,
      email: userData.email,
      firstName: userData.firstName,
      lastName: userData.lastName,
      phone: userData.phone
    })
  });
  
  const data = await response.json();
  // data.name = "John Doe"
  // data.customerId = "QB2026-5153"
  // data.kycStatus = "pending"
  
  localStorage.setItem('authToken', data.token);
  localStorage.setItem('userProfile', JSON.stringify(data));
  
  return data;
};
```

### Create Account
```javascript
const createAccount = async (accountData) => {
  const token = localStorage.getItem('authToken');
  
  const response = await fetch('http://localhost:8081/api/accounts', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      customerId: 1,
      initialBalance: accountData.initialBalance,
      accountName: accountData.name,      // e.g., "Everyday Checking"
      accountType: accountData.type       // e.g., "Checking", "Savings"
    })
  });
  
  return await response.json();
};
```

## Testing the Integration

### Test User Registration
```bash
curl -X POST http://localhost:8083/auth/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123",
    "email": "test@email.com",
    "firstName": "Test",
    "lastName": "User",
    "phone": "+1 (555) 123-4567"
  }'
```

### Test Account Creation
```bash
# Get token from login/register first
TOKEN="your_token_here"

curl -X POST http://localhost:8081/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "initialBalance": 10000.00,
    "accountName": "Primary Checking",
    "accountType": "Checking"
  }'
```

## Database Schema Updates

### Users Table (auth_db)
```sql
ALTER TABLE users 
ADD COLUMN first_name VARCHAR(100) NOT NULL,
ADD COLUMN last_name VARCHAR(100) NOT NULL,
ADD COLUMN phone VARCHAR(20),
ADD COLUMN customer_id VARCHAR(50) UNIQUE,
ADD COLUMN kyc_status VARCHAR(20) DEFAULT 'pending';
```

### Accounts Table (account_db)
```sql
ALTER TABLE accounts 
ADD COLUMN account_name VARCHAR(100),
ADD COLUMN account_type VARCHAR(50);
```

## Notes

1. **Auto-generated Customer ID**: Format is `QB{YEAR}-{RANDOM_4_DIGITS}`
   - Example: `QB2026-5153`
   
2. **Name Computation**: The `name` field is computed as `firstName + " " + lastName`

3. **KYC Status**: Defaults to "pending", can be updated to "verified" or other statuses

4. **Account Types**: Common values: "Checking", "Savings", "Fixed", "Investment"

5. **Phone Format**: No validation enforced, frontend should format as needed

## Next Steps

1. Update frontend API service files to use new field names
2. Update user profile components to display new fields
3. Update account creation forms to include name and type
4. Implement KYC status display in user profile
5. Show member since year in user dashboard

---

**Date Updated:** February 14, 2026
**Backend Version:** 1.0.0
**Status:** ✅ Ready for Integration
