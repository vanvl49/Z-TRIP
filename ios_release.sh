#!/bin/bash

# Flutter iOS Release Build & Xcode Launcher Script

# Step 1: Clean build artifacts
echo "🧹 Cleaning Flutter project..."
flutter clean

# Step 2: Get dependencies
echo "📦 Getting Flutter packages..."
flutter pub get

# Step 3: Build iOS release
echo "🚀 Building Flutter iOS app in release mode..."
flutter build ios --release

# Step 4: Open project in Xcode
IOS_PROJECT_PATH="ios/Runner.xcworkspace"
if [ -d "$IOS_PROJECT_PATH" ]; then
  echo "📂 Opening Xcode workspace..."
  open "$IOS_PROJECT_PATH"
else
  echo "❌ Xcode workspace not found at: $IOS_PROJECT_PATH"
  exit 1
fi
