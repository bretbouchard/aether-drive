# White Room Persistence Implementation Plan

## Executive Summary

**Goal:** Implement a scalable, cross-platform persistence system that saves all critical user data across song, performance, and user levels.

**Strategy:** Use **SQLite** as the primary database with **better-sqlite3** (TypeScript) and **GRDB** (Swift) for maximum compatibility and scalability.

**Timeline:** 3 weeks (15 business days)

**Priority:** Critical - Prevents data loss and enables reproducibility

---

## Architecture Overview

### Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    Cross-Platform Layer                     │
│                  SQLite Database Engine                     │
├─────────────────────────────────────────────────────────────┤
│                    Swift Platform                           │
│                     GRDB Framework                          │
├─────────────────────────────────────────────────────────────┤
│                    TypeScript Platform                       │
│                   better-sqlite3 Library                     │
├─────────────────────────────────────────────────────────────┤
│                    Shared Schema                            │
│            SQL DDL (Database Definition Language)            │
└─────────────────────────────────────────────────────────────┘
```

### Why SQLite?

✅ **Cross-Platform** - Works on iOS, macOS, Windows, Linux, Web (WASM)
✅ **Scalable** - Handles millions of records efficiently
✅ **Queryable** - SQL queries, indexing, joins
✅ **Reliable** - ACID transactions, crash recovery
✅ **Embedded** - No separate server process
✅ **Battle-Tested** - Used by billions of devices
✅ **Tooling** - Excellent browser tools (DB Browser for SQLite)

### File Structure

```
~/Library/Application Support/White Room/
├── data.db                         # Main SQLite database
├── data.db-shm                     # Shared memory (WAL mode)
├── data.db-wal                     # Write-ahead log
├── backups/                        # Automatic backups
│   ├── data_2024-01-16_120000.db
│   └── data_2024-01-17_120000.db
├── exports/                        # User exports
│   ├── songs_export_2024-01-16.json
│   └── full_backup_2024-01-16.zip
└── logs/                           # Transaction logs
    └── persistence.log
```

---

## Database Schema

### Entity Relationship Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    Songs     │────<│ Performances │────>│ Instruments  │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │
       v                    v
┌──────────────┐     ┌──────────────┐
│    Roles     │     │    Tracks    │
└──────────────┘     └──────────────┘
       │                    │
       v                    v
┌──────────────┐     ┌──────────────┐
│  Sections    │     │   MixGraph   │
└──────────────┘     └──────────────┘
                            │
                            v
                     ┌──────────────┐
                     │ EffectChains │
                     └──────────────┘

┌──────────────────┐
│ UserPreferences  │
└──────────────────┘
```

### SQL Schema

