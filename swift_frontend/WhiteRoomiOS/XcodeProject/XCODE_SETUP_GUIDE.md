# Xcode Project Setup Guide for XCUITest Phase 2

## Step-by-Step Instructions

### Option 1: Create New Xcode Project

#### Step 1: Create New Project
```bash
# Open Xcode
open -a Xcode

# Or from command line:
cd /Users/bretbouchard/apps/schill/white_room/swift_frontend/WhiteRoomiOS/XcodeProject
```

1. **File → New → Project**
2. **iOS → App**
3. **Product Name:** `WhiteRoomiOS`
4. **Interface:** SwiftUI
5. **Language:** Swift
6. **Storage:** None
7. **Include Tests:** ✅ (check both "Tests" and "UI Tests")

#### Step 2: Replace App File
1. Delete the default `WhiteRoomiOSApp.swift` created by Xcode
2. Drag in our `WhiteRoomiOSApp.swift` from `XcodeProject/`
3. Make sure it's added to the **WhiteRoomiOS** target (not test target)

#### Step 3: Add Test Files
1. Delete default test files in `WhiteRoomiOSUITests/`
2. Drag all files from `UITests/` folder into Xcode project
3. Make sure they're added to the **WhiteRoomiOSUITests** target

#### Step 4: Configure Project
1. Select project in navigator
2. Choose WhiteRoomiOS target
3. **General Tab:**
   - Deployment Target: iOS 15.0
   - Devices: iPhone
4. **Build Settings Tab:**
   - Swift Language Version: Swift 5.7+
   - Enable Testability: Yes

#### Step 5: Run Tests
```bash
# In Xcode: Product → Test (⌘U)
# Or select specific test suite and run
```

### Option 2: Add to Existing Xcode Project

#### Step 1: Add UITests Target (if not present)
1. File → New → Target
2. **iOS → UI Testing Bundle**
3. **Product Name:** `WhiteRoomiOSUITests`
4. **Project:** WhiteRoomiOS
5. **Target to be Tested:** WhiteRoomiOS

#### Step 2: Add App File
1. Drag `WhiteRoomiOSApp.swift` into project
2. Add to **WhiteRoomiOS** target

#### Step 3: Add Test Files
1. Drag all `UITests/*.swift` files into project
2. Add to **WhiteRoomiOSUITests** target

#### Step 4: Update Info.plist
Add to supporting files:

```xml
<key>UIFileSharingEnabled</key>
<false/>
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

### Option 3: Command Line Creation

```bash
cd /Users/bretbouchard/apps/schill/white_room/swift_frontend/WhiteRoomiOS/XcodeProject

# Generate Xcode project structure
mkdir -p WhiteRoomiOS
mkdir -p WhiteRoomiOSUITests

