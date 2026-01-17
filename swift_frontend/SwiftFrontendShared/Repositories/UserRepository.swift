//
//  UserRepository.swift
//  SwiftFrontendShared
//
//  Repository pattern implementation for UserPreferences CRUD operations
//  Thread-safe actor with GRDB integration
//

import Foundation
import GRDB

/// Repository for UserPreferences CRUD operations
public actor UserRepository {
    private let db: DatabaseQueue

    public init(db: DatabaseQueue) {
        self.db = db
    }

    // MARK: - CRUD Operations

    /// Create or update user preferences
    public func create(_ preferences: UserPreferences) async throws {
        try await db.write { database in
            let audioSettingsJSON = try JSONEncoder().encode(preferences.audioSettings)
            let uiSettingsJSON = try JSONEncoder().encode(preferences.uiSettings)
            let themeSettingsJSON = try JSONEncoder().encode(preferences.themeSettings)

            try database.execute(
                sql: """
                INSERT INTO user_preferences (
                    id, audio_device_id, master_volume, buffer_size,
                    audio_settings_json, ui_settings_json, theme_settings_json,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
                """,
                arguments: [
                    preferences.id,
                    preferences.audioDeviceId,
                    preferences.masterVolume,
                    preferences.bufferSize,
                    String(data: audioSettingsJSON, encoding: .utf8),
                    String(data: uiSettingsJSON, encoding: .utf8),
                    String(data: themeSettingsJSON, encoding: .utf8)
                ]
            )
        }
    }

    /// Read user preferences (singleton)
    public func read() async throws -> UserPreferences? {
        try await db.read { database in
            // User preferences is a singleton - always use ID "default"
            if let row = try Row.fetchOne(
                database,
                sql: "SELECT * FROM user_preferences WHERE id = 'default'"
            ) {
                return try mapRowToUserPreferences(row)
            }
            return nil
        }
    }

    /// Update user preferences
    public func update(_ preferences: UserPreferences) async throws {
        try await db.write { database in
            let audioSettingsJSON = try JSONEncoder().encode(preferences.audioSettings)
            let uiSettingsJSON = try JSONEncoder().encode(preferences.uiSettings)
            let themeSettingsJSON = try JSONEncoder().encode(preferences.themeSettings)

            try database.execute(
                sql: """
                UPDATE user_preferences SET
                    audio_device_id = ?, master_volume = ?, buffer_size = ?,
                    audio_settings_json = ?, ui_settings_json = ?, theme_settings_json = ?,
                    updated_at = datetime('now')
                WHERE id = ?
                """,
                arguments: [
                    preferences.audioDeviceId,
                    preferences.masterVolume,
                    preferences.bufferSize,
                    String(data: audioSettingsJSON, encoding: .utf8),
                    String(data: uiSettingsJSON, encoding: .utf8),
                    String(data: themeSettingsJSON, encoding: .utf8),
                    preferences.id
                ]
            )
        }
    }

    // MARK: - Specialized Update Operations

    /// Update audio device preference
    public func updateAudioDevice(_ deviceId: String) async throws {
        try await db.write { database in
            try database.execute(
                sql: """
                UPDATE user_preferences SET
                    audio_device_id = ?,
                    updated_at = datetime('now')
                WHERE id = 'default'
                """,
                arguments: [deviceId]
            )
        }
    }

    /// Update theme preference
    public func updateTheme(_ theme: ThemeSettings) async throws {
        try await db.write { database in
            let themeSettingsJSON = try JSONEncoder().encode(theme)

            try database.execute(
                sql: """
                UPDATE user_preferences SET
                    theme_settings_json = ?,
                    updated_at = datetime('now')
                WHERE id = 'default'
                """,
                arguments: [String(data: themeSettingsJSON, encoding: .utf8)]
            )
        }
    }

    /// Update master volume
    public func updateMasterVolume(_ volume: Double) async throws {
        try await db.write { database in
            try database.execute(
                sql: """
                UPDATE user_preferences SET
                    master_volume = ?,
                    updated_at = datetime('now')
                WHERE id = 'default'
                """,
                arguments: [volume]
            )
        }
    }

    /// Update buffer size
    public func updateBufferSize(_ size: Int) async throws {
        try await db.write { database in
            try database.execute(
                sql: """
                UPDATE user_preferences SET
                    buffer_size = ?,
                    updated_at = datetime('now')
                WHERE id = 'default'
                """,
                arguments: [size]
            )
        }
    }

    // MARK: - Helper Methods

    /// Map database row to UserPreferences model
    private func mapRowToUserPreferences(_ row: Row) throws -> UserPreferences {
        let id: String = row["id"]
        let audioDeviceId: String = row["audio_device_id"]
        let masterVolume: Double = row["master_volume"]
        let bufferSize: Int = row["buffer_size"]

        // Decode JSON columns
        let audioSettingsJSON: String = row["audio_settings_json"]
        let uiSettingsJSON: String = row["ui_settings_json"]
        let themeSettingsJSON: String = row["theme_settings_json"]

        let audioSettings = try JSONDecoder().decode(AudioSettings.self, from: audioSettingsJSON.data(using: .utf8)!)
        let uiSettings = try JSONDecoder().decode(UISettings.self, from: uiSettingsJSON.data(using: .utf8)!)
        let themeSettings = try JSONDecoder().decode(ThemeSettings.self, from: themeSettingsJSON.data(using: .utf8)!)

        return UserPreferences(
            id: id,
            audioDeviceId: audioDeviceId,
            masterVolume: masterVolume,
            bufferSize: bufferSize,
            audioSettings: audioSettings,
            uiSettings: uiSettings,
            themeSettings: themeSettings
        )
    }
}

// MARK: - Supporting Types

/// User preferences model
public struct UserPreferences: Codable, Identifiable {
    public let id: String // Always "default" for singleton
    public let audioDeviceId: String
    public let masterVolume: Double
    public let bufferSize: Int
    public let audioSettings: AudioSettings
    public let uiSettings: UISettings
    public let themeSettings: ThemeSettings
}

/// Audio settings
public struct AudioSettings: Codable {
    public let sampleRate: Int
    public let bufferSize: Int
    public let enableInputMonitoring: Bool
    public let enableLowLatencyMode: Bool
}

/// UI settings
public struct UISettings: Codable {
    public let showWaveforms: Bool
    public let showMarkers: Bool
    public let enableAnimations: Bool
    public let autoSaveInterval: Int
}

/// Theme settings
public struct ThemeSettings: Codable {
    public let mode: ThemeMode
    public let accentColor: String
    public let fontSize: FontSize
    public let reduceTransparency: Bool
}

public enum ThemeMode: String, Codable {
    case light
    case dark
    case system
}

public enum FontSize: String, Codable {
    case small
    case medium
    case large
    case extraLarge
}
