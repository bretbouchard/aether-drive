//
//  SessionReplayTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Session Replay Tests
// =============================================================================

final class SessionReplayTests: XCTestCase {

    // MARK: - Properties

    private var sessionReplay: SessionReplay!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sessionReplay = SessionReplay.shared
        sessionReplay.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sessionReplay.clearSession()
    }

    // MARK: - Recording Tests

    func testRecord_AddsEvent() async throws {
        // Given
        let event = ReplayEvent(
            type: .tap,
            screen: "TestScreen",
            action: "Test Action",
            context: [:]
        )

        // When
        sessionReplay.record(event)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, 1, "Event should be recorded")
    }

    func testRecord_MultipleEvents() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:]),
            ReplayEvent(type: .gesture, screen: "Screen3", action: "Action3", context: [:])
        ]

        // When
        for event in events {
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, 3, "All events should be recorded")
    }

    func testRecord_AllEventTypes() async throws {
        // Given
        let eventTypes: [EventType] = [.tap, .gesture, .navigation, .valueChange, .screenView, .error]

        // When
        for type in eventTypes {
            let event = ReplayEvent(
                type: type,
                screen: "TestScreen",
                action: "\(type) action",
                context: ["type": type.rawValue]
            )
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, eventTypes.count, "All event types should be recorded")
    }

    // MARK: - Circular Buffer Tests

    func testCircularBuffer_LimitsToMax() async throws {
        // Given
        let maxEvents = 1000 // default max
        let eventsToRecord = maxEvents + 100

        // When
        for i in 0..<eventsToRecord {
            let event = ReplayEvent(
                type: .tap,
                screen: "Screen\(i)",
                action: "Action\(i)",
                context: ["index": String(i)]
            )
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, maxEvents, "Should only keep max events")
    }

    func testCircularBuffer_RemovesOldest() async throws {
        // Given
        let maxEvents = 1000 // default max

        // When
        for i in 0..<maxEvents {
            let event = ReplayEvent(
                type: .tap,
                screen: "Screen\(i)",
                action: "Action\(i)",
                context: ["index": String(i)]
            )
            sessionReplay.record(event)
        }

        // Add one more
        let lastEvent = ReplayEvent(
            type: .tap,
            screen: "LastScreen",
            action: "LastAction",
            context: [:]
        )
        sessionReplay.record(lastEvent)

        // Allow async processing
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        let events = sessionReplay.getEvents()
        XCTAssertEqual(events.count, maxEvents, "Should maintain max count")

        // Verify first event was removed
        let firstEvent = events.first
        XCTAssertNotEqual(firstEvent?.screen, "Screen0", "Oldest event should be removed")
    }

    // MARK: - Save Session Tests

    func testSaveSession_WritesToDisk() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        ]

        for event in events {
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        try sessionReplay.saveSession()

        // Then
        let savedSessions = try sessionReplay.listSavedSessions()
        XCTAssertTrue(savedSessions.count > 0, "Session should be saved to disk")
    }

    func testSaveSession_WithMultipleEvents() async throws {
        // Given
        let eventCount = 100

        for i in 0..<eventCount {
            let event = ReplayEvent(
                type: .tap,
                screen: "Screen\(i)",
                action: "Action\(i)",
                context: [:]
            )
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 500_000_000)

        // When
        try sessionReplay.saveSession()

        // Then
        let savedSessions = try sessionReplay.listSavedSessions()
        XCTAssertTrue(savedSessions.count > 0, "Session with many events should be saved")
    }

    func testSaveSession_AutoSavesOnError() async throws {
        // Given
        let errorEvent = ReplayEvent(
            type: .error,
            screen: "ErrorScreen",
            action: "Critical Error",
            context: ["error": "test error"]
        )

        // When
        sessionReplay.record(errorEvent)

        // Allow async processing
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then - should auto-save
        let savedSessions = try sessionReplay.listSavedSessions()
        XCTAssertTrue(savedSessions.count > 0, "Error event should trigger auto-save")
    }

    // MARK: - Load Session Tests

    func testLoadSession_RetrievesCorrectSession() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        ]

        for event in events {
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        try sessionReplay.saveSession()

        let savedSessions = try sessionReplay.listSavedSessions()
        guard let filename = savedSessions.first else {
            XCTFail("No session saved")
            return
        }

        // When
        let loadedSession = try sessionReplay.loadSession(filename: filename)

        // Then
        XCTAssertEqual(loadedSession.events.count, events.count, "Loaded session should have same event count")
    }

    func testLoadSession_PreservesEventData() async throws {
        // Given
        let originalEvent = ReplayEvent(
            type: .gesture,
            screen: "TestScreen",
            action: "Swipe Left",
            context: ["direction": "left", "speed": "fast"]
        )

        sessionReplay.record(originalEvent)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        try sessionReplay.saveSession()

        let savedSessions = try sessionReplay.listSavedSessions()
        guard let filename = savedSessions.first else {
            XCTFail("No session saved")
            return
        }

        // When
        let loadedSession = try sessionReplay.loadSession(filename: filename)

        // Then
        XCTAssertEqual(loadedSession.events.count, 1, "Should have one event")

        let loadedEvent = loadedSession.events.first
        XCTAssertEqual(loadedEvent?.type, originalEvent.type, "Event type should match")
        XCTAssertEqual(loadedEvent?.screen, originalEvent.screen, "Screen should match")
        XCTAssertEqual(loadedEvent?.action, originalEvent.action, "Action should match")
        XCTAssertEqual(loadedEvent?.context, originalEvent.context, "Context should match")
    }

    // MARK: - Clear Session Tests

    func testClearSession_EmptyBuffer() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        ]

        for event in events {
            sessionReplay.record(event)
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        sessionReplay.clearSession()

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, 0, "Session should be cleared")
    }

    func testClearSession_DoesNotDeleteDiskFiles() async throws {
        // Given
        let event = ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:])

        sessionReplay.record(event)

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        try sessionReplay.saveSession()

        let savedSessionsBefore = try sessionReplay.listSavedSessions()

        // When
        sessionReplay.clearSession()

        // Allow async processing
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let savedSessionsAfter = try sessionReplay.listSavedSessions()
        XCTAssertEqual(
            savedSessionsAfter.count,
            savedSessionsBefore.count,
            "Disk files should not be deleted"
        )
    }

    // MARK: - Multiple Sessions Tests

    func testMultipleSessions_DontConflict() async throws {
        // Given
        let session1Events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        ]

        let session2Events = [
            ReplayEvent(type: .gesture, screen: "Screen3", action: "Action3", context: [:]),
            ReplayEvent(type: .valueChange, screen: "Screen4", action: "Action4", context: [:])
        ]

        // When - record and save first session
        for event in session1Events {
            sessionReplay.record(event)
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        try sessionReplay.saveSession()

        // Record and save second session
        sessionReplay.clearSession()

        for event in session2Events {
            sessionReplay.record(event)
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        try sessionReplay.saveSession()

        // Then
        let savedSessions = try sessionReplay.listSavedSessions()
        XCTAssertEqual(savedSessions.count, 2, "Should have two separate sessions")
    }

    // MARK: - Delete Session Tests

    func testDeleteSession_RemovesFile() async throws {
        // Given
        let event = ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:])

        sessionReplay.record(event)

        try await Task.sleep(nanoseconds: 100_000_000)
        try sessionReplay.saveSession()

        let savedSessions = try sessionReplay.listSavedSessions()
        guard let filename = savedSessions.first else {
            XCTFail("No session saved")
            return
        }

        // When
        try sessionReplay.deleteSession(filename: filename)

        // Then
        let savedSessionsAfter = try sessionReplay.listSavedSessions()
        XCTAssertFalse(savedSessionsAfter.contains(filename), "Session should be deleted")
    }

    func testDeleteSession_NonExistentFile() {
        // Given
        let filename = "nonexistent_session.json"

        // When & Then
        XCTAssertThrowsError(
            try sessionReplay.deleteSession(filename: filename)
        ) { error in
            XCTAssertTrue(error is SessionReplayError, "Should throw SessionReplayError")
        }
    }

    func testDeleteAllSessions_RemovesAllFiles() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        ]

        for event in events {
            sessionReplay.record(event)
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        try sessionReplay.saveSession()

        // When
        try sessionReplay.deleteAllSessions()

        // Then
        let savedSessions = try sessionReplay.listSavedSessions()
        XCTAssertEqual(savedSessions.count, 0, "All sessions should be deleted")
    }

    // MARK: - Export Tests

    func testExportSessionAsJSON_ReturnsValidJSON() async throws {
        // Given
        let event = ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:])

        sessionReplay.record(event)

        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        let jsonString = try sessionReplay.exportSessionAsJSON()

        // Then
        XCTAssertFalse(jsonString.isEmpty, "JSON string should not be empty")

        // Verify it's valid JSON
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Should be valid JSON")
    }

    // MARK: - Statistics Tests

    func testGetSessionStatistics_ReturnsCorrectCounts() async throws {
        // Given
        let events = [
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:]),
            ReplayEvent(type: .tap, screen: "Screen1", action: "Action2", context: [:]),
            ReplayEvent(type: .navigation, screen: "Screen2", action: "Action3", context: [:])
        ]

        for event in events {
            sessionReplay.record(event)
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        let stats = await sessionReplay.getSessionStatistics()

        // Then
        XCTAssertEqual(stats.eventCount, 3, "Should have 3 events")
        XCTAssertEqual(stats.eventTypeCounts[.tap], 2, "Should have 2 tap events")
        XCTAssertEqual(stats.eventTypeCounts[.navigation], 1, "Should have 1 navigation event")
    }

    func testGetSessionStatistics_CalculatesDuration() async throws {
        // Given
        let event1 = ReplayEvent(type: .tap, screen: "Screen1", action: "Action1", context: [:])
        sessionReplay.record(event1)

        try await Task.sleep(nanoseconds: 100_000_000)

        let event2 = ReplayEvent(type: .navigation, screen: "Screen2", action: "Action2", context: [:])
        sessionReplay.record(event2)

        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        let stats = await sessionReplay.getSessionStatistics()

        // Then
        XCTAssertGreaterThan(stats.duration, 0, "Duration should be greater than 0")
    }

    // MARK: - Thread Safety Tests

    func testThreadSafety_ConcurrentRecording() async throws {
        // Given
        let expectation = expectation(description: "Concurrent recording complete")
        expectation.expectedFulfillmentCount = 100

        // When
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            let event = ReplayEvent(
                type: .tap,
                screen: "Screen\(index)",
                action: "Action\(index)",
                context: [:]
            )
            self.sessionReplay.record(event)
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)

        // Allow async processing
        try await Task.sleep(nanoseconds: 200_000_000)

        let count = sessionReplay.getEventCount()
        XCTAssertEqual(count, 100, "All concurrent events should be recorded")
    }

    // MARK: - Event Context Tests

    func testEventContext_PreservesComplexData() async throws {
        // Given
        let complexContext = [
            "user_id": "12345",
            "preset_name": "My Preset",
            "bpm": "120",
            "time_signature": "4/4",
            "is_dirty": "true"
        ]

        let event = ReplayEvent(
            type: .valueChange,
            screen: "SettingsScreen",
            action: "Changed preset",
            context: complexContext
        )

        sessionReplay.record(event)

        try await Task.sleep(nanoseconds: 100_000_000)

        try sessionReplay.saveSession()

        // When
        let savedSessions = try sessionReplay.listSavedSessions()
        guard let filename = savedSessions.first else {
            XCTFail("No session saved")
            return
        }

        let loadedSession = try sessionReplay.loadSession(filename: filename)

        // Then
        let loadedEvent = loadedSession.events.first
        XCTAssertEqual(loadedEvent?.context, complexContext, "Complex context should be preserved")
    }

    // MARK: - Performance Tests

    func testPerformance_RecordThousandEvents() async throws {
        // Given
        measure {
            for i in 0..<1000 {
                let event = ReplayEvent(
                    type: .tap,
                    screen: "Screen\(i)",
                    action: "Action\(i)",
                    context: [:]
                )
                self.sessionReplay.record(event)
            }
        }

        // Allow async processing
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func testPerformance_SaveLargeSession() async throws {
        // Given
        for i in 0..<1000 {
            let event = ReplayEvent(
                type: .tap,
                screen: "Screen\(i)",
                action: "Action\(i)",
                context: [:]
            )
            sessionReplay.record(event)
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        // When
        measure {
            try? self.sessionReplay.saveSession()
        }
    }
}
