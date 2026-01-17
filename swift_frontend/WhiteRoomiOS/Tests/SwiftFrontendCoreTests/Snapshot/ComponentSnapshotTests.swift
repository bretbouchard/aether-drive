//
//  ComponentSnapshotTests.swift
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
 Snapshot tests for individual UI components across different states.

 Tests cover:
 - Song player card states (playing, paused, muted, soloed)
 - Transport control configurations
 - Progress view variations
 - Component edge cases
 */
class ComponentSnapshotTests: XCTestCase {

    // MARK: - Configuration

    let isRecording = false

    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    // MARK: - Song Player Card States

    func testSongPlayerCard_StatePlaying() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.isPlaying = true
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_playing"
        )
    }

    func testSongPlayerCard_StatePaused() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.isPlaying = false
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_paused"
        )
    }

    func testSongPlayerCard_StateMuted() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.isMuted = true
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_muted"
        )
    }

    func testSongPlayerCard_StateSoloed() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.isSoloed = true
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_soloed"
        )
    }

    func testSongPlayerCard_StateMutedAndSoloed() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.isMuted = true
        slot.isSoloed = true
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_muted_soloed"
        )
    }

    func testSongPlayerCard_StateLooping() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.loopEnabled = true
        slot.loopStart = 0.25
        slot.loopEnd = 0.75
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_looping"
        )
    }

    func testSongPlayerCard_TempoExtremes() {
        // Given
        var slot = Fixtures.testSongSlot

        // Minimum tempo
        slot.tempo = 0.5
        let viewMin = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)
        assertSnapshot(
            matching: viewMin,
            as: .image(layout: .sizeThatFits),
            named: "song_card_tempo_min"
        )

        // Maximum tempo
        slot.tempo = 2.0
        let viewMax = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)
        assertSnapshot(
            matching: viewMax,
            as: .image(layout: .sizeThatFits),
            named: "song_card_tempo_max"
        )
    }

    func testSongPlayerCard_VolumeExtremes() {
        // Given
        var slot = Fixtures.testSongSlot

        // Minimum volume
        slot.volume = 0.0
        let viewMin = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)
        assertSnapshot(
            matching: viewMin,
            as: .image(layout: .sizeThatFits),
            named: "song_card_volume_min"
        )

        // Maximum volume
        slot.volume = 1.0
        let viewMax = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)
        assertSnapshot(
            matching: viewMax,
            as: .image(layout: .sizeThatFits),
            named: "song_card_volume_max"
        )
    }

    func testSongPlayerCard_DarkMode() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .preferredColorScheme(.dark)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_dark_mode"
        )
    }

    // MARK: - Master Transport Controls

    func testMasterTransportControls_AllStopped() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 80)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_all_stopped"
        )
    }

    func testMasterTransportControls_AllPlaying() {
        // Given
        var state = Fixtures.testMultiSongState
        state.masterPlaying = true
        state.songs.forEach { $0.isPlaying = true }
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 80)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_all_playing"
        )
    }

    func testMasterTransportControls_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .preferredColorScheme(.dark)
            .frame(width: 350, height: 80)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_dark_mode"
        )
    }

    // MARK: - Parallel Progress View

    func testParallelProgressView_AllAtZero() {
        // Given
        let state = Fixtures.testMultiSongState
        state.songs.forEach { $0.currentPosition = 0.0 }
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 60)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "progress_all_zero"
        )
    }

    func testParallelProgressView_AllAtEnd() {
        // Given
        let state = Fixtures.testMultiSongState
        state.songs.forEach { $0.currentPosition = 1.0 }
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 60)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "progress_all_at_end"
        )
    }

    func testParallelProgressView_VariousPositions() {
        // Given
        var state = Fixtures.testMultiSongState
        state.songs[0].currentPosition = 0.0
        state.songs[1].currentPosition = 0.25
        state.songs[2].currentPosition = 0.5
        state.songs[3].currentPosition = 0.75
        state.songs[4].currentPosition = 1.0
        if state.songs.count > 5 {
            state.songs[5].currentPosition = 0.5
        }
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 60)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "progress_various_positions"
        )
    }

    func testParallelProgressView_DarkMode() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = ParallelProgressView(state: state)
            .environment(\.theme, Theme.default)
            .preferredColorScheme(.dark)
            .frame(width: 350, height: 60)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "progress_dark_mode"
        )
    }

    // MARK: - Waveform View

    func testMultiSongWaveformView_Basic() {
        // Given
        let waveform = Fixtures.testWaveform
        let view = MultiSongWaveformView(waveform: waveform)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 100)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "waveform_basic"
        )
    }

    func testMultiSongWaveformView_DarkMode() {
        // Given
        let waveform = Fixtures.testWaveform
        let view = MultiSongWaveformView(waveform: waveform)
            .environment(\.theme, Theme.default)
            .preferredColorScheme(.dark)
            .frame(width: 350, height: 100)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "waveform_dark_mode"
        )
    }

    // MARK: - Edge Cases

    func testSongPlayerCard_VeryLongSongName() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.songName = "This is a very long song name that should truncate properly"
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_long_name"
        )
    }

    func testSongPlayerCard_SpecialCharactersInName() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.songName = "Song \"with\" 'special' & chars"
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_special_chars"
        )
    }

    func testMasterTransportControls_EmptyState() {
        // Given
        let state = MultiSongState()
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .frame(width: 350, height: 80)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_empty"
        )
    }
}
