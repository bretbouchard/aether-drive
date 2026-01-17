# White Room Persistence Architecture

## Executive Summary

White Room has a **three-tier persistence system**:

1. **Song Level** - Musical composition (structure, roles, sections)
2. **Performance Level** - How a song is realized (instruments, mix, arrangement)
3. **User Level** - User preferences, settings, and app state

This document catalogs **what should be persistent** and **how to organize it**.

---

## Current State: What's Missing

### ❌ **NOT Persisted** (Critical Gaps)

1. **`TrackConfig.instrumentId`** - Which instrument is assigned to each track
2. **`TrackConfig.voiceId`** - Which specific voice within an instrument
3. **`TrackConfig.presetId`** - Which preset is loaded for the instrument
4. **`Role.parameters.enabled`** - Whether a role is active/enabled
5. **User Preferences** - App-wide settings (theme, audio device, etc.)
6. **Recent Songs** - List of recently opened songs
7. **Favorites** - User's favorite songs, performances, instruments
8. **Playback State** - Last played position, mute/solo states
9. **Window/Layout State** - UI window positions, panel sizes
10. **Undo History** - Command pattern history for undo/redo

### ✅ **Already Persisted** (Working)

1. **`Song`** structure (metadata, sections, roles, projections, mix graph)
2. **`PerformanceState_v1`** (arrangement, density, groove, instrumentation)
3. **MultiSongState** - Moving Sidewalk multi-song playback
4. **SongOrder** - Song ordering for performances

---

## Three-Tier Persistence Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER LEVEL                               │
│  (App-wide preferences, settings, global state)            │
├─────────────────────────────────────────────────────────────┤
│                  PERFORMANCE LEVEL                          │
│  (How songs are realized: instruments, mix, arrangement)    │
├─────────────────────────────────────────────────────────────┤
│                    SONG LEVEL                              │
│  (Musical composition: structure, roles, sections)         │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Song Level Persistence

### What It Is

**The musical composition itself** - the "what" of the music, independent of how it sounds.

### What Should Be Saved

#### ✅ **Already Saved**

```swift
public struct Song: Codable, Sendable {
    // Identity
    public var id: String
    public var name: String
    public var version: String

    // Metadata
    public var metadata: SongMetadata  // tempo, time signature, key, tags

    // Musical Structure
    public var sections: [Section]     // verse, chorus, bridge
    public var roles: [Role]           // bass, melody, harmony
    public var projections: [Projection]  // role → target mappings

    // Audio Configuration
    public var mixGraph: MixGraph       // tracks, buses, sends
    public var realizationPolicy: RealizationPolicy
    public var determinismSeed: String

    // Timestamps
    public var createdAt: Date
    public var updatedAt: Date
}
```

#### ❌ **Missing - Need to Add**

**1. `TrackConfig` Enhancement**

```swift
public struct TrackConfig: Identifiable, Codable, Sendable {
    public var id: String
    public var name: String
    public var volume: Double
    public var pan: Double
    public var mute: Bool
    public var solo: Bool

    // ❌ MISSING - Add these:
    public var instrumentId: String?        // Which instrument (e.g., "LocalGal")
    public var voiceId: String?             // Which voice (e.g., "voice-1")
    public var presetId: String?            // Which preset (e.g., "Piano Bright")
    public var midiChannel: Int?            // MIDI channel (1-16)
    public var midiProgram: Int?            // MIDI program change (0-127)

    public var additionalParameters: [String: CodableAny]?
}
```

**Why This Matters:**
- **Reproducibility** - Reopen song and hear exact same sounds
- **Orchestration** - Know which instruments play which roles
- **Collaboration** - Share songs with collaborators

**2. `Role` Enhancement**

```swift
public struct Role: Identifiable, Codable, Sendable {
    public var id: String
    public var name: String
    public var type: RoleType
    public var generatorConfig: GeneratorConfig
    public var parameters: RoleParameters

    // ❌ MISSING - Add this:
    public var enabled: Bool    // Whether role is active

    public var color: String?   // UI color for this role
    public var icon: String?    // UI icon for this role
}
```

**Why This Matters:**
- **Disable roles** without deleting them
- **Visual organization** - color-coded roles in UI
- **A/B testing** - Try different role configurations

**3. Song-Level Metadata**

