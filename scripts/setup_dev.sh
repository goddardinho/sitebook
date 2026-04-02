#!/bin/bash

# Development Environment Setup Script
# Run this once to set up your development environment

set -e

echo "🚀 Setting up development environment for sitebook..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first:"
    echo "  https://docs.flutter.dev/get-started/install"
    exit 1
fi

print_status "Flutter is installed"

# Install pre-commit if not available
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."

    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    elif command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v brew &> /dev/null; then
        brew install pre-commit
    else
        print_error "Cannot install pre-commit. Please install Python pip or Homebrew first"
        exit 1
    fi

    print_status "pre-commit installed"
else
    print_status "pre-commit is already installed"
fi

# Install pre-commit hooks
echo "🪝 Installing pre-commit hooks..."
pre-commit install
print_status "Pre-commit hooks installed"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get
print_status "Dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_warning ".env file created from template. Please edit it with your API keys."
    else
        print_warning "No .env.example found. You may need to create a .env file manually."
    fi
else
    print_status ".env file already exists"
fi

# Install optional tools recommendations
echo -e "\n📚 Optional development tools recommendations:"
echo "• For better coverage reports: brew install lcov (macOS) or apt-get install lcov (Linux)"
echo "• For JSON processing: brew install jq (macOS) or apt-get install jq (Linux)"
echo "• For security scanning: Consider installing snyk CLI"

# Run initial quality check
echo -e "\n🔍 Running initial quality check..."
if ./scripts/quality_check.sh; then
    print_status "Initial quality check passed!"
else
    print_warning "Initial quality check found issues. Review and fix them."
fi

echo -e "\n🎉 ${GREEN}Development environment setup complete!${NC}"
echo ""
echo "📋 Quick reference commands:"
echo "• Run quality checks: ./scripts/quality_check.sh"
echo "• Build with checks: ./scripts/build_secure.sh ios|android"
echo "• Run pre-commit on all files: pre-commit run --all-files"
echo "• Manual test run: flutter test"
echo "• Manual analysis: flutter analyze"
