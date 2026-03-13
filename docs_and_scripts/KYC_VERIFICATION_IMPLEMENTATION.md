# KYC Verification Workflow Implementation

## Overview
This document describes the KYC (Know Your Customer) verification workflow implemented in the SIA Banking Application to ensure compliance with banking regulations and prevent anonymous account creation.

## Implementation Date
2024-12-19

## Problem Statement
The original implementation allowed users to create bank accounts immediately after registration, which is unrealistic and non-compliant with banking regulations. Real-world banking applications require:
- Identity verification (KYC) before account creation
- Document submission and validation
- Administrative approval process
- Compliance with regulatory requirements

## Solution Architecture

### 1. KYC Status Management

#### User Entity Enhancement
The `users` table in the Auth Service database now includes:
```sql
kyc_status VARCHAR(20) DEFAULT 'PENDING'
```

Possible KYC statuses:
- **PENDING**: User registered but not yet verified (default)
- **VERIFIED**: KYC documents approved, can create accounts
- **REJECTED**: KYC documents rejected, cannot create accounts

#### Customer ID
- Format: `QB<YEAR>-<4_RANDOM_DIGITS>`
- Example: `QB2024-7823`
- Generated during registration
- Links user identity to accounts

### 2. Backend Implementation

#### Auth Service Changes

**New Endpoint**
```
GET /auth/api/auth/user/{userId}/kyc-status
```
Returns user's KYC status, username, and customer ID.

**New DTO**
- `UserKycDTO.java`: Data transfer object containing KYC status information
  - userId (Long)
  - username (String)
  - kycStatus (String)
  - customerId (String)

**Service Method**
- `AuthServiceImpl.getUserKycStatus(Long userId)`: Retrieves user's KYC information

#### Account Service Changes

**New Exception**
- `KycNotVerifiedException.java`: Thrown when unverified users attempt account creation

**New Feign Client**
- `AuthServiceClient.java`: Inter-service communication to validate KYC status
  - URL: `http://localhost:8083`
  - Endpoint: `/auth/api/auth/user/{userId}/kyc-status`

**Enhanced Account Creation**
Modified `AccountServiceImpl.createAccount()` to:
1. Call Auth Service to check user's KYC status
2. Verify status is "VERIFIED"
3. Throw `KycNotVerifiedException` if not verified
4. Continue with account creation only if verified

**Exception Handling**
- Global exception handler intercepts `KycNotVerifiedException`
- Returns HTTP 403 Forbidden with clear error message
- Error response includes timestamp, status, error type, and user-friendly message

### 3. Workflow Sequence

```
User Registration
    ↓
KYC Status = PENDING
    ↓
User attempts to create account ←─┐
    ↓                              │
Account Service → Auth Service     │
    ↓                              │
Check KYC Status                   │
    ↓                              │
Status = PENDING? ─────────────────┘
    ↓ (Reject with error)
    
Status = VERIFIED?
    ↓
Create Account
    ↓
Account Created Successfully
```

### 4. Error Messages

**KYC Not Verified**
```
Account creation requires KYC verification. 
Please complete your KYC verification before creating an account.
```

**Service Communication Error**
```
Unable to verify KYC status. 
Please ensure your profile is complete and try again.
```

### 5. Security Improvements

**Authentication Flow**
- JWT token forwarded from Account Service to Auth Service via Feign interceptor
- Customer ID validation ensures users can only create accounts for themselves
- KYC status cannot be bypassed or manipulated client-side

**Authorization**
- Account creation endpoint validates user's KYC status before proceeding
- 403 Forbidden response prevents further attempts until verification

### 6. Files Modified

#### Account Service
```
/account-service/src/main/java/com/banking/account/
├── exception/
│   ├── KycNotVerifiedException.java (NEW)
│   └── GlobalExceptionHandler.java (UPDATED)
├── client/
│   └── AuthServiceClient.java (NEW)
├── dto/
│   └── UserKycDTO.java (NEW)
└── service/
    └── AccountServiceImpl.java (UPDATED)
```

#### Auth Service
```
/auth/src/main/java/com/banking/auth/
├── controller/
│   └── AuthController.java (UPDATED)
├── dto/
│   └── UserKycDTO.java (NEW)
└── service/
    ├── AuthService.java (UPDATED)
    └── AuthServiceImpl.java (UPDATED)
```