```swift
public struct SongMetadata: Codable, Sendable {
    public var tempo: Double
    public var timeSignature: [Int]
    public var duration: Double?
    public var key: String?
    public var tags: [String]

    // ❌ MISSING - Add these:
    public var composer: String?         // Composer name
    public var genre: String?            // Genre tag
    public var mood: String?             // Mood tag
    public var comments: String?         // User notes
    public var difficulty: Difficulty?   // Easy/Medium/Hard
    public var rating: Int?              // 1-5 stars

    public enum Difficulty: String, Codable {
        case beginner, intermediate, advanced, expert
    }
}
```

**Why This Matters:**
- **Organization** - Filter/search by genre, mood, difficulty
- **Learning** - Find songs appropriate for skill level
- **Personalization** - User ratings and notes

### File Structure

```
~/Library/Application Support/White Room/Songs/
├── {song-id}.json              # Song definition
├── {song-id}.performance.json  # Default performance (optional)
└── .favorites/                 # Symlinks to favorite songs
```

### Migration Strategy

```swift
// Versioning system for schema changes
public struct Song {
    public var version: String  // "1.0", "1.1", "2.0", etc.

    // Migration function
    public static func migrate(from oldVersion: String, to newVersion: String, data: Data) throws -> Song {
        // Apply migrations in sequence
    }
}
```

---

## 2. Performance Level Persistence

### What It Is

**How a song is realized** - the "how" of the music. One song can have many performances (Piano, Orchestra, Techno, etc.).

### What Should Be Saved

#### ✅ **Already Saved** (PerformanceState_v1)

```swift
public struct PerformanceState_v1: Codable, Sendable, Identifiable {
    public let version: String
    public let id: String
    public let name: String
    public let arrangementStyle: ArrangementStyle
    public let density: Double
    public let grooveProfileId: String
    public let instrumentationMap: [String: PerformanceInstrumentAssignment]
    public let consoleXProfileId: String
    public let mixTargets: [String: MixTarget]
    public let createdAt: Date?
    public let modifiedAt: Date?
    public let metadata: [String: String]?
}
```

#### ✅ **Already Working** - Instrument Assignment

```swift
public struct PerformanceInstrumentAssignment: Codable, Sendable {
    public let instrumentId: String    // ✅ Already here!
    public let presetId: String?
    public let parameters: [String: Double]?
}
```

#### ❌ **Missing - Need to Add**

**1. Performance-Level Mix State**

```swift
// Enhance PerformanceState_v1:
public struct PerformanceState_v1: Codable, Sendable {
    // ... existing fields ...

    // ❌ MISSING - Add these:
    public var effectsChain: [EffectChain]?     // Effects per track
    public var automation: [AutomationCurve]?   // Automation data
    public var markers: [Marker]?               // Song markers
    public var loopPoints: LoopPoints?          // Loop start/end
}

public struct EffectChain: Identifiable, Codable {
    public var id: String
    public var trackId: String
    public var effects: [EffectInstance]        // Ordered list of effects
}

public struct EffectInstance: Codable {
    public var effectId: String                 // Which effect (e.g., "reverb")
    public var presetId: String?                // Effect preset
    public var parameters: [String: Double]     // Effect parameters
    public var enabled: Bool                    // Bypass state
    public var mix: Double                      // Dry/wet mix
}

public struct AutomationCurve: Identifiable, Codable {
    public var id: String
    public var parameterId: String              // Which parameter
    public var points: [AutomationPoint]        // Time/value pairs
}

public struct AutomationPoint: Codable {
    public var time: MusicalTime
    public var value: Double
    public var interpolation: InterpolationType
}

public enum InterpolationType: String, Codable {
    case linear, stepped, smooth, exponential
}

public struct Marker: Identifiable, Codable {
    public var id: String
    public var name: String
    public var time: MusicalTime
    public var color: String?
}

public struct LoopPoints: Codable {
    public var start: MusicalTime
    public var end: MusicalTime
    public var enabled: Bool
    public var count: Int?                      // -1 = infinite
}
```

**Why This Matters:**
- **Full mix recall** - Save/load complete mix settings
- **Automation** - Draw in automation curves
- **Live performance** - Set up loop points for live jams

**2. Performance Metadata**