```sql
-- =============================================================================
-- SCHEMA VERSION 1.0
-- =============================================================================

PRAGMA journal_mode = WAL;              -- Write-ahead logging for performance
PRAGMA synchronous = NORMAL;            -- Balance safety and speed
PRAGMA cache_size = -64000;             -- 64MB cache
PRAGMA temp_store = MEMORY;             -- Use RAM for temp tables
PRAGMA mmap_size = 30000000000;         -- Memory-map I/O

-- =============================================================================
-- SONGS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS songs (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '1.0',
    created_at INTEGER NOT NULL,        -- Unix timestamp
    updated_at INTEGER NOT NULL,        -- Unix timestamp

    -- Song Metadata
    tempo REAL NOT NULL DEFAULT 120.0,
    time_signature_numerator INTEGER NOT NULL DEFAULT 4,
    time_signature_denominator INTEGER NOT NULL DEFAULT 4,
    duration_seconds REAL,
    key TEXT,
    tags TEXT,                          -- JSON array: ["jazz", "upbeat"]
    composer TEXT,
    genre TEXT,
    mood TEXT,
    comments TEXT,
    difficulty TEXT,                     -- 'beginner' | 'intermediate' | 'advanced' | 'expert'
    rating INTEGER,                     -- 1-5 stars

    -- Realization
    determinism_seed TEXT NOT NULL,
    realization_policy_json TEXT,       -- JSON: RealizationPolicy

    -- JSON fields for complex structures
    sections_json TEXT NOT NULL,         -- JSON: [Section]
    roles_json TEXT NOT NULL,            -- JSON: [Role]
    projections_json TEXT NOT NULL,      -- JSON: [Projection]
    mix_graph_json TEXT NOT NULL,        -- JSON: MixGraph

    -- Performance state
    is_favorite INTEGER DEFAULT 0,
    play_count INTEGER DEFAULT 0,
    last_played_at INTEGER,
    auto_save_id TEXT                    -- Foreign key to autosaves
);

CREATE INDEX idx_songs_name ON songs(name);
CREATE INDEX idx_songs_created_at ON songs(created_at);
CREATE INDEX idx_songs_updated_at ON songs(updated_at);
CREATE INDEX idx_songs_tags ON songs(tags);
CREATE INDEX idx_songs_genre ON songs(genre);
CREATE INDEX idx_songs_is_favorite ON songs(is_favorite);

-- =============================================================================
-- PERFORMANCES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS performances (
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,               -- Foreign key to songs
    name TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '1.0',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,

    -- Arrangement
    arrangement_style TEXT NOT NULL,     -- 'SOLO_PIANO' | 'SATB' | 'ROCK_BAND' | etc.
    density REAL NOT NULL DEFAULT 1.0,
    groove_profile_id TEXT NOT NULL DEFAULT 'default',

    -- Instrumentation (JSON for flexibility)
    instrumentation_map_json TEXT NOT NULL,  -- JSON: {roleId: {instrumentId, presetId, parameters}}

    -- Mix
    console_x_profile_id TEXT NOT NULL DEFAULT 'default',
    mix_targets_json TEXT NOT NULL,      -- JSON: {roleId: {volume, pan, stereo}}

    -- Enhancements (JSON for scalability)
    effects_chains_json TEXT,            -- JSON: [EffectChain]
    automation_json TEXT,                -- JSON: [AutomationCurve]
    markers_json TEXT,                   -- JSON: [Marker]
    loop_points_json TEXT,               -- JSON: LoopPoints
    tempo_map_json TEXT,                 -- JSON: [TempoChange]
    time_signature_map_json TEXT,        -- JSON: [TimeSigChange]
    key_changes_json TEXT,               -- JSON: [KeyChange]
    sections_json TEXT,                  -- JSON: [PerformanceSection]

    -- Metadata
    metadata_json TEXT,                  -- JSON: {custom fields}
    is_favorite INTEGER DEFAULT 0,
    play_count INTEGER DEFAULT 0,
    last_played_at INTEGER,

    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE INDEX idx_performances_song_id ON performances(song_id);
CREATE INDEX idx_performances_name ON performances(name);
CREATE INDEX idx_performances_arrangement_style ON performances(arrangement_style);
CREATE INDEX idx_performances_is_favorite ON performances(is_favorite);

-- =============================================================================
-- USER PREFERENCES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_preferences (
    id TEXT PRIMARY KEY NOT NULL DEFAULT 'default',
    version TEXT NOT NULL DEFAULT '1.0',
    updated_at INTEGER NOT NULL,

    -- Audio Settings
    audio_device TEXT,
    sample_rate INTEGER DEFAULT 44100,
    buffer_size INTEGER DEFAULT 512,
    input_device TEXT,
    output_device TEXT,

    -- MIDI Settings
    midi_input_devices_json TEXT,        -- JSON: ["Device 1", "Device 2"]
    midi_output_devices_json TEXT,
    midi_clock_enabled INTEGER DEFAULT 0,

    -- UI Settings
    theme TEXT DEFAULT 'system',         -- 'light' | 'dark' | 'system'
    font_size TEXT DEFAULT 'medium',     -- 'small' | 'medium' | 'large' | 'extraLarge'
    color_scheme TEXT DEFAULT 'blue',
    show_keyboard_shortcuts INTEGER DEFAULT 1,
    auto_save_interval REAL DEFAULT 60.0,

    -- Window/Layout
    window_state_json TEXT,              -- JSON: {mainWindow: {x, y, w, h}, ...}
    panel_layout_json TEXT,              -- JSON: {visiblePanels: [...], ...}
    splitter_positions_json TEXT,        -- JSON: {splitter1: 0.5, ...}

    -- Library
    library_folders_json TEXT,           -- JSON: ["/path/to/songs"]
    default_save_location TEXT,
    recent_songs_json TEXT,              -- JSON: ["/path/to/song1", ...]
    favorite_songs_json TEXT,            -- JSON: ["song-id-1", ...]
    favorite_performances_json TEXT,     -- JSON: ["perf-id-1", ...]
    favorite_instruments_json TEXT,      -- JSON: ["inst-id-1", ...]

    -- Editing
    auto_quantize INTEGER DEFAULT 0,
    snap_to_grid INTEGER DEFAULT 1,
    grid_size_bars REAL DEFAULT 1.0,
    undo_history_size INTEGER DEFAULT 100,

    -- Performance
    default_tempo REAL DEFAULT 120.0,
    default_time_signature_numerator INTEGER DEFAULT 4,
    default_time_signature_denominator INTEGER DEFAULT 4,
    default_key TEXT DEFAULT 'C major',
    metronome_enabled INTEGER DEFAULT 1,
    count_in_enabled INTEGER DEFAULT 0,
    count_in_bars INTEGER DEFAULT 4,

    -- Export
    default_export_format TEXT DEFAULT 'wav',
    default_export_quality TEXT DEFAULT 'high',
    normalize_on_export INTEGER DEFAULT 1,

    -- Advanced
    lookahead_enabled INTEGER DEFAULT 1,
    deterministic_mode INTEGER DEFAULT 0,
    telemetry_enabled INTEGER DEFAULT 1,
    crash_reports_enabled INTEGER DEFAULT 1,
    analytics_enabled INTEGER DEFAULT 1,

    -- Developer
    developer_mode INTEGER DEFAULT 0,
    verbose_logging INTEGER DEFAULT 0,
    performance_metrics INTEGER DEFAULT 0
);

-- =============================================================================
-- INSTRUMENTS TABLE (Instrument Registry)
-- =============================================================================

CREATE TABLE IF NOT EXISTS instruments (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,                  -- 'synth' | 'sampler' | 'piano' | 'guitar' | etc.
    category TEXT,                      -- 'Local' | 'Kane Marco' | 'Third Party'
    plugin_id TEXT,                     -- Plugin identifier (if applicable)
    is_builtin INTEGER DEFAULT 1,
    is_available INTEGER DEFAULT 1,

    -- Metadata
    manufacturer TEXT,
    version TEXT,
    description TEXT,
    tags TEXT,                          -- JSON: ["piano", "electric"]
    custom_data_json TEXT,               -- JSON: {custom fields}

    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_instruments_name ON instruments(name);
CREATE INDEX idx_instruments_type ON instruments(type);
CREATE INDEX idx_instruments_category ON instruments(category);

-- =============================================================================
-- VOICES TABLE (Multi-timbral Instruments)
-- =============================================================================

CREATE TABLE IF NOT EXISTS voices (
    id TEXT PRIMARY KEY NOT NULL,
    instrument_id TEXT NOT NULL,         -- Foreign key to instruments
    name TEXT NOT NULL,
    number INTEGER NOT NULL,             -- Voice number (1-16)

    -- Voice characteristics
    midi_channel INTEGER,
    midi_program INTEGER,
    key_range_low INTEGER DEFAULT 0,
    key_range_high INTEGER DEFAULT 127,
    velocity_range_low INTEGER DEFAULT 0,
    velocity_range_high INTEGER DEFAULT 127,

    -- Metadata
    description TEXT,
    color TEXT,
    icon TEXT,

    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,

    FOREIGN KEY (instrument_id) REFERENCES instruments(id) ON DELETE CASCADE
);

CREATE INDEX idx_voices_instrument_id ON voices(instrument_id);
CREATE INDEX idx_voices_number ON voices(number);

-- =============================================================================
-- PRESETS TABLE (Instrument Presets)
-- =============================================================================

CREATE TABLE IF NOT EXISTS presets (
    id TEXT PRIMARY KEY NOT NULL,
    instrument_id TEXT NOT NULL,         -- Foreign key to instruments
    voice_id TEXT,                       -- Optional: specific voice
    name TEXT NOT NULL,
    category TEXT,                       -- 'Piano', 'Synth Lead', 'Pad', etc.

    -- Preset data
    parameters_json TEXT NOT NULL,       -- JSON: {param1: value1, ...}
    is_builtin INTEGER DEFAULT 0,
    is_readonly INTEGER DEFAULT 0,

    -- Metadata
    description TEXT,
    tags TEXT,                          -- JSON: ["bright", "piano"]
    rating INTEGER,                     -- 1-5 stars
    author TEXT,

    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,

    FOREIGN KEY (instrument_id) REFERENCES instruments(id) ON DELETE CASCADE
);

CREATE INDEX idx_presets_instrument_id ON presets(instrument_id);
CREATE INDEX idx_presets_voice_id ON presets(voice_id);
CREATE INDEX idx_presets_name ON presets(name);
CREATE INDEX idx_presets_category ON presets(category);

-- =============================================================================
-- AUTOSAVES TABLE (Auto-Save Snapshots)
-- =============================================================================

CREATE TABLE IF NOT EXISTS autosaves (
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,               -- Foreign key to songs
    performance_id TEXT,                 -- Optional: Foreign key to performances
    name TEXT NOT NULL,                  -- Auto-generated: "Auto-Save 2:34 PM"

    -- Snapshot data
    snapshot_json TEXT NOT NULL,         -- JSON: Complete state snapshot
    created_at INTEGER NOT NULL,

    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE INDEX idx_autosaves_song_id ON autosaves(song_id);
CREATE INDEX idx_autosaves_created_at ON autosaves(created_at);

-- =============================================================================
-- RECENTLY_USED TABLE (Recently Opened Items)
-- =============================================================================

CREATE TABLE IF NOT EXISTS recently_used (
    id TEXT PRIMARY KEY NOT NULL,
    item_type TEXT NOT NULL,             -- 'song' | 'performance' | 'instrument' | 'preset'
    item_id TEXT NOT NULL,               -- ID of the item
    item_name TEXT NOT NULL,             -- For display
    accessed_at INTEGER NOT NULL,

    -- Metadata for quick display
    metadata_json TEXT                   -- JSON: {thumbnail_url, duration, etc.}
);

CREATE INDEX idx_recently_used_item_type ON recently_used(item_type);
CREATE INDEX idx_recently_used_accessed_at ON recently_used(accessed_at DESC);

-- =============================================================================
-- METADATA TABLE (Schema Version & Migrations)
-- =============================================================================

CREATE TABLE IF NOT EXISTS metadata (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
);

-- Initialize with schema version
INSERT INTO metadata (key, value) VALUES ('schema_version', '1.0');

-- =============================================================================
-- TRIGGERS (Automatic Timestamps)
-- =============================================================================

CREATE TRIGGER IF NOT EXISTS songs_updated_at
AFTER UPDATE ON songs
FOR EACH ROW
BEGIN
    UPDATE songs SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS performances_updated_at
AFTER UPDATE ON performances
FOR EACH ROW
BEGIN
    UPDATE performances SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS instruments_updated_at
AFTER UPDATE ON instruments
FOR EACH ROW
BEGIN
    UPDATE instruments SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS voices_updated_at
AFTER UPDATE ON voices
FOR EACH ROW
BEGIN
    UPDATE voices SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS presets_updated_at
AFTER UPDATE ON presets
FOR EACH ROW
FOR EACH ROW
BEGIN
    UPDATE presets SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;
```

