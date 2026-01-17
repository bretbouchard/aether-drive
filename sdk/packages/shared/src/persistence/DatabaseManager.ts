/**
 * DatabaseManager - TypeScript/Node.js SQLite Database Manager
 *
 * Central database manager for White Room persistence layer.
 * Manages SQLite database connection, WAL mode, and provides access to raw database operations.
 *
 * @module persistence
 * @author White Room Development Team
 * @copyright 2024 White Room. All rights reserved.
 */

import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Database-specific errors
 */
export enum DatabaseErrorCode {
  SCHEMA_FILE_NOT_FOUND = 'SCHEMA_FILE_NOT_FOUND',
  MIGRATION_FAILED = 'MIGRATION_FAILED',
  INITIALIZATION_FAILED = 'INITIALIZATION_FAILED',
  DATABASE_CORRUPTED = 'DATABASE_CORRUPTED',
  CONSTRAINT_VIOLATION = 'CONSTRAINT_VIOLATION',
}

export class DatabaseError extends Error {
  constructor(
    public code: DatabaseErrorCode,
    message: string,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'DatabaseError';
  }
}

/**
 * Central database manager for White Room persistence layer.
 *
 * **Thread Safety:** better-sqlite3 is synchronous and thread-safe by default.
 * **Architecture:** Uses better-sqlite3 for direct SQLite access with prepared statements.
 *
 * @example
 * ```typescript
 * const dbManager = DatabaseManager.getInstance();
 * await dbManager.initialize();
 * const songCount = dbManager.read(db => {
 *   const stmt = db.prepare('SELECT COUNT(*) as count FROM songs');
 *   return stmt.get().count;
 * });
 * ```
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private db: Database.Database;
  private dbPath: string;
  private isInitialized = false;

  /**
   * Private constructor (use getInstance() instead)
   */
  private constructor() {
    // Get database path
    const appSupportPath = this.getApplicationSupportDirectory();
    const databaseDir = path.join(appSupportPath, 'White Room');

    // Create directory if needed
    if (!fs.existsSync(databaseDir)) {
      fs.mkdirSync(databaseDir, { recursive: true });
    }

    // Set database path
    this.dbPath = path.join(databaseDir, 'white_room.db');

    // Create database connection
    try {
      this.db = new Database(this.dbPath);
      console.log(`[DatabaseManager] Database initialized at: ${this.dbPath}`);
    } catch (error) {
      throw new DatabaseError(
        DatabaseErrorCode.INITIALIZATION_FAILED,
        'Failed to initialize database',
        error as Error
      );
    }
  }

  /**
   * Get singleton instance
   *
   * @returns DatabaseManager instance
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * Initialize the database with schema and migrations
   *
   * This method should be called once at app startup. It:
   * 1. Enables WAL mode for concurrent access
   * 2. Runs any pending migrations
   * 3. Creates initial schema if needed
   *
   * @throws DatabaseError if initialization fails
   */
  public async initialize(): Promise<void> {
    try {
      // Setup WAL mode
      this.setupWALMode();
      console.log('[DatabaseManager] WAL mode enabled');

      // Run migrations
      await this.runMigrations();

      this.isInitialized = true;
      console.log('[DatabaseManager] Database initialization complete');
    } catch (error) {
      console.error('[DatabaseManager] Initialization failed:', error);
      throw error;
    }
  }

  /**
   * Get read-only access to the database
   *
   * Use this for SELECT queries and read operations.
   *
   * @param block - Closure receiving Database instance
   * @returns Result of the block
   *
   * @example
   * ```typescript
   * const song = dbManager.read(db => {
   *   const stmt = db.prepare('SELECT * FROM songs WHERE id = ?');
   *   return stmt.get(songId);
   * });
   * ```
   */
  public read<T>(block: (db: Database.Database) => T): T {
    return block(this.db);
  }

  /**
   * Get write access to the database
   *
   * Use this for INSERT, UPDATE, DELETE operations.
   * Automatically wraps the operation in a transaction.
   *
   * @param block - Closure receiving Database instance
   * @returns Result of the block
   *
   * @example
   * ```typescript
   * dbManager.write(db => {
   *   const stmt = db.prepare('INSERT INTO songs (id, name) VALUES (?, ?)');
   *   stmt.run(songId, songName);
   * });
   * ```
   */
  public write<T>(block: (db: Database.Database) => T): T {
    return this.db.transaction(block)();
  }

  /**
   * Check if database is initialized
   */
  public get initialized(): boolean {
    return this.isInitialized;
  }

  /**
   * Get the database file path
   */
  public get databasePath(): string {
    return this.dbPath;
  }

  /**
   * Get the database directory path
   */
  public get databaseDirectoryPath(): string {
    return path.dirname(this.dbPath);
  }

  /**
   * Setup WAL (Write-Ahead Logging) mode for better concurrent access performance
   *
   * WAL mode allows:
   * - Readers don't block writers
   * - Writers don't block readers
   * - Better concurrency for Node.js applications
   */
  private setupWALMode(): void {
    // Enable WAL mode
    this.db.pragma('journal_mode = WAL');

    // Use NORMAL synchronization (safer than OFF, faster than FULL)
    this.db.pragma('synchronous = NORMAL');

    // Set cache size to 64MB (-64000 means 64000KB)
    this.db.pragma('cache_size = -64000');

    // Store temp tables in memory
    this.db.pragma('temp_store = MEMORY');

    // Enable memory-mapped I/O (30GB max)
    this.db.pragma('mmap_size = 30000000000');

    // Enforce foreign key constraints
    this.db.pragma('foreign_keys = ON');

    console.log('[DatabaseManager] WAL mode configured');
  }

  /**
   * Run database migrations
   *
   * Checks current schema version and runs any pending migrations.
   */
  private async runMigrations(): Promise<void> {
    // Get current schema version
    const currentVersion = this.getSchemaVersion();
    console.log(`[DatabaseManager] Current schema version: ${currentVersion}`);

    // TODO: Run migrations based on version
    // For now, just ensure schema is created
    if (currentVersion === 0) {
      this.createInitialSchema();
      this.insertSchemaVersion(1);
    }
  }

  /**
   * Create initial database schema
   *
   * Executes the schema.sql file to create all tables.
   */
  private createInitialSchema(): void {
    console.log('[DatabaseManager] Creating initial schema...');

    // Try multiple paths for schema.sql
    const schemaPath = this.findSchemaFile();

    if (!schemaPath) {
      throw new DatabaseError(
        DatabaseErrorCode.SCHEMA_FILE_NOT_FOUND,
        'Schema file (schema.sql) not found'
      );
    }

    // Read schema file
    const schemaSQL = fs.readFileSync(schemaPath, 'utf-8');

    // Execute schema
    this.db.exec(schemaSQL);
    console.log('[DatabaseManager] Initial schema created');
  }

  /**
   * Find schema.sql file in multiple locations
   *
   * @returns Path to schema.sql or null if not found
   */
  private findSchemaFile(): string | null {
    const possiblePaths = [
      // Try relative to this file
      path.join(__dirname, '../../../../juce_backend/shared/persistence/schema.sql'),
      // Try from package root
      path.join(__dirname, '../../../juce_backend/shared/persistence/schema.sql'),
      // Try from project root
      path.join(process.cwd(), 'juce_backend/shared/persistence/schema.sql'),
      // Try from environment variable
      process.env.PROJECT_ROOT
        ? path.join(process.env.PROJECT_ROOT, 'juce_backend/shared/persistence/schema.sql')
        : null,
    ].filter(Boolean) as string[];

    for (const schemaPath of possiblePaths) {
      if (fs.existsSync(schemaPath)) {
        console.log(`[DatabaseManager] Found schema file: ${schemaPath}`);
        return schemaPath;
      }
    }

    return null;
  }

  /**
   * Insert schema version into metadata table
   *
   * @param version - Schema version number
   */
  private insertSchemaVersion(version: number): void {
    const stmt = this.db.prepare(
      'INSERT OR REPLACE INTO metadata (key, value, updated_at) VALUES (?, ?, datetime("now"))'
    );
    stmt.run('schema_version', version.toString());
    console.log(`[DatabaseManager] Schema version set to: ${version}`);
  }

  /**
   * Get current schema version from metadata table
   *
   * @returns Schema version number (0 if not set)
   */
  private getSchemaVersion(): number {
    const stmt = this.db.prepare('SELECT value FROM metadata WHERE key = ?');
    const result = stmt.get('schema_version') as { value: string } | undefined;
    return result ? parseInt(result.value, 10) : 0;
  }

  /**
   * Get the Application Support directory for the app
   *
   * @returns Path to ~/Library/Application Support/ (macOS) or equivalent
   */
  private getApplicationSupportDirectory(): string {
    const platform = process.platform;

    switch (platform) {
      case 'darwin': // macOS
        return path.join(process.env.HOME || '', 'Library', 'Application Support');

      case 'win32': // Windows
        return process.env.APPDATA || path.join(process.env.HOME || '', 'AppData', 'Roaming');

      case 'linux': // Linux
        return process.env.XDG_DATA_HOME || path.join(process.env.HOME || '', '.local', 'share');

      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
  }
}

