//
//  MultiSongPreset.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  Preset system for saving and restoring multi-song configurations
//  including master settings and individual song states.

import Foundation

/// A preset containing the complete state of a multi-song session
public struct MultiSongPreset: Codable, Sendable, Identifiable {

    // MARK: - Identity

    /// Unique identifier for this preset
    public let id: String

    /// Human-readable name
    public var name: String

    /// Optional description
    public var description: String?

    // MARK: - Metadata

    /// When this preset was created
    public let createdAt: Date

    /// When this preset was last modified
    public var lastModified: Date

    /// Preset version (for migration)
    public var version: Int

    /// User-defined tags
    public var tags: [String]

    /// Preview image data (optional, base64 encoded)
    public var previewImageData: Data?

    // MARK: - Master Settings

    /// Master transport settings
    public var masterSettings: MasterSettings

    // MARK: - Song States

    /// States of all song instances
    public var songStates: [PresetSongState]

    // MARK: - Sync Settings

    /// Sync mode state
    public var syncSettings: SyncSettings

    // MARK: - Additional Data

    /// Custom user data
    public var customData: [String: String]?

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        version: Int = 1,
        tags: [String] = [],
        previewImageData: Data? = nil,
        masterSettings: MasterSettings,
        songStates: [PresetSongState],
        syncSettings: SyncSettings,
        customData: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.version = version
        self.tags = tags
        self.previewImageData = previewImageData
        self.masterSettings = masterSettings
        self.songStates = songStates
        self.syncSettings = syncSettings
        self.customData = customData
    }

    // MARK: - Convenience Initializers

    /// Create preset from current master transport state
    public static func fromCurrentState(
        name: String,
        description: String? = nil,
        masterState: MasterTransportState,
        syncState: SyncModeState
    ) -> MultiSongPreset {
        MultiSongPreset(
            name: name,
            description: description,
            masterSettings: MasterSettings(from: masterState),
            songStates: masterState.songStates.map { PresetSongState(from: $0) },
            syncSettings: SyncSettings(from: syncState)
        )
    }

    // MARK: - Validation

    /// Validate preset data
    public func validate() -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Check name
        if name.isEmpty {
            errors.append("Preset name cannot be empty")
        }

        // Check master settings
        if masterSettings.tempo < 20 || masterSettings.tempo > 300 {
            warnings.append("Master tempo \(masterSettings.tempo) is outside normal range (20-300)")
        }

        if masterSettings.volume < 0 || masterSettings.volume > 1 {
            errors.append("Master volume must be between 0 and 1, got \(masterSettings.volume)")
        }

        // Check song states
        if songStates.isEmpty {
            warnings.append("Preset contains no songs")
        }

        for songState in songStates {
            if songState.tempo < 20 || songState.tempo > 300 {
                warnings.append("Song '\(songState.songName)' has unusual tempo: \(songState.tempo)")
            }

            if songState.volume < 0 || songState.volume > 1 {
                errors.append("Song '\(songState.songName)' has invalid volume: \(songState.volume)")
            }
        }

        // Check sync settings
        if songStates.count > 1 && syncSettings.syncMode == .independent {
            warnings.append("Multiple songs in independent mode may have tempo conflicts")
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Export

    /// Export preset as JSON data
    public func exportToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(self)
        } catch {
            throw PresetError.encodingFailed(error)
        }
    }

    /// Export preset as JSON string
    public func exportToJSONString() throws -> String {
        let data = try exportToJSON()
        guard let string = String(data: data, encoding: .utf8) else {
            throw PresetError.stringConversionFailed
        }
        return string
    }

    // MARK: - Import

    /// Import preset from JSON data
    public static func importFromJSON(_ data: Data) throws -> MultiSongPreset {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let preset = try decoder.decode(MultiSongPreset.self, from: data)
            return preset
        } catch let error as DecodingError {
            throw PresetError.decodingFailed(error)
        } catch {
            throw PresetError.importFailed(error)
        }
    }

    /// Import preset from JSON string
    public static func importFromJSONString(_ string: String) throws -> MultiSongPreset {
        guard let data = string.data(using: .utf8) else {
            throw PresetError.stringConversionFailed
        }
        return try importFromJSON(data)
    }
}

