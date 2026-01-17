//
//  MarkerRepository.swift
//  SwiftFrontendShared
//
//  Repository pattern implementation for Marker CRUD operations
//  Thread-safe actor with GRDB integration
//

import Foundation
import GRDB

/// Repository for Marker CRUD operations
public actor MarkerRepository {
    private let db: DatabaseQueue

    public init(db: DatabaseQueue) {
        self.db = db
    }

    // MARK: - CRUD Operations

    /// Create a new marker
    public func create(_ marker: Marker) async throws {
        try await db.write { database in
            try database.execute(
                sql: """
                INSERT INTO markers (
                    id, performance_id, name, position_bars, position_beats,
                    color, note, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
                """,
                arguments: [
                    marker.id,
                    marker.performanceId,
                    marker.name,
                    marker.positionBars,
                    marker.positionBeats,
                    marker.color,
                    marker.note
                ]
            )
        }
    }

    /// Read a marker by ID
    public func read(id: String) async throws -> Marker? {
        try await db.read { database in
            if let row = try Row.fetchOne(
                database,
                sql: "SELECT * FROM markers WHERE id = ?",
                arguments: [id]
            ) {
                return try mapRowToMarker(row)
            }
            return nil
        }
    }

    /// Update an existing marker
    public func update(_ marker: Marker) async throws {
        try await db.write { database in
            try database.execute(
                sql: """
                UPDATE markers SET
                    performance_id = ?, name = ?, position_bars = ?, position_beats = ?,
                    color = ?, note = ?, updated_at = datetime('now')
                WHERE id = ?
                """,
                arguments: [
                    marker.performanceId,
                    marker.name,
                    marker.positionBars,
                    marker.positionBeats,
                    marker.color,
                    marker.note,
                    marker.id
                ]
            )
        }
    }

    /// Delete a marker by ID
    public func delete(id: String) async throws {
        try await db.write { database in
            try database.execute(
                sql: "DELETE FROM markers WHERE id = ?",
                arguments: [id]
            )
        }
    }

    // MARK: - Query Operations

    /// Get all markers for a performance
    public func getByPerformanceId(_ performanceId: String) async throws -> [Marker] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: """
                SELECT * FROM markers
                WHERE performance_id = ?
                ORDER BY position_bars, position_beats
                """,
                arguments: [performanceId]
            )
            return try rows.map { try mapRowToMarker($0) }
        }
    }

    /// Get all markers
    public func getAll() async throws -> [Marker] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT * FROM markers ORDER BY performance_id, position_bars, position_beats"
            )
            return try rows.map { try mapRowToMarker($0) }
        }
    }

    /// Get markers by color
    public func getByColor(_ color: String) async throws -> [Marker] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT * FROM markers WHERE color = ? ORDER BY performance_id, position_bars",
                arguments: [color]
            )
            return try rows.map { try mapRowToMarker($0) }
        }
    }

    /// Get markers by name pattern
    public func searchByName(query: String) async throws -> [Marker] {
        try await db.read { database in
            let searchPattern = "%\(query)%"
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT * FROM markers WHERE name LIKE ? ORDER BY performance_id, position_bars",
                arguments: [searchPattern]
            )
            return try rows.map { try mapRowToMarker($0) }
        }
    }

    /// Get markers within a position range
    public func getByPositionRange(
        performanceId: String,
        startBars: Int,
        endBars: Int
    ) async throws -> [Marker] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: """
                SELECT * FROM markers
                WHERE performance_id = ? AND position_bars BETWEEN ? AND ?
                ORDER BY position_bars, position_beats
                """,
                arguments: [performanceId, startBars, endBars]
            )
            return try rows.map { try mapRowToMarker($0) }
        }
    }

    /// Delete all markers for a performance
    public func deleteAllForPerformance(_ performanceId: String) async throws {
        try await db.write { database in
            try database.execute(
                sql: "DELETE FROM markers WHERE performance_id = ?",
                arguments: [performanceId]
            )
        }
    }

    /// Get marker count for a performance
    public func getCountForPerformance(_ performanceId: String) async throws -> Int {
        try await db.read { database in
            let count = try Int.fetchOne(
                database,
                sql: "SELECT COUNT(*) FROM markers WHERE performance_id = ?",
                arguments: [performanceId]
            )
            return count ?? 0
        }
    }

    // MARK: - Helper Methods

    /// Map database row to Marker model
    private func mapRowToMarker(_ row: Row) throws -> Marker {
        let id: String = row["id"]
        let performanceId: String = row["performance_id"]
        let name: String = row["name"]
        let positionBars: Int = row["position_bars"]
        let positionBeats: Int = row["position_beats"]
        let color: String = row["color"]
        let note: String? = row["note"]

        return Marker(
            id: id,
            performanceId: performanceId,
            name: name,
            positionBars: positionBars,
            positionBeats: positionBeats,
            color: color,
            note: note
        )
    }
}

// MARK: - Supporting Types

/// Marker model
public struct Marker: Codable, Identifiable {
    public let id: String
    public let performanceId: String
    public let name: String
    public let positionBars: Int
    public let positionBeats: Int
    public let color: String
    public let note: String?
}
