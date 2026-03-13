# SIA Bank Backend API Inventory & Development Roadmap

**Analysis Date:** March 12, 2026  
**Services:** 3 microservices (Auth, Account, Transaction)  
**Total Endpoints:** 24 documented  

---

## 1. CURRENT ENDPOINTS INVENTORY

### Auth Service (Port: 8080)

| HTTP Method | Endpoint | Purpose | Request Body | Params | Response | Auth Required |
|---|---|---|---|---|---|---|
| **POST** | `/api/auth/register` | User registration | `{username, password, email, fullName}` | None | `{userId, token, message}` | No |
| **POST** | `/api/auth/login` | User authentication & JWT issuance | `{username, password}` | None | `{userId, token, expiresIn}` | No |
| **GET** | `/api/auth/validate` | Token validation | None | Header: `Authorization: Bearer <token>` | `{valid: boolean}` | **Yes** |
| **GET** | `/api/auth/health` | Health check | None | None | `{status: "UP", service: "auth-service"}` | No |
| **GET** | `/api/auth/user/{userId}/kyc-status` | Get KYC verification status | None | Path: `userId` | `{userId, status, approvedAt, verifiedBy}` | **Yes** |
| **GET** | `/api/customers` | List all customers | None | None | `[{ customerId, cifNumber, userId, fullName, kycStatus }]` | **Yes** |
| **POST** | `/api/customers` | Create customer profile (CIF generation) | `{fullName, phoneNumber, address, dateOfBirth}` | Query: `userId` | `{customerId, cifNumber, userId, status}` | **Yes** |
| **GET** | `/api/customers/user/{userId}` | Get customer by user ID | None | Path: `userId` | `{customerId, cifNumber, userId, fullName, kycStatus}` | **Yes** |
| **GET** | `/api/customers/cif/{cifNumber}` | Get customer by CIF | None | Path: `cifNumber` | `{customerId, cifNumber, userId, fullName, kycStatus}` | **Yes** |
| **PUT** | `/api/customers/cif/{cifNumber}/kyc` | Update KYC status (Admin) | `{kycStatus, documents, verificationNotes}` | Query: `adminUsername`, Path: `cifNumber` | `{customerId, cifNumber, kycStatus, approvedAt}` | **Yes (Admin)** |
| **GET** | `/api/customers/user/{userId}/active` | Check if customer can open accounts | None | Path: `userId` | `{active: boolean, canOpenAccounts: boolean}` | **Yes** |
| **POST** | `/api/crypto/generate-keys` | Generate ML-DSA-65 key pair (PQ-safe) | None | None | `{publicKey: base64, privateKey: base64}` | **Yes** |
| **GET** | `/api/crypto/server-kem-public-key` | Get server's ML-KEM public key | None | None | `{publicKey: base64}` | No |
| **GET** | `/api/crypto/server-dsa-public-key` | Get server's ML-DSA public key (JWT sig verify) | None | None | `{publicKey: base64}` | No |
| **POST** | `/api/crypto/sign` | Sign data with ML-DSA-65 | `{privateKey: base64, sessionId, serverNonce: base64}` | None | `{signature: base64}` | No |
| **POST** | `/api/crypto/encapsulate` | Encapsulate ML-KEM shared secret | `{serverPublicKey: base64}` | None | `{ciphertext: base64}` | No |
| **GET** | `/api/crypto/health` | Crypto system health | None | None | `{status, bcpqcProvider, bcProvider, serverKeysReady, mlKemAlgorithm, mlDsaAlgorithm}` | No |

**Auth Service Total:** 17 endpoints

---

### Account Service (Port: 8081)

