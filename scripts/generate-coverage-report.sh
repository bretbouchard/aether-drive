#!/bin/bash

# Generate coverage report for all platforms
# This script creates a unified coverage report from all test sources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/TestReports/Coverage"

mkdir -p "$REPORT_DIR"

echo "=========================================="
echo "Generating Coverage Reports"
echo "=========================================="
echo ""

# ============================================
# 1. SDK Coverage (TypeScript)
# ============================================
echo "📦 SDK Coverage..."

if [ -f "$PROJECT_ROOT/sdk/package.json" ]; then
    cd "$PROJECT_ROOT/sdk"

    # Run tests with coverage
    npm run test:coverage 2>/dev/null || echo "⚠️  SDK coverage generation failed"

    # Copy coverage files
    if [ -d "coverage" ]; then
        cp coverage/lcov.info "$REPORT_DIR/sdk-coverage.lcov" 2>/dev/null || true
        cp coverage/coverage-summary.json "$REPORT_DIR/sdk-coverage.json" 2>/dev/null || true

        # Extract summary
        if [ -f "coverage/coverage-summary.json" ]; then
            LINES=$(cat coverage/coverage-summary.json | jq -r '.total.lines.pct // "N/A"')
            STATEMENTS=$(cat coverage/coverage-summary.json | jq -r '.total.statements.pct // "N/A"')
            BRANCHES=$(cat coverage/coverage-summary.json | jq -r '.total.branches.pct // "N/A"')
            FUNCTIONS=$(cat coverage/coverage-summary.json | jq -r '.total.functions.pct // "N/A"')

            echo "  Lines:       ${LINES}%"
            echo "  Statements:  ${STATEMENTS}%"
            echo "  Branches:    ${BRANCHES}%"
            echo "  Functions:   ${FUNCTIONS}%"
        fi
    fi

    cd "$PROJECT_ROOT"
else
    echo "  ⚠️  No SDK found"
fi

echo ""

# ============================================
# 2. Swift SDK Coverage
# ============================================
echo "🔧 Swift SDK Coverage..."

SWIFT_SDK="$PROJECT_ROOT/juce_backend/sdk/packages/swift"

if [ -f "$SWIFT_SDK/Package.swift" ]; then
    cd "$SWIFT_SDK"

    # Run tests with coverage
    swift test --enable-code-coverage 2>/dev/null || echo "⚠️  Swift coverage generation failed"

    # Generate coverage report
    if [ -f ".build/debug/codecov/default.profdata" ]; then
        xcrun llvm-cov export \
            .build/debug/SchillingerSDKPackageTests.xctest/Contents/MacOS/SchillingerSDKPackageTests \
            -instr-profile=.build/debug/codecov/default.profdata \
            -format=json \
            > "$REPORT_DIR/swift-sdk-coverage.json" 2>/dev/null || true

        # Convert to lcov if possible
        xcrun llvm-cov export \
            .build/debug/SchillingerSDKPackageTests.xctest/Contents/MacOS/SchillingerSDKPackageTests \
            -instr-profile=.build/debug/codecov/default.profdata \
            -format=lcov \
            > "$REPORT_DIR/swift-sdk-coverage.lcov" 2>/dev/null || true

        echo "  ✓ Coverage reports generated"
    fi

    cd "$PROJECT_ROOT"
else
    echo "  ⚠️  No Swift SDK found"
fi

echo ""

# ============================================
# 3. iOS Coverage (if available)
# ============================================
echo "📱 iOS Coverage..."

if [ -f "$PROJECT_ROOT/TestResults.xcresult" ]; then
    # Extract coverage from xcresult
    xcrun xccov view --report --json "$PROJECT_ROOT/TestResults.xcresult" \
        > "$REPORT_DIR/ios-coverage.json" 2>/dev/null || true

    # Generate lcov format
    xcrun xccov view --report "$PROJECT_ROOT/TestResults.xcresult" \
        > "$REPORT_DIR/ios-coverage.txt" 2>/dev/null || true

    echo "  ✓ iOS coverage extracted"
else
    echo "  ⚠️  No iOS test results found"
fi

echo ""

# ============================================
# 4. Generate Combined Report
# ============================================
echo "📊 Generating Combined Report..."

cat > "$REPORT_DIR/coverage-summary.md" <<EOF
# White Room Coverage Report

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary

EOF

# Add SDK coverage
if [ -f "$REPORT_DIR/sdk-coverage.json" ]; then
    cat >> "$REPORT_DIR/coverage-summary.md" <<EOF
### TypeScript SDK

\`\`\`
Lines:       $(cat "$REPORT_DIR/sdk-coverage.json" | jq -r '.total.lines.pct // "N/A")%
Statements:  $(cat "$REPORT_DIR/sdk-coverage.json" | jq -r '.total.statements.pct // "N/A")%
Branches:    $(cat "$REPORT_DIR/sdk-coverage.json" | jq -r '.total.branches.pct // "N/A")%
Functions:   $(cat "$REPORT_DIR/sdk-coverage.json" | jq -r '.total.functions.pct // "N/A")%
\`\`\`

EOF
fi

# Add Swift SDK coverage
if [ -f "$REPORT_DIR/swift-sdk-coverage.json" ]; then
    cat >> "$REPORT_DIR/coverage-summary.md" <<EOF
### Swift SDK

Coverage data available in \`swift-sdk-coverage.json\`

EOF
fi

# Add iOS coverage
if [ -f "$REPORT_DIR/ios-coverage.json" ]; then
    cat >> "$REPORT_DIR/coverage-summary.md" <<EOF
### iOS Application

Coverage data available in \`ios-coverage.json\`

EOF
fi

cat >> "$REPORT_DIR/coverage-summary.md" <<EOF
## Files

- \`sdk-coverage.lcov\` - TypeScript SDK coverage (lcov format)
- \`sdk-coverage.json\` - TypeScript SDK coverage (JSON)
- \`swift-sdk-coverage.lcov\` - Swift SDK coverage (lcov format)
- \`swift-sdk-coverage.json\` - Swift SDK coverage (JSON)
- \`ios-coverage.json\` - iOS application coverage (JSON)
- \`ios-coverage.txt\` - iOS application coverage (text)

## Viewing Coverage

### Online (Codecov)
Upload lcov files to [Codecov](https://codecov.io) for detailed visualization.

### Local
Use \`lcov\` tools to generate HTML reports:

\`\`\`bash
genhtml sdk-coverage.lcov -o coverage-html/
open coverage-html/index.html
\`\`\`

### VS Code
Install the [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) extension.

EOF

echo "✅ Coverage report complete"
echo ""
echo "Report saved to: $REPORT_DIR/coverage-summary.md"
echo ""
echo "View the report:"
echo "  cat $REPORT_DIR/coverage-summary.md"
