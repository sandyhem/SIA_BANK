# KYC Verification Testing Guide

## Quick Start

### 1. Start All Services
```bash
cd /home/inba/SIA_BANK
./start-services.sh
```

This will start:
- Auth Service (8083)
- Account Service (8081)
- Transaction Service (8082)

Wait for all services to be ready (script will confirm).

### 2. Update Database Schema

The KYC verification requires the `users` table to have a `kyc_status` column. Verify it exists:

```sql
mysql -u root -p
USE auth_db;
DESCRIBE users;
```

You should see:
```
| kyc_status  | varchar(20) | YES  |     | PENDING |
```

If the column doesn't exist, run:
```sql
ALTER TABLE users ADD COLUMN kyc_status VARCHAR(20) DEFAULT 'PENDING';
```

### 3. Test Scenarios

#### Scenario A: Unverified User (KYC PENDING)

**Setup**:
1. Register a new user or check existing user KYC status:
```sql
SELECT id, username, email, kyc_status FROM users;
```

2. Ensure user has KYC status = PENDING (default for new users)

**Test Steps**:
1. Start frontend: `cd bankProject && npm run dev`
2. Login with the user
3. Click "Create Account" button
4. Fill in account details:
   - Account Name: "My Savings"
   - Account Type: "SAVINGS"
   - Initial Balance: 100
5. Click "Create Account"

**Expected Result**:
- ❌ Error message appears
- Message: "Account creation requires KYC verification. Please complete your KYC verification before creating an account."
- HTTP 403 Forbidden response
- No account is created

**Actual Backend Flow**:
```
Frontend → Account Service
             ↓
Account Service → AuthServiceClient.getUserKycStatus()
                    ↓
              Auth Service (GET /auth/api/auth/user/{userId}/kyc-status)
                    ↓
              Returns: { kyc_status: "PENDING" }
                    ↓
Account Service → Checks if kycStatus == "VERIFIED"
                    ↓
              Status is PENDING → throw KycNotVerifiedException
                    ↓
GlobalExceptionHandler → HTTP 403 + error message
                    ↓
Frontend receives error → displays intoast/modal
```

#### Scenario B: Verified User (KYC VERIFIED)

**Setup**:
1. Update user's KYC status to VERIFIED:
```sql
UPDATE users 
SET kyc_status = 'VERIFIED' 
WHERE username = 'testuser';  -- Replace with actual username

-- Verify update
SELECT id, username, kyc_status FROM users WHERE username = 'testuser';
```

**Test Steps**:
1. Refresh the frontend (or re-login if needed)
2. Click "Create Account" button
3. Fill in account details:
   - Account Name: "My Checking"
   - Account Type: "CHECKING"
   - Initial Balance: 500
4. Click "Create Account"

**Expected Result**:
- ✅ Success message appears
- Message: "Account created successfully"
- Account appears in account list
- Can select the account for transfers/transactions

**Actual Backend Flow**:
```
Frontend → Account Service
             ↓
Account Service → AuthServiceClient.getUserKycStatus()
                    ↓
              Auth Service (GET /auth/api/auth/user/{userId}/kyc-status)
                    ↓
              Returns: { kyc_status: "VERIFIED" }
                    ↓
Account Service → Checks if kycStatus == "VERIFIED"
                    ↓
              Status is VERIFIED → Continue account creation
                    ↓
              Generate account number (ACC + UUID)
                    ↓
              Set fields, save to database
                    ↓
              Return AccountDTO
                    ↓
Frontend receives success → displays toast + refreshes account list
```

#### Scenario C: Rejected KYC

**Setup**:
```sql
UPDATE users 
SET kyc_status = 'REJECTED' 
WHERE username = 'testuser';
```

**Test Steps**:
1. Try to create an account

**Expected Result**:
- ❌ Same error as PENDING status
- "Account creation requires KYC verification..."

## Verification Commands

### Check Service Health
```bash
# Auth Service
curl http://localhost:8083/auth/api/auth/health

# Account Service
curl http://localhost:8081/accounts/api/accounts/health

# Transaction Service
curl http://localhost:8082/transactions/api/transactions/health
```

### Test KYC Endpoint Directly
```bash
# Get JWT token first (replace credentials)
TOKEN=$(curl -s -X POST http://localhost:8083/auth/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test@123"}' | jq -r '.token')

# Get user ID (from login response or database)
USER_ID=1

# Check KYC status
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8083/auth/api/auth/user/$USER_ID/kyc-status | jq .
```

