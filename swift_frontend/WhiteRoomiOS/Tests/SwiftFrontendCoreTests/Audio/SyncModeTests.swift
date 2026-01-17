//
//  SyncModeTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Sync Mode Tests
// =============================================================================

@MainActor
final class SyncModeTests: XCTestCase {

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
    // MARK: - Independent Mode Tests
    // =============================================================================

    func testIndependentModeInitialTempo() async throws {
        // Given: 3 songs in independent mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        // When: Not changing any tempos
        // Then: Each song should maintain its initial tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.0, accuracy: 0.01, "Independent mode should preserve initial tempo")
        }
    }

    func testIndependentModeTempoChanges() async throws {
        // Given: 3 songs in independent mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        let song1 = engine.state.songs[0]
        let song2 = engine.state.songs[1]
        let song3 = engine.state.songs[2]

        // When: Setting different tempos for each song
        engine.setTempo(playerId: song1.id, tempo: 0.75)
        engine.setTempo(playerId: song2.id, tempo: 1.0)
        engine.setTempo(playerId: song3.id, tempo: 1.5)

        // Then: Each song should maintain its own tempo
        XCTAssertEqual(engine.state.songs[0].tempo, 0.75, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, 1.5, accuracy: 0.01)
    }

    func testIndependentModeMasterTempoDoesNotAffectSongs() async throws {
        // Given: 3 songs in independent mode with custom tempos
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.8)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.2)
        engine.setTempo(playerId: engine.state.songs[2].id, tempo: 1.6)

        // When: Changing master tempo
        engine.setMasterTempo(1.5)

        // Then: Individual song tempos should not change
        XCTAssertEqual(engine.state.songs[0].tempo, 0.8, accuracy: 0.01, "Independent mode: master tempo should not affect songs")
        XCTAssertEqual(engine.state.songs[1].tempo, 1.2, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, 1.6, accuracy: 0.01)

        // But master tempo should update
        XCTAssertEqual(engine.state.masterTempo, 1.5, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Locked Mode Tests
    // =============================================================================

    func testLockedModeAllSongsSyncToMaster() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)

        // When: Setting master tempo
        engine.setMasterTempo(1.75)

        // Then: All songs should sync to master tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.75, accuracy: 0.01, "Locked mode: all songs should match master tempo")
        }
    }

    func testLockedModeMasterTempoChangesAffectAllSongs() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)
        engine.setMasterTempo(1.0)

        // When: Changing master tempo multiple times
        let testTempos: [Double] = [0.75, 1.25, 1.5, 0.9, 1.8]

        for tempo in testTempos {
            engine.setMasterTempo(tempo)

            // Then: All songs should sync to each master tempo
            for song in engine.state.songs {
                XCTAssertEqual(song.tempo, tempo, accuracy: 0.01, "Locked mode: all songs should sync to master tempo changes")
            }
        }
    }

    func testLockedModeIndividualTempoChangesOverridden() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)
        engine.setMasterTempo(1.5)

        // When: Trying to set individual song tempos
        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.8)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.2)

        // Then: Individual tempo changes should be overridden by master
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01, "Locked mode: individual tempo changes should be overridden")
        }
    }

    func testLockedModeTransitionFromIndependent() async throws {
        // Given: 3 songs in independent mode with different tempos
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.7)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.3)
        engine.setTempo(playerId: engine.state.songs[2].id, tempo: 1.6)

        // When: Switching to locked mode
        engine.setSyncMode(.locked)

        // Then: All songs should sync to current master tempo (1.0 by default)
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.0, accuracy: 0.01, "Transition to locked mode should sync all songs to master")
        }
    }

    // =============================================================================
    // MARK: - Ratio Mode Tests
    // =============================================================================

    func testRatioModeMaintainsTempoRatios() async throws {
        // Given: 3 songs with different original tempo ratios
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        // Set original ratios
        engine.state.songs[0].originalTempoRatio = 0.5
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 2.0

        engine.setSyncMode(.ratio)

        // When: Setting master tempo
        engine.setMasterTempo(1.5)

        // Then: Songs should maintain their ratios
        XCTAssertEqual(engine.state.songs[0].tempo, 0.75, accuracy: 0.01, "Ratio 0.5 * 1.5 = 0.75")
        XCTAssertEqual(engine.state.songs[1].tempo, 1.5, accuracy: 0.01, "Ratio 1.0 * 1.5 = 1.5")
        XCTAssertEqual(engine.state.songs[2].tempo, 3.0, accuracy: 0.01, "Ratio 2.0 * 1.5 = 3.0 (but should clamp to 2.0)")
    }

    func testRatioModeMasterTempoChangesScaleRatios() async throws {
        // Given: 3 songs with ratios in ratio mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.state.songs[0].originalTempoRatio = 0.75
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 1.25

        engine.setSyncMode(.ratio)

        // When: Changing master tempo
        let masterTempos: [Double] = [0.8, 1.0, 1.2, 1.5]

        for masterTempo in masterTempos {
            engine.setMasterTempo(masterTempo)

            // Then: Each song should scale its ratio
            XCTAssertEqual(engine.state.songs[0].tempo, masterTempo * 0.75, accuracy: 0.01)
            XCTAssertEqual(engine.state.songs[1].tempo, masterTempo * 1.0, accuracy: 0.01)
            XCTAssertEqual(engine.state.songs[2].tempo, min(masterTempo * 1.25, 2.0), accuracy: 0.01, "Should clamp to max 2.0")
        }
    }

    func testRatioModeRespectsTempoLimits() async throws {
        // Given: Song with high ratio
        engine.addSong(testSongs[0])
        engine.state.songs[0].originalTempoRatio = 3.0 // Would exceed 2.0x limit

        engine.setSyncMode(.ratio)

        // When: Setting master tempo to 1.0
        engine.setMasterTempo(1.0)

        // Then: Should clamp to maximum tempo (2.0)
        XCTAssertEqual(engine.state.songs[0].tempo, 2.0, accuracy: 0.01, "Should clamp to max tempo 2.0")

        // When: Setting master tempo to 0.5
        engine.setMasterTempo(0.5)

        // Then: Should still maintain ratio but clamp if needed
        XCTAssertEqual(engine.state.songs[0].tempo, min(3.0 * 0.5, 2.0), accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Mode Transition Tests
    // =============================================================================

    func testTransitionFromIndependentToLocked() async throws {
        // Given: 3 songs in independent mode with different tempos
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.8)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.2)
        engine.setTempo(playerId: engine.state.songs[2].id, tempo: 1.6)

        // When: Transitioning to locked mode
        engine.setSyncMode(.locked)

        // Then: All songs should sync to master tempo (1.0 default)
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.0, accuracy: 0.01, "Should sync to master tempo on transition")
        }
    }

    func testTransitionFromLockedToIndependent() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)
        engine.setMasterTempo(1.5)

        // All songs should be at 1.5
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01)
        }

        // When: Transitioning to independent mode
        engine.setSyncMode(.independent)

        // Then: Songs should maintain their current tempos but can now be changed independently
        let initialTempo = engine.state.songs[0].tempo

        // Changing one song should not affect others
        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.9)

        XCTAssertEqual(engine.state.songs[0].tempo, 0.9, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.5, accuracy: 0.01, "Other songs should maintain their tempo")
        XCTAssertEqual(engine.state.songs[2].tempo, 1.5, accuracy: 0.01)
    }

    func testTransitionFromIndependentToRatio() async throws {
        // Given: 3 songs in independent mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.independent)

        engine.setTempo(playerId: engine.state.songs[0].id, tempo: 0.8)
        engine.setTempo(playerId: engine.state.songs[1].id, tempo: 1.0)
        engine.setTempo(playerId: engine.state.songs[2].id, tempo: 1.2)

        // Set ratios (should be calculated from current tempos)
        engine.state.songs[0].originalTempoRatio = 0.8
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 1.2

        // When: Transitioning to ratio mode
        engine.setSyncMode(.ratio)

        // Then: Songs should scale according to their ratios and current master
        let masterTempo = engine.state.masterTempo

        XCTAssertEqual(engine.state.songs[0].tempo, masterTempo * 0.8, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, masterTempo * 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, masterTempo * 1.2, accuracy: 0.01)
    }

    func testTransitionFromLockedToRatio() async throws {
        // Given: 3 songs in locked mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.setSyncMode(.locked)
        engine.setMasterTempo(1.5)

        // Set up ratios for transition
        engine.state.songs[0].originalTempoRatio = 0.5
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 1.5

        // When: Transitioning to ratio mode
        engine.setSyncMode(.ratio)

        // Then: Songs should use their ratios with current master tempo
        XCTAssertEqual(engine.state.songs[0].tempo, 1.5 * 0.5, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[1].tempo, 1.5 * 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, min(1.5 * 1.5, 2.0), accuracy: 0.01)
    }

    func testTransitionFromRatioToLocked() async throws {
        // Given: 3 songs in ratio mode
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.state.songs[0].originalTempoRatio = 0.75
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 1.25

        engine.setSyncMode(.ratio)
        engine.setMasterTempo(1.5)

        // Songs should have different tempos based on ratios
        XCTAssertNotEqual(engine.state.songs[0].tempo, engine.state.songs[1].tempo)

        // When: Transitioning to locked mode
        engine.setSyncMode(.locked)

        // Then: All songs should sync to master tempo
        for song in engine.state.songs {
            XCTAssertEqual(song.tempo, 1.5, accuracy: 0.01, "All songs should sync to master in locked mode")
        }
    }

    // =============================================================================
    // MARK: - Edge Cases
    // =============================================================================

    func testEmptyEngineSyncModeChanges() async throws {
        // Given: Engine with no songs
        XCTAssertEqual(engine.state.songs.count, 0)

        // When: Changing sync modes
        engine.setSyncMode(.locked)
        engine.setSyncMode(.independent)
        engine.setSyncMode(.ratio)

        // Then: Should not crash and sync mode should update
        XCTAssertEqual(engine.state.syncMode, .ratio)
    }

    func testSingleSongSyncModes() async throws {
        // Given: Engine with 1 song
        engine.addSong(testSongs[0])

        // When: Testing all sync modes
        for mode in [SyncMode.independent, .locked, .ratio] {
            engine.setSyncMode(mode)
            engine.setMasterTempo(1.3)

            // Then: Song should respond appropriately in all modes
            XCTAssertGreaterThan(engine.state.songs[0].tempo, 0)
        }
    }

    func testExtremeTempoRatiosInRatioMode() async throws {
        // Given: Songs with extreme ratios
        for song in testSongs.prefix(3) {
            engine.addSong(song)
        }

        engine.state.songs[0].originalTempoRatio = 0.1
        engine.state.songs[1].originalTempoRatio = 1.0
        engine.state.songs[2].originalTempoRatio = 5.0

        engine.setSyncMode(.ratio)
        engine.setMasterTempo(1.0)

        // Then: Should clamp to valid range
        XCTAssertEqual(engine.state.songs[0].tempo, 0.5, accuracy: 0.01, "Should clamp to minimum 0.5")
        XCTAssertEqual(engine.state.songs[1].tempo, 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.state.songs[2].tempo, 2.0, accuracy: 0.01, "Should clamp to maximum 2.0")
    }

    // =============================================================================
    // MARK: - Test Helpers
    // =============================================================================

    private func createTestSongs(count: Int) -> [Song] {
        var songs: [Song] = []

        for i in 0..<count {
            let song = Song(
                id: "sync-test-song-\(i)",
                name: "Sync Test Song \(i)",
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
                determinismSeed: "sync-test-seed-\(i)",
                createdAt: Date(),
                updatedAt: Date()
            )

            songs.append(song)
        }

        return songs
    }
}
