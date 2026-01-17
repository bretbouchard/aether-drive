/**
 * UserRepository - Repository pattern for UserPreferences CRUD operations
 *
 * Provides data access layer for UserPreferences entities with better-sqlite3.
 * Synchronous API for optimal performance.
 *
 * @module persistence/UserRepository
 */

import Database from 'better-sqlite3';

/**
 * Theme mode enum
 */
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

/**
 * Font size enum
 */
export enum FontSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large',
  EXTRA_LARGE = 'extraLarge'
}

/**
 * Audio settings
 */
export interface AudioSettings {
  sampleRate: number;
  bufferSize: number;
  enableInputMonitoring: boolean;
  enableLowLatencyMode: boolean;
}

/**
 * UI settings
 */
export interface UISettings {
  showWaveforms: boolean;
  showMarkers: boolean;
  enableAnimations: boolean;
  autoSaveInterval: number;
}

/**
 * Theme settings
 */
export interface ThemeSettings {
  mode: ThemeMode;
  accentColor: string;
  fontSize: FontSize;
  reduceTransparency: boolean;
}

/**
 * User preferences model
 */
export interface UserPreferences {
  id: string; // Always "default" for singleton
  audioDeviceId: string;
  masterVolume: number;
  bufferSize: number;
  audioSettings: AudioSettings;
  uiSettings: UISettings;
  themeSettings: ThemeSettings;
}

/**
 * Repository for UserPreferences CRUD operations
 */
export class UserRepository {
  constructor(private db: Database.Database) {}

  // MARK: - CRUD Operations

  /**
   * Create or update user preferences
   */
  create(preferences: UserPreferences): void {
    const stmt = this.db.prepare(`
      INSERT INTO user_preferences (
        id, audio_device_id, master_volume, buffer_size,
        audio_settings_json, ui_settings_json, theme_settings_json,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    stmt.run(
      preferences.id,
      preferences.audioDeviceId,
      preferences.masterVolume,
      preferences.bufferSize,
      JSON.stringify(preferences.audioSettings),
      JSON.stringify(preferences.uiSettings),
      JSON.stringify(preferences.themeSettings)
    );
  }

  /**
   * Read user preferences (singleton)
   */
  read(): UserPreferences | undefined {
    // User preferences is a singleton - always use ID "default"
    const row = this.db.prepare("SELECT * FROM user_preferences WHERE id = 'default'").get();
    return row ? this.mapRowToUserPreferences(row as any) : undefined;
  }

  /**
   * Update user preferences
   */
  update(preferences: UserPreferences): void {
    const stmt = this.db.prepare(`
      UPDATE user_preferences SET
        audio_device_id = ?, master_volume = ?, buffer_size = ?,
        audio_settings_json = ?, ui_settings_json = ?, theme_settings_json = ?,
        updated_at = datetime('now')
      WHERE id = ?
    `);

    stmt.run(
      preferences.audioDeviceId,
      preferences.masterVolume,
      preferences.bufferSize,
      JSON.stringify(preferences.audioSettings),
      JSON.stringify(preferences.uiSettings),
      JSON.stringify(preferences.themeSettings),
      preferences.id
    );
  }

  // MARK: - Specialized Update Operations

  /**
   * Update audio device preference
   */
  updateAudioDevice(deviceId: string): void {
    this.db.prepare(`
      UPDATE user_preferences SET
        audio_device_id = ?,
        updated_at = datetime('now')
      WHERE id = 'default'
    `).run(deviceId);
  }

  /**
   * Update theme preference
   */
  updateTheme(theme: ThemeSettings): void {
    this.db.prepare(`
      UPDATE user_preferences SET
        theme_settings_json = ?,
        updated_at = datetime('now')
      WHERE id = 'default'
    `).run(JSON.stringify(theme));
  }

  /**
   * Update master volume
   */
  updateMasterVolume(volume: number): void {
    this.db.prepare(`
      UPDATE user_preferences SET
        master_volume = ?,
        updated_at = datetime('now')
      WHERE id = 'default'
    `).run(volume);
  }

  /**
   * Update buffer size
   */
  updateBufferSize(size: number): void {
    this.db.prepare(`
      UPDATE user_preferences SET
        buffer_size = ?,
        updated_at = datetime('now')
      WHERE id = 'default'
    `).run(size);
  }

  // MARK: - Helper Methods

  /**
   * Map database row to UserPreferences model
   */
  private mapRowToUserPreferences(row: any): UserPreferences {
    return {
      id: row.id,
      audioDeviceId: row.audio_device_id,
      masterVolume: row.master_volume,
      bufferSize: row.buffer_size,
      audioSettings: JSON.parse(row.audio_settings_json),
      uiSettings: JSON.parse(row.ui_settings_json),
      themeSettings: JSON.parse(row.theme_settings_json)
    };
  }
}
