# 🏦 Quantum Bank - Frontend User Guide

## Complete Banking Journey

### 1️⃣ Registration & Login ✅

**You've completed this step!**
- Navigate to: http://localhost:5173/register
- Fill in your details (username, email, password, firstName, lastName, phone)
- Click "Create account"
- You'll be automatically logged in and redirected to Dashboard

---

### 2️⃣ Create Customer Profile (CIF)

After login, you'll see a **purple welcome screen** on the Dashboard:

**What you'll see:**
- "Create Your Customer Profile" heading
- Information about what you need
- "Create Customer Profile" button

**Click the button and fill in the form:**

#### Personal Information:
- **Full Name**: Your complete legal name (e.g., "John Michael Doe")
- **Phone**: 10-digit mobile number (e.g., "9876543210")
- **Date of Birth**: Format YYYY-MM-DD (e.g., "1990-01-15")

#### Address Details:
- **Street Address**: Your residential address
- **City**: Your city name
- **State**: Your state
- **Postal Code**: 6-digit PIN code (e.g., "560001")
- **Country**: Your country (default: India)

#### KYC Documents (Important!):
- **PAN Number**: Format ABCDE1234F (10 characters, example: "ABCDE1234F")
- **Aadhaar Number**: Exactly 12 digits (example: "123456789012")

**Click "Create Profile"**

You'll receive:
- ✅ Success message
- 🎫 Your unique **CIF Number** (Customer Information File)
- This CIF number identifies you in the banking system

---

### 3️⃣ KYC Verification (Admin Action Required)

After creating your profile, you'll see a **yellow/amber screen**:
- "KYC Verification Pending" heading
- Your profile details
- Message that your documents are being reviewed

**To verify KYC (Admin Action):**

#### Option A: Using Swagger UI (Recommended)
```bash
# Open Swagger UI in your browser
http://localhost:8083/auth/swagger-ui/index.html

# Find: PUT /api/customers/cif/{cifNumber}/kyc
# Click "Try it out"
# Enter your CIF number (shown on the pending screen)
# Request Body:
{
  "kycStatus": "VERIFIED",
  "verifiedBy": "ADMIN"
}
# Click "Execute"
```

#### Option B: Using Database
```bash
# In terminal, run:
sudo mysql auth_db -e "UPDATE customers SET kyc_status = 'VERIFIED' WHERE cif_number = 'YOUR_CIF_NUMBER';"
```

#### Option C: Using curl
```bash
curl -X PUT "http://localhost:8083/auth/api/customers/cif/YOUR_CIF_NUMBER/kyc" \
  -H "Content-Type: application/json" \
  -d '{
    "kycStatus": "VERIFIED",
    "verifiedBy": "ADMIN"
  }'
```

**After KYC is verified:**
- Refresh your Dashboard page (F5)
- You'll now see the full banking dashboard with accounts!

---

### 4️⃣ Open Your First Bank Account

Once KYC is verified, you'll see the active Dashboard:

**Navigate to Accounts page:**
- Click "Accounts" in the sidebar
- You'll see "No Accounts Yet" message
- Click **"Open New Account"** button

**Fill in the Account Form:**

#### Account Type (Choose one):
- **Savings Account**: 
  - Earn interest on deposits
  - Minimum balance: ₹1,000
  - Best for personal savings

- **Current Account**: 
  - For business transactions
  - Minimum balance: ₹5,000
  - No interest, unlimited transactions

#### Other Details:
- **Branch Code**: Select from dropdown
  - Main Branch (MAIN001)
  - East Branch (EAST002)

- **Initial Deposit**: Enter amount
  - Must meet minimum balance requirement
  - Example: ₹5,000 for savings

**Click "Open Account"**

You'll receive:
- ✅ Success message
- 🏦 10-digit **Account Number**
- Account appears in your Accounts list

---

### 5️⃣ View Your Accounts

**Accounts Page Features:**
- 📊 View all your accounts
- 💰 See balances (with show/hide toggle)
- 📈 Account type and status
- 🔢 Account numbers
- 🏦 Branch information

**To hide/show balances:**
- Click "Hide Balances" or "Show Balances" button
- Balances will be masked as "••••••"

---

### 6️⃣ Transfer Money Between Accounts

**Navigate to Transfers page:**

**You'll see:**
- Current account balance at top
- Transfer form

**Fill in Transfer Details:**

1. **From Account**: 
   - Select source account from dropdown
   - Shows current balance

2. **To Account Number**: 
   - Enter 10-digit recipient account number
   - Can transfer to your own accounts or others

3. **Amount**: 
   - Enter transfer amount (₹)
   - System validates sufficient balance
   - Shows remaining balance after transfer

