//
//  TestFixtures.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Test Fixtures
// =============================================================================

/**
 Standard test fixtures for unit tests
 */
public enum Fixtures {

    // MARK: - Song Player State

    /// Standard test song with all properties
    public static var testSong: SongPlayerState {
        SongPlayerState(
            name: "Test Song",
            artist: "Test Artist",
            originalBPM: 120.0,
            duration: 180.0,
            timeSignature: "4/4",
            key: "C",
            waveform: generateWaveform(count: 100),
            thumbnailURL: nil
        )
    }

    /// Song with custom waveform for testing
    public static func songWithWaveform(_ waveform: [Float]) -> SongPlayerState {
        SongPlayerState(
            name: "Waveform Test",
            artist: "Test Artist",
            originalBPM: 120.0,
            duration: 180.0,
            waveform: waveform
        )
    }

    /// Song with specific BPM
    public static func songWithBPM(_ bpm: Double) -> SongPlayerState {
        SongPlayerState(
            name: "BPM Test Song",
            artist: "Test Artist",
            originalBPM: bpm,
            duration: 180.0
        )
    }

    /// Song with specific duration
    public static func songWithDuration(_ duration: TimeInterval) -> SongPlayerState {
        SongPlayerState(
            name: "Duration Test Song",
            artist: "Test Artist",
            originalBPM: 120.0,
            duration: duration
        )
    }

    /// Playing song
    public static var playingSong: SongPlayerState {
        let song = testSong
        song.isPlaying = true
        song.progress = 0.5
        return song
    }

    /// Muted song
    public static var mutedSong: SongPlayerState {
        let song = testSong
        song.isMuted = true
        return song
    }

    /// Soloed song
    public static var soloedSong: SongPlayerState {
        let song = testSong
        song.isSolo = true
        return song
    }

    /// Song at specific progress
    public static func songWithProgress(_ progress: Double) -> SongPlayerState {
        let song = testSong
        song.progress = progress
        return song
    }

    /// Song with specific tempo
    public static func songWithTempo(_ tempo: Double) -> SongPlayerState {
        let song = testSong
        song.tempoMultiplier = tempo
        return song
    }

    /// Song with specific volume
    public static func songWithVolume(_ volume: Double) -> SongPlayerState {
        let song = testSong
        song.volume = volume
        return song
    }

    // MARK: - Multiple Songs

    /// Array of 6 demo songs
    public static var sixDemoSongs: [SongPlayerState] {
        [
            SongPlayerState(
                name: "Cosmic Journey",
                artist: "Stellar Sounds",
                originalBPM: 110.0,
                duration: 240.0,
                waveform: generateWaveform(count: 100)
            ),
            SongPlayerState(
                name: "Urban Rhythm",
                artist: "City Beats",
                originalBPM: 128.0,
                duration: 200.0,
                waveform: generateWaveform(count: 100)
            ),
            SongPlayerState(
                name: "Ambient Dreams",
                artist: "Ethereal",
                originalBPM: 80.0,
                duration: 300.0,
                waveform: generateWaveform(count: 100)
            ),
            SongPlayerState(
                name: "Electric Pulse",
                artist: "Voltage",
                originalBPM: 140.0,
                duration: 180.0,
                waveform: generateWaveform(count: 100)
            ),
            SongPlayerState(
                name: "Jazz Fusion",
                artist: "Smooth Operators",
                originalBPM: 95.0,
                duration: 260.0,
                waveform: generateWaveform(count: 100)
            ),
            SongPlayerState(
                name: "Rock Anthem",
                artist: "Power Chords",
                originalBPM: 120.0,
                duration: 210.0,
                waveform: generateWaveform(count: 100)
            )
        ]
    }

    /// Songs with various states for edge case testing
    public static var variousStateSongs: [SongPlayerState] {
        var songs = sixDemoSongs

        songs[0].isPlaying = true
        songs[0].progress = 0.3

        songs[1].isMuted = true
        songs[1].isSolo = false

        songs[2].isSolo = true
        songs[2].tempoMultiplier = 1.5

        songs[3].volume = 0.3

        songs[4].progress = 0.95
        songs[4].isPlaying = true

        songs[5].tempoMultiplier = 0.7

        return songs
    }

