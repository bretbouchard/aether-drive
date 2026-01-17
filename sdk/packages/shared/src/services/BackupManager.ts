/**
 * Backup Manager
 *
 * Manages backup and restore operations for all user data.
 *
 * @module services/BackupManager
 */

import type {
  Backup,
  RestoreResult,
  ValidationResult,
  BackupStatistics,
  Song,
  Performance,
  UserPreferences,
} from '../types/backup-model';
import { BackupRepository } from '../persistence/BackupRepository';
import { SongDataRepository } from '../persistence/BackupDataRepositories';
import { PerformanceDataRepository } from '../persistence/BackupDataRepositories';
import { UserPreferencesRepository } from '../persistence/BackupDataRepositories';
import { BackupError, createEmptyRestoreResult, createEmptyValidationResult } from '../types/backup-model';

/**
 * Manages backup and restore operations
 */
export class BackupManager {
  private backupRepository: BackupRepository;
  private songRepository: SongDataRepository;
  private performanceRepository: PerformanceDataRepository;
  private userPreferencesRepository: UserPreferencesRepository;

  // Configuration
  private autoBackupEnabled = true;
  private backupIntervalHours = 24;
  private maxBackups = 30;
  private backupTimer: NodeJS.Timeout | null = null;

  constructor(
    backupRepository: BackupRepository,
    songRepository: SongDataRepository,
    performanceRepository: PerformanceDataRepository,
    userPreferencesRepository: UserPreferencesRepository
  ) {
    this.backupRepository = backupRepository;
    this.songRepository = songRepository;
    this.performanceRepository = performanceRepository;
    this.userPreferencesRepository = userPreferencesRepository;

    this.startBackupTimer();
  }

  // MARK: - Public Methods

  /**
   * Create a full backup of all data
   */
  async createBackup(description?: string): Promise<Backup> {
    const timestamp = new Date();

    // Backup songs
    const songs = this.songRepository.getAll();
    const songsJSON = JSON.stringify(songs);

    // Backup performances
    const performances = this.performanceRepository.getAll();
    const performancesJSON = JSON.stringify(performances);

    // Backup user preferences
    const preferences = this.userPreferencesRepository.getDefault();
    const preferencesJSON = JSON.stringify(preferences);

    // Calculate backup size
    const backupSize = songsJSON.length + performancesJSON.length + preferencesJSON.length;

    // Create backup record
    const backup: Backup = {
      id: this.generateUUID(),
      timestamp: timestamp,
      description: description || this.generateDescription(),
      songsJSON: songsJSON,
      performancesJSON: performancesJSON,
      preferencesJSON: preferencesJSON,
      size: backupSize,
      version: this.getCurrentVersion(),
    };

    // Save to database
    this.backupRepository.create(backup);

    // Prune old backups
    await this.pruneOldBackups();

    console.log(`Created backup: ${backup.description}`);
    return backup;
  }

  /**
   * Restore from backup
   */
  async restoreFromBackup(backupId: string): Promise<RestoreResult> {
    const backup = this.backupRepository.read(backupId);

    if (!backup) {
      throw new BackupError('Backup not found', 'BACKUP_NOT_FOUND');
    }

    const result: RestoreResult = createEmptyRestoreResult();

    // Restore songs
    const songs: Song[] = JSON.parse(backup.songsJSON);
    for (const song of songs) {
      try {
        // Check if song already exists
        const existing = this.songRepository.read(song.id);
        if (existing) {
          // Update existing song
          this.songRepository.update(song);
        } else {
          // Create new song
          this.songRepository.create(song);
        }
        result.songsRestored++;
      } catch (error) {
        result.errors.push(`Failed to restore song: ${song.name}`);
      }
    }

    // Restore performances
    const performances: Performance[] = JSON.parse(backup.performancesJSON);
    for (const performance of performances) {
      try {
        // Check if performance already exists
        const existing = this.performanceRepository.read(performance.id);
        if (existing) {
          // Update existing performance
          this.performanceRepository.update(performance);
        } else {
          // Create new performance
          this.performanceRepository.create(performance);
        }
        result.performancesRestored++;
      } catch (error) {
        result.errors.push(`Failed to restore performance: ${performance.name}`);
      }
    }

    // Restore user preferences
    const preferences: UserPreferences = JSON.parse(backup.preferencesJSON);
    this.userPreferencesRepository.upsert(preferences);
    result.preferencesRestored = true;

    result.isSuccess = result.errors.length === 0 && result.songsRestored > 0;

    console.log(`Restored backup: ${backup.description}`);
    return result;
  }

