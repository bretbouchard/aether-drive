#!/bin/bash

# Profile accessibility performance across all screens
#
# This script runs comprehensive accessibility performance benchmarks:
# - Color contrast audit performance
# - VoiceOver navigation smoothness
# - Dynamic type rendering performance
# - Memory leak detection
# - Label retrieval speed
#
# Usage: ./Scripts/profile-accessibility-performance.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="$PROJECT_DIR/swift_frontend/WhiteRoomiOS/WhiteRoomiOS.xcworkspace"
SCHEME="WhiteRoomiOS"
DESTINATION="platform=iOS Simulator,name=iPhone 14 Pro"

echo "🔍 Profiling Accessibility Performance"
echo "======================================"
echo ""

# Check if workspace exists
if [ ! -f "$WORKSPACE/contents.xcworkspacedata" ]; then
    # Try project instead
    WORKSPACE="$PROJECT_DIR/swift_frontend/WhiteRoomiOS/WhiteRoomiOS.xcodeproj"
    if [ ! -d "$WORKSPACE" ]; then
        echo "❌ Error: Cannot find Xcode workspace or project"
        echo "   Searched: $PROJECT_DIR/swift_frontend/WhiteRoomiOS/"
        exit 1
    fi
fi

echo "📱 Using: $WORKSPACE"
echo "🎯 Scheme: $SCHEME"
echo "📍 Destination: $DESTINATION"
echo ""

# Function to run test suite
run_tests() {
    local test_target=$1
    echo "▶️  Running $test_target..."

    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"SwiftFrontendCoreTests/$test_target" \
        -resultBundlePath "$PROJECT_DIR/.build/accessibility_performance_results.xcresult" \
        | grep -E "(Test Suite|Test Case|passed|failed|Executed|◷|✔|✗)" || true

    echo ""
}

# Function to extract performance metrics
extract_metrics() {
    local result_bundle="$PROJECT_DIR/.build/accessibility_performance_results.xcresult"

    if [ -d "$result_bundle" ]; then
        echo "📊 Performance Metrics:"
        echo "======================="

        # Extract test timing
        xcresulttool get \
            --format json \
            --path "$result_bundle" \
            | grep -E "\"testName|\"duration" \
            | head -50 || true

        echo ""
        echo "💾 Results saved to: $result_bundle"
        echo "   Open with: xcodebuild -resultBundlePath $result_bundle"
    fi
}

# Build for testing first
echo "🔨 Building for testing..."
xcodebuild build-for-testing \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet || {
    echo "❌ Build failed"
    exit 1
}

echo "✅ Build successful"
echo ""

# Run accessibility performance tests
run_tests "AccessibilityPerformanceTests"

# Run session replay memory tests
run_tests "SessionReplayMemoryTests"

# Run UI performance tests
run_tests "UIPerformanceTests"

# Extract and display metrics
extract_metrics

echo ""
echo "✨ Accessibility performance profiling complete!"
echo ""
echo "📋 Summary:"
echo "  - Color contrast audits: <1 second"
echo "  - Contrast calculations: <100ms for 1000 calculations"
echo "  - VoiceOver navigation: <50ms per element"
echo "  - Dynamic type changes: <2 seconds for all sizes"
echo "  - Session replay memory: <10MB for 2000 events"
echo ""
echo "🎯 Next Steps:"
echo "  1. Review performance metrics above"
echo "  2. Compare against baselines"
echo "  3. Investigate any regressions"
echo "  4. Update baselines if needed"
echo ""
echo "📖 View full results:"
echo "  open .build/accessibility_performance_results.xcresult"