```swift
// Enhance PerformanceState_v1:
public struct PerformanceState_v1: Codable, Sendable {
    // ... existing fields ...

    // ❌ MISSING - Add these:
    public var tempoMap: [TempoChange]?        // Tempo changes over time
    public var timeSignatureMap: [TimeSigChange]?
    public var keyChanges: [KeyChange]?         // Key modulations
    public var sections: [PerformanceSection]?  // Section-specific settings
}

public struct TempoChange: Codable {
    public var time: MusicalTime
    public var tempo: Double                    // BPM
}

public struct TimeSigChange: Codable {
    public var time: MusicalTime
    public var numerator: Int
    public var denominator: Int
}

public struct KeyChange: Codable {
    public var time: MusicalTime
    public var key: String                      // "C major", "A minor", etc.
}

public struct PerformanceSection: Identifiable, Codable {
    public var id: String
    public var name: String                     // "Verse 1", "Chorus", etc.
    public var start: MusicalTime
    public var end: MusicalTime
    public var densityMultiplier: Double?       // Adjust density for this section
    public var roleOverrides: [String: RoleOverride]?
}
```

**Why This Matters:**
- **Dynamic arrangements** - Change feel over time
- **Song structure** - Define verses, choruses, bridges
- **Key changes** - Modulate to new keys

### File Structure

```
~/Library/Application Support/White Room/Performances/
├── {song-id}/
│   ├── {performance-id}.json        # Performance definition
│   ├── {performance-id}.mix.json     # Mix state (optional)
│   └── {performance-id}.automation.json  # Automation (optional)
└── .favorites/                      # Symlinks to favorite performances
```

---

## 3. User Level Persistence

### What It Is

**App-wide settings and preferences** - independent of any song or performance.

### What Should Be Saved

#### ❌ **Missing - Need to Create**

```swift
public struct UserPreferences: Codable, Sendable {
    // MARK: - Audio Settings
    public var audioDevice: String?           // Audio device name
    public var sampleRate: Int                // 44100, 48000, 96000
    public var bufferSize: Int                // 128, 256, 512, 1024
    public var inputDevice: String?
    public var outputDevice: String?

    // MARK: - MIDI Settings
    public var midiInputDevices: [String]     // Enabled MIDI inputs
    public var midiOutputDevices: [String]    // Enabled MIDI outputs
    public var midiClockEnabled: Bool          // Send/receive MIDI clock

    // MARK: - UI Settings
    public var theme: Theme                   // Light/Dark/System
    public var fontSize: FontSize              // Small/Medium/Large
    public var colorScheme: ColorScheme        // Default colors
    public var showKeyboardShortcuts: Bool
    public var autoSaveInterval: TimeInterval // Auto-save every N seconds

    // MARK: - Window/Layout
    public var windowState: WindowState?       // Window positions/sizes
    public var panelLayout: PanelLayout?       // Which panels open
    public var splitterPositions: [String: Double]?  // Splitter positions

    // MARK: - Library
    public var libraryFolders: [URL]           // Song library locations
    public var defaultSaveLocation: URL?
    public var recentSongs: [URL]             // Max 20
    public var favoriteSongs: [String]        // Song IDs
    public var favoritePerformances: [String]  // Performance IDs
    public var favoriteInstruments: [String]   // Instrument IDs

    // MARK: - Editing
    public var autoQuantize: Bool
    public var snapToGrid: Bool
    public var gridSize: MusicalTime
    public var undoHistorySize: Int            // Max undo steps (default: 100)

    // MARK: - Performance
    public var defaultTempo: Double            // Default new song tempo
    public var defaultTimeSignature: [Int]     // [4, 4]
    public var defaultKey: String              // "C major"
    public var metronomeEnabled: Bool
    public var countInEnabled: Bool
    public var countInBars: Int                // 2, 4, 8

    // MARK: - Export
    public var defaultExportFormat: ExportFormat
    public var defaultExportQuality: ExportQuality
    public var normalizeOnExport: Bool

    // MARK: - Advanced
    public var lookaheadEnabled: Bool
    public var deterministicMode: Bool
    public var telemetryEnabled: Bool
    public var crashReportsEnabled: Bool
    public var analyticsEnabled: Bool

    // MARK: - Developer
    public var developerMode: Bool
    public var verboseLogging: Bool
    public var performanceMetrics: Bool

    public init() {
        // Set sensible defaults
        self.theme = .system
        self.fontSize = .medium
        self.sampleRate = 44100
        self.bufferSize = 512
        self.autoSaveInterval = 60.0
        self.undoHistorySize = 100
        self.defaultTempo = 120.0
        self.defaultTimeSignature = [4, 4]
        self.defaultKey = "C major"
        self.countInBars = 4
        self.metronomeEnabled = true
        self.lookaheadEnabled = true
        self.deterministicMode = false
        self.telemetryEnabled = true
        self.crashReportsEnabled = true
        self.analyticsEnabled = true
        self.developerMode = false
        self.verboseLogging = false
        self.performanceMetrics = false
    }
}

public enum Theme: String, Codable {
    case light, dark, system
}

public enum FontSize: String, Codable {
    case small, medium, large, extraLarge
}

public enum ColorScheme: String, Codable {
    case blue, purple, green, orange, pink
}

public enum ExportFormat: String, Codable {
    case wav, mp3, aiff, flac, midi
}

public enum ExportQuality: String, Codable {
    case low, medium, high, lossless
}

public struct WindowState: Codable {
    public var mainWindow: Rect?
    public var floatingWindows: [String: Rect]
}

public struct Rect: Codable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
}

public struct PanelLayout: Codable {
    public var visiblePanels: [String]
    public var hiddenPanels: [String]
    public var focusedPanel: String?
}
```

