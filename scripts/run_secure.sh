#!/bin/bash
# Secure run script for SiteBook Flutter app development
# Usage: ./scripts/run_secure.sh [device_id]

set -e  # Exit on any error

DEVICE_ID=${1:-""}

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📋 Copy .env.example to .env and fill in your API keys:"
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your actual keys"
    exit 1
fi

# Load API keys from .env file (ignore comments and empty lines)
while IFS='=' read -r key value; do
    if [[ $key =~ ^[A-Z_]+$ ]] && [[ ! -z "$value" ]]; then
        export "$key"="$value"
    fi
done < <(grep -E '^[A-Z_]+=' .env)

# Detect platform and select appropriate API key
if [[ "$DEVICE_ID" == *"android"* ]] || [[ "$DEVICE_ID" == *"emulator"* ]]; then
    PLATFORM="android"
    API_KEY="$GOOGLE_MAPS_ANDROID_API_KEY"
    KEY_TYPE="Android"
elif [[ "$DEVICE_ID" == *"ios"* ]] || [[ "$DEVICE_ID" == "" ]]; then
    PLATFORM="ios" 
    API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
    KEY_TYPE="iOS"
else
    # Auto-detect by available devices
    if flutter devices | grep -q "android"; then
        PLATFORM="android"
        API_KEY="$GOOGLE_MAPS_ANDROID_API_KEY"
        KEY_TYPE="Android"
    else
        PLATFORM="ios"
        API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
        KEY_TYPE="iOS"
    fi
fi

# Validate API key for selected platform
if [ -z "$API_KEY" ]; then
    echo "❌ Google Maps $KEY_TYPE API key not set in .env file"
    exit 1
fi

# Warn about placeholder keys
if [[ "$API_KEY" == *"your_"*"_api_key_here" ]]; then
    echo "⚠️  Using placeholder API key - maps may not work properly"
    echo "💡 Get a real Google Maps API key from: https://console.cloud.google.com/"
fi

echo "🚀 Running SiteBook on $KEY_TYPE with secure API key..."

# Run with API keys passed securely
if [ -n "$DEVICE_ID" ]; then
    flutter run -d "$DEVICE_ID" \
        --dart-define=GOOGLE_MAPS_API_KEY="$API_KEY" \
        --dart-define=RECREATION_GOV_API_KEY="$RECREATION_GOV_API_KEY"
else
    flutter run \
        --dart-define=GOOGLE_MAPS_API_KEY="$API_KEY" \
        --dart-define=RECREATION_GOV_API_KEY="$RECREATION_GOV_API_KEY"
fi