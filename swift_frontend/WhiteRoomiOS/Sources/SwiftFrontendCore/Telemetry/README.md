# Telemetry System

Complete UI event tracking, performance monitoring, and session replay for White Room iOS.

## Overview

The telemetry system provides comprehensive observability for White Room's iOS frontend, enabling:

- **Automatic UI tracking** - Capture all user interactions without manual instrumentation
- **Performance monitoring** - Measure operation duration with configurable thresholds
- **Session replay** - Record and debug user workflows with complete event history
- **Crash integration** - All telemetry flows to CrashReporting.swift (Firebase Crashlytics + Sentry)

## Architecture

```
Telemetry System
├── UITelemetryTracker        # Automatic UI event tracking
├── PerformanceTelemetry       # Operation timing and monitoring
├── SessionReplay              # Event replay for debugging
└── TelemetryEvent             # Shared data models
```

### Integration with CrashReporting

All telemetry systems integrate seamlessly with `CrashReporting.swift`:

- **Breadcrumbs**: Every UI event leaves a breadcrumb
- **Custom metrics**: Performance data recorded as custom keys
- **Error recording**: Slow operations and errors tracked
- **User context**: Session IDs and user info attached

## Usage

### 1. Automatic UI Tracking

Track user interactions with a simple SwiftUI modifier:

```swift
import SwiftUI
import SwiftFrontendCore

struct MovingSidewalkView: View {
    var body: some View {
        VStack {
            Button("Play") {
                audioEngine.play()
            }
            .trackInteraction("Play Button", in: "MovingSidewalkView")

            Slider(value: $tempo, in: 60...200)
                .trackInteraction("Tempo Slider", in: "MovingSidewalkView")

            Toggle("Sync Mode", isOn: $syncEnabled)
                .trackInteraction("Sync Toggle", in: "MovingSidewalkView")
        }
    }
}
```

#### Manual Event Recording

For more control, record events manually:

```swift
UITelemetryTracker.shared.trackTap("Play Button", in: "MovingSidewalkView")
UITelemetryTracker.shared.trackGesture("swipe_left", on: "PlaylistCard")
UITelemetryTracker.shared.trackNavigation(from: "LibraryView", to: "SettingsView")
UITelemetryTracker.shared.trackScreenView("PresetLibraryView")
UITelemetryTracker.shared.trackValueChange("TempoSlider", to: 120)
UITelemetryTracker.shared.trackError("Failed to load preset", in: "PresetLibraryView")
```

### 2. Performance Measurement

Measure sync operations:

```swift
let songs = PerformanceTelemetry.measure("Load Songs", threshold: 0.5) {
    try database.fetchSongs()
}
```

Measure async operations:

```swift
let loaded = await PerformanceTelemetry.measureAsync("Load Song", threshold: 0.3) {
    try await audioEngine.loadSong(url)
}
```

Use predefined thresholds:

```swift
let result = PerformanceTelemetry.measure(
    "Database Query",
    threshold: PerformanceTelemetry.Thresholds.databaseQuery
) {
    try database.query(preset)
}
```

#### Manual Performance Measurement

For complex operations, use manual measurement:

```swift
func loadPreset(_ name: String) throws {
    let token = PerformanceTelemetry.startMeasurement("Load Preset")

    try loadPresetData(name)
    applyPresetToInstruments()
    updateUI()

    PerformanceTelemetry.stopMeasurement(token, threshold: 0.2)
}
```

Or use automatic scope-based measurement:

```swift
func performComplexOperation() {
    let scope = PerformanceScope("Complex Operation", threshold: 1.0)

    // ... do work ...

    // scope records automatically when it goes out of scope
}
```

### 3. Session Replay

Record events for debugging:

```swift
let event = ReplayEvent(
    type: .tap,
    screen: "MovingSidewalkView",
    action: "Tapped Play Button",
    context: [
        "preset_name": "My Preset",
        "bpm": "120"
    ]
)

SessionReplay.shared.record(event)
```

Save session for debugging:

```swift
// Auto-saves on error events
try SessionReplay.shared.saveSession()

// Or manually save
try SessionReplay.shared.saveSession()
```

Load and analyze sessions:

```swift
// List saved sessions
let sessions = try SessionReplay.shared.listSavedSessions()

// Load a session
let session = try SessionReplay.shared.loadSession(filename: sessions.first!)

// Analyze events
for event in session.events {
    print("[\(event.type)] \(event.screen): \(event.action)")
}

// Get statistics
let stats = await SessionReplay.shared.getSessionStatistics()
print("Total events: \(stats.eventCount)")
print("Unique screens: \(stats.uniqueScreens)")
print("Duration: \(stats.duration)s")
```

