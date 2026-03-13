# Standard Banking Service Flow Implementation

## Architecture Overview

This implementation follows **industry-standard banking practices** with proper separation between:
1. **User** (Authentication Layer)
2. **Customer** (CIF - Customer Information File)
3. **KYC** (Know Your Customer Verification)
4. **Account** (Banking Products)

---

## 📋 Complete Banking Flow

### 1️⃣ User Registration (Pre-Customer Stage)

**Purpose**: Create authentication profile  
**Status**: `REGISTERED` (not yet a banking customer)

**Endpoint**: `POST /auth/api/auth/register`

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass@123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response**:
```json
{
  "token": "eyJhbGc...",
  "username": "john_doe",
  "email": "john@example.com",
  "role": "USER"
}
```

**What Happens**:
- User account created in `users` table
- Can login to the system
- ❌ **Cannot open bank accounts yet**
- ❌ **Not a customer yet**

---

### 2️⃣ Customer Creation (CIF Generation)

**Purpose**: Create Customer Information File (legal banking identity)  
**Status**: `KYC_STATUS = PENDING`, `CUSTOMER_STATUS = INACTIVE`

**Endpoint**: `POST /auth/api/customers?userId={userId}`

```json
{
  "fullName": "John Michael Doe",
  "phone": "9876543210",
  "address": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "postalCode": "400001",
  "country": "India",
  "dateOfBirth": "1990-05-15",
  "panNumber": "ABCDE1234F",
  "aadhaarNumber": "123456789012"
}
```

**Response**:
```json
{
  "id": 1,
  "cifNumber": "CIF2026-4567",
  "userId": 1,
  "username": "john_doe",
  "fullName": "John Michael Doe",
  "kycStatus": "PENDING",
  "customerStatus": "INACTIVE"
}
```

**What Happens**:
- CIF number generated (e.g., `CIF2026-4567`)
- Customer record created in `customers` table
- Linked to user account via `user_id`
- ❌ **Still cannot open accounts** (KYC not verified)

---

### 3️⃣ KYC Process (Regulatory Gate)

**Purpose**: Verify customer identity (regulatory requirement)  
**Status Transitions**: `PENDING` → `UNDER_REVIEW` → `VERIFIED` / `REJECTED`

#### Digital KYC (Automated)
- Aadhaar eKYC
- PAN verification
- Video KYC

#### Admin KYC (Manual Review)

**Endpoint**: `PUT /auth/api/customers/cif/{cifNumber}/kyc`

```json
{
  "kycStatus": "VERIFIED",
  "verifiedBy": "admin_user",
  "remarks": "All documents verified successfully"
}
```

**Response**:
```json
{
  "cifNumber": "CIF2026-4567",
  "kycStatus": "VERIFIED",
  "customerStatus": "ACTIVE",
  "kycVerifiedAt": "2026-02-14 10:30:00",
  "kycVerifiedBy": "admin_user"
}
```

**What Happens**:
- KYC status updated to `VERIFIED`
- Customer status automatically becomes `ACTIVE`
- ✅ **Now eligible to open bank accounts**

**KYC States**:
- `PENDING` - Initial state, documents not submitted
- `UNDER_REVIEW` - Documents submitted, being reviewed
- `VERIFIED` - Approved, can open accounts
- `REJECTED` - KYC failed, cannot open accounts

---

### 4️⃣ Account Opening

**Purpose**: Create bank account products linked to customer  
**Prerequisite**: Customer must be `ACTIVE` (KYC `VERIFIED`)

**Endpoint**: `POST /api/accounts`

```json
{
  "userId": 1,
  "accountName": "John's Savings Account",
  "accountType": "SAVINGS",
  "initialBalance": 5000
}
```

**Response**:
```json
{
  "accountNumber": "ACC12345678",
  "accountName": "John's Savings Account",
  "accountType": "SAVINGS",
  "customerCif": "CIF2026-4567",
  "userId": 1,
  "balance": 5000,
  "status": "ACTIVE"
}
```

**What Happens**:
1. System checks if customer exists for user
2. Verifies customer status is `ACTIVE`
3. Verifies KYC status is `VERIFIED`
4. Generates unique account number
5. Links account to customer CIF
6. Account created with initial deposit

**Multiple Accounts**:
One customer can have:
- Multiple savings accounts
- Checking accounts
- Fixed deposits
- Loan accounts

All linked to the same CIF number.

---

## 🔄 State Diagram

```
User Registration
       ↓
   [REGISTERED]
       ↓
Customer Creation (CIF)
       ↓
   [KYC: PENDING]
   [STATUS: INACTIVE]
       ↓
KYC Submission
       ↓
   [KYC: UNDER_REVIEW]
   [STATUS: INACTIVE]
       ↓
Admin Review
       ↓
   [KYC: VERIFIED]  ←→  [KYC: REJECTED]
   [STATUS: ACTIVE]      [STATUS: INACTIVE]
       ↓
Account Opening ✅
       ↓
   Account 1, Account 2, Account 3...
   (All linked to CIF)
```

---

## 🗂️ Database Schema

