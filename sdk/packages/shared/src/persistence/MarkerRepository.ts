/**
 * MarkerRepository - Repository pattern for Marker CRUD operations
 *
 * Provides data access layer for Marker entities with better-sqlite3.
 * Synchronous API for optimal performance.
 *
 * @module persistence/MarkerRepository
 */

import Database from 'better-sqlite3';

/**
 * Marker model
 */
export interface Marker {
  id: string;
  performanceId: string;
  name: string;
  positionBars: number;
  positionBeats: number;
  color: string;
  note?: string;
}

/**
 * Repository for Marker CRUD operations
 */
export class MarkerRepository {
  constructor(private db: Database.Database) {}

  // MARK: - CRUD Operations

  /**
   * Create a new marker
   */
  create(marker: Marker): void {
    const stmt = this.db.prepare(`
      INSERT INTO markers (
        id, performance_id, name, position_bars, position_beats,
        color, note, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    stmt.run(
      marker.id,
      marker.performanceId,
      marker.name,
      marker.positionBars,
      marker.positionBeats,
      marker.color,
      marker.note || null
    );
  }

  /**
   * Read a marker by ID
   */
  read(id: string): Marker | undefined {
    const row = this.db.prepare('SELECT * FROM markers WHERE id = ?').get(id);
    return row ? this.mapRowToMarker(row as any) : undefined;
  }

  /**
   * Update an existing marker
   */
  update(marker: Marker): void {
    const stmt = this.db.prepare(`
      UPDATE markers SET
        performance_id = ?, name = ?, position_bars = ?, position_beats = ?,
        color = ?, note = ?, updated_at = datetime('now')
      WHERE id = ?
    `);

    stmt.run(
      marker.performanceId,
      marker.name,
      marker.positionBars,
      marker.positionBeats,
      marker.color,
      marker.note || null,
      marker.id
    );
  }

  /**
   * Delete a marker by ID
   */
  delete(id: string): void {
    this.db.prepare('DELETE FROM markers WHERE id = ?').run(id);
  }

  // MARK: - Query Operations

  /**
   * Get all markers for a performance
   */
  getByPerformanceId(performanceId: string): Marker[] {
    const rows = this.db.prepare(`
      SELECT * FROM markers
      WHERE performance_id = ?
      ORDER BY position_bars, position_beats
    `).all(performanceId);
    return rows.map((row: any) => this.mapRowToMarker(row));
  }

  /**
   * Get all markers
   */
  getAll(): Marker[] {
    const rows = this.db.prepare('SELECT * FROM markers ORDER BY performance_id, position_bars, position_beats').all();
    return rows.map((row: any) => this.mapRowToMarker(row));
  }

  /**
   * Get markers by color
   */
  getByColor(color: string): Marker[] {
    const rows = this.db.prepare('SELECT * FROM markers WHERE color = ? ORDER BY performance_id, position_bars').all(color);
    return rows.map((row: any) => this.mapRowToMarker(row));
  }

  /**
   * Get markers by name pattern
   */
  searchByName(query: string): Marker[] {
    const searchPattern = `%${query}%`;
    const rows = this.db.prepare('SELECT * FROM markers WHERE name LIKE ? ORDER BY performance_id, position_bars').all(searchPattern);
    return rows.map((row: any) => this.mapRowToMarker(row));
  }

  /**
   * Get markers within a position range
   */
  getByPositionRange(performanceId: string, startBars: number, endBars: number): Marker[] {
    const rows = this.db.prepare(`
      SELECT * FROM markers
      WHERE performance_id = ? AND position_bars BETWEEN ? AND ?
      ORDER BY position_bars, position_beats
    `).all(performanceId, startBars, endBars);
    return rows.map((row: any) => this.mapRowToMarker(row));
  }

  /**
   * Delete all markers for a performance
   */
  deleteAllForPerformance(performanceId: string): void {
    this.db.prepare('DELETE FROM markers WHERE performance_id = ?').run(performanceId);
  }

  /**
   * Get marker count for a performance
   */
  getCountForPerformance(performanceId: string): number {
    const count = this.db.prepare('SELECT COUNT(*) as count FROM markers WHERE performance_id = ?').get(performanceId) as any;
    return count?.count || 0;
  }

  // MARK: - Helper Methods

  /**
   * Map database row to Marker model
   */
  private mapRowToMarker(row: any): Marker {
    return {
      id: row.id,
      performanceId: row.performance_id,
      name: row.name,
      positionBars: row.position_bars,
      positionBeats: row.position_beats,
      color: row.color,
      note: row.note || undefined
    };
  }
}
