# Complete End-to-End Testing Guide

## Quick Start

1. **Ensure all services are running:**
   ```bash
   cd /home/inba/SIA_BANK
   ./start-services.sh
   ```

2. **Open the Test UI:**
   ```bash
   # Open in default browser
   xdg-open /home/inba/SIA_BANK/test-ui-complete.html
   
   # Or manually open in browser:
   # file:///home/inba/SIA_BANK/test-ui-complete.html
   ```

## Complete Testing Flow

### Step 1: Register a New User
1. Go to **Authentication** section (Register tab)
2. Fill in:
   - Username: `testuser_demo`
   - Email: `demo@example.com`
   - Password: `Test@123`
   - First Name: `Demo`
   - Last Name: `User`
3. Click **Register User**
4. ✅ Expected: Success response with KYC status: **PENDING**

### Step 2: Login
1. Switch to **Login** tab
2. Use the credentials from Step 1
3. Click **Login**
4. ✅ Expected: JWT token received, session info displayed at top

### Step 3: Try Creating Account (Should Fail)
1. Go to **Account Creation** section
2. Fill in:
   - Account Name: `My Savings`
   - Account Type: `SAVINGS`
   - Customer ID: (auto-filled from session)
   - Initial Balance: `1000`
3. Click **Create Account**
4. ❌ Expected: **HTTP 403 Error** - "Account creation requires KYC verification"

### Step 4: Update KYC Status to VERIFIED
1. Go to **KYC Management** section
2. Username field should be auto-filled
3. Select **VERIFIED** from dropdown
4. Click **Update KYC Status**
5. Copy the SQL command shown
6. Run in terminal:
   ```bash
   sudo mysql auth_db -e "UPDATE users SET kyc_status='VERIFIED' WHERE username='testuser_demo';"
   ```

### Step 5: Re-login to Get Updated KYC Status
1. Go back to **Authentication** → **Login** tab
2. Login again with same credentials
3. ✅ Expected: Session now shows KYC Status: **VERIFIED**

### Step 6: Create Account (Should Succeed)
1. Go to **Account Creation** section
2. Fill in the same details:
   - Account Name: `My Savings`
   - Account Type: `SAVINGS`
   - Initial Balance: `1000`
3. Click **Create Account**
4. ✅ Expected: Success! Account created with account number (e.g., ACC12345678)

### Step 7: View Account Details
1. Go to **Account Details** section
2. Account number should be auto-filled from Step 6
3. Click **View Account**
4. ✅ Expected: Account details with balance shown

### Step 8: Credit Account
1. Go to **Transactions** section → **Credit** tab
2. Account number should be auto-filled
3. Enter amount: `500`
4. Click **Credit Account**
5. ✅ Expected: "Credit successful"

### Step 9: View Updated Balance
1. Go back to **Account Details**
2. Click **View Account** again
3. ✅ Expected: Balance increased by 500

### Step 10: Debit Account
1. Go to **Transactions** → **Debit** tab
2. Enter amount: `200`
3. Click **Debit Account**
4. ✅ Expected: "Debit successful"

### Step 11: Create Second Account for Transfer
1. Go to **Account Creation**
2. Create another account:
   - Account Name: `My Checking`
   - Account Type: `CHECKING`
   - Initial Balance: `500`
3. Note the account number

### Step 12: Transfer Money
1. Go to **Transactions** → **Transfer** tab
2. Fill in:
   - From Account: (first account number)
   - To Account: (second account number)
   - Amount: `300`
   - Description: `Test transfer`
3. Click **Transfer Money**
4. ✅ Expected: Transfer successful

### Step 13: View Transaction History
1. Go to **Transaction History**
2. Enter account number
3. Click **Get Transaction History**
4. ✅ Expected: List of all transactions for that account

## Testing Different KYC Statuses

### Test PENDING Status (Default)
```bash
# User created → KYC: PENDING
# Account creation → ❌ Blocked (403 Error)
```

### Test VERIFIED Status
```bash
sudo mysql auth_db -e "UPDATE users SET kyc_status='VERIFIED' WHERE username='testuser';"
# Account creation → ✅ Allowed
```

### Test REJECTED Status
```bash
sudo mysql auth_db -e "UPDATE users SET kyc_status='REJECTED' WHERE username='testuser';"
# Account creation → ❌ Blocked (403 Error)
```

## Service Health Checks

The UI automatically checks all services on load:
- ✅ Green = Service UP
- ❌ Red = Service DOWN

## Troubleshooting

### Services Not Running
```bash
cd /home/inba/SIA_BANK
./start-services.sh
```

### CORS Errors
If you see CORS errors in browser console, the services need CORS configuration. For testing, you can use a browser extension to disable CORS or run Chrome with:
```bash
google-chrome --disable-web-security --user-data-dir=/tmp/chrome_dev
```

### Database Access
If you can't run sudo mysql, try:
```bash
mysql -u appuser -ppassword auth_db -e "UPDATE users SET kyc_status='VERIFIED' WHERE username='testuser';"
```

### Token Expired
If you get 401 errors, your token may have expired. Simply login again.

## API Endpoints Tested

### Auth Service (8083)
- ✅ POST `/auth/api/auth/register` - User registration
- ✅ POST `/auth/api/auth/login` - User login
- ✅ GET `/auth/api/auth/health` - Service health

### Account Service (8081)
- ✅ POST `/api/accounts` - Create account (with KYC check)
- ✅ GET `/api/accounts/{accountNumber}` - View account
- ✅ PUT `/api/accounts/{accountNumber}/credit` - Credit account
- ✅ PUT `/api/accounts/{accountNumber}/debit` - Debit account
- ✅ GET `/api/accounts/health` - Service health

### Transaction Service (8082)
- ✅ POST `/api/transactions/transfer` - Transfer money
- ✅ GET `/api/transactions/account/{accountNumber}` - Transaction history
- ✅ GET `/api/transactions/health` - Service health

## Features Tested

- ✅ User registration with auto KYC PENDING
- ✅ User authentication with JWT
- ✅ KYC status enforcement (PENDING blocks account creation)
- ✅ KYC status update (manual DB update)
- ✅ Account creation (requires VERIFIED KYC)
- ✅ Account viewing
- ✅ Credit operations
- ✅ Debit operations
- ✅ Money transfers between accounts
- ✅ Transaction history
- ✅ Token-based authorization
- ✅ Error handling and user feedback
- ✅ Service health monitoring

## Complete Test Script Alternative

For automated testing without UI:
```bash
bash /home/inba/SIA_BANK/test-all-functionality.sh
```

This will test all endpoints via curl and show results in terminal.

## Success Criteria

All tests should show:
- ✅ Users can register
- ✅ Users can login
- ✅ KYC PENDING blocks account creation (HTTP 403)
- ✅ KYC VERIFIED allows account creation
- ✅ Accounts can be created with initial balance
- ✅ Credit/Debit operations work
- ✅ Transfers work between accounts
- ✅ Transaction history is maintained
- ✅ All services communicate properly
- ✅ JWT authentication works across services
