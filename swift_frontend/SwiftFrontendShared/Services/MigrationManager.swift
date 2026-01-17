//
//  MigrationManager.swift
//  White Room
//
//  Created by White Room Development Team
//  Copyright © 2024 White Room. All rights reserved.
//

import Foundation
import GRDB

/// Database migration manager for schema versioning and migrations.
///
/// Handles incremental schema changes with automatic version tracking and rollback support.
///
/// **Usage:**
/// ```swift
/// let migrationManager = MigrationManager()
/// try migrationManager.migrate(database)
/// ```
public actor MigrationManager {

    // MARK: - Migration Definition

    /// Defines a single database migration
    public struct Migration: Sendable {
        /// Unique version number (must be sequential)
        public let version: Int

        /// Human-readable description
        public let description: String

        /// Migration logic to execute
        public let migrate: (Database) throws -> Void

        /// Optional rollback logic
        public let rollback: ((Database) throws -> Void)?

        public init(
            version: Int,
            description: String,
            migrate: @escaping (Database) throws -> Void,
            rollback: ((Database) throws -> Void)? = nil
        ) {
            self.version = version
            self.description = description
            self.migrate = migrate
            self.rollback = rollback
        }
    }

    // MARK: - Properties

    /// All registered migrations in version order
    private let migrations: [Migration]

    // MARK: - Initialization

    /// Initialize with all migrations
    public init() {
        self.migrations = Self.registerMigrations()
    }

    // MARK: - Public API

    /// Run all pending migrations on the database
    ///
    /// This method:
    /// 1. Checks current schema version from metadata table
    /// 2. Identifies pending migrations
    /// 3. Executes each migration in a transaction
    /// 4. Updates schema version after successful migration
    ///
    /// - Parameter database: GRDB Database instance
    /// - Throws: Database errors if migration fails
    public func migrate(_ database: Database) throws {
        // Get current version
        let currentVersion = try getSchemaVersion(database: database)
        print("[MigrationManager] Current schema version: \(currentVersion)")

        // Filter migrations that need to run
        let pendingMigrations = migrations.filter { $0.version > currentVersion }

        guard !pendingMigrations.isEmpty else {
            print("[MigrationManager] Database is up to date")
            return
        }

        print("[MigrationManager] Found \(pendingMigrations.count) pending migration(s)")

        // Run each migration in order
        for migration in pendingMigrations {
            print("[MigrationManager] Running migration v\(migration.version): \(migration.description)")

            do {
                try runMigration(database: database, migration: migration)
                print("[MigrationManager] Migration v\(migration.version) completed successfully")
            } catch {
                print("[MigrationManager] Migration v\(migration.version) failed: \(error)")
                throw DatabaseError.migrationFailed("Migration v\(migration.version): \(migration.description)")
            }
        }

        let finalVersion = pendingMigrations.map { $0.version }.max() ?? currentVersion
        print("[MigrationManager] Migration complete. New schema version: \(finalVersion)")
    }

    /// Rollback to a specific schema version
    ///
    /// **WARNING:** This will lose data if rolling back past schema changes.
    ///
    /// - Parameters:
    ///   - database: GRDB Database instance
    ///   - targetVersion: Version to rollback to
    /// - Throws: Database errors if rollback fails
    public func rollback(_ database: Database, to targetVersion: Int) throws {
        let currentVersion = try getSchemaVersion(database: database)

        guard currentVersion > targetVersion else {
            print("[MigrationManager] Already at version \(targetVersion) or lower")
            return
        }

        print("[MigrationManager] Rolling back from v\(currentVersion) to v\(targetVersion)")

        // Get migrations to rollback (in reverse order)
        let migrationsToRollback = migrations
            .filter { $0.version > targetVersion && $0.version <= currentVersion }
            .sorted { $0.version > $1.version }

        guard !migrationsToRollback.isEmpty else {
            print("[MigrationManager] No migrations to rollback")
            return
        }

        // Run each rollback
        for migration in migrationsToRollback {
            guard let rollback = migration.rollback else {
                throw DatabaseError.migrationFailed("Migration v\(migration.version) does not support rollback")
            }

            print("[MigrationManager] Rolling back migration v\(migration.version): \(migration.description)")

            do {
                try rollback(database)
                try updateSchemaVersion(database: database, version: migration.version - 1)
                print("[MigrationManager] Rollback v\(migration.version) completed")
            } catch {
                print("[MigrationManager] Rollback v\(migration.version) failed: \(error)")
                throw DatabaseError.migrationFailed("Rollback v\(migration.version) failed")
            }
        }

        print("[MigrationManager] Rollback complete. New schema version: \(targetVersion)")
    }

    // MARK: - Private Methods

    /// Execute a single migration in a transaction
    ///
    /// - Parameters:
    ///   - database: GRDB Database instance
    ///   - migration: Migration to execute
    /// - Throws: Database errors if migration fails
    private func runMigration(database: Database, migration: Migration) throws {
        // Begin transaction
        try database.beginTransaction()

        do {
            // Execute migration
            try migration.migrate(database)

            // Update schema version
            try updateSchemaVersion(database: database, version: migration.version)

            // Commit transaction
            try database.commit()
        } catch {
            // Rollback on error
            try database.rollback()
            throw error
        }
    }

    /// Get current schema version from metadata table
    ///
    /// - Parameter database: GRDB Database instance
    /// - Returns: Current schema version (0 if not set)
    /// - Throws: Database errors if query fails
    private func getSchemaVersion(database: Database) throws -> Int {
        guard let versionString = try String.fetchOne(
            database,
            sql: "SELECT value FROM metadata WHERE key = 'schema_version'"
        ) else {
            return 0
        }

        return Int(versionString) ?? 0
    }

    /// Update schema version in metadata table
    ///
    /// - Parameters:
    ///   - database: GRDB Database instance
    ///   - version: New schema version
    /// - Throws: Database errors if update fails
    private func updateSchemaVersion(database: Database, version: Int) throws {
        try database.execute(
            sql: """
            INSERT OR REPLACE INTO metadata (key, value, updated_at)
            VALUES ('schema_version', ?, datetime('now'))
            """,
            arguments: [String(version)]
        )
    }

    // MARK: - Migration Registry

    /// Register all migrations in order
    ///
    /// **IMPORTANT:** Add new migrations here with sequential version numbers
    ///
    /// - Returns: Array of all migrations
    private static func registerMigrations() -> [Migration] {
        return [
            // Migration 1: Initial schema
            Migration(
                version: 1,
                description: "Initial schema with all 9 tables (songs, performances, user_preferences, roles, sections, autosaves, backups, mix_graphs, markers)"
            ) { db in
                // Execute schema.sql file
                try executeSchemaFile(database: db)
            },

            // Migration 2: Add instrumentId, voiceId, presetId to TrackConfig (in mix_graph_json)
            Migration(
                version: 2,
                description: "Add instrumentId, voiceId, presetId fields to songs.mix_graph_json for TrackConfig objects"
            ) { db in
                // This is a data migration - update existing mix_graph_json to include new fields
                // For now, this is a no-op since the schema already includes these fields
                // Future versions will add ALTER TABLE statements if needed
                print("[MigrationManager] Migration v2: instrumentId/voiceId/presetId already in schema")
            },

            // TODO: Add future migrations here
            //
            // Migration(
            //     version: 3,
            //     description: "Add full-text search indexes"
            // ) { db in
            //     try db.execute(sql: "CREATE VIRTUAL TABLE IF NOT EXISTS songs_fts USING fts5(name, composer, genre)")
            // }
        ]
    }

    /// Execute schema.sql file
    ///
    /// - Parameter database: GRDB Database instance
    /// - Throws: Database errors if schema execution fails
    private static func executeSchemaFile(database: Database) throws {
        // Try multiple paths for schema.sql
        let possiblePaths = [
            Bundle.module.path(forResource: "schema", ofType: "sql"),
            Bundle.main.path(forResource: "schema", ofType: "sql"),
            // Fallback to project-relative path
            URL(fileURLWithPath: "\(ProcessInfo.processInfo.environment["PROJECT_ROOT"] ?? ".")/juce_backend/shared/persistence/schema.sql").path
        ].compactMap { $0 }

        guard let schemaPath = possiblePaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw DatabaseError.schemaFileNotFound
        }

        print("[MigrationManager] Executing schema file: \(schemaPath)")

        // Read schema file
        let schemaSQL = try String(contentsOfFile: schemaPath, encoding: .utf8)

        // Execute schema
        try database.execute(sql: schemaSQL)

        print("[MigrationManager] Schema file executed successfully")
    }
}

