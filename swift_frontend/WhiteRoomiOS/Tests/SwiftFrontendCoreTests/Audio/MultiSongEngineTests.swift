//
//  MultiSongEngineTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Multi-Song Engine Tests
// =============================================================================

@MainActor
final class MultiSongEngineTests: XCTestCase {

    var engine: MultiSongEngine!
    var testSongs: [Song]!

    override func setUp() async throws {
        try await super.setUp()

        engine = MultiSongEngine()
        testSongs = createTestSongs(count: 6)

        // Start audio engine for tests
        try engine.startAudioEngine()
    }

    override func tearDown() async throws {
        engine.stopAudioEngine()
        engine = nil
        testSongs = nil

        try await super.tearDown()
    }

    // =============================================================================
    // MARK: - Test Song Loading
    // =============================================================================

    func testMultipleSongLoading() async throws {
        // Given: 6 test songs
        XCTAssertEqual(testSongs.count, 6, "Should have 6 test songs")

        // When: Loading all songs
        var loadedStates: [SongPlayerState] = []
        for song in testSongs {
            let state = engine.addSong(song)
            loadedStates.append(state)
        }

        // Then: All songs should be loaded
        XCTAssertEqual(engine.state.songs.count, 6, "Should have 6 loaded songs")
        XCTAssertEqual(engine.statistics.activeSongCount, 6, "Statistics should report 6 active songs")

        // And: Each song should have unique ID
        let uniqueIds = Set(loadedStates.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 6, "Each song should have unique ID")
    }

    func testSongRemoval() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        let initialCount = engine.state.songs.count
        XCTAssertEqual(initialCount, 3)

        // When: Removing one song
        let songToRemove = engine.state.songs[0]
        engine.removeSong(playerId: songToRemove.id)

        // Then: Should have 2 songs
        XCTAssertEqual(engine.state.songs.count, 2, "Should have 2 songs after removal")

