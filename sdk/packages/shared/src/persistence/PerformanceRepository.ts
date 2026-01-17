/**
 * PerformanceRepository - Repository pattern for Performance CRUD operations
 *
 * Provides data access layer for Performance entities with better-sqlite3.
 * Synchronous API for optimal performance.
 *
 * @module persistence/PerformanceRepository
 */

import Database from 'better-sqlite3';

/**
 * Arrangement style enum
 */
export enum ArrangementStyle {
  SOLO_PIANO = 'SOLO_PIANO',
  SATB = 'SATB',
  CHAMBER_ENSEMBLE = 'CHAMBER_ENSEMBLE',
  JAZZ_COMBO = 'JAZZ_COMBO',
  ROCK_BAND = 'ROCK_BAND',
  ELECTRONIC = 'ELECTRONIC',
  ORCHESTRAL = 'ORCHESTRAL',
  AMBIENT = 'AMBIENT',
  MINIMAL = 'MINIMAL',
  EXPERIMENTAL = 'EXPERIMENTAL',
  CUSTOM = 'CUSTOM',
  FULL_ENSEMBLE = 'FULL_ENSEMBLE'
}

/**
 * Mix target for audio routing
 */
export interface MixTarget {
  id: string;
  roleId: string;
  targetName: string;
  pan: number;
  volume: number;
}

/**
 * Performance model
 */
export interface Performance {
  id: string;
  songId: string;
  name: string;
  arrangementStyle: ArrangementStyle;
  density: number;
  instrumentation: Record<string, number>;
  mixTargets: MixTarget[];
}

/**
 * Repository for Performance CRUD operations
 */
export class PerformanceRepository {
  constructor(private db: Database.Database) {}

  // MARK: - CRUD Operations

  /**
   * Create a new performance in the database
   */
  create(performance: Performance): void {
    const stmt = this.db.prepare(`
      INSERT INTO performances (
        id, song_id, name, arrangement_style, density,
        instrumentation_json, mix_targets_json,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    stmt.run(
      performance.id,
      performance.songId,
      performance.name,
      performance.arrangementStyle,
      performance.density,
      JSON.stringify(performance.instrumentation),
      JSON.stringify(performance.mixTargets)
    );
  }

  /**
   * Read a performance by ID
   */
  read(id: string): Performance | undefined {
    const row = this.db.prepare('SELECT * FROM performances WHERE id = ?').get(id);
    return row ? this.mapRowToPerformance(row as any) : undefined;
  }

  /**
   * Update an existing performance
   */
  update(performance: Performance): void {
    const stmt = this.db.prepare(`
      UPDATE performances SET
        song_id = ?, name = ?, arrangement_style = ?, density = ?,
        instrumentation_json = ?, mix_targets_json = ?,
        updated_at = datetime('now')
      WHERE id = ?
    `);

    stmt.run(
      performance.songId,
      performance.name,
      performance.arrangementStyle,
      performance.density,
      JSON.stringify(performance.instrumentation),
      JSON.stringify(performance.mixTargets),
      performance.id
    );
  }

  /**
   * Delete a performance by ID
   */
  delete(id: string): void {
    this.db.prepare('DELETE FROM performances WHERE id = ?').run(id);
  }

  // MARK: - Query Operations

  /**
   * Get all performances ordered by name
   */
  getAll(): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances ORDER BY name').all();
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Get all performances for a specific song
   */
  getBySongId(songId: string): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances WHERE song_id = ? ORDER BY name').all(songId);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Get performances by arrangement style
   */
  getByArrangementStyle(style: ArrangementStyle): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances WHERE arrangement_style = ? ORDER BY name').all(style);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Get most played performances (by update count or last played)
   */
  getMostPlayed(limit: number = 20): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances ORDER BY updated_at DESC LIMIT ?').all(limit);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Get recently created performances
   */
  getRecentlyCreated(limit: number = 20): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances ORDER BY created_at DESC LIMIT ?').all(limit);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Get performances within a density range
   */
  getByDensityRange(min: number, max: number): Performance[] {
    const rows = this.db.prepare('SELECT * FROM performances WHERE density BETWEEN ? AND ? ORDER BY density').all(min, max);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  /**
   * Search performances by name
   */
  search(query: string): Performance[] {
    const searchPattern = `%${query}%`;
    const rows = this.db.prepare('SELECT * FROM performances WHERE name LIKE ? ORDER BY name').all(searchPattern);
    return rows.map((row: any) => this.mapRowToPerformance(row));
  }

  // MARK: - Helper Methods

  /**
   * Map database row to Performance model
   */
  private mapRowToPerformance(row: any): Performance {
    return {
      id: row.id,
      songId: row.song_id,
      name: row.name,
      arrangementStyle: row.arrangement_style as ArrangementStyle,
      density: row.density,
      instrumentation: JSON.parse(row.instrumentation_json),
      mixTargets: JSON.parse(row.mix_targets_json)
    };
  }
}
