-- =============================================================================
-- White Room Persistence Layer - Database Schema
-- =============================================================================
-- Schema Version: 1.0
-- Database: SQLite
-- Mode: WAL (Write-Ahead Logging) for concurrent access
-- =============================================================================

-- =============================================================================
-- PRAGMA SETTINGS (Performance Optimization)
-- =============================================================================

PRAGMA journal_mode = WAL;              -- Write-ahead logging for concurrent access
PRAGMA synchronous = NORMAL;            -- Balance safety and speed
PRAGMA cache_size = -64000;             -- 64MB cache for better performance
PRAGMA temp_store = MEMORY;             -- Use RAM for temporary tables
PRAGMA mmap_size = 30000000000;         -- Enable memory-mapped I/O (30GB)
PRAGMA foreign_keys = ON;               -- Enforce foreign key constraints

-- =============================================================================
-- TABLE: songs
-- =============================================================================
-- Stores song metadata, structure, and configuration
-- =============================================================================

CREATE TABLE IF NOT EXISTS songs (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '1.0',

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Song Metadata
    tempo REAL NOT NULL DEFAULT 120.0,
    time_signature_numerator INTEGER NOT NULL DEFAULT 4,
    time_signature_denominator INTEGER NOT NULL DEFAULT 4,
    duration_seconds REAL,
    key TEXT,
    tags TEXT,                          -- JSON array: ["jazz", "upbeat"]

    -- Extended Metadata
    composer TEXT,
    genre TEXT,
    mood TEXT,
    comments TEXT,
    difficulty TEXT,                    -- 'beginner' | 'intermediate' | 'advanced' | 'expert'
    rating INTEGER CHECK (rating >= 0 AND rating <= 5), -- 0-5 stars

    -- Realization
    determinism_seed TEXT NOT NULL,
    realization_policy_json TEXT,       -- JSON: RealizationPolicy object

    -- JSON columns for complex structures
    sections_json TEXT NOT NULL DEFAULT '[]',    -- JSON: [Section] array
    roles_json TEXT NOT NULL DEFAULT '[]',       -- JSON: [Role] array
    projections_json TEXT NOT NULL DEFAULT '[]', -- JSON: [Projection] array
    mix_graph_json TEXT NOT NULL DEFAULT '{}',   -- JSON: MixGraph object (includes instrumentId, voiceId, presetId)

    -- Performance tracking
    is_favorite INTEGER DEFAULT 0 CHECK (is_favorite = 0 OR is_favorite = 1),
    play_count INTEGER DEFAULT 0 CHECK (play_count >= 0),
    last_played_at TEXT,

    -- Auto-save reference
    auto_save_id TEXT                   -- Foreign key to autosaves table
);

-- Indexes for songs table
CREATE INDEX IF NOT EXISTS idx_songs_name ON songs(name);
CREATE INDEX IF NOT EXISTS idx_songs_created_at ON songs(created_at);
CREATE INDEX IF NOT EXISTS idx_songs_updated_at ON songs(updated_at);
CREATE INDEX IF NOT EXISTS idx_songs_tags ON songs(tags);
CREATE INDEX IF NOT EXISTS idx_songs_genre ON songs(genre);
CREATE INDEX IF NOT EXISTS idx_songs_composer ON songs(composer);
CREATE INDEX IF NOT EXISTS idx_songs_is_favorite ON songs(is_favorite);
CREATE INDEX IF NOT EXISTS idx_songs_rating ON songs(rating);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS songs_updated_at
AFTER UPDATE ON songs
FOR EACH ROW
BEGIN
    UPDATE songs SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: performances
-- =============================================================================
-- Stores performance realizations (how songs are played)
-- =============================================================================

