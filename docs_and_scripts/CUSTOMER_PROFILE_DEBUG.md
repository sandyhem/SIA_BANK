# Customer Profile Test UI - Troubleshooting Guide

## ✅ What I Fixed

The test UI has been **updated with comprehensive debug logging** to help identify why the Customer Profile feature isn't working.

## 🔍 How to Debug

### Step 1: Open the Test UI
```bash
# Open in your browser:
file:///home/inba/SIA_BANK/test-ui-complete.html
```

### Step 2: Open Browser Developer Console
- **Chrome/Firefox**: Press `F12`
- Go to the **Console** tab

### Step 3: Test the Flow

1. **Register a New User**
   - Fill in the registration form
   - Click "Register User"
   - **Check console** for: `✅ User registered. Token: ...`
   - You should see the session info appear at the top

2. **Create Customer Profile**
   - Fill in the Customer Profile (CIF) form
   - Click "Create Customer Profile (CIF)"
   - **Watch the console** for detailed logs:
     ```
     === CREATE CUSTOMER CALLED ===
     📋 Customer Data: {...}
     👤 User ID: 23
     🔑 Token: eyJhbGciOiJIUzI1NiJ9...
     🌐 Request URL: http://localhost:8083/auth/api/customers?userId=23
     📡 Response Status: 201 Created
     📦 Response Data: {...}
     ✅ Customer created successfully!
     ```

## 🐛 Common Error Messages and Solutions

### ❌ "Please login first!"
**Problem**: No authentication token available  
**Solution**: Register or login before creating customer profile

### ❌ "User ID not available. Please login again."
**Problem**: The userId wasn't returned in register/login response  
**Solution**: 
1. Check if auth service returned userId in response
2. Re-login to get fresh token with userId

### ❌ HTTP 401 Unauthorized
**Problem**: Token not being sent or invalid  
**Console shows**: `📡 Response Status: 401`  
**Solution**:
1. Make sure you registered/logged in successfully
2. Check if token exists: Look for `🔑 Token: ...` in console
3. Token might be expired - try logging in again

### ❌ HTTP 404 Not Found
**Problem**: Endpoint doesn't exist  
**Console shows**: `📡 Response Status: 404`  
**Solution**:
1. Verify auth service is running: `curl http://localhost:8083/auth/api/auth/health`
2. Check endpoint URL in console: Should be `http://localhost:8083/auth/api/customers?userId=...`

### ❌ HTTP 500 Internal Server Error
**Problem**: Server-side error  
**Console shows**: `📡 Response Status: 500`  
**Solution**:
1. Check auth service logs:
   ```bash
   tail -100 /home/inba/SIA_BANK/auth/auth-service.log
   ```
2. Look for Java exceptions or database errors

### ❌ CORS Error
**Problem**: Browser blocking cross-origin request  
**Console shows**: `Access to fetch at '...' has been blocked by CORS policy`  
**Solution**: This shouldn't happen with localhost, but if it does:
1. Make sure you're opening the HTML file directly (file:// protocol)
2. Or serve it through a simple HTTP server

## 📊 What the Console Should Show (Success)

When everything works correctly, you'll see:

```
=== CREATE CUSTOMER CALLED ===
📋 Customer Data: {fullName: "John Doe", phone: "9876543210", ...}
👤 User ID: 23
🔑 Token: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiO...
🌐 Request URL: http://localhost:8083/auth/api/customers?userId=23
📡 Response Status: 201 Created
📦 Response Data: {
  id: 5,
  cifNumber: "CIF2026-4214",
  userId: 23,
  username: "testuser_1771086725",
  fullName: "John Doe",
  kycStatus: "PENDING",
  customerStatus: "INACTIVE",
  ...
}
✅ Customer created successfully!
```

## 🧪 Quick Test with cURL (Bypass UI)

To test if the backend works without the UI:

```bash
# 1. Register a user
RESPONSE=$(curl -s -X POST http://localhost:8083/auth/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser999",
    "email": "test999@example.com",
    "password": "Test@123",
    "firstName": "Test",
    "lastName": "User"
  }')

echo "$RESPONSE" | jq '.'

# Extract token and userId
TOKEN=$(echo "$RESPONSE" | jq -r '.token')
USER_ID=$(echo "$RESPONSE" | jq -r '.userId')

echo "Token: $TOKEN"
echo "User ID: $USER_ID"

# 2. Create customer profile
curl -s -X POST "http://localhost:8083/auth/api/customers?userId=$USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "fullName": "Test User Full Name",
    "phone": "9876543210",
    "address": "123 Test Street",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postalCode": "400001",
    "country": "India",
    "panNumber": "ABCDE1234F",
    "aadhaarNumber": "123456789012",
    "dateOfBirth": "1990-01-01"
  }' | jq '.'
```

## ✅ Updated Features

The test UI now includes:
- 🔍 **Detailed console logging** for every API call
- ⏳ **Loading indicators** ("Creating customer profile...")
- 📊 **Request/Response data** logged to console
- 🎯 **Specific error messages** with troubleshooting hints
- 📱 **Session state tracking** (userId, token, CIF number)

## 🚀 Next Steps

1. Open the test UI in browser
2. Open console (F12)
3. Try registering and creating customer profile
4. Share the console output if you still see errors

The logs will tell us exactly what's failing!
