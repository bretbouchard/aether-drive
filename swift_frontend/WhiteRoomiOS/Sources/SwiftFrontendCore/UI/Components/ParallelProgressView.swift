//
//  ParallelProgressView.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  Visual timeline showing multiple songs progressing simultaneously
//  like airport moving walkways - each song has its own track moving
//  at its own rate while maintaining visual sync relationships.

import SwiftUI

// =============================================================================
// MARK: - Parallel Progress View
// =============================================================================

/**
 Visual timeline for parallel multi-song playback.

 Displays horizontal progress bars (like moving walkways) for each song,
 showing real-time position updates, loop markers, and scrubbing support.

 Key Features:
 - Parallel horizontal tracks for each song
 - Real-time position updates at 60fps
 - Loop start/end markers
 - Scrubbing with touch drag
 - Zoom in/out with pinch gesture
 - Color coding by state (playing, paused, muted, solo)
 - Smooth animations and transitions
 */
public struct ParallelProgressView: View {

    // MARK: - State

    @ObservedObject var engine: MultiSongEngine

    @State private var draggedSongId: String?
    @State private var isDragging = false
    @State private var lastDragPosition: Double = 0.0
    @State private var currentZoom: CGFloat = 1.0

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    // MARK: - Initialization

    public init(engine: MultiSongEngine) {
        self.engine = engine
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Timeline header
            TimelineHeader(engine: engine)

            // Vertical scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(engine.songs) { song in
                        SongTrack(
                            song: song,
                            engine: engine,
                            zoomLevel: engine.zoomLevel,
                            scrollOffset: engine.scrollOffset,
                            isBeingDragged: draggedSongId == song.id
                        )
                        .frame(height: 60)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDragChanged(for: song, value: value)
                                }
                                .onEnded { value in
                                    handleDragEnded(for: song, value: value)
                                }
                        )
                    }
                }
            }

            // Timeline controls
            TimelineControls(engine: engine)
        }
        .background(backgroundColor)
        .gesture(
            MagnificationGesture()
                .onChanged { scale in
                    handlePinchChanged(scale)
                }
                .onEnded { scale in
                    handlePinchEnded(scale)
                }
        )
    }

    // MARK: - Helper Views

    private var backgroundColor: Color {
        isDarkMode ? Color.black : Color.white
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(for song: MultiSongState, value: DragGesture.Value) {
        draggedSongId = song.id
        isDragging = true

        // Calculate position in timeline
        let timelineWidth = calculateTimelineWidth()
        let position = value.location.x / timelineWidth

        // Update song position
        let newPosition = position * song.duration
        engine.seekSong(id: song.id, to: newPosition)
    }

    private func handleDragEnded(for song: MultiSongState, value: DragGesture.Value) {
        draggedSongId = nil
        isDragging = false
    }

    private func handlePinchChanged(_ scale: CGFloat) {
        currentZoom = scale
    }

    private func handlePinchEnded(_ scale: CGFloat) {
        // Adjust zoom level
        let newZoom = Double(currentZoom * engine.zoomLevel)
        engine.setZoomLevel(newZoom)
        currentZoom = 1.0
    }

    private func calculateTimelineWidth() -> CGFloat {
        // This would be calculated based on actual view geometry
        return 1000.0
    }
}

// =============================================================================
// MARK: - Song Track
// =============================================================================

/**
 Single track in the parallel timeline.

 Shows one song's progress bar, waveform, loop markers, and playhead.
 */
private struct SongTrack: View {

    let song: MultiSongState
    let engine: MultiSongEngine
    let zoomLevel: Double
    let scrollOffset: Double
    let isBeingDragged: Bool

    @State private var trackWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                TrackBackground(song: song, width: geometry.size.width)

                // Waveform overlay
                TrackWaveform(song: song, width: geometry.size.width)

                // Progress fill
                TrackProgress(song: song, width: geometry.size.width)

                // Loop markers
                if song.isLooping {
                    LoopMarkers(
                        song: song,
                        width: geometry.size.width
                    )
                }

                // Playhead
                Playhead(
                    position: song.progress,
                    width: geometry.size.width,
                    color: song.color
                )

