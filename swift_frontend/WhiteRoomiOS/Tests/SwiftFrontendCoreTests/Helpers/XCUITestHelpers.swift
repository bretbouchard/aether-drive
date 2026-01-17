//
//  XCUITestHelpers.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  XCUITest helper utilities and extensions for Moving Sidewalk testing

import XCTest

// =============================================================================
// MARK: - XCUIApplication Extensions
// =============================================================================

extension XCUIApplication {

    /// Wait for app to be in running foreground state
    func waitForRunningForeground(timeout: TimeInterval) -> Bool {
        return wait(for: .runningForeground, timeout: timeout)
    }

    /// Check if app is currently in foreground
    var isRunningForeground: Bool {
        return state == .runningForeground
    }

    /// Dismiss all system alerts/dialogs
    func dismissSystemAlerts() {
        let alerts = descendants(matching: .any).matching(identifier: "UIAlertView")
        alerts.allElementsBoundByIndex.forEach { alert in
            if alert.exists {
                let buttons = alert.buttons.allElementsBoundByIndex
                buttons.first?.tap()
            }
        }
    }

    /// Take screenshot with automatic naming
    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// =============================================================================
// MARK: - XCUIElement Extensions
// =============================================================================

extension XCUIElement {

    /// Wait for element to exist and be hittable
    func waitForExistenceAndHittable(timeout: TimeInterval) -> Bool {
        return waitForExistence(timeout: timeout) && isHittable
    }

    /// Force tap element (fallback if normal tap fails)
    func forceTap() {
        if isHittable {
            tap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }

    /// Tap element at specific offset
    func tapAtOffset(_ offset: CGVector) {
        let coordinate = self.coordinate(withNormalizedOffset: offset)
        coordinate.tap()
    }

    /// Clear text field content
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }

    /// Wait for element to disappear
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)

        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Check if element is visible in viewport
    var isVisible: Bool {
        guard exists && isHittable else { return false }
        return frame.intersection(XCUIScreen.main.screenshot().image.bounds) != .zero
    }

    /// Scroll element into view
    func scrollIntoView() {
        while !isVisible {
            swipeUp()
        }
    }
}

// =============================================================================
// MARK: - XCUIElementQuery Extensions
// =============================================================================

extension XCUIElementQuery {

    /// Get first matching element or nil
    var firstMatching: XCUIElement? {
        return firstMatch.exists ? firstMatch : nil
    }

    /// Count elements that actually exist
    var existingCount: Int {
        return allElementsBoundByIndex.filter { $0.exists }.count
    }

    /// Wait for at least N elements to exist
    func waitForCount(_ count: Int, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "count >= \(count)")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)

        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// =============================================================================
// MARK: - XCUIDevice Extensions
// /// =============================================================================

extension XCUIDevice {

    /// Rotate device to specific orientation
    func rotateTo(_ orientation: UIDeviceOrientation) {
        #if os(iOS)
        let rotationExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "orientation == \(orientation.rawValue)"),
            object: self
        )

        self.orientation = orientation

        XCTWaiter.wait(for: [rotationExpectation], timeout: 5)
        #endif
    }

    /// Press home button with delay
    func pressHomeWithDelay() {
        press(.home)
        Thread.sleep(forTimeInterval: 0.5)
    }

    /// Double press home button
    func doublePressHome() {
        press(.home)
        Thread.sleep(forTimeInterval: 0.3)
        press(.home)
    }
}

// =============================================================================
// MARK: - Test Helpers
// =============================================================================

/// XCUITest helper class for common operations
final class XCUITestHelper {

    // MARK: - Wait Helpers

