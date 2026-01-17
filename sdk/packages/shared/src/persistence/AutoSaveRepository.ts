/**
 * White Room AutoSaveRepository (TypeScript)
 *
 * Repository for managing auto-saved song states in SQLite database.
 * Provides CRUD operations and query methods for autosave management.
 */

import Database from 'better-sqlite3';

// =============================================================================
// TYPES
// =============================================================================

export interface AutoSave {
  id: string;
  songId: string;
  songJSON: string;
  timestamp: Date;
  description: string;
}

// =============================================================================
// REPOSITORY
// =============================================================================

export class AutoSaveRepository {
  private db: Database.Database;
  private tableName = 'autosaves';

  constructor(dbPath: string) {
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.createTable();
    this.createIndexes();
  }

  // ---------------------------------------------------------------------------
  // TABLE CREATION
  // ---------------------------------------------------------------------------

  private createTable(): void {
    const createTableSQL = `
      CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id TEXT PRIMARY KEY,
        song_id TEXT NOT NULL,
        song_json TEXT NOT NULL,
        timestamp REAL NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      );
    `;

    this.db.exec(createTableSQL);
    console.log(`AutoSaveRepository: Table '${this.tableName}' ready`);
  }

  private createIndexes(): void {
    // Index on song_id for faster queries
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_${this.tableName}_song_id
      ON ${this.tableName}(song_id);
    `);

    // Index on timestamp for sorting
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_${this.tableName}_timestamp
      ON ${this.tableName}(timestamp DESC);
    `);

    // Composite index for song + timestamp queries
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_${this.tableName}_song_timestamp
      ON ${this.tableName}(song_id, timestamp DESC);
    `);

    console.log('AutoSaveRepository: Indexes created');
  }

  // ---------------------------------------------------------------------------
  // CRUD OPERATIONS
  // ---------------------------------------------------------------------------

  public create(autosave: AutoSave): void {
    const insertSQL = `
      INSERT INTO ${this.tableName} (id, song_id, song_json, timestamp, description)
      VALUES (?, ?, ?, ?, ?);
    `;

    const stmt = this.db.prepare(insertSQL);
    stmt.run(
      autosave.id,
      autosave.songId,
      autosave.songJSON,
      autosave.timestamp.getTime(),
      autosave.description
    );

    console.log(`AutoSaveRepository: Created autosave '${autosave.id}' for song '${autosave.songId}'`);
  }

  public read(id: string): AutoSave | undefined {
    const selectSQL = `
      SELECT id, song_id, song_json, timestamp, description
      FROM ${this.tableName}
      WHERE id = ?;
    `;

    const stmt = this.db.prepare(selectSQL);
    const row = stmt.get(id) as any;

    if (!row) {
      return undefined;
    }

    return this.mapRowToAutoSave(row);
  }

  public update(autosave: AutoSave): void {
    const updateSQL = `
      UPDATE ${this.tableName}
      SET song_json = ?, timestamp = ?, description = ?
      WHERE id = ?;
    `;

    const stmt = this.db.prepare(updateSQL);
    stmt.run(
      autosave.songJSON,
      autosave.timestamp.getTime(),
      autosave.description,
      autosave.id
    );

    console.log(`AutoSaveRepository: Updated autosave '${autosave.id}'`);
  }

  public delete(id: string): void {
    const deleteSQL = `
      DELETE FROM ${this.tableName}
      WHERE id = ?;
    `;

    const stmt = this.db.prepare(deleteSQL);
    stmt.run(id);

    console.log(`AutoSaveRepository: Deleted autosave '${id}'`);
  }

  // ---------------------------------------------------------------------------
  // QUERY METHODS
  // ---------------------------------------------------------------------------

  public getAllForSong(songId: string): AutoSave[] {
    const selectSQL = `
      SELECT id, song_id, song_json, timestamp, description
      FROM ${this.tableName}
      WHERE song_id = ?
      ORDER BY timestamp DESC;
    `;

    const stmt = this.db.prepare(selectSQL);
    const rows = stmt.all(songId) as any[];

    return rows.map(row => this.mapRowToAutoSave(row));
  }

  public getLatestForSong(songId: string): AutoSave | undefined {
    const selectSQL = `
      SELECT id, song_id, song_json, timestamp, description
      FROM ${this.tableName}
      WHERE song_id = ?
      ORDER BY timestamp DESC
      LIMIT 1;
    `;

    const stmt = this.db.prepare(selectSQL);
    const row = stmt.get(songId) as any;

    if (!row) {
      return undefined;
    }

    return this.mapRowToAutoSave(row);
  }

  public getAll(): AutoSave[] {
    const selectSQL = `
      SELECT id, song_id, song_json, timestamp, description
      FROM ${this.tableName}
      ORDER BY timestamp DESC;
    `;

    const stmt = this.db.prepare(selectSQL);
    const rows = stmt.all() as any[];

    return rows.map(row => this.mapRowToAutoSave(row));
  }

  public countForSong(songId: string): number {
    const countSQL = `
      SELECT COUNT(*) as count
      FROM ${this.tableName}
      WHERE song_id = ?;
    `;

    const stmt = this.db.prepare(countSQL);
    const result = stmt.get(songId) as { count: number };

    return result.count;
  }

  // ---------------------------------------------------------------------------
  // BATCH OPERATIONS
  // ---------------------------------------------------------------------------

  public deleteAllForSong(songId: string): number {
    const deleteSQL = `
      DELETE FROM ${this.tableName}
      WHERE song_id = ?;
    `;

    const stmt = this.db.prepare(deleteSQL);
    const result = stmt.run(songId);

    console.log(`AutoSaveRepository: Deleted ${result.changes} autosaves for song '${songId}'`);
    return result.changes;
  }

  public deleteOlderThan(date: Date): number {
    const deleteSQL = `
      DELETE FROM ${this.tableName}
      WHERE timestamp < ?;
    `;

    const stmt = this.db.prepare(deleteSQL);
    const result = stmt.run(date.getTime());

    console.log(`AutoSaveRepository: Deleted ${result.changes} autosaves older than ${date}`);
    return result.changes;
  }

  public deleteAll(): number {
    const deleteSQL = `
      DELETE FROM ${this.tableName};
    `;

    const stmt = this.db.prepare(deleteSQL);
    const result = stmt.run();

    console.log(`AutoSaveRepository: Deleted all ${result.changes} autosaves`);
    return result.changes;
  }

  // ---------------------------------------------------------------------------
  // HELPER METHODS
  // ---------------------------------------------------------------------------

  private mapRowToAutoSave(row: any): AutoSave {
    return {
      id: row.id,
      songId: row.song_id,
      songJSON: row.song_json,
      timestamp: new Date(row.timestamp),
      description: row.description
    };
  }

  public close(): void {
    this.db.close();
  }
}
