//
//  SongPlayerCard.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

#if os(tvOS)

import SwiftUI

// =============================================================================
// MARK: - Song Player Card (tvOS)
// =============================================================================

/**
 Large focusable card for controlling a single song in the multi-song grid

 This card is optimized for tvOS with:
 - Large, readable text (minimum 44pt)
 - Prominent play/pause button
 - Big tempo/volume sliders
 - Visual focus indicator (scale + shadow)
 - Remote control hints
 - Simplified info display
 */
public struct SongPlayerCard: View {

    // MARK: - Properties

    let slot: SongSlot
    let onPlayPause: () -> Void
    let onTempoChange: (Double) -> Void
    let onVolumeChange: (Double) -> Void
    let onMute: () -> Void
    let onSolo: () -> Void
    let onDismiss: () -> Void

    @State private var isFocused = false

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Song info
            if let song = slot.song {
                songInfo(song)
            } else {
                emptySlotView
            }

            // Play/Pause button (prominent)
            playPauseButton

            // Tempo control
            tempoControl

            // Volume control
            volumeControl

            // Footer controls
            footerControls
        }
        .padding(32)
        .background(cardBackground)
        .focusable()
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(
            color: focusShadowColor,
            radius: isFocused ? 30 : 10,
            x: 0,
            y: isFocused ? 10 : 5
        )
        .onTapGesture {
            onPlayPause()
        }
    }

    // =============================================================================
    // MARK: - Header View
    // =============================================================================

    private var headerView: some View {
        HStack {
            Text("Slot \(slot.index + 1)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            if slot.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
        }
    }

    // =============================================================================
    // MARK: - Song Info
    // =============================================================================

    private func songInfo(_ song: Song) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(song.name)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)

            if !song.metadata.tags.isEmpty {
                Text(song.metadata.tags.joined(separator: " • "))
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                Label("\(song.metadata.tempo, specifier: "%.0f") BPM", systemImage: "metronome")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)

                Label(
                    "\(slot.transport.currentPosition, specifier: "%.1f")s",
                    systemImage: "clock"
                )
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }

    // =============================================================================
    // MARK: - Empty Slot View
    // =============================================================================

    private var emptySlotView: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Song")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Select a song from your library")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }

    // =============================================================================
    // MARK: - Play/Pause Button
    // =============================================================================

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            HStack(spacing: 20) {
                Image(systemName: slot.transport.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))

                Text(slot.transport.isPlaying ? "Playing" : "Play")
                    .font(.system(size: 36, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(playButtonBackground)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .disabled(slot.song == nil)
    }

    private var playButtonBackground: some ShapeStyle {
        if slot.transport.isPlaying {
            return Color.orange
        } else {
            return Color.blue
        }
    }

    // =============================================================================
    // MARK: - Tempo Control
    // =============================================================================

    private var tempoControl: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Tempo", systemImage: "metronome")
                    .font(.system(size: 28, weight: .semibold))

                Spacer()

                Text("\(slot.transport.tempo, specifier: "%.0f")")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            // Large slider for tvOS remote swipe
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 20)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * tempoProgress,
                            height: 20
                        )

                    // Thumb indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 5)
                        .offset(
                            x: (geometry.size.width * tempoProgress) - 20
                        )
                }
            }
            .frame(height: 60)
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { slot.transport.tempo },
                    set: { newValue in
                        onTempoChange(newValue)
                    }
                ),
                from: 40,
                through: 240,
                sensitivity: .medium
            )

            Text("Swipe or use Digital Crown")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }

    private var tempoProgress: Double {
        min(max((slot.transport.tempo - 40) / 200, 0), 1)
    }

    // =============================================================================
    // MARK: - Volume Control
    // =============================================================================

    private var volumeControl: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Volume", systemImage: "speaker.wave.2")
                    .font(.system(size: 28, weight: .semibold))

                Spacer()

                Text("\(Int(slot.transport.volume * 100))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            // Large slider for tvOS remote swipe
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 20)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * slot.transport.volume,
                            height: 20
                        )

                    // Thumb indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 5)
                        .offset(
                            x: (geometry.size.width * slot.transport.volume) - 20
                        )
                }
            }
            .frame(height: 60)
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { slot.transport.volume },
                    set: { newValue in
                        onVolumeChange(newValue)
                    }
                ),
                from: 0,
                through: 1,
                sensitivity: .medium
            )

            Text("Swipe or use Digital Crown")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }

    // =============================================================================
    // MARK: - Footer Controls
    // =============================================================================

    private var footerControls: some View {
        HStack(spacing: 24) {
            // Mute button
            Button(action: onMute) {
                VStack(spacing: 8) {
                    Image(systemName: slot.transport.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 36))

                    Text(slot.transport.isMuted ? "Muted" : "Mute")
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(slot.transport.isMuted ? Color.red.opacity(0.3) : Color.secondary.opacity(0.2))
                .foregroundColor(slot.transport.isMuted ? .red : .primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(slot.song == nil)

            // Solo button
            Button(action: onSolo) {
                VStack(spacing: 8) {
                    Image(systemName: slot.transport.isSolo ? "star.fill" : "star")
                        .font(.system(size: 36))

                    Text(slot.transport.isSolo ? "Solo" : "Solo")
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(slot.transport.isSolo ? Color.yellow.opacity(0.3) : Color.secondary.opacity(0.2))
                .foregroundColor(slot.transport.isSolo ? .yellow : .primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(slot.song == nil)
        }
    }

    // =============================================================================
    // MARK: - Card Background
    // =============================================================================

    private var cardBackground: some ShapeStyle {
        if slot.isActive {
            return Color.accentColor.opacity(0.15)
        } else {
            return Color.secondary.opacity(0.1)
        }
    }

    private var focusShadowColor: Color {
        if slot.isActive {
            return .accentColor.opacity(0.5)
        } else {
            return .black.opacity(0.3)
        }
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#if DEBUG
struct SongPlayerCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active slot with song playing
            SongPlayerCard(
                slot: SongSlot(
                    id: UUID().uuidString,
                    index: 0,
                    song: Song(
                        id: UUID().uuidString,
                        name: "Ethereal Journey",
                        version: "1.0",
                        metadata: SongMetadata(
                            tempo: 120.0,
                            timeSignature: [4, 4],
                            duration: 180.0,
                            key: "C minor",
                            tags: ["ambient", "cinematic"]
                        ),
                        sections: [],
                        roles: [],
                        projections: [],
                        mixGraph: MixGraph(
                            tracks: [],
                            buses: [],
                            sends: [],
                            master: MixMasterConfig(volume: 0.8)
                        ),
                        realizationPolicy: RealizationPolicy(
                            windowSize: MusicalTime(beats: 4),
                            lookaheadDuration: MusicalTime(seconds: 2.0),
                            determinismMode: .seeded
                        ),
                        determinismSeed: "demo",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    transport: TransportState(
                        isPlaying: true,
                        tempo: 120.0,
                        volume: 0.8,
                        currentPosition: 45.5,
                        isMuted: false,
                        isSolo: false
                    ),
                    isActive: true
                ),
                onPlayPause: {},
                onTempoChange: { _ in },
                onVolumeChange: { _ in },
                onMute: {},
                onSolo: {},
                onDismiss: {}
            )
            .previewDisplayName("Active Playing")

            // Inactive slot with song
            SongPlayerCard(
                slot: SongSlot(
                    id: UUID().uuidString,
                    index: 1,
                    song: Song(
                        id: UUID().uuidString,
                        name: "Rhythmic Pulse",
                        version: "1.0",
                        metadata: SongMetadata(
                            tempo: 140.0,
                            timeSignature: [4, 4],
                            duration: 240.0,
                            key: "F major",
                            tags: ["electronic", "upbeat"]
                        ),
                        sections: [],
                        roles: [],
                        projections: [],
                        mixGraph: MixGraph(
                            tracks: [],
                            buses: [],
                            sends: [],
                            master: MixMasterConfig(volume: 0.8)
                        ),
                        realizationPolicy: RealizationPolicy(
                            windowSize: MusicalTime(beats: 4),
                            lookaheadDuration: MusicalTime(seconds: 2.0),
                            determinismMode: .seeded
                        ),
                        determinismSeed: "demo",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    transport: TransportState(
                        isPlaying: false,
                        tempo: 140.0,
                        volume: 0.6,
                        currentPosition: 0.0,
                        isMuted: false,
                        isSolo: false
                    ),
                    isActive: false
                ),
                onPlayPause: {},
                onTempoChange: { _ in },
                onVolumeChange: { _ in },
                onMute: {},
                onSolo: {},
                onDismiss: {}
            )
            .previewDisplayName("Inactive Paused")

            // Empty slot
            SongPlayerCard(
                slot: SongSlot(
                    id: UUID().uuidString,
                    index: 2,
                    song: nil,
                    transport: TransportState(
                        isPlaying: false,
                        tempo: 120.0,
                        volume: 0.8
                    ),
                    isActive: false
                ),
                onPlayPause: {},
                onTempoChange: { _ in },
                onVolumeChange: { _ in },
                onMute: {},
                onSolo: {},
                onDismiss: {}
            )
            .previewDisplayName("Empty Slot")
        }
    }
}
#endif

#endif