    /// Wait for condition to be true
    static func waitFor(
        timeout: TimeInterval = 5,
        description: String = "Condition to be true",
        condition: @escaping () -> Bool
    ) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        XCTFail("Timed out waiting for: \(description)")
    }

    /// Wait for multiple conditions
    static func waitForAll(
        timeout: TimeInterval = 5,
        conditions: [@escaping () -> Bool]
    ) async throws {
        for (index, condition) in conditions.enumerated() {
            try await waitFor(
                timeout: timeout,
                description: "Condition \(index)",
                condition: condition
            )
        }
    }

    // MARK: - Element Helpers

    /// Find element by accessibility identifier
    static func element(
        _ identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        return app.descendants(matching: .any)[identifier]
    }

    /// Find multiple elements by accessibility identifier
    static func elements(
        _ identifier: String,
        in app: XCUIApplication
    ) -> XCUIElementQuery {
        return app.descendants(matching: .any).matching(identifier: identifier)
    }

    /// Wait for element to appear
    static func waitForElement(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5
    ) -> XCUIElement? {
        let element = self.element(identifier, in: app)
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element
    }

    // MARK: - Action Helpers

    /// Tap element safely (waits for existence first)
    @discardableResult
    static func safeTap(
        _ element: XCUIElement,
        timeout: TimeInterval = 3
    ) -> Bool {
        guard element.waitForExistenceAndHittable(timeout: timeout) else {
            return false
        }

        element.tap()
        return true
    }

    /// Type text safely (clears field first)
    static func safeType(
        _ text: String,
        in element: XCUIElement,
        clearFirst: Bool = true
    ) {
        guard element.waitForExistence(timeout: 3) else {
            XCTFail("Element does not exist")
            return
        }

        if clearFirst {
            element.tap()
            element.clearText()
        }

        element.typeText(text)
    }

    /// Adjust slider to specific position
    static func adjustSlider(
        _ slider: XCUIElement,
        to position: CGFloat,
        timeout: TimeInterval = 2
    ) {
        guard slider.waitForExistence(timeout: timeout) else {
            XCTFail("Slider does not exist")
            return
        }

        slider.adjust(toNormalizedSliderPosition: position)
    }

    // MARK: - Screenshot Helpers

    /// Take screenshot with automatic naming including test name
    static func captureScreenshot(
        _ app: XCUIApplication,
        name: String? = nil,
        testName: String = #function
    ) {
        let screenshotName = name ?? testName
        app.takeScreenshot(name: screenshotName)
    }

    /// Capture screenshot on failure
    static func captureFailureScreenshot(
        _ app: XCUIApplication,
        testName: String = #function
    ) {
        captureScreenshot(app, name: "\(testName)_FAILED")
    }

    // MARK: - Verification Helpers

    /// Verify element exists
    static func verifyExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(
            exists,
            "Element should exist: \(element)",
            file: file,
            line: line
        )
    }

    /// Verify element does not exist
    static func verifyNotExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let disappeared = element.waitForDisappearance(timeout: timeout)
        XCTAssertTrue(
            disappeared,
            "Element should not exist: \(element)",
            file: file,
            line: line
        )
    }

    /// Verify element has specific text
    static func verifyText(
        _ element: XCUIElement,
        contains text: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let elementText = element.value as? String else {
            XCTFail("Element has no text value", file: file, line: line)
            return
        }

        XCTAssertTrue(
            elementText.contains(text),
            "Element text '\(elementText)' should contain '\(text)'",
            file: file,
            line: line
        )
    }

    /// Verify element is enabled
    static func verifyEnabled(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.isEnabled,
            "Element should be enabled: \(element)",
            file: file,
            line: line
        )
    }

    /// Verify element is disabled
    static func verifyDisabled(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            element.isEnabled,
            "Element should be disabled: \(element)",
            file: file,
            line: line
        )
    }

    // MARK: - Navigation Helpers

    /// Navigate to tab by name
    @discardableResult
    static func navigateToTab(
        _ tabName: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 3
    ) -> Bool {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: timeout) else {
            return false
        }

        let tabButton = tabBar.buttons[tabName]
        guard tabButton.exists else {
            return false
        }

        tabButton.tap()

        // Verify navigation
        let navigationBar = app.navigationBars.firstMatch
        return navigationBar.waitForExistence(timeout: timeout)
    }

    /// Navigate back
    @discardableResult
    static func navigateBack(
        in app: XCUIApplication,
        timeout: TimeInterval = 3
    ) -> Bool {
        let backButton = app.navigationBars.buttons.firstMatch
        guard backButton.exists else {
            return false
        }

        backButton.tap()
        return true
    }

    // MARK: - Data Helpers

    /// Generate random song name for testing
    static func randomSongName() -> String {
        let adjectives = ["Happy", "Sad", "Fast", "Slow", "Loud", "Quiet", "Bright", "Dark"]
        let nouns = ["Song", "Track", "Melody", "Beat", "Groove", "Jam", "Tune", "Piece"]

        let adjective = adjectives.randomElement() ?? "Test"
        let noun = nouns.randomElement() ?? "Song"
        let number = Int.random(in: 1...100)

        return "\(adjective) \(noun) \(number)"
    }

    /// Generate random preset name for testing
    static func randomPresetName() -> String {
        let prefixes = ["My", "Cool", "Awesome", "Great", "Best"]
        let nouns = ["Session", "Mix", "Jam", "Practice", "Remix"]
        let suffixes = ["1", "2", "3", "Final", "Draft"]

        let prefix = prefixes.randomElement() ?? "Test"
        let noun = nouns.randomElement() ?? "Preset"
        let suffix = suffixes.randomElement() ?? ""

        return "\(prefix) \(noun) \(suffix)".trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Performance Helpers

    /// Measure execution time of operation
    static func measureTime(
        _ operation: () -> Void
    ) -> TimeInterval {
        let start = Date()
        operation()
        let end = Date()

        return end.timeIntervalSince(start)
    }

    /// Verify operation completes within time limit
    static func verifyCompletionTime(
        _ operation: () -> Void,
        within seconds: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let time = measureTime(operation)

        XCTAssertLessThanOrEqual(
            time,
            seconds,
            "Operation should complete in \(seconds)s, took \(time)s",
            file: file,
            line: line
        )
    }

    // MARK: - Debug Helpers

    /// Print all elements in hierarchy (for debugging)
    static func printElementHierarchy(
        _ element: XCUIElement,
        indent: String = ""
    ) {
        let elementType = String(describing: type(of: element))
        let identifier = element.identifier.isEmpty ? "" : " id='\(element.identifier)'"
        let label = element.label.isEmpty ? "" : " label='\(element.label)'"

        print("\(indent)\(elementType)\(identifier)\(label)")

        for child in element.children(matching: .any).allElementsBoundByIndex {
            printElementHierarchy(child, indent: indent + "  ")
        }
    }

    /// Print current screen state (for debugging)
    static func printScreenState(_ app: XCUIApplication) {
        print("\n=== Screen State ===")
        print("App state: \(app.state)")

        let windows = app.windows.allElementsBoundByIndex
        print("Windows: \(windows.count)")

        for (index, window) in windows.enumerated() {
            print("Window \(index):")
            printElementHierarchy(window, indent: "  ")
        }

        print("===================\n")
    }
}