// MARK: - Master Settings

/// Master transport and mix settings
public struct MasterSettings: Codable, Sendable, Equatable {

    /// Master transport state
    public var transportState: TransportState

    /// Master tempo (BPM)
    public var tempo: Double

    /// Tempo multiplier
    public var tempoMultiplier: Double

    /// Master volume (0.0 to 1.0)
    public var volume: Double

    /// Init
    public init(
        transportState: TransportState = .stopped,
        tempo: Double = 120.0,
        tempoMultiplier: Double = 1.0,
        volume: Double = 1.0
    ) {
        self.transportState = transportState
        self.tempo = tempo
        self.tempoMultiplier = tempoMultiplier
        self.volume = volume
    }

    /// Init from MasterTransportState
    public init(from state: MasterTransportState) {
        self.transportState = state.transportState
        self.tempo = state.masterTempo
        self.tempoMultiplier = state.tempoMultiplier
        self.volume = state.masterVolume
    }
}

// MARK: - Preset Song State

/// State of a song in a preset
public struct PresetSongState: Codable, Sendable, Equatable, Identifiable {

    /// Unique instance ID
    public let id: String

    /// Song ID
    public var songId: String

    /// Song name (for display)
    public var songName: String

    /// Is this song active?
    public var isActive: Bool

    /// Song volume (0.0 to 1.0)
    public var volume: Double

    /// Song tempo (BPM)
    public var tempo: Double

    /// Optional: Song metadata snapshot
    public var metadata: SongMetadataSnapshot?

    /// Init
    public init(
        id: String,
        songId: String,
        songName: String,
        isActive: Bool,
        volume: Double,
        tempo: Double,
        metadata: SongMetadataSnapshot? = nil
    ) {
        self.id = id
        self.songId = songId
        self.songName = songName
        self.isActive = isActive
        self.volume = volume
        self.tempo = tempo
        self.metadata = metadata
    }

    /// Init from SongInstanceState
    public init(from state: SongInstanceState, songName: String = "") {
        self.id = state.id
        self.songId = state.songId
        self.songName = songName
        self.isActive = state.isActive
        self.volume = state.volume
        self.tempo = state.tempo
        self.metadata = nil
    }
}

/// Song metadata snapshot
public struct SongMetadataSnapshot: Codable, Sendable, Equatable {
    public var tempo: Double
    public var timeSignature: [Int]
    public var key: String?
    public var tags: [String]

    public init(
        tempo: Double,
        timeSignature: [Int],
        key: String? = nil,
        tags: [String] = []
    ) {
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.key = key
        self.tags = tags
    }
}

// MARK: - Sync Settings

/// Synchronization settings
public struct SyncSettings: Codable, Sendable, Equatable {

    /// Sync mode
    public var syncMode: SyncMode

    /// Baseline tempos for ratio mode
    public var baselineTempos: [String: Double]

    /// Tempo ratios
    public var tempoRatios: [String: Double]

    /// Smooth transitions enabled
    public var smoothTransitions: Bool

    /// Transition duration (seconds)
    public var transitionDuration: Double

    /// Init
    public init(
        syncMode: SyncMode = .independent,
        baselineTempos: [String: Double] = [:],
        tempoRatios: [String: Double] = [:],
        smoothTransitions: Bool = true,
        transitionDuration: Double = 0.5
    ) {
        self.syncMode = syncMode
        self.baselineTempos = baselineTempos
        self.tempoRatios = tempoRatios
        self.smoothTransitions = smoothTransitions
        self.transitionDuration = transitionDuration
    }

    /// Init from SyncModeState
    public init(from state: SyncModeState) {
        self.syncMode = state.syncMode
        self.baselineTempos = state.baselineTempos
        self.tempoRatios = state.tempoRatios
        self.smoothTransitions = state.smoothTransitions
        self.transitionDuration = state.transitionDuration
    }
}

// MARK: - Validation Result

