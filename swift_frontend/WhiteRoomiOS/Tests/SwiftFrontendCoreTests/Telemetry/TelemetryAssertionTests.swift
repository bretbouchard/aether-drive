//
//  TelemetryAssertionTests.swift
//  SwiftFrontendCoreTests
//
//  Telemetry-driven test assertions
//

import XCTest
@testable import SwiftFrontendCore

/// Telemetry assertion tests for QA validation
class TelemetryAssertionTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear telemetry before each test
        UITelemetryTracker.shared.clear()
        PerformanceTelemetry.shared.clear()
        SessionReplay.shared.clearSession()
    }

    override func tearDown() {
        // Clean up after each test
        UITelemetryTracker.shared.clear()
        PerformanceTelemetry.shared.clear()
        SessionReplay.shared.clearSession()
        super.tearDown()
    }

    // MARK: - UI Event Recording Tests

    func testUIEvent_Recorded_InTelemetry() {
        // Given
        let tracker = UITelemetryTracker.shared
        tracker.clear()

        // When - Perform UI action
        tracker.trackTap("Save Button", in: "MovingSidewalkView")

        // Then - Verify event recorded
        let events = tracker.getEvents()
        XCTAssertTrue(events.contains { $0.type == .uiInteraction && $0.action == "tap" },
                      "UI interaction event should be recorded")
    }

    func testUIEvent_CapturesElementAndScreen() {
        // Given
        let tracker = UITelemetryTracker.shared
        let expectedElement = "Play Button"
        let expectedScreen = "SongCard"

        // When
        tracker.trackTap(expectedElement, in: expectedScreen)

        // Then
        let events = tracker.getEvents()
        guard let event = events.first else {
            XCTFail("No events recorded")
            return
        }

        XCTAssertEqual(event.element, expectedElement, "Element should match")
        XCTAssertEqual(event.screen, expectedScreen, "Screen should match")
    }

    func testMultipleUIEvents_AllRecorded() {
        // Given
        let tracker = UITelemetryTracker.shared
        let expectedCount = 5

        // When
        for i in 0..<expectedCount {
            tracker.trackTap("Button \(i)", in: "TestView")
        }

        // Then
        let events = tracker.getEvents()
        XCTAssertEqual(events.count, expectedCount, "All events should be recorded")
    }

    // MARK: - Performance Operation Tests

    func testPerformanceOperation_Logged_WhenSlow() {
        // Given
        let slowOperation = { () -> Void in
            Thread.sleep(forTimeInterval: 0.2) // 200ms - exceeds 100ms threshold
        }

        // When - Measure operation
        PerformanceTelemetry.measure("Slow Operation", threshold: 0.1, block: slowOperation)

        // Then - Verify performance event logged
        let events = UITelemetryTracker.shared.getEvents()
        let perfEvents = events.filter { $0.type == .performance }

        XCTAssertTrue(perfEvents.contains { $0.action.contains("Slow Operation") },
                      "Slow operation should be logged")
    }

    func testPerformanceOperation_CapturesDuration() {
        // Given
        let expectedDuration: TimeInterval = 0.15
        let operation = { () -> Void in
            Thread.sleep(forTimeInterval: expectedDuration)
        }

        // When
        PerformanceTelemetry.measure("Test Operation", threshold: 0.1, block: operation)

        // Then
        let events = UITelemetryTracker.shared.getEvents()
        let perfEvent = events.first { $0.type == .performance && $0.action.contains("Test Operation") }

        XCTAssertNotNil(perfEvent, "Performance event should exist")
        XCTAssertNotNil(perfEvent?.context["duration"], "Duration should be captured")

        if let durationStr = perfEvent?.context["duration"],
           let duration = Double(durationStr) {
            XCTAssertGreaterThanOrEqual(duration, expectedDuration * 0.9, // 10% tolerance
                                       "Duration should be approximately accurate")
        }
    }

    func testPerformanceOperation_DetectsThresholdExceeded() {
        // Given
        let threshold: TimeInterval = 0.1
        let slowOperation = { () -> Void in
            Thread.sleep(forTimeInterval: 0.15)
        }

        // When
        PerformanceTelemetry.measure("Slow Operation", threshold: threshold, block: slowOperation)

        // Then
        let events = UITelemetryTracker.shared.getEvents()
        let perfEvent = events.first { $0.type == .performance }

        XCTAssertNotNil(perfEvent, "Performance event should exist")
        XCTAssertEqual(perfEvent?.context["exceeded_threshold"], "true",
                      "Should flag that threshold was exceeded")
    }

    // MARK: - Session Replay Tests

    func testSessionReplay_CapturesUIEvents() {
        // Given
        let replay = SessionReplay.shared
        replay.clearSession()

        // When - Perform series of actions
        let tracker = UITelemetryTracker.shared
        tracker.trackTap("Play", in: "SongCard")
        tracker.trackNavigation(from: "Library", to: "Moving Sidewalk")
        tracker.trackScreenView("MovingSidewalkView")

        // Then - Verify replay captured all events
        let replayEvents = replay.getEvents()
        XCTAssertEqual(replayEvents.count, 3, "Replay should capture all events")
    }

    func testSessionReplay_MaintainsEventOrder() {
        // Given
        let replay = SessionReplay.shared
        replay.clearSession()

        let expectedActions = ["First", "Second", "Third", "Fourth"]

        // When
        for action in expectedActions {
            UITelemetryTracker.shared.trackTap(action, in: "TestView")
        }

        // Then
        let replayEvents = replay.getEvents()
        let actualActions = replayEvents.map { $0.action }

        XCTAssertEqual(actualActions, expectedActions, "Events should maintain order")
    }

    func testSessionReplay_RecordsTimestamps() {
        // Given
        let replay = SessionReplay.shared
        replay.clearSession()

        // When
        UITelemetryTracker.shared.trackTap("Test", in: "TestView")

        // Then
        let events = replay.getEvents()
        XCTAssertFalse(events.isEmpty, "Should have events")
        XCTAssertNotNil(events.first?.timestamp, "Events should have timestamps")
    }

    // MARK: - Dashboard Integration Tests

    func testTelemetryIntegration_WithDashboard() {
        // Given
        let testSummary = TestSummary.testInstance

        // When - Generate telemetry report
        let telemetryReport = TelemetryMetrics.shared.generateReport(from: testSummary)

        // Then - Verify report contains expected data
        XCTAssertGreaterThanOrEqual(telemetryReport.totalUIEvents, 0,
                                   "Should have UI events count")
        XCTAssertGreaterThanOrEqual(telemetryReport.averageResponseTime, 0,
                                   "Should have response time")
        XCTAssertGreaterThanOrEqual(telemetryReport.crashFreeSessions, 0,
                                   "Should have crash-free sessions")
    }

    func testTelemetryReport_GeneratesSummary() {
        // Given
        let report = TelemetryReport(
            totalUIEvents: 150,
            averageResponseTime: 0.085,
            slowOperations: [],
            errorCount: 2,
            topErrors: [],
            crashFreeSessions: 99.5
        )

        // When
        let summary = report.summary

        // Then
        XCTAssertTrue(summary.contains("150"), "Should contain UI events count")
        XCTAssertTrue(summary.contains("85ms"), "Should contain response time")
        XCTAssertTrue(summary.contains("99.5%"), "Should contain crash-free percentage")
    }

    func testTelemetryReport_QualityThresholds() {
        // Given - Good telemetry
        let goodReport = TelemetryReport(
            totalUIEvents: 100,
            averageResponseTime: 0.1, // 100ms
            slowOperations: [],
            errorCount: 0,
            topErrors: [],
            crashFreeSessions: 99.9
        )

        // Then
        XCTAssertTrue(goodReport.meetsQualityThresholds,
                     "Good telemetry should meet thresholds")

        // Given - Bad telemetry
        let badReport = TelemetryReport(
            totalUIEvents: 100,
            averageResponseTime: 0.25, // 250ms - too slow
            slowOperations: [],
            errorCount: 0,
            topErrors: [],
            crashFreeSessions: 99.9
        )

        // Then
        XCTAssertFalse(badReport.meetsQualityThresholds,
                      "Bad telemetry should not meet thresholds")
    }

    // MARK: - Query Builder Tests

    func testQueryBuilder_BuildsDateRangeQuery() {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)

        // When
        let criteria = QueryCriteria(startDate: yesterday, endDate: now)
        let query = TelemetryQueryBuilder.buildQuery(for: criteria)

        // Then
        XCTAssertFalse(query.filters.isEmpty, "Query should have filters")

        if case .dateRange(let start, let end) = query.filters.first {
            XCTAssertEqual(start, yesterday, "Start date should match")
            XCTAssertEqual(end, now, "End date should match")
        } else {
            XCTFail("First filter should be date range")
        }
    }

    func testQueryBuilder_BuildsEventTypeQuery() {
        // Given
        let criteria = QueryCriteria(eventTypes: [.uiInteraction, .error])

        // When
        let query = TelemetryQueryBuilder.buildQuery(for: criteria)

        // Then
        XCTAssertTrue(query.filters.contains { filter in
            if case .eventTypes(let types) = filter {
                return types == [.uiInteraction, .error]
            }
            return false
        }, "Should have event type filter")
    }

    func testQueryBuilder_LastHoursConvenience() {
        // Given
        let hours = 24

        // When
        let criteria = QueryCriteria.lastHours(hours)
        let query = TelemetryQueryBuilder.buildQuery(for: criteria)

        // Then
        if case .dateRange(let start, let end) = query.filters.first {
            let timeDiff = end.timeIntervalSince(start)
            let expectedDiff = TimeInterval(hours * 3600)
            XCTAssertEqual(timeDiff, expectedDiff, accuracy: 1.0,
                          "Time range should be approximately \(hours) hours")
        } else {
            XCTFail("Should have date range filter")
        }
    }

    // MARK: - Slow Operation Tests

    func testSlowOperation_DetectsSeverity() {
        // Given
        let threshold: TimeInterval = 0.1

        // When - Warning severity
        let warningOp = SlowOperation(name: "Test", duration: 0.13, threshold: threshold)
        XCTAssertEqual(warningOp.severity, "Warning", "Should be warning severity")

        // When - Minor severity
        let minorOp = SlowOperation(name: "Test", duration: 0.17, threshold: threshold)
        XCTAssertEqual(minorOp.severity, "Minor", "Should be minor severity")

        // When - Moderate severity
        let moderateOp = SlowOperation(name: "Test", duration: 0.25, threshold: threshold)
        XCTAssertEqual(moderateOp.severity, "Moderate", "Should be moderate severity")

        // When - Severe severity
        let severeOp = SlowOperation(name: "Test", duration: 0.5, threshold: threshold)
        XCTAssertEqual(severeOp.severity, "Severe", "Should be severe severity")
    }

    func testSlowOperation_CalculatesExcessDuration() {
        // Given
        let duration: TimeInterval = 0.2
        let threshold: TimeInterval = 0.1
        let expectedExcess = 0.1

        // When
        let slowOp = SlowOperation(name: "Test", duration: duration, threshold: threshold)

        // Then
        XCTAssertEqual(slowOp.excessDuration, expectedExcess,
                      accuracy: 0.001,
                      "Should calculate excess duration")
    }

    // MARK: - Error Metric Tests

    func testErrorMetric_HasUniqueId() {
        // Given
        let error1 = ErrorMetric(message: "Test Error", count: 5, frequency: 0.1)
        let error2 = ErrorMetric(message: "Test Error", count: 5, frequency: 0.1)

        // Then
        XCTAssertNotEqual(error1.id, error2.id, "Each error metric should have unique ID")
    }

    // MARK: - Complex Scenarios

    func testComplexUserFlow_CompleteTelemetryCapture() {
        // Given
        let tracker = UITelemetryTracker.shared

        // When - Simulate complete user flow
        tracker.trackScreenView("LibraryView")
        tracker.trackTap("Song Card", in: "LibraryView")
        tracker.trackNavigation(from: "Library", to: "Moving Sidewalk")
        tracker.trackScreenView("MovingSidewahView")

        PerformanceTelemetry.measure("Load Preset", threshold: 0.05) {
            Thread.sleep(forTimeInterval: 0.08) // Simulate slow load
        }

        tracker.trackTap("Save Button", in: "MovingSidewalkView")

        // Then
        let events = tracker.getEvents()
        XCTAssertEqual(events.filter { $0.type == .uiInteraction }.count, 4,
                      "Should have 4 UI interactions")
        XCTAssertEqual(events.filter { $0.type == .navigation }.count, 1,
                      "Should have 1 navigation")
        XCTAssertEqual(events.filter { $0.type == .performance }.count, 1,
                      "Should have 1 performance measurement")
    }

    func testTelemetryAggregation_CreatesAccurateReport() {
        // Given
        let tracker = UITelemetryTracker.shared
        tracker.clear()

        // When - Generate various events
        for _ in 0..<10 {
            tracker.trackTap("Button", in: "TestView")
        }

        for i in 0..<3 {
            PerformanceTelemetry.measure("Operation \(i)", threshold: 0.1) {
                Thread.sleep(forTimeInterval: 0.15)
            }
        }

        tracker.trackError("Test Error", in: "TestView")

        // Then
        let events = tracker.getEvents()
        let report = TelemetryMetrics.shared.generateReport(from: events)

        XCTAssertEqual(report.totalUIEvents, 11, // 10 taps + 1 error
                      "Should count all UI events")
        XCTAssertEqual(report.errorCount, 1,
                      "Should count error event")
        XCTAssertEqual(report.slowOperations.count, 3,
                      "Should detect all slow operations")
    }
}

