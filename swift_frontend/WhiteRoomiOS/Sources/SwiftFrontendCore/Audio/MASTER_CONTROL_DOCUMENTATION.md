# Master Control System Documentation

## Overview

The Master Control System provides comprehensive coordination for multi-song playback in White Room, including:

- **Master Transport Control**: Coordinated play/pause/stop across all songs
- **Tempo Synchronization**: Three sync modes (Independent, Locked, Ratio)
- **Preset Management**: Save, load, and organize multi-song configurations
- **Undo/Redo Support**: Full undo/redo for all operations
- **Smooth Transitions**: Glitch-free tempo and transport changes

## Architecture

### Core Components

#### 1. MasterTransportController

The master controller that coordinates all song instances.

**Key Features:**
- Master transport state management (play/pause/stop)
- Master tempo and tempo multiplier control
- Master volume control
- Individual song control (play/pause/stop/volume/tempo)
- Emergency stop functionality
- State snapshot and restore
- Undo/redo integration

**Usage:**
```swift
let syncController = SyncModeController()
let masterController = MasterTransportController(
    syncModeController: syncController,
    undoManager: undoManager
)

// Add song instances
masterController.addSongInstance(instance1)
masterController.addSongInstance(instance2)

// Control playback
masterController.play()
masterController.pause()
masterController.stop()

// Control tempo
masterController.setMasterTempo(120.0)
masterController.setTempoMultiplier(1.5)

// Control volume
masterController.setMasterVolume(0.8)
```

#### 2. SyncModeController

Manages tempo synchronization between multiple songs.

**Sync Modes:**

**Independent Mode:**
- Each song maintains its own tempo
- No coordination between songs
- Useful for creative layering

**Locked Mode:**
- All songs sync to master tempo (1:1 ratio)
- Perfect for beat-matched playback
- All songs change together

**Ratio Mode:**
- Maintain relative tempo ratios
- When master tempo changes, songs scale proportionally
- Preserves musical relationships

**Usage:**
```swift
let syncController = SyncModeController()

// Set sync mode
syncController.setSyncMode(.locked)

// Configure transitions
syncController.smoothTransitions = true
syncController.transitionDuration = 0.5 // seconds

// Capture baseline tempos for ratio mode
syncController.captureBaselineTempos(from: songInstances)

// Manually set tempo ratios
syncController.setTempoRatio(1.5, forSongId: "song-1")
```

#### 3. MultiSongPreset

Data model for multi-song configurations.

**Structure:**
- Master settings (transport, tempo, volume)
- Song states (individual song configurations)
- Sync settings (mode, ratios, transitions)
- Metadata (name, description, tags, timestamps)

**Usage:**
```swift
// Create preset from current state
let preset = MultiSongPreset.fromCurrentState(
    name: "My Setup",
    description: "Techno setup with 3 songs",
    masterState: masterController.getCurrentState(),
    syncState: syncController.getSyncState()
)

// Validate preset
let validation = preset.validate()
if !validation.isValid {
    print("Errors: \(validation.errors)")
}

// Export/Import
let jsonData = try preset.exportToJSON()
let loadedPreset = try MultiSongPreset.importFromJSON(jsonData)
```

#### 4. MultiSongPresetManager

Manages preset library with save/load functionality.

**Features:**
- Save/load presets to disk
- Preset library browser
- Import/export presets
- Default presets (ambient, techno, orchestral)
- Search by name or tags
- Undo/redo support

**Usage:**
```swift
let presetManager = try MultiSongPresetManager()

// Save current state as preset
try presetManager.savePreset(
    name: "My Preset",
    description: "Custom setup",
    masterState: masterController.getCurrentState(),
    syncState: syncController.getSyncState(),
    overwrite: false
)

// Load preset
let preset = try presetManager.loadPreset(withId: "preset-id")

// Search presets
let results = presetManager.searchPresets(query: "techno")

// Import/Export
try presetManager.importPreset(from: fileURL)
try presetManager.exportPreset(withId: "preset-id", to: exportURL)
```

## Workflow Examples

### Example 1: Basic Multi-Song Setup

