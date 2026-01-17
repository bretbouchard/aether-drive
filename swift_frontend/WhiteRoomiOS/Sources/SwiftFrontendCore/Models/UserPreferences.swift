//
//  UserPreferences.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - User Preferences
// =============================================================================

/**
 User-level preferences (app-wide, not song-specific)

 This model contains all user-configurable preferences for the White Room
 application, including audio, MIDI, display, editing, and cloud settings.
 */
public struct UserPreferences: Codable, Sendable {

    // MARK: - Audio Preferences

    /**
     Selected audio device ID
     */
    public var audioDeviceId: String?

    /**
     Sample rate in Hz
     */
    public var sampleRate: Int

    /**
     Buffer size in samples
     */
    public var bufferSize: Int

    /**
     Master volume (0.0 to 1.0)
     */
    public var masterVolume: Double

    /**
     Enable metronome during playback
     */
    public var enableMetronome: Bool

    /**
     Metronome volume (0.0 to 1.0)
     */
    public var metronomeVolume: Double

    // MARK: - MIDI Preferences

    /**
     Default MIDI input device
     */
    public var defaultMidiInputDevice: String?

    /**
     Default MIDI output device
     */
    public var defaultMidiOutputDevice: String?

    /**
     Enable MIDI clock synchronization
     */
    public var midiClockEnabled: Bool

    /**
     MIDI sync mode (master/slave/auto)
     */
    public var midiSyncMode: String?

    // MARK: - Display Preferences

    /**
     UI theme (light/dark/system)
     */
    public var theme: String

    /**
     Show track colors in UI
     */
    public var showTrackColors: Bool

    /**
     Show track icons in UI
     */
    public var showTrackIcons: Bool

    /**
     Show section headers in timeline
     */
    public var showSectionHeaders: Bool

    /**
     Notation font size in points
     */
    public var notationFontSize: Int

    /**
     Piano roll grid opacity (0.0 to 1.0)
     */
    public var pianoRollGridOpacity: Double

    // MARK: - Editing Preferences

    /**
     Snap to grid during editing
     */
    public var snapToGrid: Bool

    /**
     Grid size in beats
     */
    public var gridSizeBeats: Double

    /**
     Auto-quantize recorded notes
     */
    public var autoQuantize: Bool

    /**
     Quantize strength (0.0 to 1.0)
     */
    public var quantizeStrength: Double

    /**
     Default editing tool (pencil/eraser/select)
     */
    public var defaultEditTool: String?

    // MARK: - Auto-Save Preferences

    /**
     Enable auto-save
     */
    public var autoSaveEnabled: Bool

    /**
     Auto-save interval in seconds
     */
    public var autoSaveIntervalSeconds: Int

    /**
     Maximum number of auto-saves to keep
     */
    public var maxAutosaves: Int

    // MARK: - Backup Preferences

    /**
     Enable automatic backups
     */
    public var autoBackupEnabled: Bool

    /**
     Backup interval in hours
     */
    public var backupIntervalHours: Int

    /**
     Maximum number of backups to keep
     */
    public var maxBackups: Int

    // MARK: - Plugin Preferences

    /**
     Default plugin search paths
     */
    public var defaultPluginSearchPaths: [String]

    /**
     Scan for plugins on startup
     */
    public var scanPluginsOnStartup: Bool

    /**
     Plugin UI mode (floating/embedded)
     */
    public var pluginUiMode: String?

    // MARK: - Cloud Preferences

    /**
     Enable iCloud synchronization
     */
    public var iCloudEnabled: Bool

    /**
     Enable automatic sync
     */
    public var autoSyncEnabled: Bool

    /**
     Sync interval in minutes
     */
    public var syncIntervalMinutes: Int

    // MARK: - Analytics Preferences

    /**
     Enable anonymous analytics
     */
    public var analyticsEnabled: Bool

    /**
     Enable crash reporting
     */
    public var crashReportingEnabled: Bool

    /**
     Enable usage reporting
     */
    public var usageReportingEnabled: Bool