## Future Enhancements

### Phase 2: KYC Document Upload
- Add document upload endpoint (ID proof, address proof, selfie)
- File storage integration (local or cloud storage)
- Document validation service
- OCR integration for automatic data extraction

### Phase 3: Admin Approval Panel
- Admin dashboard for KYC review
- View uploaded documents
- Approve/Reject with reason
- Email notifications to users
- Audit trail for compliance

### Phase 4: Enhanced KYC Information
- Personal details form (DOB, address, nationality, occupation)
- Income verification
- Source of funds declaration
- PEP (Politically Exposed Person) screening
- Sanctions list checking

### Phase 5: Account Creation Restrictions
- Minimum initial deposit requirement ($25)
- Maximum accounts per user limit (5 accounts)
- Account type restrictions based on KYC tier
- Terms & conditions acceptance

## Testing Guide

### Test Case 1: Unverified User Creates Account
**Setup**: User registered with KYC status = PENDING

**Steps**:
1. Login as unverified user
2. Click "Create Account" button
3. Fill account creation form
4. Submit

**Expected Result**: 
- Error message displayed
- HTTP 403 Forbidden
- Message: "Account creation requires KYC verification..."

### Test Case 2: Verified User Creates Account
**Setup**: User registered with KYC status = VERIFIED (manually update DB)

**Steps**:
1. Login as verified user
2. Click "Create Account" button
3. Fill account creation form
4. Submit

**Expected Result**:
- Account created successfully
- Success toast notification
- New account appears in account list

### Manual Database Update for Testing
```sql
-- Update user's KYC status to VERIFIED
UPDATE users 
SET kyc_status = 'VERIFIED' 
WHERE username = 'testuser';

-- Check user's KYC status
SELECT id, username, customer_id, kyc_status 
FROM users 
WHERE username = 'testuser';
```

## Database Schema

### Users Table (Auth Service)
```sql
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    customer_id VARCHAR(20) UNIQUE,
    kyc_status VARCHAR(20) DEFAULT 'PENDING',
    role VARCHAR(20) DEFAULT 'CUSTOMER',
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## API Documentation

### Get User KYC Status
**Endpoint**: `GET /auth/api/auth/user/{userId}/kyc-status`

**Authorization**: Required (JWT Bearer token)

**Path Parameters**:
- `userId` (Long): User's unique identifier

**Response** (200 OK):
```json
{
    "userId": 1,
    "username": "john.doe",
    "kycStatus": "VERIFIED",
    "customerId": "QB2024-7823"
}
```

**Error Responses**:
- 404 Not Found: User not found
- 401 Unauthorized: Invalid or missing JWT token

## Deployment Checklist

- [x] Create KycNotVerifiedException class
- [x] Create AuthServiceClient Feign client
- [x] Create UserKycDTO in both services
- [x] Update AccountServiceImpl with KYC validation
- [x] Add KYC status endpoint in Auth Service
- [x] Update GlobalExceptionHandler for KYC errors
- [ ] Rebuild account-service: `mvn clean package`
- [ ] Rebuild auth-service: `mvn clean package`
- [ ] Restart account-service: `java -jar target/account-service-1.0.0.jar`
- [ ] Restart auth-service: `java -jar target/auth-1.0.0.jar`
- [ ] Verify database schema has kyc_status column
- [ ] Test unverified user account creation (should fail)
- [ ] Test verified user account creation (should succeed)

## Compliance Notes

This implementation provides the foundation for regulatory compliance:

**Regulatory Requirements**:
- **KYC/AML Compliance**: Prevents anonymous account opening
- **Customer Due Diligence (CDD)**: Ensures identity verification before service provision
- **Risk-Based Approach**: Different KYC tiers can be implemented for different account types

**Best Practices**:
- Clear error messages guide users through the process
- Audit trail capability (can be extended)
- Secure inter-service communication
- Separation of concerns (Auth vs Account services)

## Conclusion

The KYC verification workflow successfully implements a realistic banking compliance feature that:
- Prevents account creation without identity verification
- Provides clear user feedback
- Maintains security through inter-service validation
- Follows microservices best practices
- Sets foundation for advanced KYC features

This implementation transforms the application from a simple demo to a compliance-ready banking system architecture.
