#!/bin/bash
set -e
FLAVOR=$1
if [ -z "$FLAVOR" ]; then
  echo "Usage: ./build_ios.sh [development|staging|production]"
  exit 1
fi
echo "Building iOS for $FLAVOR..."
flutter build ios --flavor $FLAVOR --target lib/main_${FLAVOR}.dart
echo "iOS build complete. Archive from Xcode for distribution."


