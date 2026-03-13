# 🚀 How to Run SIA Bank Flutter App

This guide covers running the Flutter application on your local development machine. The steps below were verified on Linux desktop for this repository.

## ⚡ Quick Start (5 minutes)

### Step 1: Install Flutter SDK
**macOS/Linux:**
```bash
# Download Flutter locally (verified path used in this repo)
cd /home/inba
git clone https://github.com/flutter/flutter.git -b stable flutter-sdk
export PATH="$PATH:/home/inba/flutter-sdk/bin"
export FLUTTER_CMD=/home/inba/flutter-sdk/bin/flutter

# Verify installation
$FLUTTER_CMD --version
```

**Windows:**
- Download from: https://flutter.dev/docs/get-started/install/windows
- Add Flutter bin folder to PATH manually
- Verify: `/home/inba/flutter-sdk/bin/flutter --version`

### Step 2: Install Project Dependencies
```bash
cd /home/inba/SIA_BANK/flutter_app

# Install Dart packages
$FLUTTER_CMD pub get
```

Note: `$FLUTTER_CMD pub get` is sufficient for the current checked-in project state.

### Step 3: Update Backend API URLs
**File:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
   static const String authBaseUrl = 'http://localhost:8083/auth';
   static const String accountBaseUrl = 'http://localhost:8081';
   static const String transactionBaseUrl = 'http://localhost:8082';
  // ...
}
```

These values now match the repository startup script in `docs_and_scripts/start-services.sh`.

### Step 4: Start Backend Services
```bash
cd /home/inba/SIA_BANK
./docs_and_scripts/start-services.sh
```

Expected local endpoints:
- Auth service: `http://localhost:8083/auth`
- Account service: `http://localhost:8081`
- Transaction service: `http://localhost:8082`

### Step 5: Run the App

#### Verified Linux Desktop Command
```bash
cd /home/inba/SIA_BANK/flutter_app
/home/inba/flutter-sdk/bin/flutter run -d linux
```

#### On Android Emulator
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd <emulator-name>

# Run app
$FLUTTER_CMD run
```

#### On iOS Simulator (macOS only)
```bash
# Start simulator
open -a Simulator

# Run app
$FLUTTER_CMD run
```

#### On Physical Device
```bash
# Enable Developer Mode on device
# For Android: Settings > Developer Options > USB Debugging
# For iOS: Xcode > Preferences > Accounts > Add Apple ID

# Connect device via USB and run
$FLUTTER_CMD run
```

---

## 🎯 Detailed Setup Instructions

### Prerequisites Checklist

- [ ] Flutter SDK installed
- [ ] Linux desktop toolchain or Android/iOS setup
- [ ] Backend services running (ports 8080, 8081, 8082)
- [ ] Git & basic command-line knowledge

For this repository, update the auth port item above to `8083`.

### Full Installation Guide

#### 1. Install Java (for Android development)
**macOS:**
```bash
brew install java
# Add to ~/.zshrc or ~/.bash_profile:
export JAVA_HOME=$(/usr/libexec/java_home)
```

**Linux:**
```bash
sudo apt-get install openjdk-11-jdk
```

**Windows:**
- Download JDK 11+ from https://www.oracle.com/java/technologies/javase-downloads.html
- Add JAVA_HOME to environment variables

#### 2. Install Android Studio
1. Download from: https://developer.android.com/studio
2. Run installer and follow setup wizard
3. Install Android SDK:
   - API 34 (latest)
   - API 21+ (minimum)
4. Android Emulator setup:
   - Tools > Device Manager
   - Create Virtual Device with API 29+

#### 3. Install Flutter
**Official Install:** https://flutter.dev/docs/get-started/install

**Quick Method (macOS):**
```bash
brew install flutter
$FLUTTER_CMD doctor
```

**Quick Method (Linux):**
```bash
sudo snap install flutter --classic
$FLUTTER_CMD doctor
```

#### 4. Enable Developer Mode & USB Debugging (Physical Device)

**Android:**
1. Settings > About Phone > Tap Build Number 7 times
2. Settings > Developer Options > Enable USB Debugging
3. Connect phone via USB
4. `$FLUTTER_CMD devices` (should see your phone)

**iOS:**
1. Xcode > Preferences > Accounts > Add Apple ID
2. Settings > Developer > Enable Developer Mode
3. Trust the certificate when prompted
4. Settings > General > VPN & Device Management > Trust certificate

---

## ✅ Verification Steps

### Check Flutter Setup
```bash
$FLUTTER_CMD doctor
```

**Expected output:**
```
[✓] Flutter (latest)
[✓] Android toolchain
[✓] Xcode (if on macOS)
[✓] VS Code
[✓] Connected device
```

### Check App Dependencies
```bash
cd flutter_app
$FLUTTER_CMD pub get