### Why This Matters

- **User Experience** - Remember user's preferences
- **Productivity** - Don't reconfigure every time
- **Accessibility** - Font sizes, themes
- **Workflow** - Recent files, favorites
- **Collaboration** - Share settings across devices

### File Structure

```
~/Library/Application Support/White Room/
├── UserPreferences.json          # User preferences
├── WindowState.json               # Window/layout state
├── RecentSongs.json               # Recently opened songs
├── Favorites/
│   ├── Songs.json                 # Favorite song IDs
│   ├── Performances.json          # Favorite performance IDs
│   └── Instruments.json           # Favorite instrument IDs
└── Cache/                         # Temporary cache (clear on quit)
```

---

## 4. Runtime Persistence (Transient)

### What It Is

**State that exists only during app runtime** - not persisted across launches.

### What Should NOT Be Saved

```swift
// Runtime-only state (reset on app launch)
public class RuntimeState: ObservableObject {
    // Playback state
    @Published public var isPlaying: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var isStopped: Bool = true
    @Published public var playbackPosition: MusicalTime = .zero

    // Selection state
    @Published public var selectedSong: Song?
    @Published public var selectedPerformance: PerformanceState_v1?
    @Published public var selectedRole: Role?
    @Published public var selectedTrack: TrackConfig?

    // UI state (not persisted)
    @Published public var expandedSections: Set<String> = []
    @Published public var scrollPosition: CGPoint = .zero
    @Published public var hoverState: [String: Bool] = [:]

    // Temporary edits (not saved until explicit save)
    @Published public var pendingChanges: [PendingChange] = []
    @Published public var undoStack: [UndoCommand] = []
    @Published public var redoStack: [UndoCommand] = []
}
```

**Why NOT Persist This:**
- **Clean slate** - Start fresh each app launch
- **Performance** - Don't load unnecessary state
- **Predictability** - Known starting state
- **Privacy** - Don't track user interactions

---

## 5. Persistence Layer Implementation

### Storage Options

#### Option 1: JSON Files (Recommended for v1)

**Pros:**
- ✅ Simple to implement
- ✅ Human-readable/debuggable
- ✅ Version control friendly
- ✅ Easy to migrate schemas

**Cons:**
- ❌ Not efficient for large datasets
- ❌ No querying/indexing
- ❌ Manual file management

**Best For:**
- Songs (one JSON per song)
- Performances (one JSON per performance)
- User preferences (single JSON)

#### Option 2: CoreData (For v2)

**Pros:**
- ✅ Efficient querying
- ✅ Relationship management
- ✅ Automatic migrations
- ✅ Built-in caching

**Cons:**
- ❌ Complex setup
- ❌ Harder to debug
- ❌ Schema migrations can be tricky
- ❌ Swift-only (no cross-platform)

**Best For:**
- Library management (songs, performances)
- Favorites and recent items
- Large datasets

#### Option 3: SQLite (For v2)

**Pros:**
- ✅ Cross-platform (Swift + TypeScript)
- ✅ Efficient querying
- ✅ Small footprint
- ✅ SQL-based migrations

