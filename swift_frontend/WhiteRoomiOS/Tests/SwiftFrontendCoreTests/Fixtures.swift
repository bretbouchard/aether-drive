//
//  Fixtures.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import AVFoundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Test Fixtures
// =============================================================================

enum Fixtures {

    // MARK: - Song Fixtures

    static var testSong: Song {
        Song(
            id: "test-song-1",
            name: "Test Song",
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
            determinismSeed: "test-seed-1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testSongs: [Song] {
        (0..<6).map { index in
            Song(
                id: "test-song-\(index)",
                name: "Test Song \(index)",
                version: "1.0",
                metadata: SongMetadata(
                    tempo: 120.0 + Double(index) * 10,
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
                determinismSeed: "test-seed-\(index)",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    // MARK: - Song Player State Fixtures

    static var testSongSlot: SongPlayerState {
        SongPlayerState(
            id: UUID(),
            song: testSong,
            songName: "Test Song",
            tempo: 1.0,
            volume: 0.8,
            currentPosition: 0.5,
            isPlaying: false,
            isMuted: false,
            isSoloed: false,
            loopEnabled: false,
            loopStart: 0.0,
            loopEnd: 1.0
        )
    }

    static var testMultiSongState: MultiSongState {
        var state = MultiSongState()
        state.songs = (0..<6).map { index in
            SongPlayerState(
                id: UUID(),
                song: testSongs[index],
                songName: "Test Song \(index)",
                tempo: 1.0 + Double(index) * 0.1,
                volume: 0.8,
                currentPosition: Double(index) * 0.2,
                isPlaying: false,
                isMuted: false,
                isSoloed: false,
                loopEnabled: false,
                loopStart: 0.0,
                loopEnd: 1.0
            )
        }
        state.masterTempo = 1.0
        state.masterVolume = 0.8
        state.masterPlaying = false
        state.syncMode = .independent
        return state
    }

    // MARK: - Waveform Fixtures

    static var testWaveform: WaveformData {
        WaveformData(
            samples: (0..<1000).map { _ in Float.random(in: -1...1) },
            sampleRate: 44100.0,
            channelCount: 2
        )
    }

    // MARK: - Transport State Fixtures

    static var playingState: SongPlayerState {
        var state = testSongSlot
        state.isPlaying = true
        return state
    }

    static var pausedState: SongPlayerState {
        var state = testSongSlot
        state.isPlaying = false
        return state
    }

    static var mutedState: SongPlayerState {
        var state = testSongSlot
        state.isMuted = true
        return state
    }

    static var soloedState: SongPlayerState {
        var state = testSongSlot
        state.isSoloed = true
        return state
    }

    static var loopedState: SongPlayerState {
        var state = testSongSlot
        state.loopEnabled = true
        state.loopStart = 0.25
        state.loopEnd = 0.75
        return state
    }

    // MARK: - Performance Metrics Fixtures

    static var baselineMetrics: [String: Double] {
        [
            "SongPlayerCardRendering": 0.01,
            "MovingSidewalkViewRendering": 0.05,
            "ParallelProgressViewRendering": 0.02,
            "MultiSongWaveformViewRendering": 0.03,
            "TimelineMarkerRendering": 0.015,
            "MasterTransportControlsRendering": 0.025
        ]
    }
}
