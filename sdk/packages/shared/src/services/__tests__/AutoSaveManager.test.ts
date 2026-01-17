/**
 * White Room AutoSaveManager Tests (TypeScript)
 *
 * Comprehensive test suite for auto-save functionality.
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { AutoSaveManager } from '../AutoSaveManager';
import { AutoSaveRepository } from '../../persistence/AutoSaveRepository';
import type { SongModel_v2 } from '../../types/song-model';
import { promises as fs } from 'fs';
import * as path from 'path';
import * as os from 'os';

// =============================================================================
// TEST HELPERS
// =============================================================================

function createTestSong(): SongModel_v2 {
  const now = Date.now();
  return {
    version: '2.0',
    id: 'test-song-' + now,
    createdAt: now,
    updatedAt: now,
    metadata: {
      title: 'Test Song',
      composer: 'Test Composer',
      description: 'Test song for auto-save',
      genre: 'Test'
    },
    sections: [
      {
        id: 'section-1',
        name: 'Verse',
        start: { bars: 0, beats: 0, sixteenths: 0 },
        end: { bars: 16, beats: 0, sixteenths: 0 },
        roles: ['role-1']
      },
      {
        id: 'section-2',
        name: 'Chorus',
        start: { bars: 16, beats: 0, sixteenths: 0 },
        end: { bars: 32, beats: 0, sixteenths: 0 },
        roles: ['role-2']
      }
    ],
    roles: [
      {
        id: 'role-1',
        name: 'Bass',
        type: 'bass',
        generatorConfig: {
          generators: [1, 1],
          parameters: {}
        },
        parameters: {}
      },
      {
        id: 'role-2',
        name: 'Melody',
        type: 'melody',
        generatorConfig: {
          generators: [2, 2],
          parameters: {}
        },
        parameters: {}
      }
    ],
    projections: [
      {
        id: 'proj-1',
        roleId: 'role-1',
        target: { type: 'track', id: 'track-1' }
      },
      {
        id: 'proj-2',
        roleId: 'role-2',
        target: { type: 'track', id: 'track-2' }
      }
    ],
    mixGraph: {
      tracks: [
        {
          id: 'track-1',
          name: 'Bass Track',
          volume: 0.8,
          pan: 0.0
        },
        {
          id: 'track-2',
          name: 'Melody Track',
          volume: 0.7,
          pan: 0.0
        }
      ],
      buses: [],
      sends: [],
      master: { volume: 1.0 }
    },
    realizationPolicy: {
      windowSize: { bars: 4, beats: 0, sixteenths: 0 },
      lookaheadDuration: { bars: 1, beats: 0, sixteenths: 0 },
      determinismMode: 'strict'
    },
    determinismSeed: 'test-seed'
  };
}

async function createTempDatabase(): Promise<string> {
  const tempDir = os.tmpdir();
  const dbPath = path.join(tempDir, 'test_autosave_' + Date.now() + '.db');
  return dbPath;
}

async function cleanupDatabase(dbPath: string): Promise<void> {
  try {
    await fs.unlink(dbPath);
  } catch (error) {
    // File might not exist
  }
}

// =============================================================================
// TEST SUITE
// =============================================================================

describe('AutoSaveManager', () => {
  let autoSaveManager: AutoSaveManager;
  let autoSaveRepository: AutoSaveRepository;
  let dbPath: string;

  beforeEach(async () => {
    // Create temporary database
    dbPath = await createTempDatabase();
    autoSaveRepository = new AutoSaveRepository(dbPath);
    autoSaveManager = new AutoSaveManager(autoSaveRepository);
  });

  afterEach(async () => {
    // Cleanup
    autoSaveManager.destroy();
    autoSaveRepository.close();
    await cleanupDatabase(dbPath);
  });

  // --------------------------------------------------------------------------
  // DEBOUNCE TESTS
  // --------------------------------------------------------------------------

  describe('Debouncing', () => {
    it('should debounce saves', async () => {
      const testSong = createTestSong();

      // Mark song as dirty
      autoSaveManager.markDirty(testSong);

      // Check that song is dirty
      expect(autoSaveManager.isDirty).toBe(true);

      // Wait for debounce delay
      await new Promise(resolve => setTimeout(resolve, 2500));

      // Check that save occurred
      expect(autoSaveManager.lastSaveTime).not.toBeNull();
      expect(autoSaveManager.isDirty).toBe(false);
    });

    it('should reset debounce timer on new changes', async () => {
      const testSong = createTestSong();

      // Mark song as dirty
      autoSaveManager.markDirty(testSong);

      // Wait 1 second
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Make another change - should reset debounce timer
      autoSaveManager.markDirty(testSong);

      // Wait 1.5 seconds (total 2.5 seconds from first change)
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Should not have saved yet (debounce was reset)
      expect(autoSaveManager.lastSaveTime).toBeNull();

      // Wait another second
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Now should have saved
      expect(autoSaveManager.lastSaveTime).not.toBeNull();
    });
  });

  // --------------------------------------------------------------------------
  // PERIODIC SAVE TESTS
  // --------------------------------------------------------------------------

  describe('Periodic Saves', () => {
    it('should save immediately when requested', () => {
      const testSong = createTestSong();

      // Mark song as dirty
      autoSaveManager.markDirty(testSong);

      // Save now (skip debounce)
      autoSaveManager.saveNow();

      // Check that save occurred
      expect(autoSaveManager.lastSaveTime).not.toBeNull();
      expect(autoSaveManager.isDirty).toBe(false);
    });
  });

  // --------------------------------------------------------------------------
  // PRUNING TESTS
  // --------------------------------------------------------------------------

  describe('Pruning', () => {
    it('should prune old autosaves', async () => {
      // Create 15 autosaves (more than max of 10)
      for (let i = 0; i < 15; i++) {
        const song = createTestSong();
        autoSaveManager.markDirty(song);
        autoSaveManager.saveNow();
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      // Get all autosaves
      const autosaves = autoSaveManager.getAutosaves();

      // Should have max 10 autosaves
      expect(autosaves.length).toBe(10);
    });
  });

  // --------------------------------------------------------------------------
  // ERROR HANDLING TESTS
  // --------------------------------------------------------------------------

  describe('Error Handling', () => {
    it('should throw error when saving without pending changes', () => {
      expect(() => {
        autoSaveManager.saveNow();
      }).toThrow('No pending save available');
    });

    it('should throw error getting autosaves without current song', () => {
      // Auto-save manager has no current song set
      expect(() => {
        autoSaveManager.getAutosaves();
      }).toThrow('No current song');
    });
  });
});
