#!/bin/bash

###############################################################################
# Deploy White Room to Living Room Apple TV
#
# This script builds and deploys the White Room app to the Apple TV
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Deploying White Room to Living Room Apple TV...${NC}"

# Change to swift_frontend directory
cd swift_frontend

# Find the Apple TV device ID
APPLE_TV_ID=$(xcrun devicectl list devices 2>&1 | grep "Living Room" | awk '{print $4}' || true)

if [ -z "$APPLE_TV_ID" ]; then
    echo -e "${RED}❌ Could not find Living Room Apple TV${NC}"
    echo "Please ensure your Apple TV is:"
    echo "  - Powered on and connected to the same network"
    echo "  - Paired with this Mac (check Xcode → Window → Devices and Simulators)"
    exit 1
fi

echo -e "${GREEN}✅ Found Apple TV: $APPLE_TV_ID${NC}"

# Build and install
echo -e "${YELLOW}📦 Building app...${NC}"

xcodebuild -project WhiteRoomiOS.xcodeproj \
    -scheme WhiteRoomiOS \
    -sdk appletvos \
    -configuration Debug \
    -destination "id=$APPLE_TV_ID" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=68SDK93S22 \
    build \
    || {
        echo -e "${RED}❌ Build failed${NC}"
        echo ""
        echo "If you see provisioning errors, try:"
        echo "  1. Open Xcode: open WhiteRoomiOS.xcodeproj"
        echo "  2. Select your Apple TV as destination"
        echo "  3. Product → Run (⌘R)"
        echo ""
        echo "Or manually enable signing in project settings"
        exit 1
    }

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${GREEN}✅ App should now be on your Apple TV!${NC}"
echo ""
echo "To verify:"
echo "  1. Check your Apple TV for the White Room app"
echo "  2. Launch the app"
echo "  3. Tap 'Browse Demo Songs'"
echo "  4. Verify 83 songs load"
echo "  5. Select a song and confirm it does NOT auto-play"
