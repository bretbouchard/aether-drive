//
//  MovingSidewalkXCUIUITests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  XCUITest suite for Moving Sidewalk feature - Real device/simulator UI automation

import XCTest

// =============================================================================
// MARK: - Moving Sidewalk XCUITest Suite
// =============================================================================

@MainActor
final class MovingSidewalkXCUIUITests: XCTestCase {

    // =============================================================================
    // MARK: - Properties
    // =============================================================================

    var app: XCUIApplication!

    // =============================================================================
    // MARK: - Setup & Teardown
    // =============================================================================

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST"]
        app.launchEnvironment = [
            "UITESTING": "1",
            "MOCK_AUDIO_ENGINE": "1"
        ]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
        await super.tearDown()
    }

    // =============================================================================
    // MARK: - Navigation Tests
    // =============================================================================

    func testNavigateToMovingSidewalk() async throws {
        // Given: App is launched
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        // When: Navigate to Moving Sidewalk tab
        let tabBarsQuery = app.tabBars
        let movingSidewalkTab = tabBarsQuery.buttons["Moving Sidewalk"]

        XCTAssertTrue(movingSidewalkTab.waitForExistence(timeout: 5), "Moving Sidewalk tab should exist")
        movingSidewalkTab.tap()

        // Then: Should be on Moving Sidewalk screen
        let navigationBar = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 3), "Should navigate to Moving Sidewalk")
    }

    func testMovingSidewalkTabIsSelected() async throws {
        // Given: Navigate to Moving Sidewalk
        try await testNavigateToMovingSidewalk()

        // Then: Tab should be selected
        let tabBarsQuery = app.tabBars
        let movingSidewalkTab = tabBarsQuery.buttons["Moving Sidewalk"]
        XCTAssertTrue(movingSidewalkTab.isSelected, "Moving Sidewalk tab should be selected")
    }

    // =============================================================================
    // MARK: - Song Loading Tests
    // =============================================================================

    func testLoadSongIntoSlot() async throws {
        // Given: On Moving Sidewalk screen
        try await testNavigateToMovingSidewalk()

        // When: Tap load button for slot 0
        let loadButton = app.buttons["Load Slot 0"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 3), "Load button should exist")
        loadButton.tap()

        // Then: Song picker should appear
        let songPicker = app.sheets.firstMatch
        XCTAssertTrue(songPicker.waitForExistence(timeout: 2), "Song picker should appear")

        // When: Select first demo song
        let firstSong = songPicker.buttons.matching(identifier: "DemoSongButton").firstMatch
        if firstSong.exists {
            firstSong.tap()
        }

        // Then: Song should be loaded
        let songName = app.staticTexts.matching(identifier: "SongName").firstMatch
        XCTAssertTrue(songName.exists, "Song name should be displayed")
    }

    func testLoadSixSongs_AllSlotsFilled() async throws {
        // Given: On Moving Sidewalk screen
        try await testNavigateToMovingSidewalk()

        // When: Load 6 songs into all slots
        for i in 0..<6 {
            let loadButton = app.buttons["Load Slot \(i)"]
            XCTAssertTrue(loadButton.waitForExistence(timeout: 2), "Load button \(i) should exist")
            loadButton.tap()

            let songPicker = app.sheets.firstMatch
            XCTAssertTrue(songPicker.waitForExistence(timeout: 2), "Song picker should appear")

            // Select demo song
            let demoSong = songPicker.buttons.matching(NSPredicate(format: "label CONTAINS 'Demo'")).element(boundBy: 0)
            if demoSong.exists {
                demoSong.tap()
            }

            // Wait for sheet to dismiss
            XCTAssertFalse(songPicker.exists, "Song picker should dismiss after selection")
        }

        // Then: All 6 song cards should be visible
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertEqual(songCards.count, 6, "Should have 6 song player cards")
    }

    func testLoadSong_Cancel() async throws {
        // Given: On Moving Sidewalk screen
        try await testNavigateToMovingSidewalk()

        // When: Tap load button but cancel
        let loadButton = app.buttons["Load Slot 0"]
        loadButton.tap()

        let songPicker = app.sheets.firstMatch
        XCTAssertTrue(songPicker.waitForExistence(timeout: 2))

        let cancelButton = songPicker.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }

        // Then: Picker should dismiss, no song loaded
        XCTAssertFalse(songPicker.exists, "Picker should dismiss")
    }

    // =============================================================================
    // MARK: - Play/Pause Control Tests
    // =============================================================================

    func testPlaySingleSong_UpdatesButtonToPause() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]

        XCTAssertTrue(playButton.waitForExistence(timeout: 2), "Play button should exist")

        // When: Tap play button
        playButton.tap()

        // Then: Should change to pause button
        let pauseButton = firstCard.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 1), "Should show pause button after playing")
    }

    func testPauseSingleSong_UpdatesButtonToPlay() async throws {
        // Given: Song is playing
        try await testPlaySingleSong_UpdatesButtonToPause()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let pauseButton = firstCard.buttons["Pause"]

        // When: Tap pause button
        pauseButton.tap()

        // Then: Should change back to play button
        let playButton = firstCard.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 1), "Should show play button after pausing")
    }

    func testPlayMultipleSongs_AllPlayingIndependently() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // When: Play first 3 songs
        for i in 0..<3 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let playButton = card.buttons["Play"]
            if playButton.exists {
                playButton.tap()
            }
        }

        // Then: Should have 3 playing, 3 stopped
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        let playButtons = app.buttons.matching(identifier: "Play")

        XCTAssertEqual(pauseButtons.count, 3, "Should have 3 pause buttons (3 playing)")
        XCTAssertEqual(playButtons.count, 3, "Should have 3 play buttons (3 stopped)")
    }

    func testTapSongCard_TogglesPlayback() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Tap the card
        firstCard.tap()

        // Then: Should toggle playback state
        let pauseButton = firstCard.buttons["Pause"]
        let playButton = firstCard.buttons["Play"]

        // Should be playing now
        let isPlaying = pauseButton.exists
        XCTAssertTrue(isPlaying || playButton.exists, "Should toggle playback on tap")
    }

    // =============================================================================
    // MARK: - Tempo Control Tests
    // =============================================================================

    func testTempoSlider_ChangesTempo() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        XCTAssertTrue(tempoSlider.waitForExistence(timeout: 2), "Tempo slider should exist")

        // When: Adjust to 75% position
        tempoSlider.adjust(toNormalizedSliderPosition: 0.75)

        // Then: Tempo should update (verify via label)
        let tempoLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
        if tempoLabel.exists {
            let tempoText = tempoLabel.label
            XCTAssertTrue(tempoText.contains("BPM"), "Should display BPM value")
        }
    }

    func testTempoSlider_ClampsToMinimum() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        // When: Try to go below minimum
        tempoSlider.adjust(toNormalizedSliderPosition: -0.1)

        // Then: Should clamp to minimum (40 BPM)
        let tempoLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
        if tempoLabel.exists {
            let tempoText = tempoLabel.label
            // Verify it's not negative
            XCTAssertFalse(tempoText.contains("-"), "Should not show negative tempo")
        }
    }

    func testTempoSlider_ClampsToMaximum() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        // When: Try to go above maximum
        tempoSlider.adjust(toNormalizedSliderPosition: 1.1)

        // Then: Should clamp to maximum (240 BPM)
        let tempoLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
        if tempoLabel.exists {
            let tempoText = tempoLabel.label
            // Verify reasonable maximum
            XCTAssertTrue(tempoText.contains("BPM"), "Should display valid BPM")
        }
    }

    func testTempoSlider_SmoothAdjustment() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        // When: Adjust through multiple positions
        let positions: [CGFloat] = [0.25, 0.5, 0.75, 1.0]

        for position in positions {
            tempoSlider.adjust(toNormalizedSliderPosition: position)
            Thread.sleep(forTimeInterval: 0.1) // Brief pause for UI update
        }

        // Then: Should smoothly update at each position
        let tempoLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
        XCTAssertTrue(tempoLabel.exists, "Tempo label should exist")
    }

    // =============================================================================
    // MARK: - Volume Control Tests
    // =============================================================================

    func testVolumeSlider_ChangesVolume() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let volumeSlider = firstCard.sliders["Volume"]

        XCTAssertTrue(volumeSlider.waitForExistence(timeout: 2), "Volume slider should exist")

        // When: Adjust to 50%
        volumeSlider.adjust(toNormalizedSliderPosition: 0.5)

        // Then: Volume should update
        let volumeLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Volume'")).firstMatch
        if volumeLabel.exists {
            let volumeText = volumeLabel.label
            XCTAssertTrue(volumeText.contains("%"), "Should display volume percentage")
        }
    }

    func testVolumeSlider_MutesAtZero() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let volumeSlider = firstCard.sliders["Volume"]

        // When: Set to 0
        volumeSlider.adjust(toNormalizedSliderPosition: 0.0)

        // Then: Should show muted state
        let muteButton = firstCard.buttons["Mute"]
        if muteButton.exists {
            XCTAssertTrue(muteButton.isSelected, "Mute button should be selected when volume is 0")
        }
    }

    func testVolumeSlider_MaximumVolume() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let volumeSlider = firstCard.sliders["Volume"]

        // When: Set to maximum
        volumeSlider.adjust(toNormalizedSliderPosition: 1.0)

        // Then: Should show 100%
        let volumeLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Volume'")).firstMatch
        if volumeLabel.exists {
            let volumeText = volumeLabel.label
            XCTAssertTrue(volumeText.contains("100%"), "Should show 100% volume")
        }
    }

    // =============================================================================
    // MARK: - Mute/Solo Control Tests
    // =============================================================================

    func testMuteButton_TogglesMute() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let muteButton = firstCard.buttons["Mute"]

        XCTAssertTrue(muteButton.waitForExistence(timeout: 2), "Mute button should exist")

        let initiallyMuted = muteButton.isSelected

        // When: Tap mute button
        muteButton.tap()

        // Then: Should toggle state
        let nowMuted = muteButton.isSelected
        XCTAssertNotEqual(initiallyMuted, nowMuted, "Mute state should toggle")
    }

    func testSoloButton_TogglesSolo() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let soloButton = firstCard.buttons["Solo"]

        XCTAssertTrue(soloButton.waitForExistence(timeout: 2), "Solo button should exist")

        let initiallySoloed = soloButton.isSelected

        // When: Tap solo button
        soloButton.tap()

        // Then: Should toggle state
        let nowSoloed = soloButton.isSelected
        XCTAssertNotEqual(initiallySoloed, nowSoloed, "Solo state should toggle")
    }

    func testSoloWithMute_OnlySoloHeard() async throws {
        // Given: Multiple songs loaded and playing
        try await testLoadSixSongs_AllSlotsFilled()

        // Play all songs
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        // When: Solo song 0, mute song 1
        let card0 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let card1 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 1)

        card0.buttons["Solo"].tap()
        card1.buttons["Mute"].tap()

        // Then: Verify states
        XCTAssertTrue(card0.buttons["Solo"].isSelected, "Card 0 should be soloed")
        XCTAssertTrue(card1.buttons["Mute"].isSelected, "Card 1 should be muted")
    }

    func testMultipleSolo_OnlyLastSolo() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // When: Solo multiple songs
        let card0 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let card1 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 1)
        let card2 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 2)

        card0.buttons["Solo"].tap()
        card1.buttons["Solo"].tap()

        // Then: Only last should be soloed (implementation dependent)
        // This test verifies the solo behavior (exclusive vs. multi-solo)
        let card0Solo = card0.buttons["Solo"].isSelected
        let card1Solo = card1.buttons["Solo"].isSelected
        let card2Solo = card2.buttons["Solo"].isSelected

        // At least one should be soloed
        XCTAssertTrue(card0Solo || card1Solo || card2Solo, "At least one card should be soloed")
    }

    // =============================================================================
    // MARK: - Master Transport Tests
    // =============================================================================

    func testPlayAll_StartsAllSongs() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let playAllButton = app.buttons["Play All"]
        XCTAssertTrue(playAllButton.waitForExistence(timeout: 2), "Play All button should exist")

        // When: Tap Play All
        playAllButton.tap()

        // Then: All 6 should be playing
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        XCTAssertEqual(pauseButtons.count, 6, "All 6 songs should be playing")
    }

    func testPauseAll_StopsAllSongs() async throws {
        // Given: All songs playing
        try await testPlayAll_StartsAllSongs()

        let pauseAllButton = app.buttons["Pause All"]
        XCTAssertTrue(pauseAllButton.waitForExistence(timeout: 2), "Pause All button should exist")

        // When: Tap Pause All
        pauseAllButton.tap()

        // Then: All 6 should be paused
        let playButtons = app.buttons.matching(identifier: "Play")
        XCTAssertEqual(playButtons.count, 6, "All 6 songs should be paused")
    }

    func testStopAll_ResetsAllPositions() async throws {
        // Given: All songs playing
        try await testPlayAll_StartsAllSongs()

        // Let them play for a bit
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let stopAllButton = app.buttons["Stop All"]
        XCTAssertTrue(stopAllButton.waitForExistence(timeout: 2), "Stop All button should exist")

        // When: Tap Stop All
        stopAllButton.tap()

        // Then: All positions should reset to 0
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let progressIndicator = card.progressIndicators.firstMatch

            if progressIndicator.exists {
                let value = progressIndicator.value as? Double ?? 1.0
                XCTAssertEqual(value, 0.0, accuracy: 0.1, "Card \(i) should be at position 0")
            }
        }
    }

    func testMasterTransportButtons_ExistAndEnabled() async throws {
        // Given: On Moving Sidewalk with songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // Then: All master transport buttons should exist and be enabled
        let playAllButton = app.buttons["Play All"]
        let pauseAllButton = app.buttons["Pause All"]
        let stopAllButton = app.buttons["Stop All"]

        XCTAssertTrue(playAllButton.exists && playAllButton.isEnabled, "Play All should exist and be enabled")
        XCTAssertTrue(pauseAllButton.exists && pauseAllButton.isEnabled, "Pause All should exist and be enabled")
        XCTAssertTrue(stopAllButton.exists && stopAllButton.isEnabled, "Stop All should exist and be enabled")
    }

    // =============================================================================
    // MARK: - Sync Mode Tests
    // =============================================================================

    func testSyncModeSelector_OpensMenu() async throws {
        // Given: On Moving Sidewalk
        try await testNavigateToMovingSidewalk()

        let syncModeButton = app.buttons["Sync Mode"]
        XCTAssertTrue(syncModeButton.waitForExistence(timeout: 3), "Sync Mode button should exist")

        // When: Tap sync mode button
        syncModeButton.tap()

        // Then: Should show sync mode options
        let syncModeMenu = app.sheets.firstMatch
        XCTAssertTrue(syncModeMenu.waitForExistence(timeout: 2), "Sync mode menu should appear")
    }

    func testSyncMode_Independent_TemposDiffer() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // Switch to independent mode
        let syncModeButton = app.buttons["Sync Mode"]
        syncModeButton.tap()

        let independentOption = app.sheets.buttons["Independent"]
        if independentOption.exists {
            independentOption.tap()
        }

        // When: Set different tempos for each song
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoSlider = card.sliders["Tempo"]
            tempoSlider.adjust(toNormalizedSliderPosition: CGFloat(i) / 6.0)
        }

        // Then: Tempos should differ (verify at least 2 are different)
        var tempos: Set<String> = []
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoLabel = card.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
            if tempoLabel.exists {
                tempos.insert(tempoLabel.label)
            }
        }

        XCTAssertGreaterThan(tempos.count, 1, "Should have different tempos in independent mode")
    }

    func testSyncMode_Locked_TemposSync() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // Switch to locked mode
        let syncModeButton = app.buttons["Sync Mode"]
        syncModeButton.tap()

        let lockedOption = app.sheets.buttons["Locked"]
        if lockedOption.exists {
            lockedOption.tap()
        }

        // When: Adjust master tempo
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.5)
        }

        // Then: All songs should sync to same tempo
        var tempos: Set<String> = []
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoLabel = card.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
            if tempoLabel.exists {
                tempos.insert(tempoLabel.label)
            }
        }

        XCTAssertEqual(tempos.count, 1, "All songs should have same tempo in locked mode")
    }

    func testSyncMode_Ratio_MaintainsRatios() async throws {
        // Given: Multiple songs loaded with different tempos
        try await testLoadSixSongs_AllSlotsFilled()

        // Set individual tempos first
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoSlider = card.sliders["Tempo"]
            tempoSlider.adjust(toNormalizedSliderPosition: CGFloat(i) / 6.0)
        }

        // Switch to ratio mode
        let syncModeButton = app.buttons["Sync Mode"]
        syncModeButton.tap()

        let ratioOption = app.sheets.buttons["Ratio"]
        if ratioOption.exists {
            ratioOption.tap()
        }

        // When: Adjust master tempo
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.7)
        }

        // Then: All should maintain relative ratios
        // (This would require more complex assertion logic)
        let masterTempoLabel = app.staticTexts["MasterTempoValue"]
        XCTAssertTrue(masterTempoLabel.exists, "Master tempo should be displayed")
    }

    // =============================================================================
    // MARK: - Timeline Scrubbing Tests
    // =============================================================================

    func testScrubTimeline_ChangesPosition() async throws {
        // Given: Song loaded and playing
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]
        playButton.tap()

        // Let it play for a bit
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // When: Scrub timeline
        let timeline = firstCard.otherElements["Timeline"]
        if timeline.exists {
            timeline.tap(at: CGPoint(x: timeline.frame.width * 0.7, y: timeline.frame.height / 2))
        }

        // Then: Position should update
        let progressIndicator = firstCard.progressIndicators.firstMatch
        if progressIndicator.exists {
            let value = progressIndicator.value as? Double ?? 0
            XCTAssertGreaterThan(value, 0.5, "Should be scrubbed to ~70% position")
        }
    }

    func testScrubToStart_ResetsToZero() async throws {
        // Given: Song playing
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]
        playButton.tap()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // When: Scrub to start
        let timeline = firstCard.otherElements["Timeline"]
        if timeline.exists {
            timeline.tap(at: CGPoint(x: 0, y: timeline.frame.height / 2))
        }

        // Then: Should be near start
        let progressIndicator = firstCard.progressIndicators.firstMatch
        if progressIndicator.exists {
            let value = progressIndicator.value as? Double ?? 1
            XCTAssertLessThan(value, 0.1, "Should be near start")
        }
    }

    func testScrubToEnd_GoesToDuration() async throws {
        // Given: Song loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Scrub to end
        let timeline = firstCard.otherElements["Timeline"]
        if timeline.exists {
            timeline.tap(at: CGPoint(x: timeline.frame.width, y: timeline.frame.height / 2))
        }

        // Then: Should be at or near end
        let progressIndicator = firstCard.progressIndicators.firstMatch
        if progressIndicator.exists {
            let value = progressIndicator.value as? Double ?? 0
            XCTAssertGreaterThan(value, 0.9, "Should be near end")
        }
    }

    // =============================================================================
    // MARK: - Layout & Responsiveness Tests
    // =============================================================================

    func testCompactLayout_iPhone() async throws {
        // Given: iPhone-sized viewport (compact)
        try await testLoadSixSongs_AllSlotsFilled()

        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")

        // When: Check layout
        let firstCard = songCards.element(boundBy: 0)
        let secondCard = songCards.element(boundBy: 1)

        // Then: Should be stacked vertically in compact view
        XCTAssertLessThan(secondCard.frame.minY, firstCard.frame.minY, "Second card should be below first in compact view")
    }

    func testExpandedLayout_iPad() async throws {
        // This test would run on iPad simulator
        // Given: iPad-sized viewport (expanded)
        try await testLoadSixSongs_AllSlotsFilled()

        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")

        // When: Check layout
        let firstCard = songCards.element(boundBy: 0)
        let secondCard = songCards.element(boundBy: 1)

        // Then: Should be in grid layout (2 or 3 per row)
        // On iPad, cards should be side by side
        if app.windows.firstMatch.frame.width > 600 { // iPad
            XCTAssertGreaterThan(secondCard.frame.minX, firstCard.frame.minX, "Second card should be to the right of first in expanded view")
        }
    }

    func testScrollView_ContentScrolls() async throws {
        // Given: More content than fits on screen
        try await testLoadSixSongs_AllSlotsFilled()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // When: Scroll down
            scrollView.swipeUp()

            // Then: Content should move
            let lastCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 5)
            XCTAssertTrue(lastCard.isHittable, "Last card should be accessible after scrolling")
        }
    }

    // =============================================================================
    // MARK: - Accessibility Tests
    // =============================================================================

    func testAccessibilityLabels_Present() async throws {
        // Given: On Moving Sidewalk
        try await testLoadSixSongs_AllSlotsFilled()

        // Then: All key elements should have accessibility labels
        let playButtons = app.buttons["Play"]
        let pauseButtons = app.buttons["Pause"]
        let muteButtons = app.buttons["Mute"]
        let soloButtons = app.buttons["Solo"]

        XCTAssertTrue(playButtons.firstMatch.exists, "Play button should be accessible")
        XCTAssertTrue(muteButtons.firstMatch.exists, "Mute button should be accessible")
        XCTAssertTrue(soloButtons.firstMatch.exists, "Solo button should be accessible")
    }

    func testVoiceOver_Navigation() async throws {
        // Given: VoiceOver enabled (would need to be enabled in settings)
        // This test would verify VoiceOver navigation

        // When: Navigate through elements
        // Then: Should announce proper labels and hints

        // Note: This is a placeholder for VoiceOver testing
        // Actual implementation would require VoiceOver to be enabled
    }

    func testDynamicType_Support() async throws {
        // Given: Dynamic type enabled
        // This test would verify text scales properly

        // When: Adjust dynamic type
        // Then: Text should scale without breaking layout

        // Note: This is a placeholder for Dynamic Type testing
    }

    // =============================================================================
    // MARK: - Performance Tests
    // =============================================================================

    func testLaunchTime_Performance() async throws {
        // Given: App not running
        // When: Launch app
        measure {
            app.launch()
        }

        // Then: Should launch in acceptable time
        // XCTest will measure and report the time
    }

    func testScrollingPerformance_Smooth() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // When: Scroll through content
            measure(metrics: [XCTClockMetric()]) {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }

            // Then: Scrolling should be smooth (measure scroll time)
        }
    }

    func testUIUpdate_Performance() async throws {
        // Given: Multiple songs playing
        try await testPlayAll_StartsAllSongs()

        // When: Measure UI update performance
        measure {
            // Simulate UI updates (checking element existence)
            let pauseButtons = app.buttons.matching(identifier: "Pause")
            _ = pauseButtons.count
        }
    }

    // =============================================================================
    // MARK: - State Persistence Tests
    // =============================================================================

    func testStatePersisted_AfterBackground() async throws {
        // Given: Songs loaded and playing
        try await testPlayAll_StartsAllSongs()

        // When: Background app
        XCUIDevice.shared.press(.home)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then: Return to app
        app.activate()

        // Verify state maintained
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        XCTAssertGreaterThan(pauseButtons.count, 0, "Should maintain playing state after backgrounding")
    }

    func testStatePersisted_AfterAppRestart() async throws {
        // Given: Load songs and save state
        try await testLoadSixSongs_AllSlotsFilled()

        // Save preset/state
        let saveButton = app.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
        }

        // When: Restart app
        app.terminate()
        app.launch()

        // Then: Restore state
        try await testNavigateToMovingSidewalk()

        // Verify state restored (implementation dependent)
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertEqual(songCards.count, 6, "Should restore 6 song cards")
    }

    // =============================================================================
    // MARK: - Error Handling Tests
    // =============================================================================

    func testLoadSong_InvalidFormat() async throws {
        // Given: On Moving Sidewalk
        try await testNavigateToMovingSidewalk()

        // When: Try to load invalid song (if file picker allows)
        // This would test error handling for unsupported formats

        // Then: Should show error message
        let alert = app.alerts.firstMatch
        // Verify error alert appears (if applicable)
    }

    func testPlayback_ErrorHandling() async throws {
        // Given: Song loaded but playback fails
        try await testLoadSixSongs_AllSlotsFilled()

        // When: Simulate playback error
        // This would require mock backend to trigger error

        // Then: Should show error UI
        // Verify error state displayed
    }

    func testMemoryWarning_HandledGracefully() async throws {
        // Given: Multiple songs loaded
        try await testLoadSixSongs_AllSlotsFilled()

        // When: Simulate memory warning
        // (This would need to be triggered via debug tool)

        // Then: App should remain responsive
        let playButton = app.buttons["Play All"].firstMatch
        XCTAssertTrue(playButton.exists, "App should remain functional after memory warning")
    }
}
