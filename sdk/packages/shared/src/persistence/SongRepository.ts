/**
 * SongRepository - Repository pattern for Song CRUD operations
 *
 * Provides data access layer for Song entities with better-sqlite3.
 * Synchronous API for optimal performance.
 *
 * @module persistence/SongRepository
 */

import Database from 'better-sqlite3';
import type { Song, SongMetadata, TrackConfig, Section, Role } from '../types/song-model';

/**
 * Repository for Song CRUD operations
 */
export class SongRepository {
  constructor(private db: Database.Database) {}

  // MARK: - CRUD Operations

  /**
   * Create a new song in the database
   */
  create(song: Song): void {
    const stmt = this.db.prepare(`
      INSERT INTO songs (
        id, name, tempo, time_signature_numerator, time_signature_denominator,
        composer, genre, mood, difficulty, rating,
        sections_json, roles_json, mix_graph_json,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    stmt.run(
      song.id,
      song.name,
      song.tempo,
      song.timeSignature.numerator,
      song.timeSignature.denominator,
      song.composer,
      song.genre,
      song.mood,
      song.difficulty,
      song.rating,
      JSON.stringify(song.sections),
      JSON.stringify(song.roles),
      JSON.stringify(song.trackConfigs)
    );
  }

  /**
   * Read a song by ID
   */
  read(id: string): Song | undefined {
    const row = this.db.prepare('SELECT * FROM songs WHERE id = ?').get(id);
    return row ? this.mapRowToSong(row as any) : undefined;
  }

  /**
   * Update an existing song
   */
  update(song: Song): void {
    const stmt = this.db.prepare(`
      UPDATE songs SET
        name = ?, tempo = ?, time_signature_numerator = ?, time_signature_denominator = ?,
        composer = ?, genre = ?, mood = ?, difficulty = ?, rating = ?,
        sections_json = ?, roles_json = ?, mix_graph_json = ?,
        updated_at = datetime('now')
      WHERE id = ?
    `);

    stmt.run(
      song.name,
      song.tempo,
      song.timeSignature.numerator,
      song.timeSignature.denominator,
      song.composer,
      song.genre,
      song.mood,
      song.difficulty,
      song.rating,
      JSON.stringify(song.sections),
      JSON.stringify(song.roles),
      JSON.stringify(song.trackConfigs),
      song.id
    );
  }

  /**
   * Delete a song by ID
   */
  delete(id: string): void {
    this.db.prepare('DELETE FROM songs WHERE id = ?').run(id);
  }

  // MARK: - Query Operations

  /**
   * Get all songs ordered by name
   */
  getAll(): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs ORDER BY name').all();
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Search songs by name, composer, genre, or mood
   */
  search(query: string): Song[] {
    const searchPattern = `%${query}%`;
    const stmt = this.db.prepare(`
      SELECT * FROM songs
      WHERE name LIKE ?
         OR composer LIKE ?
         OR genre LIKE ?
         OR mood LIKE ?
      ORDER BY name
    `);
    const rows = stmt.all(searchPattern, searchPattern, searchPattern, searchPattern);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get songs by genre
   */
  getByGenre(genre: string): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs WHERE genre = ? ORDER BY name').all(genre);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get songs by composer
   */
  getByComposer(composer: string): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs WHERE composer = ? ORDER BY name').all(composer);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get recently created songs
   */
  getRecentlyCreated(limit: number = 20): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs ORDER BY created_at DESC LIMIT ?').all(limit);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get recently updated songs
   */
  getRecentlyUpdated(limit: number = 20): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs ORDER BY updated_at DESC LIMIT ?').all(limit);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get songs within a tempo range
   */
  getByTempoRange(min: number, max: number): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs WHERE tempo BETWEEN ? AND ? ORDER BY tempo').all(min, max);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  /**
   * Get songs by difficulty
   */
  getByDifficulty(difficulty: string): Song[] {
    const rows = this.db.prepare('SELECT * FROM songs WHERE difficulty = ? ORDER BY name').all(difficulty);
    return rows.map((row: any) => this.mapRowToSong(row));
  }

  // MARK: - Helper Methods

  /**
   * Map database row to Song model
   */
  private mapRowToSong(row: any): Song {
    return {
      id: row.id,
      name: row.name,
      tempo: row.tempo,
      timeSignature: {
        numerator: row.time_signature_numerator,
        denominator: row.time_signature_denominator
      },
      composer: row.composer,
      genre: row.genre,
      mood: row.mood,
      difficulty: row.difficulty,
      rating: row.rating,
      trackConfigs: JSON.parse(row.mix_graph_json),
      sections: JSON.parse(row.sections_json),
      roles: JSON.parse(row.roles_json)
    };
  }
}

// MARK: - Supporting Types

/**
 * Song model for repository layer
 */
export interface Song {
  id: string;
  name: string;
  tempo: number;
  timeSignature: { numerator: number; denominator: number };
  composer: string | null;
  genre: string | null;
  mood: string | null;
  difficulty: string | null;
  rating: number | null;
  trackConfigs: TrackConfig[];
  sections: Section[];
  roles: Role[];
}

/**
 * Song metadata
 */
export interface SongMetadata {
  name: string;
  tempo: number;
  timeSignature: { numerator: number; denominator: number };
  composer?: string;
  genre?: string;
  mood?: string;
  difficulty?: string;
  rating?: number;
}