    // MARK: - Advanced Preferences

    /**
     Enable debug mode
     */
    public var debugMode: Bool

    /**
     Enable verbose logging
     */
    public var verboseLogging: Bool

    /**
     Enable performance monitoring
     */
    public var performanceMonitoring: Bool

    // MARK: - Initialization

    public init(
        audioDeviceId: String? = nil,
        sampleRate: Int = 48000,
        bufferSize: Int = 256,
        masterVolume: Double = 0.8,
        enableMetronome: Bool = true,
        metronomeVolume: Double = 0.5,
        defaultMidiInputDevice: String? = nil,
        defaultMidiOutputDevice: String? = nil,
        midiClockEnabled: Bool = false,
        midiSyncMode: String? = nil,
        theme: String = "system",
        showTrackColors: Bool = true,
        showTrackIcons: Bool = true,
        showSectionHeaders: Bool = true,
        notationFontSize: Int = 14,
        pianoRollGridOpacity: Double = 0.3,
        snapToGrid: Bool = true,
        gridSizeBeats: Double = 1.0,
        autoQuantize: Bool = false,
        quantizeStrength: Double = 0.8,
        defaultEditTool: String? = nil,
        autoSaveEnabled: Bool = true,
        autoSaveIntervalSeconds: Int = 60,
        maxAutosaves: Int = 10,
        autoBackupEnabled: Bool = true,
        backupIntervalHours: Int = 24,
        maxBackups: Int = 30,
        defaultPluginSearchPaths: [String] = [],
        scanPluginsOnStartup: Bool = false,
        pluginUiMode: String? = nil,
        iCloudEnabled: Bool = false,
        autoSyncEnabled: Bool = true,
        syncIntervalMinutes: Int = 5,
        analyticsEnabled: Bool = false,
        crashReportingEnabled: Bool = true,
        usageReportingEnabled: Bool = false,
        debugMode: Bool = false,
        verboseLogging: Bool = false,
        performanceMonitoring: Bool = true
    ) {
        self.audioDeviceId = audioDeviceId
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.masterVolume = masterVolume
        self.enableMetronome = enableMetronome
        self.metronomeVolume = metronomeVolume
        self.defaultMidiInputDevice = defaultMidiInputDevice
        self.defaultMidiOutputDevice = defaultMidiOutputDevice
        self.midiClockEnabled = midiClockEnabled
        self.midiSyncMode = midiSyncMode
        self.theme = theme
        self.showTrackColors = showTrackColors
        self.showTrackIcons = showTrackIcons
        self.showSectionHeaders = showSectionHeaders
        self.notationFontSize = notationFontSize
        self.pianoRollGridOpacity = pianoRollGridOpacity
        self.snapToGrid = snapToGrid
        self.gridSizeBeats = gridSizeBeats
        self.autoQuantize = autoQuantize
        self.quantizeStrength = quantizeStrength
        self.defaultEditTool = defaultEditTool
        self.autoSaveEnabled = autoSaveEnabled
        self.autoSaveIntervalSeconds = autoSaveIntervalSeconds
        self.maxAutosaves = maxAutosaves
        self.autoBackupEnabled = autoBackupEnabled
        self.backupIntervalHours = backupIntervalHours
        self.maxBackups = maxBackups
        self.defaultPluginSearchPaths = defaultPluginSearchPaths
        self.scanPluginsOnStartup = scanPluginsOnStartup
        self.pluginUiMode = pluginUiMode
        self.iCloudEnabled = iCloudEnabled
        self.autoSyncEnabled = autoSyncEnabled
        self.syncIntervalMinutes = syncIntervalMinutes
        self.analyticsEnabled = analyticsEnabled
        self.crashReportingEnabled = crashReportingEnabled
        self.usageReportingEnabled = usageReportingEnabled
        self.debugMode = debugMode
        self.verboseLogging = verboseLogging
        self.performanceMonitoring = performanceMonitoring
    }

    // MARK: - Default Factory

    /**
     Create default user preferences
     */
    public static let `default` = UserPreferences()
}
