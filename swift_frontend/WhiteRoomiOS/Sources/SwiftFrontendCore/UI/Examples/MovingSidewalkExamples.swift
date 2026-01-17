//
//  MovingSidewalkExamples.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import SwiftUI

// =============================================================================
// MARK: - Usage Examples
// =============================================================================

/**
 Examples showing how to use the Moving Sidewalk interface
 */

// =============================================================================
// MARK: - Example 1: Basic Setup
// =============================================================================

/**
 Basic setup of the Moving Sidewalk interface

 Usage:
 ```
 let movingSidewalk = MovingSidewalkView()
 ```
 */
struct BasicUsageExample: View {
    var body: some View {
        NavigationView {
            MovingSidewalkView()
        }
    }
}

// =============================================================================
// MARK: - Example 2: Custom Initialization
// =============================================================================

/**
 Initialize with custom songs

 Usage:
 ```
 let view = MovingSidewalkWithCustomSongs()
 ```
 */
struct MovingSidewalkWithCustomSongs: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        NavigationView {
            MovingSidewalkView()
                .environmentObject(state)
        }
        .onAppear {
            loadCustomSongs()
        }
    }

    private func loadCustomSongs() {
        // Create custom songs
        let song1 = SongPlayerState(
            name: "My Song",
            artist: "My Artist",
            originalBPM: 120.0,
            duration: 240.0,
            waveform: generateWaveform()
        )

        let song2 = SongPlayerState(
            name: "Another Song",
            artist: "Another Artist",
            originalBPM: 128.0,
            duration: 200.0,
            waveform: generateWaveform()
        )

        state.songs = [song1, song2]
    }

    private func generateWaveform() -> [Float] {
        // Generate synthetic waveform
        return (0..<100).map { _ in Float.random(in: 0.1...1.0) }
    }
}

// =============================================================================
// MARK: - Example 3: Programmatic Control
// =============================================================================

/**
 Control the interface programmatically

 Usage:
 ```
 let view = ProgrammaticControlExample()
 ```
 */
struct ProgrammaticControlExample: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        VStack(spacing: 20) {
            // Custom controls
            Button("Play All") {
                playAllSongs()
            }

            Button("Stop All") {
                stopAllSongs()
            }

            Button("Set Sync Mode: Locked") {
                state.syncMode = .locked
            }

            Button("Set Master Tempo: 1.5x") {
                state.masterTempo = 1.5
            }

            // Show the interface
            MovingSidewalkView()
                .environmentObject(state)
        }
    }

    private func playAllSongs() {
        state.isMasterPlaying = true
        for song in state.songs {
            song.isPlaying = true
        }
    }

    private func stopAllSongs() {
        state.stopAll()
    }
}

// =============================================================================
// MARK: - Example 4: Preset Management
// =============================================================================

/**
 Save and load presets

 Usage:
 ```
 let view = PresetManagementExample()
 ```
 */
struct PresetManagementExample: View {
    @StateObject private var state = MultiSongState()
    @State private var savedPresets: [MultiSongPreset] = []

    var body: some View {
        VStack {
            // Preset controls
            HStack {
                Button("Save Preset") {
                    saveCurrentAsPreset()
                }

                Button("Load Preset") {
                    loadFirstPreset()
                }
            }

            // Show interface
            MovingSidewalkView()
                .environmentObject(state)
        }
    }

    private func saveCurrentAsPreset() {
        let songConfigs = state.songs.map { song in
            SongPresetConfig(
                songId: song.id,
                tempoMultiplier: song.tempoMultiplier,
                volume: song.volume,
                isMuted: song.isMuted,
                isSolo: song.isSolo
            )
        }

        let preset = MultiSongPreset(
            name: "My Preset",
            songs: songConfigs,
            masterSettings: MasterSettings(
                masterTempo: state.masterTempo,
                masterVolume: state.masterVolume,
                isLooping: state.masterTransport.isLooping
            ),
            syncMode: state.syncMode
        )

        savedPresets.append(preset)
    }

    private func loadFirstPreset() {
        guard let preset = savedPresets.first else { return }

        // Apply preset to state
        state.masterTempo = preset.masterSettings.masterTempo
        state.masterVolume = preset.masterSettings.masterVolume
        state.masterTransport.isLooping = preset.masterSettings.isLooping
        state.syncMode = preset.syncMode

        // Apply song settings
        for config in preset.songs {
            if let song = state.getSong(id: config.songId) {
                song.tempoMultiplier = config.tempoMultiplier
                song.volume = config.volume
                song.isMuted = config.isMuted
                song.isSolo = config.isSolo
            }
        }
    }
}

// =============================================================================
// MARK: - Example 5: Backend Integration
// =============================================================================