// =============================================================================
// MARK: - Test Data Builders
// =============================================================================

/// Builder for creating test song data
struct SongTestDataBuilder {

    var name: String = "Test Song"
    var tempo: Double = 120.0
    var volume: Double = 0.8
    var duration: Double = 180.0
    var position: Double = 0.0

    func build() -> SongTestData {
        return SongTestData(
            name: name,
            tempo: tempo,
            volume: volume,
            duration: duration,
            position: position
        )
    }
}

struct SongTestData {
    let name: String
    let tempo: Double
    let volume: Double
    let duration: Double
    let position: Double
}

/// Builder for creating test preset data
struct PresetTestDataBuilder {

    var name: String = "Test Preset"
    var tempo: Double = 120.0
    var syncMode: String = "Locked"
    var songCount: Int = 6

    func build() -> PresetTestData {
        return PresetTestData(
            name: name,
            tempo: tempo,
            syncMode: syncMode,
            songCount: songCount
        )
    }
}

struct PresetTestData {
    let name: String
    let tempo: Double
    let syncMode: String
    let songCount: Int
}

// =============================================================================
// MARK: - Assert Helpers
// =============================================================================

/// Custom assertions for XCUITest
enum XCUITestAssert {

    /// Assert element is visible (exists and hittable)
    static func isVisible(
        _ element: XCUIElement,
        _ message: String = "Element should be visible",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let visible = element.exists && element.isHittable
        XCTAssertTrue(
            visible,
            "\(message): \(element)",
            file: file,
            line: line
        )
    }

    /// Assert element has specific accessibility label
    static func hasAccessibilityLabel(
        _ element: XCUIElement,
        _ label: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            element.label,
            label,
            "Element should have accessibility label '\(label)'",
            file: file,
            line: line
        )
    }

    /// Assert element is focused (tvOS)
    static func isFocused(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.hasFocus,
            "Element should be focused: \(element)",
            file: file,
            line: line
        )
    }

    /// Assert count of elements
    static func count(
        _ query: XCUIElementQuery,
        equals expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let actualCount = query.count

        XCTAssertEqual(
            actualCount,
            expectedCount,
            "Expected \(expectedCount) elements, found \(actualCount)",
            file: file,
            line: line
        )
    }
}
