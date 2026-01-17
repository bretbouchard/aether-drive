#!/bin/bash

# Aggregate test results from all platforms and agents
# Enhanced Phase 2 version with telemetry and accessibility performance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/TestReports"
ARTIFACTS_DIR="$REPORT_DIR/artifacts"

mkdir -p "$REPORT_DIR"
mkdir -p "$ARTIFACTS_DIR"

echo "=========================================="
echo "White Room Cross-Platform Test Aggregator"
echo "Phase 2: Enhanced Integration"
echo "=========================================="
echo ""

# Initialize counters
SDK_COVERAGE="N/A"
SDK_TESTS="N/A"
SDK_PASSED="N/A"
IOS_PASSED=0
IOS_FAILED=0
TVOS_PASSED=0
TVOS_FAILED=0
TELEMETRY_TESTS=0
TELEMETRY_PASSED=0
SWIFTUI_TESTS=0
SWIFTUI_PASSED=0
XCUI_TESTS=0
XCUI_PASSED=0
AX_PERF_SCORE=0
AX_ERRORS=0
AX_WARNINGS=0
PERF_REGRESSIONS=0
VISUAL_REGRESSIONS=0
SECURITY_VULNS=0
CRASH_FREE_USERS=0
ACTIVE_SESSIONS=0

# ============================================
# 1. SDK Results
# ============================================
echo "📦 Analyzing SDK Results..."

if [ -f "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" ]; then
    SDK_COVERAGE=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.lines.pct // 0')
    SDK_STATEMENTS=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.statements.pct // 0')
    SDK_FUNCTIONS=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.branches.pct // 0')
    SDK_TESTS=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.lines.covered // 0')
    SDK_PASSED=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.lines.covered // 0')

    echo "  ✓ Coverage: ${SDK_COVERAGE}%"
    echo "  ✓ Tests: $SDK_PASSED"
else
    echo "  ⚠ No SDK coverage report found"
fi

# ============================================
# 2. iOS Results
# ============================================
echo ""
echo "📱 Analyzing iOS Test Results..."

