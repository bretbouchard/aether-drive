//
//  MemoryLeakTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

/**
 Memory leak tests for UI components and engine objects.

 Tests cover:
 - View dealloc after use
 - Engine dealloc after use
 - Controller dealloc after use
 - No retain cycles in closures
 - Proper weak reference usage

 All tests should pass - any failure indicates a memory leak.
 */
class MemoryLeakTests: XCTestCase {

    // MARK: - Song Player Card Memory Tests

    func testSongPlayerCard_NoRetainCycle() {
        weak var weakCard: SongPlayerCard?

        autoreleasepool {
            let slot = Fixtures.testSongSlot
            let card = SongPlayerCard(song: slot)
                .environment(\.theme, Theme.default)
            weakCard = card
        }

        XCTAssertNil(weakCard, "SongPlayerCard has retain cycle")
    }

    func testSongPlayerCardWithStateChanges_NoRetainCycle() {
        weak var weakCard: SongPlayerCard?

        autoreleasepool {
            var slot = Fixtures.testSongSlot
            let card = SongPlayerCard(song: slot)
                .environment(\.theme, Theme.default)

            // Simulate state changes
            for i in 0..<10 {
                slot.isPlaying = i % 2 == 0
                slot.tempo = 1.0 + Double(i) * 0.1
            }

            weakCard = card
        }

        XCTAssertNil(weakCard, "SongPlayerCard with state changes has retain cycle")
    }

    // MARK: - Moving Sidewalk View Memory Tests

    func testMovingSidewalkView_NoRetainCycle() {
        weak var weakView: MovingSidewalkView?

        autoreleasepool {
            let view = MovingSidewalkView()
            weakView = view
        }

        XCTAssertNil(weakView, "MovingSidewalkView has retain cycle")
    }

    func testMovingSidewalkViewWithState_NoRetainCycle() {
        weak var weakView: MovingSidewalkView?

        autoreleasepool {
            let state = MultiSongState()
            let view = MovingSidewalkView()
            // Simulate using the view
            _ = view.body
            weakView = view
        }

        XCTAssertNil(weakView, "MovingSidewalkView with state has retain cycle")
    }

    // MARK: - Multi Song Engine Memory Tests

    func testMultiSongEngine_NoRetainCycle() {
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let engine = MultiSongEngine()
            weakEngine = engine
        }

