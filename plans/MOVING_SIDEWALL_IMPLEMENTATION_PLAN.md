# Moving Sidewalk Multi-Song Player Implementation Plan

## Overview
Implement a cross-platform "Moving Sidewalk" feature that allows multiple songs to play simultaneously with independent and master controls, inspired by airport moving walkways where multiple "paths" (songs) move forward together.

## Architecture

### Core Components
1. **MultiSongEngine** - Coordinates multiple song playback instances
2. **MovingSidewalkView** (iOS) - Touch-optimized multi-song interface
3. **MovingSidewalkView** (tvOS) - Remote-optimized interface
4. **SongPlayerCard** - Individual player widget for each song
5. **MasterTransportControls** - Global play/pause/stop/sync
6. **VisualTimeline** - Shows all songs progressing simultaneously

## Key Features

### Per-Song Controls
- Independent play/pause per song
- Individual tempo control (0.5x - 2.0x)
- Volume control per song
- Mute/solo per song
- Song selection and loading

### Master Controls
- Master play/pause/stop
- Global tempo multiplier (affects all songs)
- Master volume
- Sync all songs to master tempo
- Emergency stop (stops all)

### Visual Features
- Parallel progress bars (like airport moving walkways)
- Waveform visualization per song
- Timeline showing current positions
- Real-time BPM display
- Visual indicators for active/muted/soloed songs

### Advanced Features
- Song position locking (sync songs together)
- Loop points per song
- Crossfade between songs
- Save/load multi-song presets
- Export mixed audio

## Technical Implementation

### Data Models
```swift
struct MultiSongState: Identifiable {
    let id: UUID
    var songs: [SongPlayerState]
    var masterPlaying: Bool
    var masterTempo: Double
    var masterVolume: Double
    var syncMode: SyncMode
}

struct SongPlayerState: Identifiable {
    let id: UUID
    let songId: String
    var isPlaying: Bool
    var tempo: Double
    var volume: Double
    var isMuted: Bool
    var isSoloed: Bool
    var currentPosition: Double
    var loopEnabled: Bool
    var loopStart: Double
    var loopEnd: Double
}

enum SyncMode {
    case independent  // Each song has own tempo
    case locked       // All synced to master tempo
    case ratio        // Tempo ratios maintained
}
```

### Audio Engine
- Multiple `RealizationEngine` instances
- Mixed audio output using `AudioMixerNode`
- Independent tempo control per instance
- Master tempo coordination

## Platform-Specific UI

### iOS
- Touch-optimized cards with tap gestures
- Swipe to access song controls
- Pinch to resize cards
- Drag to reorder songs
- Compact view for iPhone, expanded for iPad

### tvOS
- Large focusable cards
- Remote control navigation
- Simplified controls (focus + play/pause)
- Visual focus indicators
- Menu button for context options

## File Structure
```
swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/
├── Audio/
│   ├── MultiSongEngine.swift
│   └── SongPlayerInstance.swift
├── UI/
│   ├── Screens/
│   │   ├── MovingSidewalkView.swift (iOS)
│   │   └── tvOS/
│   │       └── MovingSidewalkView.swift (tvOS)
│   └── Components/
│       ├── SongPlayerCard.swift
│       ├── MasterTransportControls.swift
│       ├── ParallelProgressView.swift
│       └── MultiSongWaveformView.swift
└── Models/
    └── MultiSongState.swift
```

## Implementation Phases

### Phase 1: Core Engine (Agent 1)
- MultiSongEngine coordination
- SongPlayerInstance wrapper
- Audio mixing setup
- Master transport logic

### Phase 2: iOS UI (Agent 2)
- MovingSidewalkView (iOS)
- SongPlayerCard components
- Touch interactions
- Compact/expanded views

### Phase 3: tvOS UI (Agent 3)
- MovingSidewalkView (tvOS)
- Remote navigation
- Focus management
- Simplified controls

### Phase 4: Visual Timeline (Agent 4)
- ParallelProgressView
- Multi-song waveform display
- Real-time position tracking
- Visual sync indicators

### Phase 5: Master Controls (Agent 5)
- MasterTransportControls
- Global tempo/mix
- Sync modes
- Preset management

### Phase 6: Testing & Polish (Agent 6)
- Unit tests
- Integration tests
- Performance optimization
- Documentation

## Success Criteria
✅ Multiple songs load and play simultaneously
✅ Independent tempo/volume control per song
✅ Master transport controls all songs
✅ iOS and tvOS optimized interfaces
✅ Visual timeline shows real-time progress
✅ Audio mixing works correctly
✅ Performance acceptable (6+ songs)
✅ Save/load multi-song presets

## Estimated Timeline
- Parallel execution: 2-3 days
- Sequential testing: 1 day
- Total: 3-4 days

## Dependencies
- Existing RealizationEngine
- Existing Song models
- Existing audio infrastructure
- JUCE audio backend
