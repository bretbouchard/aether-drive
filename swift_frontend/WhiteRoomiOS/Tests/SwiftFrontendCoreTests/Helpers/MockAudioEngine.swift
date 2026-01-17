//
//  MockAudioEngine.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Mock Multi Song Engine
// =============================================================================

/**
 Mock implementation of MultiSongEngine for testing
 */
public class MockMultiSongEngine {

    // MARK: - Tracking Properties

    public var loadSongCalled = false
    public var loadSongCallCount = 0
    public var loadedSongs: [(slot: Int, song: SongPlayerState)] = []

    public var playSlotCalled = false
    public var playSlotCallCount = 0
    public var playedSlots: [Int] = []

    public var pauseSlotCalled = false
    public var pauseSlotCallCount = 0
    public var pausedSlots: [Int] = []

    public var stopAllCalled = false
    public var stopAllCallCount = 0

    public var setTempoCalled = false
    public var tempoChanges: [(slot: Int, tempo: Double)] = []

    public var setVolumeCalled = false
    public var volumeChanges: [(slot: Int, volume: Double)] = []

    public var setMuteCalled = false
    public var muteChanges: [(slot: Int, muted: Bool)] = []

    public var setSoloCalled = false
    public var soloChanges: [(slot: Int, soloed: Bool)] = []

    public var seekCalled = false
    public var seekOperations: [(slot: Int, position: Double)] = []

    // MARK: - Error Simulation

    public var shouldFailLoadSong = false
    public var loadSongError: Error?

    public var shouldFailPlaySlot = false
    public var playSlotError: Error?

    public var shouldFailPauseSlot = false
    public var pauseSlotError: Error?

    // MARK: - Async State Tracking

    public var activeOperations: Set<String> = []
    public var completedOperations: Set<String> = []

    // MARK: - Song Loading

    public func loadSong(into slot: Int, song: SongPlayerState) async throws {
        let operationName = "loadSong-\(slot)"

        activeOperations.insert(operationName)
        loadSongCalled = true
        loadSongCallCount += 1
        loadedSongs.append((slot, song))

        if shouldFailLoadSong {
            activeOperations.remove(operationName)
            throw loadSongError ?? MockEngineError.loadFailed
        }

        // Simulate async operation
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        activeOperations.remove(operationName)
        completedOperations.insert(operationName)
    }

    // MARK: - Playback Control