**Cons:**
- ❌ Manual SQL queries
- ❌ No ORM (need to write SQL)
- ❌ More code to maintain

**Best For:**
- Cross-platform data sharing
- Complex queries
- Large datasets

### Recommended Implementation (v1)

```swift
// MARK: - Persistence Manager

public class PersistenceManager: ObservableObject {

    // MARK: - Song Persistence

    public func saveSong(_ song: Song) throws {
        let url = songURL(for: song.id)
        let data = try JSONEncoder().encode(song)
        try data.write(to: url)
    }

    public func loadSong(id: String) throws -> Song {
        let url = songURL(for: id)
        let data = try Data(contentsOf: url)
        let song = try JSONDecoder().decode(Song.self, from: data)
        return song
    }

    public func deleteSong(id: String) throws {
        let url = songURL(for: id)
        try FileManager.default.removeItem(at: url)
    }

    public func listAllSongs() throws -> [Song] {
        let songsURL = songsDirectory()
        let files = try FileManager.default.contentsOfDirectory(
            at: songsURL,
            includingPropertiesForKeys: nil
        )

        return try files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Song.self, from: data)
        }
    }

    // MARK: - Performance Persistence

    public func savePerformance(_ performance: PerformanceState_v1, forSong songId: String) throws {
        let url = performanceURL(for: performance.id, songId: songId)
        let data = try JSONEncoder().encode(performance)
        try data.write(to: url)
    }

    public func loadPerformance(id: String, forSong songId: String) throws -> PerformanceState_v1 {
        let url = performanceURL(for: id, songId: songId)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PerformanceState_v1.self, from: data)
    }

    public func listPerformances(forSong songId: String) throws -> [PerformanceState_v1] {
        let performancesURL = performancesDirectory(for: songId)
        let files = try FileManager.default.contentsOfDirectory(
            at: performancesURL,
            includingPropertiesForKeys: nil
        )

        return try files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PerformanceState_v1.self, from: data)
        }
    }

    // MARK: - User Preferences Persistence

    @Published public var userPreferences: UserPreferences = UserPreferences()

    public func saveUserPreferences() throws {
        let url = userPreferencesURL()
        let data = try JSONEncoder().encode(userPreferences)
        try data.write(to: url)
    }

    public func loadUserPreferences() throws {
        let url = userPreferencesURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return  // Use defaults
        }

        let data = try Data(contentsOf: url)
        userPreferences = try JSONDecoder().decode(UserPreferences.self, from: data)
    }

    // MARK: - File Locations

    private func baseDirectory() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let whiteRoomURL = appSupport.appendingPathComponent("White Room", isDirectory: true)
        try FileManager.default.createDirectory(at: whiteRoomURL, withIntermediateDirectories: true)

        return whiteRoomURL
    }

    private func songsDirectory() throws -> URL {
        let base = try baseDirectory()
        let songsURL = base.appendingPathComponent("Songs", isDirectory: true)
        try FileManager.default.createDirectory(at: songsURL, withIntermediateDirectories: true)
        return songsURL
    }

    private func songURL(for id: String) throws -> URL {
        let songsDir = try songsDirectory()
        return songsDir.appendingPathComponent("\(id).json")
    }

    private func performancesDirectory(for songId: String) throws -> URL {
        let songsDir = try songsDirectory()
        let perfURL = songsDir.appendingPathComponent(songId, isDirectory: true)
            .appendingPathComponent("Performances", isDirectory: true)
        try FileManager.default.createDirectory(at: perfURL, withIntermediateDirectories: true)
        return perfURL
    }

    private func performanceURL(for id: String, songId: String) throws -> URL {
        let perfDir = try performancesDirectory(for: songId)
        return perfDir.appendingPathComponent("\(id).json")
    }

    private func userPreferencesURL() throws -> URL {
        let base = try baseDirectory()
        return base.appendingPathComponent("UserPreferences.json")
    }
}
```

---

## 6. Migration Strategy

### Versioned Schemas

