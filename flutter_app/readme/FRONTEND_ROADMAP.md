# SIA Bank Flutter Frontend - Development Roadmap

**Aligned with Backend API Development Plan**  
**Last Updated:** March 12, 2026

---

## 📱 Frontend Architecture Overview

### Technology Stack
- **Framework:** Flutter 3.x (Dart 3.x)
- **State Management:** Riverpod (FutureProvider, StateProvider)
- **HTTP Client:** Dio with automatic JWT bearer token injection
- **Secure Storage:** flutter_secure_storage (Android Keystore, iOS Keychain)
- **UI Library:** Material 3 + responsive ScreenUtil
- **Cryptography:** Ready for PointyCastle ML-KEM/ML-DSA integration

### Design Philosophy
- **Mobile-First:** Optimized for all phone sizes (375x812 baseline)
- **Accessible:** WCAG 2.1 AA compliance for text, colors, tap targets
- **Secure by Default:** Tokens in secure storage, HTTPS enforced, no sensitive data in logs
- **Offline-Ready:** Placeholder architecture for local caching (future)

---

## 🎯 Frontend Development Roadmap

### SPRINT 1: MVP Authentication & Core Banking (Weeks 1-2)

#### Completed ✅
- [x] Splash Screen + Navigation
- [x] User Registration with validation
- [x] User Login with JWT token storage
- [x] Home Dashboard with account cards
- [x] Account balance display
- [x] Recent transaction list
- [x] Quick actions menu
- [x] Fund transfer screen (Send Money)
- [x] API service with Dio client + JWT interceptors
- [x] Data models (Auth, Account, Transaction)
- [x] AppTheme (Material 3, responsive)

#### Current Status
- **Screens Built:** 6 (Splash, Login, Register, Home, Transfer, Error handling)
- **API Endpoints Connected:** 13/24 backend endpoints
- **Test Coverage:** Manual testing flows defined

#### To Complete Sprint 1
- [ ] Unit tests for API service (3 days)
- [ ] Integration tests for auth flow (2 days)
- [ ] Error boundary wrapper around API calls (1 day)
- [ ] Offline error states (graceful degradation) (1 day)
- [ ] Performance profiling & optimization (1 day)

**Sprint 1 Deliverable Date:** March 26, 2026

---

### SPRINT 2: Enhanced Banking & Account Features (Weeks 3-4)

#### Planned Features
- [ ] **Accounts List Screen**
  - Display all customer accounts
  - Filter by account type (Savings, Checking, Investment)
  - Search accounts
  - Account status indicators
  - *Backend API:* `GET /api/accounts` + pagination support

- [ ] **Account Details Screen**
  - Full account information
  - Account statements (mini)
  - Freeze/Close account options
  - *Backend API:* `GET /api/accounts/{accountNumber}`

- [ ] **Beneficiary Management**
  - List saved beneficiaries
  - Add new beneficiary
  - Verify new beneficiary
  - Delete beneficiary
  - *Backend API:* New endpoints needed (see backend roadmap)

- [ ] **Transaction Filters**
  - Filter by date range
  - Filter by amount range
  - Filter by status (Pending, Completed, Failed)
  - Search by description
  - *Backend API:* `GET /api/transactions/account/{accountNumber}?filters=...`

- [ ] **Transaction Details Modal**
  - Full transaction information
  - Recipient/Sender details
  - Receipt/proof download (future)
  - Dispute option
  - *Backend API:* `GET /api/transactions/{transactionId}` (new)

#### Database Models to Add
```dart
// Accounts Screen
final accountsListProvider = FutureProvider<List<AccountDTO>>((ref) =>
  ref.watch(apiServiceProvider).getAllAccounts());

// Selected Account Details
final accountDetailsProvider = FutureProvider.family<AccountDTO, String>((ref, accountNo) =>
  ref.watch(apiServiceProvider).getAccount(accountNo));

// Beneficiaries
final beneficiariesProvider = FutureProvider.family<List<BeneficiaryDTO>, String>((ref, accountNo) =>
  ref.watch(apiServiceProvider).getBeneficiaries(accountNo));

// Filtered Transactions
final filteredTransactionsProvider = StateNotifierProvider<FilteredTransactionsNotifier, TransactionFilter>((ref) =>
  FilteredTransactionsNotifier());
```

**Sprint 2 Deliverable Date:** April 9, 2026

---

### SPRINT 3: Advanced Features & Compliance (Weeks 5-6)

#### Planned Features
- [ ] **KYC Document Upload**
  - Document type selector (PAN, Aadhaar, Passport, etc.)
  - Camera capture / File picker
  - Selfie with document verification
  - Submission status tracking
  - *Backend API:* `POST /api/customers/{customerId}/kyc/documents`

- [ ] **Biometric Authentication**
  - Fingerprint login
  - Face ID login (iOS)
  - Fallback to password
  - Biometric re-authentication for sensitive ops
  - *Package:* `local_auth: ^2.1.0`

