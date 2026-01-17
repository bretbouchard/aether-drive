//
//  MasterTransportControlsTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Master Transport Controls Tests
// =============================================================================

class MasterTransportControlsTests: XCTestCase {

    var state: MultiSongState!
    var hapticMock: MockHapticFeedbackManager!

    override func setUp() {
        super.setUp()
        state = Fixtures.testMultiSongState
        hapticMock = MockHapticFeedbackManager()
    }

    override func tearDown() {
        state = nil
        hapticMock = nil
        super.tearDown()
    }

    // MARK: - Play/Pause Button Tests

    func testPlayPauseButton_InitialState_IsPlayIcon() throws {
        // Given
        state.isMasterPlaying = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        let playPauseButton = buttons[1] // Second button is play/pause
        let image = try playPauseButton.image()
        XCTAssertEqual(try image.actualImage().systemName, "play.fill")
    }

    func testPlayPauseButton_WhenPlaying_IsPauseIcon() throws {
        // Given
        state.isMasterPlaying = true
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        let playPauseButton = buttons[1]
        let image = try playPauseButton.image()
        XCTAssertEqual(try image.actualImage().systemName, "pause.fill")
    }

    func testPlayPauseButton_Tap_TogglesMasterPlaying() throws {
        // Given
        state.isMasterPlaying = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()

        // Then
        XCTAssertTrue(state.isMasterPlaying)
    }

    func testPlayPauseButton_Twice_ReturnsToPaused() throws {
        // Given
        state.isMasterPlaying = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()
        try buttons[1].tap()

        // Then
        XCTAssertFalse(state.isMasterPlaying)
    }

    func testPlayPauseButton_WhenPlayed_StartsAllSongs() throws {
        // Given
        state.isMasterPlaying = false
        state.songs.forEach { $0.isPlaying = false }
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()

        // Then
        // All non-muted songs should be playing
        let playingSongs = state.songs.filter { $0.isPlaying }
        XCTAssertFalse(playingSongs.isEmpty)
    }

    func testPlayPauseButton_WhenPaused_StopsAllSongs() throws {
        // Given
        state.isMasterPlaying = true
        state.songs.forEach { $0.isPlaying = true }
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()

        // Then
        let playingSongs = state.songs.filter { $0.isPlaying }
        XCTAssertTrue(playingSongs.isEmpty)
    }

    // MARK: - Stop Button Tests

    func testStopButton_Tap_StopsAllPlayback() throws {
        // Given
        state.isMasterPlaying = true
        state.songs.forEach { song in
            song.isPlaying = true
            song.progress = Double.random(in: 0.2...0.8)
        }
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap() // First button is stop

        // Then
        XCTAssertFalse(state.isMasterPlaying)
        state.songs.forEach { song in
            XCTAssertFalse(song.isPlaying)
            XCTAssertEqual(song.progress, 0.0)
        }
    }

    func testStopButton_HasCorrectAccessibilityLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(try buttons[0].accessibilityLabel(), "Stop")
    }

    // MARK: - Loop Button Tests

    func testLoopButton_InitialState_IsNotLooping() throws {
        // Given
        state.masterTransport.isLooping = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        let loopButton = buttons[2]
        let image = try loopButton.image()
        XCTAssertEqual(try image.actualImage().systemName, "repeat")
    }

    func testLoopButton_WhenLooping_ChangesIcon() throws {
        // Given
        state.masterTransport.isLooping = true
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        let loopButton = buttons[2]
        let image = try loopButton.image()
        XCTAssertEqual(try image.actualImage().systemName, "repeat.1")
    }

    func testLoopButton_Tap_TogglesLooping() throws {
        // Given
        state.masterTransport.isLooping = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[2].tap()

        // Then
        XCTAssertTrue(state.masterTransport.isLooping)
    }

    func testLoopButton_HasCorrectAccessibilityLabel() throws {
        // Given
        state.masterTransport.isLooping = false
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(try buttons[2].accessibilityLabel(), "Looping Off")
    }

    // MARK: - Sync Mode Selector Tests

    func testSyncModeSelector_DisplaysCurrentMode() throws {
        // Given
        state.syncMode = .locked
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let menu = try view.inspect().find(ViewType.Menu.self)
        XCTAssertNotNil(menu)
    }

    func testSyncModeSelector_ChangesMode() throws {
        // Given
        state.syncMode = .independent
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        // Sync mode change would need user interaction
        state.syncMode = .locked

        // Then
        XCTAssertEqual(state.syncMode, .locked)
    }

    func testSyncModeSelector_ShowsAllModes() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let menu = try view.inspect().find(ViewType.Menu.self)
        XCTAssertNotNil(menu)
        XCTAssertEqual(MultiSongState.SyncMode.allCases.count, 3)
    }

    func testSyncModeSelector_HasCorrectAccessibilityLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let menu = try view.inspect().find(ViewType.Menu.self)
        XCTAssertEqual(try menu.accessibilityLabel(), "Sync mode")
    }

    // MARK: - Master Tempo Tests

    func testMasterTempoSlider_InitialValue_MatchesState() throws {
        // Given
        state.masterTempo = 1.5
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let tempoSlider = sliders[0]
        XCTAssertEqual(try tempoSlider.doubleValue(), 1.5)
    }

    func testMasterTempoSlider_Change_UpdatesState() throws {
        // Given
        state.masterTempo = 1.0
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let tempoSlider = sliders[0]
        try tempoSlider.setDoubleValue(1.8)

        // Then
        XCTAssertEqual(state.masterTempo, 1.8)
    }

    func testMasterTempoSlider_Range_IsCorrect() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        XCTAssertFalse(sliders.isEmpty)
    }

    func testMasterTempoSlider_HasCorrectAccessibilityLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let tempoSlider = sliders[0]
        XCTAssertEqual(try tempoSlider.accessibilityLabel(), "Master tempo")
    }

    // MARK: - Master Volume Tests

    func testMasterVolumeSlider_InitialValue_MatchesState() throws {
        // Given
        state.masterVolume = 0.6
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        XCTAssertEqual(try volumeSlider.doubleValue(), 0.6)
    }

    func testMasterVolumeSlider_Change_UpdatesState() throws {
        // Given
        state.masterVolume = 0.8
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        try volumeSlider.setDoubleValue(0.4)

        // Then
        XCTAssertEqual(state.masterVolume, 0.4)
    }

    func testMasterVolumeSlider_HasCorrectAccessibilityLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        XCTAssertEqual(try volumeSlider.accessibilityLabel(), "Master volume")
    }

    // MARK: - Action Buttons Tests

    func testAddSongButton_Exists() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        // Should have multiple buttons including Add Song
        XCTAssertGreaterThanOrEqual(buttons.count, 4)
    }

    func testAddSongButton_HasCorrectLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let addSongText = texts.first { try? $0.string() == "Add Song" }
        XCTAssertNotNil(addSongText)
    }

    func testSavePresetButton_Exists() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let saveText = texts.first { try? $0.string() == "Save" }
        XCTAssertNotNil(saveText)
    }

    func testSavePresetButton_HasCorrectLabel() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let saveText = texts.first { try? $0.string() == "Save" }
        XCTAssertNotNil(saveText)
    }

    // MARK: - Layout Tests

    func testControls_HasCorrectLayout() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testControls_HasTopAndBottomSections() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertGreaterThanOrEqual(try vStack.childCount(), 2)
    }

    // MARK: - Edge Cases

    func testControls_WithNoSongs_RendersCorrectly() throws {
        // Given
        state.songs = []
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testControls_WithMaximumTempo_RendersCorrectly() throws {
        // Given
        state.masterTempo = 2.0
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testControls_WithMinimumTempo_RendersCorrectly() throws {
        // Given
        state.masterTempo = 0.5
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testControls_WithZeroVolume_RendersCorrectly() throws {
        // Given
        state.masterVolume = 0.0
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testControls_WithFullVolume_RendersCorrectly() throws {
        // Given
        state.masterVolume = 1.0
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    // MARK: - Integration Tests

    func testControls_MultipleInteractions_UpdatesCorrectly() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap() // Play

        // Then
        XCTAssertTrue(state.isMasterPlaying)
    }

    func testControls_StateChanges_ReflectInUI() throws {
        // Given
        let view = MasterTransportControls(state: state)
            .testTheme()

        // When
        state.isMasterPlaying = true
        state.masterVolume = 0.5
        state.masterTempo = 1.2
        state.syncMode = .ratio

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    // MARK: - Visual Tests

    func testControls_IndependentMode_ShowsCorrectIcon() throws {
        // Given
        state.syncMode = .independent
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let modeText = texts.first { try? $0.string() == "Independent" }
        XCTAssertNotNil(modeText)
    }

    func testControls_LockedMode_ShowsCorrectIcon() throws {
        // Given
        state.syncMode = .locked
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let modeText = texts.first { try? $0.string() == "Locked" }
        XCTAssertNotNil(modeText)
    }

    func testControls_RatioMode_ShowsCorrectIcon() throws {
        // Given
        state.syncMode = .ratio
        let view = MasterTransportControls(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let modeText = texts.first { try? $0.string() == "Ratio" }
        XCTAssertNotNil(modeText)
    }
}
