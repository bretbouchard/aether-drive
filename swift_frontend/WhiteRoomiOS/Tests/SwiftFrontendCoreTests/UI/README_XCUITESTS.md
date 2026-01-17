# Moving Sidewalk XCUITest Suite

Comprehensive UI automation testing infrastructure for White Room's Moving Sidewalk feature across iOS and tvOS platforms.

## Overview

This XCUITest suite provides real device/simulator UI automation testing for all critical user workflows, covering:

- **iOS Testing**: Touch-based interactions, compact/expanded layouts, iPhone & iPad
- **tvOS Testing**: Focus engine, Siri Remote gestures, 10-foot interface
- **E2E Workflows**: Complete user journeys from launch to save
- **Performance Tests**: UI responsiveness, smooth animations, memory efficiency

## Test Files

### iOS XCUITest Suite
**File**: `MovingSidewalkXCUIUITests.swift` (850+ lines)

**Test Coverage**:
- Navigation (2 tests)
- Song Loading (3 tests)
- Play/Pause Controls (4 tests)
- Tempo Controls (4 tests)
- Volume Controls (3 tests)
- Mute/Solo Controls (3 tests)
- Master Transport (4 tests)
- Sync Modes (3 tests)
- Timeline Scrubbing (3 tests)
- Layout & Responsiveness (3 tests)
- Accessibility (3 tests)
- Performance (3 tests)
- State Persistence (2 tests)
- Error Handling (3 tests)

**Total**: 45+ iOS XCUITests

### tvOS XCUITest Suite
**File**: `MovingSidewalktvOSXCUIUITests.swift` (750+ lines)

**Test Coverage**:
- Focus Engine (7 tests)
- Siri Remote Buttons (4 tests)
- 10-Foot Interface (5 tests)
- Gesture Tests (2 tests)
- Control Tests (3 tests)
- Multi-User (2 tests)
- Performance (3 tests)
- Integration (3 tests)
- Accessibility (2 tests)
- Error Handling (2 tests)
- End-to-End (2 tests)

**Total**: 35+ tvOS XCUITests

### E2E Workflow Suite
**File**: `MultiSongWorkflowE2ETests.swift` (700+ lines)

**Test Coverage**:
- Complete Session Workflows (4 tests)
- Multi-Tab Navigation (2 tests)
- Error Recovery (2 tests)
- Advanced Workflows (2 tests)
- Performance & Stress (2 tests)
- State Management (2 tests)
- Cross-Feature Integration (1 test)
- Accessibility Workflows (1 test)
- Final Verification (1 test)

**Total**: 17+ E2E workflow tests

### Helper Utilities
**File**: `XCUITestHelpers.swift` (650+ lines)

**Features**:
- XCUIApplication extensions
- XCUIElement extensions
- XCUIElementQuery extensions
- XCUIDevice extensions
- Test helper functions
- Data builders
- Custom assertions

## Running Tests

### Xcode

```bash
# Run all iOS UI tests
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:SwiftFrontendCoreTests/MovingSidewalkXCUIUITests

# Run all tvOS UI tests
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOSTvOS \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -only-testing:SwiftFrontendCoreTests/MovingSidewalktvOSXCUIUITests

# Run E2E workflow tests
xcodebuild test \
  -project WhiteRoomiOS.xcodeproj \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:SwiftFrontendCoreTests/MultiSongWorkflowE2ETests
```

### Swift Package Manager

```bash
# Run all tests
swift test --filter "MovingSidewalkXCUIUITests"

# Run specific test
swift test --filter "testNavigateToMovingSidewalk"
```

### Command Line

```bash
# Run with specific simulator
xcrun simctl boot "iPhone 15 Pro"
xcodebuild test \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,id=<device-id>' \
  -only-testing:SwiftFrontendCoreTests/MovingSidewalkXCUIUITests
```

## Test Organization

### Test Structure