/// Result of preset validation
public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]

    public var hasWarnings: Bool {
        !warnings.isEmpty
    }

    public var errorDescription: String? {
        errors.isEmpty ? nil : errors.joined(separator: "; ")
    }

    public var warningDescription: String? {
        warnings.isEmpty ? nil : warnings.joined(separator: "; ")
    }
}

// MARK: - Preset Error

/// Preset-related errors
public enum PresetError: Error, LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(DecodingError)
    case importFailed(Error)
    case stringConversionFailed
    case validationFailed([String])
    case fileNotFound(URL)
    case saveFailed(Error)
    case loadFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode preset: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode preset: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import preset: \(error.localizedDescription)"
        case .stringConversionFailed:
            return "Failed to convert string data"
        case .validationFailed(let errors):
            return "Preset validation failed: \(errors.joined(separator: ", "))"
        case .fileNotFound(let url):
            return "Preset file not found: \(url.path)"
        case .saveFailed(let error):
            return "Failed to save preset: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load preset: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preset Library

/// Manages a collection of presets
public struct PresetLibrary: Codable, Sendable {

    /// Library version
    public var version: Int

    /// All presets in library
    public var presets: [MultiSongPreset]

    /// Default preset IDs (in order)
    public var defaultPresetIds: [String]

    /// Init
    public init(
        version: Int = 1,
        presets: [MultiSongPreset] = [],
        defaultPresetIds: [String] = []
    ) {
        self.version = version
        self.presets = presets
        self.defaultPresetIds = defaultPresetIds
    }

    /// Get default presets
    public var defaultPresets: [MultiSongPreset] {
        presets.filter { defaultPresetIds.contains($0.id) }
    }

    /// Find preset by ID
    public func findPreset(id: String) -> MultiSongPreset? {
        presets.first { $0.id == id }
    }

    /// Search presets by name
    public func searchPresets(name query: String) -> [MultiSongPreset] {
        presets.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    /// Search presets by tag
    public func searchPresets(tag query: String) -> [MultiSongPreset] {
        presets.filter {
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// MARK: - Default Presets

/// Factory for creating default presets
public enum DefaultPresets {

    /// Create ambient preset
    public static func ambient() -> MultiSongPreset {
        MultiSongPreset(
            name: "Ambient Soundscape",
            description: "Slow, evolving textures for ambient music",
            masterSettings: MasterSettings(
                transportState: .playing,
                tempo: 60.0,
                tempoMultiplier: 1.0,
                volume: 0.8
            ),
            songStates: [],
            syncSettings: SyncSettings(
                syncMode: .locked,
                smoothTransitions: true,
                transitionDuration: 2.0
            ),
            customData: ["genre": "ambient", "mood": "calm"]
        )
    }

    /// Create techno preset
    public static func techno() -> MultiSongPreset {
        MultiSongPreset(
            name: "Techno Framework",
            description: "Four-on-the-floor beats and synthetic elements",
            masterSettings: MasterSettings(
                transportState: .playing,
                tempo: 130.0,
                tempoMultiplier: 1.0,
                volume: 0.9
            ),
            songStates: [],
            syncSettings: SyncSettings(
                syncMode: .locked,
                smoothTransitions: false,
                transitionDuration: 0.1
            ),
            customData: ["genre": "techno", "mood": "energetic"]
        )
    }

    /// Create orchestral preset
    public static func orchestral() -> MultiSongPreset {
        MultiSongPreset(
            name: "Orchestral Ensemble",
            description: "Full ensemble with natural tempo variation",
            masterSettings: MasterSettings(
                transportState: .playing,
                tempo: 90.0,
                tempoMultiplier: 1.0,
                volume: 0.85
            ),
            songStates: [],
            syncSettings: SyncSettings(
                syncMode: .ratio,
                smoothTransitions: true,
                transitionDuration: 1.0
            ),
            customData: ["genre": "orchestral", "mood": "dramatic"]
        )
    }

    /// Get all default presets
    public static func allDefaults() -> [MultiSongPreset] {
        [
            ambient(),
            techno(),
            orchestral()
        ]
    }
}
