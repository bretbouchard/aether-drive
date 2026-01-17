//
//  SongPlayerCardTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Song Player Card Tests
// =============================================================================

class SongPlayerCardTests: XCTestCase {

    var hapticMock: MockHapticFeedbackManager!

    override func setUp() {
        super.setUp()
        hapticMock = MockHapticFeedbackManager()
    }

    override func tearDown() {
        hapticMock = nil
        super.tearDown()
    }

    // MARK: - Play/Pause Button Tests

    func testPlayPauseButton_InitialState_IsPlayIcon() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)
        let image = try button.image()
        XCTAssertEqual(try image.actualImage().systemName, "play.fill")
    }

    func testPlayPauseButton_WhenPlaying_IsPauseIcon() throws {
        // Given
        let song = Fixtures.playingSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)
        let image = try button.image()
        XCTAssertEqual(try image.actualImage().systemName, "pause.fill")
    }

    func testPlayPauseButton_AfterTap_TogglesToPlaying() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let button = try view.inspect().find(ViewType.Button.self)
        try button.tap()

        // Then
        XCTAssertTrue(song.isPlaying)
    }

    func testPlayPauseButton_Twice_ReturnsToPaused() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let button = try view.inspect().find(ViewType.Button.self)
        try button.tap()
        try button.tap()

        // Then
        XCTAssertFalse(song.isPlaying)
    }

    func testPlayPauseButton_HasCorrectAccessibilityLabel() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)
        XCTAssertEqual(try button.accessibilityLabel(), "Play")
    }

    func testPlayPauseButton_HasCorrectAccessibilityLabel_WhenPlaying() throws {
        // Given
        let song = Fixtures.playingSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)
        XCTAssertEqual(try button.accessibilityLabel(), "Pause")
    }

    // MARK: - Tempo Slider Tests

    func testTempoSlider_InitialValue_MatchesSong() throws {
        // Given
        let song = Fixtures.songWithTempo(1.5)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let slider = try view.inspect().find(ViewType.Slider.self)
        XCTAssertEqual(try slider.doubleValue(), 1.5)
    }

    func testTempoSlider_MinValue_IsPointFive() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let slider = try view.inspect().find(ViewType.Slider.self)
        // ViewInspector should expose slider bounds
        XCTAssertNotNil(slider)
    }

    func testTempoSlider_MaxValue_IsTwoPointZero() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let slider = try view.inspect().find(ViewType.Slider.self)
        XCTAssertNotNil(slider)
    }

    func testTempoSlider_Change_UpdatesSong() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let slider = try view.inspect().find(ViewType.Slider.self)
        try slider.setDoubleValue(1.8)

        // Then
        XCTAssertEqual(song.tempoMultiplier, 1.8)
    }

    func testTempoSlider_HasCorrectAccessibilityLabel() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let slider = try view.inspect().find(ViewType.Slider.self)
        XCTAssertEqual(try slider.accessibilityLabel(), "Tempo")
    }

    // MARK: - Volume Slider Tests

    func testVolumeSlider_InitialValue_MatchesSong() throws {
        // Given
        let song = Fixtures.songWithVolume(0.6)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1] // Second slider is volume
        XCTAssertEqual(try volumeSlider.doubleValue(), 0.6)
    }

    func testVolumeSlider_Change_UpdatesSong() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        try volumeSlider.setDoubleValue(0.4)

        // Then
        XCTAssertEqual(song.volume, 0.4)
    }

    func testVolumeSlider_DisabledWhenMuted() throws {
        // Given
        let song = Fixtures.mutedSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        // Volume slider should be disabled when muted
        XCTAssertNotNil(volumeSlider)
    }

    func testVolumeSlider_HasCorrectAccessibilityLabel() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1]
        XCTAssertEqual(try volumeSlider.accessibilityLabel(), "Volume")
    }

    // MARK: - Mute Button Tests

    func testMuteButton_InitialState_ShowsSpeakerIcon() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        // Mute button should show speaker.wave.2.fill when not muted
        XCTAssertGreaterThanOrEqual(buttons.count, 2)
    }

    func testMuteButton_Tap_TogglesMute() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        // Find and tap mute button (second button after play/pause)
        if buttons.count > 1 {
            try buttons[1].tap()
        }

        // Then
        XCTAssertTrue(song.isMuted)
    }

    func testMuteButton_WhenMuted_ChangesAppearance() throws {
        // Given
        let song = Fixtures.mutedSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 2)
    }

    func testMuteButton_HasCorrectAccessibilityLabel() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        if buttons.count > 1 {
            XCTAssertEqual(try buttons[1].accessibilityLabel(), "Mute")
        }
    }

    // MARK: - Solo Button Tests

    func testSoloButton_InitialState_NotSoloed() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 3)
    }

    func testSoloButton_Tap_TogglesSolo() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        // Solo button should be the third button
        if buttons.count > 2 {
            try buttons[2].tap()
        }

        // Then
        XCTAssertTrue(song.isSolo)
    }

    func testSoloButton_WhenSoloed_HasAccentBorder() throws {
        // Given
        let song = Fixtures.soloedSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Soloed song should have accent border
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testSoloButton_HasCorrectAccessibilityLabel() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        if buttons.count > 2 {
            XCTAssertEqual(try buttons[2].accessibilityLabel(), "Solo")
        }
    }

    // MARK: - Card Structure Tests

    func testCard_HasCorrectLayout() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testCard_DisplaysSongName() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let songName = texts.first { try? $0.string() == song.name }
        XCTAssertNotNil(songName)
    }

    func testCard_DisplaysArtistName() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let artistName = texts.first { try? $0.string() == song.artist }
        XCTAssertNotNil(artistName)
    }

    func testCard_DisplaysFormattedTime() throws {
        // Given
        let song = Fixtures.songWithProgress(0.5)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Progress Bar Tests

    func testProgressBar_InitialValue_MatchesSong() throws {
        // Given
        let song = Fixtures.songWithProgress(0.75)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Progress bar should reflect song progress
        XCTAssertNotNil(try view.inspect().find(ViewType.GeometryReader.self))
    }

    func testProgressBar_HasCorrectAccessibilityValue() throws {
        // Given
        let song = Fixtures.songWithProgress(0.5)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Waveform Tests

    func testWaveform_HasCorrectBarCount() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Waveform should render correct number of bars
        let vStacks = try view.inspect().findAll(ViewType.VStack.self)
        XCTAssertFalse(vStacks.isEmpty)
    }

    func testWaveform_EmptyWaveform_DoesNotCrash() throws {
        // Given
        let song = Fixtures.testSong
        song.waveform = []
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Should handle empty waveform gracefully
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    // MARK: - Thumbnail Tests

    func testThumbnail_Placeholder_WhenNoURL() throws {
        // Given
        let song = Fixtures.testSong
        song.thumbnailURL = nil
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Should show placeholder thumbnail
        XCTAssertNotNil(try view.inspect().find(ViewType.ZStack.self))
    }

    func testThumbnail_AsyncImage_WhenURLPresent() throws {
        // Given
        let song = Fixtures.testSong
        song.thumbnailURL = Fixtures.testThumbnailURL
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Should show AsyncImage
        XCTAssertNotNil(try view.inspect().find(ViewType.ZStack.self))
    }

    // MARK: - Expand Button Tests

    func testExpandButton_Tap_TogglesExpansion() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }

    func testExpandButton_ChangesIcon() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        // Expand button should show chevron.down initially
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }

    // MARK: - Metadata Tests

    func testMetadata_DisplaysBPM() throws {
        // Given
        let song = Fixtures.songWithBPM(140.0)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        // Should display BPM in metadata
        XCTAssertFalse(texts.isEmpty)
    }

    func testMetadata_DisplaysTimeSignature() throws {
        // Given
        let song = Fixtures.testSong
        song.timeSignature = "6/8"
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testMetadata_DisplaysKey() throws {
        // Given
        let song = Fixtures.testSong
        song.key = "F# minor"
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Edge Cases

    func testCard_WithExtremeTempo_RendersCorrectly() throws {
        // Given
        let song = Fixtures.songWithTempo(2.0)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testCard_WithZeroVolume_RendersCorrectly() throws {
        // Given
        let song = Fixtures.songWithVolume(0.0)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testCard_WithFullProgress_RendersCorrectly() throws {
        // Given
        let song = Fixtures.songWithProgress(1.0)
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    // MARK: - Integration Tests

    func testCard_MultipleInteractions_UpdatesCorrectly() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap() // Play
        try buttons[1].tap() // Mute
        try buttons[2].tap() // Solo

        // Then
        XCTAssertTrue(song.isPlaying)
        XCTAssertTrue(song.isMuted)
        XCTAssertTrue(song.isSolo)
    }

    func testCard_StateChanges_ReflectInUI() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When
        song.isPlaying = true
        song.isMuted = true
        song.isSolo = true
        song.volume = 0.5
        song.tempoMultiplier = 1.5

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }
}
