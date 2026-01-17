//
//  UIPerformanceTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

/**
 Performance tests for UI components to ensure smooth rendering.

 Tests cover:
 - View rendering performance
 - Component layout calculations
 - Animation frame rates
 - Memory efficiency during rendering

 Baseline metrics (in seconds):
 - SongPlayerCard: < 0.01s per render
 - MovingSidewalkView: < 0.05s per render
 - ParallelProgressView: < 0.02s per render
 - MultiSongWaveformView: < 0.03s per render
 - TimelineMarker: < 0.015s per render
 - MasterTransportControls: < 0.025s per render
 */
class UIPerformanceTests: XCTestCase {

    // MARK: - Song Player Card Performance

    func testSongPlayerCardRendering_Performance() {
        let slot = Fixtures.testSongSlot
        let card = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render card 100 times
            for _ in 0..<100 {
                _ = card.body
            }
        }
    }

    func testSongPlayerCardWithStateChanges_Performance() {
        var slot = Fixtures.testSongSlot
        let card = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate state changes
            for i in 0..<100 {
                slot.isPlaying = i % 2 == 0
                slot.tempo = 1.0 + Double(i) * 0.01
                _ = card.body
            }
        }
    }

    // MARK: - Moving Sidewalk View Performance

    func testMovingSidewalkViewRendering_Performance() {
        let state = Fixtures.testMultiSongState
        let view = configureTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render view 50 times
            for _ in 0..<50 {
                _ = view.body
            }
        }
    }

    func testMovingSidewalkViewWithManySongs_Performance() {
        var state = Fixtures.testMultiSongState
        // Add more songs for stress test
        for i in 6..<12 {
            state.songs.append(createTestSongSlot(index: i))
        }

        let view = configureTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render view 25 times (fewer due to complexity)
            for _ in 0..<25 {
                _ = view.body
            }
        }
    }

    // MARK: - Parallel Progress View Performance

    func testParallelProgressViewRendering_Performance() {
        let state = Fixtures.testMultiSongState
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render 100 times at 60fps (16.67ms per frame)
            for _ in 0..<100 {
                _ = view.body
            }
        }
    }

    func testParallelProgressViewWithUpdatingPositions_Performance() {
        var state = Fixtures.testMultiSongState
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate progress updates
            for i in 0..<100 {
                let progress = Double(i) / 100.0
                state.songs.forEach { $0.currentPosition = progress }
                _ = view.body
            }
        }
    }

    // MARK: - Waveform View Performance

    func testMultiSongWaveformViewRendering_Performance() {
        let waveform = Fixtures.testWaveform
        let view = MultiSongWaveformView(waveform: waveform)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render 50 times
            for _ in 0..<50 {
                _ = view.body
            }
        }
    }

    func testMultiSongWaveformViewWithLargeWaveform_Performance() {
        // Create larger waveform for stress test
        var largeWaveform = Fixtures.testWaveform
        largeWaveform.samples = (0..<10000).map { _ in Float.random(in: -1...1) }

        let view = MultiSongWaveformView(waveform: largeWaveform)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render 25 times (fewer due to complexity)
            for _ in 0..<25 {
                _ = view.body
            }
        }
    }

    // MARK: - Timeline Marker Performance

    func testTimelineMarkerRendering_Performance() {
        @State var position: Double = 0.5
        let view = TimelineMarker(position: $position, range: 0.0...1.0)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render 200 times (draggable, needs more iterations)
            for _ in 0..<200 {
                _ = view.body
            }
        }
    }

    func testTimelineMarkerWithPositionUpdates_Performance() {
        @State var position: Double = 0.0
        let view = TimelineMarker(position: $position, range: 0.0...1.0)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate dragging
            for i in 0..<200 {
                position = Double(i) / 200.0
                _ = view.body
            }
        }
    }

    // MARK: - Master Transport Controls Performance

    func testMasterTransportControlsRendering_Performance() {
        let state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render 100 times
            for _ in 0..<100 {
                _ = view.body
            }
        }
    }

    func testMasterTransportControlsWithStateChanges_Performance() {
        var state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate state changes
            for i in 0..<100 {
                state.masterPlaying = i % 2 == 0
                state.songs.forEach { $0.isPlaying = i % 2 == 0 }
                _ = view.body
            }
        }
    }

    // MARK: - Complex View Performance

    func testCompleteMovingSidewalkView_Performance() {
        let state = Fixtures.testMultiSongState
        let view = CompleteTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Render complete view 20 times (complex view)
            for _ in 0..<20 {
                _ = view.body
            }
        }
    }

    func testCompleteMovingSidewalkViewWithAnimations_Performance() {
        var state = Fixtures.testMultiSongState
        let view = CompleteTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate animation frame updates (60fps target)
            for i in 0..<60 {
                // Update positions
                for j in 0..<state.songs.count {
                    state.songs[j].currentPosition = (Double(i) / 60.0 + Double(j) * 0.1).truncatingRemainder(dividingBy: 1.0)
                }
                _ = view.body
            }
        }
    }

    // MARK: - Memory Performance

    func testMemoryUsageDuringRendering() {
        let state = Fixtures.testMultiSongState
        let view = CompleteTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTMemoryMetric()]) {
            // Render view 50 times and measure memory
            for _ in 0..<50 {
                _ = view.body
            }
        }
    }

    func testMemoryUsageWithManySongs() {
        var state = Fixtures.testMultiSongState
        // Add more songs
        for i in 6..<20 {
            state.songs.append(createTestSongSlot(index: i))
        }

        let view = configureTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTMemoryMetric()]) {
            // Render view 30 times
            for _ in 0..<30 {
                _ = view.body
            }
        }
    }

    // MARK: - CPU Performance

    func testCPUUsageDuringComplexRendering() {
        var state = Fixtures.testMultiSongState
        let view = CompleteTestView(state: state)
            .environment(\.theme, Theme.default)

        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            // Render complete view with state updates
            for i in 0..<50 {
                state.songs.forEach { song in
                    song.currentPosition = Double(i) / 50.0
                }
                _ = view.body
            }
        }
    }

    // MARK: - Helper Methods

    private func configureTestView(state: MultiSongState) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timeline placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 60)

                // Song cards
                LazyVStack(spacing: 12) {
                    ForEach(state.songs) { song in
                        SongPlayerCard(song: song)
                    }
                }

                // Progress view
                ParallelProgressView(state: state)
            }
        }
    }

    private func createTestSongSlot(index: Int) -> SongPlayerState {
        SongPlayerState(
            id: UUID(),
            song: Fixtures.testSongs[index % Fixtures.testSongs.count],
            songName: "Test Song \(index)",
            tempo: 1.0,
            volume: 0.8,
            currentPosition: 0.0,
            isPlaying: false,
            isMuted: false,
            isSoloed: false,
            loopEnabled: false,
            loopStart: 0.0,
            loopEnd: 1.0
        )
    }
}

// =============================================================================
// MARK: - Complete Test View
// =============================================================================

/**
 Complete test view that includes all components for performance testing
 */
struct CompleteTestView: View {
    @ObservedObject var state: MultiSongState
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Visual timeline
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.palette.background.secondary)
                    .frame(height: 60)
                    .overlay(
                        Text("Timeline")
                            .font(.caption)
                            .foregroundColor(theme.palette.text.tertiary)
                    )

                // Progress view
                ParallelProgressView(state: state)

                // Song cards
                LazyVStack(spacing: 12) {
                    ForEach(state.songs) { song in
                        SongPlayerCard(song: song)
                    }
                }

                // Waveform view
                if let waveform = state.songs.first.map({ _ in Fixtures.testWaveform }) {
                    MultiSongWaveformView(waveform: waveform)
                }

                // Transport controls
                MasterTransportControls(state: state)
            }
            .padding()
        }
    }
}
