//
//  TelemetryTestHelpers.swift
//  SwiftFrontendCoreTests
//
//  Telemetry test helpers for SwiftUI test integration
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

// MARK: - XCTestCase Telemetry Extensions

public extension XCTestCase {

    // MARK: - Event Assertions

    /// Assert a telemetry event was recorded
    func assertTelemetryEventRecorded(
        _ type: TelemetryEventType,
        action: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let matching = events.contains { event in
            event.type == type && event.action == action
        }

        XCTAssertTrue(
            matching,
            "Expected telemetry event of type \(type.rawValue) with action '\(action)' not found",
            file: file,
            line: line
        )
    }

    /// Assert telemetry event count
    func assertTelemetryEventCount(
        _ expected: Int,
        type: TelemetryEventType,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let count = events.filter { $0.type == type }.count

        XCTAssertEqual(
            expected,
            count,
            "Expected \(expected) events of type \(type.rawValue), found \(count)",
            file: file,
            line: line
        )
    }

    /// Assert telemetry event recorded for specific element
    func assertTelemetryElementTapped(
        _ element: String,
        in screen: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let matching = events.contains { event in
            event.type == .uiInteraction &&
            event.element == element &&
            event.screen == screen
        }

        XCTAssertTrue(
            matching,
            "Expected telemetry event for element '\(element)' in screen '\(screen)' not found",
            file: file,
            line: line
        )
    }

    /// Assert navigation was tracked
    func assertTelemetryNavigationTracked(
        from: String,
        to: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let matching = events.contains { event in
            event.type == .navigation &&
            event.screen == from &&
            event.context["destination"] == to
        }

        XCTAssertTrue(
            matching,
            "Expected navigation from '\(from)' to '\(to)' not found in telemetry",
            file: file,
            line: line
        )
    }

    /// Assert screen view was tracked
    func assertTelemetryScreenViewed(
        _ screen: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let matching = events.contains { event in
            event.type == .uiInteraction &&
            event.screen == screen &&
            event.action == "screen_view"
        }

        XCTAssertTrue(
            matching,
            "Expected screen view for '\(screen)' not found in telemetry",
            file: file,
            line: line
        )
    }

    /// Assert error was tracked
    func assertTelemetryErrorRecorded(
        _ error: String,
        in screen: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let matching = events.contains { event in
            event.type == .error &&
            event.action.contains(error) &&
            (screen == nil || event.screen == screen)
        }

        XCTAssertTrue(
            matching,
            "Expected error '\(error)' not found in telemetry",
            file: file,
            line: line
        )
    }

    // MARK: - Performance Assertions

    /// Assert performance operation meets threshold
    func assertTelemetryPerformanceWithinThreshold(
        _ operation: String,
        threshold: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let perfEvents = events.filter { event in
            event.type == .performance &&
            event.action.contains(operation)
        }

        XCTAssertFalse(
            perfEvents.isEmpty,
            "No performance event found for operation '\(operation)'",
            file: file,
            line: line
        )

        for event in perfEvents {
            guard let durationStr = event.context["duration"],
                  let duration = Double(durationStr) else {
                XCTFail("Performance event missing duration", file: file, line: line)
                continue
            }

            XCTAssertLessThanOrEqual(
                duration,
                threshold,
                "Operation '\(operation)' took \(String(format: "%.0f", duration * 1000))ms, " +
                "exceeds threshold of \(String(format: "%.0f", threshold * 1000))ms",
                file: file,
                line: line
            )
        }
    }

    /// Assert no slow operations recorded
    func assertTelemetryNoSlowOperations(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let events = UITelemetryTracker.shared.getEvents()

        let slowOps = events.filter { event in
            guard event.type == .performance,
                  let durationStr = event.context["duration"],
                  let duration = Double(durationStr),
                  let thresholdStr = event.context["threshold"],
                  let threshold = Double(thresholdStr) else {
                return false
            }
            return duration > threshold
        }

        XCTAssertTrue(
            slowOps.isEmpty,
            "Found \(slowOps.count) slow operations in telemetry",
            file: file,
            line: line
        )
    }

    // MARK: - Validation Assertions

    /// Assert telemetry event is valid
    func assertTelemetryEventValid(
        _ event: TelemetryEvent,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let validator = TelemetryValidator.shared
        let result = validator.validateEvent(event)

        XCTAssertTrue(
            result.isValid,
            "Telemetry event validation failed:\n\(result.description)",
            file: file,
            line: line
        )
    }

