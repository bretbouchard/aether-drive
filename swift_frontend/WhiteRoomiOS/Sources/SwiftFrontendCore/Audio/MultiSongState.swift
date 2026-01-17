//
//  MultiSongState.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import Combine

// =============================================================================
// MARK: - Multi-Song Player State
// =============================================================================

/**
 State for the Moving Sidewalk multi-song player.

 Manages multiple simultaneous song playback with independent or synced controls.
 */
@MainActor
public class MultiSongState: ObservableObject {

    // MARK: - Published Properties

    /// All loaded songs
    @Published public var songs: [SongPlayerState] = []

    /// Master transport state
    @Published public var masterTransport: MasterTransportState

    /// Sync mode between songs
    @Published public var syncMode: SyncMode = .independent

    /// Whether master play is active
    @Published public var isMasterPlaying: Bool = false

    /// Master tempo (affects all songs in ratio/locked mode)
    @Published public var masterTempo: Double = 1.0

    /// Master volume
    @Published public var masterVolume: Double = 0.8

    // MARK: - Initialization

    public init() {
        self.masterTransport = MasterTransportState()
    }

    // MARK: - Song Management

    /**
     Add a new song to the player
     */
    public func addSong(_ song: SongPlayerState) {
        songs.append(song)
    }

    /**
     Remove a song from the player
     */
    public func removeSong(id: String) {
        songs.removeAll { $0.id == id }
    }

    /**
     Get a specific song by ID
     */
    public func getSong(id: String) -> SongPlayerState? {
        songs.first { $0.id == id }
    }

    // MARK: - Transport Controls

    /**
     Toggle master play/pause
     */
    public func toggleMasterPlay() {
        isMasterPlaying.toggle()

        if isMasterPlaying {
            // Start all songs based on sync mode
            for song in songs {
                if !song.isMuted {
                    song.isPlaying = true
                }
            }
        } else {
            // Pause all songs
            for song in songs {
                song.isPlaying = false
            }
        }
    }

    /**
     Stop all playback and reset to beginning
     */
    public func stopAll() {
        isMasterPlaying = false
        for song in songs {
            song.isPlaying = false
            song.progress = 0.0
        }
    }

    // MARK: - Sync Modes

    /**
     Synchronization mode for multiple songs
     */
    public enum SyncMode: String, CaseIterable {
        case independent = "Independent"
        case locked = "Locked"
        case ratio = "Ratio"

        var icon: String {
            switch self {
            case .independent: return "arrow.triangle.2.circlepath"
            case .locked: return "lock.fill"
            case .ratio: return "percent"
            }
        }
    }
}

// =============================================================================
// MARK: - Master Transport State
// =============================================================================

/**
 Master transport controls for the multi-song player.
 */
public struct MasterTransportState {

    /// Current playback position (0.0 to 1.0)
    public var progress: Double = 0.0

    /// Loop enabled
    public var isLooping: Bool = false

    /// Loop start point (0.0 to 1.0)
    public var loopStart: Double = 0.0

    /// Loop end point (0.0 to 1.0)
    public var loopEnd: Double = 1.0

    public init() {}
}

// =============================================================================
// MARK: - Song Player State
// =============================================================================

/**
 State for an individual song in the multi-song player.
 */
@MainActor
public class SongPlayerState: ObservableObject, Identifiable {

    // MARK: - Identity

    /// Unique identifier
    public let id: String

    /// Song name
    @Published public var name: String

    /// Song artist/composer
    @Published public var artist: String

    // MARK: - Song Properties

    /// Original tempo in BPM
    @Published public var originalBPM: Double

    /// Duration in seconds
    @Published public var duration: TimeInterval

    /// Time signature
    @Published public var timeSignature: String = "4/4"

    /// Key
    @Published public var key: String = "C"

    // MARK: - Playback State

    /// Current playback position (0.0 to 1.0)
    @Published public var progress: Double = 0.0

    /// Whether song is currently playing
    @Published public var isPlaying: Bool = false

    /// Whether song is muted
    @Published public var isMuted: Bool = false

    /// Whether song is soloed
    @Published public var isSolo: Bool = false

    // MARK: - Audio Controls

    /// Tempo multiplier (0.5x to 2.0x)
    @Published public var tempoMultiplier: Double = 1.0

    /// Volume level (0.0 to 1.0)
    @Published public var volume: Double = 0.8

