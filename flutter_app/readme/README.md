# SIA Bank Flutter Mobile App

A modern, secure banking application built with Flutter, featuring fund transfers, account management, transaction tracking, and more—inspired by Google Pay and other leading fintech applications.

## 🎯 Features

### Phase 1: MVP (Current)
- ✅ User Authentication (Login/Register)
- ✅ Multi-account Dashboard
- ✅ Real-time Account Balance Display
- ✅ Fund Transfers (Account-to-Account)
- ✅ Transaction History
- ✅ Quick Actions (Send Money, Request, Pay Bills)
- ✅ Secure Token Storage
- ✅ Health Checks for Backend Services

### Phase 2: Enhanced Banking
- 🔄 Recurring Transfers/Auto-Pay
- 🔄 Bill Payment Integration
- 🔄 Beneficiary Management
- 🔄 KYC Document Upload
- 🔄 Transaction Alerts & Fraud Detection
- 🔄 Account Statement Export (PDF/CSV)
- 🔄 Biometric Authentication

### Phase 3: Advanced Features
- 🔜 Credit/Overdraft Facilities
- 🔜 Investment & Savings Accounts
- 🔜 Loan Management
- 🔜 Personal Finance Dashboard
- 🔜 Multi-currency Support

## 🏗️ Architecture

### Tech Stack
- **Framework:** Flutter 3.x
- **State Management:** Riverpod (FutureProvider, StateProvider)
- **HTTP Client:** Dio with interceptors
- **Secure Storage:** flutter_secure_storage
- **Cryptography:** PointyCastle (for future PQ-safe encryption)
- **UI Components:** Material 3 + Custom Widgets
- **Responsive Design:** ScreenUtil

### Project Structure
```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart      # Centralized theme (colors, typography)
│   │   └── constants/
│   │       └── app_constants.dart  # App-wide constants
│   ├── data/
│   │   ├── models/
│   │   │   ├── auth_models.dart         # Auth DTOs (LoginRequest, RegisterRequest, etc.)
│   │   │   ├── account_models.dart      # Account DTOs
│   │   │   └── transaction_models.dart  # Transaction DTOs
│   │   └── services/
│   │       └── api_service.dart         # Dio-based HTTP client with interceptors
│   └── presentation/
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   ├── home_screen.dart         # Main dashboard
│       │   ├── auth/
│       │   │   ├── login_screen.dart
│       │   │   └── register_screen.dart
│       │   └── accounts/
│       │       ├── transfer_screen.dart
│       │       ├── accounts_list_screen.dart (Coming Soon)
│       │       └── statement_screen.dart (Coming Soon)
│       └── widgets/
│           └── custom_widgets.dart (Coming Soon)
├── assets/
│   ├── images/
│   ├── animations/
│   ├── icons/
│   └── fonts/
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.x
- A running SIA Bank backend (auth, account, transaction services)

### Backend Service URLs
Update `lib/data/services/api_service.dart` with your backend URLs:
```dart
static const String authBaseUrl = 'http://localhost:8080';
static const String accountBaseUrl = 'http://localhost:8081';
static const String transactionBaseUrl = 'http://localhost:8082';
```

### Installation & Setup

1. **Clone the repository:**
   ```bash
   cd flutter_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate JSON serialization code:**
   ```bash
   dart run build_runner build
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Screens & Navigation

### Authentication Flow
1. **SplashScreen** → Checks authentication status (3-second intro)
2. **LoginScreen** → User login with error handling
3. **RegisterScreen** → New user registration with validation

### Main App Flow
1. **HomeScreen** → Dashboard with accounts, quick actions, recent transactions
2. **TransferScreen** → Send money between accounts
3. **MoreScreens** → (Coming Soon) Profile, Settings, Help

### Navigation Routes
```dart
'/splash'   → SplashScreen
'/login'    → LoginScreen
'/register' → RegisterScreen
'/home'     → HomeScreen
'/transfer' → TransferScreen
```

## 🔐 Security Features

- **JWT Token Management:** Tokens stored securely in `flutter_secure_storage`
- **HTTPS Transport:** All API calls over encrypted HTTPS
- **Request Interceptors:** Automatic token attachment to headers
- **Secure Password Handling:** Input obscuring, validation
- **Post-Quantum Cryptography Ready:** Integration points for ML-KEM, ML-DSA

## 📡 API Integration

### Supported Endpoints

**Auth Service (Port 8080):**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/validate` - Token validation
- `GET /api/auth/user/{userId}/kyc-status` - KYC status
- `GET /api/customers/{customerId}` - Customer details
- `POST /api/customers` - Create customer profile