```swift
// 1. Create controllers
let syncController = SyncModeController()
let masterController = MasterTransportController(
    syncModeController: syncController
)

// 2. Add song instances
masterController.addSongInstance(song1)
masterController.addSongInstance(song2)
masterController.addSongInstance(song3)

// 3. Set sync mode
masterController.setSyncMode(.locked)

// 4. Set master tempo
masterController.setMasterTempo(128.0)

// 5. Start playback
masterController.play()

// 6. Adjust tempo in real-time
masterController.setMasterTempo(140.0) // All songs update
```

### Example 2: Ratio-Based Tempo Scaling

```swift
// 1. Setup songs with different tempos
song1.setTempo(120.0) // Base: 120 BPM
song2.setTempo(90.0)  // Base: 90 BPM (0.75x)
song3.setTempo(180.0) // Base: 180 BPM (1.5x)

// 2. Capture baseline tempos
syncController.captureBaselineTempos(from: [song1, song2, song3])

// 3. Switch to ratio mode
masterController.setSyncMode(.ratio)

// 4. Change master tempo - all songs scale proportionally
masterController.setMasterTempo(100.0)
// Results:
// - song1: 100 BPM (0.83x)
// - song2: 75 BPM (0.75x)
// - song3: 150 BPM (1.5x)

// 5. Use tempo multiplier for quick changes
masterController.setTempoMultiplier(0.5) // Half speed
// Results:
// - song1: 50 BPM
// - song2: 37.5 BPM
// - song3: 75 BPM
```

### Example 3: Preset Management

```swift
let presetManager = try MultiSongPresetManager()

// Initialize default presets if library is empty
try presetManager.initializeDefaultPresets()

// Save current setup
try presetManager.savePreset(
    name: "Techno Set",
    description: "Friday night setup",
    masterState: masterController.getCurrentState(),
    syncState: syncController.getSyncState()
)

// Browse presets
print("Available presets: \(presetManager.presets.map { $0.name })")

// Load a preset
let ambientPreset = try presetManager.loadPreset(withId: "ambient-id")
masterController.restoreState(ambientPreset.masterSettings)
syncController.restoreSyncState(ambientPreset.syncSettings)

// Export preset to share
let exportURL = URL(fileURLWithPath: "/path/to/export.json")
try presetManager.exportPreset(withId: "preset-id", to: exportURL)

// Import preset from file
try presetManager.importPreset(from: importURL)
```

### Example 4: Smooth Tempo Transitions

```swift
// Enable smooth transitions
syncController.smoothTransitions = true
syncController.transitionDuration = 2.0 // 2-second crossfade

// Change tempo - smooth transition over 2 seconds
masterController.setMasterTempo(60.0)
// Songs gradually change from current tempo to 60 BPM

// Cancel active transitions if needed
syncController.cancelAllTransitions()
```

### Example 5: Emergency Stop

```swift
// Immediate stop of all audio
masterController.emergencyStop()

// This will:
// 1. Stop all song instances immediately
// 2. Set transport state to stopped
// 3. Set master volume to 0
// 4. Cancel all active transitions
```

## State Management

### State Snapshots

Both MasterTransportController and SyncModeController support state snapshots for save/restore:

```swift
// Capture current state
let masterState = masterController.getCurrentState()
let syncState = syncController.getSyncState()

// Restore state later
masterController.restoreState(masterState)
syncController.restoreSyncState(syncState)
```

### Undo/Redo Integration

All major operations support undo/redo when an UndoManager is provided:

```swift
let undoManager = UndoManager()
let masterController = MasterTransportController(
    syncModeController: syncController,
    undoManager: undoManager
)

// Operations that support undo:
masterController.setMasterTempo(120.0) // Can undo
masterController.setSyncMode(.locked) // Can undo
masterController.setMasterVolume(0.8) // Can undo

// Undo last operation
undoManager.undo()

// Redo undone operation
undoManager.redo()
```

## File Format

