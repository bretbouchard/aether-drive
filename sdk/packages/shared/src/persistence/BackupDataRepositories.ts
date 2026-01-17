/**
 * Backup Data Repositories
 *
 * Repository implementations for Song, Performance, and UserPreferences data.
 *
 * @module persistence/BackupDataRepositories
 */

import type { Song, Performance, UserPreferences } from '../types/backup-model';
import { Database } from 'better-sqlite3';

// =============================================================================
// SONG DATA REPOSITORY
// =============================================================================

/**
 * Repository for Song data persistence
 */
export class SongDataRepository {
  private db: Database;

  constructor(db: Database) {
    this.db = db;
    this.initializeTable();
  }

  private initializeTable(): void {
    this.db.exec(`
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
    `);
  }

  create(song: Song): void {
    const stmt = this.db.prepare(`
      INSERT INTO song_data (
        id, name, composer, description, genre, duration, key,
        created_at, updated_at, song_data_json, determinism_seed, custom_metadata
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      song.id,
      song.name,
      song.composer,
      song.description,
      song.genre,
      song.duration,
      song.key,
      song.createdAt.toISOString(),
      song.updatedAt.toISOString(),
      song.songDataJSON,
      song.determinismSeed,
      song.customMetadata ? JSON.stringify(song.customMetadata) : null
    );
  }

  read(id: string): Song | undefined {
    const stmt = this.db.prepare(`
      SELECT * FROM song_data WHERE id = ?
    `);

    const row = stmt.get(id) as any;
    return row ? this.mapRowToSong(row) : undefined;
  }

  update(song: Song): void {
    const stmt = this.db.prepare(`
      UPDATE song_data SET
        name = ?, composer = ?, description = ?, genre = ?, duration = ?, key = ?,
        updated_at = ?, song_data_json = ?, determinism_seed = ?, custom_metadata = ?
      WHERE id = ?
    `);

    stmt.run(
      song.name,
      song.composer,
      song.description,
      song.genre,
      song.duration,
      song.key,
      song.updatedAt.toISOString(),
      song.songDataJSON,
      song.determinismSeed,
      song.customMetadata ? JSON.stringify(song.customMetadata) : null,
      song.id
    );
  }

  delete(id: string): void {
    const stmt = this.db.prepare(`
      DELETE FROM song_data WHERE id = ?
    `);

    stmt.run(id);
  }

  getAll(): Song[] {
    const stmt = this.db.prepare(`
      SELECT * FROM song_data ORDER BY name
    `);

    const rows = stmt.all() as any[];
    return rows.map(row => this.mapRowToSong(row));
  }

  getRecentlyCreated(limit: number = 20): Song[] {
    const stmt = this.db.prepare(`
      SELECT * FROM song_data ORDER BY created_at DESC LIMIT ?
    `);

    const rows = stmt.all(limit) as any[];
    return rows.map(row => this.mapRowToSong(row));
  }

  getRecentlyUpdated(limit: number = 20): Song[] {
    const stmt = this.db.prepare(`
      SELECT * FROM song_data ORDER BY updated_at DESC LIMIT ?
    `);

    const rows = stmt.all(limit) as any[];
    return rows.map(row => this.mapRowToSong(row));
  }

  search(query: string): Song[] {
    const stmt = this.db.prepare(`
      SELECT * FROM song_data
      WHERE name LIKE ? OR composer LIKE ?
      ORDER BY name
    `);

    const searchPattern = `%${query}%`;
    const rows = stmt.all(searchPattern, searchPattern) as any[];
    return rows.map(row => this.mapRowToSong(row));
  }

  count(): number {
    const stmt = this.db.prepare(`
      SELECT COUNT(*) as count FROM song_data
    `);

    const result = stmt.get() as { count: number };
    return result.count;
  }

  private mapRowToSong(row: any): Song {
    return {
      id: row.id,
      name: row.name,
      composer: row.composer,
      description: row.description,
      genre: row.genre,
      duration: row.duration,
      key: row.key,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
      songDataJSON: row.song_data_json,
      determinismSeed: row.determinism_seed,
      customMetadata: row.custom_metadata ? JSON.parse(row.custom_metadata) : undefined,
    };
  }
}

// =============================================================================
// PERFORMANCE DATA REPOSITORY
// =============================================================================

/**
 * Repository for Performance data persistence
 */
export class PerformanceDataRepository {
  private db: Database;

  constructor(db: Database) {
    this.db = db;
    this.initializeTable();
  }

  private initializeTable(): void {
    this.db.exec(`
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
    `);
  }

  create(performance: Performance): void {
    const stmt = this.db.prepare(`
      INSERT INTO performance_data (
        id, name, song_id, description, duration,
        performance_data_json, created_at, updated_at,
        is_favorite, tags
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      performance.id,
      performance.name,
      performance.songId,
      performance.description,
      performance.duration,
      performance.performanceDataJSON,
      performance.createdAt.toISOString(),
      performance.updatedAt.toISOString(),
      performance.isFavorite ? 1 : 0,
      JSON.stringify(performance.tags)
    );
  }

  read(id: string): Performance | undefined {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data WHERE id = ?
    `);

    const row = stmt.get(id) as any;
    return row ? this.mapRowToPerformance(row) : undefined;
  }

  update(performance: Performance): void {
    const stmt = this.db.prepare(`
      UPDATE performance_data SET
        name = ?, song_id = ?, description = ?, duration = ?,
        performance_data_json = ?, updated_at = ?,
        is_favorite = ?, tags = ?
      WHERE id = ?
    `);

    stmt.run(
      performance.name,
      performance.songId,
      performance.description,
      performance.duration,
      performance.performanceDataJSON,
      performance.updatedAt.toISOString(),
      performance.isFavorite ? 1 : 0,
      JSON.stringify(performance.tags),
      performance.id
    );
  }

  delete(id: string): void {
    const stmt = this.db.prepare(`
      DELETE FROM performance_data WHERE id = ?
    `);

    stmt.run(id);
  }

  getAll(): Performance[] {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data ORDER BY name
    `);

    const rows = stmt.all() as any[];
    return rows.map(row => this.mapRowToPerformance(row));
  }

