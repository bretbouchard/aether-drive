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

// =============================================================================
// MARK: - Supporting Types
// =============================================================================

/**
 Type-erased Codable wrapper for storing any Codable value
 */
public struct CodableAny: Codable, Sendable {
    public let value: Any

    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    public init<T: Codable>(_ value: T) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "CodableAny value cannot be decoded"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "CodableAny value cannot be encoded"
                )
            )
        }
    }
}

/**
 Instrument projection for a performance
 */
public struct Projection: Codable, Sendable, Equatable {
    /// Projection type
    public let type: ProjectionType

    /// Instrument assignment
    public let instrumentId: String

    /// Volume/level for this projection
    public let level: Double

    /// Pan position (-1.0 to 1.0)
    public let pan: Double

    /// Effects applied
    public let effects: [String]

    public init(
        type: ProjectionType,
        instrumentId: String,
        level: Double = 1.0,
        pan: Double = 0.0,
        effects: [String] = []
    ) {
        self.type = type
        self.instrumentId = instrumentId
        self.level = level
        self.pan = pan
        self.effects = effects
    }

    public enum ProjectionType: String, Codable, Sendable {
        case direct
        case room
        case hall
        case plate
        case chamber
        case custom
    }
}