# Should show "Got dependencies"
```

### Test Backend Connection
Update API URLs and run:
```bash
$FLUTTER_CMD run --verbose
```

Watch for successful login endpoint calls in logs.

For this repository, an HTTP `400` from registration means the frontend is connected to the auth backend, but the backend rejected the request body.
The auth service expects `firstName` and `lastName`. The Flutter client now sends these fields directly from separate First Name and Last Name inputs.

---

## 🏃 Running the App

### Development Mode (with Hot Reload)
```bash
$FLUTTER_CMD run
```

**In terminal, you can now:**
- Press `r` - Hot reload (fast, keeps state)
- Press `R` - Full restart (clears state)
- Press `v` - Open DevTools
- Press `q` - Quit app

### Production Mode
```bash
$FLUTTER_CMD run --release
```

### With Verbose Logging (for debugging)
```bash
$FLUTTER_CMD run -v
```

### Build Only (without running)
```bash
$FLUTTER_CMD build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

---

## 🐛 Common Issues & Fixes

### Issue: "No devices found"
```bash
$FLUTTER_CMD devices
```
**Fix:** Make sure emulator is running or physical device is connected with USB debugging enabled.

### Issue: "Gradle build failed"
```bash
$FLUTTER_CMD clean
$FLUTTER_CMD pub get
$FLUTTER_CMD run
```

### Issue: "API connection refused"
Check backend services:
```bash
cd /home/inba/SIA_BANK
./docs_and_scripts/start-services.sh
```

If you still see connection errors, verify that the auth service is on `http://localhost:8083/auth` rather than `8080`.

### Issue: "Registration failed" with HTTP 400
This usually means the frontend reached the backend successfully, but the backend rejected the request because of validation or business rules.

Verified auth backend registration contract:
- Endpoint: `POST http://localhost:8083/auth/api/auth/register`
- Required fields: `username`, `password`, `email`, `firstName`, `lastName`
- Common backend rejections: missing `firstName` or `lastName`, invalid email, duplicate username, duplicate email

Current Flutter behavior:
- The UI collects `First Name` and `Last Name` directly
- The app sends `firstName` and `lastName` in the registration payload

Important distinction:
- `Connection refused` means the frontend is not connected to the backend
- `400 Bad Request` means the frontend is connected, but the backend rejected the submitted data

### Issue: "RenderFlex overflowed"
The splash screen and login social buttons were adjusted for Linux desktop window sizes. If this returns, enlarge the Linux window and rerun `$FLUTTER_CMD clean && $FLUTTER_CMD run -d linux`.

### Issue: "JSON Serialization code not generated"
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Issue: "Permission denied" on Linux
```bash
chmod +x /home/inba/flutter-sdk/bin/flutter
```

---

## 📱 Testing on Different Devices

### Android Emulator
```bash
# Pixel 6 with Android 13
emulator -avd Pixel_6_API_33 &
$FLUTTER_CMD run
```

### iOS Simulator
```bash
# iPhone 14 Pro
open -a Simulator
$FLUTTER_CMD run
```

### Physical Android Device
```bash
# Enable USB Debugging (see above)
adb devices  # Should list your phone
$FLUTTER_CMD run -d <device-id>
```

### Physical iOS Device
```bash
# Connect iPhone, trust certificate
$FLUTTER_CMD run -d <device-uuid>
```

---

## 🔐 Important: Update Backend URLs

**File:** `lib/core/constants/app_constants.dart`

Replace localhost with your actual IP (if services are on different machine):

```dart
// Local development
static const String authBaseUrl = 'http://localhost:8083/auth';

// Remote development (replace 192.168.1.100 with your IP)
// static const String authBaseUrl = 'http://192.168.1.100:8083/auth';

// With port forwarding (if using SSH)
// ssh -L 8083:localhost:8083 -L 8081:localhost:8081 -L 8082:localhost:8082 user@server
```

---

## 📊 Test User Credentials

After app starts, use these to log in:

**Test Account 1:**
- Username: `john.doe`
- Password: `password123`

**Test Account 2:**
- Username: `jane.smith`
- Password: `password456`

*(Note: Ensure these are created in backend first)*

---

## 💾 Saving & Hot Reload Workflow

1. Make a change to `lib/presentation/screens/home_screen.dart`
2. Save file (Ctrl+S / Cmd+S)
3. Press `r` in terminal
4. App reloads in < 1 second
5. See your changes instantly

This is the power of Flutter's hot reload! 🔥

---

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Syntax Guide](https://dart.dev/guides/language/language-tour)
- [Material 3 Components](https://m3.material.io)
- [Riverpod State Management](https://riverpod.dev)

---

## 🆘 Need Help?

1. **Run `$FLUTTER_CMD doctor` again** - Shows any missing dependencies
2. **Check logs:** `$FLUTTER_CMD run -v` - Verbose output
3. **Review backend logs** - Ensure APIs are responding
4. **Check firewall** - Ports 8080-8082 must be accessible
5. **Update Flutter:** `/home/inba/flutter-sdk/bin/flutter upgrade`

---

## ✨ What to Expect

### First Run:
1. Splash screen appears (3 seconds)
2. Redirects to Login screen
3. You can register or login

### After Login:
1. Home dashboard loads with accounts
2. Tap "Send Money" to test transfers
3. View transaction history

### Backend Integration Working When:
- ✅ Login succeeds with real credentials
- ✅ Accounts load with actual balances
- ✅ Transfers print success message
- ✅ No API error messages in logs

---

**Ready to run?** Start with `$FLUTTER_CMD run` and watch the magic happen! ✨

Last updated: March 12, 2026
