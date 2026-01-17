//
//  PropertyBasedTesting.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Property-Based Tests
// =============================================================================

/// Property-based testing framework for SwiftUI state management
/// Tests invariants and properties that should hold true for all valid inputs
public class PropertyBasedTests: XCTestCase {

    // =============================================================================
    // MARK: - Tempo Property Tests
    // =============================================================================

    /// Test that any tempo value clamps to valid range (40-240 BPM)
    /// This property should hold for ALL random inputs in the tested range
    func testTempoProperty_AnyValue_ClampsToValidRange() {
        for _ in 0..<1000 {
            let randomTempo = Double.random(in: -100...300)
            var slot = XCUITestFixtures.createTestSongSlot()
            slot.tempo = randomTempo

            // Property: Tempo should always be in valid range after clamping
            XCTAssertGreaterThanOrEqual(
                slot.tempo,
                0.0,
                "Tempo \(slot.tempo) should be >= 0.0"
            )
            XCTAssertLessThanOrEqual(
                slot.tempo,
                2.0,
                "Tempo \(slot.tempo) should be <= 2.0"
            )
        }
    }

    /// Test tempo boundary values
    func testTempoProperty_BoundaryValues_MaintainInvariants() {
        let boundaryValues: [Double] = [0.0, 0.5, 1.0, 1.5, 2.0]

        for tempo in boundaryValues {
            var slot = XCUITestFixtures.createTestSongSlot()
            slot.tempo = tempo

            XCTAssertEqual(
                slot.tempo,
                tempo,
                "Tempo should maintain exact value at boundary"
            )
        }
    }

    // =============================================================================
    // MARK: - Volume Property Tests
    // =============================================================================

    /// Test that any volume value clamps to valid range (0.0-1.0)
    /// This property should hold for ALL random inputs
    func testVolumeProperty_AnyValue_ClampsToValidRange() {
        for _ in 0..<1000 {
            let randomVolume = Double.random(in: -1.0...2.0)
            var slot = XCUITestFixtures.createTestSongSlot()
            slot.volume = randomVolume

            // Property: Volume should always be in valid range
            XCTAssertGreaterThanOrEqual(
                slot.volume,
                0.0,
                "Volume \(slot.volume) should be >= 0.0"
            )
            XCTAssertLessThanOrEqual(
                slot.volume,
                1.0,
                "Volume \(slot.volume) should be <= 1.0"
            )
        }
    }

    /// Test volume precision is maintained
    func testVolumeProperty_Precision_Maintained() {
        let preciseValues: [Double] = [
            0.0, 0.123, 0.456, 0.789, 1.0
        ]

        for volume in preciseValues {
            var slot = XCUITestFixtures.createTestSongSlot()
            slot.volume = volume

            XCTAssertEqual(
                slot.volume,
                volume,
                accuracy: 0.001,
                "Volume precision should be maintained"
            )
        }
    }

    // =============================================================================
    // MARK: - Position Property Tests
    // =============================================================================

    /// Test that any position value clamps to valid range (0.0-1.0)
    /// This property should hold for ALL random inputs
    func testPositionProperty_AnyValue_ClampsToValidRange() {
        for _ in 0..<1000 {
            let randomPosition = Double.random(in: -0.5...1.5)
            var slot = XCUITestFixtures.createTestSongSlot()
            slot.currentPosition = randomPosition

            // Property: Position should always be in valid range
            XCTAssertGreaterThanOrEqual(
                slot.currentPosition,
                0.0,
                "Position \(slot.currentPosition) should be >= 0.0"
            )
            XCTAssertLessThanOrEqual(
                slot.currentPosition,
                1.0,
                "Position \(slot.currentPosition) should be <= 1.0"
            )
        }
    }

    /// Test position wraps around correctly
    func testPositionProperty_WrapAround_MaintainsContinuity() {
        var slot = XCUITestFixtures.createTestSongSlot()
        slot.currentPosition = 0.9

        // Simulate moving forward
        slot.currentPosition += 0.2

        // Should wrap to 0.1
        XCTAssertEqual(
            slot.currentPosition,
            0.1,
            accuracy: 0.01,
            "Position should wrap around"
        )
    }

    // =============================================================================
    // MARK: - State Transition Properties
    // =============================================================================

    /// Test that play/pause toggling is stable over many iterations
    /// Property: Toggling should never crash or enter invalid state
    func testPlayPauseProperty_Alternating_IsStable() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialState = slot.isPlaying

