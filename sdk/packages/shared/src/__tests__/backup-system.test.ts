/**
 * Backup System Tests
 *
 * Comprehensive tests for backup and restore functionality.
 *
 * @module __tests__/backup-system
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import Database from 'better-sqlite3';
import { unlinkSync, existsSync, mkdirSync, rmdirSync } from 'fs';
import { join } from 'path';

import { BackupRepository } from '../persistence/BackupRepository';
import {
  SongDataRepository,
  PerformanceDataRepository,
  UserPreferencesRepository,
} from '../persistence/BackupDataRepositories';
import { BackupManager } from '../services/BackupManager';
import { ExportManager } from '../services/ExportManager';
import type {
  Backup,
  Song,
  Performance,
  UserPreferences,
  RestoreResult,
  ValidationResult,
} from '../types/backup-model';
import {
  createDefaultUserPreferences,
  formatBackupSize,
  validateBackupData,
} from '../types/backup-model';

describe('Backup System', () => {
  let db: Database.Database;
  let backupRepo: BackupRepository;
  let songRepo: SongDataRepository;
  let performanceRepo: PerformanceDataRepository;
  let userPrefsRepo: UserPreferencesRepository;
  let backupManager: BackupManager;
  let exportManager: ExportManager;
  let testDbPath: string;
  let testExportDir: string;

  beforeEach(() => {
    // Create in-memory database for testing
    db = new Database(':memory:');

    // Initialize repositories
    backupRepo = new BackupRepository(db);
    songRepo = new SongDataRepository(db);
    performanceRepo = new PerformanceDataRepository(db);
    userPrefsRepo = new UserPreferencesRepository(db);

    // Initialize managers
    backupManager = new BackupManager(
      backupRepo,
      songRepo,
      performanceRepo,
      userPrefsRepo
    );
    exportManager = new ExportManager(backupManager, backupRepo);

    // Create test export directory
    testExportDir = join(__dirname, '.test-exports');
    if (!existsSync(testExportDir)) {
      mkdirSync(testExportDir, { recursive: true });
    }
  });

  afterEach(() => {
    // Cleanup
    if (db) {
      db.close();
    }

    // Remove test export directory
    if (existsSync(testExportDir)) {
      rmdirSync(testExportDir, { recursive: true });
    }
  });

  // =============================================================================
  // BACKUP MODEL TESTS
  // =============================================================================

  describe('Backup Models', () => {
    it('should create default user preferences', () => {
      const prefs = createDefaultUserPreferences();

      expect(prefs.userId).toBe('default');
      expect(prefs.autoSaveEnabled).toBe(true);
      expect(prefs.autoBackupEnabled).toBe(true);
      expect(prefs.backupIntervalHours).toBe(24);
      expect(prefs.maxBackups).toBe(30);
    });

    it('should format backup size correctly', () => {
      expect(formatBackupSize(500)).toBe('500.00 B');
      expect(formatBackupSize(1024)).toBe('1.00 KB');
      expect(formatBackupSize(1024 * 1024)).toBe('1.00 MB');
      expect(formatBackupSize(1024 * 1024 * 1024)).toBe('1.00 GB');
    });
  });

  // =============================================================================
  // BACKUP REPOSITORY TESTS
  // =============================================================================

  describe('BackupRepository', () => {
    it('should create a backup', () => {
      const backup: Backup = {
        id: 'test-backup-1',
        timestamp: new Date(),
        description: 'Test backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup);

      const retrieved = backupRepo.read('test-backup-1');
      expect(retrieved).toBeDefined();
      expect(retrieved?.id).toBe('test-backup-1');
      expect(retrieved?.description).toBe('Test backup');
    });

    it('should update a backup', () => {
      const backup: Backup = {
        id: 'test-backup-2',
        timestamp: new Date(),
        description: 'Original description',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup);

      const updated: Backup = {
        ...backup,
        description: 'Updated description',
        size: 200,
      };

      backupRepo.update(updated);

      const retrieved = backupRepo.read('test-backup-2');
      expect(retrieved?.description).toBe('Updated description');
      expect(retrieved?.size).toBe(200);
    });

    it('should delete a backup', () => {
      const backup: Backup = {
        id: 'test-backup-3',
        timestamp: new Date(),
        description: 'Test backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup);
      backupRepo.delete('test-backup-3');

      const retrieved = backupRepo.read('test-backup-3');
      expect(retrieved).toBeUndefined();
    });

    it('should get all backups ordered by timestamp', () => {
      const now = new Date();

      const backup1: Backup = {
        id: 'test-backup-4',
        timestamp: new Date(now.getTime() - 1000),
        description: 'Oldest backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      const backup2: Backup = {
        id: 'test-backup-5',
        timestamp: now,
        description: 'Newest backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup1);
      backupRepo.create(backup2);

      const backups = backupRepo.getAll();
      expect(backups).toHaveLength(2);
      expect(backups[0].id).toBe('test-backup-5'); // Newest first
      expect(backups[1].id).toBe('test-backup-4');
    });

    it('should get latest backup', () => {
      const now = new Date();

      const backup1: Backup = {
        id: 'test-backup-6',
        timestamp: new Date(now.getTime() - 1000),
        description: 'Oldest backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      const backup2: Backup = {
        id: 'test-backup-7',
        timestamp: now,
        description: 'Newest backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup1);
      backupRepo.create(backup2);

      const latest = backupRepo.getLatest();
      expect(latest?.id).toBe('test-backup-7');
    });

    it('should count backups', () => {
      expect(backupRepo.count()).toBe(0);

      const backup: Backup = {
        id: 'test-backup-8',
        timestamp: new Date(),
        description: 'Test backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      backupRepo.create(backup);
      expect(backupRepo.count()).toBe(1);
    });

    it('should get total backup size', () => {
      const backup1: Backup = {
        id: 'test-backup-9',
        timestamp: new Date(),
        description: 'Test backup 1',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      const backup2: Backup = {
        id: 'test-backup-10',
        timestamp: new Date(),
        description: 'Test backup 2',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 200,
        version: '1.0.0',
      };

      backupRepo.create(backup1);
      backupRepo.create(backup2);

      expect(backupRepo.getTotalSize()).toBe(300);
    });
  });

  // =============================================================================
  // SONG DATA REPOSITORY TESTS
  // =============================================================================

  describe('SongDataRepository', () => {
    it('should create a song', () => {
      const song: Song = {
        id: 'song-1',
        name: 'Test Song',
        composer: 'Test Composer',
        description: 'Test Description',
        genre: 'Rock',
        duration: 180,
        key: 'C',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
        customMetadata: { mood: 'happy' },
      };

      songRepo.create(song);

      const retrieved = songRepo.read('song-1');
      expect(retrieved).toBeDefined();
      expect(retrieved?.name).toBe('Test Song');
      expect(retrieved?.composer).toBe('Test Composer');
    });

    it('should update a song', () => {
      const song: Song = {
        id: 'song-2',
        name: 'Original Name',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
      };

      songRepo.create(song);

      const updated: Song = {
        ...song,
        name: 'Updated Name',
        updatedAt: new Date(),
      };

      songRepo.update(updated);

      const retrieved = songRepo.read('song-2');
      expect(retrieved?.name).toBe('Updated Name');
    });

    it('should delete a song', () => {
      const song: Song = {
        id: 'song-3',
        name: 'Test Song',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
      };

      songRepo.create(song);
      songRepo.delete('song-3');

      const retrieved = songRepo.read('song-3');
      expect(retrieved).toBeUndefined();
    });

    it('should search songs', () => {
      const song1: Song = {
        id: 'song-4',
        name: 'Bohemian Rhapsody',
        composer: 'Queen',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
      };

      const song2: Song = {
        id: 'song-5',
        name: 'Stairway to Heaven',
        composer: 'Led Zeppelin',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-456',
      };

      songRepo.create(song1);
      songRepo.create(song2);

      const results = songRepo.search('Queen');
      expect(results).toHaveLength(1);
      expect(results[0].id).toBe('song-4');
    });
  });

  // =============================================================================
  // BACKUP MANAGER TESTS
  // =============================================================================

  describe('BackupManager', () => {
    it('should create a backup', async () => {
      const backup = await backupManager.createBackup('Test backup');

      expect(backup).toBeDefined();
      expect(backup.description).toBe('Test backup');
      expect(backup.songsJSON).toBeDefined();
      expect(backup.performancesJSON).toBeDefined();
      expect(backup.preferencesJSON).toBeDefined();
    });

    it('should restore from backup', async () => {
      // Create some test data
      const song: Song = {
        id: 'song-6',
        name: 'Test Song',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
      };

      songRepo.create(song);

      // Create backup
      const backup = await backupManager.createBackup('Test backup');

      // Delete the song
      songRepo.delete('song-6');

      // Restore from backup
      const result: RestoreResult = await backupManager.restoreFromBackup(backup.id);

      expect(result.songsRestored).toBe(1);
      expect(result.errors).toHaveLength(0);
      expect(result.isSuccess).toBe(true);

      // Verify song was restored
      const restoredSong = songRepo.read('song-6');
      expect(restoredSong).toBeDefined();
      expect(restoredSong?.name).toBe('Test Song');
    });

    it('should validate backup integrity', async () => {
      const backup = await backupManager.createBackup('Test backup');

      const result: ValidationResult = backupManager.validateBackup(backup.id);

      expect(result.validSongs).toBe(true);
      expect(result.validPerformances).toBe(true);
      expect(result.validPreferences).toBe(true);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should get backup statistics', async () => {
      await backupManager.createBackup('Backup 1');
      await backupManager.createBackup('Backup 2');
      await backupManager.createBackup('Backup 3');

      const stats = backupManager.getBackupStatistics();

      expect(stats.totalBackups).toBe(3);
      expect(stats.totalSize).toBeGreaterThan(0);
      expect(stats.newestBackup).toBeDefined();
      expect(stats.oldestBackup).toBeDefined();
    });
  });

  // =============================================================================
  // EXPORT MANAGER TESTS
  // =============================================================================

  describe('ExportManager', () => {
    it('should export backup to file', async () => {
      const backup = await backupManager.createBackup('Test backup');
      const exportPath = join(testExportDir, 'test-backup.json');

      await exportManager.exportBackup(backup.id, exportPath);

      expect(existsSync(exportPath)).toBe(true);

      // Cleanup
      unlinkSync(exportPath);
    });

    it('should import backup from file', async () => {
      // Create and export backup
      const originalBackup = await backupManager.createBackup('Original backup');
      const exportPath = join(testExportDir, 'test-import.json');

      await exportManager.exportBackup(originalBackup.id, exportPath);

      // Import backup
      const importedBackup = await exportManager.importBackup(exportPath);

      expect(importedBackup).toBeDefined();
      expect(importedBackup.description).toContain('Imported');
      expect(importedBackup.songsJSON).toBe(originalBackup.songsJSON);

      // Cleanup
      unlinkSync(exportPath);
    });

    it('should export songs to directory', async () => {
      const song: Song = {
        id: 'song-7',
        name: 'Test Song',
        createdAt: new Date(),
        updatedAt: new Date(),
        songDataJSON: '{}',
        determinismSeed: 'seed-123',
      };

      songRepo.create(song);

      const exportDir = join(testExportDir, 'songs');
      await exportManager.exportSongs(exportDir);

      const exportedFile = join(exportDir, 'Test Song.json');
      expect(existsSync(exportedFile)).toBe(true);

      // Cleanup
      unlinkSync(exportedFile);
    });

    it('should generate backup filename', () => {
      const filename = exportManager.generateBackupFilename();

      expect(filename).toMatch(/^whiteroom_backup_\d{4}-\d{2}-\d{2}_\d{6}\.json$/);
    });
  });

  // =============================================================================
  // VALIDATION TESTS
  // =============================================================================

  describe('Validation', () => {
    it('should validate backup data', () => {
      const validBackup: Backup = {
        id: 'test-validation-1',
        timestamp: new Date(),
        description: 'Valid backup',
        songsJSON: '[]',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      const result = validateBackupData(validBackup);

      expect(result.validSongs).toBe(true);
      expect(result.validPerformances).toBe(true);
      expect(result.validPreferences).toBe(true);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should detect invalid songs JSON', () => {
      const invalidBackup: Backup = {
        id: 'test-validation-2',
        timestamp: new Date(),
        description: 'Invalid backup',
        songsJSON: 'invalid json',
        performancesJSON: '[]',
        preferencesJSON: '{}',
        size: 100,
        version: '1.0.0',
      };

      const result = validateBackupData(invalidBackup);

      expect(result.validSongs).toBe(false);
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });
  });

  // =============================================================================
  // PERFORMANCE TESTS
  // =============================================================================

  describe('Performance', () => {
    it('should create backup in under 500ms', async () => {
      const start = Date.now();

      // Create 100 test songs
      for (let i = 0; i < 100; i++) {
        const song: Song = {
          id: `song-perf-${i}`,
          name: `Song ${i}`,
          createdAt: new Date(),
          updatedAt: new Date(),
          songDataJSON: '{}',
          determinismSeed: `seed-${i}`,
        };
        songRepo.create(song);
      }

      const backup = await backupManager.createBackup('Performance test');

      const duration = Date.now() - start;

      expect(duration).toBeLessThan(500);
      expect(backup).toBeDefined();
    });

    it('should restore 100 songs in under 1s', async () => {
      // Create 100 test songs
      const songs: Song[] = [];
      for (let i = 0; i < 100; i++) {
        const song: Song = {
          id: `song-restore-${i}`,
          name: `Song ${i}`,
          createdAt: new Date(),
          updatedAt: new Date(),
          songDataJSON: '{}',
          determinismSeed: `seed-${i}`,
        };
        songRepo.create(song);
        songs.push(song);
      }

      // Create backup
      const backup = await backupManager.createBackup('Performance restore test');

      // Delete all songs
      for (const song of songs) {
        songRepo.delete(song.id);
      }

      // Restore and measure time
      const start = Date.now();
      const result = await backupManager.restoreFromBackup(backup.id);
      const duration = Date.now() - start;

      expect(duration).toBeLessThan(1000);
      expect(result.songsRestored).toBe(100);
      expect(result.isSuccess).toBe(true);
    });
  });
});