- [ ] **Transaction Alerts**
  - Real-time alert notifications
  - Alert history
  - Alert actions (confirm, dismiss, investigate)
  - Rule-based filtering (large transactions, unusual activity)
  - *Backend API:* `GET /api/accounts/{accountNumber}/alerts`

- [ ] **Recurring Transfers UI**
  - Setup recurring payment
  - Manage existing recurring transfers
  - Pause/Resume options
  - Next scheduled date display
  - *Backend API:* `POST /api/transactions/recurring` (new backend)

- [ ] **Bill Payment Stub**
  - Bill payment submission UI
  - Provider selection
  - Bill reference tracking
  - Payment history
  - *Backend API:* `POST /api/payments/bills` (new backend)

#### Data Models to Add
```dart
@JsonSerializable()
class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? status;
  final String? searchTerm;
}

@JsonSerializable()
class RecurringTransferUI {
  final RecurringTransferDTO data;
  final String nextScheduledFormatted;
  final int transactionsProcessed;
  final int transactionsFailed;
}
```

**Sprint 3 Deliverable Date:** April 23, 2026

---

### SPRINT 4: Personalization & Analytics (Weeks 7-8)

#### Planned Features
- [ ] **User Dashboard Customization**
  - Hide/show account cards
  - Reorder accounts
  - Set primary account
  - Save preferences
  - *Storage:* SharedPreferences or local SQLite

- [ ] **Spending Analytics**
  - Spending by category (pie chart)
  - Monthly trend (line chart)
  - Top recipients
  - Average transaction amount
  - *Visualization:* `fl_chart: ^0.65.0`

- [ ] **Account Statements Export**
  - PDF download
  - CSV export
  - Email statement
  - Date range selection
  - *Backend API:* `GET /api/accounts/{accountNumber}/statement/export`

- [ ] **Multi-Language Support**
  - English (en)
  - Hindi (hi)
  - Tamil (ta)
  - Telugu (te)
  - *Package:* `intl: ^0.19.0` + localization files

- [ ] **Dark Mode Improvement**
  - System preference detection
  - Manual theme toggle
  - OLED dark optimization
  - *Implementation:* Update `AppTheme.darkTheme`

#### Advanced Features (Nice-to-Have)
- [ ] Push Notifications (Firebase Cloud Messaging)
- [ ] In-app Chat (Bank support)
- [ ] QR Code Transfer (Dynamic QR generation)
- [ ] Voice Authentication (Post-Sprint evaluation)

**Sprint 4 Deliverable Date:** May 7, 2026

---

## 🔗 Frontend-Backend Synchronization Matrix

### Current Phase (MVP)
| Feature | Frontend Status | Backend Status | API Deployed | Notes |
|---------|---|---|---|---|
| Login/Register | ✅ DONE | ✅ DONE | ✅ YES | JWT auth working |
| Account Display | ✅ DONE | ✅ DONE | ✅ YES | List & details |
| Transactions | ✅ DONE | ✅ DONE | ✅ YES | History only |
| Send Money | ✅ DONE | ✅ DONE | ✅ YES | Direct transfer |
| KYC Status | ✅ DONE | ✅ DONE | ✅ YES | Read-only |

### Sprint 2 Coordination
| Feature | Frontend | Backend | Target Date | Block? |
|---------|---|---|---|---|
| Beneficiaries | 🔄 IN PROGRESS | ⏳ TODO | Mar 26 | No (fallback to direct account) |
| Transaction Filters | 🔄 IN PROGRESS | ⏳ TODO | Mar 26 | No (client-side filtering initially) |
| Document Upload | ⏳ TODO | ⏳ TODO | Apr 2 | Yes (blocks KYC completion) |

### Sprint 3+ Coordination
| Feature | Frontend | Backend | Block? |
|---------|---|---|---|
| Recurring Transfers | ⏳ TODO | ⏳ TODO (Queue-based) | No (standard API fallback) |
| Bill Payments | ⏳ TODO | ⏳ TODO | No (can wait on backend) |
| Fraud Alerts | ⏳ TODO | ⏳ TODO | No (nice-to-have) |

---

## 🎨 UI/UX Specifications

### Color Palette
```dart
Primary:    #6366F1 (Indigo)      - Actions, CTAs
Success:    #10B981 (Emerald)     - Positive actions
Warning:    #F59E0B (Amber)       - Warning states
Danger:     #EF4444 (Red)         - Errors, debit
Neutral:    #6B7280 (Gray)        - Secondary text
Background: #F9FAFB (Light)       - Page background
```

### Typography
- **Family:** Poppins (Google Fonts)
- **Weights:** 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Sizes:**
  - H1 (Headlines): 32sp
  - H2 (Section Headers): 24sp
  - Title: 18sp
  - Body: 16sp
  - Small: 14sp
  - Caption: 12sp

### Spacing System (8dp baseline)
- xs: 4dp
- sm: 8dp
- md: 16dp
- lg: 24dp
- xl: 32dp
- 2xl: 48dp

### Component Specifications

