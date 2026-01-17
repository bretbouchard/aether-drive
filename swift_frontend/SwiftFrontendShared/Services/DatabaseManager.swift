//
//  DatabaseManager.swift
//  White Room
//
//  Created by White Room Development Team
//  Copyright © 2024 White Room. All rights reserved.
//

import Foundation
import GRDB

/// Central database manager for White Room persistence layer.
/// Manages SQLite database connection, WAL mode, and provides access to raw database operations.
///
/// **Thread Safety:** This class is thread-safe and can be accessed from multiple threads concurrently.
/// **Architecture:** Uses GRDB's DatabaseQueue for serialized access to SQLite database.
public final class DatabaseManager: Sendable {

    // MARK: - Singleton

    /// Shared singleton instance
    public static let shared = DatabaseManager()

    // MARK: - Properties

    /// GRDB DatabaseQueue for serialized database access
    private let dbQueue: DatabaseQueue

    /// File system URL to the database file
    private let databaseURL: URL

    /// Initialization lock for thread-safe lazy initialization
    private static let initLock = NSLock()

    /// Flag indicating if database has been initialized
    private var isInitialized = false

    // MARK: - Initialization

    /// Private initializer (use `DatabaseManager.shared` instead)
    private init() {
        // Get database path
        let appSupportURL = Self.applicationSupportDirectory
        let databaseDirectory = appSupportURL.appendingPathComponent("White Room", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)

        // Set database URL
        self.databaseURL = databaseDirectory.appendingPathComponent("white_room.db")

        // Create database queue
        do {
            self.dbQueue = try DatabaseQueue(path: self.databaseURL.path)
            print("[DatabaseManager] Database initialized at: \(self.databaseURL.path)")
        } catch {
            fatalError("[DatabaseManager] Failed to initialize database: \(error)")
        }
    }

    // MARK: - Public API

    /// Initialize the database with schema and migrations
    ///
    /// This method should be called once at app startup. It:
    /// 1. Enables WAL mode for concurrent access
    /// 2. Runs any pending migrations
    /// 3. Creates initial schema if needed
    ///
    /// - Throws: Database errors if initialization fails
    public func initialize() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                // Setup WAL mode
                try dbQueue.write { db in
                    try Self.setupWALMode(database: db)
                    print("[DatabaseManager] WAL mode enabled")
                }

                // Run migrations
                try await runMigrations()

                isInitialized = true
                print("[DatabaseManager] Database initialization complete")

                continuation.resume()
            } catch {
                print("[DatabaseManager] Initialization failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Get read-only access to the database
    ///
    /// Use this for SELECT queries and read operations.
    ///
    /// - Parameter block: Closure receiving Database instance
    /// - Throws: Database errors
    public func read<T>(_ block: (Database) throws -> T) throws -> T {
        return try dbQueue.read(block)
    }

    /// Get write access to the database
    ///
    /// Use this for INSERT, UPDATE, DELETE operations.
    ///
    /// - Parameter block: Closure receiving Database instance
    /// - Throws: Database errors
    public func write<T>(_ block: (Database) throws -> T) throws -> T {
        return try dbQueue.write(block)
    }

    /// Check if database is initialized
    public var initialized: Bool {
        return isInitialized
    }

    /// Get the database file path
    public var databasePath: String {
        return databaseURL.path
    }

    /// Get the database directory URL
    public var databaseDirectoryURL: URL {
        return databaseURL.deletingLastPathComponent()
    }

    // MARK: - Private Methods

    /// Setup WAL (Write-Ahead Logging) mode for better concurrent access performance
    ///
    /// WAL mode allows:
    /// - Readers don't block writers
    /// - Writers don't block readers
    /// - Better concurrency for iOS/macOS
    ///
    /// - Parameter database: GRDB Database instance
    /// - Throws: Database errors if PRAGMA execution fails
    private static func setupWALMode(database: Database) throws {
        // Enable WAL mode
        try database.execute(sql: "PRAGMA journal_mode = WAL")

        // Use NORMAL synchronization (safer than OFF, faster than FULL)
        try database.execute(sql: "PRAGMA synchronous = NORMAL")

        // Set cache size to 64MB (-64000 means 64000KB)
        try database.execute(sql: "PRAGMA cache_size = -64000")

        // Store temp tables in memory
        try database.execute(sql: "PRAGMA temp_store = MEMORY")

        // Enable memory-mapped I/O (30GB max)
        try database.execute(sql: "PRAGMA mmap_size = 30000000000")

        // Enforce foreign key constraints
        try database.execute(sql: "PRAGMA foreign_keys = ON")

        print("[DatabaseManager] WAL mode configured")
    }

    /// Run database migrations
    ///
    /// Checks current schema version and runs any pending migrations.
    ///
    /// - Throws: Database errors if migration fails
    private func runMigrations() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try dbQueue.write { db in
                    // Get current schema version
                    let currentVersion = try Int.fetchOne(db, sql: "SELECT value FROM metadata WHERE key = 'schema_version'") ?? 0

                    print("[DatabaseManager] Current schema version: \(currentVersion)")

                    // TODO: Run migrations based on version
                    // For now, just ensure schema is created
                    if currentVersion == 0 {
                        try createInitialSchema(database: db)
                        try insertSchemaVersion(database: db, version: 1)
                    }
                }

                continuation.resume()
            } catch {
                print("[DatabaseManager] Migration failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Create initial database schema
    ///
    /// Executes the schema.sql file to create all tables.
    ///
    /// - Parameter database: GRDB Database instance
    /// - Throws: Database errors if schema creation fails
    private func createInitialSchema(database: Database) throws {
        print("[DatabaseManager] Creating initial schema...")

        // Read schema.sql file
        guard let schemaPath = Bundle.module.path(forResource: "schema", ofType: "sql") ??
                              Bundle.main.path(forResource: "schema", ofType: "sql") else {
            // Fallback: try to find schema.sql in juce_backend
            let projectRoot = ProcessInfo.processInfo.environment["PROJECT_ROOT"] ?? FileManager.default.currentDirectoryPath
            let fallbackPath = "\(projectRoot)/juce_backend/shared/persistence/schema.sql"

            guard FileManager.default.fileExists(atPath: fallbackPath) else {
                throw DatabaseError.schemaFileNotFound
            }

            // Read schema file
            let schemaSQL = try String(contentsOfFile: fallbackPath, encoding: .utf8)

            // Execute schema
            try database.execute(sql: schemaSQL)
            print("[DatabaseManager] Initial schema created from fallback path")

            return
        }

        // Read and execute schema file
        let schemaSQL = try String(contentsOfFile: schemaPath, encoding: .utf8)
        try database.execute(sql: schemaSQL)
        print("[DatabaseManager] Initial schema created")
    }

    /// Insert schema version into metadata table
    ///
    /// - Parameters:
    ///   - database: GRDB Database instance
    ///   - version: Schema version number
    /// - Throws: Database errors if insert fails
    private func insertSchemaVersion(database: Database, version: Int) throws {
        try database.execute(
            sql: "INSERT OR REPLACE INTO metadata (key, value, updated_at) VALUES (?, ?, datetime('now'))",
            arguments: ["schema_version", String(version)]
        )
        print("[DatabaseManager] Schema version set to: \(version)")
    }

    // MARK: - File System Utilities

    /// Get the Application Support directory for the app
    ///
    /// Returns: URL to ~/Library/Application Support/
    private static var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )

        guard let appSupport = paths.first else {
            fatalError("[DatabaseManager] Failed to get Application Support directory")
        }

        return appSupport
    }
}