---

## Implementation Phases

### Phase 1: Foundation (Days 1-3)

**Goal:** Set up SQLite database infrastructure

#### Tasks:

1. **Create SQL Schema File**
   - File: `infrastructure/persistence/schema.sql`
   - Contains all CREATE TABLE statements
   - Include indexes, triggers, constraints

2. **Swift: GRDB Integration**
   - Add GRDB dependency to Swift Package Manager
   - Create `DatabaseManager.swift` (GRDB wrapper)
   - Create table record structs (Codable structs mapping to tables)
   - Implement connection pooling
   - Enable WAL mode for performance

3. **TypeScript: better-sqlite3 Integration**
   - Add better-sqlite3 to package.json
   - Create `DatabaseManager.ts` (better-sqlite3 wrapper)
   - Create table interface definitions (TypeScript interfaces)
   - Implement prepared statements for performance

4. **Migration System**
   - Create `MigrationManager` (Swift & TypeScript)
   - Implement schema versioning
   - Create migration scripts (1.0 → 1.1, etc.)
   - Add automatic migration on startup

#### Deliverables:
- ✅ SQLite database file created with all tables
- ✅ DatabaseManager classes for both platforms
- ✅ Migration system working
- ✅ Unit tests for database operations

---

### Phase 2: Data Model Enhancements (Days 4-6)

**Goal:** Add missing fields to existing data models

#### Tasks:

1. **Swift Model Updates**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Audio/SongModels.swift`

   ```swift
   // Enhance TrackConfig
   public struct TrackConfig: Identifiable, Codable, Sendable {
       public var id: String
       public var name: String
       public var volume: Double
       public var pan: Double
       public var mute: Bool
       public var solo: Bool

       // ✅ NEW FIELDS
       public var instrumentId: String?       // TrackConfig.instrumentId
       public var voiceId: String?            // TrackConfig.voiceId
       public var presetId: String?           // TrackConfig.presetId
       public var midiChannel: Int?           // 1-16
       public var midiProgram: Int?           // 0-127

       public var additionalParameters: [String: CodableAny]?
   }

   // Enhance Role
   public struct Role: Identifiable, Codable, Sendable {
       public var id: String
       public var name: String
       public var type: RoleType
       public var generatorConfig: GeneratorConfig
       public var parameters: RoleParameters

       // ✅ NEW FIELDS
       public var enabled: Bool = true        // Role.enabled
       public var color: String?              // Hex color
       public var icon: String?               // Icon name
   }

   // Enhance SongMetadata
   public struct SongMetadata: Codable, Sendable {
       public var tempo: Double
       public var timeSignature: [Int]
       public var duration: Double?
       public var key: String?
       public var tags: [String]

       // ✅ NEW FIELDS
       public var composer: String?           // SongMetadata.composer
       public var genre: String?              // SongMetadata.genre
       public var mood: String?               // SongMetadata.mood
       public var comments: String?           // SongMetadata.comments
       public var difficulty: Difficulty?     // SongMetadata.difficulty
       public var rating: Int?                // 1-5 stars

       public enum Difficulty: String, Codable {
           case beginner, intermediate, advanced, expert
       }
   }
   ```

2. **TypeScript Model Updates**

   **File:** `sdk/packages/shared/src/types/song-model.ts`

   ```typescript
   // Enhance TrackConfig (already has instrumentId, just add others)
   export interface TrackConfig {
       id: string;
       name: string;
       volume: number;
       pan: number;
       mute: boolean;
       solo: boolean;

       // ✅ NEW FIELDS
       voiceId?: string;              // TrackConfig.voiceId
       presetId?: string;             // TrackConfig.presetId
       midiChannel?: number;          // 1-16
       midiProgram?: number;          // 0-127

       additionalParameters?: Record<string, unknown>;
   }

   // Enhance Role
   export interface Role_v1 {
       id: string;
       name: string;
       type: RoleType;
       generatorConfig: GeneratorConfig;
       parameters: RoleParameters;

       // ✅ NEW FIELDS
       enabled?: boolean;             // Role.enabled
       color?: string;                // Hex color
       icon?: string;                 // Icon name
   }
   ```

3. **Create New Models**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Models/UserPreferences.swift`

   ```swift
   public struct UserPreferences: Codable, Sendable {
       // Audio Settings
       public var audioDevice: String?
       public var sampleRate: Int
       public var bufferSize: Int
       public var inputDevice: String?
       public var outputDevice: String?

       // MIDI Settings
       public var midiInputDevices: [String]
       public var midiOutputDevices: [String]
       public var midiClockEnabled: Bool

       // UI Settings
       public var theme: Theme
       public var fontSize: FontSize
       public var colorScheme: ColorScheme
       public var showKeyboardShortcuts: Bool
       public var autoSaveInterval: TimeInterval

       // ... (all fields from PERSISTENCE_ARCHITECTURE.md)

       public init() {
           // Set sensible defaults
           self.theme = .system
           self.fontSize = .medium
           self.sampleRate = 44100
           self.bufferSize = 512
           // ... (all defaults)
       }
   }
   ```

   **File:** `sdk/packages/shared/src/types/user-preferences.ts`

   ```typescript
   export interface UserPreferences {
       // Audio Settings
       audioDevice?: string;
       sampleRate: number;
       bufferSize: number;
       inputDevice?: string;
       outputDevice?: string;

       // MIDI Settings
       midiInputDevices: string[];
       midiOutputDevices: string[];
       midiClockEnabled: boolean;

       // ... (all fields from PERSISTENCE_ARCHITECTURE.md)
   }
   ```

