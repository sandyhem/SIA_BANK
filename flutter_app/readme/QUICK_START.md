# 🎯 Quick Reference - Running SIA Bank Flutter App

## ⚡ Ultra-Quick (Copy-Paste)

### On macOS/Linux:
```bash
cd /path/to/SIA_BANK/flutter_app

# One-time setup:
./readme/setup.sh

# Run the app:
./readme/run_app.sh
```

### On Windows (PowerShell):
```powershell
cd C:\path\to\SIA_BANK\flutter_app

# One-time setup:
flutter pub get
dart run build_runner build

# Run the app:
flutter run
```

---

## 📋 Step-by-Step

### 1️⃣ Prerequisites
- [ ] Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- [ ] Android emulator **OR** iOS simulator **OR** physical device
- [ ] Backend services running (8080, 8081, 8082)

### 2️⃣ Setup (First Time Only)
```bash
cd flutter_app
flutter pub get                  # Install dependencies
dart run build_runner build      # Generate code
```

### 3️⃣ Configure Backend URL
**File:** `lib/core/constants/app_constants.dart`

```dart
// Use localhost if services are on same machine
static const String authBaseUrl = 'http://localhost:8080';

// Use your IP if services are on different machine
// static const String authBaseUrl = 'http://192.168.1.100:8080';
```

Get your IP:
- Windows: `ipconfig` → look for "IPv4 Address"
- Mac/Linux: `ifconfig` → look for "inet"

### 4️⃣ Start Emulator/Simulator

**Android Emulator:**
```bash
emulator -avd Pixel_6_API_33 &
```

**iOS Simulator (macOS only):**
```bash
open -a Simulator
```

### 5️⃣ Run the App
```bash
flutter run
```

**Or with options:**
```bash
flutter run -d emulator-5554              # Specify device
flutter run --release                     # Production build
flutter run -v                            # Verbose logging (debugging)
```

---

## 🎮 Controls During Development

| Key | Action |
|-----|--------|
| `r` | Hot reload (fast, keeps state) |
| `R` | Full restart (clears state) |
| `v` | Open DevTools in browser |
| `w` | Toggle widget inspector |
| `q` | Quit app |
| `p` | Toggle debug paint |
| `i` | Toggle widget inspector |

---

## 🏪 Test Credentials

Use these after first launch:

| Field | Value |
|-------|-------|
| Username | `john.doe` |
| Password | `password123` |

*(Ensure accounts exist in backend KYC)*

---

## 📱 Select Device to Run On

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Examples:
flutter run -d emulator-5554              # Android emulator
flutter run -d D5BFBFGH                   # Physical Android phone
flutter run -d iPhone-SE                  # iOS simulator
flutter run -d "All iPhones"              # iOS device
```

---

## 🐛 Troubleshooting

### Problem: "No devices found"
```bash
# Android: Start emulator
emulator -list-avds                       # List available
emulator -avd <name> &                    # Start one

# iOS: Start simulator
open -a Simulator
```

### Problem: "Cannot connect to backend"
```bash
# Check if services are running
curl http://localhost:8080/api/auth/health

# Update API URL in constants if needed
# Make sure firewall allows ports 8080-8082
```

### Problem: "Build failed - Gradle error"
```bash
flutter clean
flutter pub get
flutter run
```

### Problem: "Code generation missing"
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🔄 Typical Development Workflow

```bash
# 1. Terminal 1: Start emulator/simulator
emulator -avd Pixel_6_API_33 &

# 2. Terminal 2: Start backend services
cd auth && mvn spring-boot:run       # Port 8080
# (In other terminals: account-service on 8081, transaction-service on 8082)

# 3. Terminal 3: Run Flutter app
cd flutter_app && flutter run

# 4. In Terminal 3: Use 'r' to reload after code changes
# 5. Check backend logs in Terminal 2 for API calls
```

---

## 📊 Build Outputs

### Debug APK (Android):
```bash
flutter build apk --debug
# Output: build/app/outputs/apk/debug/app-debug.apk
```

### Release APK (Android):
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### App Bundle (Android - for Play Store):
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only):
```bash
flutter build ios --release
# Output: build/ios/Release-iphoneos/Runner.app
# Then use Xcode to archive and upload to App Store
```

---

## 🌐 Environment Variables (Optional)

Create `.env` file in `flutter_app/`:
```
FLUTTER_BUILD_MODE=release
AUTH_SERVICE_URL=http://localhost:8080
ACCOUNT_SERVICE_URL=http://localhost:8081
TRANSACTION_SERVICE_URL=http://localhost:8082
```

Then load in code (requires setup, usually not needed for MVP).

---

## ⏱️ Expected Times

| Step | Time |
|------|------|
| First setup | 2-3 min |
| Start emulator | 10-20 sec |
| `flutter run` (first)| 30-60 sec |
| Hot reload `r` | 1-2 sec |
| Full restart `R` | 5-10 sec |

---

## 🎯 Success Indicators

✅ **App is running when you see:**
- Splash screen with "SIA Bank" logo
- Redirects to Login screen after 3 sec
- No red error banners

✅ **Backend connected when:**
- Login succeeds with test credentials
- Accounts load with real balance data
- Transfer submits without API errors

---

## 📖 Full Documentation

For more details, see:
- `RUN_INSTRUCTIONS.md` - Complete setup guide
- `README.md` - Project overview
- `SETUP_GUIDE.md` - Configuration details
- `FRONTEND_ROADMAP.md` - Development plan

---

**Last Updated:** March 12, 2026  
**Quick Ref v1.0**