    // MARK: - Multi Song State

    /// Basic multi-song state with 6 songs
    public static var testMultiSongState: MultiSongState {
        let state = MultiSongState()
        state.songs = sixDemoSongs
        state.masterTempo = 1.0
        state.masterVolume = 0.8
        state.syncMode = .independent
        return state
    }

    /// Multi-song state in locked mode
    public static var lockedSyncState: MultiSongState {
        let state = testMultiSongState
        state.syncMode = .locked
        state.masterTempo = 1.2
        return state
    }

    /// Multi-song state in ratio mode
    public static var ratioSyncState: MultiSongState {
        let state = testMultiSongState
        state.syncMode = .ratio
        state.masterTempo = 1.0
        return state
    }

    /// Multi-song state with master playing
    public static var masterPlayingState: MultiSongState {
        let state = testMultiSongState
        state.isMasterPlaying = true
        state.songs.forEach { $0.isPlaying = true }
        return state
    }

    // MARK: - Master Transport State

    /// Basic master transport state
    public static var testMasterTransport: MasterTransportState {
        MasterTransportState(
            progress: 0.0,
            isLooping: false,
            loopStart: 0.0,
            loopEnd: 1.0
        )
    }

    /// Master transport with loop enabled
    public static var loopingTransport: MasterTransportState {
        MasterTransportState(
            progress: 0.25,
            isLooping: true,
            loopStart: 0.1,
            loopEnd: 0.9
        )
    }

    // MARK: - Waveform Data

    /// Generate synthetic waveform for testing
    public static func generateWaveform(count: Int, seed: UInt32 = 42) -> [Float] {
        var randomGenerator = SeededRandom(seed: seed)
        return (0..<count).map { _ in
            Float.random(in: 0.1...1.0, using: &randomGenerator)
        }
    }

    /// Flat waveform for edge case testing
    public static var flatWaveform: [Float] {
        Array(repeating: 0.5, count: 100)
    }

    /// Peak waveform for edge case testing
    public static var peakWaveform: [Float] {
        Array(repeating: 1.0, count: 100)
    }

    /// Empty waveform for edge case testing
    public static var emptyWaveform: [Float] {
        []
    }

    // MARK: - URL Fixtures

    /// Test thumbnail URL
    public static var testThumbnailURL: URL {
        URL(string: "https://example.com/thumbnail.png")!
    }

    // MARK: - Helper Types

    /// Seeded random generator for reproducible tests
    private struct SeededRandom {
        private var seed: UInt32

        init(seed: UInt32) {
            self.seed = seed
        }

        mutating func next() -> UInt32 {
            seed = seed &* 1103515245 &+ 12345
            return seed
        }
    }
}

// =============================================================================
// MARK: - Float Random Extension
// =============================================================================

private extension Float {
    static func random(in range: ClosedRange<Float>, using generator: inout Fixtures.SeededRandom) -> Float {
        let random = Float(generator.next()) / Float(UInt32.max)
        return range.lowerBound + random * (range.upperBound - range.lowerBound)
    }
}

// =============================================================================
// MARK: - Convenience Accessors
// =============================================================================

public extension XCTestCase {
    /// Create test song with custom properties
    func makeSong(
        name: String = "Test Song",
        artist: String = "Test Artist",
        bpm: Double = 120.0,
        duration: TimeInterval = 180.0,
        waveform: [Float] = []
    ) -> SongPlayerState {
        SongPlayerState(
            name: name,
            artist: artist,
            originalBPM: bpm,
            duration: duration,
            waveform: waveform.isEmpty ? Fixtures.generateWaveform(count: 100) : waveform
        )
    }

    /// Create multi-song state with custom song count
    func makeMultiSongState(songCount: Int = 6) -> MultiSongState {
        let state = MultiSongState()
        state.songs = (0..<songCount).map { index in
            SongPlayerState(
                name: "Song \(index + 1)",
                artist: "Artist \(index + 1)",
                originalBPM: 100.0 + Double(index) * 10,
                duration: 180.0,
                waveform: Fixtures.generateWaveform(count: 100, seed: UInt32(index))
            )
        }
        return state
    }
}