/**
 Integrate with backend audio engine

 Usage:
 ```
 let view = BackendIntegrationExample()
 ```
 */
struct BackendIntegrationExample: View {
    @StateObject private var state = MultiSongState()

    // This would be your actual backend
    // private let backend = MultiSongEngine()

    var body: some View {
        MovingSidewalkView()
            .environmentObject(state)
            .onAppear {
                loadSongsFromBackend()
            }
            .onChange(of: state.songs) { songs in
                syncToBackend(songs)
            }
    }

    private func loadSongsFromBackend() {
        // In real implementation:
        // state.songs = backend.loadSongs()

        // For demo:
        state.songs = SongPlayerState.demoSongs()
    }

    private func syncToBackend(_ songs: [SongPlayerState]) {
        // In real implementation:
        // backend.updateSongs(songs)

        print("Syncing \(songs.count) songs to backend")
    }
}

// =============================================================================
// MARK: - Example 6: Custom Theme
// =============================================================================

/**
 Apply custom theme to the interface

 Usage:
 ```
 let view = CustomThemeExample()
 ```
 */
struct CustomThemeExample: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        MovingSidewalkView()
            .environmentObject(state)
            .environment(\.theme, .studio) // Use studio theme
    }
}

// =============================================================================
// MARK: - Example 7: Event Handling
// =============================================================================

/**
 Handle events from the interface

 Usage:
 ```
 let view = EventHandlingExample()
 ```
 */
struct EventHandlingExample: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        MovingSidewalkView()
            .environmentObject(state)
            .onChange(of: state.isMasterPlaying) { isPlaying in
                handleMasterPlayChange(isPlaying)
            }
            .onChange(of: state.syncMode) { mode in
                handleSyncModeChange(mode)
            }
            .onChange(of: state.masterTempo) { tempo in
                handleTempoChange(tempo)
            }
    }

    private func handleMasterPlayChange(_ isPlaying: Bool) {
        print("Master play changed: \(isPlaying)")
        // Handle event
    }

    private func handleSyncModeChange(_ mode: MultiSongState.SyncMode) {
        print("Sync mode changed: \(mode.rawValue)")
        // Handle event
    }

    private func handleTempoChange(_ tempo: Double) {
        print("Master tempo changed: \(tempo)x")
        // Handle event
    }
}

// =============================================================================
// MARK: - Example 8: Animation Customization
// =============================================================================

/**
 Customize animations

 Usage:
 ```
 let view = AnimationCustomizationExample()
 ```
 */
struct AnimationCustomizationExample: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        MovingSidewalkView()
            .environmentObject(state)
            .animation(
                UIAccessibility.isReduceMotionEnabled
                    ? .none
                    : .spring(response: 0.3, dampingFraction: 0.7),
                value: state.isMasterPlaying
            )
    }
}

// =============================================================================
// MARK: - Example 9: Accessibility Enhancement
// =============================================================================

/**
 Add custom accessibility features

 Usage:
 ```
 let view = AccessibilityEnhancementExample()
 ```
 */
struct AccessibilityEnhancementExample: View {
    @StateObject private var state = MultiSongState()

    var body: some View {
        MovingSidewalkView()
            .environmentObject(state)
            .onAppear {
                setupAccessibility()
            }
    }

    private func setupAccessibility() {
        // Announce screen to VoiceOver
        VoiceOverFocusEngine.announceScreenChange(
            "Moving Sidewalk with \(state.songs.count) songs loaded"
        )
    }
}

// =============================================================================
// MARK: - Example 10: Performance Monitoring
// =============================================================================

/**
 Monitor performance of the interface

 Usage:
 ```
 let view = PerformanceMonitoringExample()
 ```
 */
struct PerformanceMonitoringExample: View {
    @StateObject private var state = MultiSongState()
    @State private var frameRate: Double = 60.0

    var body: some View {
        VStack {
            // Performance metrics
            Text("Frame Rate: \(Int(frameRate)) fps")
                .font(.caption)
                .foregroundColor(.secondary)

            // Main interface
            MovingSidewalkView()
                .environmentObject(state)
        }
        .onAppear {
            startPerformanceMonitoring()
        }
    }

    private func startPerformanceMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // In real implementation, measure actual frame rate
                frameRate = 60.0
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

import Combine

// =============================================================================
// MARK: - Preview
// =============================================================================

struct MovingSidewalkExamples_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BasicUsageExample()
                .previewDisplayName("Basic Usage")

            CustomThemeExample()
                .previewDisplayName("Custom Theme")

            ProgrammaticControlExample()
                .previewDisplayName("Programmatic Control")
        }
    }
}
