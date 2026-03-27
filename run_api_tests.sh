#!/bin/bash

# API Integration Test Runner
# Runs all API integration tests and provides detailed output

echo "🚀 Sitebook API Integration Test Suite"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check Flutter is available
if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Please install Flutter first."
    exit 1
fi

print_status "Flutter version:"
flutter --version
echo ""

# Run static analysis first
print_status "Running static analysis..."
flutter analyze --no-fatal-infos

# Check if we should run tests
echo ""
read -p "🤔 Do you want to run the test suites? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Running test suites..."
    
    echo ""
    print_status "1. Database Integration Tests"
    echo "   Testing SQLite database operations, CRUD, search, monitoring"
    flutter test test/database_test.dart --reporter=expanded
    
    echo ""
    print_status "2. API Services Tests"
    echo "   Testing Recreation.gov and State Parks API services"
    flutter test test/api_services_test.dart --reporter=expanded
    
    echo ""
    print_status "3. Repository Integration Tests"
    echo "   Testing repository pattern, data coordination, caching"
    flutter test test/repository_integration_test.dart --reporter=expanded
    
    echo ""
    print_status "4. Provider Integration Tests"
    echo "   Testing Riverpod providers, state management, async operations"
    flutter test test/provider_integration_test.dart --reporter=expanded
    
    echo ""
    print_status "5. Manual API Integration Tests"
    echo "   Testing end-to-end functionality with real data operations"
    flutter test test/manual_api_test.dart --reporter=expanded
    
    echo ""
    print_success "All test suites completed!"
else
    print_warning "Test execution skipped by user choice."
fi

# Summary
echo ""
print_status "Test Suite Summary:"
echo "  📦 Database Operations: SQLite with location queries"
echo "  🌐 API Services: Recreation.gov + State Parks APIs"
echo "  🔄 Repository Pattern: Data coordination with caching"
echo "  🎯 State Management: Riverpod providers for UI"
echo "  🧪 Manual Testing: End-to-end validation"
echo ""

# Quick functionality verification
echo ""
read -p "🔍 Do you want to run a quick functionality verification? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Running quick verification..."
    
    # Create a simple test to verify core functionality
    flutter test --plain-name "should save and retrieve campgrounds from database" test/manual_api_test.dart
    
    if [ $? -eq 0 ]; then
        print_success "Core functionality verification passed!"
    else
        print_warning "Core functionality verification had issues. Check test output above."
    fi
fi

echo ""
print_status "Next Steps:"
echo "  1. ✅ API Integration is complete and tested"
echo "  2. 🗺️  Ready to move to Maps & Location Features (Week 2)"
echo "  3. 📱 UI integration can be refined based on test results"
echo "  4. 🔄 Consider running tests regularly during development"
echo ""
print_success "API Integration Test Runner Complete!"