#### Deliverables:
- ✅ All missing fields added to Swift models
- ✅ All missing fields added to TypeScript models
- ✅ UserPreferences model created
- ✅ Backward compatibility maintained
- ✅ Unit tests for model updates

---

### Phase 3: Persistence Layer (Days 7-10)

**Goal:** Implement CRUD operations for all entities

#### Tasks:

1. **Swift: GRDB Operations**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/SongRepository.swift`

   ```swift
   import GRDB

   public class SongRepository {
       private let db: DatabaseQueue

       public init(db: DatabaseQueue) {
           self.db = db
       }

       // CREATE
       public func save(_ song: Song) throws {
           try db.write { database in
               try song.insert(database)
           }
       }

       // READ
       public func load(id: String) throws -> Song? {
           return try db.read { database in
               try Song.fetchOne(database, key: id)
           }
       }

       public func loadAll() throws -> [Song] {
           return try db.read { database in
               try Song.order(Column("updatedAt").desc).fetchAll(database)
           }
       }

       public func search(query: String) throws -> [Song] {
           return try db.read { database in
               try Song
                   .filter(Column("name").like("%\(query)%"))
                   .or(Column("tags").like("%\(query)%"))
                   .order(Column("updatedAt").desc)
                   .fetchAll(database)
           }
       }

       // UPDATE
       public func update(_ song: Song) throws {
           try db.write { database in
               try song.update(database)
           }
       }

       // DELETE
       public func delete(id: String) throws {
           try db.write { database in
               _ = try Song.deleteOne(database, key: id)
           }
       }

       // BATCH OPERATIONS
       public func saveAll(_ songs: [Song]) throws {
           try db.write { database in
               for song in songs {
                   try song.save(database)
               }
           }
       }

       // COUNT
       public func count() throws -> Int {
           return try db.read { database in
               try Song.fetchCount(database)
           }
       }
   }
   ```

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/PerformanceRepository.swift`

   ```swift
   import GRDB

   public class PerformanceRepository {
       private let db: DatabaseQueue

       public init(db: DatabaseQueue) {
           self.db = db
       }

       // CRUD operations
       public func save(_ performance: PerformanceState_v1, forSong songId: String) throws
       public func load(id: String, forSong songId: String) throws -> PerformanceState_v1?
       public func loadAll(forSong songId: String) throws -> [PerformanceState_v1]
       public func update(_ performance: PerformanceState_v1) throws
       public func delete(id: String) throws
       public func count(forSong songId: String) throws -> Int
   }
   ```

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/UserPreferencesRepository.swift`

   ```swift
   import GRDB

   public class UserPreferencesRepository {
       private let db: DatabaseQueue

       public init(db: DatabaseQueue) {
           self.db = db
       }

       public func save(_ preferences: UserPreferences) throws
       public func load() throws -> UserPreferences?
       public func update(_ preferences: UserPreferences) throws
   }
   ```

2. **TypeScript: better-sqlite3 Operations**

   **File:** `sdk/packages/core/src/persistence/SongRepository.ts`

   ```typescript
   import Database from 'better-sqlite3';

   export class SongRepository {
       private db: Database.Database;

       constructor(db: Database.Database) {
           this.db = db;
       }

       // CREATE
       save(song: SongModel_v1): void {
           const stmt = this.db.prepare(`
               INSERT OR REPLACE INTO songs (
                   id, name, version, created_at, updated_at,
                   tempo, time_signature_numerator, time_signature_denominator,
                   duration_seconds, key, tags, composer, genre, mood, comments,
                   difficulty, rating, determinism_seed, realization_policy_json,
                   sections_json, roles_json, projections_json, mix_graph_json,
                   is_favorite, play_count, last_played_at
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           `);

               // Convert SongModel to JSON
               const sectionsJson = JSON.stringify(song.sections);
               const rolesJson = JSON.stringify(song.roles);
               const projectionsJson = JSON.stringify(song.projections);
               const mixGraphJson = JSON.stringify(song.mixGraph);

               stmt.run(
                   song.id,
                   song.name,
                   song.version,
                   song.createdAt,
                   song.updatedAt,
                   song.metadata.tempo,
                   song.metadata.timeSignature[0],
                   song.metadata.timeSignature[1],
                   song.metadata.duration,
                   song.metadata.key,
                   JSON.stringify(song.metadata.tags),
                   // ... etc
               );
           }

       // READ
           load(id: string): SongModel_v1 | null {
               const stmt = this.db.prepare('SELECT * FROM songs WHERE id = ?');
               const row = stmt.get(id);

               if (!row) return null;

               return this.rowToSong(row);
           }

           loadAll(): SongModel_v1[] {
               const stmt = this.db.prepare(`
                   SELECT * FROM songs
                   ORDER BY updated_at DESC
               `);

               return stmt.all().map(row => this.rowToSong(row));
           }

           search(query: string): SongModel_v1[] {
               const stmt = this.db.prepare(`
                   SELECT * FROM songs
                   WHERE name LIKE ?
                      OR tags LIKE ?
                      OR composer LIKE ?
                   ORDER BY updated_at DESC
               `);

               const pattern = `%${query}%`;
               return stmt.all(pattern, pattern, pattern).map(row => this.rowToSong(row));
           }

       // UPDATE
       update(song: SongModel_v1): void {
           this.save(song);  // UPSERT
       }

       // DELETE
           delete(id: string): void {
               const stmt = this.db.prepare('DELETE FROM songs WHERE id = ?');
               stmt.run(id);
           }

       // BATCH
       saveAll(songs: SongModel_v1[]): void {
           const transaction = this.db.transaction(() => {
               for (const song of songs) {
                   this.save(song);
               }
           });

           transaction();
       }

       // COUNT
       count(): number {
           const stmt = this.db.prepare('SELECT COUNT(*) as count FROM songs');
           const row = stmt.get() as { count: number };
           return row.count;
       }

       // Helper: Convert DB row to SongModel
       private rowToSong(row: any): SongModel_v1 {
               return {
                   id: row.id,
                   name: row.name,
                   version: row.version,
                   createdAt: row.created_at,
                   updatedAt: row.updated_at,
                   metadata: {
                       tempo: row.tempo,
                       timeSignature: [row.time_signature_numerator, row.time_signature_denominator],
                       duration: row.duration_seconds,
                       key: row.key,
                       tags: JSON.parse(row.tags || '[]'),
                       composer: row.composer,
                       genre: row.genre,
                       mood: row.mood,
                       comments: row.comments,
                       difficulty: row.difficulty,
                       rating: row.rating,
                   },
                   sections: JSON.parse(row.sections_json),
                   roles: JSON.parse(row.roles_json),
                   projections: JSON.parse(row.projections_json),
                   mixGraph: JSON.parse(row.mix_graph_json),
                   realizationPolicy: JSON.parse(row.realization_policy_json),
                   determinismSeed: row.determinism_seed,
               };
           }
   }
   ```

   **File:** `sdk/packages/core/src/persistence/PerformanceRepository.ts`

   ```typescript
   export class PerformanceRepository {
       // Similar CRUD operations for performances
       save(performance: PerformanceState_v1, songId: string): void
       load(id: string, songId: string): PerformanceState_v1 | null
       loadAll(songId: string): PerformanceState_v1[]
       update(performance: PerformanceState_v1): void
       delete(id: string): void
       count(songId: string): number
   }
   ```

3. **Repository Manager**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/RepositoryManager.swift`

   ```swift
   public class RepositoryManager {
       public static let shared = RepositoryManager()

       private let db: DatabaseQueue
       public let songs: SongRepository
       public let performances: PerformanceRepository
       public let userPreferences: UserPreferencesRepository
       public let instruments: InstrumentRepository
       public let voices: VoiceRepository
       public let presets: PresetRepository

       private init() {
           let dbPath = databaseFileURL()
           self.db = try! DatabaseQueue(path: dbPath.path)

           // Initialize repositories
           self.songs = SongRepository(db: db)
           self.performances = PerformanceRepository(db: db)
           self.userPreferences = UserPreferencesRepository(db: db)
           self.instruments = InstrumentRepository(db: db)
           self.voices = VoiceRepository(db: db)
           self.presets = PresetRepository(db: db)

           // Migrate database on startup
           try! migrateDatabaseIfNeeded(db: db)
       }

       private func databaseFileURL() -> URL {
           let paths = FileManager.default.urls(
               for: .applicationSupportDirectory,
               in: .userDomainMask
           )

           let appSupport = paths.first!
           let whiteRoomURL = appSupport.appendingPathComponent("White Room", isDirectory: true)

           try! FileManager.default.createDirectory(at: whiteRoomURL, withIntermediateDirectories: true)

           return whiteRoomURL.appendingPathComponent("data.db")
       }
   }
   ```

   **File:** `sdk/packages/core/src/persistence/RepositoryManager.ts`

   ```typescript
   export class RepositoryManager {
       private static instance: RepositoryManager;
       public readonly songs: SongRepository;
       public readonly performances: PerformanceRepository;
       public readonly userPreferences: UserPreferencesRepository;
       public readonly instruments: InstrumentRepository;

       private constructor(dbPath: string) {
           const db = new Database(dbPath, {
               verbose: process.env.NODE_ENV === 'development'
           });

           // Enable WAL mode
               db.pragma('journal_mode = WAL');
               db.pragma('synchronous = NORMAL');

           // Initialize repositories
           this.songs = new SongRepository(db);
           this.performances = new PerformanceRepository(db);
           this.userPreferences = new UserPreferencesRepository(db);
           this.instruments = new InstrumentRepository(db);

           // Migrate database on startup
           this.migrateDatabaseIfNeeded(db);
       }

       public static getInstance(): RepositoryManager {
           if (!this.instance) {
               const dbPath = getDatabasePath();
               this.instance = new RepositoryManager(dbPath);
           }
           return this.instance;
       }

       private migrateDatabaseIfNeeded(db: Database.Database): void {
           const currentVersion = db.pragma('user_version', { simple: true });
           const targetVersion = 1;  // Schema version

           if (currentVersion < targetVersion) {
               console.log(`Migrating database from v${currentVersion} to v${targetVersion}`);
               // Run migrations
               this.runMigrations(db, currentVersion, targetVersion);
           }
       }
   }
   ```

