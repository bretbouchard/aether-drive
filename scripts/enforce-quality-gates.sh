#!/bin/bash

# Enforce quality gates based on test results
# Supports both pre-merge and pre-release gate levels

set -e

GATE_LEVEL="${1:-pre-merge}"

echo "=========================================="
echo "Quality Gate Enforcement"
echo "Gate Level: $GATE_LEVEL"
echo "=========================================="
echo ""

# Load test results
REPORT_FILE="TestReports/cross-platform-report.json"

if [ ! -f "$REPORT_FILE" ]; then
    echo "❌ Test report not found: $REPORT_FILE"
    exit 1
fi

REPORT=$(cat "$REPORT_FILE")
SCORE=$(echo "$REPORT" | jq -r '.overallScore')
GRADE=$(echo "$REPORT" | jq -r '.grade')
SDK_COVERAGE=$(echo "$REPORT" | jq -r '.sdk.coverage')
IOS_FAILED=$(echo "$REPORT" | jq -r '.ios.failed')
TVOS_FAILED=$(echo "$REPORT" | jq -r '.tvos.failed')
TELEMETRY_PASSED=$(echo "$REPORT" | jq -r '.telemetry.passed')
TELEMETRY_TESTS=$(echo "$REPORT" | jq -r '.telemetry.tests')
AX_ERRORS=$(echo "$REPORT" | jq -r '.accessibility.errors')
PERF_REGRESSIONS=$(echo "$REPORT" | jq -r '.performance.regressions')
VISUAL_REGRESSIONS=$(echo "$REPORT" | jq -r '.visual.regressions')
SECURITY_VULNS=$(echo "$REPORT" | jq -r '.security.vulnerabilities')
CRASH_FREE_USERS=$(echo "$REPORT" | jq -r '.production.crashFreeUsers')

# Define gate thresholds
case "$GATE_LEVEL" in
  pre-merge)
    MIN_SCORE=75
    MIN_COVERAGE=80
    echo "📋 Pre-Merge Gates"
    echo "  Minimum Score: $MIN_SCORE"
    echo "  Minimum Coverage: ${MIN_COVERAGE}%"
    echo "  Zero iOS Failures: Required"
    echo "  Zero Accessibility Errors: Required"
    echo "  Zero Performance Regressions: Required"
    echo "  Zero Visual Regressions: Required"
    ;;
  pre-release)
    MIN_SCORE=85
    MIN_COVERAGE=85
    echo "🚀 Pre-Release Gates"
    echo "  Minimum Score: $MIN_SCORE"
    echo "  Minimum Coverage: ${MIN_COVERAGE}%"
    echo "  Zero iOS Failures: Required"
    echo "  Zero tvOS Failures: Required"
    echo "  Zero Telemetry Failures: Required"
    echo "  Zero Accessibility Errors: Required"
    echo "  Zero Performance Regressions: Required"
    echo "  Zero Visual Regressions: Required"
    echo "  Zero Security Vulnerabilities: Required"
    echo "  Crash-Free Users ≥ 99%: Required"
    ;;
  *)
    echo "❌ Unknown gate level: $GATE_LEVEL"
    echo "Valid levels: pre-merge, pre-release"
    exit 1
    ;;
esac

echo ""
echo "=========================================="
echo "Validating Gates"
echo "=========================================="
echo ""

FAILURES=()

# Overall score gate
echo "🔍 Checking Overall Score..."
if (( $(echo "$SCORE < $MIN_SCORE" | bc -l) )); then
    FAILURES+=("Score $SCORE below minimum $MIN_SCORE")
    echo "  ❌ FAIL: $SCORE < $MIN_SCORE"
else
    echo "  ✅ PASS: $SCORE ≥ $MIN_SCORE"
fi

# SDK coverage gate
echo ""
echo "🔍 Checking SDK Coverage..."
if [ "$SDK_COVERAGE" != "null" ]; then
    if (( $(echo "$SDK_COVERAGE < $MIN_COVERAGE" | bc -l) )); then
        FAILURES+=("SDK coverage $SDK_COVERAGE% below minimum ${MIN_COVERAGE}%")
        echo "  ❌ FAIL: ${SDK_COVERAGE}% < ${MIN_COVERAGE}%"
    else
        echo "  ✅ PASS: ${SDK_COVERAGE}% ≥ ${MIN_COVERAGE}%"
    fi
else
    echo "  ⚠️  SKIP: No SDK coverage data"
fi

