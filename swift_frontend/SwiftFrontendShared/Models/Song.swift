/**
 * Song Model
 *
 * Represents a musical composition with sections, roles, and audio routing.
 * Based on SongModel_v2 from the SDK.
 */

import Foundation

/// Musical composition
public struct Song: Codable, Sendable, Identifiable {
    /// Unique identifier
    public let id: String

    /// Song title
    public let name: String

    /// Composer name
    public let composer: String?

    /// Song description
    public let songDescription: String?

    /// Musical genre
    public let genre: String?

    /// Song duration in seconds
    public let duration: Double?

    /// Musical key
    public let key: String?

    /// Creation timestamp
    public let createdAt: Date

    /// Last modification timestamp
    public let updatedAt: Date

    /// Song data as JSON (SongModel_v2)
    public let songDataJSON: String

    /// Determinism seed for realization
    public let determinismSeed: String

    /// Custom metadata
    public let customMetadata: [String: String]?

    public init(
        id: String,
        name: String,
        composer: String? = nil,
        songDescription: String? = nil,
        genre: String? = nil,
        duration: Double? = nil,
        key: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        songDataJSON: String,
        determinismSeed: String,
        customMetadata: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.composer = composer
        self.songDescription = songDescription
        self.genre = genre
        self.duration = duration
        self.key = key
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.songDataJSON = songDataJSON
        self.determinismSeed = determinismSeed
        self.customMetadata = customMetadata
    }

    /// Coding keys for JSON serialization
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case composer
        case songDescription = "description"
        case genre
        case duration
        case key
        case createdAt
        case updatedAt
        case songDataJSON = "song_data_json"
        case determinismSeed = "determinism_seed"
        case customMetadata = "custom_metadata"
    }
}