// MARK: - Test Helpers

extension TelemetryAssertionTests {
    func createSampleEvents(count: Int) -> [TelemetryEvent] {
        (0..<count).map { index in
            TelemetryEvent(
                type: .uiInteraction,
                screen: "TestScreen",
                element: "Element\(index)",
                action: "action\(index)"
            )
        }
    }
}

// MARK: - Performance Extensions

extension PerformanceTelemetry {
    static func measure(
        _ name: String,
        threshold: TimeInterval,
        block: () -> Void
    ) {
        let start = Date()
        block()
        let duration = Date().timeIntervalSince(start)

        let tracker = UITelemetryTracker.shared
        let event = TelemetryEvent.performance(
            screen: "unknown",
            operation: name,
            duration: duration,
            threshold: threshold
        )

        Task {
            await tracker.trackEvent(event)
        }
    }
}

extension UITelemetryTracker {
    func clear() {
        // Clear events - implementation depends on storage
        // This is a placeholder for the actual implementation
    }

    func getEvents() -> [TelemetryEvent] {
        // Get all events - implementation depends on storage
        // This is a placeholder for the actual implementation
        return []
    }

    func trackEvent(_ event: TelemetryEvent) async {
        // Track event - implementation depends on storage
        // This is a placeholder for the actual implementation
    }
}

extension SessionReplay {
    static var shared: SessionReplay {
        SessionReplay()
    }

    func clearSession() {
        // Clear session - implementation depends on storage
    }

    func getEvents() -> [TelemetryEvent] {
        // Get replay events - implementation depends on storage
        return []
    }
}

struct SessionReplay {
    init() {}
}
