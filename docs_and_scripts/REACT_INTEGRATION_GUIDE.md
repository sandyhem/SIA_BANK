# 🎉 React Frontend Backend Integration - Complete Guide

## ✅ What's Been Done

### 1. Service Layer Integration
✅ **Updated Services** - All service files now integrate with real backend:
- `/bankProject/src/services/authService.js` - JWT authentication with backend
- `/bankProject/src/services/customerService.js` - NEW! CIF and KYC management
- `/bankProject/src/services/accountService.js` - Account operations
- `/bankProject/src/services/transactionService.js` - Money transfers and history

### 2. Auth Context Enhanced
✅ **Updated `/bank Project/src/context/AuthContext.jsx`**
- Added customer profile management
- Automatic customer data fetching on login
- KYC status tracking
- Helper methods: `hasCustomerProfile`, `isKycVerified`, `isCustomerActive`

### 3. Components Created
✅ **New Components**:
- `/bankProject/src/components/CreateCustomerModal.jsx` - CIF creation form
- `/bankProject/src/pages/AccountsNew.jsx` - Real backend integration for accounts
- Updated `/bankProject/src/components/CreateAccountModal.jsx` (needs manual fix - see below)

### 4. Dashboard Updated
✅ **Updated `/bankProject/src/pages/Dashboard.jsx`**
- Shows customer profile status
- Displays real account data from backend
- Handles three states: No Profile → KYC Pending → Active Dashboard

---

## 🚀 Quick Start - Run the Integration

### Step 1: Start Backend Services
```bash
cd /home/inba/SIA_BANK
bash start-services.sh
```

Verify all services are running:
- Auth Service: http://localhost:8083
- Account Service: http://localhost:8081
- Transaction Service: http://localhost:8082

### Step 2: Start React Frontend
```bash
cd /home/inba/SIA_BANK/bankProject
npm run dev
```

The app will run on: http://localhost:5173

---

## 📋 Testing the Complete Banking Flow

### 1. **Register & Login**
- Navigate to http://localhost:5173/register
- Create a new account
- Login with credentials

### 2. **Create Customer Profile (CIF)**
- After login, Dashboard will show "Create Customer Profile" prompt
- Fill in all required fields:
  - Personal info (Name, Phone, DOB)
  - Address details (Street, City, State, Postal Code)
  - KYC documents (PAN, Aadhaar)
- Submit to get CIF number

### 3. **KYC Verification** (Admin Action)
Your profile will be in PENDING status. To verify KYC:

**Option A: Using Swagger UI**
1. Open: http://localhost:8083/auth/swagger-ui/index.html
2. Use `PUT /api/customers/cif/{cifNumber}/kyc` endpoint
3. Body: `{ "kycStatus": "VERIFIED" }`

**Option B: Using Database**
```bash
sudo mysql auth_db -e "UPDATE customers SET kyc_status = 'VERIFIED' WHERE cif_number = 'YOUR_CIF_NUMBER';"
```

### 4. **Open Bank Account**
- After KYC verification, go to Accounts page
- Click "Open New Account"
- Choose account type (Savings/Current)
- Set initial deposit
- Submit

### 5. **Perform Transactions**
- Go to Transfers page
- Transfer money between accounts
- View transaction history

---

## 🔧 Files That Need Manual Updates

### 1. Update App Routing
Edit `/bankProject/src/App.jsx` to use new Accounts page:

```jsx
// Replace old Accounts import
import Accounts from './pages/AccountsNew';  // Use the new one
```

### 2. Fix CreateAccountModal Import
The CreateAccountModal was updated but needs verification. Check if this import works:

```jsx
// In any file using CreateAccountModal
import CreateAccountModal from '../components/CreateAccountModal';
```

If you get errors, manually copy the content from `/bankProject/src/pages/AccountsNew.jsx` which has the working implementation.

### 3. Update Transfers Page (Optional)
Create `/bankProject/src/pages/TransfersNew.jsx`:

