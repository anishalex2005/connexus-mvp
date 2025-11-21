#!/bin/bash
set -e
FLAVOR=$1
if [ -z "$FLAVOR" ]; then
  echo "Usage: ./build_apk.sh [development|staging|production]"
  exit 1
fi
echo "Building APK for $FLAVOR..."
flutter build apk --flavor $FLAVOR --target lib/main_${FLAVOR}.dart
echo "APK build complete."