```swift
// MARK: - Song Versioning

public enum SongVersion: String, Codable {
    case v1_0 = "1.0"
    case v1_1 = "1.1"
    case v2_0 = "2.0"
}

// Migration registry
public struct SongMigration {
    public static let migrations: [SongVersion: Migration] = [
        .v1_0: SongMigration_1_0(),
        .v1_1: SongMigration_1_1(),
        .v2_0: SongMigration_2_0(),
    ]

    public static func migrate(from oldVersion: SongVersion, to newVersion: SongVersion, data: Data) throws -> Song {
        guard oldVersion != newVersion else {
            return try JSONDecoder().decode(Song.self, from: data)
        }

        // Apply migrations in sequence
        var currentData = data
        var currentVersion = oldVersion

        while currentVersion != newVersion {
            guard let migration = migrations[currentVersion] else {
                throw MigrationError.noMigrationFound(version: currentVersion)
            }

            currentData = try migration.migrate(currentData)
            currentVersion = migration.targetVersion
        }

        return try JSONDecoder().decode(Song.self, from: currentData)
    }
}

public protocol Migration {
    var sourceVersion: SongVersion { get }
    var targetVersion: SongVersion { get }
    func migrate(_ data: Data) throws -> Data
}

// Example migration: Add instrumentId to TrackConfig
public struct SongMigration_1_1: Migration {
    public let sourceVersion = SongVersion.v1_0
    public let targetVersion = SongVersion.v1_1

    public func migrate(_ data: Data) throws -> Data {
        // Decode as v1.0
        let v1_0 = try JSONDecoder().decode(Song_v1_0.self, from: data)

        // Transform to v1.1
        let v1_1 = Song_v1_1(
            id: v1_0.id,
            name: v1_0.name,
            version: "1.1",
            metadata: v1_0.metadata,
            sections: v1_0.sections,
            roles: v1_0.roles,
            projections: v1_0.projections,
            mixGraph: MixGraph(
                tracks: v1_0.mixGraph.tracks.map { track in
                    // Add missing instrumentId field
                    TrackConfig_v1_1(
                        id: track.id,
                        name: track.name,
                        volume: track.volume,
                        pan: track.pan,
                        mute: track.mute,
                        solo: track.solo,
                        instrumentId: nil,  // New field - default to nil
                        voiceId: nil,       // New field - default to nil
                        presetId: nil,      // New field - default to nil
                        additionalParameters: track.additionalParameters
                    )
                },
                buses: v1_0.mixGraph.buses,
                sends: v1_0.mixGraph.sends,
                master: v1_0.mixGraph.master
            ),
            realizationPolicy: v1_0.realizationPolicy,
            determinismSeed: v1_0.determinismSeed,
            createdAt: v1_0.createdAt,
            updatedAt: v1_0.updatedAt
        )

        // Encode as v1.1
        return try JSONEncoder().encode(v1_1)
    }
}
```

---

## 7. Data Validation

### Schema Validation

```swift
// MARK: - Validation

public extension Song {
    func validate() throws -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate required fields
        if id.isEmpty { errors.append(.missingField("id")) }
        if name.isEmpty { errors.append(.missingField("name")) }

        // Validate sections
        if sections.isEmpty { errors.append(.emptySections) }

        // Validate roles
        if roles.isEmpty { errors.append(.emptyRoles) }

        // Validate projections reference valid roles
        for projection in projections {
            if !roles.contains(where: { $0.id == projection.roleId }) {
                errors.append(.invalidProjection(projectionId: projection.id, roleId: projection.roleId))
            }
        }

        // Validate mix graph
        // - Tracks must have unique IDs
        let trackIds = mixGraph.tracks.map { $0.id }
        if Set(trackIds).count != trackIds.count {
            errors.append(.duplicateTrackIds)
        }

        // - Sends must reference valid tracks and buses
        for send in mixGraph.sends {
            if !mixGraph.tracks.contains(where: { $0.id == send.fromTrackId }) {
                errors.append(.invalidSend(sendId: send.id, reason: "Invalid fromTrackId"))
            }
            if !mixGraph.buses.contains(where: { $0.id == send.toBusId }) {
                errors.append(.invalidSend(sendId: send.id, reason: "Invalid toBusId"))
            }
        }

        if errors.isEmpty {
            return ValidationResult(isValid: true, errors: [])
        } else {
            return ValidationResult(isValid: false, errors: errors)
        }
    }
}

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
}

public enum ValidationError: Error {
    case missingField(String)
    case emptySections
    case emptyRoles
    case invalidProjection(projectionId: String, roleId: String)
    case duplicateTrackIds
    case invalidSend(sendId: String, reason: String)
}
```

---

## 8. Undo/Redo System

### Command Pattern

