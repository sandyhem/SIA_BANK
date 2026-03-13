# SIA Bank Flutter App - Setup & Configuration Guide

## 📋 Prerequisites

1. **Flutter SDK:** 3.x or higher
   ```bash
   flutter --version
   ```

2. **Dart SDK:** 3.x or higher (included with Flutter)

3. **Backend Services:** Must be running
   - Auth Service: `http://localhost:8080`
   - Account Service: `http://localhost:8081`
   - Transaction Service: `http://localhost:8082`

4. **Development Environment:**
   - Android Studio / VS Code with Flutter extension
   - Android SDK (for Android development) or Xcode (for iOS)
   - Git

---

## 🚀 Initial Setup

### Step 1: Clone Repository
```bash
cd /home/inba/SIA_BANK/flutter_app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Generate JSON Serialization Code
The app uses `json_serializable` for automatically generating JSON serialization code. Run:
```bash
dart run build_runner build
```

This will generate:
- `lib/data/models/auth_models.g.dart`
- `lib/data/models/account_models.g.dart`
- `lib/data/models/transaction_models.g.dart`

### Step 4: Verify Device Connection
```bash
flutter devices
```

You should see at least one available device (Android/iOS emulator or physical phone).

---

## ⚙️ Configuration

### Backend API URLs

Edit `lib/data/services/api_service.dart`:

```dart
class ApiService {
  static const String authBaseUrl = 'http://localhost:8080';
  static const String accountBaseUrl = 'http://localhost:8081';
  static const String transactionBaseUrl = 'http://localhost:8082';
  // ...
}
```

**Or use environment variables:**
```bash
# Create .env file
AUTH_SERVICE_URL=http://192.168.x.x:8080
ACCOUNT_SERVICE_URL=http://192.168.x.x:8081
TRANSACTION_SERVICE_URL=http://192.168.x.x:8082
```

### Android Configuration

**File:** `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

**Enable HTTPS Communication:**
Keep `usesCleartextTraffic = false` in `android/app/src/main/AndroidManifest.xml` for production.

### iOS Configuration

**File:** `ios/Podfile`
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

---

## 🏃 Running the App

### Development Mode (Hot Reload)
```bash
flutter run
```

### Run on Specific Device
```bash
flutter run -d <device-id>
```

### Release Mode (Production)
```bash
flutter run --release
```

### Run with Verbose Logging
```bash
flutter run -v
```

---

## 🔧 Troubleshooting

### Issue: "Android SDK not found"
**Solution:**
```bash
flutter doctor --android-licenses
# Accept all licenses
```

### Issue: App crashes at startup
**Check:**
1. Backend services are running
2. API URLs are correct in `api_service.dart`
3. Check logs: `flutter logs`

### Issue: "Failed to resolve 'dio'"
**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade dio
```

### Issue: JSON Serialization code not generated
**Solution:**
```bash
flutter clean
dart run build_runner build --delete-conflicting-outputs
```

### Issue: CORS errors from backend
**Backend Configuration:**
Add CORS headers in Spring Boot:
```java
@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                    .allowedOrigins("*")
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowCredentials(false)
                    .maxAge(3600);
            }
        };
    }
}
```

---

## 📱 Device Testing

### Android Emulator
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd <emulator-name>

# Run app on emulator
flutter run -d emulator-5554
```

### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Start simulator
open -a Simulator

# Run app on simulator
flutter run -d booted
```

### Physical Device
1. Enable Developer Mode
2. Connect via USB
3. ```bash
   flutter run -d <device-id>
   ```

---

## 🔐 Security Setup

### 1. HTTPS Certificate Pinning (Optional)
Add to `lib/data/services/api_service.dart`:
```dart
final httpClient = HttpClient();
httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
  // Implement certificate pinning logic
  return false;
};
```

### 2. Secure Token Storage
The app uses `flutter_secure_storage` which:
- **Android:** Uses Android Keystore
- **iOS:** Uses Keychain

Token is automatically stored at login and retrieved for API calls.

### 3. Request Signing (For PQ-Safe Future)
Placeholders in `CryptoController` for ML-DSA-65 signing:
```dart
// Future: Add signing before requests
final signature = await apiService.signRequest(request);
```

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/app_test.dart
```

### Manual Testing Checklist

**Authentication:**
- [ ] Register with valid email/password
- [ ] Register with invalid email (should show error)
- [ ] Register with mismatched passwords (should show error)
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should show error)
- [ ] Logout (token should be cleared)

**Accounts:**
- [ ] Load and display multiple accounts
- [ ] Account balances are correct
- [ ] Account types are displayed (Savings, Checking)
- [ ] Account status is shown (Active, Inactive)

**Transactions:**
- [ ] Display recent transactions for selected account
- [ ] Transaction amounts and dates are correct
- [ ] Transaction status badges display correctly

**Transfers:**
- [ ] Fill transfer form with valid data
- [ ] Submit transfer and see success message
- [ ] Try transfer with same from/to accounts (should show error)
- [ ] Try transfer with negative amount (should show error)
- [ ] Try transfer with invalid account numbers (should show error)

---

## 📊 Performance Optimization

### Build Performance
```bash
# Profile build time
flutter build apk --analyze-size

# Build faster by limiting to one architecture
flutter build apk --split-per-abi
```

### App Performance
1. **Lazy Load Screens:** Use `Navigator` with `MaterialPageRoute`
2. **Cache API Responses:** Implement caching in `api_service.dart`
3. **Optimize Images:** Use appropriate image sizes
4. **Profile App:** 
   ```bash
   flutter run --profile
   ```

---

## 📦 Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Android App Bundle
```bash
flutter build appbundle --release
# Output: build/app/outputs/appbundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Follow Xcode archiving steps for iOS distribution
```

---

## 🔄 Hot Reload & Hot Restart

### Hot Reload (Fast - keeps state)
Press `R` in terminal while running

### Hot Restart (Refreshes app - clears state)
Press `Shift + R` in terminal

---

## 📝 Useful Commands

```bash
# Clean everything
flutter clean

# Upgrade all dependencies
flutter pub upgrade

# Check for dependency updates
flutter pub outdated

# Get app size info
flutter build apk --analyze-size

# Lint code
dart analyze

# Format code
dart format lib/

# Run specific file
flutter test lib/data/services/api_service_test.dart
```

---

## 🚨 Common Errors & Solutions

| Error | Solution |
|-------|----------|
| `Cannot find device` | Run `flutter devices` and ensure device is connected |
| `API 401 Unauthorized` | Token expired - logout and login again |
| `Network refused` | Check backend services are running |
| `JSON parse error` | Regenerate serialization: `dart run build_runner build` |
| `Module not found` | Run `flutter pub get` |

---

## 📚 Resources

- [Flutter Official Docs](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Material Design 3](https://m3.material.io)

---

## 🤝 Contributing

When adding new features:

1. **Create a new branch:**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Follow Dart style guide:**
   ```bash
   dart format lib/
   dart analyze
   ```

3. **Add tests for new features**

4. **Run before committing:**
   ```bash
   flutter test
   flutter analyze
   ```

---

**Last Updated:** March 12, 2026  
**Maintained by:** SIA Bank Development Team