// MARK: - Migration Logging

extension MigrationManager {

    /// Get list of all registered migrations
    ///
    /// - Returns: Array of migration descriptions
    public func allMigrations() -> [(version: Int, description: String)] {
        return migrations.map { ($0.version, $0.description) }
    }

    /// Get pending migrations (not yet applied)
    ///
    /// - Parameter database: GRDB Database instance
    /// - Returns: Array of pending migrations
    /// - Throws: Database errors if version check fails
    public func pendingMigrations(_ database: Database) throws -> [(version: Int, description: String)] {
        let currentVersion = try getSchemaVersion(database: database)
        return migrations
            .filter { $0.version > currentVersion }
            .map { ($0.version, $0.description) }
    }
}

// MARK: - Validation

extension MigrationManager {

    /// Validate that all migrations can run without errors
    ///
    /// This is useful for testing migrations before deployment.
    ///
    /// - Parameter database: GRDB Database instance
    /// - Returns: true if all migrations are valid
    public func validateMigrations(_ database: Database) -> Bool {
        print("[MigrationManager] Validating migrations...")

        for migration in migrations {
            do {
                // Begin test transaction
                try database.beginTransaction()

                // Run migration
                try migration.migrate(database)

                // Rollback (don't actually apply)
                try database.rollback()

                print("[MigrationManager] ✓ Migration v\(migration.version): \(migration.description)")
            } catch {
                print("[MigrationManager] ✗ Migration v\(migration.version) failed: \(error)")
                return false
            }
        }

        print("[MigrationManager] All migrations validated successfully")
        return true
    }
}
