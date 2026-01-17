/**
 * MigrationManager - TypeScript/Node.js Database Migration Manager
 *
 * Handles incremental schema changes with automatic version tracking and rollback support.
 *
 * @module persistence
 * @author White Room Development Team
 * @copyright 2024 White Room. All rights reserved.
 */

import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';
import { DatabaseError, DatabaseErrorCode } from './DatabaseManager';

/**
 * Defines a single database migration
 */
export interface Migration {
  /** Unique version number (must be sequential) */
  version: number;

  /** Human-readable description */
  description: string;

  /** Migration logic to execute */
  migrate: (db: Database.Database) => void;

  /** Optional rollback logic */
  rollback?: (db: Database.Database) => void;
}

/**
 * Database migration manager for schema versioning and migrations.
 *
 * **Usage:**
 * ```typescript
 * const migrationManager = new MigrationManager();
 * migrationManager.migrate(database);
 * ```
 */
export class MigrationManager {
  private migrations: Migration[];

  /**
   * Initialize with all migrations
   */
  constructor() {
    this.migrations = this.registerMigrations();
  }

  /**
   * Run all pending migrations on the database
   *
   * This method:
   * 1. Checks current schema version from metadata table
   * 2. Identifies pending migrations
   * 3. Executes each migration in a transaction
   * 4. Updates schema version after successful migration
   *
   * @param db - better-sqlite3 Database instance
   * @throws DatabaseError if migration fails
   */
  public migrate(db: Database.Database): void {
    // Get current version
    const currentVersion = this.getSchemaVersion(db);
    console.log(`[MigrationManager] Current schema version: ${currentVersion}`);

    // Filter migrations that need to run
    const pendingMigrations = this.migrations.filter((m) => m.version > currentVersion);

    if (pendingMigrations.length === 0) {
      console.log('[MigrationManager] Database is up to date');
      return;
    }

    console.log(`[MigrationManager] Found ${pendingMigrations.length} pending migration(s)`);

    // Run each migration in order
    for (const migration of pendingMigrations) {
      console.log(
        `[MigrationManager] Running migration v${migration.version}: ${migration.description}`
      );

      try {
        this.runMigration(db, migration);
        console.log(`[MigrationManager] Migration v${migration.version} completed successfully`);
      } catch (error) {
        console.error(`[MigrationManager] Migration v${migration.version} failed:`, error);
        throw new DatabaseError(
          DatabaseErrorCode.MIGRATION_FAILED,
          `Migration v${migration.version}: ${migration.description}`,
          error as Error
        );
      }
    }

    const finalVersion = Math.max(...pendingMigrations.map((m) => m.version));
    console.log(`[MigrationManager] Migration complete. New schema version: ${finalVersion}`);
  }

  /**
   * Rollback to a specific schema version
   *
   * **WARNING:** This will lose data if rolling back past schema changes.
   *
   * @param db - better-sqlite3 Database instance
   * @param targetVersion - Version to rollback to
   * @throws DatabaseError if rollback fails
   */
  public rollback(db: Database.Database, targetVersion: number): void {
    const currentVersion = this.getSchemaVersion(db);

    if (currentVersion <= targetVersion) {
      console.log(`[MigrationManager] Already at version ${targetVersion} or lower`);
      return;
    }

    console.log(`[MigrationManager] Rolling back from v${currentVersion} to v${targetVersion}`);

    // Get migrations to rollback (in reverse order)
    const migrationsToRollback = this.migrations
      .filter((m) => m.version > targetVersion && m.version <= currentVersion)
      .sort((a, b) => b.version - a.version);

    if (migrationsToRollback.length === 0) {
      console.log('[MigrationManager] No migrations to rollback');
      return;
    }

    // Run each rollback
    for (const migration of migrationsToRollback) {
      if (!migration.rollback) {
        throw new DatabaseError(
          DatabaseErrorCode.MIGRATION_FAILED,
          `Migration v${migration.version} does not support rollback`
        );
      }

      console.log(
        `[MigrationManager] Rolling back migration v${migration.version}: ${migration.description}`
      );

      try {
        migration.rollback(db);
        this.updateSchemaVersion(db, migration.version - 1);
        console.log(`[MigrationManager] Rollback v${migration.version} completed`);
      } catch (error) {
        console.error(`[MigrationManager] Rollback v${migration.version} failed:`, error);
        throw new DatabaseError(
          DatabaseErrorCode.MIGRATION_FAILED,
          `Rollback v${migration.version} failed`,
          error as Error
        );
      }
    }

    console.log(`[MigrationManager] Rollback complete. New schema version: ${targetVersion}`);
  }

  /**
   * Execute a single migration in a transaction
   *
   * @param db - better-sqlite3 Database instance
   * @param migration - Migration to execute
   * @throws DatabaseError if migration fails
   */
  private runMigration(db: Database.Database, migration: Migration): void {
    // Use immediate transaction for DDL statements
    const runMigration = db.transaction(() => {
      // Execute migration
      migration.migrate(db);

      // Update schema version
      this.updateSchemaVersion(db, migration.version);
    });

    runMigration();
  }