/**
 * Database statistics utilities
 */
export class DatabaseStatistics {
  constructor(private dbManager: DatabaseManager) {}

  /**
   * Get database file size in bytes
   *
   * @returns File size in bytes
   */
  public databaseSize(): number {
    const stats = fs.statSync(this.dbManager.databasePath);
    return stats.size;
  }

  /**
   * Get database file size as human-readable string
   *
   * @returns Formatted file size (e.g., "12.5 MB")
   */
  public databaseSizeFormatted(): string {
    const bytes = this.databaseSize();
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(1)} ${units[unitIndex]}`;
  }

  /**
   * Get total number of songs in database
   *
   * @returns Song count
   */
  public songCount(): number {
    return this.dbManager.read((db) => {
      const stmt = db.prepare('SELECT COUNT(*) as count FROM songs');
      const result = stmt.get() as { count: number };
      return result.count;
    });
  }

  /**
   * Get total number of performances in database
   *
   * @returns Performance count
   */
  public performanceCount(): number {
    return this.dbManager.read((db) => {
      const stmt = db.prepare('SELECT COUNT(*) as count FROM performances');
      const result = stmt.get() as { count: number };
      return result.count;
    });
  }

  /**
   * Get current schema version
   *
   * @returns Schema version number
   */
  public schemaVersion(): number {
    return this.dbManager.read((db) => {
      const stmt = db.prepare('SELECT value FROM metadata WHERE key = ?');
      const result = stmt.get('schema_version') as { value: string } | undefined;
      return result ? parseInt(result.value, 10) : 0;
    });
  }

  /**
   * Perform database integrity check
   *
   * @returns true if database passes integrity check
   */
  public checkIntegrity(): boolean {
    return this.dbManager.read((db) => {
      const result = db.pragma('integrity_check', { simple: true });
      return result === 'ok';
    });
  }
}

/**
 * Debugging utilities (development only)
 */
export class DatabaseDebugger {
  constructor(private dbManager: DatabaseManager) {}

  /**
   * Log all table names and row counts
   */
  public debugLogTableCounts(): void {
    const tables = this.dbManager.read((db) => {
      const stmt = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      return stmt.all() as { name: string }[];
    });

    console.log('[DatabaseManager] === Database Statistics ===');
    for (const table of tables) {
      const count = this.dbManager.read((db) => {
        const stmt = db.prepare(`SELECT COUNT(*) as count FROM ${table.name}`);
        const result = stmt.get() as { count: number };
        return result.count;
      });
      console.log(`[DatabaseManager] ${table.name}: ${count} rows`);
    }
    console.log('[DatabaseManager] =============================');
  }

  /**
   * Export database table to JSON for debugging
   *
   * @param tableName - Name of table to export
   * @returns Array of objects representing rows
   */
  public debugExportTable(tableName: string): Record<string, any>[] {
    return this.dbManager.read((db) => {
      const stmt = db.prepare(`SELECT * FROM ${tableName}`);
      return stmt.all() as Record<string, any>[];
    });
  }
}

/**
 * Convenience function to get database statistics
 *
 * @param dbManager - DatabaseManager instance
 * @returns DatabaseStatistics instance
 */
export function getDatabaseStatistics(dbManager: DatabaseManager): DatabaseStatistics {
  return new DatabaseStatistics(dbManager);
}

/**
 * Convenience function to get database debugger (dev only)
 *
 * @param dbManager - DatabaseManager instance
 * @returns DatabaseDebugger instance
 */
export function getDatabaseDebugger(dbManager: DatabaseManager): DatabaseDebugger {
  return new DatabaseDebugger(dbManager);
}
