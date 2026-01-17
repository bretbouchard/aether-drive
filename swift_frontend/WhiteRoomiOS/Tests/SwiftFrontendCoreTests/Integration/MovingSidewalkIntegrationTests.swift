//
//  MovingSidewalkIntegrationTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Moving Sidewalk Integration Tests
// =============================================================================

/**
 End-to-end integration tests for the Moving Sidewalk multi-song playback system.

 These tests verify the entire system works correctly from engine coordination
 through state management to UI updates.
 */
@MainActor
final class MovingSidewalkIntegrationTests: XCTestCase {

    var engine: MultiSongEngine!
    var testSongs: [Song]!

    override func setUp() async throws {
        try await super.setUp()

        engine = MultiSongEngine()
        testSongs = createTestSongs(count: 6)

        try engine.startAudioEngine()
    }

    override func tearDown() async throws {
        engine.stopAudioEngine()
        engine = nil
        testSongs = nil

        try await super.tearDown()
    }

    // =============================================================================
    // MARK: - End-to-End Workflow Tests
    // =============================================================================

    func testCompleteWorkflow_LoadPlayAdjust() async throws {
        // Given: 6 songs to load

        // When: Loading all songs
        var loadedSongs: [SongPlayerState] = []
        for song in testSongs {
            let state = engine.addSong(song)
            loadedSongs.append(state)
        }

        // Then: All songs should be loaded
        XCTAssertEqual(engine.state.songs.count, 6)

        // When: Starting playback
        engine.toggleMasterPlayback()

        // Then: All songs should be playing
        XCTAssertTrue(engine.state.masterPlaying)
        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying)
        }

        // When: Adjusting individual controls
        for (index, song) in engine.state.songs.enumerated() {
            engine.setTempo(playerId: song.id, tempo: 1.0 + Double(index) * 0.1)
            engine.setVolume(playerId: song.id, volume: 0.8 - Double(index) * 0.05)
        }

        // Then: Changes should be applied
        for (index, song) in engine.state.songs.enumerated() {
            XCTAssertEqual(song.tempo, 1.0 + Double(index) * 0.1, accuracy: 0.01)
            XCTAssertEqual(song.volume, 0.8 - Double(index) * 0.05, accuracy: 0.01)
        }

        // When: Stopping playback
        engine.toggleMasterPlayback()

        // Then: All songs should stop
        XCTAssertFalse(engine.state.masterPlaying)
        for song in engine.state.songs {
            XCTAssertFalse(song.isPlaying)
        }
    }

    func testCompleteWorkflow_MasterControls() async throws {
        // Given: 6 loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        // When: Using master transport
        engine.toggleMasterPlayback()
        XCTAssertTrue(engine.state.masterPlaying)

        // When: Adjusting master tempo
        engine.setMasterTempo(1.5)
        XCTAssertEqual(engine.state.masterTempo, 1.5, accuracy: 0.01)

        // When: Adjusting master volume
        engine.setMasterVolume(0.6)
        XCTAssertEqual(engine.state.masterVolume, 0.6, accuracy: 0.01)

        // When: Changing sync mode
        engine.setSyncMode(.locked)
        XCTAssertEqual(engine.state.syncMode, .locked)

        // Then: All songs should sync to master
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01)
        }

        // When: Emergency stop
        engine.emergencyStop()

        // Then: Everything should stop
        XCTAssertFalse(engine.state.masterPlaying)
        XCTAssertEqual(engine.state.songs[0].currentPosition, 0.0)
    }

    func testCompleteWorkflow_PresetSaveLoad() async throws {
        // Given: 6 loaded songs with specific settings
        for song in testSongs {
            engine.addSong(song)
        }

        engine.setMasterTempo(1.3)
        engine.setMasterVolume(0.7)
        engine.setSyncMode(.ratio)

        // Set individual song settings
        for (index, song) in engine.state.songs.enumerated() {
            engine.setTempo(playerId: song.id, tempo: 0.8 + Double(index) * 0.1)
            engine.setVolume(playerId: song.id, volume: 0.9 - Double(index) * 0.05)
        }

        // When: Saving preset
        let preset = engine.savePreset(named: "Integration Test Preset")

        // Then: Preset should capture all settings
        XCTAssertEqual(preset.name, "Integration Test Preset")
        XCTAssertEqual(preset.state.masterTempo, 1.3, accuracy: 0.01)
        XCTAssertEqual(preset.state.masterVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(preset.state.syncMode, .ratio)
        XCTAssertEqual(preset.state.songs.count, 6)

        // When: Clearing and loading preset
        engine.removeAllSongs()
        XCTAssertEqual(engine.state.songs.count, 0)

        engine.loadPreset(preset)

        // Then: State should be restored
        XCTAssertEqual(engine.state.masterTempo, 1.3, accuracy: 0.01)
        XCTAssertEqual(engine.state.masterVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(engine.state.syncMode, .ratio)
        XCTAssertEqual(engine.state.songs.count, 6)
    }

    // =============================================================================
    // MARK: - Multi-Song Playback Tests
    // =============================================================================

    func testSixSongsSimultaneousPlayback() async throws {
        // Given: 6 songs
        for song in testSongs {
            engine.addSong(song)
        }

        // When: Starting all songs
        engine.toggleMasterPlayback()

        // Then: All should play
        XCTAssertTrue(engine.state.masterPlaying)
        XCTAssertEqual(engine.state.songs.count, 6)

        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying, "Song \(song.songName) should be playing")
        }

        // When: Playing for 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then: Still playing
        XCTAssertTrue(engine.state.masterPlaying)
    }

    func testIndividualSongControlInMultiSongContext() async throws {
        // Given: 6 songs all playing
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // When: Stopping one song
        let targetSong = engine.state.songs[0]
        engine.toggleSongPlayback(playerId: targetSong.id)

        // Then: Only that song should stop
        XCTAssertFalse(targetSong.isPlaying)

        for song in engine.state.songs where song.id != targetSong.id {
            XCTAssertTrue(song.isPlaying, "Other songs should still be playing")
        }

        // When: Starting that song again
        engine.toggleSongPlayback(playerId: targetSong.id)

        // Then: All songs should be playing
        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying)
        }
    }

    // =============================================================================
    // MARK: - Sync Mode Integration Tests
    // =============================================================================

    func testSyncModeTransitionDuringPlayback() async throws {
        // Given: 6 songs playing
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // Set different tempos in independent mode
        for (index, song) in engine.state.songs.enumerated() {
            engine.setTempo(playerId: song.id, tempo: 0.8 + Double(index) * 0.1)
        }

        let initialTempos = engine.state.songs.map { $0.tempo }

        // When: Switching to locked mode
        engine.setSyncMode(.locked)

        // Then: All songs should sync to master tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, engine.state.masterTempo, accuracy: 0.01)
        }

        // When: Switching back to independent
        engine.setSyncMode(.independent)

        // Then: Each song should maintain current tempo (now master tempo)
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, engine.state.masterTempo, accuracy: 0.01)
        }
    }

    func testRatioModeIntegration() async throws {
        // Given: 6 songs
        for song in testSongs {
            engine.addSong(song)
        }

        // Set original ratios
        for (index, _) in engine.state.songs.enumerated() {
            engine.state.songs[index].originalTempoRatio = 0.5 + Double(index) * 0.2
        }

        engine.setSyncMode(.ratio)

        // When: Changing master tempo
        engine.setMasterTempo(1.5)

        // Then: All songs should scale by ratio
        for (index, song) in engine.state.songs.enumerated() {
            let expectedTempo = min(1.5 * (0.5 + Double(index) * 0.2), 2.0)
            XCTAssertEqual(song.tempo, expectedTempo, accuracy: 0.01)
        }
    }

    // =============================================================================
    // MARK: - Performance Tests (6+ Songs)
    // =============================================================================

    func testPerformanceWith6Songs() async throws {
        // Given: Engine
        measure {
            // When: Loading and playing 6 songs
            for song in testSongs {
                engine.addSong(song)
            }

            engine.toggleMasterPlayback()

            // And: Making various adjustments
            for song in engine.state.songs {
                engine.setTempo(playerId: song.id, tempo: 1.2)
                engine.setVolume(playerId: song.id, volume: 0.8)
            }

            engine.setMasterTempo(1.5)
            engine.setMasterVolume(0.7)
        }
    }

    func testPerformanceWith12Songs() async throws {
        // Given: 12 test songs
        let extendedSongs = createTestSongs(count: 12)

        measure {
            // When: Loading 12 songs
            for song in extendedSongs {
                engine.addSong(song)
            }

            // Then: Should handle 12 songs
            XCTAssertEqual(engine.state.songs.count, 12)

            // When: Starting playback
            engine.toggleMasterPlayback()

            // Then: All should be playing
            XCTAssertTrue(engine.state.masterPlaying)

            for song in engine.state.songs {
                XCTAssertTrue(song.isPlaying)
            }
        }
    }

    func testCPUUsageWith6Songs() async throws {
        // Given: 6 loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // When: Checking statistics
        let stats = engine.statistics

        // Then: CPU usage should be reasonable
        XCTAssertLessThan(stats.cpuUsage, 0.5, "CPU usage should be under 50%")

        // And: Memory usage should be reasonable
        let expectedMemory = 6 * 50_000_000 // 50MB per song
        XCTAssertEqual(stats.memoryUsage, expectedMemory, accuracy: 10_000_000)
    }

    func testMemoryUsageOverTime() async throws {
        // Given: Engine
        for song in testSongs {
            engine.addSong(song)
        }

        var memorySnapshots: [Int] = []

        // When: Taking memory snapshots over time
        for _ in 0..<10 {
            engine.toggleMasterPlayback()
            memorySnapshots.append(engine.statistics.memoryUsage)

            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            engine.toggleMasterPlayback()
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then: Memory usage should not grow significantly
        let initialMemory = memorySnapshots[0]
        let finalMemory = memorySnapshots.last!

        let growth = Double(finalMemory - initialMemory) / Double(initialMemory)

        XCTAssertLessThan(growth, 0.2, "Memory growth should be less than 20%")
    }

    // =============================================================================
    // MARK: - Memory Leak Tests
    // =============================================================================

    func testNoMemoryLeakWhenAddingRemoving() async throws {
        // Given: Engine
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let testEngine = MultiSongEngine()

            // When: Adding and removing songs many times
            for _ in 0..<5 {
                for song in testSongs {
                    testEngine.addSong(song)
                }
                testEngine.removeAllSongs()
            }

            weakEngine = testEngine
        }

        // Then: Engine should be deallocated
        XCTAssertNil(weakEngine, "Engine should be deallocated after autoreleasepool")
    }

    func testNoMemoryLeakDuringPlayback() async throws {
        // Given: Engine with songs
        for song in testSongs {
            engine.addSong(song)
        }

        let initialMemory = engine.statistics.memoryUsage

        // When: Starting and stopping playback many times
        for _ in 0..<10 {
            engine.toggleMasterPlayback()
            try await Task.sleep(nanoseconds: 100_000_000)

            engine.toggleMasterPlayback()
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        let finalMemory = engine.statistics.memoryUsage

        // Then: Memory should not grow significantly
        let growth = Double(finalMemory - initialMemory) / Double(initialMemory)

        XCTAssertLessThan(growth, 0.1, "Memory growth should be less than 10%")
    }

    // =============================================================================
    // MARK: - Audio Latency Tests
    // =============================================================================

    func testAudioLatencyWith6Songs() async throws {
        // Given: 6 loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // When: Checking audio latency
        let latency = engine.statistics.audioLatency

        // Then: Should be acceptable for real-time playback
        XCTAssertLessThan(latency, 50.0, "Audio latency should be under 50ms")
    }

    // =============================================================================
    // MARK: - Frame Rate Tests
    // =============================================================================

    func testUIFrameRateWith6Songs() async throws {
        // Given: 6 loaded songs
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // When: Checking UI frame rate
        let frameRate = engine.statistics.uiFrameRate

        // Then: Should maintain 60fps
        XCTAssertGreaterThanOrEqual(frameRate, 55.0, "UI should maintain at least 55fps")
    }

    // =============================================================================
    // MARK: - Stress Tests
    // =============================================================================

    func testStressWith12Songs() async throws {
        // Given: 12 songs
        let stressTestSongs = createTestSongs(count: 12)

        // When: Loading all songs
        for song in stressTestSongs {
            engine.addSong(song)
        }

        // Then: Should load successfully
        XCTAssertEqual(engine.state.songs.count, 12)

        // When: Starting playback
        engine.toggleMasterPlayback()

        // Then: All should play
        XCTAssertTrue(engine.state.masterPlaying)

        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying)
        }

        // When: Rapidly changing settings
        for _ in 0..<5 {
            for song in engine.state.songs {
                engine.setTempo(playerId: song.id, tempo: Double.random(in: 0.5...2.0))
                engine.setVolume(playerId: song.id, volume: Double.random(in: 0.0...1.0))
            }

            engine.setMasterTempo(Double.random(in: 0.5...2.0))
            engine.setMasterVolume(Double.random(in: 0.0...1.0))

            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        // Then: Should still be playing
        XCTAssertTrue(engine.state.masterPlaying)
    }

    func testRapidStateChanges() async throws {
        // Given: 6 songs
        for song in testSongs {
            engine.addSong(song)
        }

        // When: Rapidly changing state
        for _ in 0..<20 {
            engine.toggleMasterPlayback()

            for song in engine.state.songs {
                if Bool.random() {
                    engine.toggleMute(playerId: song.id)
                }
                if Bool.random() {
                    engine.toggleLoop(playerId: song.id)
                }
            }

            if Bool.random() {
                engine.setSyncMode([.independent, .locked, .ratio].randomElement()!)
            }

            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // Then: Should not crash
        XCTAssertTrue(true, "Should complete rapid state changes without crashing")
    }

    // =============================================================================
    // MARK: - Edge Cases
    // =============================================================================

    func testRemovingSongWhilePlaying() async throws {
        // Given: 6 songs playing
        for song in testSongs {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()
        XCTAssertTrue(engine.state.masterPlaying)

        // When: Removing a song while playing
        let songToRemove = engine.state.songs[0]
        engine.removeSong(playerId: songToRemove.id)

        // Then: Should have 5 songs
        XCTAssertEqual(engine.state.songs.count, 5)

        // And: Master should still be playing
        XCTAssertTrue(engine.state.masterPlaying)

        // And: Other songs should still be playing
        for song in engine.state.songs {
            XCTAssertTrue(song.isPlaying)
        }
    }

    func testAddingSongWhilePlaying() async throws {
        // Given: 3 songs playing
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.toggleMasterPlayback()

        // When: Adding more songs while playing
        for song in testSongs.dropFirst(3) {
            engine.addSong(song)
        }

        // Then: Should have 6 songs
        XCTAssertEqual(engine.state.songs.count, 6)

        // And: Master should still be playing
        XCTAssertTrue(engine.state.masterPlaying)

        // And: New songs should not be playing (only master controls start)
        let newSongs = engine.state.songs.dropFirst(3)
        for song in newSongs {
            XCTAssertFalse(song.isPlaying, "New songs should not auto-play")
        }
    }

    func testChangingSyncModeWithExtremeTempos() async throws {
        // Given: Songs with extreme tempos
        for song in testSongs {
            engine.addSong(song)
        }

        // Set extreme tempos
        engine.state.songs[0].originalTempoRatio = 0.1
        engine.state.songs[1].originalTempoRatio = 5.0

        engine.setSyncMode(.ratio)
        engine.setMasterTempo(1.5)

        // When: Switching to locked mode
        engine.setSyncMode(.locked)

        // Then: All songs should sync to master
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01)
        }

        // When: Switching back to ratio
        engine.setSyncMode(.ratio)

        // Then: Should clamp to valid range
        XCTAssertEqual(engine.state.songs[0].tempo, 0.5, accuracy: 0.01, "Should clamp to min")
        XCTAssertEqual(engine.state.songs[1].tempo, 2.0, accuracy: 0.01, "Should clamp to max")
    }

    // =============================================================================
    // MARK: - Test Helpers
    // =============================================================================

    private func createTestSongs(count: Int) -> [Song] {
        var songs: [Song] = []

        for i in 0..<count {
            let song = Song(
                id: "integration-test-song-\(i)",
                name: "Integration Test Song \(i)",
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
                determinismSeed: "integration-test-seed-\(i)",
                createdAt: Date(),
                updatedAt: Date()
            )

            songs.append(song)
        }

        return songs
    }
}
