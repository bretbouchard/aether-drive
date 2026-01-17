#!/bin/bash

# =============================================================================
# Compare Screenshots Script
# =============================================================================
#
# Compares screenshots for visual regression detection using ImageMagick.
# Generates diff images showing changes between baseline and current.
#
# Usage: ./Scripts/compare-screenshots.sh <baseline_dir> <current_dir> [output_dir]
#
# Requirements:
#   - ImageMagick (install with: brew install imagemagick)
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
BASELINE_DIR="$1"
CURRENT_DIR="$2"
OUTPUT_DIR="${3:-$PROJECT_DIR/Screenshots/Diff}"

# Check arguments
if [ -z "$BASELINE_DIR" ] || [ -z "$CURRENT_DIR" ]; then
    echo "❌ Error: Missing required arguments"
    echo ""
    echo "Usage: $0 <baseline_dir> <current_dir> [output_dir]"
    echo ""
    echo "Example:"
    echo "  $0 Screenshots/Baseline Screenshots/Current Screenshots/Diff"
    echo ""
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v compare &> /dev/null; then
    echo "❌ Error: ImageMagick not found"
    echo ""
    echo "Install with: brew install imagemagick"
    echo ""
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "======================================"
echo "White Room Screenshot Comparison"
echo "======================================"
echo "Baseline:  $BASELINE_DIR"
echo "Current:   $CURRENT_DIR"
echo "Output:    $OUTPUT_DIR"
echo ""

# Counters
total_comparisons=0
passed_comparisons=0
failed_comparisons=0

# Thresholds
PIXEL_THRESHOLD=10  # Number of different pixels to consider as failure
METRIC_THRESHOLD=0  # AE metric (Absolute Error) threshold

# Compare each screenshot
echo "Comparing screenshots..."
echo ""

for baseline_file in "$BASELINE_DIR"/*.png; do
    # Check if baseline file exists
    if [ ! -f "$baseline_file" ]; then
        continue
    fi

    filename=$(basename "$baseline_file")
    current_file="$CURRENT_DIR/$filename"

    # Check if current file exists
    if [ ! -f "$current_file" ]; then
        echo "⚠️  WARNING: No current file for $filename"
        continue
    fi

    echo "📷 Comparing: $filename"

    # Generate diff output filename
    diff_output="$OUTPUT_DIR/diff_$filename"
    highlighted_output="$OUTPUT_DIR/highlighted_$filename"

    # Compare images and capture metric
    metric_output=$(compare \
        "$baseline_file" \
        "$current_file" \
        -metric AE \
        "$diff_output" \
        2>&1 || true)

    # Also create highlighted diff
    compare \
        "$baseline_file" \
        "$current_file" \
        -highlight-color red \
        -lowlight-color white \
        -compose Src \
        "$highlighted_output" \
        2>/dev/null || true

    # Increment total
    total_comparisons=$((total_comparisons + 1))

    # Check metric
    if [ "$metric_output" -le "$METRIC_THRESHOLD" ]; then
        echo "  ✅ PASS: No significant differences"
        passed_comparisons=$((passed_comparisons + 1))

        # Remove diff output if passed (clean up)
        rm -f "$diff_output" "$highlighted_output"
    else
        echo "  ❌ FAIL: $metric_output different pixels"
        failed_comparisons=$((failed_comparisons + 1))

        # Get file sizes
        baseline_size=$(du -h "$baseline_file" | cut -f1)
        current_size=$(du -h "$current_file" | cut -f1)
        diff_size=$(du -h "$diff_output" | cut -f1)

        echo "     Baseline: $baseline_size"
        echo "     Current:  $current_size"
        echo "     Diff:     $diff_size"
        echo "     Diff file: $diff_output"
    fi

    echo ""
done

echo "======================================"
echo "Comparison Results"
echo "======================================"
echo "Total comparisons:   $total_comparisons"
echo "Passed:              $passed_comparisons"
echo "Failed:              $failed_comparisons"
echo ""

# Summary
if [ $failed_comparisons -eq 0 ]; then
    echo "✅ All screenshots match baseline!"
    echo ""
    exit 0
else
    echo "❌ Visual regressions detected in $failed_comparisons screenshot(s)"
    echo ""
    echo "Diff images saved to: $OUTPUT_DIR"
    echo ""
    exit 1
fi
