//
//  XCUITestFixtures.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import SwiftUI
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - XCUITest Fixtures
// =============================================================================

/// Comprehensive fixture builders for XCUITest suite
/// Provides realistic test data for UI testing scenarios
public class XCUITestFixtures {

    // =============================================================================
    // MARK: - Song Data Builders
    // =============================================================================

    /// Creates a test song with customizable parameters
    /// - Parameters:
    ///   - id: Unique identifier (defaults to random UUID)
    ///   - name: Song name
    ///   - bpm: Tempo in beats per minute
    ///   - duration: Song duration in seconds
    /// - Returns: A configured Song instance
    public static func createTestSong(
        id: String = "test-song-\(UUID().uuidString)",
        name: String = "Test Song",
        bpm: Double = 120,
        duration: TimeInterval = 180.0
    ) -> Song {
        Song(
            id: id,
            name: name,
            version: "1.0",
            metadata: SongMetadata(
                tempo: bpm,
                timeSignature: [4, 4],
                duration: duration
            ),
            sections: createTestSections(count: 3),
            roles: createTestRoles(),
            projections: [],
            mixGraph: MixGraph(
                tracks: createTestTracks(count: 3),
                buses: [],
                sends: [],
                master: MixMasterConfig(volume: 0.8)
            ),
            realizationPolicy: RealizationPolicy(
                windowSize: MusicalTime(beats: 4),
                lookaheadDuration: MusicalTime(seconds: 1.0),
                determinismMode: .seeded
            ),
            determinismSeed: "test-seed",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Creates multiple test songs with varying properties
    /// - Parameter count: Number of songs to create
    /// - Returns: Array of Song instances
    public static func createTestSongs(count: Int) -> [Song] {
        (0..<count).map { index in
            createTestSong(
                id: "song-\(index)",
                name: "Demo Song \(index)",
                bpm: 80 + (index * 20), // 80, 100, 120, 140, 160, 180
                duration: 180.0
            )
        }
    }

    // =============================================================================
    // MARK: - State Builders
    // =============================================================================

    /// Creates a test multi-song state for UI testing
    /// - Parameters:
    ///   - songCount: Number of songs in the state (0-6)
    ///   - allPlaying: Whether all songs are playing
    ///   - syncMode: Synchronization mode
    /// - Returns: A configured MultiSongState instance
    public static func createTestMultiSongState(
        songCount: Int = 6,
        allPlaying: Bool = false,
        syncMode: SyncMode = .independent
    ) -> MultiSongState {
        let songs = (0..<songCount).map { index in
            SongPlayerState(
                id: UUID(),
                song: createTestSong(
                    id: "song-\(index)",
                    name: "Test Song \(index)",
                    bpm: 120 + (index * 10)
                ),
                songName: "Test Song \(index)",
                tempo: 1.0 + Double(index) * 0.1,
                volume: 0.8,
                currentPosition: 0.0,
                isPlaying: allPlaying,
                isMuted: false,
                isSoloed: false,
                loopEnabled: false,
                loopStart: 0.0,
                loopEnd: 1.0
            )
        }

        var state = MultiSongState()
        state.songs = songs
        state.masterTempo = 1.0
        state.masterVolume = 0.8
        state.masterPlaying = allPlaying
        state.syncMode = syncMode
        return state
    }

    /// Creates a test song slot for individual player testing
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - songId: Song identifier
    ///   - isPlaying: Initial play state
    ///   - tempo: Initial tempo
    ///   - volume: Initial volume (0.0-1.0)
    /// - Returns: A configured SongPlayerState instance
    public static func createTestSongSlot(
        id: UUID = UUID(),
        songId: String = "test-song",
        isPlaying: Bool = false,
        tempo: Double = 1.0,
        volume: Double = 0.8
    ) -> SongPlayerState {
        SongPlayerState(
            id: id,
            song: createTestSong(id: songId),
            songName: "Test Song",
            tempo: tempo,
            volume: volume,
            currentPosition: 0.0,
            isPlaying: isPlaying,
            isMuted: false,
            isSoloed: false,
            loopEnabled: false,
            loopStart: 0.0,
            loopEnd: 1.0
        )
    }

    // =============================================================================
    // MARK: - Preset Data Builders
    // =============================================================================

    /// Creates a test preset for preset management testing
    /// - Parameters:
    ///   - name: Preset name
    ///   - songCount: Number of songs in the preset
    /// - Returns: A configured MultiSongPreset instance
    public static func createTestPreset(
        name: String = "Test Preset",
        songCount: Int = 6
    ) -> MultiSongPreset {
        let state = createTestMultiSongState(songCount: songCount)

        return MultiSongPreset(
            id: UUID(),
            name: name,
            songs: state.songs.map { slot in
                PresetSongSlot(
                    songId: slot.song.id,
                    tempo: slot.tempo,
                    volume: slot.volume,
                    isMuted: slot.isMuted,
                    isSoloed: slot.isSoloed
                )
            },
            masterSettings: MasterSettings(
                tempo: 120,
                syncMode: .locked
            ),
            metadata: PresetMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                author: "Test User",
                version: 1
            )
        )
    }

    /// Creates multiple test presets
    /// - Parameter count: Number of presets to create
    /// - Returns: Array of MultiSongPreset instances
    public static func createTestPresets(count: Int) -> [MultiSongPreset] {
        (0..<count).map { index in
            createTestPreset(
                name: "Preset \(index)",
                songCount: Int.random(in: 1...6)
            )
        }
    }

    // =============================================================================
    // MARK: - Edge Case Scenarios
    // =============================================================================

    /// Creates a stress test state with maximum song count
    /// - Parameter songCount: Number of songs (default 10 for stress testing)
    /// - Returns: A MultiSongState with all songs playing
    public static func createStressTestState(songCount: Int = 10) -> MultiSongState {
        createTestMultiSongState(
            songCount: songCount,
            allPlaying: true,
            syncMode: .locked
        )
    }

    /// Creates an empty state for edge case testing
    /// - Returns: A MultiSongState with no songs
    public static func createEmptyState() -> MultiSongState {
        createTestMultiSongState(songCount: 0)
    }

    /// Creates a full state with all songs playing and locked sync
    /// - Returns: A fully loaded MultiSongState
    public static func createFullState() -> MultiSongState {
        createTestMultiSongState(
            songCount: 6,
            allPlaying: true,
            syncMode: .locked
        )
    }

    /// Creates a state with extreme tempo values for boundary testing
    /// - Returns: A MultiSongState with min and max tempo songs
    public static func createBoundaryTempoState() -> MultiSongState {
        let songs = [
            createTestSongSlot(tempo: 0.0),   // Minimum
            createTestSongSlot(tempo: 2.0),   // Maximum
            createTestSongSlot(tempo: 1.0),   // Normal
        ]

        var state = MultiSongState()
        state.songs = songs
        state.masterTempo = 1.0
        return state
    }

    /// Creates a state with extreme volume values for boundary testing
    /// - Returns: A MultiSongState with min, max, and normal volumes
    public static func createBoundaryVolumeState() -> MultiSongState {
        let songs = [
            createTestSongSlot(volume: 0.0),  // Muted
            createTestSongSlot(volume: 1.0),  // Full
            createTestSongSlot(volume: 0.5),  // Half
        ]

        var state = MultiSongState()
        state.songs = songs
        return state
    }

    // =============================================================================
    // MARK: - Helper Methods
    // =============================================================================

    /// Creates test track data
    /// - Parameter count: Number of tracks to create
    /// - Returns: Array of Track instances
    private static func createTestTracks(count: Int) -> [Track] {
        (0..<count).map { index in
            Track(
                id: "track-\(index)",
                name: "Track \(index)",
                instrument: .drums,
                volume: 0.8,
                pan: 0.0,
                isMuted: false,
                isSoloed: false
            )
        }
    }

    /// Creates test section data
    /// - Parameter count: Number of sections to create
    /// - Returns: Array of Section instances
    private static func createTestSections(count: Int) -> [Section] {
        (0..<count).map { index in
            Section(
                id: "section-\(index)",
                name: "Section \(index)",
                start: MusicalTime(beats: Double(index) * 16),
                duration: MusicalTime(beats: 16),
                loops: 1
            )
        }
    }

    /// Creates test role data
    /// - Returns: Array of Role instances
    private static func createTestRoles() -> [Role] {
        [
            Role(
                id: "role-drums",
                name: "Drums",
                instrument: .drums,
                patterns: []
            ),
            Role(
                id: "role-bass",
                name: "Bass",
                instrument: .bass,
                patterns: []
            )
        ]
    }

    // =============================================================================
    // MARK: - Performance Test Data
    // =============================================================================

    /// Creates a large dataset for performance testing
    /// - Returns: A MultiSongState with maximum configuration
    public static func createPerformanceTestState() -> MultiSongState {
        var state = createTestMultiSongState(
            songCount: 6,
            allPlaying: true,
            syncMode: .locked
        )

        // Add additional complexity
        for i in 0..<state.songs.count {
            state.songs[i].tempo = 1.0 + Double(i) * 0.2
            state.songs[i].volume = 0.5 + Double(i) * 0.1
            state.songs[i].currentPosition = Double(i) * 0.15
        }

        return state
    }

    /// Creates waveform data for visualization testing
    /// - Parameter sampleCount: Number of samples to generate
    /// - Returns: WaveformData instance
    public static func createTestWaveform(sampleCount: Int = 1000) -> WaveformData {
        WaveformData(
            samples: (0..<sampleCount).map { i in
                sin(Float(i) * 0.1) * 0.8
            },
            sampleRate: 44100.0,
            channelCount: 2
        )
    }

    // =============================================================================
    // MARK: - Integration Test Data
    // =============================================================================

    /// Creates a complete test scenario for integration testing
    /// - Returns: Tuple of (state, presets, waveforms)
    public static func createIntegrationTestData() -> (
        state: MultiSongState,
        presets: [MultiSongPreset],
        waveforms: [String: WaveformData]
    ) {
        let state = createTestMultiSongState()
        let presets = createTestPresets(count: 3)
        let waveforms = Dictionary(
            uniqueKeysWithValues: state.songs.map { ($0.song.id, createTestWaveform()) }
        )

        return (state, presets, waveforms)
    }
}
