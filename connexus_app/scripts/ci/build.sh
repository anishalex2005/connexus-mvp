#!/bin/bash

# ConnexUS Build Script
# This script is used by CI/CD to build the app

set -e  # Exit on error

echo "==================================="
echo "ConnexUS Build Script"
echo "==================================="

# Parse arguments
BUILD_TYPE=${1:-debug}
PLATFORM=${2:-all}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Flutter installation
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed"
        exit 1
    fi
    
    log_info "Flutter version: $(flutter --version | head -1)"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    flutter clean
    rm -rf build/
    rm -rf .dart_tool/
    rm -rf .packages
}

# Get dependencies
get_dependencies() {
    log_info "Getting dependencies..."
    flutter pub get
}

# Run tests
run_tests() {
    log_info "Running tests..."
    flutter test --coverage || {
        log_error "Tests failed"
        exit 1
    }
}

# Build Android
build_android() {
    log_info "Building Android $BUILD_TYPE..."
    
    case $BUILD_TYPE in
        debug)
            flutter build apk --debug
            log_info "Android debug APK built: build/app/outputs/flutter-apk/app-debug.apk"
            ;;
        profile)
            flutter build apk --profile
            log_info "Android profile APK built: build/app/outputs/flutter-apk/app-profile.apk"
            ;;
        release)
            flutter build apk --release
            flutter build appbundle --release
            log_info "Android release APK built: build/app/outputs/flutter-apk/app-release.apk"
            log_info "Android app bundle built: build/app/outputs/bundle/release/app-release.aab"
            ;;
        *)
            log_error "Unknown build type: $BUILD_TYPE"
            exit 1
            ;;
    esac
}

# Build iOS
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "iOS builds can only be run on macOS. Skipping iOS build."
        return
    fi
    
    log_info "Building iOS $BUILD_TYPE..."
    
    case $BUILD_TYPE in
        debug)
            flutter build ios --debug --no-codesign --simulator
            log_info "iOS debug build complete"
            ;;
        profile)
            flutter build ios --profile --no-codesign
            log_info "iOS profile build complete"
            ;;
        release)
            flutter build ios --release --no-codesign
            log_info "iOS release build complete"
            ;;
        *)
            log_error "Unknown build type: $BUILD_TYPE"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    log_info "Starting build process..."
    log_info "Build type: $BUILD_TYPE"
    log_info "Platform: $PLATFORM"
    
    check_flutter
    clean_build
    get_dependencies
    run_tests
    
    case $PLATFORM in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        all)
            build_android
            build_ios
            ;;
        *)
            log_error "Unknown platform: $PLATFORM"
            exit 1
            ;;
    esac
    
    log_info "Build completed successfully!"
}

# Run main function
main


