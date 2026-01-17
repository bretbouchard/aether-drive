#!/bin/bash

# Aggregate all test results into a single report
# This script collects results from all test runs and calculates an overall quality score

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/TestReports"
ARTIFACTS_DIR="$REPORT_DIR/artifacts"

mkdir -p "$REPORT_DIR"
mkdir -p "$ARTIFACTS_DIR"

echo "=========================================="
echo "White Room Test Result Aggregator"
echo "=========================================="
echo ""

# Initialize counters
SDK_COVERAGE="N/A"
IOS_TESTS_PASSED=0
IOS_TESTS_FAILED=0
TVOS_TESTS_PASSED=0
TVOS_TESTS_FAILED=0
AX_ISSUES=0
AX_WARNINGS=0
PERF_REGRESSIONS=0
VISUAL_REGRESSIONS=0
SECURITY_VULNERABILITIES=0

# ============================================
# 1. SDK Coverage Analysis
# ============================================
echo "📦 Analyzing SDK Coverage..."

if [ -f "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" ]; then
    SDK_COVERAGE=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.lines.pct // 0')
    SDK_STATEMENTS=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.statements.pct // 0')
    SDK_FUNCTIONS=$(cat "$PROJECT_ROOT/sdk/coverage/coverage-summary.json" | jq -r '.total.branches.pct // 0')

    echo "  ✓ Lines: ${SDK_COVERAGE}%"
    echo "  ✓ Statements: ${SDK_STATEMENTS}%"
    echo "  ✓ Branches: ${SDK_FUNCTIONS}%"
else
    echo "  ⚠ No SDK coverage report found"
    SDK_COVERAGE="N/A"
fi

# ============================================
# 2. iOS Test Results
# ============================================
echo ""
echo "📱 Analyzing iOS Test Results..."