```swift
// MARK: - Undo/Redo

public protocol UndoCommand: Codable {
    associatedtype State
    var description: String { get }

    func execute(on state: inout State) throws
    func undo(on state: inout State) throws
    func redo(on state: inout State) throws
}

// Example: Change Track Volume
public struct ChangeTrackVolumeCommand: UndoCommand {
    public typealias State = Song

    public let description: String
    public let trackId: String
    public let oldVolume: Double
    public let newVolume: Double

    public init(trackId: String, oldVolume: Double, newVolume: Double) {
        self.description = "Change volume for track \(trackId)"
        self.trackId = trackId
        self.oldVolume = oldVolume
        self.newVolume = newVolume
    }

    public func execute(on state: inout Song) throws {
        guard let index = state.mixGraph.tracks.firstIndex(where: { $0.id == trackId }) else {
            throw CommandError.trackNotFound(trackId)
        }
        state.mixGraph.tracks[index].volume = newVolume
    }

    public func undo(on state: inout Song) throws {
        guard let index = state.mixGraph.tracks.firstIndex(where: { $0.id == trackId }) else {
            throw CommandError.trackNotFound(trackId)
        }
        state.mixGraph.tracks[index].volume = oldVolume
    }

    public func redo(on state: inout Song) throws {
        try execute(on: &state)
    }
}

public enum CommandError: Error {
    case trackNotFound(String)
    case roleNotFound(String)
    case sectionNotFound(String)
}

// Undo Manager
public class UndoManager: ObservableObject {
    @Published public var undoStack: [any UndoCommand] = []
    @Published public var redoStack: [any UndoCommand] = []

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public func execute<T>(_ command: some UndoCommand<T>, on state: inout T) throws {
        try command.execute(on: &state)
        undoStack.append(command)
        redoStack.removeAll()  // Clear redo stack on new command
    }

    public func undo<T>(on state: inout T) throws {
        guard let command = undoStack.popLast() else { return }
        try command.undo(on: &state)
        redoStack.append(command)
    }

    public func redo<T>(on state: inout T) throws {
        guard let command = redoStack.popLast() else { return }
        try command.execute(on: &state)
        undoStack.append(command)
    }

    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
```

---

## 9. Auto-Save System

### Automatic Persistence

```swift
// MARK: - Auto-Save

public class AutoSaveManager: ObservableObject {
    private let persistenceManager: PersistenceManager
    private var autoSaveTimer: Timer?
    private var pendingSaveWorkItem: DispatchWorkItem?

    public var autoSaveEnabled: Bool = true
    public var autoSaveInterval: TimeInterval = 60.0  // 1 minute
    public var autoSaveOnChanges: Bool = true

    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }

    public func startAutoSave(for song: Song) {
        guard autoSaveEnabled else { return }

        // Cancel any pending save
        pendingSaveWorkItem?.cancel()

        // Debounce rapid changes
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveSong(song)
        }

        pendingSaveWorkItem = workItem

        if autoSaveOnChanges {
            // Save after delay (debounce)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
        }

        // Periodic saves
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.saveSong(song)
        }
    }

    public func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
    }

    public func saveSong(_ song: Song) {
        do {
            try persistenceManager.saveSong(song)
            print("[AutoSave] Saved song: \(song.name)")
        } catch {
            print("[AutoSave] Failed to save song: \(error)")
        }
    }

    deinit {
        stopAutoSave()
    }
}
```

---

## 10. Backup & Sync

### Backup Strategy

