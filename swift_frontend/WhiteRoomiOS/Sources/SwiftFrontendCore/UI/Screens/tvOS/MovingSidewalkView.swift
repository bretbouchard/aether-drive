//
//  MovingSidewalkView.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

#if os(tvOS)

import SwiftUI

// =============================================================================
// MARK: - Moving Sidewalk View (tvOS)
// =============================================================================

/**
 tvOS-optimized multi-song player interface with remote control navigation

 Moving Sidewalk is a 10-foot UI experience for controlling multiple simultaneous
 song playbacks. Designed for television viewing with:
 - Grid layout of song cards (2-3 columns adaptive)
 - Focus-based navigation optimized for Siri Remote
 - Simplified controls (focus + select)
 - Large, readable text (minimum 44pt body)
 - High contrast focus indicators
 - Smooth focus animations
 - Remote control hints

 The interface is designed for couch viewing distance with minimal text
 and focus on big-picture musical decisions.
 */
public struct MovingSidewalkView: View {

    // MARK: - State

    @StateObject private var engine: MultiSongEngine = MockMultiSongEngine()
    @State private var selectedSlotIndex: Int?
    @State private var showingSongPicker = false
    @State private var showingSaveConfirm = false
    @State private var showingMenu = false

    // MARK: - Focus State

    @FocusState private var focusedSection: FocusSection?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Background gradient for visual depth
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    headerView

                    // Master transport controls
                    masterControlsView
                        .focused($focusedSection, equals: .masterControls)