  getBySongId(songId: string): Performance[] {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data WHERE song_id = ?
      ORDER BY created_at DESC
    `);

    const rows = stmt.all(songId) as any[];
    return rows.map(row => this.mapRowToPerformance(row));
  }

  getFavorites(): Performance[] {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data WHERE is_favorite = 1
      ORDER BY name
    `);

    const rows = stmt.all() as any[];
    return rows.map(row => this.mapRowToPerformance(row));
  }

  getRecentlyCreated(limit: number = 20): Performance[] {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data ORDER BY created_at DESC LIMIT ?
    `);

    const rows = stmt.all(limit) as any[];
    return rows.map(row => this.mapRowToPerformance(row));
  }

  search(query: string): Performance[] {
    const stmt = this.db.prepare(`
      SELECT * FROM performance_data
      WHERE name LIKE ?
      ORDER BY name
    `);

    const searchPattern = `%${query}%`;
    const rows = stmt.all(searchPattern) as any[];
    return rows.map(row => this.mapRowToPerformance(row));
  }

  count(): number {
    const stmt = this.db.prepare(`
      SELECT COUNT(*) as count FROM performance_data
    `);

    const result = stmt.get() as { count: number };
    return result.count;
  }

  private mapRowToPerformance(row: any): Performance {
    return {
      id: row.id,
      name: row.name,
      songId: row.song_id,
      description: row.description,
      duration: row.duration,
      performanceDataJSON: row.performance_data_json,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
      isFavorite: row.is_favorite === 1,
      tags: row.tags ? JSON.parse(row.tags) : [],
    };
  }
}

// =============================================================================
// USER PREFERENCES REPOSITORY
// =============================================================================

/**
 * Repository for User Preferences persistence
 */
export class UserPreferencesRepository {
  private db: Database;

  constructor(db: Database) {
    this.db = db;
    this.initializeTable();
  }

  private initializeTable(): void {
    this.db.exec(`
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
    `);
  }

  upsert(preferences: UserPreferences): void {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO user_preferences (
        user_id, display_name, default_output_device, default_input_device,
        default_sample_rate, default_buffer_size,
        auto_save_enabled, auto_save_interval,
        auto_backup_enabled, backup_interval_hours, max_backups,
        theme, language, show_tooltips, custom_preferences, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      preferences.userId,
      preferences.displayName,
      preferences.defaultOutputDevice,
      preferences.defaultInputDevice,
      preferences.defaultSampleRate,
      preferences.defaultBufferSize,
      preferences.autoSaveEnabled ? 1 : 0,
      preferences.autoSaveInterval,
      preferences.autoBackupEnabled ? 1 : 0,
      preferences.backupIntervalHours,
      preferences.maxBackups,
      preferences.theme,
      preferences.language,
      preferences.showTooltips ? 1 : 0,
      JSON.stringify(preferences.customPreferences),
      preferences.updatedAt.toISOString()
    );
  }

  read(userId: string = 'default'): UserPreferences | undefined {
    const stmt = this.db.prepare(`
      SELECT * FROM user_preferences WHERE user_id = ?
    `);

    const row = stmt.get(userId) as any;
    return row ? this.mapRowToUserPreferences(row) : undefined;
  }

  update(preferences: UserPreferences): void {
    this.upsert(preferences);
  }

  delete(userId: string): void {
    const stmt = this.db.prepare(`
      DELETE FROM user_preferences WHERE user_id = ?
    `);

    stmt.run(userId);
  }

  getDefault(): UserPreferences {
    const existing = this.read();
    if (existing) {
      return existing;
    }

    const defaults: UserPreferences = {
      userId: 'default',
      displayName: undefined,
      defaultOutputDevice: undefined,
      defaultInputDevice: undefined,
      defaultSampleRate: 48000,
      defaultBufferSize: 256,
      autoSaveEnabled: true,
      autoSaveInterval: 300,
      autoBackupEnabled: true,
      backupIntervalHours: 24,
      maxBackups: 30,
      theme: undefined,
      language: undefined,
      showTooltips: true,
      customPreferences: {},
      updatedAt: new Date(),
    };

    this.upsert(defaults);
    return defaults;
  }

  private mapRowToUserPreferences(row: any): UserPreferences {
    return {
      userId: row.user_id,
      displayName: row.display_name,
      defaultOutputDevice: row.default_output_device,
      defaultInputDevice: row.default_input_device,
      defaultSampleRate: row.default_sample_rate,
      defaultBufferSize: row.default_buffer_size,
      autoSaveEnabled: row.auto_save_enabled === 1,
      autoSaveInterval: row.auto_save_interval,
      autoBackupEnabled: row.auto_backup_enabled === 1,
      backupIntervalHours: row.backup_interval_hours,
      maxBackups: row.max_backups,
      theme: row.theme,
      language: row.language,
      showTooltips: row.show_tooltips === 1,
      customPreferences: row.custom_preferences ? JSON.parse(row.custom_preferences) : {},
      updatedAt: new Date(row.updated_at),
    };
  }
}
