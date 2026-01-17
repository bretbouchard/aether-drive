//
//  MultiSongStateTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Multi Song State Tests
// =============================================================================

class MultiSongStateTests: XCTestCase {

    var state: MultiSongState!

    override func setUp() {
        super.setUp()
        state = Fixtures.testMultiSongState
    }

    override func tearDown() {
        state = nil
        super.tearDown()
    }

    // MARK: - Song Management Tests

    func testAddSong_IncreasesSongCount() {
        // Given
        let initialCount = state.songs.count
        let newSong = Fixtures.testSong

        // When
        state.addSong(newSong)

        // Then
        XCTAssertEqual(state.songs.count, initialCount + 1)
    }

    func testAddSong_AddsToSongsArray() {
        // Given
        let newSong = Fixtures.testSong

        // When
        state.addSong(newSong)

        // Then
        XCTAssertTrue(state.songs.contains { $0.id == newSong.id })
    }

    func testRemoveSong_DecreasesSongCount() {
        // Given
        let songToRemove = state.songs.first!
        let initialCount = state.songs.count

        // When
        state.removeSong(id: songToRemove.id)

        // Then
        XCTAssertEqual(state.songs.count, initialCount - 1)
    }

    func testRemoveSong_RemovesCorrectSong() {
        // Given
        let songToRemove = state.songs.first!

        // When
        state.removeSong(id: songToRemove.id)

        // Then
        XCTAssertFalse(state.songs.contains { $0.id == songToRemove.id })
    }

    func testRemoveSong_WithNonExistentID_DoesNothing() {
        // Given
        let initialCount = state.songs.count
        let nonExistentID = "non-existent-id"

        // When
        state.removeSong(id: nonExistentID)

        // Then
        XCTAssertEqual(state.songs.count, initialCount)
    }

    func testGetSong_WithExistingID_ReturnsSong() {
        // Given
        let song = state.songs.first!

        // When
        let retrievedSong = state.getSong(id: song.id)

        // Then
        XCTAssertNotNil(retrievedSong)
        XCTAssertEqual(retrievedSong?.id, song.id)
    }

    func testGetSong_WithNonExistentID_ReturnsNil() {
        // Given
        let nonExistentID = "non-existent-id"

        // When
        let retrievedSong = state.getSong(id: nonExistentID)

        // Then
        XCTAssertNil(retrievedSong)
    }

    // MARK: - Transport Control Tests

    func testToggleMasterPlay_WhenPaused_StartsPlaying() {
        // Given
        state.isMasterPlaying = false

        // When
        state.toggleMasterPlay()

        // Then
        XCTAssertTrue(state.isMasterPlaying)
    }

    func testToggleMasterPlay_WhenPlaying_Pauses() {
        // Given
        state.isMasterPlaying = true

        // When
        state.toggleMasterPlay()

        // Then
        XCTAssertFalse(state.isMasterPlaying)
    }

    func testToggleMasterPlay_StartsNonMutedSongs() {
        // Given
        state.isMasterPlaying = false
        state.songs.forEach { $0.isPlaying = false }
        state.songs[0].isMuted = true

        // When
        state.toggleMasterPlay()

        // Then
        // Non-muted songs should be playing
        let playingNonMutedSongs = state.songs.filter { !$0.isMuted && $0.isPlaying }
        XCTAssertFalse(playingNonMutedSongs.isEmpty)
    }

    func testToggleMasterPlay_DoesNotStartMutedSongs() {
        // Given
        state.isMasterPlaying = false
        state.songs[0].isMuted = true

        // When
        state.toggleMasterPlay()

        // Then
        XCTAssertFalse(state.songs[0].isPlaying)
    }

    func testStopAll_StopsMasterPlaying() {
        // Given
        state.isMasterPlaying = true
        state.songs.forEach { $0.isPlaying = true }

        // When
        state.stopAll()

        // Then
        XCTAssertFalse(state.isMasterPlaying)
    }

    func testStopAll_StopsAllSongs() {
        // Given
        state.songs.forEach { song in
            song.isPlaying = true
            song.progress = Double.random(in: 0.2...0.8)
        }

        // When
        state.stopAll()

        // Then
        state.songs.forEach { song in
            XCTAssertFalse(song.isPlaying)
            XCTAssertEqual(song.progress, 0.0)
        }
    }

    func testStopAll_ResetsAllProgressToZero() {
        // Given
        state.songs.forEach { song in
            song.progress = Double.random(in: 0.2...0.8)
        }

        // When
        state.stopAll()

        // Then
        state.songs.forEach { song in
            XCTAssertEqual(song.progress, 0.0)
        }
    }