        XCTAssertNil(weakEngine, "MultiSongEngine has retain cycle")
    }

    func testMultiSongEngineWithSongs_NoRetainCycle() {
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let engine = MultiSongEngine()
            let songs = Fixtures.testSongs

            // Add songs
            for song in songs.prefix(3) {
                engine.addSong(song)
            }

            // Remove songs
            engine.removeAllSongs()

            weakEngine = engine
        }

        XCTAssertNil(weakEngine, "MultiSongEngine with songs has retain cycle")
    }

    func testMultiSongEngineWithPlayback_NoRetainCycle() {
        weak var weakEngine: MultiSongEngine?

        autoreleasepool {
            let engine = MultiSongEngine()
            let songs = Fixtures.testSongs

            // Add songs and start playback
            for song in songs.prefix(2) {
                engine.addSong(song)
            }

            engine.toggleMasterPlayback()
            engine.emergencyStop()

            weakEngine = engine
        }

        XCTAssertNil(weakEngine, "MultiSongEngine with playback has retain cycle")
    }

    // MARK: - Controller Memory Tests

    func testMasterTransportController_NoRetainCycle() {
        weak var weakController: MasterTransportController?

        autoreleasepool {
            let engine = MultiSongEngine()
            let controller = MasterTransportController(engine: engine)
            weakController = controller
        }

        XCTAssertNil(weakController, "MasterTransportController has retain cycle")
    }

    func testSyncModeController_NoRetainCycle() {
        weak var weakController: SyncModeController?

        autoreleasepool {
            let engine = MultiSongEngine()
            let controller = SyncModeController(engine: engine)
            weakController = controller
        }

        XCTAssertNil(weakController, "SyncModeController has retain cycle")
    }

    func testProjectionEngine_NoRetainCycle() {
        weak var weakEngine: ProjectionEngine?

        autoreleasepool {
            let song = Fixtures.testSong
            let engine = ProjectionEngine(song: song)
            weakEngine = engine
        }

        XCTAssertNil(weakEngine, "ProjectionEngine has retain cycle")
    }

    // MARK: - Component Memory Tests

    func testParallelProgressView_NoRetainCycle() {
        weak var weakView: ParallelProgressView?

        autoreleasepool {
            let state = Fixtures.testMultiSongState
            let view = ParallelProgressView(state: state)
                .environment(\.theme, Theme.default)
            weakView = view
        }

        XCTAssertNil(weakView, "ParallelProgressView has retain cycle")
    }

    func testMasterTransportControls_NoRetainCycle() {
        weak var weakView: MasterTransportControls?

        autoreleasepool {
            let state = Fixtures.testMultiSongState
            let view = MasterTransportControls(state: state)
                .environment(\.theme, Theme.default)
            weakView = view
        }

        XCTAssertNil(weakView, "MasterTransportControls has retain cycle")
    }

    func testMultiSongWaveformView_NoRetainCycle() {
        weak var weakView: MultiSongWaveformView?

        autoreleasepool {
            let waveform = Fixtures.testWaveform
            let view = MultiSongWaveformView(waveform: waveform)
                .environment(\.theme, Theme.default)
            weakView = view
        }

        XCTAssertNil(weakView, "MultiSongWaveformView has retain cycle")
    }

    func testTimelineMarker_NoRetainCycle() {
        weak var weakView: TimelineMarker?

        autoreleasepool {
            @State var position: Double = 0.5
            let view = TimelineMarker(position: $position, range: 0.0...1.0)
                .environment(\.theme, Theme.default)
            weakView = view
        }

        XCTAssertNil(weakView, "TimelineMarker has retain cycle")
    }

    // MARK: - State Object Memory Tests

    func testMultiSongState_NoRetainCycle() {
        weak var weakState: MultiSongState?

        autoreleasepool {
            let state = MultiSongState()
            let songs = Fixtures.testSongs

            // Populate state
            state.songs = songs.prefix(3).map { song in
                SongPlayerState(
                    id: UUID(),
                    song: song,
                    songName: song.name,
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

            weakState = state
        }

        XCTAssertNil(weakState, "MultiSongState has retain cycle")
    }

    func testSongPlayerState_NoRetainCycle() {
        weak var weakState: SongPlayerState?

        autoreleasepool {
            let state = SongPlayerState(
                id: UUID(),
                song: Fixtures.testSong,
                songName: "Test",
                tempo: 1.0,
                volume: 0.8,
                currentPosition: 0.5,
                isPlaying: false,
                isMuted: false,
                isSoloed: false,
                loopEnabled: false,
                loopStart: 0.0,
                loopEnd: 1.0
            )

            // Simulate state changes
            var mutableState = state
            for i in 0..<10 {
                mutableState.isPlaying = i % 2 == 0
                mutableState.tempo = 1.0 + Double(i) * 0.1
            }

            weakState = state
        }

        XCTAssertNil(weakState, "SongPlayerState has retain cycle")
    }

    // MARK: - Complex Scenario Memory Tests

    func testCompleteViewHierarchy_NoRetainCycle() {
        weak var weakView: CompleteMemoryTestView?

        autoreleasepool {
            let state = Fixtures.testMultiSongState
            let view = CompleteMemoryTestView(state: state)
                .environment(\.theme, Theme.default)

            // Simulate view usage
            _ = view.body

            weakView = view
        }

        XCTAssertNil(weakView, "Complete view hierarchy has retain cycle")
    }

    func testEngineWithMultipleControllers_NoRetainCycle() {
        weak var weakEngine: MultiSongEngine?
        weak var weakTransportController: MasterTransportController?
        weak var weakSyncController: SyncModeController?

        autoreleasepool {
            let engine = MultiSongEngine()
            let transportController = MasterTransportController(engine: engine)
            let syncController = SyncModeController(engine: engine)

            // Use controllers
            transportController.togglePlayback()
            syncController.setSyncMode(.locked)

            weakEngine = engine
            weakTransportController = transportController
            weakSyncController = syncController
        }

        XCTAssertNil(weakEngine, "Engine has retain cycle with multiple controllers")
        XCTAssertNil(weakTransportController, "TransportController has retain cycle")
        XCTAssertNil(weakSyncController, "SyncController has retain cycle")
    }

    func testRepeatedViewCreation_NoMemoryAccumulation() {
        // Create multiple instances to check for memory accumulation
        var weakViews: [WeakViewBox] = []

        autoreleasepool {
            for _ in 0..<10 {
                let state = Fixtures.testMultiSongState
                let view = SongPlayerCard(song: state.songs[0])
                    .environment(\.theme, Theme.default)
                weakViews.append(WeakViewBox(view: view))
            }
        }

        // All views should be deallocated
        let deallocatedCount = weakViews.filter { $0.view == nil }.count
        XCTAssertEqual(
            deallocatedCount,
            10,
            "Not all views were deallocated (only \(deallocatedCount)/10)"
        )
    }

    // MARK: - Helper Types

    private class WeakViewBox {
        weak var view: SongPlayerCard?

        init(view: SongPlayerCard) {
            self.view = view
        }
    }
}

// =============================================================================
// MARK: - Complete Memory Test View
// =============================================================================

/**
 Complete view for memory leak testing that includes all components
 */
struct CompleteMemoryTestView: View {
    @ObservedObject var state: MultiSongState
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            // Progress view
            ParallelProgressView(state: state)

            // Song cards
            ForEach(state.songs) { song in
                SongPlayerCard(song: song)
            }

            // Transport controls
            MasterTransportControls(state: state)

            // Waveform
            if let waveform = state.songs.first.map({ _ in Fixtures.testWaveform }) {
                MultiSongWaveformView(waveform: waveform)
            }
        }
    }
}
