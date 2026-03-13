#!/bin/bash

# SIA Bank Flutter App - Run Script
# This script runs the Flutter app in development mode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$SCRIPT_DIR"

echo "🚀 Starting SIA Bank Flutter App..."
echo "===================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo "📖 Run: ./setup.sh"
    exit 1
fi

# Navigate to app directory
cd "$APP_DIR"

# Check for devices
DEVICE_COUNT=$(flutter devices | grep -c "device")

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No devices or emulators found!"
    echo ""
    echo "📱 Please:"
    echo "  • Start an Android emulator: emulator -avd <name>"
    echo "  • Or start iOS simulator: open -a Simulator"
    echo "  • Or connect a physical device with USB debugging enabled"
    echo ""
    echo "After connecting a device, run: flutter run"
    exit 1
fi

echo "✅ Device(s) found"
echo ""

# Run the app
echo "📱 Starting app..."
echo "💡 Press 'r' for hot reload, 'R' for full restart, 'q' to quit"
echo ""

flutter run "$@"