        // And: Statistics should update
        XCTAssertEqual(engine.statistics.activeSongCount, 2)
    }

    func testRemoveAllSongs() async throws {
        // Given: Multiple loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        XCTAssertGreaterThan(engine.state.songs.count, 0)

        // When: Removing all songs
        engine.removeAllSongs()

        // Then: Should have no songs
        XCTAssertEqual(engine.state.songs.count, 0, "Should have no songs")
        XCTAssertFalse(engine.state.masterPlaying, "Master should not be playing")
    }

    // =============================================================================
    // MARK: - Test Simultaneous Playback
    // =============================================================================

    func testSimultaneousPlayback() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        XCTAssertFalse(engine.state.masterPlaying, "Should start stopped")

        // When: Starting master playback
        engine.toggleMasterPlayback()

        // Then: All songs should be playing
        XCTAssertTrue(engine.state.masterPlaying, "Master should be playing")

        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying, "Song \(song.songName) should be playing")
        }

        // When: Stopping master playback
        engine.toggleMasterPlayback()

        // Then: All songs should be stopped
        XCTAssertFalse(engine.state.masterPlaying, "Master should be stopped")

        for song in engine.state.songs {
            XCTAssertFalse(song.isPlaying, "Song \(song.songName) should be stopped")
        }
    }

    func testIndividualSongPlayback() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        let targetSong = engine.state.songs[0]

        // When: Toggling individual song playback
        engine.toggleSongPlayback(playerId: targetSong.id)

        // Then: Only that song should be playing
        XCTAssertTrue(targetSong.isPlaying, "Target song should be playing")
        XCTAssertFalse(engine.state.masterPlaying, "Master should still be stopped")

        // Other songs should not be playing
        for song in engine.state.songs where song.id != targetSong.id {
            XCTAssertFalse(song.isPlaying, "Other songs should not be playing")
        }
    }

    func testEmergencyStop() async throws {
        // Given: Multiple songs playing
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()
        XCTAssertTrue(engine.state.masterPlaying)

        // When: Emergency stop
        engine.emergencyStop()

        // Then: Everything should stop
        XCTAssertFalse(engine.state.masterPlaying, "Master should be stopped")

        for song in engine.state.songs {
            XCTAssertFalse(song.isPlaying, "Song \(song.songName) should be stopped")
            XCTAssertEqual(song.currentPosition, 0.0, "Position should reset to 0")
        }
    }

    // =============================================================================
    // MARK: - Test Independent Tempo Control
    // =============================================================================

    func testIndependentTempoControl() async throws {
        // Given: 3 songs with independent sync mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        // When: Setting individual tempos
        let song1 = engine.state.songs[0]
        let song2 = engine.state.songs[1]
        let song3 = engine.state.songs[2]

        engine.setTempo(playerId: song1.id, tempo: 0.75)
        engine.setTempo(playerId: song2.id, tempo: 1.25)
        engine.setTempo(playerId: song3.id, tempo: 1.5)

        // Then: Each song should have its own tempo
        XCTAssertEqual(engine.state.songs[0].tempo, 0.75, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.25, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, 1.5, accuracy: 0.01)
    }

    func testTempoClamping() async throws {
        // Given: A loaded song
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        // When: Setting tempo below minimum
        engine.setTempo(playerId: song.id, tempo: 0.2)

        // Then: Should clamp to minimum
        XCTAssertEqual(engine.state.songs[0].tempo, 0.5, accuracy: 0.01)

        // When: Setting tempo above maximum
        engine.setTempo(playerId: song.id, tempo: 3.0)

        // Then: Should clamp to maximum
        XCTAssertEqual(engine.state.songs[0].tempo, 2.0, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Test Master Transport
    // =============================================================================

    func testMasterTransportControls() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        // When: Using master play/pause
        engine.toggleMasterPlayback()
        XCTAssertTrue(engine.state.masterPlaying)

        engine.toggleMasterPlayback()
        XCTAssertFalse(engine.state.masterPlaying)

        // When: Using emergency stop
        engine.toggleMasterPlayback()
        engine.emergencyStop()

        XCTAssertFalse(engine.state.masterPlaying)
        XCTAssertEqual(engine.state.songs[0].currentPosition, 0.0)
    }

    func testMasterTempoControl() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)

        // When: Setting master tempo
        engine.setMasterTempo(1.5)

        // Then: Master tempo should update
        XCTAssertEqual(engine.state.masterTempo, 1.5, accuracy: 0.01)

        // And: All songs should sync to master tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01, "Song \(song.songName) should sync to master")
        }
    }

    func testMasterVolumeControl() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        // When: Setting master volume
        engine.setMasterVolume(0.5)

        // Then: Master volume should update
        XCTAssertEqual(engine.state.masterVolume, 0.5, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Test Sync Modes
    // =============================================================================

    func testIndependentSyncMode() async throws {
        // Given: 3 songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        // When: Setting individual tempos
        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.8)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.2)

        // Then: Songs should maintain independent tempos
        XCTAssertEqual(engine.state.songs[0].tempo, 0.8, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.2, accuracy: 0.01)
    }

    func testLockedSyncMode() async throws {
        // Given: 3 songs with different initial tempos
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)

        // When: Setting master tempo
        engine.setMasterTempo(1.3)

        // Then: All songs should lock to master tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.3, accuracy: 0.01, "Locked mode: all songs should match master tempo")
        }
    }

    func testRatioSyncMode() async throws {
        // Given: 3 songs with original tempo ratios
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        // Set original ratios
        engine.state.songs[0].originalTempoRatio = 0.75
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 1.25

        engine.setSyncMode(.ratio)

        // When: Setting master tempo
        engine.setMasterTempo(1.5)

        // Then: Songs should maintain ratios
        XCTAssertEqual(engine.state.songs[0].tempo, 1.5 * 0.75, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.5 * 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, 1.5 * 1.25, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Test Audio Mixing
    // ==============================================================================

    func testVolumeControl() async throws {
        // Given: A loaded song
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        // When: Setting volume
        engine.setVolume(playerId: song.id, volume: 0.6)

        // Then: Volume should update
        XCTAssertEqual(engine.state.songs[0].volume, 0.6, accuracy: 0.01)
    }

    func testMuteToggle() async throws {
        // Given: A loaded song
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        XCTAssertFalse(song.isMuted, "Should start unmuted")

        // When: Toggling mute
        engine.toggleMute(playerId: song.id)

        // Then: Should be muted
        XCTAssertTrue(engine.state.songs[0].isMuted, "Should be muted")

        // When: Toggling again
        engine.toggleMute(playerId: song.id)

        // Then: Should be unmuted
        XCTAssertFalse(engine.state.songs[0].isMuted, "Should be unmuted")
    }

    func testSoloToggle() async throws {
        // Given: 3 loaded songs
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        let song1 = engine.state.songs[0]
        let song2 = engine.state.songs[1]

        // When: Soloing song1
        engine.toggleSolo(playerId: song1.id)

        // Then: Song1 should be soloed
        XCTAssertTrue(engine.state.songs[0].isSoloed)

        // When: Soloing song2
        engine.toggleSolo(playerId: song2.id)

        // Then: Song1 should be unsoloed, song2 soloed
        XCTAssertFalse(engine.state.songs[0].isSoloed, "Only one song should be soloed")
        XCTAssertTrue(engine.state.songs[1].isSoloed)
    }

    // =============================================================================
    // MARK: - Test Loop Controls
    // =============================================================================

    func testLoopToggle() async throws {
        // Given: A loaded song
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        XCTAssertFalse(song.loopEnabled, "Should start without loop")

        // When: Toggling loop
        engine.toggleLoop(playerId: song.id)

        // Then: Loop should be enabled
        XCTAssertTrue(engine.state.songs[0].loopEnabled)
    }

    func testLoopPoints() async throws {
        // Given: A loaded song with duration 180s
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        // When: Setting loop points
        engine.setLoopPoints(playerId: song.id, start: 30.0, end: 120.0)

        // Then: Loop points should be set
        XCTAssertEqual(engine.state.songs[0].loopStart, 30.0, accuracy: 0.1)
        XCTAssertEqual(engine.state.songs[0].loopEnd, 120.0, accuracy: 0.1)
    }

    func testLoopPointsClamping() async throws {
        // Given: A loaded song
        engine.addSong(testSongs[0])
        let song = engine.state.songs[0]

        // When: Setting invalid loop points (end before start)
        engine.setLoopPoints(playerId: song.id, start: 100.0, end: 50.0)

        // Then: Should clamp end to be after start
        XCTAssertGreaterThanOrEqual(engine.state.songs[0].loopEnd, engine.state.songs[0].loopStart)
    }

    // =============================================================================
    // MARK: - Test Preset Management
    // =============================================================================

    func testPresetSave() async throws {
        // Given: 3 loaded songs with specific settings
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setMasterTempo(1.25)
        engine.setMasterVolume(0.7)
        engine.setSyncMode(.locked)

        // When: Saving preset
        let preset = engine.savePreset(named: "Test Preset")

        // Then: Preset should capture state
        XCTAssertEqual(preset.name, "Test Preset")
        XCTAssertEqual(preset.state.masterTempo, 1.25, accuracy: 0.01)
        XCTAssertEqual(preset.state.masterVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(preset.state.syncMode, .locked)
        XCTAssertEqual(preset.state.songs.count, 3)
    }

    func testPresetLoad() async throws {
        // Given: A saved preset
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setMasterTempo(1.5)
        engine.setSyncMode(.ratio)

        let preset = engine.savePreset(named: "Load Test")

        // When: Modifying state and loading preset
        engine.setMasterTempo(1.0)
        engine.setSyncMode(.independent)

        engine.loadPreset(preset)

        // Then: State should be restored
        XCTAssertEqual(engine.state.masterTempo, 1.5, accuracy: 0.01)
        XCTAssertEqual(engine.state.syncMode, .ratio)
    }

    // =============================================================================
    // MARK: - Test Statistics
    // =============================================================================

    func testStatisticsUpdate() async throws {
        // Given: Engine with no songs
        XCTAssertEqual(engine.statistics.activeSongCount, 0)

        // When: Adding songs
        for song in testSongs.prefix(4) {
            engine.addSong(song)
        }

        // Then: Statistics should update
        XCTAssertEqual(engine.statistics.activeSongCount, 4)

        // And: Memory usage should increase
        XCTAssertGreaterThan(engine.statistics.memoryUsage, 0)
    }

    // =============================================================================
    // MARK: - Memory Leak Tests
    // =============================================================================

    func testNoMemoryLeakWhenAddingRemovingSongs() async throws {
        // Given: Engine
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let testEngine = MultiSongEngine()

            // When: Adding and removing many songs
            for _ in 0..<10 {
                for song in testSongs {
                    testEngine.addSong(song)
                }
                testEngine.removeAllSongs()
            }

            weakEngine = testEngine
        }

        // Then: Engine should be deallocated
        XCTAssertNil(weakEngine, "Engine should be deallocated")
    }

    // =============================================================================
    // MARK: - Performance Tests
    // =============================================================================

    func testPerformanceWith6Songs() async throws {
        // Given: Engine
        measure {
            // When: Loading 6 songs
            for song in testSongs {
                engine.addSong(song)
            }

            // And: Starting playback
            engine.toggleMasterPlayback()

            // And: Adjusting controls
            for song in engine.state.songs {
                engine.setTempo(playerId: song.id, tempo: 1.2)
                engine.setVolume(playerId: song.id, volume: 0.8)
            }
        }
    }

    func testPerformanceMasterTempoChange() async throws {
        // Given: 6 loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)

        measure {
            // When: Changing master tempo multiple times
            for tempo in stride(from: 0.5, through: 2.0, by: 0.1) {
                engine.setMasterTempo(tempo)
            }
        }
    }

    // =============================================================================
    // MARK: - Test Helpers
    // =============================================================================

    private func createTestSongs(count: Int) -> [Song] {
        var songs: [Song] = []

        for i in 0..<count {
            let song = Song(
                id: "test-song-\(i)",
                name: "Test Song \(i)",
                version: "1.0",
                metadata: SongMetadata(
                    tempo: 120.0,
                    timeSignature: [4, 4],
                    duration: 180.0
                ),
                sections: [],
                roles: [],
                projections: [],
                mixGraph: MixGraph(
                    tracks: [],
                    buses: [],
                    sends: [],
                    master: MixMasterConfig(volume: 0.8)
                ),
                realizationPolicy: RealizationPolicy(
                    windowSize: MusicalTime(beats: 4),
                    lookaheadDuration: MusicalTime(seconds: 1.0),
                    determinismMode: .seeded
                ),
                determinismSeed: "test-seed-\(i)",
                createdAt: Date(),
                updatedAt: Date()
            )

            songs.append(song)
        }

        return songs
    }
}