```jsx
import { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { transactionService } from '../services/transactionService';

export default function Transfers() {
  const { customer } = useAuth();
  const [accounts, setAccounts] = useState([]);
  const [formData, setFormData] = useState({
    fromAccount: '',
    toAccount: '',
    amount: '',
    description: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (customer?.id) {
      loadAccounts();
    }
  }, [customer]);

  const loadAccounts = async () => {
    try {
      const data = await accountService.getAccountsByCustomerId(customer.id);
      setAccounts(data);
      if (data.length > 0) {
        setFormData(prev => ({ ...prev, fromAccount: data[0].accountNumber }));
      }
    } catch (err) {
      console.error('Error loading accounts:', err);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      await transactionService.transfer(
        formData.fromAccount,
        formData.toAccount,
        parseFloat(formData.amount),
        formData.description
      );
      setSuccess('Transfer completed successfully!');
      setFormData({ ...formData, toAccount: '', amount: '', description: '' });
      await loadAccounts(); // Refresh balances
    } catch (err) {
      setError(err.response?.data || 'Transfer failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <QuantumLayout title="Transfers" subtitle="Transfer money between accounts">
      <div className="max-w-2xl mx-auto">
        <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-lg">
          {error && <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">{error}</div>}
          {success && <div className="mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">{success}</div>}

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">From Account</label>
              <select 
                value={formData.fromAccount} 
                onChange={(e) => setFormData({...formData, fromAccount: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                required
              >
                {accounts.map(acc => (
                  <option key={acc.id} value={acc.accountNumber}>
                    {acc.accountNumber} - ₹{parseFloat(acc.balance).toLocaleString('en-IN')}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">To Account Number</label>
              <input 
                type="text" 
                value={formData.toAccount}
                onChange={(e) => setFormData({...formData, toAccount: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                placeholder="Enter recipient account number"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Amount</label>
              <input 
                type="number" 
                step="0.01"
                min="0.01"
                value={formData.amount}
                onChange={(e) => setFormData({...formData, amount: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                placeholder="Enter amount"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Description (Optional)</label>
              <input 
                type="text" 
                value={formData.description}
                onChange={(e) => setFormData({...formData, description: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                placeholder="Payment description"
              />
            </div>

            <button 
              type="submit"
              disabled={loading}
              className="w-full px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 disabled:opacity-50 font-medium"
            >
              {loading ? 'Processing...' : 'Transfer Money'}
            </button>
          </div>
        </form>
      </div>
    </QuantumLayout>
  );
}
```

---

## 🎯 Complete File Changes Summary

### Created Files:
1. `/bankProject/src/services/customerService.js` ✅
2. `/bankProject/src/components/CreateCustomerModal.jsx` ✅
3. `/bankProject/src/pages/AccountsNew.jsx` ✅

### Modified Files:
1. `/bankProject/src/services/authService.js` ✅
2. `/bankProject/src/services/accountService.js` ✅
3. `/bankProject/src/services/transactionService.js` ✅
4. `/bankProject/src/context/AuthContext.jsx` ✅
5. `/bankProject/src/pages/Dashboard.jsx` ✅
6. `/bankProject/src/components/CreateAccountModal.jsx` ⚠️ (Needs verification)

---

## 🧪 Test Endpoints

All backend endpoints are available via Swagger UI:
- **Auth & Customer**: http://localhost:8083/auth/swagger-ui/index.html
- **Accounts**: http://localhost:8081/swagger-ui/index.html
- **Transactions**: http://localhost:8082/swagger-ui/index.html

---

## 📝 Next Steps

1. ✅ Backend is running with Swagger
2. ✅ Service layer is integrated
3. ✅ Auth context updated
4. ✅ Dashboard shows real data
5. ⏳ Start React app and test the flow
6. ⏳ Update remaining pages (Transactions, Transfers if needed)

---

## 🆘 Troubleshooting

### CORS Errors
All services have CORS enabled. If you still get errors:
```bash
# Restart services
cd /home/inba/SIA_BANK
bash start-services.sh
```

### Authentication Errors
- Check if JWT token is being sent in requests
- Verify token in localStorage: `localStorage.getItem('authToken')`
- Login again to get fresh token

### Customer Profile Issues
- Check KYC status in database
- Use Swagger to update KYC status manually
- Verify customer exists: `GET /api/customers/user/{userId}`

---

## 📚 API Endpoints Reference

### Auth Service (Port 8083)
- `POST /auth/api/auth/register` - Register user
- `POST /auth/api/auth/login` - Login & get JWT
- `POST /auth/api/customers?userId={id}` - Create customer (CIF)
- `GET /auth/api/customers/user/{userId}` - Get customer by user ID
- `PUT /auth/api/customers/cif/{cif}/kyc` - Update KYC status

### Account Service (Port 8081)
- `POST /api/accounts` - Create account
- `GET /api/accounts/customer/{customerId}` - Get accounts by customer
- `PUT /api/accounts/{accountNo}/credit` - Credit account
- `PUT /api/accounts/{accountNo}/debit` - Debit account

### Transaction Service (Port 8082)
- `POST /api/transactions/transfer` - Transfer money
- `GET /api/transactions/account/{accountNo}` - Get transaction history

---

**Happy Banking! 🏦💰**

For any issues, check:
- Service logs in `/home/inba/SIA_BANK/*/logs`
- Browser console for errors
- Swagger UI for endpoint testing