#### Deliverables:
- ✅ SongRepository (Swift & TypeScript)
- ✅ PerformanceRepository (Swift & TypeScript)
- ✅ UserPreferencesRepository (Swift & TypeScript)
- ✅ InstrumentRepository (Swift & TypeScript)
- ✅ VoiceRepository (Swift & TypeScript)
- ✅ PresetRepository (Swift & TypeScript)
- ✅ RepositoryManager (Swift & TypeScript)
- ✅ CRUD operations for all entities
- ✅ Batch operations
- ✅ Search functionality
- ✅ Unit tests with 90%+ coverage

---

### Phase 4: Auto-Save System (Days 11-12)

**Goal:** Implement automatic saving to prevent data loss

#### Tasks:

1. **Swift Auto-Save Manager**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/AutoSaveManager.swift`

   ```swift
   import Combine

   public class AutoSaveManager: ObservableObject {
       public static let shared = AutoSaveManager()

       @Published public var isAutoSaving: Bool = false
       @Published public var lastAutoSaveAt: Date?

       private var autoSaveTimer: Timer?
       private var pendingSaveWorkItem: DispatchWorkItem?

       private let repository: SongRepository
       private let autoSaveInterval: TimeInterval = 60.0  // 1 minute
       private let debounceDelay: TimeInterval = 2.0       // 2 seconds

       private init(repository: SongRepository = RepositoryManager.shared.songs) {
           self.repository = repository
       }

       public func startAutoSaving(for song: Song) {
           // Cancel any pending save
           pendingSaveWorkItem?.cancel()

           // Debounce rapid changes
           let workItem = DispatchWorkItem { [weak self] in
               self?.saveSong(song)
           }

           pendingSaveWorkItem = workItem

           if UserDefaults.standard.bool(forKey: "autoSaveOnChanges") {
               DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
           }

           // Periodic saves
           autoSaveTimer?.invalidate()
           autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
               self?.saveSong(song)
           }
       }

       public func stopAutoSaving() {
           autoSaveTimer?.invalidate()
           autoSaveTimer = nil
           pendingSaveWorkItem?.cancel()
           pendingSaveWorkItem = nil
       }

       private func saveSong(_ song: Song) {
           isAutoSaving = true
           defer { isAutoSaving = false }

           do {
               try repository.save(song)
               lastAutoSaveAt = Date()

               // Create auto-save snapshot
               try createAutoSaveSnapshot(for: song.id)

               print("[AutoSave] Saved song: \(song.name)")
           } catch {
               print("[AutoSave] Failed to save song: \(error)")
           }
       }

       private func createAutoSaveSnapshot(for songId: String) throws {
           let snapshot = AutoSave(
               id: UUID().uuidString,
               songId: songId,
               name: "Auto-Save \(DateFormatter.shortTime.string(from: Date()))",
               snapshotData: Data(),  // Complete state
               createdAt: Date()
           )

           // Save to autosaves table
           // This allows users to restore previous versions
       }
   }
   ```

2. **TypeScript Auto-Save Manager**

   **File:** `sdk/packages/core/src/persistence/AutoSaveManager.ts`

   ```typescript
   export class AutoSaveManager {
       private static instance: AutoSaveManager;
       private autoSaveTimer: NodeJS.Timeout | null = null;
       private pendingSaveTimeout: NodeJS.Timeout | null = null;

       private readonly songRepository: SongRepository;
       private readonly autoSaveInterval: number = 60000;  // 1 minute
       private readonly debounceDelay: number = 2000;       // 2 seconds

       private constructor(songRepository: SongRepository) {
           this.songRepository = songRepository;
       }

       public static getInstance(): AutoSaveManager {
           if (!this.instance) {
               const songRepo = RepositoryManager.getInstance().songs;
               this.instance = new AutoSaveManager(songRepo);
           }
           return this.instance;
       }

       public startAutoSaving(song: SongModel_v1): void {
           // Cancel any pending save
           if (this.pendingSaveTimeout) {
               clearTimeout(this.pendingSaveTimeout);
           }

           // Debounce rapid changes
           this.pendingSaveTimeout = setTimeout(() => {
               this.saveSong(song);
           }, this.debounceDelay);

           // Periodic saves
           if (this.autoSaveTimer) {
               clearInterval(this.autoSaveTimer);
           }

           this.autoSaveTimer = setInterval(() => {
               this.saveSong(song);
           }, this.autoSaveInterval);
       }

       public stopAutoSaving(): void {
           if (this.autoSaveTimer) {
               clearInterval(this.autoSaveTimer);
               this.autoSaveTimer = null;
           }

           if (this.pendingSaveTimeout) {
               clearTimeout(this.pendingSaveTimeout);
               this.pendingSaveTimeout = null;
           }
       }

       private saveSong(song: SongModel_v1): void {
           try {
               this.songRepository.save(song);
               this.createAutoSaveSnapshot(song.id);
               console.log(`[AutoSave] Saved song: ${song.name}`);
           } catch (error) {
               console.error(`[AutoSave] Failed to save song: ${error}`);
           }
       }

       private createAutoSaveSnapshot(songId: string): void {
           // Create snapshot in autosaves table
           // This allows users to restore previous versions
       }
   }
   ```

#### Deliverables:
- ✅ AutoSaveManager (Swift & TypeScript)
- ✅ Debounced saves on changes
- ✅ Periodic saves every 60 seconds
- ✅ Auto-save snapshots for versioning
- ✅ Configurable interval
- ✅ Graceful shutdown
- ✅ Unit tests

---

### Phase 5: Backup & Restore (Days 13-14)

**Goal:** Implement backup and restore functionality

#### Tasks:

1. **Backup Manager**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/BackupManager.swift`

   ```swift
   public class BackupManager {
       private let db: DatabaseQueue

       public init(db: DatabaseQueue) {
           self.db = db
       }

       public func createBackup() throws -> URL {
           let timestamp = ISO8601DateFormatter().string(from: Date())

           let backupURL = try backupDirectory()
               .appendingPathComponent("data_\(timestamp).db")

           // Close database
           db.close()

           // Copy database file
           let sourceURL = databaseFileURL()
           let fm = FileManager.default

           if fm.fileExists(atPath: backupURL.path) {
               try fm.removeItem(at: backupURL)
           }

           try fm.copyItem(at: sourceURL, to: backupURL)

           // Reopen database
           try db.open()

           return backupURL
       }

       public func restoreBackup(from backupURL: URL) throws {
           // Validate backup
           guard FileManager.default.fileExists(atPath: backupURL.path) else {
               throw BackupError.backupNotFound(backupURL)
           }

           // Confirm with user (this will overwrite all data)
           // TODO: Show alert dialog

           // Close database
           db.close()

           // Backup current data
           let currentBackup = try createBackup()

           // Copy backup file
           let targetURL = databaseFileURL()
           try FileManager.default.removeItem(at: targetURL)
           try FileManager.default.copyItem(at: backupURL, to: targetURL)

           // Reopen database
           try db.open()

           // Verify backup integrity
           try verifyDatabaseIntegrity()
       }

       public func listBackups() throws -> [BackupInfo] {
           let backupDir = try backupDirectory()
           let files = try FileManager.default.contentsOfDirectory(
               at: backupDir,
               includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
           )

           return try files.compactMap { url in
               guard url.pathExtension == "db" else { return nil }

               let values = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
               let created = values.creationDate!
               let size = values.fileSize!

               return BackupInfo(
                   url: url,
                   createdAt: created,
                   size: ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
               )
           }.sorted { $0.createdAt > $1.createdAt }  // Newest first
       }

       private func backupDirectory() throws -> URL {
           let paths = FileManager.default.urls(
               for: .applicationSupportDirectory,
               in: .userDomainMask
           )

           let appSupport = paths.first!
           let whiteRoomURL = appSupport.appendingPathComponent("White Room", isDirectory: true)

           let backupURL = whiteRoomURL.appendingPathComponent("backups", isDirectory: true)
           try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)

           return backupURL
       }

       private func databaseFileURL() -> URL {
           // Get main database file URL
           // Same as RepositoryManager.databaseFileURL()
           let paths = FileManager.default.urls(
               for: .applicationSupportDirectory,
               in: .userDomainMask
           )

           let appSupport = paths.first!
           return appSupport
               .appendingPathComponent("White Room", isDirectory: true)
               .appendingPathComponent("data.db")
       }

       private func verifyDatabaseIntegrity() throws {
           // Run PRAGMA integrity_check
           try db.read { database in
               let result = try String.fetchOne(database, sql: "PRAGMA integrity_check")

               if result != "ok" {
                   throw BackupError.databaseCorrupted(result ?? "Unknown error")
               }
           }
       }
   }

   public struct BackupInfo {
       public let url: URL
       public let createdAt: Date
       public let size: String
   }

   public enum BackupError: Error {
       case backupNotFound(URL)
       case databaseCorrupted(String)
       case restoreFailed(underlying: Error)
   }
   ```