## Integration Points

### Moving Sidewalk Screen Tracking

```swift
struct MovingSidewalkView: View {
    var body: some View {
        VStack {
            // All controls tracked
            PlayPauseButton()
                .trackInteraction("Play/Pause", in: "MovingSidewalkView")

            TempoSlider()
                .trackInteraction("Tempo", in: "MovingSidewalkView")

            PresetCard()
                .trackInteraction("Preset Card", in: "MovingSidewalkView")
        }
        .onAppear {
            UITelemetryTracker.shared.trackScreenView("MovingSidewalkView")
        }
    }
}
```

### Song Player Card Interactions

```swift
struct SongPlayerCard: View {
    var body: some View {
        VStack {
            Button("Play") { play() }
                .trackInteraction("Song Play Button")

            Button("Pause") { pause() }
                .trackInteraction("Song Pause Button")

            Button("Next") { next() }
                .trackInteraction("Song Next Button")
        }
    }
}
```

### Master Transport Controls

```swift
struct TransportControls: View {
    var body: some View {
        HStack {
            Button("Stop") { stop() }
                .trackInteraction("Stop Button", in: "Transport")

            Button("Play") { play() }
                .trackInteraction("Play Button", in: "Transport")

            Button("Record") { record() }
                .trackInteraction("Record Button", in: "Transport")
        }
    }
}
```

### Tempo/Volume Sliders

```swift
struct TempoSlider: View {
    @Binding var tempo: Double

    var body: some View {
        Slider(value: $tempo, in: 60...200)
            .onChange(of: tempo) { newValue in
                UITelemetryTracker.shared.trackValueChange("Tempo Slider", to: newValue)
            }
            .trackInteraction("Tempo Slider", in: "MovingSidewalkView")
    }
}
```

### Sync Mode Switching

```swift
struct SyncModeToggle: View {
    @Binding var syncEnabled: Bool

    var body: some View {
        Toggle("Sync Mode", isOn: $syncEnabled)
            .onChange(of: syncEnabled) { newValue in
                UITelemetryTracker.shared.trackValueChange("Sync Mode", to: newValue)
            }
            .trackInteraction("Sync Toggle", in: "SettingsView")
    }
}
```

### Async Operations Wrapping

```swift
// Song loading
func loadSong(_ url: URL) async throws {
    _ = await PerformanceTelemetry.measureAsync(
        "Load Song: \(url.lastPathComponent)",
        threshold: PerformanceTelemetry.Thresholds.songLoading
    ) {
        try await audioEngine.loadSong(url)
    }
}

// Preset save/load
func savePreset(_ preset: Preset) async throws {
    _ = await PerformanceTelemetry.measureAsync(
        "Save Preset: \(preset.name)",
        threshold: PerformanceTelemetry.Thresholds.presetLoading
    ) {
        try await presetManager.save(preset)
    }
}

// Navigation transitions
func navigateToSettings() {
    PerformanceTelemetry.measure(
        "Navigate to Settings",
        threshold: PerformanceTelemetry.Thresholds.navigation
    ) {
        navigationController.pushViewController(settingsVC, animated: true)
    }
}
```

## Best Practices

### 1. Use Descriptive Element Names

```swift
// Good
.trackInteraction("Play Button", in: "MovingSidewalkView")

// Bad
.trackInteraction("Button1", in: "Screen1")
```

### 2. Choose Appropriate Thresholds

```swift
// UI interactions should be fast
PerformanceTelemetry.measure("Tap Handler", threshold: 0.016) { // 16ms
    handleTap()
}

// Network requests can be slower
PerformanceTelemetry.measure("API Call", threshold: 1.0) { // 1s
    try await api.fetchData()
}
```

### 3. Add Context to Events

```swift
// Good - rich context
SessionReplay.shared.record(
    ReplayEvent(
        type: .valueChange,
        screen: "SettingsView",
        action: "Changed preset",
        context: [
            "preset_name": "My Preset",
            "bpm": "120",
            "time_signature": "4/4",
            "was_dirty": "true"
        ]
    )
)

// Bad - no context
SessionReplay.shared.record(
    ReplayEvent(
        type: .valueChange,
        screen: "SettingsView",
        action: "Changed preset",
        context: [:]
    )
)
```

### 4. Track Errors with Context