# Copy files
cp WhiteRoomiOSApp.swift WhiteRoomiOS/
cp UITests/*.swift WhiteRoomiOSUITests/

# Create placeholder Info.plist files
touch WhiteRoomiOS/Info.plist
touch WhiteRoomiOSUITests/Info.plist

# Open in Xcode to complete setup
open -a Xcode WhiteRoomiOSApp.swift
```

## Project Structure

```
WhiteRoomiOS/
├── WhiteRoomiOS/
│   ├── WhiteRoomiOSApp.swift          # Main app file
│   ├── Info.plist                     # App configuration
│   ├── Assets.xcassets                # Images, colors
│   └── Preview Content/
│
├── WhiteRoomiOSUITests/
│   ├── PerformanceBaselineTests.swift
│   ├── AccessibilityE2ETests.swift
│   ├── GestureTests.swift
│   ├── MockDataIntegrationTests.swift
│   └── Info.plist
│
└── WhiteRoomiOS.xcodeproj             # Project file
```

## Configuration Checklist

### App Target (WhiteRoomiOS)
- [x] Deployment Target: iOS 15.0+
- [x] SwiftUI framework linked
- [x] XCTest framework linked
- [ ] WhiteRoomiOSApp.swift added
- [ ] Accessibility permissions in Info.plist

### UITests Target (WhiteRoomiOSUITests)
- [x] XCTest framework linked
- [x] XCUITest framework linked
- [ ] All 4 test files added
- [ ] Target under test: WhiteRoomiOS
- [ ] Host Application: WhiteRoomiOS

## Build Settings

### Required Settings

```bash
# For App Target
SWIFT_VERSION = 5.7
IPHONEOS_DEPLOYMENT_TARGET = 15.0
ENABLE_TESTABILITY = YES

# For UITests Target
SWIFT_VERSION = 5.7
IPHONEOS_DEPLOYMENT_TARGET = 15.0
TARGETED_DEVICE_FAMILY = 1,2  # iPhone, iPad
```

## Scheme Configuration

### Create Test Scheme
1. Product → Scheme → Manage Schemes
2. Edit WhiteRoomiOS scheme
3. **Test** tab:
   - Check WhiteRoomiOSUITests
   - Configure to run on iPhone 15 Pro
   - Parallelize: Yes

### Share Scheme
1. Check "Shared" box in scheme editor
2. Commit to git

## Running Tests

### In Xcode
```bash
# All tests
⌘U (Product → Test)

# Specific test
Right-click test method → Run "testName()"

# Specific test suite
Product → Test → Select test suite in navigator
```

### Command Line
```bash
# All tests
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Specific test
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOS \
  -only-testing:WhiteRoomiOSUITests/PerformanceBaselineTests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Generate results bundle
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath TestResults.xcresult
```

## Troubleshooting

### Issue: Tests not finding elements
**Solution:**
1. Verify `.accessibilityIdentifier()` is set in SwiftUI code
2. Check element exists in view hierarchy
3. Increase `waitForExistence(timeout:)` value

### Issue: "Missing required module"
**Solution:**
1. Clean build folder (⌘⇧K)
2. Delete derived data
3. Rebuild project

### Issue: Tests timing out
**Solution:**
1. Increase timeout in `waitForExistence(timeout:)`
2. Check for infinite loops in code
3. Verify app isn't crashing

### Issue: "No such module"
**Solution:**
1. Add SwiftUI framework to target
2. Add XCTest framework to test target
3. Clean and rebuild

## Verification

### Step 1: Build
```bash
⌘B (Product → Build)
```
Should succeed with 0 errors, 0 warnings.

### Step 2: Run App
```bash
⌘R (Product → Run)
```
Should launch in simulator with:
- Tab bar with 3 tabs
- Moving Sidewalk tab showing 6 cards
- Each card has play button and slider

### Step 3: Run Tests
```bash
⌘U (Product → Test)
```
Should run 62 tests:
- 13 PerformanceBaselineTests
- 11 AccessibilityE2ETests
- 31 GestureTests
- 7 MockDataIntegrationTests

### Step 4: Check Results
```bash
# View test results in Xcode:
# Navigator → Test Navigator (⌘6)
# All tests should pass ✅
```

## Next Steps

1. ✅ Create Xcode project using guide above
2. ✅ Add all test files to project
3. ✅ Run initial test suite
4. ✅ Fix any runtime issues
5. ✅ Generate baseline metrics
6. ✅ Set up CI/CD workflow

## Support

### Documentation
- **Complete Summary:** `XCUITEST_PHASE2_SUMMARY.md`
- **Quick Reference:** `README.md`
- **Setup Guide:** This file

### Test Files
- **Performance:** `UITests/PerformanceBaselineTests.swift`
- **Accessibility:** `UITests/AccessibilityE2ETests.swift`
- **Gestures:** `UITests/GestureTests.swift`
- **Integration:** `UITests/MockDataIntegrationTests.swift`

### Common Issues
- See "Troubleshooting" section above
- Check Xcode console output
- Review simulator logs
- Verify accessibility identifiers

---

**Status:** Ready for Xcode project creation
**Files:** 5 Swift files ready to integrate
**Tests:** 62 tests across 4 suites
**Documentation:** Complete guides provided
