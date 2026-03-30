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
    if [[ $key =~ ^[A-Z_]+$ ]]; then
        export "$key"="$value"
    fi
done < <(grep -E '^[A-Z_]+=.*' .env)

# Validate Google Maps API key
if [ -z "$GOOGLE_MAPS_IOS_API_KEY" ]; then
    echo "❌ GOOGLE_MAPS_IOS_API_KEY not set in .env file"
    exit 1
fi

# Warn about placeholder keys
if [ "$GOOGLE_MAPS_IOS_API_KEY" = "your_ios_api_key_here" ]; then
    echo "⚠️  Using placeholder API key - maps may not work properly"
    echo "💡 Get a real Google Maps API key from: https://console.cloud.google.com/"
fi

echo "🚀 Running SiteBook with secure API keys..."

# Run with API keys passed securely
if [ -n "$DEVICE_ID" ]; then
    flutter run -d "$DEVICE_ID" \
        --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_IOS_API_KEY" \
        --dart-define=RECREATION_GOV_API_KEY="$RECREATION_GOV_API_KEY"
else
    flutter run \
        --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_IOS_API_KEY" \
        --dart-define=RECREATION_GOV_API_KEY="$RECREATION_GOV_API_KEY"
fi