| HTTP Method | Endpoint | Purpose | Request Body | Params | Response | Auth Required |
|---|---|---|---|---|---|---|
| **GET** | `/api/accounts/health` | Health check | None | None | `"Account Service is UP"` | No |
| **GET** | `/api/accounts/{accountNumber}` | Get account details | None | Path: `accountNumber` | `{accountNumber, customerId, balance, status, type, createdAt}` | **Yes** |
| **PUT** | `/api/accounts/{accountNumber}/debit` | Debit (withdrawal) | `{amount, description, transactionId}` | Path: `accountNumber` | `"Debit successful"` | **Yes** |
| **PUT** | `/api/accounts/{accountNumber}/credit` | Credit (deposit) | `{amount, description, transactionId}` | Path: `accountNumber` | `"Credit successful"` | **Yes** |
| **POST** | `/api/accounts` | Create new account | `{customerId, accountType, initialBalance}` | None | `{accountNumber, customerId, balance, status, createdAt}` | **Yes** |
| **GET** | `/api/accounts` | Get all accounts | None | None | `[{accountNumber, customerId, balance, status, type}]` | **Yes** |
| **GET** | `/api/accounts/customer/{customerId}` | Get accounts by customer | None | Path: `customerId` | `[{accountNumber, customerId, balance, status, type}]` | **Yes** |

**Account Service Total:** 7 endpoints

---

### Transaction Service (Port: 8082)

| HTTP Method | Endpoint | Purpose | Request Body | Params | Response | Auth Required |
|---|---|---|---|---|---|---|
| **GET** | `/` | Service info | None | None | `{service: "Transaction Service", status: "UP", port: "8082"}` | No |
| **GET** | `/health` | Health check | None | None | `{status: "UP"}` | No |
| **GET** | `/api/transactions/health` | Health check (API style) | None | None | `{status: "UP", service: "Transaction Service"}` | No |
| **POST** | `/api/transactions/transfer` | Fund transfer (account-to-account) | `{fromAccount, toAccount, amount, narration}` | None | `"Transfer successful"` or error | **Yes** |
| **GET** | `/api/transactions/account/{accountNumber}` | Get transaction history | None | Path: `accountNumber` | `[{transactionId, type, amount, date, status, narration}]` | **Yes** |

**Transaction Service Total:** 5 endpoints

---

## 2. GAPS & RISKS (Critical Issues)

### Security Gaps
- ❌ **No rate limiting** on login/register endpoints (brute force vulnerability)
- ❌ **No request/response encryption** between client & services (only HTTPS transport)
- ❌ **KYC update** missing document upload/verification workflow
- ❌ **No audit logging** for sensitive operations (money transfers, account creation)
- ⚠️ **Admin endpoint** (`PUT /api/customers/.../kyc`) lacks role-based access control

