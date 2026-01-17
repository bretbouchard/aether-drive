/**
 * Performance Model
 *
 * Represents a recorded performance or realization of a song.
 */

import Foundation

/// Recorded performance
public struct Performance: Codable, Sendable, Identifiable {
    /// Unique identifier
    public let id: String

    /// Performance name
    public var name: String

    /// Associated song ID
    public let songId: String

    /// Performance description
    public var description: String?

    /// Performance duration in seconds
    public let duration: Double

    /// Performance data as JSON (realized events)
    public let performanceDataJSON: String

    /// Creation timestamp
    public let createdAt: Date

    /// Last modification timestamp
    public var updatedAt: Date

    /// Whether this performance is a favorite
    public var isFavorite: Bool

    /// Performance tags
    public var tags: [String]

    /// Whether this performance is active
    public var active: Bool

    /// Performance parameters (key-value pairs)
    public var parameters: [String: CodableAny]

    /// Performance projections (role ID -> projection)
    public var projections: [String: Projection]

    public init(
        id: String,
        name: String,
        songId: String,
        description: String? = nil,
        duration: Double,
        performanceDataJSON: String,
        createdAt: Date,
        updatedAt: Date,
        isFavorite: Bool = false,
        tags: [String] = [],
        active: Bool = true,
        parameters: [String: CodableAny] = [:],
        projections: [String: Projection] = [:]
    ) {
        self.id = id
        self.name = name
        self.songId = songId
        self.description = description
        self.duration = duration
        self.performanceDataJSON = performanceDataJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.tags = tags
        self.active = active
        self.parameters = parameters
        self.projections = projections
    }

    /// Coding keys for JSON serialization
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case songId = "song_id"
        case description
        case duration
        case performanceDataJSON = "performance_data_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isFavorite = "is_favorite"
        case tags
        case active
        case parameters
        case projections
    }
}