```swift
do {
    try await loadPreset(name)
} catch {
    UITelemetryTracker.shared.trackError(
        "Failed to load preset: \(error.localizedDescription)",
        in: "PresetLibraryView",
        element: "PresetCard_\(name)"
    )
    throw error
}
```

## Performance Considerations

### Thread Safety

All telemetry systems are thread-safe:

- **UITelemetryTracker**: Uses actor-based event queue
- **SessionReplay**: Uses actor-based event storage
- **PerformanceTelemetry**: Lock-free recording

### Memory Usage

- **UITelemetryTracker**: Minimal (event queue cleared to CrashReporting)
- **SessionReplay**: ~500KB for 1000 events
- **PerformanceTelemetry**: Negligible (direct recording)

### Disk Usage

Session replay files are automatically cleaned up:
- **Location**: `Library/Caches/SessionReplay/`
- **Retention**: 7 days
- **Auto-cleanup**: On app launch

## Testing

Comprehensive test coverage:

```bash
# Run all telemetry tests
swift test --filter Telemetry

# Run specific test suite
swift test --filter UITelemetryTrackerTests
swift test --filter PerformanceTelemetryTests
swift test --filter SessionReplayTests
```

## Troubleshooting

### Events Not Recording

1. Verify CrashReporting is enabled
2. Check app has write permissions
3. Review console logs for errors

### Session Save Failures

1. Verify disk space available
2. Check file permissions
3. Review error logs

### Performance Warnings

1. Verify threshold is appropriate for operation
2. Check if operation is genuinely slow
3. Consider optimization if warnings are frequent

## API Reference

### UITelemetryTracker

```swift
class UITelemetryTracker: ObservableObject {
    static let shared: UITelemetryTracker

    func trackTap(_ element: String, in screen: String)
    func trackGesture(_ gesture: String, on element: String)
    func trackNavigation(from: String, to: String)
    func trackScreenView(_ screen: String)
    func trackValueChange(_ element: String, to value: Any)
    func trackError(_ error: String, in screen: String, element: String?)
}

extension View {
    func trackInteraction(_ element: String, in screen: String) -> some View
}
```

### PerformanceTelemetry

```swift
class PerformanceTelemetry {
    static func measure<T>(
        _ operation: String,
        threshold: TimeInterval = 0.1,
        block: () throws -> T
    ) rethrows -> T

    static func measureAsync<T>(
        _ operation: String,
        threshold: TimeInterval = 0.5,
        block: () async throws -> T
    ) async rethrows -> T

    static func startMeasurement(_ operation: String) -> PerformanceMeasurementToken
    static func stopMeasurement(_ token: PerformanceMeasurementToken, threshold: TimeInterval)

    struct Thresholds {
        static let uiInteraction: TimeInterval = 0.016
        static let screenTransition: TimeInterval = 0.1
        static let databaseQuery: TimeInterval = 0.05
        static let networkRequest: TimeInterval = 1.0
        static let fileIO: TimeInterval = 0.1
        static let audioProcessing: TimeInterval = 0.05
        static let songLoading: TimeInterval = 0.5
        static let presetLoading: TimeInterval = 0.2
        static let navigation: TimeInterval = 0.1
    }
}

struct PerformanceScope {
    init(_ operation: String, threshold: TimeInterval = 0.1)
    // Records automatically on deinit
}
```

### SessionReplay

```swift
class SessionReplay {
    static let shared: SessionReplay

    func record(_ event: ReplayEvent)
    func saveSession() throws
    func loadSession(filename: String) throws -> Session
    func clearSession()
    func getEventCount() -> Int
    func getEvents() -> [ReplayEvent]
    func listSavedSessions() throws -> [String]
    func deleteSession(filename: String) throws
    func deleteAllSessions() throws
    func exportSessionAsJSON() throws -> String
    func getSessionStatistics() async -> SessionStatistics
}

struct ReplayEvent: Codable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let screen: String
    let action: String
    let context: [String: String]
}

enum EventType: String, Codable {
    case tap
    case gesture
    case navigation
    case valueChange
    case screenView
    case error
}

struct Session: Codable {
    let id: UUID
    let timestamp: Date
    let events: [ReplayEvent]
    let metadata: SessionMetadata
}

struct SessionStatistics {
    let eventCount: Int
    let eventTypeCounts: [EventType: Int]
    let uniqueScreens: Int
    let duration: TimeInterval
}
```

## License

Copyright © 2026 White Room. All rights reserved.
