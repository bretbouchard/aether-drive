//
//  MultiSongState.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - Multi-Song State Models
// =============================================================================

/**
 State for the entire multi-song playback system.

 Coordinates multiple song players with master controls.
 */
public struct MultiSongState: Equatable, Codable, Sendable {

    /// Unique identifier for this multi-song session
    public let id: UUID

    /// All song player states
    public var songs: [SongPlayerState]

    /// Master playback state
    public var masterPlaying: Bool

    /// Master tempo multiplier (applies to all songs in locked mode)
    public var masterTempo: Double

    /// Master volume (0.0 to 1.0)
    public var masterVolume: Double

    /// How songs synchronize their tempos
    public var syncMode: SyncMode

    public init(
        id: UUID = UUID(),
        songs: [SongPlayerState] = [],
        masterPlaying: Bool = false,
        masterTempo: Double = 1.0,
        masterVolume: Double = 0.8,
        syncMode: SyncMode = .independent
    ) {
        self.id = id
        self.songs = songs
        self.masterPlaying = masterPlaying
        self.masterTempo = masterTempo
        self.masterVolume = masterVolume
        self.syncMode = syncMode
    }
}

// =============================================================================
// MARK: - Song Player State
// =============================================================================

/**
 State for an individual song player in the multi-song system.

 Each song can be controlled independently or synchronized with others.
 */
public struct SongPlayerState: Equatable, Codable, Sendable, Identifiable {

    /// Unique identifier for this player instance
    public let id: UUID

    /// Reference to the song being played
    public let songId: String

    /// Song name for display
    public var songName: String

    /// Current playback state
    public var isPlaying: Bool

    /// Individual tempo multiplier (0.5x to 2.0x)
    public var tempo: Double

    /// Volume for this song (0.0 to 1.0)
    public var volume: Double

    /// Mute state
    public var isMuted: Bool

    /// Solo state
    public var isSoloed: Bool

    /// Current playback position in seconds
    public var currentPosition: Double

    /// Total duration in seconds
    public var duration: Double

    /// Loop enabled
    public var loopEnabled: Bool

    /// Loop start position (seconds)
    public var loopStart: Double

    /// Loop end position (seconds)
    public var loopEnd: Double

    /// Original tempo ratio (for ratio sync mode)
    public var originalTempoRatio: Double

    public init(
        id: UUID = UUID(),
        songId: String,
        songName: String,
        isPlaying: Bool = false,
        tempo: Double = 1.0,
        volume: Double = 0.8,
        isMuted: Bool = false,
        isSoloed: Bool = false,
        currentPosition: Double = 0.0,
        duration: Double = 0.0,
        loopEnabled: Bool = false,
        loopStart: Double = 0.0,
        loopEnd: Double = 0.0,
        originalTempoRatio: Double = 1.0
    ) {
        self.id = id
        self.songId = songId
        self.songName = songName
        self.isPlaying = isPlaying
        self.tempo = tempo
        self.volume = volume
        self.isMuted = isMuted
        self.isSoloed = isSoloed
        self.currentPosition = currentPosition
        self.duration = duration
        self.loopEnabled = loopEnabled
        self.loopStart = loopStart
        self.loopEnd = loopEnd
        self.originalTempoRatio = originalTempoRatio
    }
}

// =============================================================================
// MARK: - Sync Mode
// =============================================================================

/**
 How songs synchronize their tempos in the multi-song system.
 */
public enum SyncMode: String, Equatable, Codable, Sendable, CaseIterable {

    /// Each song has its own independent tempo
    case independent

    /// All songs locked to master tempo
    case locked

    /// Songs maintain tempo ratios relative to master
    case ratio

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .independent:
            return "Independent"
        case .locked:
            return "Locked"
        case .ratio:
            return "Ratio"
        }
    }

    /// Description for UI
    public var description: String {
        switch self {
        case .independent:
            return "Each song plays at its own tempo"
        case .locked:
            return "All songs synchronized to master tempo"
        case .ratio:
            return "Songs maintain tempo ratios"
        }
    }
}

// =============================================================================
// MARK: - Multi-Song Preset
// =============================================================================

/**
 A saved preset of multi-song configuration.

 Allows users to save and restore multi-song setups.
 */
public struct MultiSongPreset: Equatable, Codable, Sendable, Identifiable {

    /// Unique identifier
    public let id: UUID

    /// Preset name
    public var name: String

    /// When this preset was created
    public var createdAt: Date

    /// Multi-song state snapshot
    public var state: MultiSongState

    public init(
        id: UUID = UUID(),
        name: String,
        state: MultiSongState
    ) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.state = state
    }
}

// =============================================================================
// MARK: - Playback Statistics
// =============================================================================

/**
 Real-time statistics for multi-song playback performance.
 */
public struct MultiSongStatistics: Equatable, Sendable {

    /// Total number of active songs
    public var activeSongCount: Int

    /// Current CPU usage (0.0 to 1.0)
    public var cpuUsage: Double

    /// Current memory usage in bytes
    public var memoryUsage: Int

    /// Audio latency in milliseconds
    public var audioLatency: Double

    /// Current frame rate for UI
    public var uiFrameRate: Double

    public init(
        activeSongCount: Int = 0,
        cpuUsage: Double = 0.0,
        memoryUsage: Int = 0,
        audioLatency: Double = 0.0,
        uiFrameRate: Double = 60.0
    ) {
        self.activeSongCount = activeSongCount
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.audioLatency = audioLatency
        self.uiFrameRate = uiFrameRate
    }
}