```
Tests/SwiftFrontendCoreTests/
├── UI/
│   ├── MovingSidewalkXCUIUITests.swift         # iOS tests (45+)
│   ├── MovingSidewalktvOSXCUIUITests.swift     # tvOS tests (35+)
│   ├── MultiSongWorkflowE2ETests.swift         # E2E tests (17+)
│   └── README_XCUITESTS.md                     # This file
└── Helpers/
    └── XCUITestHelpers.swift                   # Utilities (650+ lines)
```

### Test Categories

1. **Smoke Tests** (5-10 minutes)
   - Basic navigation
   - Element existence
   - Simple interactions

2. **Functional Tests** (20-30 minutes)
   - All features work as expected
   - User flows complete successfully
   - State changes propagate correctly

3. **Integration Tests** (30-45 minutes)
   - Cross-feature interactions
   - State persistence
   - Error handling

4. **E2E Tests** (45-60 minutes)
   - Complete user journeys
   - Real-world usage patterns
   - Performance under load

## Writing New Tests

### Basic Test Template

```swift
func testNewFeature() async throws {
    // Given: Setup test conditions
    try await navigateToMovingSidewalk()
    let element = app.buttons["MyButton"]

    // When: Perform action
    element.tap()

    // Then: Verify outcome
    let result = app.staticTexts["Result"]
    XCUITestAssert.isVisible(result)
}
```

### Using Helpers

```swift
func testWithHelpers() async throws {
    // Navigate
    XCUITestHelper.navigateToTab("Moving Sidewalk", in: app)

    // Wait for element
    guard let button = XCUITestHelper.waitForElement("MyButton", in: app) else {
        XCTFail("Button not found")
        return
    }

    // Safe tap
    XCUITestHelper.safeTap(button)

    // Verify
    XCUITestAssert.isVisible(button)
}
```

### Performance Testing

```swift
func testPerformance() async throws {
    measure {
        // Code to measure
        app.buttons["MyButton"].tap()
    }
}
```

## Test Data

### Mock Data

Tests use mock audio engine to avoid requiring actual audio files:

```swift
app.launchEnvironment = [
    "UITESTING": "1",
    "MOCK_AUDIO_ENGINE": "1"
]
```

### Demo Songs

Test environment includes 6 demo songs:
- Demo Song 0 through Demo Song 5
- Each song is 180 seconds (3 minutes) long
- Default tempo: 120 BPM
- Default volume: 80%

## CI/CD Integration

### GitHub Actions

```yaml
name: XCUITest

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run iOS Tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -only-testing:SwiftFrontendCoreTests/MovingSidewalkXCUIUITests

      - name: Run tvOS Tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOSTvOS \
            -destination 'platform=tvOS Simulator,name=Apple TV' \
            -only-testing:SwiftFrontendCoreTests/MovingSidewalktvOSXCUIUITests
```

### Test Results

Test results are saved to:
```
~/Library/Developer/Xcode/DerivedData/WhiteRoomiOS-*/Logs/Test/
```

### Screenshots

Failed tests automatically capture screenshots:
```
testFunctionName_FAILED.png
```

## Debugging Tests

### Enable Debug Output

```bash
# Enable verbose logging
xcodebuild test \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -verbose \
  -only-testing:SwiftFrontendCoreTests/MovingSidewalkXCUIUITests
```

### Print Element Hierarchy

```swift
XCUITestHelper.printElementHierarchy(app.windows.firstMatch)
```

### Print Screen State

```swift
XCUITestHelper.printScreenState(app)
```

### Capture Screenshot

```swift
XCUITestHelper.captureScreenshot(app, name: "MyScreenshot")
```

## Best Practices

### 1. Use Helpers

Prefer helper functions over raw XCUITest APIs:

```swift
// Good
XCUITestHelper.safeTap(button)

// Avoid
button.tap()
```

### 2. Wait for Elements

Always wait for elements before interacting:

