/**
 * User Preferences Model
 *
 * Stores user application preferences and settings.
 */

import Foundation

/// User preferences and settings
public struct UserPreferences: Codable, Sendable {
    /// Unique user identifier (device-specific)
    public let userId: String

    /// User display name
    public var displayName: String?

    /// Default audio output device
    public var defaultOutputDevice: String?

    /// Default audio input device
    public var defaultInputDevice: String?

    /// Default sample rate
    public var defaultSampleRate: Int?

    /// Default buffer size
    public var defaultBufferSize: Int?

    /// Whether to enable auto-save
    public var autoSaveEnabled: Bool

    /// Auto-save interval in seconds
    public var autoSaveInterval: Int

    /// Whether to enable automatic backups
    public var autoBackupEnabled: Bool

    /// Backup interval in hours
    public var backupIntervalHours: Int

    /// Maximum number of backups to keep
    public var maxBackups: Int

    /// Theme preference
    public var theme: String?

    /// Language preference
    public var language: String?

    /// Whether to show tooltips
    public var showTooltips: Bool

    /// Custom preferences
    public var customPreferences: [String: String]

    /// Last modification timestamp
    public let updatedAt: Date

    public init(
        userId: String,
        displayName: String? = nil,
        defaultOutputDevice: String? = nil,
        defaultInputDevice: String? = nil,
        defaultSampleRate: Int? = nil,
        defaultBufferSize: Int? = nil,
        autoSaveEnabled: Bool = true,
        autoSaveInterval: Int = 300,
        autoBackupEnabled: Bool = true,
        backupIntervalHours: Int = 24,
        maxBackups: Int = 30,
        theme: String? = nil,
        language: String? = nil,
        showTooltips: Bool = true,
        customPreferences: [String: String] = [:],
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.displayName = displayName
        self.defaultOutputDevice = defaultOutputDevice
        self.defaultInputDevice = defaultInputDevice
        self.defaultSampleRate = defaultSampleRate
        self.defaultBufferSize = defaultBufferSize
        self.autoSaveEnabled = autoSaveEnabled
        self.autoSaveInterval = autoSaveInterval
        self.autoBackupEnabled = autoBackupEnabled
        self.backupIntervalHours = backupIntervalHours
        self.maxBackups = maxBackups
        self.theme = theme
        self.language = language
        self.showTooltips = showTooltips
        self.customPreferences = customPreferences
        self.updatedAt = updatedAt
    }

    /// Coding keys for JSON serialization
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case defaultOutputDevice = "default_output_device"
        case defaultInputDevice = "default_input_device"
        case defaultSampleRate = "default_sample_rate"
        case defaultBufferSize = "default_buffer_size"
        case autoSaveEnabled = "auto_save_enabled"
        case autoSaveInterval = "auto_save_interval"
        case autoBackupEnabled = "auto_backup_enabled"
        case backupIntervalHours = "backup_interval_hours"
        case maxBackups = "max_backups"
        case theme
        case language
        case showTooltips = "show_tooltips"
        case customPreferences = "custom_preferences"
        case updatedAt = "updated_at"
    }
}
