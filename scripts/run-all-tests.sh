#!/bin/bash

# Run all tests and generate comprehensive report
# This script executes the complete test suite locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "White Room Complete Test Suite"
echo "=========================================="
echo ""

# Parse arguments
SKIP_BUILD=false
SKIP_IOS=false
SKIP_SDK=false
COVERAGE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-ios)
            SKIP_IOS=true
            shift
            ;;
        --skip-sdk)
            SKIP_SDK=true
            shift
            ;;
        --coverage-only)
            COVERAGE_ONLY=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-build      Skip build steps"
            echo "  --skip-ios        Skip iOS tests"
            echo "  --skip-sdk        Skip SDK tests"
            echo "  --coverage-only   Only run coverage generation"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================
# 1. SDK Tests
# ============================================
if [ "$SKIP_SDK" = false ]; then
    echo "📦 Running SDK Tests..."
    echo "=========================================="

    cd "$PROJECT_ROOT/sdk"

    if [ -f "package.json" ]; then
        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            echo "Installing SDK dependencies..."
            npm ci
        fi

        # Run linting
        if [ "$COVERAGE_ONLY" = false ]; then
            echo "Running ESLint..."
            npm run lint || echo "⚠️  Linting failed"
        fi

        # Run type checking
        if [ "$COVERAGE_ONLY" = false ]; then
            echo "Running TypeScript check..."
            npm run type-check || echo "⚠️  Type check failed"
        fi

        # Run tests
        echo "Running unit tests..."
        npm test -- --coverage --maxWorkers=2 || echo "⚠️  Some tests failed"

        # Generate coverage
        echo "Generating coverage report..."
        npm run test:coverage || echo "⚠️  Coverage generation failed"

        echo "✅ SDK tests complete"
    else
        echo "⚠️  No package.json found in sdk/"
    fi

    cd "$PROJECT_ROOT"
    echo ""
fi

# ============================================
# 2. iOS Tests
# ============================================
if [ "$SKIP_IOS" = false ]; then
    echo "📱 Running iOS Tests..."
    echo "=========================================="

    # Find Xcode project
    XCODE_PROJECT=$(find ios -name "*.xcodeproj" -maxdepth 2 2>/dev/null | head -n 1)

    if [ -n "$XCODE_PROJECT" ]; then
        PROJECT_NAME=$(basename "$XCODE_PROJECT" .xcodeproj)
        SCHEME_NAME=$(echo "$PROJECT_NAME" | sed 's/iOS//')

        echo "Found project: $PROJECT_NAME"
        echo "Using scheme: $SCHEME_NAME"

        # Build if needed
        if [ "$SKIP_BUILD" = false ]; then
            echo "Building iOS project..."
            xcodebuild build \
                -project "$XCODE_PROJECT" \
                -scheme "$SCHEME_NAME" \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
                || echo "⚠️  Build failed"
        fi

        # Run unit tests
        if [ "$COVERAGE_ONLY" = false ]; then
            echo "Running unit tests..."
            xcodebuild test \
                -project "$XCODE_PROJECT" \
                -scheme "$SCHEME_NAME" \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
                -enableCodeCoverage YES \
                -resultBundlePath "$PROJECT_ROOT/TestResults.xcresult" \
                || echo "⚠️  Some tests failed"
        fi

        echo "✅ iOS tests complete"
    else
        echo "⚠️  No Xcode project found in ios/"
    fi

    echo ""
fi

# ============================================
# 3. Swift SDK Tests
# ============================================
echo "🔧 Running Swift SDK Tests..."
echo "=========================================="

SWIFT_SDK="$PROJECT_ROOT/juce_backend/sdk/packages/swift"

if [ -f "$SWIFT_SDK/Package.swift" ]; then
    cd "$SWIFT_SDK"

    echo "Running Swift tests..."
    swift test --enable-code-coverage || echo "⚠️  Swift tests failed"

    cd "$PROJECT_ROOT"
    echo "✅ Swift SDK tests complete"
else
    echo "⚠️  No Swift SDK found"
fi

echo ""

# ============================================
# 4. Aggregate Results
# ============================================
echo "📊 Aggregating Results..."
echo "=========================================="

if [ -f "$SCRIPT_DIR/aggregate-test-results.sh" ]; then
    chmod +x "$SCRIPT_DIR/aggregate-test-results.sh"
    "$SCRIPT_DIR/aggregate-test-results.sh"
else
    echo "⚠️  Aggregation script not found"
fi

echo ""
echo "=========================================="
echo "Test Suite Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  - Review test results above"
echo "  - Check TestReports/aggregate-report.json"
echo "  - Fix any failing tests"
echo "  - Run again before committing"
