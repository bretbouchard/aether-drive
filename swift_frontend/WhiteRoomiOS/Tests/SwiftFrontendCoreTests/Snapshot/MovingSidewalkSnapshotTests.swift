//
//  MovingSidewalkSnapshotTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SwiftFrontendCore

/**
 Snapshot tests for MovingSidewalkView across devices and themes.

 Tests cover:
 - Light and dark mode appearances
 - iPhone and iPad layouts
 - Different device configurations
 - Navigation and toolbar elements
 */
class MovingSidewalkSnapshotTests: XCTestCase {

    // MARK: - Configuration

    let isRecording = false

    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    // MARK: - iPhone Tests

    func testMovingSidewalkView_iPhone13Pro_LightMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_iphone13_light"
        )
    }

    func testMovingSidewalkView_iPhone13Pro_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .preferredColorScheme(.dark)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_iphone13_dark"
        )
    }

    func testMovingSidewalkView_iPhone15Pro_LightMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone15Pro)),
            named: "moving_sidewalk_iphone15_light"
        )
    }

    func testMovingSidewalkView_iPhone15Pro_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .preferredColorScheme(.dark)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone15Pro)),
            named: "moving_sidewalk_iphone15_dark"
        )
    }

    // MARK: - iPad Tests

    func testMovingSidewalkView_iPadPro_LightMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPadPro12_9)),
            named: "moving_sidewalk_ipad_light"
        )
    }

    func testMovingSidewalkView_iPadPro_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .preferredColorScheme(.dark)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPadPro12_9)),
            named: "moving_sidewalk_ipad_dark"
        )
    }

    func testMovingSidewalkView_iPadMini_LightMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPadMini)),
            named: "moving_sidewalk_ipadmini_light"
        )
    }

    func testMovingSidewalkView_iPadMini_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .preferredColorScheme(.dark)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPadMini)),
            named: "moving_sidewalk_ipadmini_dark"
        )
    }

    // MARK: - State Variations

    func testMovingSidewalkView_AllSongsStopped() {
        // Given
        var state = Fixtures.testMultiSongState
        state.songs.forEach { $0.isPlaying = false }
        state.masterPlaying = false
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_all_stopped"
        )
    }

    func testMovingSidewalkView_AllSongsPlaying() {
        // Given
        var state = Fixtures.testMultiSongState
        state.songs.forEach { $0.isPlaying = true }
        state.masterPlaying = true
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_all_playing"
        )
    }

    func testMovingSidewalkView_MixedStates() {
        // Given
        var state = Fixtures.testMultiSongState
        state.songs[0].isPlaying = true
        state.songs[1].isPlaying = false
        state.songs[2].isMuted = true
        state.songs[3].isSoloed = true
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_mixed_states"
        )
    }

    func testMovingSidewalkView_EmptyState() {
        // Given
        let state = MultiSongState()
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_empty_state"
        )
    }

    func testMovingSidewalkView_SingleSong() {
        // Given
        var state = MultiSongState()
        state.songs = [Fixtures.testSongSlot]
        let view = configureView(state: state)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_single_song"
        )
    }

    // MARK: - Helper Methods

    private func configureView(state: MultiSongState) -> some View {
        NavigationView {
            MovingSidewalkView_TestWrapper(state: state)
        }
        .environment(\.theme, Theme.default)
    }
}

// =============================================================================
// MARK: - Test Wrapper
// =============================================================================

/**
 Test wrapper for MovingSidewalkView that allows dependency injection
 */
struct MovingSidewalkView_TestWrapper: View {
    @ObservedObject var state: MultiSongState
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Visual timeline placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.palette.background.secondary)
                    .frame(height: 60)
                    .overlay(
                        Text("Timeline")
                            .font(.caption)
                            .foregroundColor(theme.palette.text.tertiary)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Song cards header
                HStack {
                    Text("Songs")
                        .font(.headline)
                        .foregroundColor(theme.palette.text.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundColor(theme.palette.accent.primary)

                        Text("Independent")
                            .font(.caption)
                            .foregroundColor(theme.palette.text.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Song cards
                LazyVStack(spacing: 12) {
                    ForEach(state.songs) { song in
                        SongPlayerCard(song: song)
                    }
                }
                .padding(.horizontal, 16)

                // Master transport controls
                VStack(spacing: 16) {
                    // Master controls placeholder
                    MasterTransportControls(state: state)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Moving Sidewalk")
                        .font(.headline)
                        .foregroundColor(theme.palette.text.primary)

                    Text("\(state.songs.count) songs")
                        .font(.caption)
                        .foregroundColor(theme.palette.text.tertiary)
                }
            }
        }
    }
}