CREATE TABLE IF NOT EXISTS performances (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,              -- Foreign key to songs
    name TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '1.0',

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Arrangement
    arrangement_style TEXT NOT NULL,     -- 'SOLO_PIANO' | 'SATB' | 'ROCK_BAND' | etc.
    density REAL NOT NULL DEFAULT 1.0 CHECK (density >= 0.0 AND density <= 2.0),
    groove_profile_id TEXT NOT NULL DEFAULT 'default',

    -- Instrumentation (JSON for flexibility)
    instrumentation_map_json TEXT NOT NULL DEFAULT '{}', -- JSON: {roleId: {instrumentId, presetId, parameters}}

    -- Mix
    console_x_profile_id TEXT NOT NULL DEFAULT 'default',
    mix_targets_json TEXT NOT NULL DEFAULT '{}', -- JSON: {roleId: {volume, pan, stereo}}

    -- Performance Enhancements (JSON for scalability)
    effects_chains_json TEXT,           -- JSON: [EffectChain]
    automation_json TEXT,               -- JSON: [AutomationCurve]
    markers_json TEXT,                  -- JSON: [Marker]
    loop_points_json TEXT,              -- JSON: LoopPoints
    tempo_map_json TEXT,                -- JSON: [TempoChange]
    time_signature_map_json TEXT,       -- JSON: [TimeSigChange]
    key_changes_json TEXT,              -- JSON: [KeyChange]
    sections_json TEXT,                 -- JSON: [PerformanceSection]

    -- Metadata
    metadata_json TEXT,                 -- JSON: {custom fields}

    -- Performance tracking
    is_favorite INTEGER DEFAULT 0 CHECK (is_favorite = 0 OR is_favorite = 1),
    play_count INTEGER DEFAULT 0 CHECK (play_count >= 0),
    last_played_at TEXT,

    -- Foreign key constraints
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Indexes for performances table
CREATE INDEX IF NOT EXISTS idx_performances_song_id ON performances(song_id);
CREATE INDEX IF NOT EXISTS idx_performances_name ON performances(name);
CREATE INDEX IF NOT EXISTS idx_performances_arrangement_style ON performances(arrangement_style);
CREATE INDEX IF NOT EXISTS idx_performances_is_favorite ON performances(is_favorite);
CREATE INDEX IF NOT EXISTS idx_performances_created_at ON performances(created_at);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS performances_updated_at
AFTER UPDATE ON performances
FOR EACH ROW
BEGIN
    UPDATE performances SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: user_preferences
-- =============================================================================
-- Stores user-level settings and preferences
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_preferences (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL DEFAULT 'default',
    version TEXT NOT NULL DEFAULT '1.0',
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Audio Settings
    audio_device TEXT,
    sample_rate INTEGER DEFAULT 44100 CHECK (sample_rate IN (44100, 48000, 96000)),
    buffer_size INTEGER DEFAULT 512 CHECK (buffer_size IN (128, 256, 512, 1024, 2048)),
    input_device TEXT,
    output_device TEXT,

    -- MIDI Settings
    midi_input_devices_json TEXT,       -- JSON: ["Device 1", "Device 2"]
    midi_output_devices_json TEXT,
    midi_clock_enabled INTEGER DEFAULT 0 CHECK (midi_clock_enabled = 0 OR midi_clock_enabled = 1),

    -- UI Settings
    theme TEXT DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
    font_size TEXT DEFAULT 'medium' CHECK (font_size IN ('small', 'medium', 'large', 'extraLarge')),
    color_scheme TEXT DEFAULT 'blue',
    show_keyboard_shortcuts INTEGER DEFAULT 1,
    auto_save_interval REAL DEFAULT 60.0 CHECK (auto_save_interval > 0),

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
    grid_size_bars REAL DEFAULT 1.0 CHECK (grid_size_bars > 0),
    undo_history_size INTEGER DEFAULT 100 CHECK (undo_history_size > 0),

    -- Performance
    default_tempo REAL DEFAULT 120.0 CHECK (default_tempo > 0),
    default_time_signature_numerator INTEGER DEFAULT 4,
    default_time_signature_denominator INTEGER DEFAULT 4,
    default_key TEXT DEFAULT 'C major',
    metronome_enabled INTEGER DEFAULT 1,
    count_in_enabled INTEGER DEFAULT 0,
    count_in_bars INTEGER DEFAULT 4 CHECK (count_in_bars IN (1, 2, 4, 8)),

    -- Export
    default_export_format TEXT DEFAULT 'wav' CHECK (default_export_format IN ('wav', 'mp3', 'aiff', 'flac', 'midi')),
    default_export_quality TEXT DEFAULT 'high' CHECK (default_export_quality IN ('low', 'medium', 'high', 'lossless')),
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

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS user_preferences_updated_at
AFTER UPDATE ON user_preferences
FOR EACH ROW
BEGIN
    UPDATE user_preferences SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: roles
-- =============================================================================
-- Stores customizable song roles
-- =============================================================================

CREATE TABLE IF NOT EXISTS roles (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,              -- Foreign key to songs
    name TEXT NOT NULL,
    type TEXT NOT NULL,                 -- 'MELODY' | 'HARMONY' | 'BASS' | 'RHYTHM' | etc.

    -- Role Configuration
    generator_config_json TEXT NOT NULL DEFAULT '{}', -- JSON: GeneratorConfig object
    parameters_json TEXT NOT NULL DEFAULT '{}',       -- JSON: RoleParameters object

    -- Role Properties
    enabled INTEGER DEFAULT 1 CHECK (enabled = 0 OR enabled = 1),
    color TEXT,                         -- Hex color for UI
    icon TEXT,                          -- Icon name for UI

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Foreign key constraints
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Indexes for roles table
CREATE INDEX IF NOT EXISTS idx_roles_song_id ON roles(song_id);
CREATE INDEX IF NOT EXISTS idx_roles_type ON roles(type);
CREATE INDEX IF NOT EXISTS idx_roles_enabled ON roles(enabled);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS roles_updated_at
AFTER UPDATE ON roles
FOR EACH ROW
BEGIN
    UPDATE roles SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: sections
-- =============================================================================
-- Stores song sections with tension/harmony information
-- =============================================================================

CREATE TABLE IF NOT EXISTS sections (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,              -- Foreign key to songs
    name TEXT NOT NULL,                 -- e.g., "Verse 1", "Chorus"
    type TEXT,                          -- 'VERSE' | 'CHORUS' | 'BRIDGE' | etc.

    -- Musical Properties
    start_bar INTEGER NOT NULL,
    end_bar INTEGER NOT NULL,
    tension_level REAL CHECK (tension_level >= 0.0 AND tension_level <= 1.0),
    complexity REAL CHECK (complexity >= 0.0 AND complexity <= 1.0),

    -- Musical parameters
    key TEXT,                           -- Section-specific key
    tempo REAL,                         -- Section-specific tempo
    time_signature_numerator INTEGER,
    time_signature_denominator INTEGER,

    -- Section configuration
    density_multiplier REAL DEFAULT 1.0 CHECK (density_multiplier > 0),
    role_overrides_json TEXT,           -- JSON: {roleId: overrides}

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Foreign key constraints
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Indexes for sections table
CREATE INDEX IF NOT EXISTS idx_sections_song_id ON sections(song_id);
CREATE INDEX IF NOT EXISTS idx_sections_type ON sections(type);
CREATE INDEX IF NOT EXISTS idx_sections_start_bar ON sections(start_bar);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS sections_updated_at
AFTER UPDATE ON sections
FOR EACH ROW
BEGIN
    UPDATE sections SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: autosaves
-- =============================================================================
-- Stores auto-saved states for versioning
-- =============================================================================

CREATE TABLE IF NOT EXISTS autosaves (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT NOT NULL,              -- Foreign key to songs
    performance_id TEXT,                -- Optional: Foreign key to performances

    -- Auto-save metadata
    name TEXT NOT NULL,                 -- Auto-generated: "Auto-Save 2:34 PM"
    snapshot_json TEXT NOT NULL,        -- JSON: Complete state snapshot

    -- Timestamp
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Foreign key constraints
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Indexes for autosaves table
CREATE INDEX IF NOT EXISTS idx_autosaves_song_id ON autosaves(song_id);
CREATE INDEX IF NOT EXISTS idx_autosaves_performance_id ON autosaves(performance_id);
CREATE INDEX IF NOT EXISTS idx_autosaves_created_at ON autosaves(created_at DESC);

-- =============================================================================
-- TABLE: backups
-- =============================================================================
-- Stores timestamped backups
-- =============================================================================

CREATE TABLE IF NOT EXISTS backups (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,                 -- e.g., "Backup 2024-01-16 12:00:00"

    -- Backup metadata
    description TEXT,
    backup_type TEXT NOT NULL,          -- 'MANUAL' | 'AUTOMATIC' | 'BEFORE_MIGRATION'
    file_size_bytes INTEGER,

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Backup reference
    backup_path TEXT NOT NULL           -- File system path to backup file
);

-- Indexes for backups table
CREATE INDEX IF NOT EXISTS idx_backups_created_at ON backups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_backups_type ON backups(backup_type);

-- =============================================================================
-- TABLE: mix_graphs
-- =============================================================================
-- Stores mixing console state (separate from songs for flexibility)
-- =============================================================================

CREATE TABLE IF NOT EXISTS mix_graphs (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    song_id TEXT,                       -- Optional: Foreign key to songs
    performance_id TEXT,                -- Optional: Foreign key to performances
    name TEXT NOT NULL,

    -- Mix state
    tracks_json TEXT NOT NULL DEFAULT '[]',    -- JSON: [TrackConfig] (includes instrumentId, voiceId, presetId)
    buses_json TEXT NOT NULL DEFAULT '[]',     -- JSON: [BusConfig]
    sends_json TEXT NOT NULL DEFAULT '[]',     -- JSON: [SendConfig]
    master_json TEXT NOT NULL DEFAULT '{}',    -- JSON: MasterConfig

    -- Effects and automation
    effects_chains_json TEXT,           -- JSON: [EffectChain]
    automation_json TEXT,               -- JSON: [AutomationCurve]

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Foreign key constraints
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE,
    FOREIGN KEY (performance_id) REFERENCES performances(id) ON DELETE CASCADE
);

-- Indexes for mix_graphs table
CREATE INDEX IF NOT EXISTS idx_mix_graphs_song_id ON mix_graphs(song_id);
CREATE INDEX IF NOT EXISTS idx_mix_graphs_performance_id ON mix_graphs(performance_id);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS mix_graphs_updated_at
AFTER UPDATE ON mix_graphs
FOR EACH ROW
BEGIN
    UPDATE mix_graphs SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- TABLE: markers
-- =============================================================================
-- Stores performance markers and loop points
-- =============================================================================

CREATE TABLE IF NOT EXISTS markers (
    -- Primary Identity
    id TEXT PRIMARY KEY NOT NULL,
    performance_id TEXT NOT NULL,       -- Foreign key to performances
    song_id TEXT,                       -- Optional: Direct song reference

    -- Marker properties
    name TEXT NOT NULL,                 -- e.g., "Verse Start", "Solo Section"
    time_bars REAL NOT NULL,            -- Position in bars
    time_beats REAL DEFAULT 0.0,        -- Position in beats
    marker_type TEXT NOT NULL,          -- 'MARKER' | 'LOOP_START' | 'LOOP_END' | 'SECTION'

    -- Visual properties
    color TEXT,                         -- Hex color for UI
    icon TEXT,                          -- Icon name for UI

    -- Loop configuration (for loop markers)
    loop_count INTEGER DEFAULT -1,      -- -1 = infinite, 0+ = specific count

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Foreign key constraints
    FOREIGN KEY (performance_id) REFERENCES performances(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Indexes for markers table
CREATE INDEX IF NOT EXISTS idx_markers_performance_id ON markers(performance_id);
CREATE INDEX IF NOT EXISTS idx_markers_song_id ON markers(song_id);
CREATE INDEX IF NOT EXISTS idx_markers_time_bars ON markers(time_bars);
CREATE INDEX IF NOT EXISTS idx_markers_type ON markers(marker_type);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS markers_updated_at
AFTER UPDATE ON markers
FOR EACH ROW
BEGIN
    UPDATE markers SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- =============================================================================
-- METADATA TABLE (Schema Version & Migrations)
-- =============================================================================

CREATE TABLE IF NOT EXISTS metadata (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Initialize with schema version
INSERT OR IGNORE INTO metadata (key, value) VALUES ('schema_version', '1.0');

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
-- Total tables created: 9
-- 1. songs - Song metadata and track configs
-- 2. performances - Performance realizations
-- 3. user_preferences - User-level settings
-- 4. roles - Song roles (customizable per song)
-- 5. sections - Song sections with tension/harmony
-- 6. autosaves - Auto-saved states
-- 7. backups - Timestamped backups
-- 8. mix_graphs - Mixing console state
-- 9. markers - Performance markers/loop points
-- =============================================================================