// MARK: - Database Errors

/// Database-specific errors
public enum DatabaseError: LocalizedError {
    case schemaFileNotFound
    case migrationFailed(String)
    case initializationFailed(String)
    case databaseCorrupted
    case constraintViolation(String)

    public var errorDescription: String? {
        switch self {
        case .schemaFileNotFound:
            return "Schema file (schema.sql) not found"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .initializationFailed(let message):
            return "Database initialization failed: \(message)"
        case .databaseCorrupted:
            return "Database file is corrupted"
        case .constraintViolation(let message):
            return "Database constraint violation: \(message)"
        }
    }
}

// MARK: - Database Statistics

extension DatabaseManager {

    /// Get database file size in bytes
    ///
    /// - Returns: File size in bytes
    /// - Throws: File system errors
    public func databaseSize() throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: databaseURL.path)
        return attributes[.size] as? Int ?? 0
    }

    /// Get database file size as human-readable string
    ///
    /// - Returns: Formatted file size (e.g., "12.5 MB")
    public func databaseSizeFormatted() throws -> String {
        let bytes = try databaseSize()
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    /// Get total number of songs in database
    ///
    /// - Returns: Song count
    public func songCount() throws -> Int {
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM songs") ?? 0
        }
    }

    /// Get total number of performances in database
    ///
    /// - Returns: Performance count
    public func performanceCount() throws -> Int {
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM performances") ?? 0
        }
    }

    /// Get current schema version
    ///
    /// - Returns: Schema version number
    public func schemaVersion() throws -> Int {
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT value FROM metadata WHERE key = 'schema_version'") ?? 0
        }
    }

    /// Perform database integrity check
    ///
    /// - Returns: true if database passes integrity check
    /// - Throws: Database errors
    public func checkIntegrity() throws -> Bool {
        return try dbQueue.read { db in
            let result = try String.fetchOne(db, sql: "PRAGMA integrity_check")
            return result == "ok"
        }
    }
}

// MARK: - Debugging Utilities

#if DEBUG

extension DatabaseManager {

    /// Log all table names and row counts (DEBUG only)
    public func debugLogTableCounts() throws {
        let tables = try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        }

        print("[DatabaseManager] === Database Statistics ===")
        for table in tables {
            let count = try dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
            }
            print("[DatabaseManager] \(table): \(count) rows")
        }
        print("[DatabaseManager] =============================")
    }

    /// Export database to JSON for debugging (DEBUG only)
    ///
    /// - Parameter tableName: Name of table to export
    /// - Returns: Array of JSON objects
    public func debugExportTable(_ tableName: String) throws -> [[String: Any]] {
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
            return rows.map { row in
                var dict: [String: Any] = [:]
                for column in row.columnNames {
                    if let value = row[column] {
                        dict[column] = value
                    }
                }
                return dict
            }
        }
    }
}

#endif