    /// Pan position (-1.0 to 1.0)
    @Published public var pan: Double = 0.0

    // MARK: - Visual Data

    /// Waveform data for visualization
    @Published public var waveform: [Float] = []

    /// Album art or thumbnail
    @Published public var thumbnailURL: URL?

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        name: String,
        artist: String = "",
        originalBPM: Double,
        duration: TimeInterval,
        timeSignature: String = "4/4",
        key: String = "C",
        waveform: [Float] = [],
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.originalBPM = originalBPM
        self.duration = duration
        self.timeSignature = timeSignature
        self.key = key
        self.waveform = waveform
        self.thumbnailURL = thumbnailURL
    }

    // MARK: - Computed Properties

    /**
     Current tempo in BPM
     */
    public var currentBPM: Double {
        originalBPM * tempoMultiplier
    }

    /**
     Current playback position in seconds
     */
    public var currentTime: TimeInterval {
        duration * progress
    }

    /**
     Formatted time string (MM:SS)
     */
    public var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /**
     Formatted duration string (MM:SS)
     */
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// =============================================================================
// MARK: - Demo Data
// =============================================================================

public extension SongPlayerState {

    /**
     Create demo song for testing
     */
    static func demoSong(
        name: String,
        artist: String = "Demo Artist",
        bpm: Double = 120.0,
        duration: TimeInterval = 180.0
    ) -> SongPlayerState {
        // Generate synthetic waveform
        let waveform = (0..<100).map { _ in
            Float.random(in: 0.1...1.0)
        }

        return SongPlayerState(
            name: name,
            artist: artist,
            originalBPM: bpm,
            duration: duration,
            waveform: waveform
        )
    }

    /**
     Create multiple demo songs
     */
    static func demoSongs() -> [SongPlayerState] {
        [
            demoSong(name: "Cosmic Journey", artist: "Stellar Sounds", bpm: 110.0, duration: 240.0),
            demoSong(name: "Urban Rhythm", artist: "City Beats", bpm: 128.0, duration: 200.0),
            demoSong(name: "Ambient Dreams", artist: "Ethereal", bpm: 80.0, duration: 300.0),
            demoSong(name: "Electric Pulse", artist: "Voltage", bpm: 140.0, duration: 180.0)
        ]
    }
}

// =============================================================================
// MARK: - Preset Management
// =============================================================================

/**
 Preset configuration for multi-song setups
 */
public struct MultiSongPreset: Codable, Identifiable {

    /// Unique identifier
    public let id: String

    /// Preset name
    public let name: String

    /// Song configurations
    public let songs: [SongPresetConfig]

    /// Master settings
    public let masterSettings: MasterSettings

    /// Sync mode
    public let syncMode: MultiSongState.SyncMode

    /// When preset was created
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        songs: [SongPresetConfig],
        masterSettings: MasterSettings,
        syncMode: MultiSongState.SyncMode,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.songs = songs
        self.masterSettings = masterSettings
        self.syncMode = syncMode
        self.createdAt = createdAt
    }
}

/**
 Preset configuration for a single song
 */
public struct SongPresetConfig: Codable, Identifiable {

    /// Unique identifier
    public let id: String

    /// Song ID (references actual song)
    public let songId: String

    /// Tempo multiplier
    public let tempoMultiplier: Double

    /// Volume
    public let volume: Double

    /// Is muted
    public let isMuted: Bool

    /// Is soloed
    public let isSolo: Bool

    public init(
        id: String = UUID().uuidString,
        songId: String,
        tempoMultiplier: Double = 1.0,
        volume: Double = 0.8,
        isMuted: Bool = false,
        isSolo: Bool = false
    ) {
        self.id = id
        self.songId = songId
        self.tempoMultiplier = tempoMultiplier
        self.volume = volume
        self.isMuted = isMuted
        self.isSolo = isSolo
    }
}

/**
 Master settings for preset
 */
public struct MasterSettings: Codable {

    /// Master tempo
    public let masterTempo: Double

    /// Master volume
    public let masterVolume: Double

    /// Loop enabled
    public let isLooping: Bool

    public init(
        masterTempo: Double = 1.0,
        masterVolume: Double = 0.8,
        isLooping: Bool = false
    ) {
        self.masterTempo = masterTempo
        self.masterVolume = masterVolume
        self.isLooping = isLooping
    }
}
