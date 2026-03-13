#!/bin/bash

# SIA Bank Flutter App - Quick Setup Script
# This script sets up the Flutter app for local development

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$SCRIPT_DIR"

echo "🚀 SIA Bank Flutter App - Setup"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo "📖 Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Navigate to app directory
cd "$APP_DIR"
echo "📁 Working directory: $APP_DIR"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Generate JSON serialization code
echo "🔨 Generating JSON serialization code..."
dart run build_runner build
echo "✅ Code generation complete"
echo ""

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices
echo ""

echo "✨ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Update backend API URLs in: lib/core/constants/app_constants.dart"
echo "2. Start your Flutter app with: flutter run"
echo "3. Or run the companion script: ./run_app.sh"
echo ""
echo "💡 For detailed instructions, see: RUN_INSTRUCTIONS.md"