### API Quality Issues
- 🔄 **Duplicate health endpoints** across services (/, /health, /api/*/health) — standardize to `/actuator/health`
- ❌ **No API versioning** (e.g., `/v1/api/accounts`) — will cause breaking changes
- ❌ **Inconsistent response formats** (string messages vs JSON objects)
- ❌ **No error codes/standards** (should use RFC 7231 HTTP status consistently)
- ❌ **No pagination** on list endpoints (GET /api/accounts, GET /api/customers)

### Banking Domain Gaps
- ❌ **No deposit/withdrawal endpoints** (only direct account debit/credit)
- ❌ **No bill payment** (utilities, credit cards, loans)
- ❌ **No beneficiary management** (add/remove/list payees)
- ❌ **No transaction scheduling** (future-dated transfers, recurring payments)
- ❌ **No ATM/cash services** integration
- ❌ **No account statement export** (PDF/CSV)
- ❌ **No dispute/claim workflow** (for incorrect transactions)
- ❌ **No overdraft/credit facility** management

### Observability Gaps
- ❌ **No request ID tracking** for distributed tracing
- ❌ **No transaction lifecycle logging** (initiated → processed → settled)
- ❌ **No metrics** for API latency, error rates, success rates
- ❌ **No alerting** for suspicious transactions (fraud detection)

---

## 3. NEXT 10 APIs TO BUILD (Priority Order)

### **SPRINT 1: SECURITY & CORE BANKING (Week 1-2)**

#### **1. Rate Limit Check** (Prevent Brute Force)
```
POST /api/auth/login-with-otp
Headers: X-Request-ID, Content-Type
Body: {
  "username": "john.doe@bank.com",
  "otp": "123456",
  "deviceId": "uuid-xxxx"
}
Response: {
  "userId": 101,
  "token": "eyJ0eXAi...",
  "expiresIn": 3600,
  "mfaRequired": false
}
Notes: 2FA/OTP support for high-security login
```

#### **2. List Beneficiaries**
```
GET /api/accounts/{accountNumber}/beneficiaries
Query: ?limit=20&offset=0
Response: {
  "beneficiaries": [
    {
      "beneficiaryId": 1,
      "accountNumber": "1234567890",
      "name": "Jane Doe",
      "bankName": "Another Bank",
      "status": "verified",
      "addedAt": "2026-01-15"
    }
  ],
  "total": 5
}
```

#### **3. Add Beneficiary**
```
POST /api/accounts/{accountNumber}/beneficiaries
Body: {
  "name": "Jane Doe",
  "accountNumber": "1234567890",
  "ifscCode": "SBIN0000001",
  "accountType": "savings"
}
Response: {
  "beneficiaryId": 1,
  "status": "pending_verification",
  "verificationMethod": "micro_deposit"
}
```

#### **4. Transaction Audit Log** (Compliance)
```
GET /api/transactions/account/{accountNumber}/audit?days=30
Response: {
  "transactionId": "txn-uuid",
  "initiatedBy": "userId-101",
  "amount": 5000,
  "status": "completed",
  "timestamp": "2026-03-12T10:30:00Z",
  "deviceInfo": { "ipAddress": "192.168.1.1", "userAgent": "..." },
  "approvedBy": "userId-admin-50"
}
```

#### **5. Account Statement Export**
```
GET /api/accounts/{accountNumber}/statement/export?format=pdf&startDate=2026-01-01&endDate=2026-03-12
Response: PDF binary or { "downloadUrl": "https://..." }
```

### **SPRINT 2: ENHANCED BANKING FEATURES (Week 3-4)**

#### **6. Recurring Transfers (Auto-Pay)**
```
POST /api/transactions/recurring
Body: {
  "fromAccount": "source-acc",
  "toAccount": "dest-acc",
  "amount": 1000,
  "frequency": "monthly",
  "startDate": "2026-04-01",
  "endDate": "2026-12-31",
  "narration": "Rent payment"
}
Response: {
  "recurringTransferId": "rec-uuid",
  "status": "active",
  "nextScheduledDate": "2026-04-01"
}
```

#### **7. Bill Payment (Multi-provider)**
```
POST /api/payments/bills
Body: {
  "fromAccount": "account-123",
  "providerCode": "ELECTRICITY_GRID_01",
  "billReference": "CUST-12345",
  "amount": 2500,
  "dueDate": "2026-03-15"
}
Response: {
  "paymentId": "bill-uuid",
  "status": "pending_confirmation",
  "confirmUrl": "..."
}
```

#### **8. Fraud Detection Alert**
```
GET /api/accounts/{accountNumber}/alerts?type=fraud
Response: {
  "alerts": [
    {
      "alertId": "alert-uuid",
      "severity": "high",
      "type": "unusual_activity",
      "description": "Large withdrawal detected at 3 AM",
      "timestamp": "2026-03-12T03:15:00Z",
      "actionRequired": "confirm_transaction"
    }
  ]
}
POST /api/accounts/{accountNumber}/alerts/{alertId}/acknowledge
```

#### **9. Account Linking (Multi-account)**
```
POST /api/accounts/link
Body: {
  "primaryAccount": "account-1",
  "linkedAccount": "account-2",
  "linkType": "sweep"
}
Response: {
  "linkId": "link-uuid",
  "status": "active"
}
```

#### **10. KYC Document Upload**
```
POST /api/customers/{customerId}/kyc/documents
Content-Type: multipart/form-data
Fields:
  - documentType: "IDENTITY_PROOF" | "ADDRESS_PROOF" | "PAN"
  - file: <binary>
  - selfieWithDocument: <binary>

Response: {
  "documentId": "doc-uuid",
  "status": "pending_verification",
  "verificationDeadline": "2026-03-19"
}
```

---

## 4. IMPLEMENTATION PLAN (2 Sprints)

### **SPRINT 1: Foundation Security & Core Features**
**Goal:** Lock down authentication, add audit trail, improve data consistency

| Task | Effort | Owner | Sprint Days |
|---|---|---|---|
| Implement login rate limiting + OTP | 3 days | Auth Team | 1-3 |
| Add transaction audit logging (database + indexing) | 2 days | Transaction Team | 1-2 |
| Build beneficiary management (CRUD) | 3 days | Account Team | 2-4 |
| Standardize health endpoints + error responses | 1 day | DevOps | 4 |
| Write integration tests for existing 24 endpoints | 2 days | QA | 3-5 |
| **Sprint 1 Subtotal** | **11 days** | - | **Sprint 1** |

**Sprint 1 Deliverables:**
- ✅ 5 new endpoints (OTP login, beneficiaries, audit logs, statements, rate limiting)
- ✅ Audit logging database schema + index strategy
- ✅ Updated OpenAPI/Swagger docs
- ✅ Test coverage >80% for auth flow

---

### **SPRINT 2: Enhanced Banking & Developer Experience**
**Goal:** Monetize with bill payments, recurring transfers, improve frontend-backend sync

| Task | Effort | Owner | Sprint Days |
|---|---|---|---|
| Recurring transfers scheduling + settlement engine | 4 days | Transaction Team | 1-4 |
| Multi-provider bill payment integration | 3 days | Payment Integration | 2-5 |
| KYC document upload + verification workflow | 3 days | Compliance Team | 1-3 |
| Fraud detection rule engine + alerting | 3 days | Security Team | 3-5 |
| API versioning scheme + backward compatibility guide | 1 day | DevOps | 4 |
| Performance testing (latency, load) | 2 days | QA | 5-10 |
| **Sprint 2 Subtotal** | **16 days** | - | **Sprint 2** |

**Sprint 2 Deliverables:**
- ✅ 5 new endpoints (recurring payments, bills, fraud alerts, account linking, doc upload)
- ✅ Message queue for async settlements (RabbitMQ/Kafka)
- ✅ Fraud detection dashboard (admin view)
- ✅ API v1.0 stability certified (no breaking changes test)
- ✅ Load test results (SLA: <500ms p95 latency, 5000 req/sec)

---

## 5. RECOMMENDATIONS FOR IMMEDIATE ACTION

### **Within 48 hours:**
1. ✅ **Code Freezing Strategy:** Adopt semantic versioning (`/v1/api/...`)
2. ✅ **OpenAPI/Swagger:** Generate from annotations, host at `/api/v1/swagger-ui.html`
3. ✅ **Error Standards:** Define unified error response:
   ```json
   {
     "error": {
       "code": "INSUFFICIENT_BALANCE",
       "message": "Account balance is insufficient",
       "timestamp": "2026-03-12T10:30:00Z",
       "traceId": "trace-uuid"
     }
   }
   ```

### **Within 1 week:**
1. ✅ **Rate Limiting:** Add `spring-cloud-gateway` + Redis-backed rate limiter
2. ✅ **Audit Trail:** Create `audit_logs` table, log all writes to accounts/transactions
3. ✅ **Request ID Tracking:** Implement `MDC` (Mapped Diagnostic Context) in SLF4J

### **UI/Frontend Ready for:**
- User registration + KYC flow
- Account management (balance, mini-statement)
- Transfer/payment workflows
- Transaction history with filters
- Beneficiary management
- Bill payment integration
- Fraud alert acknowledgment

---

## 6. TECH DEBT & REFACTORING

| Issue | Impact | Priority | Fix |
|---|---|---|---|
| Query N+1 in customer list endpoint | High latency | High | Add `@EntityGraph` or JOIN FETCH |
| No database connection pooling | Connection exhaustion under load | High | HikariCP with pool size tuning |
| Crypto keys in-memory (ephemeral) | Key loss on restart | Medium | Integrate with HSM or Vault |
| No circuit breaker between services | Cascading failures | Medium | Add Resilience4j circuit breaker |
| JWT with no refresh token rotation | Token compromise window | High | Implement refresh token rotation + short-lived JWTs |

---

**Report Generated:** 2026-03-12  
**Next Review:** Post-Sprint 1 (Target: 2026-03-26)