Expected response:
```json
{
  "userId": 1,
  "username": "testuser",
  "kycStatus": "VERIFIED",
  "customerId": "QB2024-7823"
}
```

### Verify Account Creation Blocked
```bash
# Try to create account for unverified user (should fail)
curl -X POST http://localhost:8081/accounts/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountName": "Test Account",
    "accountType": "SAVINGS",
    "customerId": 1,
    "initialBalance": 100
  }' | jq .
```

Expected response when KYC not verified (HTTP 403):
```json
{
  "timestamp": "2024-12-19T14:30:00.000+00:00",
  "status": 403,
  "error": "KYC Verification Required",
  "message": "Account creation requires KYC verification. Please complete your KYC verification before creating an account."
}
```

## Database Queries

### View All Users and KYC Status
```sql
SELECT 
    id,
    username,
    email,
    customer_id,
    kyc_status,
    created_at
FROM users
ORDER BY created_at DESC;
```

### Count Users by KYC Status
```sql
SELECT 
    kyc_status,
    COUNT(*) as count
FROM users
GROUP BY kyc_status;
```

### View User's Accounts
```sql
SELECT 
    u.id,
    u.username,
    u.kyc_status,
    a.account_number,
    a.account_name,
    a.account_type,
    a.balance,
    a.status
FROM users u
LEFT JOIN accounts a ON u.id = a.customer_id
WHERE u.username = 'testuser';
```

## Troubleshooting

### Service Won't Start
```bash
# Check if port is in use
lsof -i :8083
lsof -i :8081
lsof -i :8082

# Kill processes on ports
lsof -ti:8083 | xargs -r kill -9
lsof -ti:8081 | xargs -r kill -9
lsof -ti:8082 | xargs -r kill -9

# Check logs
tail -f /home/inba/SIA_BANK/auth/auth-service.log
tail -f /home/inba/SIA_BANK/account-service/account-service.log
```

### KYC Check Not Working
1. Verify auth-service is running and accessible
2. Check Feign client configuration in account-service application.yml:
   ```yaml
   auth:
     service:
       url: http://localhost:8083
   ```
3. Check logs for Feign errors
4. Verify JWT token is being forwarded via FeignClientInterceptor

### Database Schema Issues
```sql
-- Check if kyc_status column exists
SHOW COLUMNS FROM users LIKE 'kyc_status';

-- Add if missing
ALTER TABLE users ADD COLUMN kyc_status VARCHAR(20) DEFAULT 'PENDING';

-- Update existing users
UPDATE users SET kyc_status = 'PENDING' WHERE kyc_status IS NULL;
```

### Frontend Not Showing Error
1. Check browser console for errors
2. Verify CreateAccountModal error handling in catch block
3. Check network tab for API response (should be 403)
4. Verify Toast component is working

## Next Steps

When KYC verification is working:

1. **Add KYC Document Upload**
   - Create endpoint for document upload
   - Store documents in file system or cloud storage
   - Add document validation

2. **Create Admin Panel**
   - View pending KYC submissions
   - Approve/reject with reason
   - View uploaded documents

3. **Add Account Creation Restrictions**
   - Minimum deposit ($25)
   - Maximum accounts per user (5)
   - Terms & conditions

4. **Implement KYC Submission UI**
   - Personal details form
   - Document upload interface
   - Status tracking

## Files Modified in This Implementation

### Backend (Account Service)
- `AccountServiceImpl.java` - Added KYC verification in createAccount()
- `KycNotVerifiedException.java` - New exception for KYC failures
- `AuthServiceClient.java` - Feign client to call Auth Service
- `UserKycDTO.java` - DTO for KYC status response
- `GlobalExceptionHandler.java` - Added handler for KycNotVerifiedException

### Backend (Auth Service)
- `AuthController.java` - Added GET /user/{userId}/kyc-status endpoint
- `AuthService.java` - Added getUserKycStatus() method declaration
- `AuthServiceImpl.java` - Implemented getUserKycStatus() method
- `UserKycDTO.java` - DTO for KYC status response

### Frontend
- No changes needed - existing error handling in CreateAccountModal works

### Documentation
- `KYC_VERIFICATION_IMPLEMENTATION.md` - Full implementation documentation
- This file - Testing guide

## Summary

The KYC verification workflow ensures that:
- ✅ Users cannot create accounts without KYC verification
- ✅ Clear error messages guide users
- ✅ Secure inter-service communication
- ✅ Compliance-ready architecture
- ✅ Easy to extend with document upload and admin approval

Test results should show:
- PENDING users → Account creation blocked
- VERIFIED users → Account creation allowed
- REJECTED users → Account creation blocked