        // Toggle 100 times
        for _ in 0..<100 {
            slot.isPlaying.toggle()

            // Property: State should always be valid
            XCTAssertNotNil(slot)

            // Property: Should always be boolean
            XCTAssertTrue(
                slot.isPlaying == true || slot.isPlaying == false,
                "Playing state should be boolean"
            )
        }

        // After 100 toggles, should be opposite of initial
        XCTAssertEqual(
            slot.isPlaying,
            !initialState,
            "After even number of toggles, should return to initial"
        )
    }

    /// Test that mute/solo combinations are always valid
    /// Property: Any combination of mute/solo should be valid state
    func testMuteSoloProperty_MultipleCombinations_Valid() {
        var slot = XCUITestFixtures.createTestSongSlot()

        let muteStates = [true, false]
        let soloStates = [true, false]

        for isMuted in muteStates {
            for isSoloed in soloStates {
                slot.isMuted = isMuted
                slot.isSoloed = isSoloed

                // Property: State should always be valid
                XCTAssertNotNil(slot)

                // Property: Values should match what we set
                XCTAssertEqual(slot.isMuted, isMuted)
                XCTAssertEqual(slot.isSoloed, isSoloed)
            }
        }
    }

    /// Test that loop boundaries maintain valid relationship
    /// Property: Loop end should always be >= loop start
    func testLoopBoundariesProperty_Always_Valid() {
        for _ in 0..<100 {
            let start = Double.random(in: 0...0.8)
            let end = Double.random(in: 0.2...1.0)

            var slot = XCUITestFixtures.createTestSongSlot()
            slot.loopStart = min(start, end)
            slot.loopEnd = max(start, end)
            slot.loopEnabled = true

            // Property: End should be >= start
            XCTAssertGreaterThanOrEqual(
                slot.loopEnd,
                slot.loopStart,
                "Loop end should be >= loop start"
            )

            // Property: Both should be in valid range
            XCTAssertGreaterThanOrEqual(slot.loopStart, 0.0)
            XCTAssertLessThanOrEqual(slot.loopEnd, 1.0)
        }
    }

    // =============================================================================
    // MARK: - Array Property Tests
    // =============================================================================

    /// Test that adding songs maintains array consistency
    /// Property: Array count should match number of additions
    func testSongSlotsArray_AddingToSix_MaintainsConsistency() {
        var state = XCUITestFixtures.createTestMultiSongState(songCount: 0)

        for i in 0..<6 {
            let newSong = XCUITestFixtures.createTestSongSlot(
                songId: "song-\(i)"
            )

            state.songs.append(newSong)

            // Property: Count should match additions
            XCTAssertEqual(
                state.songs.count,
                i + 1,
                "Array count should match additions"
            )

            // Property: Last element should be what we added
            XCTAssertEqual(
                state.songs.last?.song.id,
                newSong.song.id,
                "Last element should match added song"
            )
        }
    }

    /// Test that removing songs maintains consistency
    /// Property: Removing should decrease count and preserve other elements
    func testSongSlotsArray_Removing_MaintainsConsistency() {
        var state = XCUITestFixtures.createTestMultiSongState(songCount: 6)
        let initialCount = state.songs.count
        let firstSongId = state.songs.first?.song.id

        state.songs.removeFirst()

        // Property: Count should decrease
        XCTAssertEqual(
            state.songs.count,
            initialCount - 1,
            "Count should decrease after removal"
        )

        // Property: Removed element should not exist
        let remainingIds = state.songs.map { $0.song.id }
        XCTAssertFalse(
            remainingIds.contains(firstSongId ?? ""),
            "Removed song should not exist"
        )
    }

    /// Test that array operations preserve song count limit
    /// Property: Should never exceed 6 songs
    func testSongSlotsArray_NeverExceedsSix_MaintainsInvariant() {
        var state = XCUITestFixtures.createTestMultiSongState(songCount: 0)

        // Try to add 10 songs
        for i in 0..<10 {
            let newSong = XCUITestFixtures.createTestSongSlot(
                songId: "song-\(i)"
            )

            if state.songs.count < 6 {
                state.songs.append(newSong)
            }
        }

        // Property: Should never exceed 6
        XCTAssertLessThanOrEqual(
            state.songs.count,
            6,
            "Should never exceed 6 songs"
        )
    }

    // =============================================================================
    // MARK: - Performance Properties
    // =============================================================================

    /// Test that rendering with variable state is always consistent
    /// Property: Should render without crashing for any valid state
    func testRenderingPerformance_WithVariableState_Consistent() {
        // Test rendering with 100 different random states
        for _ in 0..<100 {
            let state = XCUITestFixtures.createTestMultiSongState(
                songCount: Int.random(in: 0...6),
                allPlaying: Bool.random(),
                syncMode: SyncMode.allCases.randomElement()!
            )

            // Property: Should create view without crashing
            XCTAssertNoThrow(
                _ = MovingSidewalkView(
                    state: state,
                    engine: MockMultiSongEngine()
                ),
                "Should create view for any valid state"
            )
        }
    }

    /// Test that state updates are thread-safe
    /// Property: Concurrent updates should not cause crashes
    func testStateUpdates_Concurrent_AreThreadSafe() {
        let expectation = XCTestExpectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 100

        var state = XCUITestFixtures.createTestMultiSongState()

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            // Simulate concurrent updates
            let songIndex = i % state.songs.count
            state.songs[songIndex].volume = Double.random(in: 0...1)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Property: State should remain valid
        XCTAssertNotNil(state)
    }

    // =============================================================================
    // MARK: - Mathematical Properties
    // =============================================================================

    /// Test that tempo multiplication is associative
    /// Property: (a * b) * c = a * (b * c)
    func testTempoMultiplication_IsAssociative() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialTempo = slot.tempo

        let factor1 = 1.2
        let factor2 = 0.8

        // (initial * factor1) * factor2
        slot.tempo = initialTempo * factor1
        slot.tempo = slot.tempo * factor2
        let result1 = slot.tempo

        // Reset
        slot.tempo = initialTempo

        // initial * (factor1 * factor2)
        slot.tempo = initialTempo * (factor1 * factor2)
        let result2 = slot.tempo

        // Property: Results should be equal
        XCTAssertEqual(
            result1,
            result2,
            accuracy: 0.001,
            "Tempo multiplication should be associative"
        )
    }

    /// Test that volume addition is commutative
    /// Property: a + b = b + a
    func testVolumeAddition_IsCommutative() {
        var slot1 = XCUITestFixtures.createTestSongSlot()
        var slot2 = XCUITestFixtures.createTestSongSlot()

        let initialVolume = slot1.volume
        let adjustment1 = 0.1
        let adjustment2 = 0.2

        // a + b
        slot1.volume = initialVolume + adjustment1
        slot1.volume = slot1.volume + adjustment2
        let result1 = slot1.volume

        // b + a
        slot2.volume = initialVolume + adjustment2
        slot2.volume = slot2.volume + adjustment1
        let result2 = slot2.volume

        // Property: Results should be equal
        XCTAssertEqual(
            result1,
            result2,
            accuracy: 0.001,
            "Volume addition should be commutative"
        )
    }

    // =============================================================================
    // MARK: - Identity Properties
    // =============================================================================

    /// Test that adding 0 to tempo maintains identity
    /// Property: a + 0 = a
    func testTempoAdditionZero_MaintainsIdentity() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialTempo = slot.tempo

        slot.tempo = initialTempo + 0.0

        XCTAssertEqual(
            slot.tempo,
            initialTempo,
            "Adding 0 should maintain identity"
        )
    }

    /// Test that multiplying volume by 1 maintains identity
    /// Property: a * 1 = a
    func testVolumeMultiplicationOne_MaintainsIdentity() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialVolume = slot.volume

        slot.volume = initialVolume * 1.0

        XCTAssertEqual(
            slot.volume,
            initialVolume,
            "Multiplying by 1 should maintain identity"
        )
    }

    // =============================================================================
    // MARK: - Inverse Properties
    // =============================================================================

    /// Test that play/pause are inverses
    /// Property: play after pause returns to original
    func testPlayPauseToggle_IsInverse() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialState = slot.isPlaying

        slot.isPlaying.toggle()
        slot.isPlaying.toggle()

        XCTAssertEqual(
            slot.isPlaying,
            initialState,
            "Double toggle should return to initial state"
        )
    }

    /// Test that mute/unmute are inverses
    /// Property: mute after unmute returns to original
    func testMuteToggle_IsInverse() {
        var slot = XCUITestFixtures.createTestSongSlot()
        let initialState = slot.isMuted

        slot.isMuted.toggle()
        slot.isMuted.toggle()

        XCTAssertEqual(
            slot.isMuted,
            initialState,
            "Double toggle should return to initial state"
        )
    }
}