# iOS test failures gate
echo ""
echo "🔍 Checking iOS Test Failures..."
if [ "$IOS_FAILED" != "null" ] && [ "$IOS_FAILED" -gt 0 ]; then
    FAILURES+=("iOS tests failing: $IOS_FAILED failed")
    echo "  ❌ FAIL: $IOS_FAILED failures"
else
    echo "  ✅ PASS: Zero failures"
fi

# tvOS test failures gate (pre-release only)
if [ "$GATE_LEVEL" == "pre-release" ]; then
    echo ""
    echo "🔍 Checking tvOS Test Failures..."
    if [ "$TVOS_FAILED" != "null" ] && [ "$TVOS_FAILED" -gt 0 ]; then
        FAILURES+=("tvOS tests failing: $TVOS_FAILED failed")
        echo "  ❌ FAIL: $TVOS_FAILED failures"
    else
        echo "  ✅ PASS: Zero failures"
    fi
fi

# Telemetry gate (pre-release only)
if [ "$GATE_LEVEL" == "pre-release" ]; then
    echo ""
    echo "🔍 Checking Telemetry Tests..."
    if [ "$TELEMETRY_TESTS" -gt 0 ] && [ "$TELEMETRY_PASSED" -lt "$TELEMETRY_TESTS" ]; then
        FAILURES+=("Telemetry tests failing: $TELEMETRY_PASSED/$TELEMETRY_TESTS passed")
        echo "  ❌ FAIL: $TELEMETRY_PASSED/$TELEMETRY_TESTS passed"
    else
        echo "  ✅ PASS: All telemetry tests passed"
    fi
fi

# Accessibility errors gate
echo ""
echo "🔍 Checking Accessibility Errors..."
if [ "$AX_ERRORS" -gt 0 ]; then
    FAILURES+=("Accessibility errors: $AX_ERRORS errors")
    echo "  ❌ FAIL: $AX_ERRORS errors"
else
    echo "  ✅ PASS: Zero errors"
fi

# Performance regressions gate
echo ""
echo "🔍 Checking Performance Regressions..."
if [ "$PERF_REGRESSIONS" -gt 0 ]; then
    FAILURES+=("Performance regressions: $PERF_REGRESSIONS regressions")
    echo "  ❌ FAIL: $PERF_REGRESSIONS regressions"
else
    echo "  ✅ PASS: Zero regressions"
fi

# Visual regressions gate
echo ""
echo "🔍 Checking Visual Regressions..."
if [ "$VISUAL_REGRESSIONS" -gt 0 ]; then
    FAILURES+=("Visual regressions: $VISUAL_REGRESSIONS regressions")
    echo "  ❌ FAIL: $VISUAL_REGRESSIONS regressions"
else
    echo "  ✅ PASS: Zero regressions"
fi

# Security vulnerabilities gate (pre-release only)
if [ "$GATE_LEVEL" == "pre-release" ]; then
    echo ""
    echo "🔍 Checking Security Vulnerabilities..."
    if [ "$SECURITY_VULNS" -gt 0 ]; then
        FAILURES+=("Security vulnerabilities: $SECURITY_VULNS vulnerabilities")
        echo "  ❌ FAIL: $SECURITY_VULNS vulnerabilities"
    else
        echo "  ✅ PASS: Zero vulnerabilities"
    fi
fi

# Crash-free users gate (pre-release only)
if [ "$GATE_LEVEL" == "pre-release" ]; then
    echo ""
    echo "🔍 Checking Crash-Free Users..."
    if [ "$CRASH_FREE_USERS" != "null" ]; then
        if (( $(echo "$CRASH_FREE_USERS < 99" | bc -l) )); then
            FAILURES+=("Crash-free users below 99%: ${CRASH_FREE_USERS}%")
            echo "  ❌ FAIL: ${CRASH_FREE_USERS}% < 99%"
        else
            echo "  ✅ PASS: ${CRASH_FREE_USERS}% ≥ 99%"
        fi
    else
        echo "  ⚠️  SKIP: No crash data available"
    fi
fi

# ============================================
# Report Results
# ============================================
echo ""
echo "=========================================="
echo "Quality Gate Results"
echo "=========================================="
echo ""
echo "Overall Score: $SCORE/100 ($GRADE)"
echo ""

if [ ${#FAILURES[@]} -eq 0 ]; then
    echo "✅ All quality gates PASSED ($GATE_LEVEL)"
    echo ""
    echo "🎉 Ready to proceed!"
    exit 0
else
    echo "❌ ${#FAILURES[@]} quality gate(s) FAILED ($GATE_LEVEL)"
    echo ""
    echo "Failed Gates:"
    for failure in "${FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo ""
    echo "Please fix the issues above before proceeding."
    exit 1
fi