if [ -f "$ARTIFACTS_DIR/ios-test-results/test-results.json" ]; then
    IOS_PASSED=$(cat "$ARTIFACTS_DIR/ios-test-results/test-results.json" | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
    IOS_FAILED=$(cat "$ARTIFACTS_DIR/ios-test-results/test-results.json" | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')
    echo "  ✓ Passed: $IOS_PASSED"
    echo "  ✓ Failed: $IOS_FAILED"
elif [ -d "$ARTIFACTS_DIR/ios-test-results" ]; then
    cd "$ARTIFACTS_DIR/ios-test-results"
    if [ -f "TestResults.xcresult" ]; then
        xcrun xcresulttool get --format json --path TestResults.xcresult > /tmp/ios-results.json 2>/dev/null || true
        IOS_PASSED=$(cat /tmp/ios-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
        IOS_FAILED=$(cat /tmp/ios-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')
        echo "  ✓ Passed: $IOS_PASSED"
        echo "  ✓ Failed: $IOS_FAILED"
    fi
else
    echo "  ⚠ No iOS test results found"
fi

# ============================================
# 3. tvOS Results
# ============================================
echo ""
echo "📺 Analyzing tvOS Test Results..."

if [ -d "$ARTIFACTS_DIR/tvos-test-results" ]; then
    cd "$ARTIFACTS_DIR/tvos-test-results"
    if [ -f "TestResults.tvos.xcresult" ]; then
        xcrun xcresulttool get --format json --path TestResults.tvos.xcresult > /tmp/tvos-results.json 2>/dev/null || true
        TVOS_PASSED=$(cat /tmp/tvos-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
        TVOS_FAILED=$(cat /tmp/tvos-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')
        echo "  ✓ Passed: $TVOS_PASSED"
        echo "  ✓ Failed: $TVOS_FAILED"
    fi
else
    echo "  ⚠ No tvOS test results found"
fi

# ============================================
# 4. Telemetry Results (Phase 2)
# ============================================
echo ""
echo "📊 Analyzing Telemetry Integration Results..."

if [ -f "$ARTIFACTS_DIR/telemetry-test-results/telemetry-results.json" ]; then
    TELEMETRY_TESTS=$(cat "$ARTIFACTS_DIR/telemetry-test-results/telemetry-results.json" | jq -r '.tests // 0')
    TELEMETRY_PASSED=$(cat "$ARTIFACTS_DIR/telemetry-test-results/telemetry-results.json" | jq -r '.passed // 0')
    echo "  ✓ Telemetry Tests: $TELEMETRY_PASSED/$TELEMETRY_TESTS passed"
else
    echo "  ⚠ No telemetry results found"
fi

# ============================================
# 5. SwiftUI Enhanced Tests (Phase 2)
# ============================================
echo ""
echo "🎨 Analyzing SwiftUI Enhanced Tests..."

if [ -f "$ARTIFACTS_DIR/swiftui-test-results/swiftui-results.json" ]; then
    SWIFTUI_TESTS=$(cat "$ARTIFACTS_DIR/swiftui-test-results/swiftui-results.json" | jq -r '.tests // 0')
    SWIFTUI_PASSED=$(cat "$ARTIFACTS_DIR/swiftui-test-results/swiftui-results.json" | jq -r '.passed // 0')
    echo "  ✓ SwiftUI Tests: $SWIFTUI_PASSED/$SWIFTUI_TESTS passed"
else
    echo "  ⚠ No SwiftUI test results found"
fi

# ============================================
# 6. XCUITest Enhanced Results (Phase 2)
# ============================================
echo ""
echo "🧪 Analyzing XCUITest Enhanced Results..."

if [ -f "$ARTIFACTS_DIR/xcui-test-results/xcui-results.json" ]; then
    XCUI_TESTS=$(cat "$ARTIFACTS_DIR/xcui-test-results/xcui-results.json" | jq -r '.tests // 0')
    XCUI_PASSED=$(cat "$ARTIFACTS_DIR/xcui-test-results/xcui-results.json" | jq -r '.passed // 0')
    echo "  ✓ XCUITest: $XCUI_PASSED/$XCUI_TESTS passed"
else
    echo "  ⚠ No XCUITest results found"
fi

# ============================================
# 7. Accessibility Performance (Phase 2)
# ============================================
echo ""
echo "♿ Analyzing Accessibility Performance..."

if [ -f "$ARTIFACTS_DIR/accessibility-performance-results/ax-perf-metrics.json" ]; then
    AX_PERF_SCORE=$(cat "$ARTIFACTS_DIR/accessibility-performance-results/ax-perf-metrics.json" | jq -r '.score // 0')
    echo "  ✓ Accessibility Performance Score: $AX_PERF_SCORE/100"
else
    echo "  ⚠ No accessibility performance results found"
fi

# ============================================
# 8. Accessibility Analysis
# ============================================
echo ""
echo "♿ Analyzing Accessibility Results..."

if [ -f "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" ]; then
    AX_ERRORS=$(cat "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" | jq -r '.errors // 0')
    AX_WARNINGS=$(cat "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" | jq -r '.warnings // 0')
    echo "  ✓ Errors: $AX_ERRORS"
    echo "  ✓ Warnings: $AX_WARNINGS"
else
    echo "  ⚠ No accessibility report found"
fi

# ============================================
# 9. Performance Regression Analysis
# ============================================
echo ""
echo "⚡ Analyzing Performance Results..."

if [ -f "$PROJECT_ROOT/Tests/Performance/check-performance-regression.log" ]; then
    PERF_REGRESSIONS=$(grep -c "REGRESSION:" "$PROJECT_ROOT/Tests/Performance/check-performance-regression.log" 2>/dev/null || echo "0")
    echo "  ✓ Regressions: $PERF_REGRESSIONS"
else
    echo "  ⚠ No performance regression data found"
fi

# ============================================
# 10. Visual Regression Analysis
# ============================================
echo ""
echo "🎨 Analyzing Visual Regression Results..."

if [ -f "$PROJECT_ROOT/Tests/Visual/visual-regression-report.json" ]; then
    VISUAL_REGRESSIONS=$(cat "$PROJECT_ROOT/Tests/Visual/visual-regression-report.json" | jq -r '.regressions // 0')
    echo "  ✓ Regressions: $VISUAL_REGRESSIONS"
else
    echo "  ⚠ No visual regression data found"
fi

# ============================================
# 11. Security Analysis
# ============================================
echo ""
echo "🔒 Analyzing Security Scan Results..."

if [ -f "$PROJECT_ROOT/Tests/Security/security-report.json" ]; then
    SECURITY_VULNS=$(cat "$PROJECT_ROOT/Tests/Security/security-report.json" | jq -r '.vulnerabilities // 0')
    echo "  ✓ Vulnerabilities: $SECURITY_VULNS"
else
    echo "  ⚠ No security report found"
fi

# ============================================
# 12. Telemetry Data (Phase 2)
# ============================================
echo ""
echo "📈 Analyzing Production Telemetry..."

if [ -f "$PROJECT_ROOT/Tests/Telemetry/telemetry-data.json" ]; then
    CRASH_FREE_USERS=$(cat "$PROJECT_ROOT/Tests/Telemetry/telemetry-data.json" | jq -r '.crashFreeUsers // 0')
    ACTIVE_SESSIONS=$(cat "$PROJECT_ROOT/Tests/Telemetry/telemetry-data.json" | jq -r '.activeSessions // 0')
    echo "  ✓ Crash-Free Users: $CRASH_FREE_USERS%"
    echo "  ✓ Active Sessions: $ACTIVE_SESSIONS"
else
    echo "  ⚠ No telemetry data found (using defaults)"
    CRASH_FREE_USERS=100
    ACTIVE_SESSIONS=0
fi

# ============================================
# 13. Calculate Overall Quality Score
# ============================================
echo ""
echo "=========================================="
echo "Calculating Cross-Platform Quality Score..."
echo "=========================================="

SCORE=0
WEIGHT=0

# SDK coverage (25% weight)
if [ "$SDK_COVERAGE" != "N/A" ]; then
    SDK_SCORE=$(echo "scale=2; $SDK_COVERAGE / 100 * 25" | bc)
    SCORE=$(echo "scale=2; $SCORE + $SDK_SCORE" | bc)
    WEIGHT=$((WEIGHT + 25))
    echo "SDK Coverage: $SDK_COVERAGE% → +$(echo "scale=1" <<< "$SDK_SCORE") points"
fi

# iOS tests (20% weight)
if [ "$IOS_FAILED" != "N/A" ]; then
    TOTAL=$((IOS_PASSED + IOS_FAILED))
    if [ $TOTAL -gt 0 ]; then
        PASS_RATE=$(echo "scale=2; $IOS_PASSED / $TOTAL" | bc)
        TEST_SCORE=$(echo "scale=2; $PASS_RATE * 20" | bc)
        SCORE=$(echo "scale=2; $SCORE + $TEST_SCORE" | bc)
        WEIGHT=$((WEIGHT + 20))
        echo "iOS Tests: $(echo "scale=1" <<< "$PASS_RATE * 100")% pass rate → +$(echo "scale=1" <<< "$TEST_SCORE") points"
    fi
fi

# tvOS tests (10% weight)
if [ "$TVOS_FAILED" != "N/A" ]; then
    TVOS_TOTAL=$((TVOS_PASSED + TVOS_FAILED))
    if [ $TVOS_TOTAL -gt 0 ]; then
        TVOS_PASS_RATE=$(echo "scale=2; $TVOS_PASSED / $TVOS_TOTAL" | bc)
        TVOS_SCORE=$(echo "scale=2; $TVOS_PASS_RATE * 10" | bc)
        SCORE=$(echo "scale=2; $SCORE + $TVOS_SCORE" | bc)
        WEIGHT=$((WEIGHT + 10))
        echo "tvOS Tests: $(echo "scale=1" <<< "$TVOS_PASS_RATE * 100")% pass rate → +$(echo "scale=1" <<< "$TVOS_SCORE") points"
    fi
fi

# Telemetry (10% weight)
if [ "$TELEMETRY_TESTS" -gt 0 ]; then
    TELEMETRY_SCORE=$(echo "scale=2; $TELEMETRY_PASSED / $TELEMETRY_TESTS * 10" | bc)
    SCORE=$(echo "scale=2; $SCORE + $TELEMETRY_SCORE" | bc)
    WEIGHT=$((WEIGHT + 10))
    echo "Telemetry: $TELEMETRY_PASSED/$TELEMETRY_TESTS → +$(echo "scale=1" <<< "$TELEMETRY_SCORE") points"
fi

# Accessibility (20% weight)
if [ "$AX_ERRORS" -eq 0 ]; then
    AX_SCORE_VAL=20
else
    AX_SCORE_VAL=$(echo "scale=2; 20 - ($AX_ERRORS * 2)" | bc)
    AX_SCORE_VAL=$(echo "scale=0" <<< "$AX_SCORE_VAL")
    if [ "$AX_SCORE_VAL" -lt 0 ]; then
        AX_SCORE_VAL=0
    fi
fi
SCORE=$(echo "scale=2; $SCORE + $AX_SCORE_VAL" | bc)
WEIGHT=$((WEIGHT + 20))
echo "Accessibility: $AX_ERRORS errors → +$AX_SCORE_VAL points"

# Performance (15% weight)
if [ "$PERF_REGRESSIONS" -eq 0 ]; then
    PERF_SCORE=15
else
    PERF_SCORE=$(echo "scale=2; 15 - ($PERF_REGRESSIONS * 3)" | bc)
    PERF_SCORE=$(echo "scale=0" <<< "$PERF_SCORE")
    if [ "$PERF_SCORE" -lt 0 ]; then
        PERF_SCORE=0
    fi
fi
SCORE=$(echo "scale=2; $SCORE + $PERF_SCORE" | bc)
WEIGHT=$((WEIGHT + 15))
echo "Performance: $PERF_REGRESSIONS regressions → +$PERF_SCORE points"

# Normalize score if not all categories present
if [ $WEIGHT -lt 100 ] && [ $WEIGHT -gt 0 ]; then
    SCORE=$(echo "scale=1; $SCORE * 100 / $WEIGHT" | bc)
fi

FINAL_SCORE=$(echo "scale=1; $SCORE" | bc)

echo ""
echo "=========================================="
echo "Overall Quality Score: $FINAL_SCORE/100"
echo "=========================================="

# Determine grade
if (( $(echo "$FINAL_SCORE >= 95" | bc -l) )); then
    GRADE="A+"
elif (( $(echo "$FINAL_SCORE >= 90" | bc -l) )); then
    GRADE="A"
elif (( $(echo "$FINAL_SCORE >= 85" | bc -l) )); then
    GRADE="B+"
elif (( $(echo "$FINAL_SCORE >= 80" | bc -l) )); then
    GRADE="B"
elif (( $(echo "$FINAL_SCORE >= 75" | bc -l) )); then
    GRADE="C"
else
    GRADE="F"
fi

echo "Grade: $GRADE"

# ============================================
# 14. Generate Cross-Platform JSON Report
# ============================================
cat > "$REPORT_DIR/cross-platform-report.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "overallScore": $FINAL_SCORE,
  "grade": "$GRADE",
  "sdk": {
    "coverage": $([ "$SDK_COVERAGE" = "N/A" ] && echo "null" || echo "$SDK_COVERAGE"),
    "tests": $([ "$SDK_TESTS" = "N/A" ] && echo "null" || echo "$SDK_TESTS"),
    "passed": $([ "$SDK_PASSED" = "N/A" ] && echo "null" || echo "$SDK_PASSED")
  },
  "ios": {
    "passed": $IOS_PASSED,
    "failed": $IOS_FAILED
  },
  "tvos": {
    "passed": $TVOS_PASSED,
    "failed": $TVOS_FAILED
  },
  "telemetry": {
    "tests": $TELEMETRY_TESTS,
    "passed": $TELEMETRY_PASSED
  },
  "swiftui": {
    "tests": $SWIFTUI_TESTS,
    "passed": $SWIFTUI_PASSED
  },
  "xcui": {
    "tests": $XCUI_TESTS,
    "passed": $XCUI_PASSED
  },
  "accessibilityPerformance": {
    "score": $AX_PERF_SCORE
  },
  "accessibility": {
    "errors": $AX_ERRORS,
    "warnings": $AX_WARNINGS
  },
  "performance": {
    "regressions": $PERF_REGRESSIONS
  },
  "visual": {
    "regressions": $VISUAL_REGRESSIONS
  },
  "security": {
    "vulnerabilities": $SECURITY_VULNS
  },
  "production": {
    "crashFreeUsers": $CRASH_FREE_USERS,
    "activeSessions": $ACTIVE_SESSIONS
  },
  "meetsGates": $(echo "$FINAL_SCORE >= 75" | bc -l)
}
EOF

echo ""
echo "Report saved to: $REPORT_DIR/cross-platform-report.json"

# ============================================
# 15. Quality Gate Enforcement
# ============================================
echo ""
echo "=========================================="
echo "Quality Gate Enforcement"
echo "=========================================="

GATE_FAILURES=0

# Pre-merge gates
if [ "$IOS_FAILED" -gt 0 ]; then
    echo "❌ FAIL: iOS tests failing ($IOS_FAILED failed)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

if [ "$SDK_COVERAGE" != "N/A" ]; then
    if (( $(echo "$SDK_COVERAGE < 80" | bc -l) )); then
        echo "❌ FAIL: SDK coverage below 80% (${SDK_COVERAGE}%)"
        GATE_FAILURES=$((GATE_FAILURES + 1))
    fi
fi

if [ "$AX_ERRORS" -gt 0 ]; then
    echo "❌ FAIL: Accessibility errors ($AX_ERRORS errors)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

if [ "$PERF_REGRESSIONS" -gt 0 ]; then
    echo "❌ FAIL: Performance regressions ($PERF_REGRESSIONS regressions)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

if [ "$VISUAL_REGRESSIONS" -gt 0 ]; then
    echo "❌ FAIL: Visual regressions ($VISUAL_REGRESSIONS regressions)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Overall score gate
if (( $(echo "$FINAL_SCORE < 75" | bc -l) )); then
    echo "❌ FAIL: Quality score below 75% ($FINAL_SCORE%)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

echo ""
if [ $GATE_FAILURES -eq 0 ]; then
    echo "✅ All quality gates PASSED"
    echo ""
    echo "Ready to merge! 🚀"
    exit 0
else
    echo "❌ $GATE_FAILURES quality gate(s) FAILED"
    echo ""
    echo "Please fix the issues above before merging."
    exit 1
fi
