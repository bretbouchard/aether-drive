# XCUITest Phase 2 - Quick Reference

## Overview
Comprehensive E2E testing infrastructure for White Room iOS app with 62 tests across 4 test suites.

## File Structure
```
swift_frontend/WhiteRoomiOS/XcodeProject/
├── WhiteRoomiOSApp.swift              # iOS app target (168 lines)
├── UITests/
│   ├── PerformanceBaselineTests.swift  # 13 performance tests (578 lines)
│   ├── AccessibilityE2ETests.swift     # 11 accessibility tests (642 lines)
│   ├── GestureTests.swift              # 31 gesture tests (724 lines)
│   └── MockDataIntegrationTests.swift  # 7 integration tests (476 lines)
├── XCUITEST_PHASE2_SUMMARY.md          # Complete documentation
└── README.md                           # This file
```

## Quick Start

### 1. Create Xcode Project
```bash
# Open Xcode
# File → New → Project → iOS App
# Name: WhiteRoomiOS
# Interface: SwiftUI
# Include Tests: ✅ (check both boxes)

# Add UITests target if not created automatically
# File → New → Target → iOS UI Testing Bundle
```

### 2. Add Files to Project
```bash
# Drag these files into your Xcode project:
# - WhiteRoomiOSApp.swift → App target
# - UITests/*.swift → UITests target
```

### 3. Run Tests
```bash
# In Xcode: ⌘U (Product → Test)
# Or command line:
xcodebuild test -project WhiteRoomiOS.xcodeproj -scheme WhiteRoomiOS
```

## Test Suites

### PerformanceBaselineTests (13 tests)
- Launch time <2s
- Song loading <3s
- Button response <100ms
- Slider update <50ms
- Memory <500MB
- CPU usage validation

**Run:** `xcodebuild test -only-testing:WhiteRoomiOSUITests/PerformanceBaselineTests`

### AccessibilityE2ETests (11 tests)
- Complete a11y audit
- VoiceOver navigation
- Tap targets 44x44pt
- Dynamic type support
- Color contrast WCAG AA
- Reduced motion

**Run:** `xcodebuild test -only-testing:WhiteRoomiOSUITests/AccessibilityE2ETests`

### GestureTests (31 tests)
- Single/double tap
- Horizontal/vertical swipe
- Drag sliders
- Pinch zoom
- Long press
- Pan gestures
- Rotation

**Run:** `xcodebuild test -only-testing:WhiteRoomiOSUITests/GestureTests`

### MockDataIntegrationTests (7 tests)
- Fixture integration
- Edge case testing
- State restoration
- Performance with fixtures
- Error handling

**Run:** `xcodebuild test -only-testing:WhiteRoomiOSUITests/MockDataIntegrationTests`

## Launch Arguments

Pass these to `app.launchArguments` before `app.launch()`:

```swift
// Performance testing
app.launchArguments = ["PERFORMANCE_TEST"]

// Accessibility testing
app.launchArguments = ["ACCESSIBILITY_TEST"]

// Gesture testing
app.launchArguments = ["GESTURE_TEST"]

// Mock data testing
app.launchArguments = ["MOCK_DATA_TEST"]

// Dynamic type
app.launchArguments = ["DYNAMIC_TYPE=accessibilityExtraLarge"]

// Dark mode
app.launchArguments = ["DARK_MODE"]

// Reduced motion
app.launchArguments = ["REDUCED_MOTION"]
```

## Accessibility Identifiers

Required in SwiftUI code:

```swift
// View
.accessibilityIdentifier("MovingSidewalkView")
.accessibilityIdentifier("SongPlayerCard")
.accessibilityIdentifier("LibraryView")
.accessibilityIdentifier("SettingsView")

// Controls
.accessibilityIdentifier("Play")
.accessibilityIdentifier("Pause")
.accessibilityIdentifier("Tempo")
.accessibilityIdentifier("Load Slot \(i)")
```

## Performance Baselines

| Metric | Target | Test |
|--------|--------|------|
| Launch Time | <2s | `testLaunchTime_CompletesWithinBaseline` |
| Load 6 Songs | <3s | `testLoadSong_CompletesWithinBaseline` |
| Button Response | <100ms | `testPlayButtonResponse_WithinBaseline` |
| Slider Update | <50ms | `testSliderUpdate_WithinBaseline` |
| Memory Usage | <500MB | `testSixSongPlayback_PerformanceWithinBaseline` |

## Accessibility Standards

| Requirement | Standard | Test |
|-------------|----------|------|
| Tap Targets | 44x44pt minimum | `testAllInteractiveElements_MeetTapTargetSize` |
| Color Contrast | WCAG AA 4.5:1 | `testColorContrast_WCAGCompliant` |
| VoiceOver | All elements labeled | `testVoiceOver_CompleteWorkflow_Navigable` |
| Dynamic Type | XS to AXXL | `testDynamicType_AllSizes_Readable` |

## CI/CD Integration

```yaml
- name: Run XCUITests
  run: |
    xcodebuild test \
      -project WhiteRoomiOS.xcodeproj \
      -scheme WhiteRoomiOS \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -resultBundlePath TestResults.xcresult
```

## Troubleshooting

### Tests not finding elements
**Solution:** Add `.accessibilityIdentifier()` to SwiftUI views

### Tests timing out
**Solution:** Increase `waitForExistence(timeout:)` value

### Performance tests failing
**Solution:** Run in Release configuration, not Debug

### Accessibility tests failing
**Solution:** Add `.accessibilityLabel()` to all interactive elements

## Integration Points

- **Agent 2 (SwiftUI Tests):** Uses `XCUITestFixtures` for mock data
- **Agent 4 (Performance):** Validates performance baselines
- **Agent 5 (Accessibility):** Uses accessibility audit tools

## Summary

- **62 total tests** across 4 test suites
- **2,588 lines** of test code
- **13 performance** tests with baselines
- **11 accessibility** tests with WCAG validation
- **31 gesture** tests covering all touch interactions
- **7 integration** tests using mock fixtures

## Next Steps

1. Create Xcode project with UITests target
2. Add all test files to project
3. Run initial test suite (⌘U)
4. Fix any runtime issues
5. Establish baseline metrics
6. Set up CI/CD workflow

## Documentation

See `XCUITEST_PHASE2_SUMMARY.md` for complete documentation including:
- Detailed test descriptions
- Integration guides
- Performance metrics
- CI/CD examples
- Maintenance procedures

---

**Status:** ✅ Complete - Ready for Xcode integration
**Agent:** Agent 9 (XCUITest Integration Specialist)
**Phase:** 2 - Performance, Accessibility, Gesture Testing
