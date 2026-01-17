#!/bin/bash

# =============================================================================
# Take Screenshots Script
# =============================================================================
#
# Captures screenshots of the app for visual regression testing.
# Supports multiple devices, themes, and configurations.
#
# Usage: ./Scripts/take-screenshots.sh [output_dir]
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-$PROJECT_DIR/Screenshots}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "======================================"
echo "White Room Screenshot Capture"
echo "======================================"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Define configurations
DEVICES=("iPhone 14 Pro" "iPad Pro (12.9-inch) (6th generation)")
THEMES=("Light" "Dark")
SCREENS=("MovingSidewalk")

# Build the app first
echo "Building app..."
cd "$PROJECT_DIR"

if [ -f "Package.swift" ]; then
    # Swift Package Manager build
    swift build -c release
else
    # Xcode build
    xcodebuild build \
        -project WhiteRoomiOSProject/WhiteRoomiOS.xcodeproj \
        -scheme WhiteRoomiOS \
        -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
        -quiet
fi

echo "Build complete!"
echo ""

# Function to take a screenshot
take_screenshot() {
    local device_name="$1"
    local theme="$2"
    local screen_name="$3"
    local output_path="$4"

    echo "  Capturing: $screen_name on $device_name ($theme mode)"

    # Boot device if needed
    xcrun simctl boot "$device_name" 2>/dev/null || true

    # Wait for device to be ready
    sleep 2

    # Take screenshot
    local filename="${screen_name}_${device_name// /_}_${theme}.png"
    xcrun simctl io "$device_name" screenshot "$output_path/$filename" --mask=BLACK

    # Wait for capture
    sleep 1
}

# Take screenshots for each configuration
echo "Capturing screenshots..."
echo ""

for device in "${DEVICES[@]}"; do
    echo "Device: $device"

    for theme in "${THEMES[@]}"; do
        echo "  Theme: $theme"

        for screen in "${SCREENS[@]}"; do
            take_screenshot "$device" "$theme" "$screen" "$OUTPUT_DIR"
        done
    done

    echo ""
done

echo "======================================"
echo "Screenshot capture complete!"
echo "======================================"
echo "Screenshots saved to: $OUTPUT_DIR"
echo ""

# Count screenshots
screenshot_count=$(find "$OUTPUT_DIR" -name "*.png" | wc -l | tr -d ' ')
echo "Total screenshots captured: $screenshot_count"
echo ""

# List captured screenshots
echo "Captured screenshots:"
ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo "✅ Screenshot capture complete!"