    public func playSlot(_ slot: Int) async throws {
        let operationName = "playSlot-\(slot)"

        activeOperations.insert(operationName)
        playSlotCalled = true
        playSlotCallCount += 1
        playedSlots.append(slot)

        if shouldFailPlaySlot {
            activeOperations.remove(operationName)
            throw playSlotError ?? MockEngineError.playFailed
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        activeOperations.remove(operationName)
        completedOperations.insert(operationName)
    }

    public func pauseSlot(_ slot: Int) async throws {
        let operationName = "pauseSlot-\(slot)"

        activeOperations.insert(operationName)
        pauseSlotCalled = true
        pauseSlotCallCount += 1
        pausedSlots.append(slot)

        if shouldFailPauseSlot {
            activeOperations.remove(operationName)
            throw pauseSlotError ?? MockEngineError.pauseFailed
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        activeOperations.remove(operationName)
        completedOperations.insert(operationName)
    }

    public func stopAll() async throws {
        let operationName = "stopAll"

        activeOperations.insert(operationName)
        stopAllCalled = true
        stopAllCallCount += 1

        try? await Task.sleep(nanoseconds: 10_000_000)

        activeOperations.remove(operationName)
        completedOperations.insert(operationName)
    }

    // MARK: - Parameter Control

    public func setTempo(slot: Int, tempo: Double) async throws {
        setTempoCalled = true
        tempoChanges.append((slot, tempo))
        try? await Task.sleep(nanoseconds: 5_000_000)
    }

    public func setVolume(slot: Int, volume: Double) async throws {
        setVolumeCalled = true
        volumeChanges.append((slot, volume))
        try? await Task.sleep(nanoseconds: 5_000_000)
    }

    public func setMute(slot: Int, muted: Bool) async throws {
        setMuteCalled = true
        muteChanges.append((slot, muted))
        try? await Task.sleep(nanoseconds: 5_000_000)
    }

    public func setSolo(slot: Int, soloed: Bool) async throws {
        setSoloCalled = true
        soloChanges.append((slot, soloed))
        try? await Task.sleep(nanoseconds: 5_000_000)
    }

    public func seek(slot: Int, position: Double) async throws {
        seekCalled = true
        seekOperations.append((slot, position))
        try? await Task.sleep(nanoseconds: 5_000_000)
    }

    // MARK: - Reset

    public func reset() {
        loadSongCalled = false
        loadSongCallCount = 0
        loadedSongs = []

        playSlotCalled = false
        playSlotCallCount = 0
        playedSlots = []

        pauseSlotCalled = false
        pauseSlotCallCount = 0
        pausedSlots = []

        stopAllCalled = false
        stopAllCallCount = 0

        setTempoCalled = false
        tempoChanges = []

        setVolumeCalled = false
        volumeChanges = []

        setMuteCalled = false
        muteChanges = []

        setSoloCalled = false
        soloChanges = []

        seekCalled = false
        seekOperations = []

        shouldFailLoadSong = false
        loadSongError = nil

        shouldFailPlaySlot = false
        playSlotError = nil

        shouldFailPauseSlot = false
        pauseSlotError = nil

        activeOperations = []
        completedOperations = []
    }

    // MARK: - Verification Helpers

    /// Verify song was loaded into specific slot
    public func didLoadSong(into slot: Int) -> Bool {
        return loadedSongs.contains { $0.slot == slot }
    }

    /// Verify specific slot was played
    public func didPlaySlot(_ slot: Int) -> Bool {
        return playedSlots.contains(slot)
    }

    /// Verify specific slot was paused
    public func didPauseSlot(_ slot: Int) -> Bool {
        return pausedSlots.contains(slot)
    }

    /// Get latest tempo for slot
    public func tempoForSlot(_ slot: Int) -> Double? {
        tempoChanges.reversed().first { $0.slot == slot }?.tempo
    }

    /// Get latest volume for slot
    public func volumeForSlot(_ slot: Int) -> Double? {
        volumeChanges.reversed().first { $0.slot == slot }?.volume
    }

    /// Get latest mute state for slot
    public func muteStateForSlot(_ slot: Int) -> Bool? {
        muteChanges.reversed().first { $0.slot == slot }?.muted
    }

    /// Get latest solo state for slot
    public func soloStateForSlot(_ slot: Int) -> Bool? {
        soloChanges.reversed().first { $0.slot == slot }?.soloed
    }
}

// =============================================================================
// MARK: - Mock Engine Error
// =============================================================================

public enum MockEngineError: Error {
    case loadFailed
    case playFailed
    case pauseFailed
    case stopFailed
    case tempoChangeFailed
    case volumeChangeFailed
    case muteFailed
    case soloFailed
    case seekFailed
}

// =============================================================================
// MARK: - Engine Test Extensions
// =============================================================================

public extension XCTestCase {

    /// Assert song was loaded into slot
    func assertSongLoaded(
        _ mock: MockMultiSongEngine,
        into slot: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            mock.didLoadSong(into: slot),
            "Expected song to be loaded into slot \(slot), but it was not",
            file: file,
            line: line
        )
    }

    /// Assert slot was played
    func assertSlotPlayed(
        _ mock: MockMultiSongEngine,
        _ slot: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            mock.didPlaySlot(slot),
            "Expected slot \(slot) to be played, but it was not",
            file: file,
            line: line
        )
    }

    /// Assert slot was paused
    func assertSlotPaused(
        _ mock: MockMultiSongEngine,
        _ slot: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            mock.didPauseSlot(slot),
            "Expected slot \(slot) to be paused, but it was not",
            file: file,
            line: line
        )
    }

    /// Assert stop all was called
    func assertStopAllCalled(
        _ mock: MockMultiSongEngine,
        times: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.stopAllCallCount,
            times,
            "Expected stopAll to be called \(times) times, but was called \(mock.stopAllCallCount) times",
            file: file,
            line: line
        )
    }

    /// Assert tempo was set for slot
    func assertTempoSet(
        _ mock: MockMultiSongEngine,
        slot: Int,
        to tempo: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let actualTempo = mock.tempoForSlot(slot) else {
            XCTFail("Expected tempo to be set for slot \(slot), but it was not", file: file, line: line)
            return
        }

        XCTAssertEqual(
            actualTempo,
            tempo,
            accuracy: 0.01,
            "Expected tempo \(tempo) for slot \(slot), but found \(actualTempo)",
            file: file,
            line: line
        )
    }

    /// Assert volume was set for slot
    func assertVolumeSet(
        _ mock: MockMultiSongEngine,
        slot: Int,
        to volume: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let actualVolume = mock.volumeForSlot(slot) else {
            XCTFail("Expected volume to be set for slot \(slot), but it was not", file: file, line: line)
            return
        }

        XCTAssertEqual(
            actualVolume,
            volume,
            accuracy: 0.01,
            "Expected volume \(volume) for slot \(slot), but found \(actualVolume)",
            file: file,
            line: line
        )
    }

    /// Assert no operations are currently active
    func assertNoActiveOperations(
        _ mock: MockMultiSongEngine,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            mock.activeOperations.isEmpty,
            "Expected no active operations, but found: \(mock.activeOperations)",
            file: file,
            line: line
        )
    }

    /// Wait for all async operations to complete
    func waitForEngineOperations(
        _ mock: MockMultiSongEngine,
        timeout: TimeInterval = 1.0
    ) async {
        let startTime = Date()

        while !mock.activeOperations.isEmpty {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for operations to complete: \(mock.activeOperations)")
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
}
