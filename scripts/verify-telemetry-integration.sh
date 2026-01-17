#!/bin/bash

# Verify telemetry integration in iOS app
# Validates telemetry events, crash reporting, and analytics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Telemetry Integration Verification"
echo "=========================================="
echo ""

TELEMETRY_VALID=0
TELEMETRY_TOTAL=0

# ============================================
# 1. Check Telemetry Framework Integration
# ============================================
echo "🔍 Checking Telemetry Framework Integration..."

if grep -r "import Telemetry" ios/ 2>/dev/null; then
    echo "  ✅ Telemetry framework imported"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ❌ Telemetry framework not imported"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for telemetry initialization
if grep -r "Telemetry.shared" ios/ 2>/dev/null | grep -q "configure\|initialize\|start"; then
    echo "  ✅ Telemetry initialized"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ❌ Telemetry not initialized"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# ============================================
# 2. Verify Telemetry Events
# ============================================
echo ""
echo "🔍 Verifying Telemetry Events..."

# Check for event tracking
if grep -r "trackEvent\|logEvent" ios/ 2>/dev/null; then
    echo "  ✅ Event tracking implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No event tracking found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for screen tracking
if grep -r "trackScreen\|screenView" ios/ 2>/dev/null; then
    echo "  ✅ Screen tracking implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No screen tracking found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for user properties
if grep -r "setUserProperty\|userProperties" ios/ 2>/dev/null; then
    echo "  ✅ User properties implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No user properties found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# ============================================
# 3. Verify Crash Reporting
# ============================================
echo ""
echo "🔍 Verifying Crash Reporting..."

# Check for crash reporting setup
if grep -r "Crashlytics\|CrashReporting" ios/ 2>/dev/null; then
    echo "  ✅ Crash reporting configured"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No crash reporting found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for custom crash keys
if grep -r "setCustomKey\|crashKeys" ios/ 2>/dev/null; then
    echo "  ✅ Custom crash keys implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No custom crash keys found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# ============================================
# 4. Verify Analytics Configuration
# ============================================
echo ""
echo "🔍 Verifying Analytics Configuration..."

# Check for analytics setup
if grep -r "Analytics\|FirebaseAnalytics" ios/ 2>/dev/null; then
    echo "  ✅ Analytics configured"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No analytics configuration found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for conversion tracking
if grep -r "conversion\|purchase" ios/ 2>/dev/null; then
    echo "  ✅ Conversion tracking implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ℹ️  No conversion tracking found (optional)"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# ============================================
# 5. Verify Telemetry Schema
# ============================================
echo ""
echo "🔍 Verifying Telemetry Schema..."

TELEMETRY_SCHEMA_FILE="$PROJECT_ROOT/sdk/telemetry-schema.json"

if [ -f "$TELEMETRY_SCHEMA_FILE" ]; then
    echo "  ✅ Telemetry schema file exists"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))

    # Validate JSON
    if jq empty "$TELEMETRY_SCHEMA_FILE" 2>/dev/null; then
        echo "  ✅ Schema JSON is valid"
        TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
    else
        echo "  ❌ Schema JSON is invalid"
    fi
    TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 2))
else
    echo "  ⚠️  No telemetry schema file found"
    TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 2))
fi

# ============================================
# 6. Verify Privacy Compliance
# ============================================
echo ""
echo "🔍 Verifying Privacy Compliance..."

# Check for privacy manifest
if [ -f "ios/WhiteRoomiOS/PrivacyInfo.xcprivacy" ]; then
    echo "  ✅ Privacy manifest exists"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No privacy manifest found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# Check for consent management
if grep -r "consent\|privacy\|trackingAuthorization" ios/ 2>/dev/null; then
    echo "  ✅ Consent management implemented"
    TELEMETRY_VALID=$((TELEMETRY_VALID + 1))
else
    echo "  ⚠️  No consent management found"
fi
TELEMETRY_TOTAL=$((TELEMETRY_TOTAL + 1))

# ============================================
# 7. Generate Telemetry Test Results
# ============================================
echo ""
echo "=========================================="
echo "Telemetry Verification Results"
echo "=========================================="
echo ""

# Calculate pass rate
if [ $TELEMETRY_TOTAL -gt 0 ]; then
    PASS_RATE=$(echo "scale=1; $TELEMETRY_VALID * 100 / $TELEMETRY_TOTAL" | bc)
    echo "Tests Passed: $TELEMETRY_VALID/$TELEMETRY_TOTAL ($PASS_RATE%)"
else
    PASS_RATE=0
    echo "No telemetry tests found"
fi

# Save results
mkdir -p "$PROJECT_ROOT/Tests/Telemetry"
cat > "$PROJECT_ROOT/Tests/Telemetry/telemetry-results.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tests": $TELEMETRY_TOTAL,
  "passed": $TELEMETRY_VALID,
  "failed": $((TELEMETRY_TOTAL - TELEMETRY_VALID)),
  "passRate": $PASS_RATE,
  "checks": {
    "frameworkImported": $(grep -r "import Telemetry" ios/ 2>/dev/null && echo true || echo false),
    "frameworkInitialized": $(grep -r "Telemetry.shared" ios/ 2>/dev/null | grep -q "configure\|initialize\|start" && echo true || echo false),
    "eventTracking": $(grep -r "trackEvent\|logEvent" ios/ 2>/dev/null && echo true || echo false),
    "screenTracking": $(grep -r "trackScreen\|screenView" ios/ 2>/dev/null && echo true || echo false),
    "userProperties": $(grep -r "setUserProperty\|userProperties" ios/ 2>/dev/null && echo true || echo false),
    "crashReporting": $(grep -r "Crashlytics\|CrashReporting" ios/ 2>/dev/null && echo true || echo false),
    "customCrashKeys": $(grep -r "setCustomKey\|crashKeys" ios/ 2>/dev/null && echo true || echo false),
    "analyticsConfigured": $(grep -r "Analytics\|FirebaseAnalytics" ios/ 2>/dev/null && echo true || echo false),
    "schemaExists": $( [ -f "$TELEMETRY_SCHEMA_FILE" ] && echo true || echo false),
    "schemaValid": $( [ -f "$TELEMETRY_SCHEMA_FILE" ] && jq empty "$TELEMETRY_SCHEMA_FILE" 2>/dev/null && echo true || echo false),
    "privacyManifest": $( [ -f "ios/WhiteRoomiOS/PrivacyInfo.xcprivacy" ] && echo true || echo false),
    "consentManagement": $(grep -r "consent\|privacy\|trackingAuthorization" ios/ 2>/dev/null && echo true || echo false)
  }
}
EOF

echo ""
echo "Results saved to: Tests/Telemetry/telemetry-results.json"

# ============================================
# 8. Final Verdict
# ============================================
echo ""
echo "=========================================="
if [ $TELEMETRY_VALID -eq $TELEMETRY_TOTAL ]; then
    echo "✅ All telemetry checks PASSED"
    exit 0
elif [ $(echo "$PASS_RATE >= 75" | bc -l) -eq 1 ]; then
    echo "⚠️  Telemetry integration partially complete ($PASS_RATE%)"
    exit 0
else
    echo "❌ Telemetry integration needs improvement ($PASS_RATE%)"
    exit 1
fi
