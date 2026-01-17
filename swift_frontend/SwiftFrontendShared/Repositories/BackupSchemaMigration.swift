//
//  BackupSchemaMigration.swift
//  SwiftFrontendShared
//
//  Database migration for backup system tables
//

import Foundation
import GRDB

/// Database migration for backup system
public struct BackupSchemaMigration {

    /// Run migration to create backup tables
    public static func migrate(_ db: DatabaseQueue) throws {
        try db.write { database in
            // Create backups table
            try database.execute(
                sql: """
                CREATE TABLE IF NOT EXISTS backups (
                    id TEXT PRIMARY KEY,
                    timestamp TEXT NOT NULL,
                    description TEXT NOT NULL,
                    songs_json TEXT NOT NULL,
                    performances_json TEXT NOT NULL,
                    preferences_json TEXT NOT NULL,
                    size INTEGER NOT NULL,
                    version TEXT NOT NULL,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );

                CREATE INDEX IF NOT EXISTS idx_backups_timestamp ON backups(timestamp);
                CREATE INDEX IF NOT EXISTS idx_backups_version ON backups(version);
                """
            )

            // Create song_data table
            try database.execute(
                sql: """
                CREATE TABLE IF NOT EXISTS song_data (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    composer TEXT,
                    description TEXT,
                    genre TEXT,
                    duration REAL,
                    key TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    song_data_json TEXT NOT NULL,
                    determinism_seed TEXT NOT NULL,
                    custom_metadata TEXT
                );

                CREATE INDEX IF NOT EXISTS idx_song_data_name ON song_data(name);
                CREATE INDEX IF NOT EXISTS idx_song_data_composer ON song_data(composer);
                CREATE INDEX IF NOT EXISTS idx_song_data_created_at ON song_data(created_at);
                """
            )

            // Create performance_data table
            try database.execute(
                sql: """
                CREATE TABLE IF NOT EXISTS performance_data (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    song_id TEXT NOT NULL,
                    description TEXT,
                    duration REAL NOT NULL,
                    performance_data_json TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    is_favorite INTEGER DEFAULT 0,
                    tags TEXT
                );

                CREATE INDEX IF NOT EXISTS idx_performance_data_name ON performance_data(name);
                CREATE INDEX IF NOT EXISTS idx_performance_data_song_id ON performance_data(song_id);
                CREATE INDEX IF NOT EXISTS idx_performance_data_created_at ON performance_data(created_at);
                """
            )

            // Create user_preferences table
            try database.execute(
                sql: """
                CREATE TABLE IF NOT EXISTS user_preferences (
                    user_id TEXT PRIMARY KEY,
                    display_name TEXT,
                    default_output_device TEXT,
                    default_input_device TEXT,
                    default_sample_rate INTEGER,
                    default_buffer_size INTEGER,
                    auto_save_enabled INTEGER DEFAULT 1,
                    auto_save_interval INTEGER DEFAULT 300,
                    auto_backup_enabled INTEGER DEFAULT 1,
                    backup_interval_hours INTEGER DEFAULT 24,
                    max_backups INTEGER DEFAULT 30,
                    theme TEXT,
                    language TEXT,
                    show_tooltips INTEGER DEFAULT 1,
                    custom_preferences TEXT,
                    updated_at TEXT NOT NULL
                );
                """
            )

            print("Backup schema migration completed successfully")
        }
    }

    /// Rollback migration (drop backup tables)
    public static func rollback(_ db: DatabaseQueue) throws {
        try db.write { database in
            try database.execute(sql: "DROP TABLE IF EXISTS backups")
            try database.execute(sql: "DROP TABLE IF EXISTS song_data")
            try database.execute(sql: "DROP TABLE IF EXISTS performance_data")
            try database.execute(sql: "DROP TABLE IF EXISTS user_preferences")
            print("Backup schema rollback completed successfully")
        }
    }

    /// Check if migration is needed
    public static func isMigrationNeeded(_ db: DatabaseQueue) -> Bool {
        do {
            try db.read { database in
                try database.execute(sql: "SELECT 1 FROM backups LIMIT 1")
            }
            return false
        } catch {
            return true
        }
    }
}
