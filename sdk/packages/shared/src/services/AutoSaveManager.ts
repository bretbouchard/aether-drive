/**
 * White Room AutoSaveManager (TypeScript)
 *
 * Intelligent auto-save system with debouncing and periodic saves.
 * Prevents data loss while avoiding excessive writes.
 */

import { EventEmitter } from 'events';
import { AutoSaveRepository, AutoSave } from '../persistence/AutoSaveRepository';
import type { SongModel_v2 } from '../types/song-model';

// =============================================================================
// AUTO-SAVE MANAGER
// =============================================================================

export class AutoSaveManager extends EventEmitter {
  private autoSaveRepository: AutoSaveRepository;
  private debounceTimer: NodeJS.Timeout | null = null;
  private periodicTimer: NodeJS.Timeout | null = null;
  private pendingSave: {
    songId: string;
    song: SongModel_v2;
    timestamp: Date;
  } | null = null;

  public currentSongId: string | null = null;
  public lastSaveTime: Date | null = null;
  public isDirty: boolean = false;

  // Configuration
  private autoSaveEnabled = true;
  private debounceDelay = 2000;  // 2 seconds
  private periodicInterval = 60000;  // 1 minute
  private maxAutosaves = 10;

  constructor(autoSaveRepository: AutoSaveRepository) {
    super();
    this.autoSaveRepository = autoSaveRepository;
    this.startPeriodicTimer();
  }

  // ---------------------------------------------------------------------------
  // PUBLIC METHODS
  // ---------------------------------------------------------------------------

  /**
   * Mark song as dirty and schedule auto-save
   */
  public markDirty(song: SongModel_v2): void {
    this.isDirty = true;
    this.currentSongId = song.id;

    this.pendingSave = {
      songId: song.id,
      song: song,
      timestamp: new Date()
    };

    // Cancel existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }

    // Start new debounce timer
    this.debounceTimer = setTimeout(() => {
      if (this.autoSaveEnabled && this.pendingSave) {
        this.performAutoSave(this.pendingSave);
      }
    }, this.debounceDelay);
  }

  /**
   * Immediately save current song (skip debounce)
   */
  public saveNow(): void {
    if (!this.pendingSave) {
      throw new Error('No pending save available');
    }

    this.performAutoSave(this.pendingSave);
  }

  /**
   * Discard pending changes
   */
  public discardPendingSave(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }

    this.pendingSave = null;
    this.isDirty = false;
  }

  /**
   * Get all autosaves for current song
   */
  public getAutosaves(): AutoSave[] {
    if (!this.currentSongId) {
      throw new Error('No current song');
    }

    return this.autoSaveRepository.getAllForSong(this.currentSongId);
  }

  /**
   * Restore from autosave
   */
  public restoreFromAutosave(autosaveId: string): SongModel_v2 {
    const autosave = this.autoSaveRepository.read(autosaveId);

    if (!autosave) {
      throw new Error('Auto-save not found');
    }

    return JSON.parse(autosave.songJSON);
  }

  /**
   * Clear all autosaves for current song
   */
  public clearAutosaves(): void {
    if (!this.currentSongId) {
      throw new Error('No current song');
    }

    this.autoSaveRepository.deleteAllForSong(this.currentSongId);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE METHODS
  // ---------------------------------------------------------------------------

  /**
   * Perform auto-save
   */
  private performAutoSave(pending: {
    songId: string;
    song: SongModel_v2;
    timestamp: Date;
  }): void {
    try {
      const autosave: AutoSave = {
        id: this.generateUUID(),
        songId: pending.songId,
        songJSON: JSON.stringify(pending.song),
        timestamp: pending.timestamp,
        description: this.generateDescription(pending.song)
      };

      this.autoSaveRepository.create(autosave);

      this.lastSaveTime = new Date();
      this.isDirty = false;
      this.pendingSave = null;

      this.pruneOldAutosaves(pending.songId);

      this.emit('autosave', autosave);

      console.log(`Auto-saved song: ${pending.song.metadata.title}`);
    } catch (error) {
      this.emit('error', error);
      console.error('Auto-save failed:', error);
    }
  }

  /**
   * Start periodic timer
   */
  private startPeriodicTimer(): void {
    this.periodicTimer = setInterval(() => {
      if (this.autoSaveEnabled && this.isDirty && this.pendingSave) {
        this.performAutoSave(this.pendingSave);
      }
    }, this.periodicInterval);
  }

  /**
   * Prune old autosaves
   */
  private pruneOldAutosaves(songId: string): void {
    const autosaves = this.autoSaveRepository.getAllForSong(songId);

    if (autosaves.length > this.maxAutosaves) {
      // Sort by timestamp, oldest first
      const sorted = autosaves.sort((a, b) =>
        a.timestamp.getTime() - b.timestamp.getTime()
      );

      const toDelete = sorted.slice(this.maxAutosaves);

      for (const autosave of toDelete) {
        this.autoSaveRepository.delete(autosave.id);
      }

      console.log(`AutoSaveManager: Pruned ${toDelete.length} old autosaves`);
    }
  }

  /**
   * Generate description for autosave
   */
  private generateDescription(song: SongModel_v2): string {
    const timestamp = new Date().toLocaleString();
    const trackCount = song.mixGraph.tracks.length;
    const sectionCount = song.sections.length;

    return `Auto-save - ${timestamp} - ${trackCount} tracks, ${sectionCount} sections`;
  }

  /**
   * Generate UUID
   */
  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  public destroy(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }

    if (this.periodicTimer) {
      clearInterval(this.periodicTimer);
      this.periodicTimer = null;
    }

    this.removeAllListeners();
  }
}

// =============================================================================
// ERROR TYPES
// =============================================================================

export class AutoSaveError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'AutoSaveError';
  }
}