**Account Service (Port 8081):**
- `GET /api/accounts` - List all accounts
- `GET /api/accounts/{accountNumber}` - Get account details
- `GET /api/accounts/customer/{customerId}` - Customer's accounts
- `POST /api/accounts` - Create new account
- `PUT /api/accounts/{accNo}/debit` - Withdraw
- `PUT /api/accounts/{accNo}/credit` - Deposit

**Transaction Service (Port 8082):**
- `POST /api/transactions/transfer` - Send money
- `GET /api/transactions/account/{accountNumber}` - Transaction history

## 🎨 UI/UX Highlights

- **Material Design 3:** Modern, accessible UI components
- **Responsive Layout:** ScreenUtil for all phone sizes
- **Gradient Cards:** Beautiful account card display with multiple color themes
- **Real-time Balance:** Live balance updates from backend
- **Error Handling:** User-friendly error messages
- **Loading States:** Smooth progress indicators during API calls

## 📊 State Management with Riverpod

### Providers Used:
```dart
// Async data providers
final accountsProvider = FutureProvider(...)
final transactionHistoryProvider = FutureProvider.family(...)

// State providers
final selectedAccountProvider = StateProvider(...)

// Service provider
final apiServiceProvider = Provider(...)
```

## 🔗 API Service Usage Example

```dart
// Login
final apiService = ref.read(apiServiceProvider);
final response = await apiService.login(LoginRequest(...));

// Get accounts
final accounts = await apiService.getAllAccounts();

// Transfer funds
final result = await apiService.transferFunds(TransferRequestDTO(...));
```

## 🧪 Testing

### Manual Testing Flows:
1. **Authentication Flow:**
   - Register new user → Verify user creation
   - Login with credentials → Check token storage
   - Logout → Verify token removal

2. **Account Operations:**
   - Load accounts → Check balance display
   - View account details → Verify formatting
   - Load transaction history → Check table rendering

3. **Transfer Flow:**
   - Enter transfer details → Validate input
   - Submit transfer → Check success/error handling
   - Verify transaction appears in history

### Automated Testing (Future):
```bash
flutter test
```

## 📦 Build & Release

### Development Build:
```bash
flutter run -d <device-id>
```

### Android Release Build:
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release Build:
```bash
flutter build ios --release
```

## 🔄 Roadmap

### Sprint 1 (Weeks 1-2):
- ✅ MVP with core banking features
- ✅ Authentication & security
- ✅ Account & transaction management

### Sprint 2 (Weeks 3-4):
- 🔄 KYC document upload
- 🔄 Beneficiary management
- 🔄 Transaction alerts

### Sprint 3 (Weeks 5-6):
- 🔄 Bill payment integration
- 🔄 Recurring transfers
- 🔄 Account statement export

### Sprint 4 (Weeks 7-8):
- 🔄 Fraud detection display
- 🔄 Multi-currency support
- 🔄 Investment accounts

## 🐛 Known Issues & Limitations

1. **Splash Navigation:** Currently hardcoded to `/login` — should check stored token
2. **Error Messages:** Generic API errors displayed — should parse specific error codes
3. **Offline Mode:** Not yet implemented — requires local caching
4. **Pagination:** List endpoints don't support pagination yet
5. **Localization:** Only English supported

## 🤝 Contributing

To add new features:

1. **Create a new screen:**
   ```
   lib/presentation/screens/<feature>/<feature>_screen.dart
   ```

2. **Add API method in `api_service.dart`**

3. **Create necessary models in `lib/data/models/`**

4. **Add Riverpod provider if needed**

5. **Update navigation in `main.dart`**

## 📞 Support

For issues or feature requests:
- Check `API_INVENTORY_AND_ROADMAP.md` for backend planning
- Review `docs_and_scripts/` folder for integration guides
- Check backend logs for API errors

## 📄 License

SIA Bank © 2026. All rights reserved.

---

**Last Updated:** March 12, 2026  
**Next Review:** Post-Sprint 1
