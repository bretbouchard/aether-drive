/**
 * MixGraphRepository - Repository pattern for MixGraph CRUD operations
 *
 * Provides data access layer for MixGraph entities with better-sqlite3.
 * Synchronous API for optimal performance.
 *
 * @module persistence/MixGraphRepository
 */

import Database from 'better-sqlite3';

/**
 * Mix track
 */
export interface MixTrack {
  id: string;
  name: string;
  volume: number;
  pan: number;
  muted: boolean;
  solo: boolean;
  busId?: string;
  instrumentId?: string;
}

/**
 * Mix bus
 */
export interface MixBus {
  id: string;
  name: string;
  volume: number;
  pan: number;
  muted: boolean;
}

/**
 * Mix send
 */
export interface MixSend {
  id: string;
  fromTrackId: string;
  toBusId: string;
  amount: number;
}

/**
 * Mix master
 */
export interface MixMaster {
  volume: number;
  busId?: string;
}

/**
 * Mix graph model
 */
export interface MixGraph {
  id: string;
  songId: string;
  tracks: MixTrack[];
  buses: MixBus[];
  sends: MixSend[];
  master: MixMaster;
}

/**
 * Repository for MixGraph CRUD operations
 */
export class MixGraphRepository {
  constructor(private db: Database.Database) {}

  // MARK: - CRUD Operations

  /**
   * Create a new mix graph for a song
   */
  create(mixGraph: MixGraph): void {
    const stmt = this.db.prepare(`
      INSERT INTO mix_graphs (
        id, song_id, tracks_json, buses_json, sends_json, master_json,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    stmt.run(
      mixGraph.id,
      mixGraph.songId,
      JSON.stringify(mixGraph.tracks),
      JSON.stringify(mixGraph.buses),
      JSON.stringify(mixGraph.sends),
      JSON.stringify(mixGraph.master)
    );
  }

  /**
   * Read a mix graph by song ID
   */
  read(songId: string): MixGraph | undefined {
    const row = this.db.prepare('SELECT * FROM mix_graphs WHERE song_id = ?').get(songId);
    return row ? this.mapRowToMixGraph(row as any) : undefined;
  }

  /**
   * Update an existing mix graph
   */
  update(mixGraph: MixGraph): void {
    const stmt = this.db.prepare(`
      UPDATE mix_graphs SET
        tracks_json = ?, buses_json = ?, sends_json = ?, master_json = ?,
        updated_at = datetime('now')
      WHERE id = ?
    `);

    stmt.run(
      JSON.stringify(mixGraph.tracks),
      JSON.stringify(mixGraph.buses),
      JSON.stringify(mixGraph.sends),
      JSON.stringify(mixGraph.master),
      mixGraph.id
    );
  }

  /**
   * Delete a mix graph by song ID
   */
  delete(songId: string): void {
    this.db.prepare('DELETE FROM mix_graphs WHERE song_id = ?').run(songId);
  }

  // MARK: - Query Operations

  /**
   * Get all mix graphs
   */
  getAll(): MixGraph[] {
    const rows = this.db.prepare('SELECT * FROM mix_graphs ORDER BY created_at DESC').all();
    return rows.map((row: any) => this.mapRowToMixGraph(row));
  }

  /**
   * Get recently updated mix graphs
   */
  getRecentlyUpdated(limit: number = 20): MixGraph[] {
    const rows = this.db.prepare('SELECT * FROM mix_graphs ORDER BY updated_at DESC LIMIT ?').all(limit);
    return rows.map((row: any) => this.mapRowToMixGraph(row));
  }

  /**
   * Get mix graphs with track count
   */
  getByTrackCount(minTracks: number, maxTracks: number): MixGraph[] {
    const allGraphs = this.getAll();
    return allGraphs.filter(graph => {
      const trackCount = graph.tracks.length;
      return trackCount >= minTracks && trackCount <= maxTracks;
    });
  }

  /**
   * Get mix graphs using specific bus
   */
  getByBusName(busName: string): MixGraph[] {
    const allGraphs = this.getAll();
    return allGraphs.filter(graph =>
      graph.buses.some(bus => bus.name === busName)
    );
  }

  // MARK: - Helper Methods

  /**
   * Map database row to MixGraph model
   */
  private mapRowToMixGraph(row: any): MixGraph {
    return {
      id: row.id,
      songId: row.song_id,
      tracks: JSON.parse(row.tracks_json),
      buses: JSON.parse(row.buses_json),
      sends: JSON.parse(row.sends_json),
      master: JSON.parse(row.master_json)
    };
  }
}
