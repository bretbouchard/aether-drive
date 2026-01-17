//
//  MixGraphRepository.swift
//  SwiftFrontendShared
//
//  Repository pattern implementation for MixGraph CRUD operations
//  Thread-safe actor with GRDB integration
//

import Foundation
import GRDB

/// Repository for MixGraph CRUD operations
public actor MixGraphRepository {
    private let db: DatabaseQueue

    public init(db: DatabaseQueue) {
        self.db = db
    }

    // MARK: - CRUD Operations

    /// Create a new mix graph for a song
    public func create(_ mixGraph: MixGraph) async throws {
        try await db.write { database in
            let tracksJSON = try JSONEncoder().encode(mixGraph.tracks)
            let busesJSON = try JSONEncoder().encode(mixGraph.buses)
            let sendsJSON = try JSONEncoder().encode(mixGraph.sends)
            let masterJSON = try JSONEncoder().encode(mixGraph.master)

            try database.execute(
                sql: """
                INSERT INTO mix_graphs (
                    id, song_id, tracks_json, buses_json, sends_json, master_json,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
                """,
                arguments: [
                    mixGraph.id,
                    mixGraph.songId,
                    String(data: tracksJSON, encoding: .utf8),
                    String(data: busesJSON, encoding: .utf8),
                    String(data: sendsJSON, encoding: .utf8),
                    String(data: masterJSON, encoding: .utf8)
                ]
            )
        }
    }

    /// Read a mix graph by song ID
    public func read(songId: String) async throws -> MixGraph? {
        try await db.read { database in
            if let row = try Row.fetchOne(
                database,
                sql: "SELECT * FROM mix_graphs WHERE song_id = ?",
                arguments: [songId]
            ) {
                return try mapRowToMixGraph(row)
            }
            return nil
        }
    }

    /// Update an existing mix graph
    public func update(_ mixGraph: MixGraph) async throws {
        try await db.write { database in
            let tracksJSON = try JSONEncoder().encode(mixGraph.tracks)
            let busesJSON = try JSONEncoder().encode(mixGraph.buses)
            let sendsJSON = try JSONEncoder().encode(mixGraph.sends)
            let masterJSON = try JSONEncoder().encode(mixGraph.master)

            try database.execute(
                sql: """
                UPDATE mix_graphs SET
                    tracks_json = ?, buses_json = ?, sends_json = ?, master_json = ?,
                    updated_at = datetime('now')
                WHERE id = ?
                """,
                arguments: [
                    String(data: tracksJSON, encoding: .utf8),
                    String(data: busesJSON, encoding: .utf8),
                    String(data: sendsJSON, encoding: .utf8),
                    String(data: masterJSON, encoding: .utf8),
                    mixGraph.id
                ]
            )
        }
    }

    /// Delete a mix graph by song ID
    public func delete(songId: String) async throws {
        try await db.write { database in
            try database.execute(
                sql: "DELETE FROM mix_graphs WHERE song_id = ?",
                arguments: [songId]
            )
        }
    }

    // MARK: - Query Operations

    /// Get all mix graphs
    public func getAll() async throws -> [MixGraph] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT * FROM mix_graphs ORDER BY created_at DESC"
            )
            return try rows.map { try mapRowToMixGraph($0) }
        }
    }

    /// Get recently updated mix graphs
    public func getRecentlyUpdated(limit: Int = 20) async throws -> [MixGraph] {
        try await db.read { database in
            let rows = try Row.fetchAll(
                database,
                sql: "SELECT * FROM mix_graphs ORDER BY updated_at DESC LIMIT ?",
                arguments: [limit]
            )
            return try rows.map { try mapRowToMixGraph($0) }
        }
    }

    /// Get mix graphs with track count
    public func getByTrackCount(minTracks: Int, maxTracks: Int) async throws -> [MixGraph] {
        try await db.read { database in
            let allGraphs = try getAll()
            return allGraphs.filter { graph in
                let trackCount = graph.tracks.count
                return trackCount >= minTracks && trackCount <= maxTracks
            }
        }
    }

    /// Get mix graphs using specific bus
    public func getByBusName(_ busName: String) async throws -> [MixGraph] {
        try await db.read { database in
            let allGraphs = try getAll()
            return allGraphs.filter { graph in
                graph.buses.contains { $0.name == busName }
            }
        }
    }

    // MARK: - Helper Methods

    /// Map database row to MixGraph model
    private func mapRowToMixGraph(_ row: Row) throws -> MixGraph {
        let id: String = row["id"]
        let songId: String = row["song_id"]

        // Decode JSON columns
        let tracksJSON: String = row["tracks_json"]
        let busesJSON: String = row["buses_json"]
        let sendsJSON: String = row["sends_json"]
        let masterJSON: String = row["master_json"]

        let tracks = try JSONDecoder().decode([MixTrack].self, from: tracksJSON.data(using: .utf8)!)
        let buses = try JSONDecoder().decode([MixBus].self, from: busesJSON.data(using: .utf8)!)
        let sends = try JSONDecoder().decode([MixSend].self, from: sendsJSON.data(using: .utf8)!)
        let master = try JSONDecoder().decode(MixMaster.self, from: masterJSON.data(using: .utf8)!)

        return MixGraph(
            id: id,
            songId: songId,
            tracks: tracks,
            buses: buses,
            sends: sends,
            master: master
        )
    }
}

// MARK: - Supporting Types

/// Mix graph model
public struct MixGraph: Codable, Identifiable {
    public let id: String
    public let songId: String
    public let tracks: [MixTrack]
    public let buses: [MixBus]
    public let sends: [MixSend]
    public let master: MixMaster
}

/// Mix track
public struct MixTrack: Codable, Identifiable {
    public let id: String
    public let name: String
    public let volume: Double
    public let pan: Double
    public let muted: Bool
    public let solo: Bool
    public let busId: String?
    public let instrumentId: String?
}

/// Mix bus
public struct MixBus: Codable, Identifiable {
    public let id: String
    public let name: String
    public let volume: Double
    public let pan: Double
    public let muted: Bool
}

/// Mix send
public struct MixSend: Codable, Identifiable {
    public let id: String
    public let fromTrackId: String
    public let toBusId: String
    public let amount: Double
}

/// Mix master
public struct MixMaster: Codable {
    public let volume: Double
    public let busId: String?
}