2. **TypeScript Backup Manager**

   ```typescript
   import * as fs from 'fs';
   import * as path from 'path';

   export class BackupManager {
       private db: Database.Database;

       constructor(db: Database.Database) {
           this.db = db;
       }

       public async createBackup(): Promise<string> {
           const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
           const backupDir = this.getBackupDirectory();
           const backupPath = path.join(backupDir, `data_${timestamp}.db`);

           // Ensure backup directory exists
           await fs.promises.mkdir(backupDir, { recursive: true });

           // Close database
           this.db.close();

           // Copy database file
           const dbPath = this.getDatabasePath();
           await fs.promises.copyFile(dbPath, backupPath);

           // Reopen database
           this.db.open();

           return backupPath;
       }

       public async restoreBackup(backupPath: string): Promise<void> {
           // Validate backup exists
               if (!fs.existsSync(backupPath)) {
                   throw new Error(`Backup not found: ${backupPath}`);
               }

           // Close database
           this.db.close();

           // Backup current data
           const currentBackup = await this.createBackup();

           // Copy backup file
           const dbPath = this.getDatabasePath();

           if (fs.existsSync(dbPath)) {
               await fs.promises.unlink(dbPath);
           }

           await fs.promises.copyFile(backupPath, dbPath);

           // Reopen database
           this.db.open();

           // Verify integrity
           await this.verifyDatabaseIntegrity();
       }

       public async listBackups(): Promise<BackupInfo[]> {
           const backupDir = this.getBackupDirectory();
           const files = await fs.promises.readdir(backupDir);

           const backups = await Promise.all(
               files
                   .filter(f => f.endsWith('.db'))
                   .map(async filename => {
                       const filePath = path.join(backupDir, filename);
                       const stats = await fs.promises.stat(filePath);

                       return {
                           path: filePath,
                           createdAt: stats.mtime,
                           size: this.formatBytes(stats.size)
                       };
                   })
           );

           return backups.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
       }

       private getBackupDirectory(): string {
           const appDataPath = getAppDataPath();
           return path.join(appDataPath, 'White Room', 'backups');
       }

       private getDatabasePath(): string {
           const appDataPath = getAppDataPath();
           return path.join(appDataPath, 'White Room', 'data.db');
       }

       private formatBytes(bytes: number): string {
           if (bytes < 1024) return bytes + ' B';
           if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
           return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
       }

       private async verifyDatabaseIntegrity(): Promise<void> {
           const result = this.db.pragma('integrity_check', { simple: true });
           if (result !== 'ok') {
               throw new Error(`Database corrupted: ${result}`);
           }
       }
   }

   interface BackupInfo {
       path: string;
       createdAt: Date;
       size: string;
   }
   ```