**Buttons:**
- Height: 56dp
- Corner Radius: 12dp
- Padding: 16dp horizontal, 14dp vertical
- States: Enabled, Disabled, Loading, Active

**Input Fields:**
- Height: 56dp
- Corner Radius: 12dp
- Border: 1dp solid #E5E7EB
- Focus Border: 2dp solid #6366F1
- Padding: 16dp horizontal, 14dp vertical

**Cards:**
- Corner Radius: 16dp
- Elevation: 1-2dp shadow
- Padding: 16-24dp
- States: Resting, Hover, Active, Disabled

---

## 🔐 Security Implementation

### Authentication Flow
```
1. User enters credentials
2. POST /api/auth/login (email, password in body)
3. Backend returns JWT token
4. Token stored in flutter_secure_storage
5. Token attached to all requests via interceptor
6. On 401: Auto-refresh token or redirect to login
```

### Data Security
- ✅ JWT tokens in secure storage (not SharedPreferences)
- ✅ No sensitive data in logs (logger sanitization)
- ✅ HTTPS enforcement (update API service)
- ✅ Biometric re-auth for sensitive operations
- 🔄 Certificate pinning (future: post-Sprint 1)
- 🔄 End-to-end encryption (future: post-quantum ready)

### Permissions Required
- **Android:**
  - `INTERNET` - API calls
  - `USE_BIOMETRIC` - Fingerprint auth
  - `CAMERA` - Document capture & selfie
  - `READ_EXTERNAL_STORAGE` - File picker

- **iOS:**
  - NSBiometricUsageDescription
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription

---

## 📊 Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| App Startup | < 2s | ~3s (splash delay) |
| Screen Load | < 1s | Varies (network-dependent) |
| First API Call | < 500ms | ~1-2s (local testing) |
| Smooth Animations | 60fps | ✅ Achieved |
| App Size | < 30MB | ~25MB (estimate) |
| Memory (Idle) | < 100MB | ~95MB (estimate) |

### Optimization Roadmap
- [ ] Lazy load screens (Navigator-based)
- [ ] Cache API responses (local SQLite)
- [ ] Image compression
- [ ] Code splitting (multiple APKs)
- [ ] Minify & optimize production builds

---

## 🧪 Testing Strategy

### Unit Tests (Data Layer)
```dart
// tests/data/services/api_service_test.dart
- Test each API method with mock Dio
- Validate request payload
- Validate response parsing
- Test error handling
```

### Widget Tests (UI Layer)
```dart
// tests/presentation/screens/...
- Test screen rendering
- Test user interactions (button taps, form input)
- Test state changes
- Test error displays
```

### Integration Tests (End-to-End)
```dart
// integration_test/app_test.dart
- Test complete login flow
- Test account loading
- Test transfer submission
- Test error recovery
```

### Manual Test Cases
See [Testing Matrix](TESTING_MATRIX.md) (TODO)

---

## 🚀 Deployment Plan

### Development Environment
- Flutter channel: **stable** (default)
- Min SDK: Android 21 (API 21), iOS 12.0
- Target SDK: Android 34, iOS 17.0

### Staging Environment
- Deploy to Firebase App Distribution
- Testflight for iOS beta testers

### Production Environment
- Google Play Store (Android)
- Apple App Store (iOS)
- Version: 1.0.0+1 (initial)

### Release Schedule
- **Alpha (Internal):** March 26, 2026
- **Beta (Public):** April 2, 2026
- **GA (Production):** April 23, 2026

---

## 📞 Support & Maintenance

### Monitoring
- Sentry for crash reporting
- Firebase Analytics for user behavior
- Custom logging for API issues

### Issue Triage
- P0 (Critical): Security, data loss → Fix same day
- P1 (High): Auth failure, money transfer issues → Fix within 24h
- P2 (Medium): UI glitches, non-critical features → Fix within 1 week
- P3 (Low): Polish, minor improvements → Backlog

### User Support
- In-app help screen (FAQ)
- Contact form → Support ticket
- Phone support (future)

---

## 📚 Documentation

### For Developers
- [README.md](README.md) - Project overview
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Installation & configuration
- Code comments (every method)
- API integration examples

### For QA
- Test automation framework setup
- Manual testing checklists
- Device compatibility matrix
- Localization testing guide

### For Product
- Feature releases notes
- Analytics dashboard
- User feedback summary
- Roadmap progress

---

## 🎯 Success Metrics

By end of Sprint 1:
- ✅ App runs smoothly on Android & iOS
- ✅ All auth flows work (register, login, logout)
- ✅ Account data displays correctly
- ✅ Transfers submit successfully
- ✅ < 5 critical bugs in beta testing
- ✅ Average session duration > 2 minutes

By end of Sprint 4:
- 📈 10,000+ downloads
- ⭐ 4.5+ star rating
- 📊 50%+ monthly active users retention
- 💰 Average user makes 5+ transfers/month
- 🔒 Zero security incidents

---

**Maintained by:** Flutter Frontend Team  
**Last Review:** March 12, 2026  
**Next Review:** March 26, 2026 (Post-Sprint 1)