    /// Assert all telemetry events in session are valid
    func assertTelemetrySessionValid(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let events = tracker.getEvents()

        let validator = TelemetryValidator.shared
        let result = validator.validateSession(events)

        XCTAssertTrue(
            result.isValid,
            "Telemetry session validation failed:\n\(result.description)",
            file: file,
            line: line
        )
    }

    /// Assert telemetry meets quality thresholds
    func assertTelemetryMeetsQualityThresholds(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let events = UITelemetryTracker.shared.getEvents()
        let report = TelemetryMetrics.shared.generateReport(from: events)

        XCTAssertTrue(
            report.meetsQualityThresholds,
            "Telemetry does not meet quality thresholds:\n\(report.summary)",
            file: file,
            line: line
        )
    }

    // MARK: - Session Replay Assertions

    /// Assert session replay captured events
    func assertSessionReplayCapturedEvents(
        count: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let replay = SessionReplay.shared
        let events = replay.getEvents()

        XCTAssertEqual(
            events.count,
            count,
            "Expected \(count) events in session replay, found \(events.count)",
            file: file,
            line: line
        )
    }

    /// Assert session replay maintained event order
    func assertSessionReplayMaintainedOrder(
        expectedActions: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let replay = SessionReplay.shared
        let events = replay.getEvents()

        let actualActions = events.map { $0.action }

        XCTAssertEqual(
            actualActions,
            expectedActions,
            "Session replay event order does not match expected",
            file: file,
            line: line
        )
    }
}

// MARK: - SwiftUI View Testing Helpers

public extension XCTestCase {

    /// Tap a SwiftUI button and verify telemetry
    func tapAndVerifyTelemetry(
        _ element: String,
        in screen: String,
        view: some View,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // This would integrate with ViewInspector or similar
        // For now, it's a placeholder showing the intended usage

        // 1. Tap the element
        // try view.inspect().button(element).tap()

        // 2. Verify telemetry
        assertTelemetryElementTapped(element, in: screen, file: file, line: line)
    }

    /// Perform view action and verify telemetry event
    func performActionAndVerifyTelemetry<T: View>(
        action: () -> Void,
        expectedType: TelemetryEventType,
        expectedAction: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let tracker = UITelemetryTracker.shared
        let beforeCount = tracker.getEvents().count

        // Perform action
        action()

        // Verify telemetry
        let afterCount = tracker.getEvents().count
        XCTAssertGreaterThan(
            afterCount,
            beforeCount,
            "Expected new telemetry event after action",
            file: file,
            line: line
        )

        assertTelemetryEventRecorded(
            expectedType,
            action: expectedAction,
            file: file,
            line: line
        )
    }
}

// MARK: - Telemetry Test Scenarios

public extension XCTestCase {

    /// Test complete user flow with telemetry verification
    func testUserFlowWithTelemetry(
        steps: [TelemetryTestStep],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Clear telemetry before test
        UITelemetryTracker.shared.clear()

        // Execute each step
        for (index, step) in steps.enumerated() {
            // Perform the action
            step.action()

            // Verify telemetry for this step
            switch step.validation {
            case .eventRecorded(let type, let action):
                assertTelemetryEventRecorded(type, action: action, file: file, line: line)

            case .elementTapped(let element, let screen):
                assertTelemetryElementTapped(element, in: screen, file: file, line: line)

            case .navigation(let from, let to):
                assertTelemetryNavigationTracked(from: from, to: to, file: file, line: line)

            case .screenViewed(let screen):
                assertTelemetryScreenViewed(screen, file: file, line: line)

            case .performance(let operation, let threshold):
                assertTelemetryPerformanceWithinThreshold(operation, threshold: threshold, file: file, line: line)

            case .custom(let customValidation):
                customValidation()
            }

            // Add delay between steps if needed
            if index < steps.count - 1 {
                Thread.sleep(forTimeInterval: step.delay)
            }
        }

        // Final validation - ensure all telemetry is valid
        assertTelemetrySessionValid(file: file, line: line)
    }

    /// Measure operation and verify performance telemetry
    func measureAndVerifyPerformance(
        _ operation: String,
        threshold: TimeInterval,
        block: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        PerformanceTelemetry.measure(operation, threshold: threshold, block: block)

        assertTelemetryPerformanceWithinThreshold(
            operation,
            threshold: threshold,
            file: file,
            line: line
        )
    }
}

// MARK: - Telemetry Test Step

