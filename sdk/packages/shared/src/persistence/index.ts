/**
 * Persistence Layer - Repository Pattern Implementation
 *
 * Complete data access layer for White Room application with CRUD operations
 * for all entities across Swift and TypeScript platforms.
 *
 * @module persistence
 *
 * @example
 * ```typescript
 * import Database from 'better-sqlite3';
 * import { SongRepository, PerformanceRepository } from './persistence';
 *
 * const db = new Database('white_room.db');
 * const songRepo = new SongRepository(db);
 * const perfRepo = new PerformanceRepository(db);
 *
 * // Create a song
 * songRepo.create({
 *   id: 'song-1',
 *   name: 'My Song',
 *   tempo: 120,
 *   timeSignature: { numerator: 4, denominator: 4 },
 *   // ... other fields
 * });
 *
 * // Query songs
 * const songs = songRepo.getByGenre('Jazz');
 * ```
 */

// -----------------------------------------------------------------------------
// REPOSITORIES
// -----------------------------------------------------------------------------

export { SongRepository } from './SongRepository';
export type { Song as SongModel, SongMetadata } from './SongRepository';

export { PerformanceRepository } from './PerformanceRepository';
export type { Performance, MixTarget, ArrangementStyle } from './PerformanceRepository';

export { UserRepository } from './UserRepository';
export type {
  UserPreferences,
  AudioSettings,
  UISettings,
  ThemeSettings,
  ThemeMode,
  FontSize
} from './UserRepository';

export { AutoSaveRepository } from './AutoSaveRepository';
export type { AutoSave, AutoSaveTriggerType } from './AutoSaveRepository';

export { BackupRepository } from './BackupRepository';
export type { Backup } from './BackupRepository';

export { MixGraphRepository } from './MixGraphRepository';
export type { MixGraph, MixTrack, MixBus, MixSend, MixMaster } from './MixGraphRepository';

export { MarkerRepository } from './MarkerRepository';
export type { Marker } from './MarkerRepository';

// -----------------------------------------------------------------------------
// TYPES
// -----------------------------------------------------------------------------

/**
 * Repository error types
 */
export enum RepositoryError {
  NOT_FOUND = 'NOT_FOUND',
  INVALID_DATA = 'INVALID_DATA',
  DATABASE_ERROR = 'DATABASE_ERROR',
  CONSTRAINT_VIOLATION = 'CONSTRAINT_VIOLATION'
}

/**
 * Repository error class
 */
export class RepositoryException extends Error {
  constructor(
    public type: RepositoryError,
    message: string,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = 'RepositoryException';
  }
}

// -----------------------------------------------------------------------------
// PERFORMANCE TARGETS
// -----------------------------------------------------------------------------

/**
 * Target operation timings (in milliseconds)
 */
export const PERFORMANCE_TARGETS = {
  SONG_LOAD: 50,
  SONG_SAVE: 50,
  PERFORMANCE_LOAD: 30,
  PERFORMANCE_SAVE: 30,
  SEARCH_QUERY: 100,
  BATCH_OPERATION: 200
} as const;

// -----------------------------------------------------------------------------
// UTILITY FUNCTIONS
// -----------------------------------------------------------------------------

/**
 * Measure repository operation performance
 */
export function measurePerformance<T>(
  operation: string,
  fn: () => T,
  targetMs: number
): T {
  const start = Date.now();
  try {
    const result = fn();
    const elapsed = Date.now() - start;

    if (elapsed > targetMs) {
      console.warn(`[Performance] ${operation} took ${elapsed}ms (target: ${targetMs}ms)`);
    }

    return result;
  } catch (error) {
    const elapsed = Date.now() - start;
    console.error(`[Performance] ${operation} failed after ${elapsed}ms`, error);
    throw error;
  }
}

/**
 * Wrap repository operation with error handling
 */
export function wrapOperation<T>(
  operation: string,
  fn: () => T
): T {
  try {
    return fn();
  } catch (error) {
    if (error instanceof RepositoryException) {
      throw error;
    }

    throw new RepositoryException(
      RepositoryError.DATABASE_ERROR,
      `Failed to ${operation}: ${error instanceof Error ? error.message : String(error)}`,
      error instanceof Error ? error : undefined
    );
  }
}