  /**
   * Get all backups
   */
  getAllBackups(): Backup[] {
    return this.backupRepository.getAll();
  }

  /**
   * Get latest backup
   */
  getLatestBackup(): Backup | undefined {
    return this.backupRepository.getLatest();
  }

  /**
   * Delete backup
   */
  deleteBackup(backupId: string): void {
    this.backupRepository.delete(backupId);
  }

  /**
   * Get backup size in bytes
   */
  getBackupSize(backupId: string): number {
    const backup = this.backupRepository.read(backupId);

    if (!backup) {
      throw new BackupError('Backup not found', 'BACKUP_NOT_FOUND');
    }

    return backup.size;
  }

  /**
   * Validate backup integrity
   */
  validateBackup(backupId: string): ValidationResult {
    const backup = this.backupRepository.read(backupId);

    if (!backup) {
      throw new BackupError('Backup not found', 'BACKUP_NOT_FOUND');
    }

    const result: ValidationResult = createEmptyValidationResult();

    // Validate songs JSON
    try {
      JSON.parse(backup.songsJSON);
      result.validSongs = true;
    } catch (error) {
      result.errors.push(`Invalid songs JSON: ${error}`);
    }

    // Validate performances JSON
    try {
      JSON.parse(backup.performancesJSON);
      result.validPerformances = true;
    } catch (error) {
      result.errors.push(`Invalid performances JSON: ${error}`);
    }

    // Validate preferences JSON
    try {
      JSON.parse(backup.preferencesJSON);
      result.validPreferences = true;
    } catch (error) {
      result.errors.push(`Invalid preferences JSON: ${error}`);
    }

    result.isValid = result.validSongs && result.validPerformances && result.validPreferences;

    return result;
  }

  /**
   * Get backup statistics
   */
  getBackupStatistics(): BackupStatistics {
    const backups = this.backupRepository.getAll();
    const totalSize = this.backupRepository.getTotalSize();
    const count = backups.length;

    return {
      totalBackups: count,
      totalSize: totalSize,
      oldestBackup: backups.length > 0 ? backups[backups.length - 1].timestamp : undefined,
      newestBackup: backups.length > 0 ? backups[0].timestamp : undefined,
      averageSize: count > 0 ? Math.floor(totalSize / count) : 0,
    };
  }

  // MARK: - Private Methods

  /**
   * Start backup timer
   */
  private startBackupTimer(): void {
    const interval = this.backupIntervalHours * 3600 * 1000; // Convert to milliseconds

    this.backupTimer = setInterval(() => {
      if (this.autoBackupEnabled) {
        this.createBackup('Scheduled backup');
      }
    }, interval);
  }

  /**
   * Prune old backups
   */
  private async pruneOldBackups(): Promise<void> {
    const backups = this.backupRepository.getAll();

    if (backups.length > this.maxBackups) {
      // Sort by timestamp, oldest first
      const sorted = backups.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      const toDelete = sorted.slice(this.maxBackups);

      for (const backup of toDelete) {
        this.backupRepository.delete(backup.id);
      }
    }
  }

  /**
   * Generate description for backup
   */
  private generateDescription(): string {
    const timestamp = new Date().toLocaleString();
    return `Backup - ${timestamp}`;
  }

  /**
   * Get current version
   */
  private getCurrentVersion(): string {
    // TODO: Read from package.json
    return '1.0.0';
  }

  /**
   * Generate UUID
   */
  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  /**
   * Cleanup
   */
  destroy(): void {
    if (this.backupTimer) {
      clearInterval(this.backupTimer);
    }
  }
}
