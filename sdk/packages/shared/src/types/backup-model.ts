/**
 * Backup Model
 *
 * Represents a complete backup of all user data including songs, performances, and preferences.
 * Used for data recovery, export/import, and version control.
 *
 * @module types/backup-model
 */

// =============================================================================
// CORE BACKUP MODEL
// =============================================================================

/**
 * Backup - Complete backup of all user data
 */
export interface Backup {
  /** Unique backup identifier */
  id: string;

  /** Backup creation timestamp */
  timestamp: Date;

  /** Human-readable description */
  description: string;

  /** Serialized songs (JSON array) */
  songsJSON: string;

  /** Serialized performances (JSON array) */
  performancesJSON: string;

  /** Serialized user preferences (JSON object) */
  preferencesJSON: string;

  /** Total backup size in bytes */
  size: number;

  /** Application version that created this backup */
  version: string;
}

// =============================================================================
// RESTORE RESULT
// =============================================================================

/**
 * Result of a restore operation
 */
export interface RestoreResult {
  /** Number of songs successfully restored */
  songsRestored: number;

  /** Number of performances successfully restored */
  performancesRestored: number;

  /** Whether preferences were restored */
  preferencesRestored: boolean;

  /** Any errors that occurred during restore */
  errors: string[];

  /** Whether the restore was successful */
  isSuccess: boolean;
}

// =============================================================================
// VALIDATION RESULT
// =============================================================================

/**
 * Result of backup validation
 */
export interface ValidationResult {
  /** Whether songs JSON is valid */
  validSongs: boolean;

  /** Whether performances JSON is valid */
  validPerformances: boolean;

  /** Whether preferences JSON is valid */
  validPreferences: boolean;

  /** Overall validity */
  isValid: boolean;

  /** Validation errors */
  errors: string[];
}

// =============================================================================
// BACKUP EXPORT DATA
// =============================================================================

/**
 * Backup export data format for file I/O
 */
export interface BackupExportData {
  /** Application version */
  version: string;

  /** Backup timestamp */
  timestamp: Date;

  /** Backup description */
  description: string;

  /** Songs JSON data */
  songs: string;

  /** Performances JSON data */
  performances: string;

  /** Preferences JSON data */
  preferences: string;
}

// =============================================================================
// BACKUP STATISTICS
// =============================================================================

/**
 * Backup statistics
 */
export interface BackupStatistics {
  /** Total number of backups */
  totalBackups: number;

  /** Total size of all backups in bytes */
  totalSize: number;

  /** Oldest backup timestamp */
  oldestBackup?: Date;

  /** Newest backup timestamp */
  newestBackup?: Date;

  /** Average backup size in bytes */
  averageSize: number;
}

// =============================================================================
// BACKUP ERROR TYPES
// =============================================================================

/**
 * Backup-related errors
 */
export class BackupError extends Error {
  constructor(
    message: string,
    public code: 'BACKUP_NOT_FOUND' | 'INVALID_BACKUP' | 'RESTORE_FAILED' | 'EXPORT_FAILED' | 'IMPORT_FAILED'
  ) {
    super(message);
    this.name = 'BackupError';
  }
}

// =============================================================================
// SONG MODEL (for backup)
// =============================================================================

/**
 * Song data model
 */
export interface Song {
  /** Unique identifier */
  id: string;

  /** Song title */
  name: string;

  /** Composer name */
  composer?: string;

  /** Song description */
  description?: string;

  /** Musical genre */
  genre?: string;

  /** Song duration in seconds */
  duration?: number;

  /** Musical key */
  key?: string;

  /** Creation timestamp */
  createdAt: Date;

  /** Last modification timestamp */
  updatedAt: Date;

  /** Song data as JSON (SongModel_v2) */
  songDataJSON: string;

  /** Determinism seed for realization */
  determinismSeed: string;

  /** Custom metadata */
  customMetadata?: Record<string, string>;
}

// =============================================================================
// PERFORMANCE MODEL (for backup)
// =============================================================================

/**
 * Performance data model
 */
export interface Performance {
  /** Unique identifier */
  id: string;

  /** Performance name */
  name: string;

  /** Associated song ID */
  songId: string;

  /** Performance description */
  description?: string;

  /** Performance duration in seconds */
  duration: number;

  /** Performance data as JSON (realized events) */
  performanceDataJSON: string;

  /** Creation timestamp */
  createdAt: Date;

  /** Last modification timestamp */
  updatedAt: Date;

  /** Whether this performance is a favorite */
  isFavorite: boolean;

  /** Performance tags */
  tags: string[];
}

// =============================================================================
// USER PREFERENCES MODEL (for backup)
// =============================================================================

/**
 * User preferences and settings
 */
export interface UserPreferences {
  /** Unique user identifier (device-specific) */
  userId: string;

  /** User display name */
  displayName?: string;

  /** Default audio output device */
  defaultOutputDevice?: string;

  /** Default audio input device */
  defaultInputDevice?: string;

  /** Default sample rate */
  defaultSampleRate?: number;

  /** Default buffer size */
  defaultBufferSize?: number;

  /** Whether to enable auto-save */
  autoSaveEnabled: boolean;

  /** Auto-save interval in seconds */
  autoSaveInterval: number;

  /** Whether to enable automatic backups */
  autoBackupEnabled: boolean;

  /** Backup interval in hours */
  backupIntervalHours: number;

  /** Maximum number of backups to keep */
  maxBackups: number;

  /** Theme preference */
  theme?: string;

  /** Language preference */
  language?: string;

  /** Whether to show tooltips */
  showTooltips: boolean;

  /** Custom preferences */
  customPreferences: Record<string, string>;

  /** Last modification timestamp */
  updatedAt: Date;
}

// =============================================================================
// FACTORY FUNCTIONS
// =============================================================================

/**
 * Create an empty restore result
 */
export function createEmptyRestoreResult(): RestoreResult {
  return {
    songsRestored: 0,
    performancesRestored: 0,
    preferencesRestored: false,
    errors: [],
    isSuccess: false,
  };
}

/**
 * Create an empty validation result
 */
export function createEmptyValidationResult(): ValidationResult {
  return {
    validSongs: false,
    validPerformances: false,
    validPreferences: false,
    isValid: false,
    errors: [],
  };
}

/**
 * Create default user preferences
 */
export function createDefaultUserPreferences(): UserPreferences {
  return {
    userId: 'default',
    displayName: undefined,
    defaultOutputDevice: undefined,
    defaultInputDevice: undefined,
    defaultSampleRate: 48000,
    defaultBufferSize: 256,
    autoSaveEnabled: true,
    autoSaveInterval: 300,
    autoBackupEnabled: true,
    backupIntervalHours: 24,
    maxBackups: 30,
    theme: undefined,
    language: undefined,
    showTooltips: true,
    customPreferences: {},
    updatedAt: new Date(),
  };
}

/**
 * Validate backup integrity
 */
export function validateBackupData(backup: Backup): ValidationResult {
  const result: ValidationResult = {
    validSongs: false,
    validPerformances: false,
    validPreferences: false,
    isValid: false,
    errors: [],
  };

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
 * Format backup size for display
 */
export function formatBackupSize(bytes: number): string {
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return `${size.toFixed(2)} ${units[unitIndex]}`;
}

/**
 * Format backup timestamp for display
 */
export function formatBackupTimestamp(timestamp: Date): string {
  return timestamp.toLocaleString();
}
