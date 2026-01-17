//
//  MasterTransportControls.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

#if os(tvOS)

import SwiftUI

// =============================================================================
// MARK: - Master Transport Controls (tvOS)
// =============================================================================

/**
 Large master controls for multi-song playback

 This component provides master-level controls for all songs:
 - Master play/stop
 - Master volume
 - Tempo multiplier
 - Playback mode selection
 - Clear visual hierarchy
 - Remote button mapping
 */
public struct MasterTransportControls: View {

    // MARK: - Properties

    let masterTransport: MasterTransport
    let onPlayPause: () -> Void
    let onVolumeChange: (Double) -> Void
    let onTempoMultiplierChange: (Double) -> Void
    let onPlaybackModeChange: (MasterTransport.PlaybackMode) -> Void
    let onSave: () -> Void

    @State private var isFocused = false

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 32) {
            // Master play/stop button (prominent)
            masterPlayButton

            // Master volume control
            masterVolumeControl

            // Tempo multiplier control
            tempoMultiplierControl

            // Playback mode selector
            playbackModeSelector

            // Save button
            saveButton
        }
        .padding(40)
        .background(
            LinearGradient(
                colors: [
                    Color.secondary.opacity(0.15),
                    Color.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(
            color: .black.opacity(0.2),
            radius: 20,
            x: 0,
            y: 10
        )
    }

    // =============================================================================
    // MARK: - Master Play Button
    // =============================================================================

    private var masterPlayButton: some View {
        Button(action: onPlayPause) {
            HStack(spacing: 24) {
                Image(systemName: masterTransport.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))

                VStack(alignment: .leading, spacing: 8) {
                    Text(masterTransport.isPlaying ? "Stop All" : "Start All")
                        .font(.system(size: 40, weight: .bold))

                    Text(masterTransport.isPlaying ? "Stop all active songs" : "Start all active songs")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 48)
            .padding(.vertical, 40)
            .background(
                LinearGradient(
                    colors: masterTransport.isPlaying ? [Color.red, Color.orange] : [Color.green, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }

    // =============================================================================
    // MARK: - Master Volume Control
    // =============================================================================

    private var masterVolumeControl: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Master Volume", systemImage: "speaker.wave.3")
                    .font(.system(size: 32, weight: .bold))

                Spacer()

                Text("\(Int(masterTransport.masterVolume * 100))%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            // Large slider for tvOS remote swipe
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 24)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * masterTransport.masterVolume,
                            height: 24
                        )

                    // Thumb indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(radius: 8)
                        .offset(
                            x: (geometry.size.width * masterTransport.masterVolume) - 24
                        )
                }
            }
            .frame(height: 80)
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { masterTransport.masterVolume },
                    set: { newValue in
                        onVolumeChange(newValue)
                    }
                ),
                from: 0,
                through: 1,
                sensitivity: .medium
            )

            Text("Swipe or use Digital Crown")
                .font(.system(size: 22))
                .foregroundColor(.secondary)
        }
        .padding(28)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(20)
    }

    // =============================================================================
    // MARK: - Tempo Multiplier Control
    // =============================================================================

    private var tempoMultiplierControl: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Tempo Multiplier", systemImage: "speedometer")
                    .font(.system(size: 32, weight: .bold))

                Spacer()

                Text("×\(masterTransport.tempoMultiplier, specifier: "%.1f")")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            // Large slider for tvOS remote swipe
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 24)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * multiplierProgress,
                            height: 24
                        )

                    // Thumb indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(radius: 8)
                        .offset(
                            x: (geometry.size.width * multiplierProgress) - 24
                        )
                }
            }
            .frame(height: 80)
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { masterTransport.tempoMultiplier },
                    set: { newValue in
                        onTempoMultiplierChange(newValue)
                    }
                ),
                from: 0.5,
                through: 2.0,
                sensitivity: .medium
            )

            // Preset buttons
            HStack(spacing: 16) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { preset in
                    Button(action: { onTempoMultiplierChange(preset) }) {
                        Text("×\(preset, specifier: "%.2f")")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(masterTransport.tempoMultiplier == preset ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                masterTransport.tempoMultiplier == preset ?
                                    Color.accentColor :
                                    Color.secondary.opacity(0.2)
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Swipe, use Digital Crown, or select preset")
                .font(.system(size: 22))
                .foregroundColor(.secondary)
        }
        .padding(28)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(20)
    }

    private var multiplierProgress: Double {
        min(max((masterTransport.tempoMultiplier - 0.5) / 1.5, 0), 1)
    }

    // =============================================================================
    // MARK: - Playback Mode Selector
    // =============================================================================

    private var playbackModeSelector: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Playback Mode", systemImage: "play.rectangle.stack")
                .font(.system(size: 32, weight: .bold))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(MasterTransport.PlaybackMode.allCases, id: \.self) { mode in
                    Button(action: { onPlaybackModeChange(mode) }) {
                        VStack(spacing: 16) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 48))
                                .foregroundColor(masterTransport.playbackMode == mode ? .white : .primary)

                            Text(mode.displayName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(masterTransport.playbackMode == mode ? .white : .primary)

                            Text(modeDescription(mode))
                                .font(.system(size: 20))
                                .foregroundColor(masterTransport.playbackMode == mode ? .white.opacity(0.8) : .secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            masterTransport.playbackMode == mode ?
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                Color.secondary.opacity(0.1)
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(28)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(20)
    }

    private func modeDescription(_ mode: MasterTransport.PlaybackMode) -> String {
        switch mode {
        case .simultaneous:
            return "All songs play together"
        case .roundRobin:
            return "Songs play in sequence"
        case .random:
            return "Random song selection"
        case .cascade:
            return "Staggered start times"
        }
    }

    // =============================================================================
    // MARK: - Save Button
    // =============================================================================

    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 36))

                Text("Save Session")
                    .font(.system(size: 32, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#if DEBUG
struct MasterTransportControls_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MasterTransportControls(
                masterTransport: MasterTransport(
                    isPlaying: true,
                    masterVolume: 0.8,
                    tempoMultiplier: 1.0,
                    playbackMode: .simultaneous
                ),
                onPlayPause: {},
                onVolumeChange: { _ in },
                onTempoMultiplierChange: { _ in },
                onPlaybackModeChange: { _ in },
                onSave: {}
            )
            .previewDisplayName("Playing")

            MasterTransportControls(
                masterTransport: MasterTransport(
                    isPlaying: false,
                    masterVolume: 0.6,
                    tempoMultiplier: 1.5,
                    playbackMode: .roundRobin
                ),
                onPlayPause: {},
                onVolumeChange: { _ in },
                onTempoMultiplierChange: { _ in },
                onPlaybackModeChange: { _ in },
                onSave: {}
            )
            .previewDisplayName("Stopped - 1.5x Tempo")
        }
    }
}
#endif

#endif