                    // Song grid
                    songGridView
                        .focused($focusedSection, equals: .songGrid)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
            }
        }
        .overlay {
            // Menu overlay
            if showingMenu {
                menuOverlay
            }
        }
        .sheet(isPresented: $showingSongPicker) {
            SongPickerScreen(
                onSongSelected: { song in
                    if let index = selectedSlotIndex {
                        Task {
                            try? await engine.assignSong(song, toSlot: index)
                        }
                    }
                    showingSongPicker = false
                }
            )
        }
        .alert("Save Session", isPresented: $showingSaveConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    try? await engine.saveSession()
                }
            }
        } message: {
            Text("Save current multi-song session?")
        }
        .onAppear {
            // Set initial focus
            focusedSection = .masterControls

            // Start position monitoring
            engine.startMonitoring()
        }
        .onDisappear {
            engine.stopMonitoring()
        }
        .onPlayPauseCommand {
            // Handle Siri Remote play/pause button
            Task {
                try? await engine.toggleMasterPlay()
            }
        }
    }

    // =============================================================================
    // MARK: - Background Gradient
    // =============================================================================

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // =============================================================================
    // MARK: - Header View
    // =============================================================================

    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Moving Sidewalk")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.primary)

            Text("Multi-Song Player")
                .font(.system(size: 28))
                .foregroundColor(.secondary)

            Text("Use Siri Remote to navigate • Menu button for options")
                .font(.system(size: 22))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }

    // =============================================================================
    // MARK: - Master Controls View
    // =============================================================================

    private var masterControlsView: some View {
        MasterTransportControls(
            masterTransport: engine.state.masterTransport,
            onPlayPause: {
                Task {
                    try? await engine.toggleMasterPlay()
                }
            },
            onVolumeChange: { volume in
                Task {
                    try? await engine.setMasterVolume(volume)
                }
            },
            onTempoMultiplierChange: { multiplier in
                Task {
                    try? await engine.setTempoMultiplier(multiplier)
                }
            },
            onPlaybackModeChange: { mode in
                Task {
                    try? await engine.setPlaybackMode(mode)
                }
            },
            onSave: {
                showingSaveConfirm = true
            }
        )
    }

    // =============================================================================
    // MARK: - Song Grid View
    // =============================================================================

    private var songGridView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Songs")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)

            // Adaptive grid layout
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 24),
                    GridItem(.flexible(), spacing: 24),
                    GridItem(.flexible(), spacing: 24)
                ],
                spacing: 32
            ) {
                ForEach(Array(engine.state.songs.enumerated()), id: \.element.id) { index, slot in
                    SongCard(
                        slot: slot,
                        onSelect: {
                            selectedSlotIndex = index
                            if slot.song == nil {
                                showingSongPicker = true
                            }
                        },
                        onTogglePlay: {
                            Task {
                                try? await engine.togglePlaySlot(index)
                            }
                        },
                        onToggleActive: {
                            Task {
                                if slot.isActive {
                                    try? await engine.deactivateSlot(index)
                                } else {
                                    try? await engine.activateSlot(index)
                                }
                            }
                        }
                    )
                    .focusable()
                }
            }
        }
        .padding(32)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(24)
    }

    // =============================================================================
    // MARK: - Menu Overlay
    // =============================================================================

    private var menuOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingMenu = false
                    }
                }

            // Menu panel
            VStack(spacing: 0) {
                // Menu header
                HStack {
                    Text("Menu")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            showingMenu = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .background(Color.secondary.opacity(0.1))

                Divider()

                // Menu options
                VStack(spacing: 0) {
                    MenuRow(
                        icon: "plus.circle",
                        title: "New Session",
                        subtitle: "Create empty session"
                    ) {
                        Task {
                            try? await engine.createSession()
                            withAnimation {
                                showingMenu = false
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, 80)

                    MenuRow(
                        icon: "folder",
                        title: "Load Session",
                        subtitle: "Open saved session"
                    ) {
                        // TODO: Implement session picker
                        withAnimation {
                            showingMenu = false
                        }
                    }

                    Divider()
                        .padding(.leading, 80)

                    MenuRow(
                        icon: "square.and.arrow.down",
                        title: "Save Session",
                        subtitle: "Save current session"
                    ) {
                        Task {
                            try? await engine.saveSession()
                            withAnimation {
                                showingMenu = false
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, 80)

                    MenuRow(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "Audio and playback settings"
                    ) {
                        // TODO: Implement settings
                        withAnimation {
                            showingMenu = false
                        }
                    }

                    Divider()
                        .padding(.leading, 80)

                    MenuRow(
                        icon: "info.circle",
                        title: "About Moving Sidewalk",
                        subtitle: "Learn more about multi-song playback"
                    ) {
                        // TODO: Implement about
                        withAnimation {
                            showingMenu = false
                        }
                    }
                }
                .padding(.vertical, 16)

                Divider()

                // Menu footer with hints
                VStack(spacing: 12) {
                    Text("Remote Control Hints")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 32) {
                        RemoteHint(icon: "play.circle", text: "Play/Pause")
                        RemoteHint(icon: "speaker.wave.2", text: "Volume")
                        RemoteHint(icon: "goforward", text: "Swipe Scrub")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(Color.secondary.opacity(0.1))
            }
            .frame(maxWidth: 800)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 40)
        }
        .transition(.opacity)
    }
}

// =============================================================================
// MARK: - Song Card (Grid Item)
// =============================================================================

/**
 Compact card for the song grid showing essential info
 */
struct SongCard: View {
    let slot: SongSlot
    let onSelect: () -> Void
    let onTogglePlay: () -> Void
    let onToggleActive: () -> Void

    @State private var isFocused = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Slot \(slot.index + 1)")
                        .font(.system(size: 28, weight: .bold))

                    Spacer()

                    if slot.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                    }
                }
                .foregroundColor(.primary)

                // Song info or empty state
                if let song = slot.song {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(song.name)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            Image(systemName: "metronome")
                                .font(.system(size: 20))

                            Text("\(slot.transport.tempo, specifier: "%.0f") BPM")
                                .font(.system(size: 22))

                            Spacer()

                            if slot.transport.isPlaying {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("Add Song")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // Quick controls
                if slot.song != nil {
                    HStack(spacing: 16) {
                        // Play/pause button
                        Button(action: onTogglePlay) {
                            Image(systemName: slot.transport.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(slot.transport.isPlaying ? .orange : .blue)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Active toggle
                        Button(action: onToggleActive) {
                            Image(systemName: slot.isActive ? "checkmark.square.fill" : "square")
                                .font(.system(size: 36))
                                .foregroundColor(slot.isActive ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(cardBackground)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .shadow(
            color: focusShadowColor,
            radius: isFocused ? 25 : 8,
            x: 0,
            y: isFocused ? 8 : 4
        )
        .onAppear {
            // Focus animation
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = true
            }
        }
    }

    private var cardBackground: some ShapeStyle {
        if slot.isActive {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return Color.secondary.opacity(0.1)
        }
    }

    private var focusShadowColor: Color {
        if slot.isActive {
            return .accentColor.opacity(0.6)
        } else {
            return .black.opacity(0.3)
        }
    }
}

// =============================================================================
// MARK: - Menu Row
// =============================================================================

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// =============================================================================
// MARK: - Remote Hint
// =============================================================================

struct RemoteHint: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.secondary)

            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
    }
}

// =============================================================================
// MARK: - Focus Section
// =============================================================================

enum FocusSection: Hashable {
    case masterControls
    case songGrid
}

// =============================================================================
// MARK: - Song Picker Screen (Placeholder)
// =============================================================================

struct SongPickerScreen: View {
    let onSongSelected: (Song) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select a song from your library")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)

                Text("TODO: Implement song library picker")
                    .font(.system(size: 32))
                    .foregroundColor(.primary)

                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 28))
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
            }
            .navigationTitle("Choose Song")
        }
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#if DEBUG
struct MovingSidewalkView_Previews: PreviewProvider {
    static var previews: some View {
        MovingSidewalkView()
            .previewDisplayName("Moving Sidewalk - tvOS")
    }
}
#endif

#endif