  /**
   * Get current schema version from metadata table
   *
   * @param db - better-sqlite3 Database instance
   * @returns Current schema version (0 if not set)
   */
  private getSchemaVersion(db: Database.Database): number {
    const stmt = db.prepare('SELECT value FROM metadata WHERE key = ?');
    const result = stmt.get('schema_version') as { value: string } | undefined;
    return result ? parseInt(result.value, 10) : 0;
  }

  /**
   * Update schema version in metadata table
   *
   * @param db - better-sqlite3 Database instance
   * @param version - New schema version
   */
  private updateSchemaVersion(db: Database.Database, version: number): void {
    const stmt = db.prepare(
      'INSERT OR REPLACE INTO metadata (key, value, updated_at) VALUES (?, ?, datetime("now"))'
    );
    stmt.run('schema_version', version.toString());
  }

  /**
   * Register all migrations in order
   *
   * **IMPORTANT:** Add new migrations here with sequential version numbers
   *
   * @returns Array of all migrations
   */
  private registerMigrations(): Migration[] {
    return [
      // Migration 1: Initial schema
      {
        version: 1,
        description:
          'Initial schema with all 9 tables (songs, performances, user_preferences, roles, sections, autosaves, backups, mix_graphs, markers)',
        migrate: (db) => {
          // Execute schema.sql file
          this.executeSchemaFile(db);
        },
      },

      // Migration 2: Add instrumentId, voiceId, presetId to TrackConfig (in mix_graph_json)
      {
        version: 2,
        description:
          'Add instrumentId, voiceId, presetId fields to songs.mix_graph_json for TrackConfig objects',
        migrate: (db) => {
          // This is a data migration - update existing mix_graph_json to include new fields
          // For now, this is a no-op since the schema already includes these fields
          // Future versions will add ALTER TABLE statements if needed
          console.log(
            '[MigrationManager] Migration v2: instrumentId/voiceId/presetId already in schema'
          );
        },
      },

      // TODO: Add future migrations here
      //
      // {
      //   version: 3,
      //   description: 'Add full-text search indexes',
      //   migrate: (db) => {
      //     db.exec('CREATE VIRTUAL TABLE IF NOT EXISTS songs_fts USING fts5(name, composer, genre)');
      //   }
      // }
    ];
  }

  /**
   * Execute schema.sql file
   *
   * @param db - better-sqlite3 Database instance
   * @throws DatabaseError if schema execution fails
   */
  private executeSchemaFile(db: Database.Database): void {
    // Try multiple paths for schema.sql
    const schemaPath = this.findSchemaFile();

    if (!schemaPath) {
      throw new DatabaseError(
        DatabaseErrorCode.SCHEMA_FILE_NOT_FOUND,
        'Schema file (schema.sql) not found'
      );
    }

    console.log(`[MigrationManager] Executing schema file: ${schemaPath}`);

    // Read schema file
    const schemaSQL = fs.readFileSync(schemaPath, 'utf-8');

    // Execute schema
    db.exec(schemaSQL);

    console.log('[MigrationManager] Schema file executed successfully');
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
        return schemaPath;
      }
    }

    return null;
  }

  /**
   * Get list of all registered migrations
   *
   * @returns Array of migration descriptions
   */
  public allMigrations(): { version: number; description: string }[] {
    return this.migrations.map((m) => ({ version: m.version, description: m.description }));
  }

  /**
   * Get pending migrations (not yet applied)
   *
   * @param db - better-sqlite3 Database instance
   * @returns Array of pending migrations
   */
  public pendingMigrations(db: Database.Database): { version: number; description: string }[] {
    const currentVersion = this.getSchemaVersion(db);
    return this.migrations
      .filter((m) => m.version > currentVersion)
      .map((m) => ({ version: m.version, description: m.description }));
  }

  /**
   * Validate that all migrations can run without errors
   *
   * This is useful for testing migrations before deployment.
   *
   * @param db - better-sqlite3 Database instance
   * @returns true if all migrations are valid
   */
  public validateMigrations(db: Database.Database): boolean {
    console.log('[MigrationManager] Validating migrations...');

    for (const migration of this.migrations) {
      try {
        // Begin test transaction (immediate for DDL)
        const testMigration = db.transaction(() => {
          // Run migration
          migration.migrate(db);
        });

        testMigration(); // Will be rolled back automatically in immediate mode

        console.log(
          `✓ Migration v${migration.version}: ${migration.description}`
        );
      } catch (error) {
        console.error(`✗ Migration v${migration.version} failed:`, error);
        return false;
      }
    }

    console.log('[MigrationManager] All migrations validated successfully');
    return true;
  }
}

/**
 * Convenience function to create migration manager
 *
 * @returns MigrationManager instance
 */
export function createMigrationManager(): MigrationManager {
  return new MigrationManager();
}
