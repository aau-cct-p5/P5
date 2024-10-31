#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# =============================
# 1. Install CocoaPods
# =============================

echo "Installing CocoaPods via Homebrew..."
brew install cocoapods

# Verify CocoaPods installation
echo "Verifying CocoaPods installation..."
pod --version

# =============================
# 2. Install Flutter via Homebrew
# =============================

echo "Installing Flutter via Homebrew..."
brew install flutter

# Verify Flutter installation
echo "Verifying Flutter installation..."
flutter --version

# Ensure Flutter is on PATH (Homebrew typically adds it automatically)
# If not, uncomment the following line to add it manually
# export PATH="$PATH:$(brew --prefix flutter)/bin"

# =============================
# 3. Setup Flutter Environment
# =============================

echo "Running flutter doctor..."
flutter doctor

# =============================
# 4. Navigate to Flutter App Directory
# =============================

# Update this path if your repository structure differs
FLUTTER_APP_DIR="/Volumes/workspace/repository/flutter_app"

echo "Navigating to Flutter app directory: $FLUTTER_APP_DIR"
cd "$FLUTTER_APP_DIR"

# =============================
# 5. Get Flutter Dependencies
# =============================

echo "Fetching Flutter dependencies..."
flutter pub get

# =============================
# 6. Prepare iOS Environment
# =============================

echo "Navigating to iOS directory..."
cd ios

echo "Installing CocoaPods dependencies..."
pod install --repo-update

# Optionally, you can add debug steps to verify pod installation
echo "Listing installed CocoaPods..."
pod list

# Navigate back to Flutter app directory
cd ..

# =============================
# 7. Build iOS Application
# =============================

echo "Building iOS application without code signing..."
flutter build ios --no-codesign

# Optionally, you can add verbose logging for debugging
# flutter build ios --no-codesign --verbose

# =============================
# 8. Finalize
# =============================

echo "CI Post Clone Script Execution Completed Successfully."