/// Step in a telemetry test scenario
public struct TelemetryTestStep {
    public let action: () -> Void
    public let validation: TelemetryValidation
    public let delay: TimeInterval

    public init(
        action: @escaping () -> Void,
        validation: TelemetryValidation,
        delay: TimeInterval = 0.01
    ) {
        self.action = action
        self.validation = validation
        self.delay = delay
    }
}

/// Validation type for telemetry test step
public enum TelemetryValidation {
    case eventRecorded(TelemetryEventType, action: String)
    case elementTapped(String, in: String)
    case navigation(from: String, to: String)
    case screenViewed(String)
    case performance(String, threshold: TimeInterval)
    case custom(() -> Void)
}

// MARK: - Telemetry Assertion Helpers

public extension XCTestCase {

    /// Get telemetry events for inspection
    func getTelemetryEvents() -> [TelemetryEvent] {
        return UITelemetryTracker.shared.getEvents()
    }

    /// Get telemetry events by type
    func getTelemetryEvents(ofType type: TelemetryEventType) -> [TelemetryEvent] {
        return UITelemetryTracker.shared.getEvents().filter { $0.type == type }
    }

    /// Get telemetry events by screen
    func getTelemetryEvents(forScreen screen: String) -> [TelemetryEvent] {
        return UITelemetryTracker.shared.getEvents().filter { $0.screen == screen }
    }

    /// Print telemetry summary for debugging
    func printTelemetrySummary() {
        let events = getTelemetryEvents()

        print("\n=== Telemetry Summary ===")
        print("Total Events: \(events.count)")

        let byType = Dictionary(grouping: events, by: { $0.type })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        print("\nBy Type:")
        for (type, count) in byType {
            print("  \(type.description): \(count)")
        }

        let byScreen = Dictionary(grouping: events, by: { $0.screen })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        print("\nBy Screen:")
        for (screen, count) in byScreen.prefix(10) {
            print("  \(screen): \(count)")
        }

        print("========================\n")
    }

    /// Clear telemetry before test
    func clearTelemetry() {
        UITelemetryTracker.shared.clear()
        PerformanceTelemetry.shared.clear()
        SessionReplay.shared.clearSession()
    }
}

// MARK: - Performance Testing Extensions

public extension XCTestCase {
    /// Measure operation with telemetry
    func measureWithTelemetry(
        _ operation: String,
        threshold: TimeInterval,
        block: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let metrics = measure(metrics: [.wallClockTime]) {
            PerformanceTelemetry.measure(operation, threshold: threshold, block: block)
        }

        // Verify telemetry was recorded
        assertTelemetryEventRecorded(
            .performance,
            action: operation,
            file: file,
            line: line
        )
    }

    /// Benchmark operation across multiple iterations
    func benchmarkWithTelemetry(
        _ operation: String,
        iterations: Int,
        threshold: TimeInterval,
        block: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for i in 0..<iterations {
            PerformanceTelemetry.measure("\(operation) #\(i)", threshold: threshold, block: block)
        }

        // Verify all iterations recorded
        assertTelemetryEventCount(
            iterations,
            type: .performance,
            file: file,
            line: line
        )
    }
}

// MARK: - Usage Examples

/*
 Usage Example 1: Basic telemetry assertion

 ```swift
 func testSaveButton_RecordsTelemetry() {
     // Given
     let viewModel = SongViewModel()

     // When
     viewModel.save()

     // Then - Verify telemetry
     assertTelemetryElementTapped("Save Button", in: "MovingSidewalkView")
 }
 ```

 Usage Example 2: Performance testing with telemetry

 ```swift
 func testPresetLoad_Performance() {
     measureAndVerifyPerformance(
         "Load Preset",
         threshold: 0.05 // 50ms
     ) {
         let preset = try! subject.loadPreset(named: "Test Preset")
     }
 }
 ```

 Usage Example 3: Complete user flow

 ```swift
 func testCompleteUserFlow_Telemetry() {
     let steps = [
         TelemetryTestStep(
             action: { subject.loadLibrary() },
             validation: .screenViewed("LibraryView")
         ),
         TelemetryTestStep(
             action: { subject.selectSong(at: 0) },
             validation: .elementTapped("Song Card 0", in: "LibraryView")
         ),
         TelemetryTestStep(
             action: { subject.navigateToMovingSidewalk() },
             validation: .navigation(from: "Library", to: "Moving Sidewalk")
         ),
     ]

     testUserFlowWithTelemetry(steps: steps)
 }
 ```
 */
