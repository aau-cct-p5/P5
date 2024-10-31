#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Install CocoaPods using Homebrew
brew install cocoapods

# Set Flutter version
FLUTTER_VERSION="3.24.4-stable"

# Set Flutter directory
FLUTTER_DIR="$HOME/flutter"

# Download Flutter SDK
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}.zip -o flutter.zip

# Unzip Flutter SDK
unzip -q flutter.zip -d $HOME

# Remove the zip file after extraction
rm flutter.zip

# Export Flutter to PATH
export PATH="$PATH:$FLUTTER_DIR/bin"

# Verify Flutter installation
flutter doctor

# Navigate to your Flutter app directory
cd "/Volumes/workspace/repository/flutter_app"

# Get Flutter packages
flutter pub get

# Navigate to the iOS directory
cd ios

# Install CocoaPods dependencies
pod install --repo-update

# Navigate back to the Flutter app directory
cd ..

# Build iOS app with code signing disabled
flutter build ios --no-codesign