### Preset JSON Structure

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My Preset",
  "description": "Custom multi-song setup",
  "createdAt": "2026-01-16T10:00:00Z",
  "lastModified": "2026-01-16T10:00:00Z",
  "version": 1,
  "tags": ["techno", "live"],
  "previewImageData": null,

  "masterSettings": {
    "transportState": "playing",
    "tempo": 120.0,
    "tempoMultiplier": 1.0,
    "volume": 0.8
  },

  "songStates": [
    {
      "id": "song-1",
      "songId": "song-id-1",
      "songName": "Drone",
      "isActive": true,
      "volume": 1.0,
      "tempo": 120.0,
      "metadata": null
    }
  ],

  "syncSettings": {
    "syncMode": "locked",
    "baselineTempos": {},
    "tempoRatios": {},
    "smoothTransitions": true,
    "transitionDuration": 0.5
  },

  "customData": {
    "genre": "techno",
    "mood": "energetic"
  }
}
```

## Thread Safety

All master control components are thread-safe:

- Operations are dispatched to dedicated serial queues
- Published properties are updated on main thread
- No race conditions or data corruption

**Queue Labels:**
- `com.whiteroom.audio.master_transport` - MasterTransportController
- `com.whiteroom.audio.sync_mode` - SyncModeController
- `com.whiteroom.audio.preset_manager` - MultiSongPresetManager

## Error Handling

All components use comprehensive error handling:

```swift
do {
    try presetManager.savePreset(...)
} catch PresetError.validationFailed(let errors) {
    print("Validation errors: \(errors)")
} catch PresetError.saveFailed(let error) {
    print("Save failed: \(error)")
}
```

## Performance Considerations

1. **Smooth Transitions**: Use 10ms update intervals for glitch-free tempo changes
2. **State Snapshots**: Minimal overhead - copies only necessary data
3. **Preset I/O**: Asynchronous operations don't block audio thread
4. **Undo/Redo**: Lightweight - stores state snapshots, not full copies

## Best Practices

1. **Always validate presets** before saving or loading
2. **Use smooth transitions** for live performances
3. **Capture baseline tempos** before switching to ratio mode
4. **Enable undo/redo** for interactive applications
5. **Initialize default presets** for new installations
6. **Set appropriate transition durations** (0.1-2.0 seconds)
7. **Use emergency stop** for critical situations
8. **Tag presets** for easy searching

## Troubleshooting

**Issue: Songs not syncing in locked mode**
- Verify all songs are active (`isActive == true`)
- Check that sync mode is set to `.locked`
- Ensure `setMasterTempo` is called after mode change

**Issue: Tempo ratios not working**
- Capture baseline tempos first with `captureBaselineTempos()`
- Verify sync mode is `.ratio`
- Check that tempo ratios are set for each song

**Issue: Audio glitches during tempo changes**
- Enable smooth transitions: `smoothTransitions = true`
- Increase transition duration: `transitionDuration = 1.0`
- Check for other audio processing bottlenecks

**Issue: Preset save fails**
- Check disk space and permissions
- Verify preset name is unique
- Validate preset data before saving

## Integration Points

### JUCE Engine Integration

The master control system works with JUCE engine via `SongInstance` protocol:

```swift
public protocol SongInstance: AnyObject {
    var id: String { get }
    var song: Song { get }
    var isActive: Bool { get }

    func play()
    func pause()
    func stop()
    func setVolume(_ volume: Double)
    func setTempo(_ tempo: Double)

    func getCurrentState() -> SongInstanceState
    func restoreState(_ state: SongInstanceState)
}
```

Implement this protocol in your JUCE song wrapper to integrate with master control.

## Future Enhancements

Potential future improvements:

1. **MIDI Learn**: Map MIDI controllers to master parameters
2. **Automation**: Record and playback automation of master parameters
3. **Scene Management**: Quick-switch between multiple configurations
4. **Crossfade**: Smooth crossfade between presets
5. **Cloud Sync**: Share presets across devices
6. **Version Control**: Track preset history and changes
7. **Performance Analysis**: Monitor CPU/memory usage
8. **Custom Sync Modes**: Plugin-defined sync behaviors

## API Reference

See individual source files for complete API documentation:

- `MasterTransportController.swift` - Master coordination API
- `SyncModeController.swift` - Sync mode management API
- `MultiSongPreset.swift` - Preset data model API
- `MultiSongPresetManager.swift` - Preset library API

---

**Version**: 1.0
**Last Updated**: 2026-01-16
**Author**: White Room AI
