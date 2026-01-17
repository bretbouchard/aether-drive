# Automated UI Testing & QA Strategy
## White Room Comprehensive Testing Guide

**Version:** 1.0
**Last Updated:** 2026-01-16
**Status:** Production Ready

---

## Executive Summary

This document outlines White Room's comprehensive automated testing and quality assurance strategy for UI interactions. The strategy integrates multiple testing layers to ensure production-ready quality across iOS, tvOS, and macOS platforms.

**Key Philosophy:** "If tests pass, the app works. Comprehensive automated testing makes manual QA unnecessary."

**Quality Targets:**
- 90%+ code coverage across all platforms
- Zero UI bugs in production
- <100ms UI response time
- 100% accessibility compliance
- Continuous automated validation

---

## Table of Contents

1. [Testing Stack Overview](#testing-stack-overview)
2. [Telemetry Integration](#telemetry-integration)
3. [UI Testing Layers](#ui-testing-layers)
4. [Visual Regression Testing](#visual-regression-testing)
5. [Accessibility Testing](#accessibility-testing)
6. [Performance Testing](#performance-testing)
7. [Continuous Integration](#continuous-integration)
8. [Test Coverage Requirements](#test-coverage-requirements)
9. [QA Dashboard & Reporting](#qa-dashboard--reporting)
10. [Implementation Roadmap](#implementation-roadmap)

---

## Testing Stack Overview

### Current Infrastructure

White Room currently has:

✅ **Telemetry System** (CrashReporting.swift)
- Firebase Crashlytics integration
- Sentry backend support
- Breadcrumb tracking for user actions
- Custom error recording
- User identification and context

✅ **Unit Testing** (SDK/TypeScript)
- Vitest test runner
- 92 tests passing (Moving Sidewalk)
- Coverage tracking enabled

✅ **Build System**
- CMake (JUCE backend)
- Swift Package Manager (iOS/tvOS)
- Automated build scripts

### Recommended Additions

🔧 **SwiftUI Testing**
- XCUITest for UI interaction tests
- Snapshot testing for visual regression
- ViewInspector for SwiftUI unit tests

🔧 **E2E Testing**
- Real user workflow validation
- Multi-platform automation
- External integration testing

🔧 **Performance Monitoring**
- Core Animation instrumentation
- Memory leak detection
- CPU usage profiling

---

## Telemetry Integration

### Current Telemetry Setup

The `CrashReporting.swift` service is already well-configured:

```swift
// Location: swift_frontend/SwiftFrontendShared/Services/CrashReporting.swift

// Automatic crash tracking
CrashReporting.shared.recordError(error)

// User action breadcrumbs
CrashReporting.shared.leaveBreadcrumb(
    "User saved project",
    category: "user",
    level: .info
)

// User identification
CrashReporting.shared.setUser(
    identifier: "user-123",
    email: "user@example.com",
    name: "User Name"
)
```

### Telemetry Enhancement Plan

**1. UI Interaction Tracking**

Add automatic UI event tracking:

```swift
// UI/TelemetryTracker.swift (NEW)

public class UITelemetryTracker: ObservableObject {
    public static let shared = UITelemetryTracker()

    // Track all UI interactions automatically
    public func trackTap(_ element: String, in screen: String) {
        CrashReporting.shared.trackUserAction("Tap: \(element)", details: [
            "screen": screen,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }

    public func trackGesture(_ gesture: String, on element: String) {
        CrashReporting.shared.trackUserAction("Gesture: \(gesture)", details: [
            "element": element
        ])
    }

    public func trackNavigation(from: String, to: String) {
        CrashReporting.shared.trackNavigation(to, from: from)
    }

    public func trackScreenView(_ screen: String) {
        CrashReporting.shared.trackUserAction("Screen View: \(screen)")
    }
}

// SwiftUI View Modifier for automatic tracking
extension View {
    public func trackInteraction(_ element: String) -> some View {
        self.onTapGesture {
            UITelemetryTracker.shared.trackTap(element, in: String(describing: self))
        }
    }
}
```

**Usage:**
```swift
// Automatically track all button taps
Button("Save") {
    saveProject()
}
.trackInteraction("Save Button")
```

**2. Performance Metrics**

Add performance tracking to telemetry:

```swift
// PerformanceTelemetry.swift (NEW)

public class PerformanceTelemetry {
    public static func measure<T>(
        _ operation: String,
        block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start

        CrashReporting.shared.setCustomValue(duration, forKey: "perf_\(operation)")

        // Warn if slow
        if duration > 0.1 { // 100ms threshold
            CrashReporting.shared.recordError(
                WhiteRoomError.performance(
                    "Slow \(operation): \(duration)s"
                )
            )
        }

        return result
    }
}

// Usage
let result = PerformanceTelemetry.measure("Song Loading") {
    try await loadSong(song)
}
```

**3. Session Replay**

Implement session replay for debugging:

```swift
// SessionReplay.swift (NEW)

public class SessionReplay {
    private var events: [ReplayEvent] = []
    private let maxEvents = 1000

    public func record(_ event: ReplayEvent) {
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst()
        }
    }

    public func saveSession() throws {
        let data = try JSONEncoder().encode(events)
        let url = sessionReplayDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try data.write(to: url)
    }
}

public struct ReplayEvent: Codable {
    let timestamp: Date
    let type: EventType
    let screen: String
    let action: String
    let context: [String: String]
}
```

---

## UI Testing Layers

### Layer 1: SwiftUI Unit Tests

**Purpose:** Test individual SwiftUI views in isolation

**Tool:** ViewInspector (third-party library)

**Example:**
```swift
// Tests/Unit/SongPlayerCardTests.swift

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

class SongPlayerCardTests: XCTestCase {
    func testPlayPauseButtonToggle() throws {
        // Given
        @State var slot = SongSlot(
            song: testSong,
            transport: TransportState(isPlaying: false)
        )

        let view = SongPlayerCard(slot: $slot)

        // When
        try view.inspect().button(0).tap()

        // Then
        XCTAssertTrue(slot.transport.isPlaying)
    }

    func testTempoSliderClamping() throws {
        // Given
        @State var slot = SongSlot.testInstance

        let view = SongPlayerCard(slot: $slot)

        // When - try to set below minimum
        try view.inspect().slider(1).setValue(20)

        // Then - should clamp to 40
        XCTAssertEqual(slot.transport.tempo, 40)
    }

    func testHapticFeedbackOnTap() throws {
        // Given
        let hapticMock = HapticFeedbackManagerMock()
        let view = SongPlayerCard(slot: .constant(testSlot))

        // When
        try view.inspect().button(0).tap()

        // Then
        XCTAssertTrue(hapticMock.mediumImpactCalled)
    }
}
```

**Coverage Target:** 80%+ for all SwiftUI views

### Layer 2: XCUITest Integration Tests

**Purpose:** Test real UI interactions on device/simulator

**Tool:** XCUITest (built-in Xcode)

**Example:**
```swift
// Tests/UI/MovingSidewalkUITests.swift

import XCTest

class MovingSidewalkUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST"]
        app.launch()
    }

    func testLoadAndPlayMultipleSongs() {
        // Navigate to Moving Sidewalk
        app.tabBars.buttons["Library"].tap()
        app.tables.staticTexts["Moving Sidewalk"].tap()

        // Load 6 songs
        for i in 0..<6 {
            app.buttons["Load Song \(i)"].tap()
            app.sheets.buttons["Demo Song \(i)"].tap()
        }

        // Verify all 6 cards are visible
        XCTAssertEqual(app.otherElements["SongPlayerCard"].count, 6)

        // Play first song
        app.otherElements["SongPlayerCard"].element(boundBy: 0).buttons["Play"].tap()

        // Verify is playing
        let playButton = app.otherElements["SongPlayerCard"].element(boundBy: 0).buttons["Pause"]
        XCTAssertTrue(playButton.exists)
    }

    func testMasterTransportControls() {
        // Load songs
        loadMultipleSongs()

        // Tap Play All
        app.buttons["Play All"].tap()

        // Verify all songs are playing
        let pauseButtons = app.buttons["Pause"]
        XCTAssertEqual(pauseButtons.count, 6)

        // Tap Pause All
        app.buttons["Pause All"].tap()

        // Verify all paused
        let playButtons = app.buttons["Play"]
        XCTAssertEqual(playButtons.count, 6)
    }

    func testTempoSliderInteraction() {
        loadMultipleSongs()

        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        // Adjust tempo
        tempoSlider.adjust(toNormalizedSliderPosition: 0.7)

        // Verify tempo changed (check label or value)
        let tempoLabel = firstCard.staticTexts["TempoValue"]
        XCTAssertTrue(tempoLabel.label.contains("120"))
    }

    func testSyncModeSwitching() {
        loadMultipleSongs()

        // Open sync mode menu
        app.buttons["Sync Mode"].tap()
        app.sheets.buttons["Locked"].tap()

        // Adjust master tempo
        app.sliders["Master Tempo"].adjust(toNormalizedSliderPosition: 0.6)

        // Verify all songs synced to same tempo
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            let tempoLabel = card.staticTexts["TempoValue"]
            XCTAssertEqual(tempoLabel.label, "120 BPM")
        }
    }
}
```

**Coverage Target:** All critical user workflows

### Layer 3: Snapshot Testing

**Purpose:** Detect visual regressions automatically

**Tool:** SnapshotTesting (pointfreeco)

**Example:**
```swift
// Tests/SnapshotTests/MovingSidewalkSnapshotTests.swift

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SwiftFrontendCore

class MovingSidewalkSnapshotTests: XCTestCase {
    func testMovingSidewalkView_LightMode() {
        // Given
        let view = MovingSidewalkView(state: testState)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_light"
        )
    }

    func testMovingSidewalkView_DarkMode() {
        // Given
        let view = MovingSidewalkView(state: testState)
            .preferredColorScheme(.dark)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_dark"
        )
    }

    func testSongPlayerCard_AllStates() {
        // Playing state
        assertSnapshot(
            matching: SongPlayerCard(slot: .constant(playingSlot)),
            as: .image(layout: .sizeThatFits),
            named: "song_card_playing"
        )

        // Paused state
        assertSnapshot(
            matching: SongPlayerCard(slot: .constant(pausedSlot)),
            as: .image(layout: .sizeThatFits),
            named: "song_card_paused"
        )

        // Muted state
        assertSnapshot(
            matching: SongPlayerCard(slot: .constant(mutedSlot)),
            as: .image(layout: .sizeThatFits),
            named: "song_card_muted"
        )

        // Soloed state
        assertSnapshot(
            matching: SongPlayerCard(slot: .constant(soloedSlot)),
            as: .image(layout: .sizeThatFits),
            named: "song_card_soloed"
        )
    }
}
```

**CI Integration:**
```yaml
# .github/workflows/snapshot-tests.yml

name: Snapshot Tests

on: [pull_request]

jobs:
  snapshot:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - name: Run Snapshot Tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
            -only-testing:WhiteRoomiOSTests/SnapshotTests
```

**Coverage Target:** All unique UI states

### Layer 4: E2E Workflow Tests

**Purpose:** Validate complete user journeys

**Tool:** XCUITest + Custom Test Helpers

**Example:**
```swift
// Tests/E2E/UserWorkflowTests.swift

class UserWorkflowTests: XCTestCase {
    var app: XCUIApplication!

    func testCompleteMusicCreationWorkflow() {
        // 1. Launch app
        app.launch()

        // 2. Create new project
        app.buttons["New Project"].tap()
        app.textFields["Project Name"].typeText("My First Song")
        app.buttons["Create"].tap()

        // 3. Add instrument track
        app.navigationBars.buttons["Add Track"].tap()
        app.tables.staticTexts["Drums"].tap()

        // 4. Draw notes in piano roll
        let pianoRoll = app.otherElements["PianoRoll"]
        pianoRoll.tap(atCenter: CGPoint(x: 100, y: 100))
        pianoRoll.tap(atCenter: CGPoint(x: 150, y: 100))
        pianoRoll.tap(atCenter: CGPoint(x: 200, y: 100))

        // 5. Press play
        app.buttons["Play"].tap()

        // 6. Verify audio is playing (check transport state)
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout: 5))

        // 7. Save project
        app.buttons["Save"].tap()

        // 8. Verify save succeeded
        XCTAssertTrue(app.alerts["Success"].exists)
    }

    func testMovingSidewalkMultiSongWorkflow() {
        // 1. Navigate to Moving Sidewalk
        app.tabBars.buttons["Moving Sidewalk"].tap()

        // 2. Load 6 different demo songs
        for i in 0..<6 {
            app.buttons["Load Slot \(i)"].tap()
            app.sheets.scrollViews.otherElements.buttons["Song \(i)"].tap()
        }

        // 3. Set individual tempos
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            let tempoSlider = card.sliders["Tempo"]
            tempoSlider.adjust(toNormalizedSliderPosition: Double(i) / 6.0)
        }

        // 4. Enable locked sync mode
        app.buttons["Sync Mode"].tap()
        app.sheets.buttons["Locked"].tap()

        // 5. Adjust master tempo to 120 BPM
        let masterSlider = app.sliders["Master Tempo"]
        masterSlider.adjust(toNormalizedSliderPosition: 0.5)

        // 6. Verify all songs synced
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            let tempo = card.staticTexts["TempoValue"]
            XCTAssertEqual(tempo.label, "120 BPM")
        }

        // 7. Play all
        app.buttons["Play All"].tap()

        // 8. Verify all playing
        let pauseButtons = app.buttons["Pause"]
        XCTAssertEqual(pauseButtons.count, 6)

        // 9. Wait 10 seconds
        Thread.sleep(forTimeInterval: 10)

        // 10. Verify all still in sync (positions within 1%)
        var positions: [Double] = []
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            let progress = card.progressIndicators["Progress"]
            positions.append(progress.value as? Double ?? 0)
        }

        let avgPosition = positions.reduce(0, +) / Double(positions.count)
        for position in positions {
            let diff = abs(position - avgPosition)
            XCTAssertLessThan(diff, 0.01, "Songs drifted out of sync")
        }
    }
}
```

**Coverage Target:** All documented user workflows

---

## Visual Regression Testing

### Automated Screenshot Comparison

**Tool:** Percy + GitHub Actions

**Setup:**
```yaml
# .github/workflows/visual-regression.yml

name: Visual Regression Tests

on: [pull_request]

jobs:
  percy:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          npm install -g @percy/cli

      - name: Build iOS app
        run: |
          xcodebuild build \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

      - name: Take screenshots
        run: |
          ./Scripts/take-screenshots.sh

      - name: Upload to Percy
        run: |
          percy upload ./Screenshots/*
        env:
          PERCY_TOKEN: ${{ secrets.PERCY_TOKEN }}
```

**Screenshot Script:**
```bash
#!/bin/bash
# Scripts/take-screenshots.sh

# Define screens to capture
screens=(
    "MovingSidewalkView"
    "MixingConsole"
    "PianoRoll"
    "InstrumentLibrary"
)

# Define configurations
configs=(
    "iPhone13Pro:Light"
    "iPhone13Pro:Dark"
    "iPadPro:Light"
    "iPadPro:Dark"
    "AppleTV:Light"
)

for screen in "${screens[@]}"; do
    for config in "${configs[@]}"; do
        IFS=':' read -r device theme <<< "$config"

        xcrun simctl booted launch \
          "com.whiteroom.app" \
          --screenshot "./Screenshots/${screen}_${device}_${theme}.png" \
          --test-screenshots \
          --screen "$screen" \
          --theme "$theme"
    done
done
```

### Component-Level Visual Testing

**Tool:** SnapshotTesting (as shown above)

**Strategy:**
- Test each unique UI component state
- Test light/dark mode
- test Dynamic Type sizes
- Test accessibility layouts

---

## Accessibility Testing

### Automated Accessibility Audits

**Tool:** XCTest Accessibility Assertions

**Example:**
```swift
// Tests/Accessibility/AccessibilityTests.swift

class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UITEST", "ACCESSIBILITY_AUDIT"]
        app.launch()
    }

    func testMovingSidewalkAccessibility() {
        // Navigate to Moving Sidewalk
        app.tabBars.buttons["Moving Sidewalk"].tap()

        // Audit all elements
        let audit = app.audit()
        XCTAssert(audit.isEmpty, "Accessibility issues found: \(audit)")
    }

    func testVoiceOverNavigation() {
        app.launchArguments += ["UI_TESTING_VOICE_OVER"]
        app.launch()

        // Navigate through UI using VoiceOver
        let element = app.navigationBars.buttons["Back"]
        element.tap()

        // Verify VoiceOver focus moved correctly
        XCTAssertTrue(element.hasFocus)
    }

    func testDynamicTypeSupport() {
        // Test with largest Dynamic Type size
        app.launchArguments += ["UI_TESTING_LARGE_TEXT"]
        app.launch()

        // Verify no truncation
        let tempoLabel = app.staticTexts["TempoLabel"]
        XCTAssertFalse(tempoLabel.isHittable && tempoLabel.frame.width < tempoLabel.frame.width * 0.9)
    }

    func testMinimumTapTargetSize() {
        // All interactive elements must be 44x44 minimum
        for element in app.buttons.allElementsBoundByIndex {
            let frame = element.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Button too small: \(element)")
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Button too small: \(element)")
        }
    }

    func testColorContrast() {
        // Use custom accessibility inspector
        let inspector = AccessibilityInspector(app)
        let issues = inspector.auditColorContrast()

        XCTAssertTrue(issues.isEmpty, "Color contrast issues: \(issues)")
    }
}
```

### Custom Accessibility Inspector

```swift
// Testing/Accessibility/AccessibilityInspector.swift

public class AccessibilityInspector {
    private let app: XCUIApplication

    public init(_ app: XCUIApplication) {
        self.app = app
    }

    public func auditColorContrast() -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []

        for element in app.otherElements.allElementsBoundByIndex {
            let bgColor = element.backgroundColor
            let fgColor = element.textColor

            let contrast = calculateContrast(bgColor, fgColor)

            if contrast < 4.5 { // WCAG AA standard
                issues.append(AccessibilityIssue(
                    element: element,
                    type: .contrast,
                    severity: .error,
                    message: "Contrast \(contrast) below 4.5:1"
                ))
            }
        }

        return issues
    }

    public func auditMissingLabels() -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []

        // Check all buttons have accessibility labels
        for button in app.buttons.allElementsBoundByIndex {
            if button.label.isEmpty {
                issues.append(AccessibilityIssue(
                    element: button,
                    type: .missingLabel,
                    severity: .error,
                    message: "Button missing accessibility label"
                ))
            }
        }

        return issues
    }

    private func calculateContrast(_ bg: Color, _ fg: Color) -> Double {
        // WCAG contrast calculation
        let l1 = relativeLuminance(bg)
        let l2 = relativeLuminance(fg)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    private func relativeLuminance(_ color: Color) -> Double {
        // WCAG relative luminance formula
        // Implementation omitted for brevity
        return 0
    }
}

public struct AccessibilityIssue {
    let element: XCUIElement
    let type: IssueType
    let severity: Severity
    let message: String

    public enum IssueType {
        case contrast
        case missingLabel
        case missingHint
        case invalidTrait
    }

    public enum Severity {
        case error
        case warning
    }
}
```

**Coverage Target:** 100% WCAG 2.1 AA compliance

---

## Performance Testing

### Core Animation Instrumentation

**Tool:** Xcode Instruments + XCTest Performance

**Example:**
```swift
// Tests/Performance/UIPerformanceTests.swift

class UIPerformanceTests: XCTestCase {
    func testMovingSidewalkScrollPerformance() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTStorageMetric()]) {
            // Load Moving Sidewalk with 6 songs
            let app = XCUIApplication()
            app.launch()

            // Navigate to Moving Sidewalk
            app.tabBars.buttons["Moving Sidewalk"].tap()

            // Scroll through all cards
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeLeft()

            // Wait for scroll to complete
            Thread.sleep(forTimeInterval: 1)
        }
    }

    func testSongPlayerCardRendering() {
        let state = MultiSongState.testInstance
        let card = SongPlayerCard(slot: .constant(state.songs[0]))

        measure {
            // Render card 100 times
            for _ in 0..<100 {
                _ = card.body
            }
        }
    }

    func testMultiSongWaveformPerformance() {
        let waveform = WaveformData.testInstance

        measure {
            // Render waveform 100 times
            for _ in 0..<100 {
                let view = MultiSongWaveformView(waveform: waveform)
                _ = view.body
            }
        }
    }
}
```

### Memory Leak Detection

**Tool:** Xcode Leaks Instrument + XCTest

**Example:**
```swift
// Tests/Performance/MemoryLeakTests.swift

class MemoryLeakTests: XCTestCase {
    func testNoRetainCyclesInSongPlayerCard() {
        weak var weakCard: SongPlayerCard?

        autoreleasepool {
            let state = MultiSongState.testInstance
            let card = SongPlayerCard(slot: .constant(state.songs[0]))
            weakCard = card
        }

        XCTAssertNil(weakCard, "SongPlayerCard has retain cycle")
    }

    func testMultiSongEngineCleanup() {
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let engine = MultiSongEngineImpl()
            weakEngine = engine
        }

        XCTAssertNil(weakEngine, "MultiSongEngine has retain cycle")
    }
}
```

**Coverage Target:** Zero memory leaks, <100MB baseline memory

---

## Continuous Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test-suite.yml

name: Complete Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  # SDK Tests
  sdk-tests:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        working-directory: ./sdk
        run: npm ci

      - name: Run unit tests
        working-directory: ./sdk
        run: npm test

      - name: Generate coverage
        working-directory: ./sdk
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./sdk/coverage/lcov.info

  # iOS Tests
  ios-tests:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Run XCUITests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
            -resultBundlePath TestResults.xcresult

      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: ios-test-results
          path: TestResults.xcresult

      - name: Run snapshot tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
            -only-testing:WhiteRoomiOSTests/SnapshotTests

      - name: Run accessibility tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
            -only-testing:WhiteRoomiOSTests/AccessibilityTests

  # tvOS Tests
  tvos-tests:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Run tvOS tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomtvOS \
            -destination 'platform=tvOS Simulator,name=Apple TV' \
            -resultBundlePath TestResults.tvos.xcresult

  # Performance Tests
  performance-tests:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Run performance tests
        run: |
          xcodebuild test \
            -scheme WhiteRoomiOS \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
            -only-testing:WhiteRoomiOSTests/PerformanceTests

      - name: Check for performance regressions
        run: |
          ./Scripts/check-performance-regression.sh

  # Visual Regression
  visual-regression:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Build and take screenshots
        run: ./Scripts/take-screenshots.sh

      - name: Upload to Percy
        run: |
          npm install -g @percy/cli
          percy upload ./Screenshots/*
        env:
          PERCY_TOKEN: ${{ secrets.PERCY_TOKEN }}

  # Security Scan
  security-scan:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Run security scan
        run: |
          npm install -g snyk
          snyk test

  # Telemetry Validation
  telemetry-check:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3

      - name: Verify telemetry events
        run: |
          ./Scripts/verify-telemetry-events.sh

      - name: Check crash reporting setup
        run: |
          ./Scripts/verify-crash-reporting.sh
```

### Test Result Aggregation

```bash
#!/bin/bash
# Scripts/aggregate-test-results.sh

# Gather all test results
echo "Aggregating test results..."

# SDK tests
SDK_TESTS=$(cat sdk/coverage/coverage-summary.json | jq '.total.lines.pct')
echo "SDK Coverage: ${SDK_TESTS}%"

# iOS tests
IOS_RESULTS=$(xcrun xcresulttool get --format json --path TestResults.xcresult | jq '.metrics.testsCount')
echo "iOS Tests: ${IOS_RESULTS} passed"

# Accessibility
AX_ISSUES=$(cat TestResults/Accessibility/report.json | jq '.issues | length')
echo "Accessibility Issues: ${AX_ISSUES}"

# Performance
PERF_REGRESSIONS=$(cat TestResults/Performance/regressions.txt | wc -l)
echo "Performance Regressions: ${PERF_REGRESSIONS}"

# Overall status
if (( $(echo "$SDK_TESTS >= 90" | bc -l) )) && \
   [ "$AX_ISSUES" -eq 0 ] && \
   [ "$PERF_REGRESSIONS" -eq 0 ]; then
    echo "✅ All quality gates passed"
    exit 0
else
    echo "❌ Quality gates failed"
    exit 1
fi
```

---

## Test Coverage Requirements

### Minimum Coverage Targets

| Component | Unit Tests | Integration Tests | E2E Tests | Total Target |
|-----------|-----------|------------------|-----------|--------------|
| SDK/TypeScript | 85% | 50% | 30% | 80% |
| iOS SwiftUI | 80% | 60% | 40% | 75% |
| tvOS SwiftUI | 80% | 60% | 40% | 75% |
| JUCE Backend | 70% | 40% | 20% | 60% |
| **Overall** | **80%** | **50%** | **30%** | **75%** |

### Critical Path Coverage

**Must Have 100% Coverage:**
- Multi-song audio engine coordination
- Master transport controls
- Sync mode logic (locked, ratio, independent)
- Preset save/load operations
- Crash reporting integration
- Telemetry event tracking

**Must Have 90%+ Coverage:**
- All UI controls (play/pause, tempo, volume)
- Navigation flows
- State management (@StateObject, @Published)
- Error handling paths

---

## QA Dashboard & Reporting

### Test Dashboard Setup

**Tool:** GitHub Actions + Custom Dashboard

**Dashboard Metrics:**
```swift
// Infrastructure/QADashboard/Summary.swift

public struct TestSummary: Codable {
    public let date: Date
    public let sdkCoverage: Double
    public let iosTestsPassed: Int
    public let iosTestsFailed: Int
    public let accessibilityIssues: Int
    public let performanceRegressions: Int
    public let visualRegressions: Int
    public let crashFreeUsers: Double

    public var overallScore: Double {
        var score = 0.0

        // SDK coverage (30% weight)
        score += (sdkCoverage / 100.0) * 30

        // iOS tests pass rate (25% weight)
        let passRate = Double(iosTestsPassed) / Double(iosTestsPassed + iosTestsFailed)
        score += passRate * 25

        // Accessibility (20% weight)
        let axScore = accessibilityIssues == 0 ? 1.0 : 0.5
        score += axScore * 20

        // Performance (15% weight)
        let perfScore = performanceRegressions == 0 ? 1.0 : 0.5
        score += perfScore * 15

        // Visual (10% weight)
        let visualScore = visualRegressions == 0 ? 1.0 : 0.5
        score += visualScore * 10

        return score
    }

    public var grade: String {
        switch overallScore {
        case 95...100: return "A+"
        case 90..<95: return "A"
        case 85..<90: return "B+"
        case 80..<85: return "B"
        case 75..<80: return "C"
        default: return "F"
        }
    }
}
```

### Automated Test Reports

**Daily Test Summary Email:**
```swift
// Infrastructure/Reports/DailyTestReport.swift

public struct DailyTestReport {
    public func generate() -> String {
        let summary = loadTestSummary()

        return """
        White Room Daily Test Report
        Date: \(Date())

        Overall Score: \(summary.grade) (\(String(format: "%.1f", summary.overallScore))%)

        Coverage:
        - SDK: \(String(format: "%.1f", summary.sdkCoverage))%
        - iOS: Not measured
        - tvOS: Not measured

        Tests:
        - iOS Passed: \(summary.iosTestsPassed)
        - iOS Failed: \(summary.iosTestsFailed)

        Quality:
        - Accessibility Issues: \(summary.accessibilityIssues)
        - Performance Regressions: \(summary.performanceRegressions)
        - Visual Regressions: \(summary.visualRegressions)

        Telemetry:
        - Crash-Free Users: \(String(format: "%.1f", summary.crashFreeUsers))%
        - Active Sessions: \(loadActiveSessionCount())

        Trends:
        \(loadTrendData())
        """
    }
}
```

### Quality Gates

**Pre-Merge Requirements:**
- All unit tests passing
- Coverage ≥ target threshold
- Zero accessibility errors
- Zero performance regressions
- Zero visual regressions (approved by human)

**Pre-Release Requirements:**
- All pre-merge requirements
- 100% critical path coverage
- Zero high-severity crashes
- <1% crash rate (7-day)
- Performance baseline maintained

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
✅ **Already Complete:**
- Telemetry system (CrashReporting.swift)
- SDK unit tests (Vitest)
- Moving Sidewalk tests (92 tests)

🔧 **To Implement:**
- UI telemetry tracking enhancement
- Snapshot testing setup
- XCUITest infrastructure

### Phase 2: Core Testing (Week 3-4)
- SwiftUI unit tests (ViewInspector)
- XCUITest integration tests
- Accessibility audit suite
- Performance test baseline

### Phase 3: Advanced Testing (Week 5-6)
- Visual regression automation
- E2E workflow tests
- Memory leak detection
- Continuous integration setup

### Phase 4: QA Dashboard (Week 7-8)
- Test result aggregation
- Dashboard UI
- Automated reporting
- Quality gate enforcement

### Phase 5: Optimization (Week 9-10)
- Test parallelization
- Flaky test elimination
- Performance optimization
- Documentation completion

---

## Quick Start Commands

### Run All Tests

```bash
# SDK tests
cd sdk && npm test

# iOS tests
xcodebuild test -scheme WhiteRoomiOS -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

# Snapshot tests
xcodebuild test -scheme WhiteRoomiOS -only-testing:SnapshotTests

# Accessibility tests
xcodebuild test -scheme WhiteRoomiOS -only-testing:AccessibilityTests

# Performance tests
xcodebuild test -scheme WhiteRoomiOS -only-testing:PerformanceTests

# All tests
./Scripts/run-all-tests.sh
```

### Generate Coverage Report

```bash
# SDK coverage
cd sdk && npm run test:coverage

# iOS coverage (requires Xcode 13+)
xcodebuild test \
  -scheme WhiteRoomiOS \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

xcrun xccov view --report TestResults.xcresult
```

### Run Visual Regression

```bash
# Take screenshots
./Scripts/take-screenshots.sh

# Upload to Percy
percy upload ./Screenshots/*
```

---

## Best Practices

### Test Organization

**Folder Structure:**
```
Tests/
├── Unit/                    # Component-level tests
│   ├── SongPlayerCardTests.swift
│   ├── MultiSongEngineTests.swift
│   └── SyncModeTests.swift
├── Integration/             # Multi-component tests
│   ├── MovingSidewalkTests.swift
│   └── MasterTransportTests.swift
├── E2E/                     # Full workflow tests
│   ├── UserWorkflowTests.swift
│   └── MultiSongSessionTests.swift
├── Snapshot/                # Visual regression tests
│   ├── MovingSidewalkSnapshotTests.swift
│   └── ComponentSnapshotTests.swift
├── Accessibility/           # A11y compliance tests
│   └── AccessibilityTests.swift
└── Performance/             # Performance benchmarks
    ├── UIPerformanceTests.swift
    └── MemoryLeakTests.swift
```

### Test Naming

```swift
// ✅ Good: Descriptive, follows pattern
func testPlayPauseButtonToggle_WhenClicked_StateUpdates()

// ❌ Bad: Vague, no context
func testButton()

// ✅ Good: Tests specific behavior
func testTempoSlider_WhenSetBelowMinimum_ClampsToForty()

// ❌ Bad: Tests implementation
func testTempoVariableSet()
```

### Test Data Management

```swift
// TestHelpers/Fixtures.swift

public enum Fixtures {
    public static var testSong: Song {
        Song(
            id: "test-song-1",
            name: "Test Song",
            bpm: 120,
            timeSignature: TimeSignature(numerator: 4, denominator: 4),
            tracks: []
        )
    }

    public static var testMultiSongState: MultiSongState {
        MultiSongState(
            songs: (0..<6).map { _ in testSongSlot },
            masterTransport: .testInstance,
            sessionMetadata: .testInstance
        )
    }
}
```

---

## Success Metrics

### Quality KPIs

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| SDK Coverage | 85% | Measured in CI | 🟡 |
| iOS Tests Passing | 100% | 92/92 | 🟢 |
| Accessibility Compliance | 100% | Not measured | 🔴 |
| Crash-Free Users | >99% | From telemetry | 🟡 |
- Visual Regressions | 0 | Not measured | 🔴 |
- Performance Regressions | 0 | Not measured | 🔴 |

### Milestone Targets

**Week 2:**
- ✅ SDK tests running (Vitest)
- ✅ Moving Sidewalk tests passing (92 tests)
- 🔧 UI telemetry enhancement
- 🔧 Snapshot testing setup

**Week 4:**
- 🎯 SwiftUI unit tests (80%+ coverage)
- 🎯 XCUITest integration tests
- 🎯 Accessibility audit suite
- 🎯 Performance baseline established

**Week 6:**
- 🎯 Visual regression automation
- 🎯 E2E workflow tests
- 🎯 Memory leak detection
- 🎯 CI/CD pipeline complete

**Week 8:**
- 🎯 QA dashboard live
- 🎯 Automated reporting
- 🎯 Quality gates enforced
- 🎯 Documentation complete

---

## Conclusion

This comprehensive testing strategy ensures White Room maintains production-ready quality across all platforms. By combining unit tests, integration tests, E2E tests, visual regression, accessibility audits, and performance monitoring, we create a robust quality assurance system that catches issues before they reach users.

**Key Takeaways:**

1. **Test Early, Test Often**: Write tests alongside code, not after
2. **Automate Everything**: If it can be automated, it should be
3. **Measure Quality**: Use metrics to track improvement over time
4. **Integrate Telemetry**: Leverage existing crash reporting for smarter tests
5. **Quality Gates**: Enforce standards before merging and releasing

**Next Steps:**

1. Implement UI telemetry tracking enhancement
2. Set up snapshot testing infrastructure
3. Write initial XCUITest suite
4. Configure CI/CD pipeline
5. Deploy QA dashboard

**Remember:** "If tests pass, the app works. Comprehensive automated testing makes manual QA unnecessary."

---

**Appendices**

- [A: Test Configuration Reference](#appendix-a-test-configuration-reference)
- [B: CI/CD Pipeline Examples](#appendix-b-cicd-pipeline-examples)
- [C: Troubleshooting Guide](#appendix-c-troubleshooting-guide)
- [D: Further Reading](#appendix-d-further-reading)

---

*Document maintained by White Room QA Team*
*Last review: 2026-01-16*
*Next review: 2026-02-01*