3. **Export/Import**

   **File:** `swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Persistence/ExportManager.swift`

   ```swift
   public class ExportManager {
       private let repositoryManager: RepositoryManager

       public init(repositoryManager: RepositoryManager = .shared) {
           self.repositoryManager = repositoryManager
       }

       public func exportAllSongs(to url: URL) throws {
           let songs = try repositoryManager.songs.loadAll()

           let exportData = try JSONEncoder().encode(songs)
           try exportData.write(to: url)
       }

       public func exportSong(_ song: Song, to url: URL) throws {
           let exportData = try JSONEncoder().encode(song)
           try exportData.write(to: url)
       }

       public func exportPerformance(_ performance: PerformanceState_v1, to url: URL) throws {
           let exportData = try JSONEncoder().encode(performance)
           try exportData.write(to: url)
       }

       public func importSong(from url: URL) throws -> Song {
           let data = try Data(contentsOf: url)
           return try JSONDecoder().decode(Song.self, from: data)
       }

       public func importSongs(from url: URL) throws -> [Song] {
           let data = try Data(contentsOf: url)
           return try JSONDecoder().decode([Song].self, from: data)
       }
   }
   ```

#### Deliverables:
- ✅ BackupManager (Swift & TypeScript)
- ✅ Create backup with timestamp
- ✅ Restore backup with validation
- ✅ List all backups
- ✅ Export to JSON
- ✅ Import from JSON
- ✅ Integrity checking
- ✅ Unit tests

---

### Phase 6: Testing & Documentation (Days 15)

**Goal:** Comprehensive testing and documentation

#### Tasks:

1. **Unit Tests**

   **Swift Tests:**
   - `SongRepositoryTests.swift` - CRUD operations
   - `PerformanceRepositoryTests.swift` - CRUD operations
   - `UserPreferencesRepositoryTests.swift` - Preferences
   - `AutoSaveManagerTests.swift` - Auto-save functionality
   - `BackupManagerTests.swift` - Backup/restore
   - `MigrationTests.swift` - Schema migrations

   **TypeScript Tests:**
   - `songRepository.test.ts` - CRUD operations
   - `performanceRepository.test.ts` - CRUD operations
   - `userPreferencesRepository.test.ts` - Preferences
   - `autoSaveManager.test.ts` - Auto-save
   - `backupManager.test.ts` - Backup/restore
   - `migration.test.ts` - Schema migrations

2. **Integration Tests**

   - Test complete song save/load cycle
   - Test performance save/load cycle
   - Test auto-save triggers
   - Test backup/restore workflow
   - Test migration from old schema
   - Test concurrent access