4. **Description** (Optional):
   - Add note like "Payment for services", "Rent", etc.

**Click "Transfer Money"**

Transfer is instant! You'll see:
- ✅ Success message
- Updated account balances
- Transaction recorded in history

---

### 7️⃣ View Transaction History

**Navigate to Transactions page:**

**You'll see:**
- List of all your transactions
- Transaction types: CREDIT, DEBIT, TRANSFER
- Date, time, amount
- Account numbers involved
- Transaction descriptions
- Current balance after each transaction

**Filter & Search:**
- Search by transaction type
- Filter by date range
- Sort by amount or date

---

## 🎨 Dashboard Overview

Once fully set up, your Dashboard shows:

### Quick Stats Cards:
- **Total Accounts**: Number of accounts you have
- **Total Balance**: Combined balance across all accounts
- **Recent Transactions**: Number of transactions this month
- **Active Services**: Services you're using

### Recent Transactions:
- Last 5 transactions
- Quick overview of activity
- Click to see full history

### Account Summary:
- All your accounts at a glance
- Current balances
- Quick actions

---

## 🚀 Quick Start Checklist

- [x] **Register** - Create user account
- [ ] **Create CIF** - Fill customer profile form
- [ ] **Verify KYC** - Admin verifies your documents
- [ ] **Open Account** - Create savings/current account
- [ ] **Transfer Money** - Send money between accounts
- [ ] **View Transactions** - Check your transaction history

---

## 💡 Pro Tips

### Account Management:
- Open multiple accounts for different purposes
- Maintain minimum balance to avoid penalties
- Use descriptive names in transfers for better tracking

### Security:
- Your JWT token expires after 24 hours
- You'll need to login again after expiry
- Keep your CIF number safe - it's your unique identifier

### Transfers:
- Double-check recipient account number before submitting
- Add meaningful descriptions for future reference
- Transfers are instant and irreversible
- Minimum transfer amount: ₹0.01

### Navigation:
- Use sidebar to switch between pages
- Dashboard shows overview of everything
- Each page focuses on specific functionality

---

## 🆘 Troubleshooting

### "No Customer Profile" showing?
- Make sure you clicked "Create Customer Profile" on Dashboard
- Check if form was submitted successfully
- Look for CIF number confirmation

### "KYC Pending" not changing?
- Verify KYC status was updated in database
- Check Swagger UI PUT request succeeded
- Refresh the page (F5) after KYC verification

### Transfer failing?
- Check sufficient balance in source account
- Verify recipient account number is correct (10 digits)
- Ensure amount is greater than ₹0
- Check both accounts exist in system

### Not seeing accounts?
- Verify KYC is verified first
- Check if account creation succeeded
- Look for success message after opening account
- Refresh the page

### Token expired errors?
- JWT tokens expire after 24 hours
- Simply logout and login again
- Your data is safely stored in the database

---

## 📊 Testing the Complete Flow

### Test Scenario: Family Banking

1. **Create 2 Users:**
   - User A: John (register as john@bank.com)
   - User B: Jane (register as jane@bank.com)

2. **Both Create Customer Profiles:**
   - Fill in different details
   - Note down both CIF numbers

3. **Verify Both KYC:**
   - Use Swagger UI for both CIF numbers

4. **Each Opens 2 Accounts:**
   - John: 1 Savings + 1 Current
   - Jane: 1 Savings + 1 Current

5. **Transfer Between Accounts:**
   - John transfers from Savings → Current
   - John transfers to Jane's account
   - Jane receives and transfers back

6. **Check Transaction History:**
   - Both can see complete transaction trail
   - All transfers properly recorded

---

## 🎯 What Each Page Does

| Page | Purpose | Key Features |
|------|---------|--------------|
| **Dashboard** | Overview | Stats, recent transactions, quick actions |
| **Accounts** | Manage Accounts | View all accounts, open new accounts, check balances |
| **Transactions** | Transaction History | View all transactions, filter, search |
| **Transfers** | Send Money | Transfer between accounts, real-time validation |
| **Settings** | User Settings | Profile management, preferences |
| **Support** | Help & Support | Contact information, FAQs |

---

## 🔐 Security Features

- **JWT Authentication**: Secure token-based auth
- **Password Encryption**: Bcrypt hashing on backend
- **Protected Routes**: Must be logged in to access banking features
- **Session Management**: Auto-logout on token expiry
- **Validation**: Input validation on both frontend and backend

---

## 📱 Responsive Design

The app works on:
- 💻 Desktop (optimized)
- 📱 Tablet (responsive)
- 📲 Mobile (mobile-friendly)

---

**Enjoy your banking experience!** 🎉

For any issues, check the browser console (F12) for error messages.