```swift
// Good
guard let button = XCUITestHelper.waitForElement("MyButton", in: app) else {
    XCTFail("Button not found")
    return
}

// Avoid
let button = app.buttons["MyButton"]
button.tap() // May fail if not loaded yet
```

### 3. Use Descriptive Names

Test names should describe what they test:

```swift
// Good
func testPlayAll_StartsAllSongs() async throws

// Avoid
func testPlay() async throws
```

### 4. Assert, Don't Assume

Always verify outcomes:

```swift
// Good
playAllButton.tap()
XCTAssertTrue(verifyAllCardsPlaying(), "All songs should be playing")

// Avoid
playAllButton.tap()
// Assume it worked
```

### 5. Clean Up in tearDown

Ensure tests don't affect each other:

```swift
override func tearDown() async throws {
    // Stop all playback
    app.buttons["Stop All"].tap()

    // Navigate back to start
    app.tabBars.buttons["Home"].tap()

    app = nil
    await super.tearDown()
}
```

## Troubleshooting

### Tests Fail to Launch

**Problem**: Tests fail to find simulator or app won't launch

**Solution**:
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Element Not Found

**Problem**: `waitForExistence` times out

**Solution**:
```swift
// Increase timeout
element.waitForExistence(timeout: 10)

// Check if element exists in hierarchy
XCUITestHelper.printElementHierarchy(app.windows.firstMatch)

// Verify accessibility identifier is set
// In code:
// button.accessibilityIdentifier = "MyButton"
```

### Tests Flakey

**Problem**: Tests pass sometimes, fail sometimes

**Solution**:
```swift
// Add explicit waits
try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

// Use more robust selectors
// Instead of:
app.buttons["Play"].tap()

// Use:
app.buttons.matching(identifier: "Play").firstMatch.tap()
```

### Performance Issues

**Problem**: Tests take too long

**Solution**:
- Run tests in parallel (different simulators)
- Use `continueAfterFailure = false` to stop on first failure
- Disable animations in test environment
- Use `measure` blocks to identify slow tests

## Coverage

### Current Coverage

- **iOS**: 45+ tests covering all major features
- **tvOS**: 35+ tests covering focus engine and Siri Remote
- **E2E**: 17+ complete workflow tests

### Coverage Goals

- [ ] 90%+ UI element coverage
- [ ] 100% critical user flow coverage
- [ ] All accessibility paths tested
- [ ] All error conditions tested

## Contributing

### Adding New Tests

1. Choose appropriate file:
   - `MovingSidewalkXCUIUITests.swift` for iOS tests
   - `MovingSidewalktvOSXCUIUITests.swift` for tvOS tests
   - `MultiSongWorkflowE2ETests.swift` for E2E tests

2. Follow naming convention:
   ```swift
   func test<Feature>_<Action>_<Outcome>() async throws
   ```

3. Use helpers:
   ```swift
   try await navigateToMovingSidewalk()
   XCUITestHelper.safeTap(button)
   XCUITestAssert.isVisible(result)
   ```

4. Add comments for complex tests

### Code Review Checklist

- [ ] Test follows naming convention
- [ ] Test uses helpers where appropriate
- [ ] Test has clear Given/When/Then structure
- [ ] Test cleans up after itself
- [ ] Test has descriptive failure messages
- [ ] Test is independent (no dependencies on other tests)

## Resources

### Documentation

- [XCUITest Documentation](https://developer.apple.com/documentation/xctest/xcuitest)
- [Testing with Xcode](https://developer.apple.com/documentation/xcode/testing)
- [Accessibility Testing](https://developer.apple.com/documentation/xctest/accessibility_testing)

### Tools

- [Xcode](https://developer.apple.com/xcode/) - Test runner
- [xcrun](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) - Command-line tool
- [simctl](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) - Simulator control

### Community

- [Swift Forums](https://forums.swift.org/) - Swift testing discussions
- [Stack Overflow](https://stackoverflow.com/questions/tagged/xctest) - XCUITest Q&A

## License

Copyright © 2026 White Room. All rights reserved.