3. **Documentation**

   - **API Documentation** - JSDoc/SwiftDoc comments
   - **User Guide** - How to use backup/restore
   - **Developer Guide** - How to add new migrations
   - **Schema Reference** - Database schema documentation
   - **Troubleshooting** - Common issues and solutions

#### Deliverables:
- ✅ 50+ unit tests (90%+ coverage)
- ✅ 10+ integration tests
- ✅ Complete API documentation
- ✅ User guide
- ✅ Developer guide
- ✅ Schema reference
- ✅ Troubleshooting guide

---

## Success Criteria

### Must Have (Blocking)

- ✅ All Priority 1 fields implemented (instrumentId, voiceId, presetId, etc.)
- ✅ SQLite database working on both platforms
- ✅ CRUD operations for all entities
- ✅ Auto-save system operational
- ✅ Backup/restore functionality
- ✅ Migration system in place
- ✅ 90%+ test coverage
- ✅ Cross-platform compatibility verified

### Should Have (Important)

- ✅ Search functionality
- ✅ Batch operations
- ✅ Export/import JSON
- ✅ Performance benchmarks (<100ms for most operations)
- ✅ Error handling and recovery
- ✅ Transaction support

### Nice to Have (Future)

- ⏳ iCloud sync
- ⏳ Cloud backup
- ⏳ Database encryption
- ⏳ Full-text search
- ⏳ Query optimization
- ⏳ Distributed transactions

---

## Risk Mitigation

### Risk 1: Data Loss During Migration

**Mitigation:**
- Always create backup before migration
- Test migrations on sample data first
- Implement rollback mechanism
- Validate migration success before committing

### Risk 2: Performance Issues

**Mitigation:**
- Use indexes on frequently queried columns
- Batch operations when possible
- Use prepared statements
- Profile and optimize slow queries
- Enable WAL mode for concurrent access

### Risk 3: Cross-Platform Compatibility

**Mitigation:**
- Use SQL standard syntax
- Avoid platform-specific features
- Test on all target platforms
- Use TypeScript/Swift type checking
- Validate data integrity

### Risk 4: Schema Evolution

**Mitigation:**
- Use semantic versioning
- Implement forward/backward migrations
- Never drop columns (add only)
- Document all schema changes
- Test migration paths

---

## Dependencies

### Swift

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0")
]
```

### TypeScript

```json
// package.json
{
  "dependencies": {
    "better-sqlite3": "^9.0.0"
  },
  "devDependencies": {
    "@types/better-sqlite3": "^7.6.8"
  }
}
```

---

## File Structure

```
white_room/
├── infrastructure/
│   └── persistence/
│       ├── schema.sql                 # SQL schema definition
│       ├── migrations/                # Migration scripts
│       │   ├── 001_initial.sql
│       │   ├── 002_add_instrument_id.sql
│       │   └── 003_add_performance_enhancements.sql
│       └── seeds/                     # Seed data (optional)
│           └── 001_default_instruments.sql
│
├── swift_frontend/WhiteRoomiOS/
│   └── Sources/SwiftFrontendCore/
│       └── Persistence/
│           ├── DatabaseManager.swift
│           ├── SongRepository.swift
│           ├── PerformanceRepository.swift
│           ├── UserPreferencesRepository.swift
│           ├── InstrumentRepository.swift
│           ├── VoiceRepository.swift
│           ├── PresetRepository.swift
│           ├── RepositoryManager.swift
│           ├── AutoSaveManager.swift
│           ├── BackupManager.swift
│           ├── ExportManager.swift
│           └── MigrationManager.swift
│
├── sdk/packages/core/src/
│   └── persistence/
│       ├── DatabaseManager.ts
│       ├── SongRepository.ts
│       ├── PerformanceRepository.ts
│       ├── UserPreferencesRepository.ts
│       ├── InstrumentRepository.ts
│       ├── VoiceRepository.ts
│       ├── PresetRepository.ts
│       ├── RepositoryManager.ts
│       ├── AutoSaveManager.ts
│       ├── BackupManager.ts
│       ├── ExportManager.ts
│       └── MigrationManager.ts
│
└── tests/
    ├── swift/
    │   ├── SongRepositoryTests.swift
    │   ├── PerformanceRepositoryTests.swift
    │   ├── UserPreferencesRepositoryTests.swift
    │   ├── AutoSaveManagerTests.swift
    │   ├── BackupManagerTests.swift
    │   └── MigrationTests.swift
    │
    └── typescript/
        ├── songRepository.test.ts
        ├── performanceRepository.test.ts
        ├── userPreferencesRepository.test.ts
        ├── autoSaveManager.test.ts
        ├── backupManager.test.ts
        └── migration.test.ts
```

---

## Performance Targets

| Operation | Target | Notes |
|-----------|--------|-------|
| Save Song | <50ms | Single song write |
| Load Song | <50ms | Single song read |
| Load All Songs | <500ms | 1000 songs |
| Search Songs | <100ms | Full-text search |
| Save Performance | <50ms | Single performance |
| Load Performance | <50ms | Single performance |
| Create Backup | <5s | For 100MB database |
| Restore Backup | <10s | For 100MB database |
| Migration | <30s | Per schema version |

---

## Testing Strategy

### Unit Tests

- **Repository Tests** - Test CRUD operations in isolation
- **Migration Tests** - Test all migration paths
- **AutoSave Tests** - Test debouncing and periodic saves
- **Backup Tests** - Test backup/restore workflow

### Integration Tests

- **End-to-End** - Test complete song save/load cycle
- **Concurrency** - Test simultaneous reads/writes
- **Performance** - Benchmark critical operations
- **Cross-Platform** - Verify same behavior on Swift/TS

### Manual Tests

- **Migration Testing** - Test with real user data
- **Backup/Restore** - Test with large databases
- **Auto-Save** - Test data loss prevention
- **UI Integration** - Test with actual UI components

---

## Rollback Plan

If critical issues arise:

1. **Revert to previous persistence system** (JSON files)
2. **Keep SQLite system** for future investigation
3. **Fix issues** in development branch
4. **Re-test** thoroughly
5. **Re-deploy** when fixed

---

## Next Steps

1. **Review this plan** with team
2. **Create bd issues** for each phase
3. **Set up development environment** (SQLite tooling)
4. **Start with Phase 1** (Foundation)
5. **Test on both platforms** after each phase
6. **Gather feedback** and adjust as needed

---

**Total Estimated Time:** 3 weeks (15 business days)

**Total Lines of Code:** ~5,000-6,000 lines

**Files Created:** 50+ files

**Test Coverage:** 90%+

---

*This plan prioritizes data integrity, cross-platform compatibility, and scalability while maintaining simplicity and testability.*

