/**
 * Export Manager
 *
 * Manages export and import of backups to/from files.
 *
 * @module services/ExportManager
 */

import type {
  Backup,
  BackupExportData,
  Song,
  Performance,
  UserPreferences,
} from '../types/backup-model';
import { BackupRepository } from '../persistence/BackupRepository';
import { BackupManager } from './BackupManager';
import { BackupError } from '../types/backup-model';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Manages export and import of backups
 */
export class ExportManager {
  private backupManager: BackupManager;
  private backupRepository: BackupRepository;

  constructor(
    backupManager: BackupManager,
    backupRepository: BackupRepository
  ) {
    this.backupManager = backupManager;
    this.backupRepository = backupRepository;
  }

  // MARK: - Public Methods

  /**
   * Export backup to file
   */
  async exportBackup(backupId: string, filePath: string): Promise<void> {
    const backup = this.backupRepository.read(backupId);

    if (!backup) {
      throw new BackupError('Backup not found', 'BACKUP_NOT_FOUND');
    }

    // Create export data
    const exportData: BackupExportData = {
      version: backup.version,
      timestamp: backup.timestamp,
      description: backup.description,
      songs: backup.songsJSON,
      performances: backup.performancesJSON,
      preferences: backup.preferencesJSON,
    };

    // Encode to JSON
    const jsonData = JSON.stringify(exportData, null, 2);

    // Ensure directory exists
    const directory = path.dirname(filePath);
    if (!fs.existsSync(directory)) {
      fs.mkdirSync(directory, { recursive: true });
    }

    // Write to file
    fs.writeFileSync(filePath, jsonData, 'utf-8');

    console.log(`Exported backup to: ${filePath}`);
  }

  /**
   * Import backup from file
   */
  async importBackup(filePath: string): Promise<Backup> {
    // Read file
    const jsonData = fs.readFileSync(filePath, 'utf-8');

    // Decode
    const exportData: BackupExportData = JSON.parse(jsonData);

    // Validate data
    try {
      JSON.parse(exportData.songs);
    } catch (error) {
      throw new BackupError('Invalid songs data in backup file', 'IMPORT_FAILED');
    }

    // Create backup record
    const backup: Backup = {
      id: this.generateUUID(),
      timestamp: exportData.timestamp,
      description: `${exportData.description} (Imported)`,
      songsJSON: exportData.songs,
      performancesJSON: exportData.performances,
      preferencesJSON: exportData.preferences,
      size: jsonData.length,
      version: exportData.version,
    };

    // Save to database
    this.backupRepository.create(backup);

    console.log(`Imported backup from: ${filePath}`);
    return backup;
  }

  /**
   * Export songs to individual JSON files
   */
  async exportSongs(directoryPath: string): Promise<void> {
    const songs = (this.backupManager as any).songRepository.getAll();

    // Ensure directory exists
    if (!fs.existsSync(directoryPath)) {
      fs.mkdirSync(directoryPath, { recursive: true });
    }

    for (const song of songs) {
      const filename = `${song.name.replace(/\//g, '-')}.json`;
      const filePath = path.join(directoryPath, filename);

      const jsonData = JSON.stringify(song, null, 2);
      fs.writeFileSync(filePath, jsonData, 'utf-8');
    }

    console.log(`Exported ${songs.length} songs to: ${directoryPath}`);
  }

  /**
   * Export performances to individual JSON files
   */
  async exportPerformances(directoryPath: string): Promise<void> {
    const performances = (this.backupManager as any).performanceRepository.getAll();

    // Ensure directory exists
    if (!fs.existsSync(directoryPath)) {
      fs.mkdirSync(directoryPath, { recursive: true });
    }

    for (const performance of performances) {
      const filename = `${performance.name.replace(/\//g, '-')}.json`;
      const filePath = path.join(directoryPath, filename);

      const jsonData = JSON.stringify(performance, null, 2);
      fs.writeFileSync(filePath, jsonData, 'utf-8');
    }

    console.log(`Exported ${performances.length} performances to: ${directoryPath}`);
  }

  /**
   * Export user preferences to JSON file
   */
  async exportPreferences(filePath: string): Promise<void> {
    const preferences = (this.backupManager as any).userPreferencesRepository.getDefault();

    const jsonData = JSON.stringify(preferences, null, 2);

    // Ensure directory exists
    const directory = path.dirname(filePath);
    if (!fs.existsSync(directory)) {
      fs.mkdirSync(directory, { recursive: true });
    }

    fs.writeFileSync(filePath, jsonData, 'utf-8');

    console.log(`Exported preferences to: ${filePath}`);
  }

  /**
   * Import songs from JSON files
   */
  async importSongs(directoryPath: string): Promise<number> {
    const fileNames = fs.readdirSync(directoryPath);
    const jsonFiles = fileNames.filter((name) => name.endsWith('.json'));

    let importedCount = 0;

    for (const fileName of jsonFiles) {
      try {
        const filePath = path.join(directoryPath, fileName);
        const jsonData = fs.readFileSync(filePath, 'utf-8');
        const song: Song = JSON.parse(jsonData);

        // Check if song already exists
        const existing = (this.backupManager as any).songRepository.read(song.id);
        if (existing) {
          // Update existing song
          (this.backupManager as any).songRepository.update(song);
        } else {
          // Create new song
          (this.backupManager as any).songRepository.create(song);
        }

        importedCount++;
      } catch (error) {
        console.error(`Failed to import song from ${fileName}: ${error}`);
      }
    }

    console.log(`Imported ${importedCount} songs from: ${directoryPath}`);
    return importedCount;
  }

  /**
   * Get default export directory
   */
  getDefaultExportDirectory(): string {
    const homeDir = os.homedir();
    const appSupportDir = path.join(homeDir, 'Library', 'Application Support', 'White Room');
    const exportsDir = path.join(appSupportDir, 'Exports');

    if (!fs.existsSync(exportsDir)) {
      fs.mkdirSync(exportsDir, { recursive: true });
    }

    return exportsDir;
  }

  /**
   * Generate default backup filename
   */
  generateBackupFilename(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    return `whiteroom_backup_${year}-${month}-${day}_${hours}${minutes}${seconds}.json`;
  }

  /**
   * Get available exports
   */
  getAvailableExports(): string[] {
    const directory = this.getDefaultExportDirectory();
    const fileNames = fs.readdirSync(directory);
    const jsonFiles = fileNames.filter((name) => name.endsWith('.json'));

    // Get file stats and sort by modification date
    const filesWithStats = jsonFiles.map((fileName) => {
      const filePath = path.join(directory, fileName);
      const stats = fs.statSync(filePath);
      return {
        fileName,
        filePath,
        mtime: stats.mtime,
      };
    });

    // Sort by modification time (newest first)
    filesWithStats.sort((a, b) => b.mtime.getTime() - a.mtime.getTime());

    return filesWithStats.map((file) => file.filePath);
  }

  /**
   * Delete export file
   */
  deleteExport(filePath: string): void {
    fs.unlinkSync(filePath);
    console.log(`Deleted export: ${filePath}`);
  }

  // MARK: - Private Methods

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
}

// Import os module for homedir
import * as os from 'os';
