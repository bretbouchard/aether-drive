#!/bin/bash

# Compare snapshot test images with reference images
# Uses ImageMagick to detect visual regressions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_ROOT/ios/WhiteRoomiOS/Screenshots"
REFERENCE_DIR="$SCREENSHOTS_DIR/Reference"
CURRENT_DIR="$SCREENSHOTS_DIR/Current"
DIFF_DIR="$SCREENSHOTS_DIR/Diff"
REPORT_FILE="$PROJECT_ROOT/Tests/Visual/visual-regression-report.json"

mkdir -p "$CURRENT_DIR"
mkdir -p "$DIFF_DIR"
mkdir -p "$(dirname "$REPORT_FILE")"

echo "=========================================="
echo "Visual Regression Testing"
echo "=========================================="
echo ""

# Check if ImageMagick is installed
if ! command -v compare &> /dev/null; then
    echo "❌ ImageMagick not found"
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
REGRESSIONS=0

# Arrays to store results
declare -a FAILED_FILES
declare -a DIFF_PERCENTAGES

# ============================================
# Compare screenshots
# ============================================
echo "Comparing screenshots..."

if [ ! -d "$REFERENCE_DIR" ]; then
    echo "⚠️  No reference directory found"
    echo "Creating reference directory at: $REFERENCE_DIR"
    mkdir -p "$REFERENCE_DIR"
    echo ""
    echo "To establish baseline, copy reference images to:"
    echo "  $REFERENCE_DIR"
    exit 0
fi

for reference_image in "$REFERENCE_DIR"/*.png "$REFERENCE_DIR"/*.jpg; do
    if [ ! -f "$reference_image" ]; then
        continue
    fi

    filename=$(basename "$reference_image")
    current_image="$CURRENT_DIR/$filename"
    diff_image="$DIFF_DIR/$filename"

    echo ""
    echo "Testing: $filename"

    if [ ! -f "$current_image" ]; then
        echo "  ⚠️  No current image found (expected at $current_image)"
        continue
    fi

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Compare images using ImageMagick
    # Returns 0 if identical, 1 if different
    if compare -metric AE "$reference_image" "$current_image" "$diff_image" 2>/dev/null; then
        echo "  ✅ PASS - Images are identical"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        # Calculate difference percentage
        DIFF_OUTPUT=$(compare -metric RMSE -f "%[distortion]" "$reference_image" "$current_image" "$diff_image" 2>&1)

        if [ $? -eq 0 ]; then
            echo "  ✅ PASS - No significant difference ($DIFF_OUTPUT)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "  ❌ FAIL - Images differ ($DIFF_OUTPUT)"
            FAILED_TESTS=$((FAILED_TESTS_TESTS + 1))
            REGRESSIONS=$((REGRESSIONS + 1))

            FAILED_FILES+=("$filename")
            DIFF_PERCENTAGES+=("$DIFF_OUTPUT")

            # Generate annotated diff image
            convert "$current_image" "$reference_image" \
                -compose_difference -composite \
                -auto-level \
                "$diff_image" 2>/dev/null || true
        fi
    fi
done

# ============================================
# Generate Report
# ============================================
echo ""
echo "=========================================="
echo "Results"
echo "=========================================="
echo "Total:  $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

# Generate JSON report
cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "totalTests": $TOTAL_TESTS,
  "passedTests": $PASSED_TESTS,
  "failedTests": $FAILED_TESTS,
  "regressions": $REGRESSIONS,
  "failures": [
EOF

# Add failure details
FIRST=true
for i in "${!FAILED_FILES[@]}"; do
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        cat >> "$REPORT_FILE" <<EOF
    ,
EOF
    fi

    cat >> "$REPORT_FILE" <<EOF
    {
      "file": "${FAILED_FILES[$i]}",
      "diff": "${DIFF_PERCENTAGES[$i]}"
    }
EOF
done

cat >> "$REPORT_FILE" <<EOF

  ]
}
EOF

echo "Report saved to: $REPORT_FILE"
echo ""

# Generate human-readable report
cat > "$SCREENSHOTS_DIR/visual-regression-report.md" <<EOF
# Visual Regression Test Report

**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary

- **Total Tests:** $TOTAL_TESTS
- **Passed:** $PASSED_TESTS ✅
- **Failed:** $FAILED_TESTS ❌
- **Regressions:** $REGRESSIONS

## Failures

EOF

if [ $FAILED_TESTS -gt 0 ]; then
    for i in "${!FAILED_FILES[@]}"; do
        cat >> "$SCREENSHOTS_DIR/visual-regression-report.md" <<EOF
### ${FAILED_FILES[$i]}

- **Difference:** ${DIFF_PERCENTAGES[$i]}
- **Reference:** \`Reference/${FAILED_FILES[$i]}\`
- **Current:** \`Current/${FAILED_FILES[$i]}\`
- **Diff:** \`Diff/${FAILED_FILES[$i]}\`

EOF
    done
else
    cat >> "$SCREENSHOTS_DIR/visual-regression-report.md" <<EOF
No failures detected! 🎉

EOF
fi

cat >> "$SCREENSHOTS_DIR/visual-regression-report.md" <<EOF
## Viewing Differences

Open the diff images in \`$DIFF_DIR\` to see visual differences:
- Red areas indicate differences
- The intensity of red shows the magnitude of difference

## Updating Baseline

If changes are intentional, update the reference images:

\`\`\`bash
cp Current/*.png Reference/
\`\`\`

---

**Report location:** \`$REPORT_FILE\`
**Markdown report:** \`$SCREENSHOTS_DIR/visual-regression-report.md\`
EOF

echo "Markdown report saved to: $SCREENSHOTS_DIR/visual-regression-report.md"

# Exit with error if there are regressions
if [ $REGRESSIONS -gt 0 ]; then
    echo ""
    echo "❌ Visual regressions detected!"
    echo "Review diff images in: $DIFF_DIR"
    exit 1
else
    echo "✅ No visual regressions detected!"
    exit 0
fi