if [ -f "$ARTIFACTS_DIR/test-results.json" ]; then
    IOS_TESTS_PASSED=$(cat "$ARTIFACTS_DIR/test-results.json" | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
    IOS_TESTS_FAILED=$(cat "$ARTIFACTS_DIR/test-results.json" | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')

    echo "  ✓ Passed: $IOS_TESTS_PASSED"
    echo "  ✓ Failed: $IOS_TESTS_FAILED"
elif [ -d "$ARTIFACTS_DIR/ios-test-results" ]; then
    # Parse from xcresult bundle
    cd "$ARTIFACTS_DIR/ios-test-results"
    if [ -f "TestResults.xcresult" ]; then
        xcrun xcresulttool get --format json --path TestResults.xcresult > /tmp/ios-results.json 2>/dev/null || true
        IOS_TESTS_PASSED=$(cat /tmp/ios-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
        IOS_TESTS_FAILED=$(cat /tmp/ios-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')
        echo "  ✓ Passed: $IOS_TESTS_PASSED"
        echo "  ✓ Failed: $IOS_TESTS_FAILED"
    fi
else
    echo "  ⚠ No iOS test results found"
fi

# ============================================
# 3. tvOS Test Results
# ============================================
echo ""
echo "📺 Analyzing tvOS Test Results..."

if [ -d "$ARTIFACTS_DIR/tvos-test-results" ]; then
    cd "$ARTIFACTS_DIR/tvos-test-results"
    if [ -f "TestResults.tvos.xcresult" ]; then
        xcrun xcresulttool get --format json --path TestResults.tvos.xcresult > /tmp/tvos-results.json 2>/dev/null || true
        TVOS_TESTS_PASSED=$(cat /tmp/tvos-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsPassed") | .value // 0')
        TVOS_TESTS_FAILED=$(cat /tmp/tvos-results.json | jq -r '.metrics.testsCountMap[]? | select(.key == "testsFailed") | .value // 0')
        echo "  ✓ Passed: $TVOS_TESTS_PASSED"
        echo "  ✓ Failed: $TVOS_TESTS_FAILED"
    fi
else
    echo "  ⚠ No tvOS test results found"
fi

# ============================================
# 4. Accessibility Analysis
# ============================================
echo ""
echo "♿ Analyzing Accessibility Results..."

if [ -f "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" ]; then
    AX_ISSUES=$(cat "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" | jq -r '.errors // 0')
    AX_WARNINGS=$(cat "$PROJECT_ROOT/Tests/Accessibility/accessibility-report.json" | jq -r '.warnings // 0')

    echo "  ✓ Errors: $AX_ISSUES"
    echo "  ✓ Warnings: $AX_WARNINGS"
else
    echo "  ⚠ No accessibility report found"
fi

# ============================================
# 5. Performance Regression Analysis
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
# 6. Visual Regression Analysis
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
# 7. Security Analysis
# ============================================
echo ""
echo "🔒 Analyzing Security Scan Results..."

if [ -f "$PROJECT_ROOT/Tests/Security/security-report.json" ]; then
    SECURITY_VULNERABILITIES=$(cat "$PROJECT_ROOT/Tests/Security/security-report.json" | jq -r '.vulnerabilities // 0')
    echo "  ✓ Vulnerabilities: $SECURITY_VULNERABILITIES"
else
    echo "  ⚠ No security report found"
fi

# ============================================
# 8. Calculate Overall Quality Score
# ============================================
echo ""
echo "=========================================="
echo "Calculating Quality Score..."
echo "=========================================="

SCORE=0
WEIGHT=0

# SDK coverage (30% weight)
if [ "$SDK_COVERAGE" != "N/A" ]; then
    SDK_SCORE=$(echo "scale=2; $SDK_COVERAGE / 100 * 30" | bc)
    SCORE=$(echo "scale=2; $SCORE + $SDK_SCORE" | bc)
    WEIGHT=$((WEIGHT + 30))
    echo "SDK Coverage: $SDK_COVERAGE% → +$(echo "scale=1" <<< "$SDK_SCORE") points"
fi

# iOS tests (25% weight)
if [ "$IOS_TESTS_FAILED" != "N/A" ] && [ "$IOS_TESTS_PASSED" -gt 0 ]; then
    TOTAL=$((IOS_TESTS_PASSED + IOS_TESTS_FAILED))
    if [ $TOTAL -gt 0 ]; then
        PASS_RATE=$(echo "scale=2; $IOS_TESTS_PASSED / $TOTAL" | bc)
        TEST_SCORE=$(echo "scale=2; $PASS_RATE * 25" | bc)
        SCORE=$(echo "scale=2; $SCORE + $TEST_SCORE" | bc)
        WEIGHT=$((WEIGHT + 25))
        echo "iOS Tests: $(echo "scale=1" <<< "$PASS_RATE * 100")% pass rate → +$(echo "scale=1" <<< "$TEST_SCORE") points"
    fi
fi

# tvOS tests (5% weight)
if [ "$TVOS_TESTS_FAILED" != "N/A" ] && [ "$TVOS_TESTS_PASSED" -gt 0 ]; then
    TVOS_TOTAL=$((TVOS_TESTS_PASSED + TVOS_TESTS_FAILED))
    if [ $TVOS_TOTAL -gt 0 ]; then
        TVOS_PASS_RATE=$(echo "scale=2; $TVOS_TESTS_PASSED / $TVOS_TOTAL" | bc)
        TVOS_SCORE=$(echo "scale=2; $TVOS_PASS_RATE * 5" | bc)
        SCORE=$(echo "scale=2; $SCORE + $TVOS_SCORE" | bc)
        WEIGHT=$((WEIGHT + 5))
        echo "tvOS Tests: $(echo "scale=1" <<< "$TVOS_PASS_RATE * 100")% pass rate → +$(echo "scale=1" <<< "$TVOS_SCORE") points"
    fi
fi

# Accessibility (15% weight)
if [ "$AX_ISSUES" != "N/A" ]; then
    if [ "$AX_ISSUES" -eq 0 ]; then
        AX_SCORE=15
    else
        AX_SCORE=$(echo "scale=2; 15 - ($AX_ISSUES * 2)" | bc)
        AX_SCORE=$(echo "scale=0" <<< "$AX_SCORE")
        if [ "$AX_SCORE" -lt 0 ]; then
            AX_SCORE=0
        fi
    fi
    SCORE=$(echo "scale=2; $SCORE + $AX_SCORE" | bc)
    WEIGHT=$((WEIGHT + 15))
    echo "Accessibility: $AX_ISSUES errors → +$AX_SCORE points"
fi

# Performance (10% weight)
if [ "$PERF_REGRESSIONS" != "N/A" ]; then
    if [ "$PERF_REGRESSIONS" -eq 0 ]; then
        PERF_SCORE=10
    else
        PERF_SCORE=$(echo "scale=2; 10 - ($PERF_REGRESSIONS * 2)" | bc)
        PERF_SCORE=$(echo "scale=0" <<< "$PERF_SCORE")
        if [ "$PERF_SCORE" -lt 0 ]; then
            PERF_SCORE=0
        fi
    fi
    SCORE=$(echo "scale=2; $SCORE + $PERF_SCORE" | bc)
    WEIGHT=$((WEIGHT + 10))
    echo "Performance: $PERF_REGRESSIONS regressions → +$PERF_SCORE points"
fi

# Visual (10% weight)
if [ "$VISUAL_REGRESSIONS" != "N/A" ]; then
    if [ "$VISUAL_REGRESSIONS" -eq 0 ]; then
        VISUAL_SCORE=10
    else
        VISUAL_SCORE=$(echo "scale=2; 10 - ($VISUAL_REGRESSIONS * 2)" | bc)
        VISUAL_SCORE=$(echo "scale=0" <<< "$VISUAL_SCORE")
        if [ "$VISUAL_SCORE" -lt 0 ]; then
            VISUAL_SCORE=0
        fi
    fi
    SCORE=$(echo "scale=2; $SCORE + $VISUAL_SCORE" | bc)
    WEIGHT=$((WEIGHT + 10))
    echo "Visual: $VISUAL_REGRESSIONS regressions → +$VISUAL_SCORE points"
fi

# Security (5% weight)
if [ "$SECURITY_VULNERABILITIES" != "N/A" ]; then
    if [ "$SECURITY_VULNERABILITIES" -eq 0 ]; then
        SECURITY_SCORE=5
    else
        SECURITY_SCORE=$(echo "scale=2; 5 - ($SECURITY_VULNERABILITIES * 1)" | bc)
        SECURITY_SCORE=$(echo "scale=0" <<< "$SECURITY_SCORE")
        if [ "$SECURITY_SCORE" -lt 0 ]; then
            SECURITY_SCORE=0
        fi
    fi
    SCORE=$(echo "scale=2; $SCORE + $SECURITY_SCORE" | bc)
    WEIGHT=$((WEIGHT + 5))
    echo "Security: $SECURITY_VULNERABILITIES vulnerabilities → +$SECURITY_SCORE points"
fi

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
    GRADE_EMOJI="🌟"
elif (( $(echo "$FINAL_SCORE >= 90" | bc -l) )); then
    GRADE="A"
    GRADE_EMOJI="✨"
elif (( $(echo "$FINAL_SCORE >= 85" | bc -l) )); then
    GRADE="B+"
    GRADE_EMOJI="👍"
elif (( $(echo "$FINAL_SCORE >= 80" | bc -l) )); then
    GRADE="B"
    GRADE_EMOJI="✅"
elif (( $(echo "$FINAL_SCORE >= 75" | bc -l) )); then
    GRADE="C"
    GRADE_EMOJI="⚠️"
else
    GRADE="F"
    GRADE_EMOJI="❌"
fi

echo "Grade: $GRADE $GRADE_EMOJI"

# ============================================
# 9. Generate JSON Report
# ============================================
cat > "$REPORT_DIR/aggregate-report.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "score": $FINAL_SCORE,
  "grade": "$GRADE",
  "sdkCoverage": $([ "$SDK_COVERAGE" = "N/A" ] && echo "null" || echo "$SDK_COVERAGE"),
  "iosTestsPassed": $IOS_TESTS_PASSED,
  "iosTestsFailed": $IOS_TESTS_FAILED,
  "tvosTestsPassed": $TVOS_TESTS_PASSED,
  "tvosTestsFailed": $TVOS_TESTS_FAILED,
  "accessibilityErrors": $AX_ISSUES,
  "accessibilityWarnings": $AX_WARNINGS,
  "performanceRegressions": $PERF_REGRESSIONS,
  "visualRegressions": $VISUAL_REGRESSIONS,
  "securityVulnerabilities": $SECURITY_VULNERABILITIES,
  "breakdown": {
    "coverage": $(echo "scale=1" <<< "$SDK_SCORE"),
    "tests": $(echo "scale=1" <<< "$TEST_SCORE"),
    "accessibility": $AX_SCORE,
    "performance": $PERF_SCORE,
    "visual": $VISUAL_SCORE,
    "security": $SECURITY_SCORE
  }
}
EOF

echo ""
echo "Report saved to: $REPORT_DIR/aggregate-report.json"

# ============================================
# 10. Quality Gate Enforcement
# ============================================
echo ""
echo "=========================================="
echo "Quality Gate Enforcement"
echo "=========================================="

GATE_FAILURES=0

# Pre-merge gates
if [ "$IOS_TESTS_FAILED" -gt 0 ]; then
    echo "❌ FAIL: iOS tests failing ($IOS_TESTS_FAILED failed)"
    GATE_FAILURES=$((GATE_FAILURES + 1))
fi

if [ "$SDK_COVERAGE" != "N/A" ]; then
    if (( $(echo "$SDK_COVERAGE < 80" | bc -l) )); then
        echo "❌ FAIL: SDK coverage below 80% (${SDK_COVERAGE}%)"
        GATE_FAILURES=$((GATE_FAILURES + 1))
    fi
fi

if [ "$AX_ISSUES" -gt 0 ]; then
    echo "❌ FAIL: Accessibility errors ($AX_ISSUES errors)"
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