                // Time ruler
                TimeRuler(
                    duration: song.duration,
                    zoomLevel: zoomLevel,
                    width: geometry.size.width
                )
            }
            .frame(height: 60)
            .onAppear {
                trackWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { newWidth in
                trackWidth = newWidth
            }
        }
        .overlay(
            // Song info overlay
            SongInfoOverlay(song: song),
            alignment: .leading
        )
        .scaleEffect(isBeingDragged ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isBeingDragged)
    }
}

// =============================================================================
// MARK: - Track Background
// =============================================================================

private struct TrackBackground: View {

    let song: MultiSongState
    let width: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        if song.isMuted {
            return Color.gray.opacity(0.2)
        } else if song.isSoloed {
            return song.color.opacity(0.1)
        } else {
            return Color.primary.opacity(0.05)
        }
    }

    private var borderColor: Color {
        if song.isMuted {
            return Color.gray.opacity(0.3)
        } else if song.isPlaying {
            return song.color.opacity(0.5)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
}

// =============================================================================
// MARK: - Track Waveform
// =============================================================================

private struct TrackWaveform: View {

    let song: MultiSongState
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let waveformData = generateWaveformPoints(width: geometry.size.width)

            ZStack {
                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, point in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(waveformColor)
                        .frame(width: max(1, point.width), height: point.height)
                        .position(x: point.x, y: geometry.size.height / 2)
                }
            }
        }
    }

    private var waveformColor: Color {
        if song.isMuted {
            return Color.gray.opacity(0.3)
        } else {
            return song.color.opacity(0.4)
        }
    }

    private func generateWaveformPoints(width: CGFloat) -> [WaveformBar] {
        guard !song.waveform.isEmpty else { return [] }

        let barCount = min(song.waveform.count, 100)
        let barSpacing = width / CGFloat(barCount)
        var bars: [WaveformBar] = []

        for i in 0..<barCount {
            let point = song.waveform[i]
            let barHeight = CGFloat(point.amplitude) * 40.0 // Max height 40pt

            bars.append(WaveformBar(
                x: CGFloat(i) * barSpacing + barSpacing / 2,
                width: barSpacing - 2,
                height: barHeight
            ))
        }

        return bars
    }

    private struct WaveformBar {
        let x: CGFloat
        let width: CGFloat
        let height: CGFloat
    }
}

// =============================================================================
// MARK: - Track Progress
// =============================================================================

private struct TrackProgress: View {

    let song: MultiSongState
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let progressWidth = geometry.size.width * song.progress

            RoundedRectangle(cornerRadius: 8)
                .fill(progressColor)
                .frame(width: progressWidth)
                .animation(.linear(duration: 0.016), value: song.progress) // 60fps smooth
        }
    }

    private var progressColor: Color {
        if song.isMuted {
            return Color.gray.opacity(0.3)
        } else if song.isPlaying {
            return song.color.opacity(0.6)
        } else {
            return song.color.opacity(0.3)
        }
    }
}

// =============================================================================
// MARK: - Playhead
// =============================================================================

private struct Playhead: View {

    let position: Double
    let width: CGFloat
    let color: Color

    var body: some View {
        let xPos = width * CGFloat(position)

        return ZStack {
            // Vertical line
            Rectangle()
                .fill(color)
                .frame(width: 2)

            // Circle at top
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(y: -4)

            // Glow effect
            Rectangle()
                .fill(color)
                .frame(width: 2)
                .blur(radius: 2)
                .opacity(0.5)
        }
        .position(x: xPos, y: 30)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 0)
    }
}

// =============================================================================
// MARK: - Loop Markers
// =============================================================================

private struct LoopMarkers: View {

    let song: MultiSongState
    let width: CGFloat

    var body: some View {
        ZStack {
            if let loopStart = song.loopStart, let loopEnd = song.loopEnd {
                let startX = width * CGFloat(loopStart / song.duration)
                let endX = width * CGFloat(loopEnd / song.duration)

                // Loop region background
                RoundedRectangle(cornerRadius: 4)
                    .fill(song.color.opacity(0.2))
                    .frame(width: endX - startX)
                    .position(x: (startX + endX) / 2, y: 30)

                // Loop start marker
                LoopMarker(type: .start, color: song.color)
                    .position(x: startX, y: 30)

                // Loop end marker
                LoopMarker(type: .end, color: song.color)
                    .position(x: endX, y: 30)
            }
        }
    }
}