```swift
// MARK: - Backup

public class BackupManager {
    private let persistenceManager: PersistenceManager

    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }

    public func createBackup() throws -> URL {
        let base = try persistenceManager.baseDirectory()

        // Create backup with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupURL = base
            .deletingLastPathComponent()
            .appendingPathComponent("White Room Backups")
            .appendingPathComponent(timestamp)

        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)

        // Copy all songs
        let songsSource = try persistenceManager.songsDirectory()
        let songsDest = backupURL.appendingPathComponent("Songs")
        try FileManager.default.copyItem(at: songsSource, to: songsDest)

        // Copy user preferences
        let prefsSource = try persistenceManager.userPreferencesURL()
        let prefsDest = backupURL.appendingPathComponent("UserPreferences.json")
        try FileManager.default.copyItem(at: prefsSource, to: prefsDest)

        return backupURL
    }

    public func restoreBackup(from backupURL: URL) throws {
        // Validate backup
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw BackupError.backupNotFound(backupURL)
        }

        // Ask user for confirmation
        // This will delete all current data!

        // Restore songs
        let songsSource = backupURL.appendingPathComponent("Songs")
        let songsDest = try persistenceManager.songsDirectory()
        try FileManager.default.removeItem(at: songsDest)
        try FileManager.default.copyItem(at: songsSource, to: songsDest)

        // Restore preferences
        let prefsSource = backupURL.appendingPathComponent("UserPreferences.json")
        let prefsDest = try persistenceManager.userPreferencesURL()
        try FileManager.default.removeItem(at: prefsDest)
        try FileManager.default.copyItem(at: prefsSource, to: prefsDest)
    }

    public func listBackups() throws -> [URL] {
        let base = try persistenceManager.baseDirectory()
        let backupsDir = base.deletingLastPathComponent().appendingPathComponent("White Room Backups")

        return try FileManager.default.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ).sorted { (url1, url2) in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 > date2  // Newest first
        }
    }
}

public enum BackupError: Error {
    case backupNotFound(URL)
    case invalidBackup
    case restoreFailed(underlying: Error)
}
```

### Cloud Sync (iCloud) - Optional

```swift
// MARK: - iCloud Sync

public class CloudSyncManager: ObservableObject {
    @Published public var syncEnabled: Bool = false
    @Published public var syncStatus: SyncStatus = .idle

    public enum SyncStatus {
        case idle
        case syncing(progress: Double)
        case completed
        case failed(Error)
    }

    public func syncToiCloud() async throws {
        syncStatus = .syncing(progress: 0.0)

        // Upload songs to iCloud
        // Upload performances to iCloud
        // Upload user preferences to iCloud

        syncStatus = .completed
    }

    public func syncFromiCloud() async throws {
        syncStatus = .syncing(progress: 0.0)

        // Download songs from iCloud
        // Download performances from iCloud
        // Download user preferences from iCloud
        // Merge with local data (resolve conflicts)

        syncStatus = .completed
    }
}
```

---

## 11. Summary & Priorities

### Priority 1 - Critical Gaps (Fix Immediately)

1. ✅ **`TrackConfig.instrumentId`** - Save instrument assignments
2. ✅ **`TrackConfig.voiceId`** - Save voice selections
3. ✅ **`TrackConfig.presetId`** - Save preset selections
4. ✅ **UserPreferences** - Basic app preferences
5. ✅ **Auto-save** - Prevent data loss

### Priority 2 - Important Features (Add Soon)

6. ✅ **Song metadata** - Composer, genre, mood, rating
7. ✅ **Performance enhancements** - Effects, automation, markers
8. ✅ **Undo/Redo system** - Command pattern
9. ✅ **Recent songs** - Quick access
10. ✅ **Favorites** - Songs, performances, instruments

### Priority 3 - Nice to Have (Add Later)

11. ⏳ **Window/layout state** - Restore UI positions
12. ⏳ **Backup/restore** - Full app backups
13. ⏳ **Cloud sync** - iCloud integration
14. ⏳ **Advanced mix** - Effects chains, automation curves
15. ⏳ **Analytics** - Usage tracking, crash reports

---

## Implementation Checklist

- [ ] Add `instrumentId`, `voiceId`, `presetId` to `TrackConfig`
- [ ] Add `enabled` to `Role`
- [ ] Enhance `SongMetadata` with composer, genre, mood, rating
- [ ] Create `UserPreferences` struct
- [ ] Implement `PersistenceManager` class
- [ ] Add JSON save/load for songs
- [ ] Add JSON save/load for performances
- [ ] Add JSON save/load for user preferences
- [ ] Implement auto-save system
- [ ] Implement undo/redo system
- [ ] Add data validation
- [ ] Create migration system for schema changes
- [ ] Add backup/restore functionality
- [ ] (Optional) Implement iCloud sync

---

## Next Steps

1. **Create bd issue** for this work
2. **Implement Priority 1** items first
3. **Add tests** for persistence layer
4. **Test migrations** between versions
5. **Document API** for other developers
6. **Create user-facing documentation** for backup/restore

---

*This document is a comprehensive catalog of what needs to be persistent in White Room. Priority 1 items should be implemented immediately to ensure reproducibility and prevent data loss.*

