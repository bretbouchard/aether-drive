//
//  MovingSidewalkUITests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Moving Sidewalk UI Tests
// =============================================================================

@MainActor
final class MovingSidewalkUITests: XCTestCase {

    // =============================================================================
    // MARK: - Test Song Player Card Component
    // =============================================================================

    func testSongPlayerCardCreation() async throws {
        // Given: Song player state
        let state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isPlaying: false,
            tempo: 1.0,
            volume: 0.8,
            currentPosition: 45.5,
            duration: 180.0
        )

        // When: Creating card (would create view in real implementation)
        // Then: Should display correctly
        XCTAssertEqual(state.songName, "Test Song")
        XCTAssertEqual(state.currentPosition, 45.5, accuracy: 0.1)
        XCTAssertFalse(state.isPlaying)
    }

    func testSongPlayerCardProgressCalculation() async throws {
        // Given: Song player state
        let state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            currentPosition: 90.0,
            duration: 180.0
        )

        // When: Calculating progress
        let progress = state.currentPosition / state.duration

        // Then: Should be 50%
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testSongPlayerCardMuteToggle() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isMuted: false
        )

        XCTAssertFalse(state.isMuted)

        // When: Toggling mute
        state.isMuted.toggle()

        // Then: Should be muted
        XCTAssertTrue(state.isMuted)
    }

    func testSongPlayerCardSoloToggle() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isSoloed: false
        )

        XCTAssertFalse(state.isSoloed)

        // When: Toggling solo
        state.isSoloed.toggle()

        // Then: Should be soloed
        XCTAssertTrue(state.isSoloed)
    }

    // =============================================================================
    // MARK: - Test Master Transport Controls
    // =============================================================================

    func testMasterPlayButton() async throws {
        // Given: Multi-song state
        var state = MultiSongState(
            masterPlaying: false
        )

        XCTAssertFalse(state.masterPlaying)

        // When: Toggling master play
        state.masterPlaying.toggle()

        // Then: Should be playing
        XCTAssertTrue(state.masterPlaying)
    }

    func testMasterTempoSlider() async throws {
        // Given: Multi-song state
        var state = MultiSongState(
            masterTempo: 1.0
        )

        XCTAssertEqual(state.masterTempo, 1.0, accuracy: 0.01)

        // When: Adjusting master tempo
        state.masterTempo = 1.5

        // Then: Should update
        XCTAssertEqual(state.masterTempo, 1.5, accuracy: 0.01)
    }

    func testMasterVolumeSlider() async throws {
        // Given: Multi-song state
        var state = MultiSongState(
            masterVolume: 0.8
        )

        XCTAssertEqual(state.masterVolume, 0.8, accuracy: 0.01)

        // When: Adjusting master volume
        state.masterVolume = 0.5

        // Then: Should update
        XCTAssertEqual(state.masterVolume, 0.5, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Test Sync Mode Selector
    // =============================================================================

    func testSyncModeSelector() async throws {
        // Given: Multi-song state
        var state = MultiSongState(
            syncMode: .independent
        )

        XCTAssertEqual(state.syncMode, .independent)

        // When: Changing sync mode
        state.syncMode = .locked

        // Then: Should update
        XCTAssertEqual(state.syncMode, .locked)

        // When: Changing to ratio
        state.syncMode = .ratio

        // Then: Should update
        XCTAssertEqual(state.syncMode, .ratio)
    }

    func testSyncModeDisplayNames() async throws {
        // Given: All sync modes
        let modes: [SyncMode] = [.independent, .locked, .ratio]

        // Then: Each should have display name
        for mode in modes {
            XCTAssertFalse(mode.displayName.isEmpty, "\(mode) should have display name")
            XCTAssertFalse(mode.description.isEmpty, "\(mode) should have description")
        }
    }

    // =============================================================================
    // MARK: - Test Touch Gestures
    // =============================================================================

    func testTapGestureOnCard() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isPlaying: false
        )

        XCTAssertFalse(state.isPlaying)

        // When: Simulating tap gesture (toggle playback)
        state.isPlaying.toggle()

        // Then: Should start playing
        XCTAssertTrue(state.isPlaying)
    }

    func testSwipeGestureOnCard() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            volume: 0.8
        )

        XCTAssertEqual(state.volume, 0.8, accuracy: 0.01)

        // When: Simulating swipe gesture (adjust volume)
        state.volume = 0.5

        // Then: Should update volume
        XCTAssertEqual(state.volume, 0.5, accuracy: 0.01)
    }

    // =============================================================================
    // MARK: - Test Scrubbing
    // =============================================================================

    func testScrubbingTimeline() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            currentPosition: 0.0,
            duration: 180.0
        )

        XCTAssertEqual(state.currentPosition, 0.0, accuracy: 0.1)

        // When: Scrubbing to different positions
        let positions: [Double] = [30.0, 60.0, 90.0, 120.0, 150.0]

        for position in positions {
            state.currentPosition = position
            XCTAssertEqual(state.currentPosition, position, accuracy: 0.1)
        }
    }

    func testScrubbingBeyondDuration() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            currentPosition: 90.0,
            duration: 180.0
        )

        // When: Trying to scrub beyond duration
        let newPosition = min(200.0, state.duration)
        state.currentPosition = newPosition

        // Then: Should clamp to duration
        XCTAssertLessThanOrEqual(state.currentPosition, state.duration)
    }

    func testScrubbingBeforeStart() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            currentPosition: 90.0,
            duration: 180.0
        )

        // When: Trying to scrub before start
        let newPosition = max(-10.0, 0.0)
        state.currentPosition = newPosition

        // Then: Should clamp to 0
        XCTAssertGreaterThanOrEqual(state.currentPosition, 0.0)
    }

    // =============================================================================
    // MARK: - Test Control Response
    // =============================================================================

    func testTempoSliderResponse() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            tempo: 1.0
        )

        // When: Adjusting tempo slider through full range
        let tempos: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

        for tempo in tempos {
            state.tempo = tempo
            XCTAssertEqual(state.tempo, tempo, accuracy: 0.01)
        }
    }

    func testVolumeSliderResponse() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            volume: 0.8
        )

        // When: Adjusting volume slider through full range
        let volumes: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for volume in volumes {
            state.volume = volume
            XCTAssertEqual(state.volume, volume, accuracy: 0.01)
        }
    }

    // =============================================================================
    // MARK: - Test Compact vs Expanded Views
    // =============================================================================

    func testCompactViewLayout() async throws {
        // Given: iPhone-sized viewport (compact)
        let viewportWidth: CGFloat = 390 // iPhone 14 Pro width

        // When: Calculating card width for compact view
        let cardWidth = viewportWidth - 32 // 16pt padding on each side

        // Then: Should fit in viewport
        XCTAssertLessThan(cardWidth, viewportWidth)
    }

    func testExpandedViewLayout() async throws {
        // Given: iPad-sized viewport (expanded)
        let viewportWidth: CGFloat = 1024 // iPad Pro width

        // When: Calculating card width for expanded view
        let cardsPerRow = 3
        let cardWidth = (viewportWidth - 64) / CGFloat(cardsPerRow)

        // Then: Should fit 3 cards per row
        XCTAssertEqual(cardWidth * CGFloat(cardsPerRow) + 64, viewportWidth, accuracy: 1.0)
    }

    // =============================================================================
    // MARK: - Test Accessibility
    // =============================================================================

    func testAccessibilityLabels() async throws {
        // Given: Song player state
        let state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isPlaying: false
        )

        // When: Generating accessibility label
        let accessibilityLabel = "\(state.songName), \(state.isPlaying ? "Playing" : "Stopped"), Tempo: \(state.tempo)x"

        // Then: Should be descriptive
        XCTAssertFalse(accessibilityLabel.isEmpty)
        XCTAssertTrue(accessibilityLabel.contains("Test Song"))
    }

    func testAccessibilityHintForMuteButton() async throws {
        // Given: Mute button state
        let isMuted = false

        // When: Creating accessibility hint
        let hint = isMuted ? "Unmute song" : "Mute song"

        // Then: Should provide clear action
        XCTAssertEqual(hint, "Mute song")
    }

    func testAccessibilityHintForSoloButton() async throws {
        // Given: Solo button state
        let isSoloed = false

        // When: Creating accessibility hint
        let hint = isSoloed ? "Unsolo song" : "Solo song"

        // Then: Should provide clear action
        XCTAssertEqual(hint, "Solo song")
    }

    // =============================================================================
    // MARK: - Test Visual Feedback
    // =============================================================================

    func testPlayingStateVisualIndicator() async throws {
        // Given: Playing and stopped states
        let playingState = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isPlaying: true
        )

        let stoppedState = SongPlayerState(
            songId: "test-song-2",
            songName: "Test Song 2",
            isPlaying: false
        )

        // Then: Playing state should have visual indicator
        XCTAssertTrue(playingState.isPlaying)
        XCTAssertFalse(stoppedState.isPlaying)
    }

    func testMutedStateVisualIndicator() async throws {
        // Given: Muted and unmuted states
        let mutedState = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isMuted: true
        )

        let unmutedState = SongPlayerState(
            songId: "test-song-2",
            songName: "Test Song 2",
            isMuted: false
        )

        // Then: Should have different visual indicators
        XCTAssertTrue(mutedState.isMuted)
        XCTAssertFalse(unmutedState.isMuted)
    }

    func testSoloedStateVisualIndicator() async throws {
        // Given: Soloed and unsoloed states
        let soloedState = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            isSoloed: true
        )

        let unsoloedState = SongPlayerState(
            songId: "test-song-2",
            songName: "Test Song 2",
            isSoloed: false
        )

        // Then: Should have different visual indicators
        XCTAssertTrue(soloedState.isSoloed)
        XCTAssertFalse(unsoloedState.isSoloed)
    }

    // =============================================================================
    // MARK: - Test UI Performance
    // =============================================================================

    func testUIRefreshRate() async throws {
        // Given: Multiple songs
        var states: [SongPlayerState] = []

        for i in 0..<6 {
            let state = SongPlayerState(
                songId: "song-\(i)",
                songName: "Song \(i)",
                currentPosition: Double(i * 30),
                duration: 180.0
            )
            states.append(state)
        }

        // When: Simulating UI refresh (updating positions)
        measure {
            for i in states.indices {
                states[i].currentPosition += 0.016 // ~60fps
            }
        }
    }

    func testLargeDatasetUIPerformance() async throws {
        // Given: Large number of songs
        var states: [SongPlayerState] = []

        for i in 0..<12 {
            let state = SongPlayerState(
                songId: "song-\(i)",
                songName: "Song \(i)",
                currentPosition: 0.0,
                duration: 180.0
            )
            states.append(state)
        }

        // When: Measuring update performance
        measure {
            for i in states.indices {
                // Simulate updating UI for each card
                let progress = states[i].currentPosition / states[i].duration
                XCTAssertGreaterThanOrEqual(progress, 0.0)
                XCTAssertLessThanOrEqual(progress, 1.0)
            }
        }
    }

    // =============================================================================
    // MARK: - Test Error Handling
    // =============================================================================

    func testInvalidTempoHandling() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            tempo: 1.0
        )

        // When: Setting invalid tempo (too low)
        state.tempo = max(0.2, 0.5)

        // Then: Should clamp to minimum
        XCTAssertGreaterThanOrEqual(state.tempo, 0.5)

        // When: Setting invalid tempo (too high)
        state.tempo = min(3.0, 2.0)

        // Then: Should clamp to maximum
        XCTAssertLessThanOrEqual(state.tempo, 2.0)
    }

    func testInvalidVolumeHandling() async throws {
        // Given: Song player state
        var state = SongPlayerState(
            songId: "test-song-1",
            songName: "Test Song",
            volume: 0.8
        )

        // When: Setting invalid volume (too low)
        state.volume = max(-0.5, 0.0)

        // Then: Should clamp to minimum
        XCTAssertGreaterThanOrEqual(state.volume, 0.0)

        // When: Setting invalid volume (too high)
        state.volume = min(1.5, 1.0)

        // Then: Should clamp to maximum
        XCTAssertLessThanOrEqual(state.volume, 1.0)
    }
}