    // MARK: - Sync Mode Tests

    func testSyncMode_Independent_HasCorrectIcon() {
        // Given
        state.syncMode = .independent

        // Then
        XCTAssertEqual(state.syncMode.icon, "arrow.triangle.2.circlepath")
    }

    func testSyncMode_Locked_HasCorrectIcon() {
        // Given
        state.syncMode = .locked

        // Then
        XCTAssertEqual(state.syncMode.icon, "lock.fill")
    }

    func testSyncMode_Ratio_HasCorrectIcon() {
        // Given
        state.syncMode = .ratio

        // Then
        XCTAssertEqual(state.syncMode.icon, "percent")
    }

    func testSyncMode_HasThreeCases() {
        // Then
        XCTAssertEqual(MultiSongState.SyncMode.allCases.count, 3)
    }

    // MARK: - Master Tempo Tests

    func testMasterTempo_InitialValue_IsOne() {
        // Then
        XCTAssertEqual(state.masterTempo, 1.0)
    }

    func testMasterTempo_CanBeChanged() {
        // Given
        state.masterTempo = 1.5

        // Then
        XCTAssertEqual(state.masterTempo, 1.5)
    }

    func testMasterTempo_Minimum_IsPointFive() {
        // When
        state.masterTempo = 0.5

        // Then
        XCTAssertEqual(state.masterTempo, 0.5)
    }

    func testMasterTempo_Maximum_IsTwo() {
        // When
        state.masterTempo = 2.0

        // Then
        XCTAssertEqual(state.masterTempo, 2.0)
    }

    // MARK: - Master Volume Tests

    func testMasterVolume_InitialValue_IsPointEight() {
        // Then
        XCTAssertEqual(state.masterVolume, 0.8)
    }

    func testMasterVolume_CanBeChanged() {
        // Given
        state.masterVolume = 0.6

        // Then
        XCTAssertEqual(state.masterVolume, 0.6)
    }

    func testMasterVolume_Minimum_IsZero() {
        // When
        state.masterVolume = 0.0

        // Then
        XCTAssertEqual(state.masterVolume, 0.0)
    }

    func testMasterVolume_Maximum_IsOne() {
        // When
        state.masterVolume = 1.0

        // Then
        XCTAssertEqual(state.masterVolume, 1.0)
    }

    // MARK: - Master Transport State Tests

    func testMasterTransport_InitialProgress_IsZero() {
        // Then
        XCTAssertEqual(state.masterTransport.progress, 0.0)
    }

    func testMasterTransport_InitialLooping_IsFalse() {
        // Then
        XCTAssertFalse(state.masterTransport.isLooping)
    }

    func testMasterTransport_InitialLoopStart_IsZero() {
        // Then
        XCTAssertEqual(state.masterTransport.loopStart, 0.0)
    }

    func testMasterTransport_InitialLoopEnd_IsOne() {
        // Then
        XCTAssertEqual(state.masterTransport.loopEnd, 1.0)
    }

    func testMasterTransport_CanBeModified() {
        // Given
        state.masterTransport.progress = 0.5
        state.masterTransport.isLooping = true
        state.masterTransport.loopStart = 0.2
        state.masterTransport.loopEnd = 0.8

        // Then
        XCTAssertEqual(state.masterTransport.progress, 0.5)
        XCTAssertTrue(state.masterTransport.isLooping)
        XCTAssertEqual(state.masterTransport.loopStart, 0.2)
        XCTAssertEqual(state.masterTransport.loopEnd, 0.8)
    }

    // MARK: - Edge Cases

    func testState_WithNoSongs_HandlesCorrectly() {
        // Given
        state.songs = []

        // When
        state.toggleMasterPlay()

        // Then
        XCTAssertFalse(state.isMasterPlaying)
    }

    func testState_WithAllMutedSongs_DoesNotPlayAny() {
        // Given
        state.songs.forEach { $0.isMuted = true }
        state.isMasterPlaying = false

        // When
        state.toggleMasterPlay()

        // Then
        state.songs.forEach { song in
            XCTAssertFalse(song.isPlaying)
        }
    }

    func testState_WithMultipleToggleOperations_MaintainsConsistency() {
        // Given
        state.isMasterPlaying = false

        // When
        state.toggleMasterPlay()
        state.toggleMasterPlay()
        state.toggleMasterPlay()

        // Then
        XCTAssertTrue(state.isMasterPlaying)
    }
}
