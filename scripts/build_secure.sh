#!/bin/bash
# Secure build script for SiteBook Flutter app
# Usage: ./scripts/build_secure.sh ios|android [debug|release]

set -e  # Exit on any error

PLATFORM=${1:-ios}
BUILD_MODE=${2:-debug}

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📋 Copy .env.example to .env and fill in your API keys:"
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your actual keys"
    exit 1
fi

# Load API keys from .env file (ignore comments and empty lines)
set -o allexport
source <(grep -E '^[A-Z_]+=.*' .env)
set +o allexport

# Validate required keys
if [ -z "$GOOGLE_MAPS_IOS_API_KEY" ] && [ "$PLATFORM" = "ios" ]; then
    echo "❌ GOOGLE_MAPS_IOS_API_KEY not set in .env file"
    exit 1
fi

if [ -z "$GOOGLE_MAPS_ANDROID_API_KEY" ] && [ "$PLATFORM" = "android" ]; then
    echo "❌ GOOGLE_MAPS_ANDROID_API_KEY not set in .env file"
    exit 1
fi

# Select appropriate API key for platform
if [ "$PLATFORM" = "ios" ]; then
    API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
else
    API_KEY="$GOOGLE_MAPS_ANDROID_API_KEY"
fi

echo "🔧 Building SiteBook for $PLATFORM in $BUILD_MODE mode..."

# Build with API key passed securely
flutter build $PLATFORM \
    --$BUILD_MODE \
    --dart-define=GOOGLE_MAPS_API_KEY="$API_KEY" \
    --dart-define=RECREATION_GOV_API_KEY="$RECREATION_GOV_API_KEY"

echo "✅ Build completed successfully!"