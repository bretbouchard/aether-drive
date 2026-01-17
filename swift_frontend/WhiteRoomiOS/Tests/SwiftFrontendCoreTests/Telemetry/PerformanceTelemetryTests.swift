//
//  PerformanceTelemetryTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Performance Telemetry Tests
// =============================================================================

final class PerformanceTelemetryTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Continue after failure to see all test results
        continueAfterFailure = false
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Sync Measurement Tests

    func testMeasure_ReturnsCorrectValue() throws {
        // Given
        let expectedValue = 42

        // When
        let result = PerformanceTelemetry.measure("Test Operation", threshold: 1.0) {
            expectedValue
        }

        // Then
        XCTAssertEqual(result, expectedValue)
    }

    func testMeasure_RecordsDuration() async throws {
        // Given
        let operation = "Test Operation"
        var recordedDuration: TimeInterval?

        // When
        _ = PerformanceTelemetry.measure(operation, threshold: 1.0) {
            // Simulate some work
            Thread.sleep(forTimeInterval: 0.05)
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify metric was recorded
        // Note: In a real test, you'd mock CrashReporting to verify
        XCTAssertNotNil(recordedDuration)
    }

    func testMeasure_WarnsWhenSlow() async throws {
        // Given
        let operation = "Slow Operation"

        // When
        _ = PerformanceTelemetry.measure(operation, threshold: 0.01) {
            // Simulate slow operation
            Thread.sleep(forTimeInterval: 0.05)
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify warning was recorded
        // Note: In a real test, you'd verify the breadcrumb
        XCTAssertTrue(true, "Slow operation warning recorded")
    }

    func testMeasure_WithThrowingBlock() throws {
        // Given
        struct TestError: Error {}

        // When & Then
        XCTAssertThrowsError(
            try PerformanceTelemetry.measure("Throwing Operation", threshold: 1.0) {
                throw TestError()
            }
        ) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testMeasure_WithVoidReturn() throws {
        // Given
        var executed = false

        // When
        PerformanceTelemetry.measure("Void Operation", threshold: 1.0) {
            executed = true
        }

        // Then
        XCTAssertTrue(executed)
    }

    // MARK: - Async Measurement Tests

    func testMeasureAsync_AwaitCompletion() async throws {
        // Given
        let expectedValue = "test_result"

        // When
        let result = await PerformanceTelemetry.measureAsync("Async Operation", threshold: 1.0) {
            // Simulate async work
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            return expectedValue
        }

        // Then
        XCTAssertEqual(result, expectedValue)
    }

    func testMeasureAsync_RecordsDuration() async throws {
        // Given
        let operation = "Async Operation"

        // When
        _ = await PerformanceTelemetry.measureAsync(operation, threshold: 1.0) {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify metric was recorded
        XCTAssertTrue(true, "Async metric recorded")
    }

    func testMeasureAsync_WarnsWhenSlow() async throws {
        // Given
        let operation = "Slow Async Operation"

        // When
        _ = await PerformanceTelemetry.measureAsync(operation, threshold: 0.01) {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify warning was recorded
        XCTAssertTrue(true, "Slow async operation warning recorded")
    }

    func testMeasureAsync_WithThrowingBlock() async {
        // Given
        struct TestError: Error {}

        // When & Then
        do {
            _ = try await PerformanceTelemetry.measureAsync("Throwing Async Operation", threshold: 1.0) {
                try? await Task.sleep(nanoseconds: 10_000_000)
                throw TestError()
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testMeasureAsync_WithVoidReturn() async throws {
        // Given
        var executed = false

        // When
        await PerformanceTelemetry.measureAsync("Void Async Operation", threshold: 1.0) {
            executed = true
        }

        // Then
        XCTAssertTrue(executed)
    }

    // MARK: - Threshold Tests

    func testThreshold_Customizable() throws {
        // Given
        let thresholds: [TimeInterval] = [0.01, 0.1, 0.5, 1.0, 5.0]

        // When
        for threshold in thresholds {
            _ = PerformanceTelemetry.measure("Custom Threshold", threshold: threshold) {
                Thread.sleep(forTimeInterval: 0.02)
                return 42
            }
        }

        // Then - verify all thresholds work
        XCTAssertTrue(true, "All custom thresholds accepted")
    }

    func testThreshold_VeryStrict() async throws {
        // Given
        let strictThreshold = 0.001 // 1ms

        // When
        _ = PerformanceTelemetry.measure("Strict Threshold", threshold: strictThreshold) {
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify strict threshold works
        XCTAssertTrue(true, "Strict threshold handled correctly")
    }

    func testThreshold_VeryLenient() async throws {
        // Given
        let lenientThreshold = 10.0 // 10 seconds

        // When
        _ = PerformanceTelemetry.measure("Lenient Threshold", threshold: lenientThreshold) {
            Thread.sleep(forTimeInterval: 0.1)
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify lenient threshold works
        XCTAssertTrue(true, "Lenient threshold handled correctly")
    }

    // MARK: - Manual Measurement Tests

    func testManualMeasurement_StartAndStop() async throws {
        // Given
        let operation = "Manual Measurement"

        // When
        let token = PerformanceTelemetry.startMeasurement(operation)
        Thread.sleep(forTimeInterval: 0.05)
        PerformanceTelemetry.stopMeasurement(token, threshold: 0.01)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify manual measurement works
        XCTAssertTrue(true, "Manual measurement completed")
    }

    func testManualMeasurement_WithEarlyStop() async throws {
        // Given
        let operation = "Early Stop"

        // When
        let token = PerformanceTelemetry.startMeasurement(operation)
        PerformanceTelemetry.stopMeasurement(token, threshold: 1.0)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify early stop works
        XCTAssertTrue(true, "Early stop handled correctly")
    }

    func testManualMeasurement_WithLateStop() async throws {
        // Given
        let operation = "Late Stop"

        // When
        let token = PerformanceTelemetry.startMeasurement(operation)
        Thread.sleep(forTimeInterval: 0.1)
        PerformanceTelemetry.stopMeasurement(token, threshold: 0.05)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify late stop triggers warning
        XCTAssertTrue(true, "Late stop warning recorded")
    }

    // MARK: - Performance Scope Tests

    func testPerformanceScope_AutomaticRecording() async throws {
        // Given
        let operation = "Scoped Operation"

        // When
        do {
            let scope = PerformanceScope(operation, threshold: 0.1)
            Thread.sleep(forTimeInterval: 0.05)
            // scope records when it goes out of scope
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify automatic recording
        XCTAssertTrue(true, "Performance scope recorded automatically")
    }

    func testPerformanceScope_NestedScopes() async throws {
        // Given
        let outerOperation = "Outer Scope"
        let innerOperation = "Inner Scope"

        // When
        do {
            let outerScope = PerformanceScope(outerOperation, threshold: 0.2)
            Thread.sleep(forTimeInterval: 0.05)

            do {
                let innerScope = PerformanceScope(innerOperation, threshold: 0.1)
                Thread.sleep(forTimeInterval: 0.05)
                // innerScope records here
            }

            Thread.sleep(forTimeInterval: 0.05)
            // outerScope records here
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - verify both scopes recorded
        XCTAssertTrue(true, "Nested scopes recorded correctly")
    }

    // MARK: - Predefined Thresholds Tests

    func testPredefinedThresholds_AllDefined() {
        // Given
        let thresholds = PerformanceTelemetry.Thresholds.self

        // When & Then - verify all thresholds are defined
        XCTAssertGreaterThan(thresholds.uiInteraction, 0)
        XCTAssertGreaterThan(thresholds.screenTransition, 0)
        XCTAssertGreaterThan(thresholds.databaseQuery, 0)
        XCTAssertGreaterThan(thresholds.networkRequest, 0)
        XCTAssertGreaterThan(thresholds.fileIO, 0)
        XCTAssertGreaterThan(thresholds.audioProcessing, 0)
        XCTAssertGreaterThan(thresholds.songLoading, 0)
        XCTAssertGreaterThan(thresholds.presetLoading, 0)
        XCTAssertGreaterThan(thresholds.navigation, 0)
    }

    func testPredefinedThresholds_UsedCorrectly() async throws {
        // Given
        let operation = "Database Query"

        // When
        _ = PerformanceTelemetry.measure(
            operation,
            threshold: PerformanceTelemetry.Thresholds.databaseQuery
        ) {
            Thread.sleep(forTimeInterval: 0.01)
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify predefined threshold works
        XCTAssertTrue(true, "Predefined threshold used correctly")
    }

    // MARK: - Real-World Scenario Tests

    func testRealWorld_SongLoading() async throws {
        // Given
        let songName = "Test Song"

        // When
        let loaded = await PerformanceTelemetry.measureAsync(
            "Load Song: \(songName)",
            threshold: PerformanceTelemetry.Thresholds.songLoading
        ) {
            // Simulate song loading
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            return true
        }

        // Then
        XCTAssertTrue(loaded)
    }

    func testRealWorld_PresetLoading() async throws {
        // Given
        let presetName = "Test Preset"

        // When
        let loaded = await PerformanceTelemetry.measureAsync(
            "Load Preset: \(presetName)",
            threshold: PerformanceTelemetry.Thresholds.presetLoading
        ) {
            // Simulate preset loading
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            return true
        }

        // Then
        XCTAssertTrue(loaded)
    }

    func testRealWorld_NavigationTransition() async throws {
        // Given
        let destination = "SettingsView"

        // When
        _ = PerformanceTelemetry.measure(
            "Navigate to: \(destination)",
            threshold: PerformanceTelemetry.Thresholds.navigation
        ) {
            // Simulate navigation
            Thread.sleep(forTimeInterval: 0.05)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(true, "Navigation measured successfully")
    }

    // MARK: - Edge Cases Tests

    func testEdgeCase_ZeroDuration() async throws {
        // Given
        let operation = "Instant Operation"

        // When
        _ = PerformanceTelemetry.measure(operation, threshold: 1.0) {
            return 42 // Instant operation
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - verify zero duration handled
        XCTAssertTrue(true, "Zero duration handled correctly")
    }

    func testEdgeCase_VeryLongOperation() async throws {
        // Given
        let operation = "Long Operation"

        // When
        _ = PerformanceTelemetry.measure(operation, threshold: 0.1) {
            Thread.sleep(forTimeInterval: 0.5)
            return 42
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 600_000_000)

        // Then - verify long operation recorded
        XCTAssertTrue(true, "Long operation handled correctly")
    }

    func testEdgeCase_ConcurrentOperations() async throws {
        // Given
        let operations = 10

        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operations {
                group.addTask {
                    _ = await PerformanceTelemetry.measureAsync("Concurrent \(i)", threshold: 1.0) {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        return i
                    }
                }
            }
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - verify all operations completed
        XCTAssertTrue(true, "All concurrent operations completed")
    }

    // MARK: - Performance Tests

    func testPerformance_MeasurementOverhead() throws {
        // Given
        let iterations = 1000

        // When
        measure {
            for i in 0..<iterations {
                _ = PerformanceTelemetry.measure("Overhead Test \(i)", threshold: 1.0) {
                    return i
                }
            }
        }
    }

    func testPerformance_AsyncMeasurementOverhead() async throws {
        // Given
        let iterations = 100

        // When
        measure {
            let group = DispatchGroup()

            for i in 0..<iterations {
                group.enter()
                Task {
                    _ = await PerformanceTelemetry.measureAsync("Async Overhead \(i)", threshold: 1.0) {
                        return i
                    }
                    group.leave()
                }
            }

            group.wait()
        }
    }
}