### users (Authentication)
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  role VARCHAR(20),
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### customers (CIF - Customer Information File)
```sql
CREATE TABLE customers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  cif_number VARCHAR(20) UNIQUE NOT NULL,
  user_id BIGINT UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  address VARCHAR(255),
  city VARCHAR(50),
  state VARCHAR(50),
  postal_code VARCHAR(10),
  country VARCHAR(50),
  date_of_birth TIMESTAMP,
  pan_number VARCHAR(10),
  aadhaar_number VARCHAR(12),
  kyc_status VARCHAR(20) DEFAULT 'PENDING',
  customer_status VARCHAR(20) DEFAULT 'INACTIVE',
  kyc_verified_at TIMESTAMP,
  kyc_verified_by VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### accounts (Bank Accounts)
```sql
CREATE TABLE accounts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  account_number VARCHAR(20) UNIQUE NOT NULL,
  account_name VARCHAR(100),
  account_type VARCHAR(20),
  customer_cif VARCHAR(20) NOT NULL,
  user_id BIGINT NOT NULL,
  balance DECIMAL(15,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'ACTIVE',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_cif) REFERENCES customers(cif_number),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 🔐 Security & Validation

### Account Creation Checks
1. ✅ User must be authenticated (JWT token)
2. ✅ Customer profile must exist
3. ✅ KYC must be `VERIFIED`
4. ✅ Customer must be `ACTIVE`
5. ✅ Initial deposit must be positive

### Error Responses

#### Customer Not Found
```json
{
  "status": 403,
  "error": "Customer Not Active",
  "message": "Customer profile not found. Please create your customer profile (CIF) first before opening an account."
}
```

#### KYC Not Verified
```json
{
  "status": 403,
  "error": "Customer Not Active",
  "message": "Customer account is INACTIVE. Only ACTIVE customers can open bank accounts. Current KYC Status: PENDING. Please complete KYC verification."
}
```

---

## 📊 Relationships

```
User (1) ←→ (1) Customer ←→ (many) Accounts

│ User │
└─────┘
   │ 1:1
   │
│ Customer (CIF) │
└───────────────┘
   │ 1:many
   ├── Account (Savings)
   ├── Account (Checking)
   ├── Account (FD)
   └── Account (Loan)
```

---

## 🧪 Testing Flow

### Complete End-to-End Test

```bash
# 1. Register User
curl -X POST http://localhost:8083/auth/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test@123",
    "firstName": "Test",
    "lastName": "User"
  }'

# Response: Get userId and token

# 2. Create Customer (CIF)
curl -X POST "http://localhost:8083/auth/api/customers?userId=1" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "phone": "9876543210",
    "address": "123 Test St",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postalCode": "400001",
    "country": "India",
    "panNumber": "ABCDE1234F",
    "aadhaarNumber": "123456789012"
  }'

# Response: Get cifNumber (e.g., CIF2026-4567)

# 3. Update KYC to VERIFIED (Admin)
curl -X PUT http://localhost:8083/auth/api/customers/cif/CIF2026-4567/kyc \
  -H "Content-Type: application/json" \
  -d '{
    "kycStatus": "VERIFIED",
    "verifiedBy": "admin"
  }'

# 4. Create Account (Should succeed now)
curl -X POST http://localhost:8081/api/accounts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "accountName": "My Savings",
    "accountType": "SAVINGS",
    "initialBalance": 10000
  }'

# Response: Account created with account number
```

---

## 🎯 Benefits of This Architecture

### 1. **Separation of Concerns**
- Authentication (User) ≠ Banking Customer
- One user can theoretically manage multiple customer relationships

### 2. **Regulatory Compliance**
- Proper KYC gating before account opening
- Audit trail of KYC verification
- Clear customer status tracking

### 3. **Scalability**
- One customer → multiple accounts
- Easy to add new account types
- Support for joint accounts (future)

### 4. **Data Integrity**
- Foreign key constraints
- Status transitions enforced
- Cannot bypass KYC requirements

### 5. **Real-World Banking**
- Matches actual bank core systems
- CIF is industry standard
- Proper customer lifecycle management

---

## 🔧 API Endpoints Summary

### Auth Service (Port 8083)
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/api/auth/register` | POST | User registration |
| `/auth/api/auth/login` | POST | User login |
| `/auth/api/customers` | POST | Create customer (CIF) |
| `/auth/api/customers/user/{userId}` | GET | Get customer by user ID |
| `/auth/api/customers/cif/{cifNumber}` | GET | Get customer by CIF |
| `/auth/api/customers/cif/{cifNumber}/kyc` | PUT | Update KYC status |
| `/auth/api/customers/user/{userId}/active` | GET | Check if customer active |

### Account Service (Port 8081)
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/accounts` | POST | Create account (requires active customer) |
| `/api/accounts/{accountNumber}` | GET | Get account details |
| `/api/accounts/{accountNumber}/credit` | PUT | Credit account |
| `/api/accounts/{accountNumber}/debit` | PUT | Debit account |

---

## 📝 Notes

- **Customer ID vs User ID**: Always use User ID in API calls. The system will fetch the customer CIF internally.
- **CIF Number**: Auto-generated in format `CIF{YEAR}-{4-DIGIT-RANDOM}`
- **Account Number**: Auto-generated in format `ACC{8-CHAR-UUID}`
- **KYC Verification**: Can be done via admin endpoint or automated eKYC integration
- **Initial Deposit**: Required when opening account (configurable minimum)

---

## 🚀 Next Steps

1. **Frontend Integration**: Update UI to follow this flow
2. **Document Upload**: Add KYC document upload endpoints
3. **Admin Dashboard**: Create KYC review interface
4. **Notifications**: Email/SMS on KYC status changes
5. **Joint Accounts**: Support multiple customers per account
6. **Account Limits**: Min/max balance, transaction limits
7. **Product Variants**: Different savings account types
