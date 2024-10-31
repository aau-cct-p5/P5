#!/bin/sh

# Install CocoaPods using Homebrew.
brew install cocoapods

# Install Flutter without sudo
# Set Flutter version
FLUTTER_VERSION="3.24.4-stable"

# Set Flutter directory
FLUTTER_DIR="$HOME/flutter"

# Download Flutter SDK
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}.zip -o flutter.zip

# Unzip Flutter SDK
unzip -q flutter.zip -d $HOME

# Export Flutter to PATH
export PATH="$PATH:$FLUTTER_DIR/bin"

# Verify Flutter installation
flutter doctor

# Navigate to your Flutter app directory
cd "$CI_WORKSPACE/repository/flutter_app"

# Get Flutter packages
flutter pub get

# Build iOS app without code signing
flutter build ios --no-codesign