private struct LoopMarker: View {

    enum MarkerType {
        case start
        case end
    }

    let type: MarkerType
    let color: Color

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: 3)

            if type == .start {
                // Left arrow
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: -6, y: -6))
                    path.addLine(to: CGPoint(x: -6, y: 6))
                    path.closeSubpath()
                }
                .fill(color)
            } else {
                // Right arrow
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 6, y: -6))
                    path.addLine(to: CGPoint(x: 6, y: 6))
                    path.closeSubpath()
                }
                .fill(color)
            }
        }
        .frame(height: 20)
    }
}

// =============================================================================
// MARK: - Time Ruler
// =============================================================================

private struct TimeRuler: View {

    let duration: Double
    let zoomLevel: Double
    let width: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(timeMarkers(), id: \.self) { time in
                if time > 0 {
                    TimeTick(time: time, width: width)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 8)
        .position(x: width / 2, y: 56)
    }

    private func timeMarkers() -> [Double] {
        let interval = timeInterval()
        var markers: [Double] = []

        var currentTime = 0.0
        while currentTime <= duration {
            markers.append(currentTime)
            currentTime += interval
        }

        return markers
    }

    private func timeInterval() -> Double {
        // Calculate time interval based on zoom level
        switch zoomLevel {
        case 0..<20:
            return 60.0 // Every minute
        case 20..<50:
            return 30.0 // Every 30 seconds
        case 50..<100:
            return 15.0 // Every 15 seconds
        default:
            return 5.0 // Every 5 seconds
        }
    }
}

private struct TimeTick: View {

    let time: Double
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 1, height: 6)

            Text(formatTime(time))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// =============================================================================
// MARK: - Song Info Overlay
// =============================================================================

private struct SongInfoOverlay: View {

    let song: MultiSongState

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Song name
            Text(song.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // Current time
            Text(song.currentTimeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .monospacedDigit()

            Spacer()

            // Duration
            Text(song.durationString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .monospacedDigit()

            // Playback rate
            if song.playbackRate != 1.0 {
                Text("\(String(format: "%.1fx", song.playbackRate))")
                    .font(.caption2)
                    .foregroundColor(song.color)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.1))
                .blur(radius: 1)
        )
        .padding(.leading, 8)
        .padding(.top, 4)
    }

    private var statusColor: Color {
        if song.isMuted {
            return .gray
        } else if song.isPlaying {
            return song.color
        } else {
            return .secondary
        }
    }
}

// =============================================================================
// MARK: - Timeline Header
// =============================================================================

private struct TimelineHeader: View {

    @ObservedObject var engine: MultiSongEngine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Parallel Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(engine.songs.count) song\(engine.songs.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Global time display
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatGlobalTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var formatGlobalTime: String {
        let mins = Int(engine.globalTime) / 60
        let secs = Int(engine.globalTime) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// =============================================================================
// MARK: - Timeline Controls
// =============================================================================

private struct TimelineControls: View {

    @ObservedObject var engine: MultiSongEngine

    var body: some View {
        HStack(spacing: 16) {
            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(engine.isPlaying ? Color.orange : Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())

            // Stop button
            Button(action: stopPlayback) {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Zoom controls
            HStack(spacing: 8) {
                Button(action: { zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())

                Text("\(Int(engine.zoomLevel))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30)

                Button(action: { zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func togglePlayback() {
        if engine.isPlaying {
            engine.pause()
        } else {
            engine.play()
        }
    }

    private func stopPlayback() {
        engine.stop()
    }

    private func zoomIn() {
        engine.setZoomLevel(engine.zoomLevel * 1.2)
    }

    private func zoomOut() {
        engine.setZoomLevel(engine.zoomLevel / 1.2)
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#if DEBUG
struct ParallelProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            ParallelProgressView(engine: MultiSongEngine())
                .previewDisplayName("Light Mode")
                .preferredColorScheme(.light)

            // Dark mode
            ParallelProgressView(engine: MultiSongEngine())
                .previewDisplayName("Dark Mode")
                .preferredColorScheme(.dark)

            // iPhone size
            ParallelProgressView(engine: MultiSongEngine())
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone 14 Pro")

            // iPad size
            ParallelProgressView(engine: MultiSongEngine())
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad Pro")
        }
    }
}
#endif
