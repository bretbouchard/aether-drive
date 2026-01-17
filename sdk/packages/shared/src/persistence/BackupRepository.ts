/**
 * Backup Repository
 *
 * Repository for backup CRUD operations using SQLite.
 *
 * @module persistence/BackupRepository
 */

import type { Backup } from '../types/backup-model';
import { Database } from 'better-sqlite3';

/**
 * Repository for Backup CRUD operations
 */
export class BackupRepository {
  private db: Database;

  constructor(db: Database) {
    this.db = db;
    this.initializeTable();
  }

  /**
   * Initialize backups table
   */
  private initializeTable(): void {
    this.db.exec(`
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
    `);
  }

  // MARK: - CRUD Operations

  /**
   * Create a new backup
   */
  create(backup: Backup): void {
    const stmt = this.db.prepare(`
      INSERT INTO backups (
        id, timestamp, description,
        songs_json, performances_json, preferences_json,
        size, version
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      backup.id,
      backup.timestamp.toISOString(),
      backup.description,
      backup.songsJSON,
      backup.performancesJSON,
      backup.preferencesJSON,
      backup.size,
      backup.version
    );
  }

  /**
   * Read a backup by ID
   */
  read(id: string): Backup | undefined {
    const stmt = this.db.prepare(`
      SELECT * FROM backups WHERE id = ?
    `);

    const row = stmt.get(id) as any;
    return row ? this.mapRowToBackup(row) : undefined;
  }

  /**
   * Update an existing backup
   */
  update(backup: Backup): void {
    const stmt = this.db.prepare(`
      UPDATE backups SET
        description = ?,
        songs_json = ?,
        performances_json = ?,
        preferences_json = ?,
        size = ?
      WHERE id = ?
    `);

    stmt.run(
      backup.description,
      backup.songsJSON,
      backup.performancesJSON,
      backup.preferencesJSON,
      backup.size,
      backup.id
    );
  }

  /**
   * Delete a backup by ID
   */
  delete(id: string): void {
    const stmt = this.db.prepare(`
      DELETE FROM backups WHERE id = ?
    `);

    stmt.run(id);
  }

  // MARK: - Query Operations

  /**
   * Get all backups ordered by timestamp (newest first)
   */
  getAll(): Backup[] {
    const stmt = this.db.prepare(`
      SELECT * FROM backups ORDER BY timestamp DESC
    `);

    const rows = stmt.all() as any[];
    return rows.map(row => this.mapRowToBackup(row));
  }

  /**
   * Get latest backup
   */
  getLatest(): Backup | undefined {
    const stmt = this.db.prepare(`
      SELECT * FROM backups ORDER BY timestamp DESC LIMIT 1
    `);

    const row = stmt.get() as any;
    return row ? this.mapRowToBackup(row) : undefined;
  }

  /**
   * Get backups within a date range
   */
  getByDateRange(startDate: Date, endDate: Date): Backup[] {
    const stmt = this.db.prepare(`
      SELECT * FROM backups
      WHERE timestamp BETWEEN ? AND ?
      ORDER BY timestamp DESC
    `);

    const rows = stmt.all(startDate.toISOString(), endDate.toISOString()) as any[];
    return rows.map(row => this.mapRowToBackup(row));
  }

  /**
   * Get backups by version
   */
  getByVersion(version: string): Backup[] {
    const stmt = this.db.prepare(`
      SELECT * FROM backups WHERE version = ?
      ORDER BY timestamp DESC
    `);

    const rows = stmt.all(version) as any[];
    return rows.map(row => this.mapRowToBackup(row));
  }

  /**
   * Get total backup size
   */
  getTotalSize(): number {
    const stmt = this.db.prepare(`
      SELECT SUM(size) as total FROM backups
    `);

    const result = stmt.get() as { total: number | null };
    return result.total || 0;
  }

  /**
   * Delete backups older than specified date
   */
  deleteOlderThan(date: Date): number {
    const stmt = this.db.prepare(`
      DELETE FROM backups WHERE timestamp < ?
    `);

    const info = stmt.run(date.toISOString());
    return info.changes;
  }

  /**
   * Count total backups
   */
  count(): number {
    const stmt = this.db.prepare(`
      SELECT COUNT(*) as count FROM backups
    `);

    const result = stmt.get() as { count: number };
    return result.count;
  }

  // MARK: - Helper Methods

  /**
   * Map database row to Backup model
   */
  private mapRowToBackup(row: any): Backup {
    return {
      id: row.id,
      timestamp: new Date(row.timestamp),
      description: row.description,
      songsJSON: row.songs_json,
      performancesJSON: row.performances_json,
      preferencesJSON: row.preferences_json,
      size: row.size,
      version: row.version,
    };
  }
}
