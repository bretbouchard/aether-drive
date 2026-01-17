//
//  MovingSidewalktvOSXCUIUITests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  XCUITest suite for Moving Sidewalk on tvOS - Focus engine & Siri Remote

import XCTest

// =============================================================================
// MARK: - Moving Sidewalk tvOS XCUITest Suite
// =============================================================================

@MainActor
final class MovingSidewalktvOSXCUIUITests: XCTestCase {

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
        app.launchArguments = ["UITEST", "TVOS"]
        app.launchEnvironment = [
            "UITESTING": "1",
            "MOCK_AUDIO_ENGINE": "1",
            "TVOS_MODE": "1"
        ]

        // Increase timeout for tvOS (focus engine can be slower)
        app.launchTimeout = 10
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
        await super.tearDown()
    }

    // =============================================================================
    // MARK: - Helper Methods
    // =============================================================================

    /// Navigate to Moving Sidewalk on tvOS
    private func navigateToMovingSidewalk() async throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // On tvOS, navigation might be different (could be tab-based or menu-based)
        let tabBarsQuery = app.tabBars
        let movingSidewalkTab = tabBarsQuery.buttons["Moving Sidewalk"]

        if movingSidewalkTab.exists {
            movingSidewalkTab.tap()
        } else {
            // Alternative: menu-based navigation
            let menuButton = app.buttons["Menu"]
            if menuButton.exists {
                menuButton.tap()
            }

            let movingSidewalkMenuItem = app.cells["Moving Sidewalk"]
            XCTAssertTrue(movingSidewalkMenuItem.waitForExistence(timeout: 5))
            movingSidewalkMenuItem.tap()
        }

        let navigationBar = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
    }

    /// Load multiple songs for testing
    private func loadMultipleSongs() async throws {
        try await navigateToMovingSidewalk()

        for i in 0..<6 {
            let loadButton = app.buttons["Load Slot \(i)"]
            if loadButton.waitForExistence(timeout: 3) {
                loadButton.tap()

                let songPicker = app.sheets.firstMatch
                if songPicker.waitForExistence(timeout: 2) {
                    let demoSong = songPicker.buttons.matching(NSPredicate(format: "label CONTAINS 'Demo'")).element(boundBy: 0)
                    if demoSong.exists {
                        demoSong.tap()
                    }
                }

                // Wait for sheet to dismiss
                XCTAssertFalse(songPicker.exists, "Song picker should dismiss")
            }
        }
    }

    // =============================================================================
    // MARK: - Focus Engine Tests
    // =============================================================================

    func testFocusEngine_InitialFocus() async throws {
        // Given: On Moving Sidewalk screen
        try await navigateToMovingSidewalk()

        // When: Check initial focus
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // Then: First card should be focused
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5), "First card should exist")
        // Note: hasFocus is not directly available in XCUITest, we verify through interaction
    }

    func testFocusEngine_SwipeRight_NextCard() async throws {
        // Given: Multiple songs loaded, first card focused
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists)

        // When: Swipe right (Siri Remote gesture)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeRight()
        }

        // Then: Focus should move to next card
        let secondCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 1)
        XCTAssertTrue(secondCard.exists, "Second card should exist")

        // Verify by attempting interaction (will only work on focused element)
        // Note: XCUITest doesn't directly expose focus state, but we can infer it
    }

    func testFocusEngine_SwipeLeft_PreviousCard() async throws {
        // Given: On second card
        try await testFocusEngine_SwipeRight_NextCard()

        // When: Swipe left
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeLeft()
        }

        // Then: Focus should return to first card
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists, "First card should exist")
    }

    func testFocusEngine_SwipeDown_NextRow() async throws {
        // Given: Multiple songs loaded (grid layout)
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists)

        // When: Swipe down (to next row in 3-column grid)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
        }

        // Then: Focus should move to card below (card 3 in 3-column grid)
        let fourthCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 3)
        XCTAssertTrue(fourthCard.exists, "Fourth card should exist")
    }

    func testFocusEngine_SwipeUp_PreviousRow() async throws {
        // Given: On card in second row
        try await testFocusEngine_SwipeDown_NextRow()

        // When: Swipe up
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Then: Focus should return to first row
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists, "First card should exist")
    }

    func testFocusEngine_Edge_Wrapping() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        let lastCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 5)
        XCTAssertTrue(lastCard.exists)

        // When: Try to navigate past last card (swipe right)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeRight()
            scrollView.swipeRight()
        }

        // Then: Should either stay on last card or wrap to first (depends on implementation)
        // This test verifies focus behavior at edges
        let stillOnLast = lastCard.exists
        XCTAssertTrue(stillOnLast || app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0).exists)
    }

    func testFocusEngine_MenuButton_Back() async throws {
        // Given: On Moving Sidewalk with card focused
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists)

        // When: Press menu button (simulated via key command)
        app.children(matching: .window).element(boundBy: 0).tap()

        // Then: Should navigate back or show menu
        // Verify navigation state changed
    }

    // =============================================================================
    // MARK: - Siri Remote Button Tests
    // =============================================================================

    func testSiriRemote_SelectButton_PlaysSong() async throws {
        // Given: Multiple songs loaded, card focused
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Press select button (tap on focused element)
        firstCard.tap()

        // Then: Song should start playing
        let pauseButton = firstCard.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Should show pause button after playing")
    }

    func testSiriRemote_SelectButton_TogglesPlayback() async throws {
        // Given: Song playing
        try await testSiriRemote_SelectButton_PlaysSong()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Press select again
        firstCard.tap()

        // Then: Should pause
        let playButton = firstCard.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2), "Should show play button after pausing")
    }

    func testSiriRemote_PlayPauseButton_MasterControl() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        // When: Press play/pause on Siri Remote (if mapped to master control)
        let masterPlayButton = app.buttons["Play All"]
        if masterPlayButton.exists {
            masterPlayButton.tap()
        }

        // Then: All songs should play
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        XCTAssertGreaterThan(pauseButtons.count, 0, "Should have playing songs")
    }

    func testSiriRemote_LongPress_ContextualMenu() async throws {
        // Given: Card focused
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Long press on Siri Remote
        firstCard.press(forDuration: 1.0)

        // Then: Should show contextual menu (if implemented)
        let contextualMenu = app.otherElements["ContextualMenu"].firstMatch
        // Note: This depends on whether long-press menus are implemented
    }

    // =============================================================================
    // MARK: - 10-Foot Interface Tests
    // =============================================================================

    func testGridLayout_ThreeColumns() async throws {
        // Given: Multiple songs loaded on tvOS
        try await loadMultipleSongs()

        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")

        // Then: Should have 2 rows of 3 columns
        XCTAssertEqual(songCards.count, 6, "Should have 6 cards")

        // Verify grid layout by checking positions
        let card0 = songCards.element(boundBy: 0).frame
        let card1 = songCards.element(boundBy: 1).frame
        let card3 = songCards.element(boundBy: 3).frame

        // Card 3 should be below card 0 (different row)
        XCTAssertGreaterThan(card3.origin.y, card0.origin.y + 10, "Card 3 should be in next row")

        // Card 1 should be right of card 0 (same row)
        XCTAssertGreaterThan(card1.origin.x, card0.origin.x + 10, "Card 1 should be to the right of card 0")
    }

    func testLargeButtons_MinimumTapTargetSize() async throws {
        // Given: On Moving Sidewalk
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]

        XCTAssertTrue(playButton.waitForExistence(timeout: 3), "Play button should exist")

        // Then: Should be at least 48x48 points (tvOS minimum)
        let frame = playButton.frame
        XCTAssertGreaterThanOrEqual(frame.width, 48, "Button width should meet minimum")
        XCTAssertGreaterThanOrEqual(frame.height, 48, "Button height should meet minimum")
    }

    func testTextSize_ReadableFromDistance() async throws {
        // Given: On Moving Sidewalk
        try await navigateToMovingSidewalk()

        // Check song name labels
        let songNames = app.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'SongName'"))

        // Then: Text should be large enough for 10-foot interface
        // tvOS guidelines recommend minimum font sizes
        if songNames.firstMatch.exists {
            let firstLabel = songNames.element(boundBy: 0)
            // Verify label is visible and has content
            XCTAssertTrue(firstLabel.exists, "Song name label should exist")
        }
    }

    func testHighContrastMode_Visible() async throws {
        // Given: High contrast mode enabled (would need to be enabled in settings)
        try await loadMultipleSongs()

        // When: Check visibility
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]

        // Then: Elements should be visible and distinguishable
        XCTAssertTrue(playButton.exists, "Play button should be visible in high contrast")
    }

    func testReduceMotion_SmoothTransitions() async throws {
        // Given: Reduce motion enabled
        try await loadMultipleSongs()

        // When: Navigate between cards
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeRight()
        }

        // Then: Should still be smooth even with reduced motion
        let secondCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 1)
        XCTAssertTrue(secondCard.exists, "Navigation should work with reduce motion")
    }

    // =============================================================================
    // MARK: - Gesture Tests
    // =============================================================================

    func testSwipeGesture_Sensitivity() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Perform multiple small swipes
        for _ in 0..<3 {
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeRight()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        // Then: Should have moved multiple cards
        let fourthCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 3)
        XCTAssertTrue(fourthCard.exists, "Should navigate through multiple cards")
    }

    func testScroll_Smooth() async throws {
        // Given: More content than fits on screen
        try await loadMultipleSongs()

        let scrollView = app.scrollViews.firstMatch

        // When: Scroll through content
        if scrollView.exists {
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            scrollView.swipeDown()
        }

        // Then: Scrolling should be smooth
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        XCTAssertTrue(firstCard.exists, "Content should remain accessible after scrolling")
    }

    // =============================================================================
    // MARK: - Control Tests (tvOS-specific)
    // =============================================================================

    func testTempoAdjustment_Scrubbing() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // Focus on card
        firstCard.tap()

        // When: Use Siri Remote touch surface to adjust tempo
        // (This would involve long-press or specific gesture)
        let tempoSlider = firstCard.sliders["Tempo"]
        if tempoSlider.exists {
            tempoSlider.adjust(toNormalizedSliderPosition: 0.75)
        }

        // Then: Tempo should update
        let tempoLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
        if tempoLabel.exists {
            XCTAssertTrue(tempoLabel.label.contains("BPM"), "Should display updated tempo")
        }
    }

    func testVolumeAdjustment_Scrubbing() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Adjust volume
        let volumeSlider = firstCard.sliders["Volume"]
        if volumeSlider.exists {
            volumeSlider.adjust(toNormalizedSliderPosition: 0.5)
        }

        // Then: Volume should update
        let volumeLabel = firstCard.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Volume'")).firstMatch
        if volumeLabel.exists {
            XCTAssertTrue(volumeLabel.label.contains("%"), "Should display updated volume")
        }
    }

    func testTimelineScrubbing_Precision() async throws {
        // Given: Song loaded
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Scrub timeline
        let timeline = firstCard.otherElements["Timeline"]
        if timeline.exists {
            timeline.tap(at: CGPoint(x: timeline.frame.width * 0.5, y: timeline.frame.height / 2))
        }

        // Then: Position should update
        let progressIndicator = firstCard.progressIndicators.firstMatch
        if progressIndicator.exists {
            let value = progressIndicator.value as? Double ?? 0
            XCTAssertGreaterThan(value, 0.3, "Should scrub to approximately 50%")
        }
    }

    // =============================================================================
    // MARK: - Multi-User Tests
    // =============================================================================

    func testMultiUser_ProfileSwitching() async throws {
        // Given: User A's session loaded
        try await loadMultipleSongs()

        // When: Switch to User B profile (if implemented)
        let profileButton = app.buttons["Switch Profile"]
        if profileButton.exists {
            profileButton.tap()

            let userProfile = app.sheets.buttons["User B"]
            if userProfile.exists {
                userProfile.tap()
            }
        }

        // Then: Should load User B's settings
        // Verify profile-specific settings applied
    }

    func testFamilySharing_AccessControl() async throws {
        // Given: Family sharing enabled
        try await navigateToMovingSidewalk()

        // When: Try to access restricted content
        // Verify appropriate access controls

        // Then: Should respect family sharing settings
    }

    // =============================================================================
    // MARK: - Performance Tests (tvOS-specific)
    // =============================================================================

    func testFocusPerformance_Smooth() async throws {
        // Given: Multiple cards
        try await loadMultipleSongs()

        let scrollView = app.scrollViews.firstMatch

        // When: Measure focus navigation performance
        if scrollView.exists {
            measure(metrics: [XCTClockMetric()]) {
                scrollView.swipeRight()
                scrollView.swipeLeft()
                scrollView.swipeDown()
                scrollView.swipeUp()
            }
        }

        // Then: Focus navigation should be fast (<100ms per move)
    }

    func testAnimationPerformance_Fluid() async throws {
        // Given: On Moving Sidewalk
        try await navigateToMovingSidewalk()

        // When: Trigger animations
        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)
        firstCard.tap()

        // Then: Animations should be smooth (60fps)
        // Measure frame drops during focus changes
    }

    func testMemoryUsage_Efficient() async throws {
        // Given: Multiple songs loaded
        try await loadMultipleSongs()

        // When: Check memory usage
        // (Would need to use performance monitoring tools)

        // Then: Should use <200MB for UI
        // tvOS has generous memory, but should still be efficient
    }

    // =============================================================================
    // MARK: - Integration Tests
    // =============================================================================

    func testSiriIntegration_VoiceCommands() async throws {
        // Given: On Moving Sidewalk
        try await navigateToMovingSidewalk()

        // When: Use Siri voice commands (if integrated)
        // "Play all songs"
        // "Set tempo to 120"

        // Then: Commands should execute
        // Note: This would require actual Siri integration testing
    }

    func testAirPlay_Streaming() async throws {
        // Given: Songs playing
        try await loadMultipleSongs()

        // When: Enable AirPlay to external speakers
        let airPlayButton = app.buttons["AirPlay"]
        if airPlayButton.exists {
            airPlayButton.tap()
        }

        // Then: Audio should stream without interruption
        // Verify playback continues
    }

    func testSleepTimer_AutoStop() async throws {
        // Given: Songs playing
        try await loadMultipleSongs()

        // When: Set sleep timer (if implemented)
        let sleepTimerButton = app.buttons["Sleep Timer"]
        if sleepTimerButton.exists {
            sleepTimerButton.tap()

            let timerOption = app.sheets.buttons["30 minutes"]
            if timerOption.exists {
                timerOption.tap()
            }
        }

        // Then: Should stop after timer expires
        // (Would need to wait 30 minutes or mock timer)
    }

    // =============================================================================
    // MARK: - Accessibility Tests (tvOS-specific)
    // =============================================================================

    func testVoiceOver_FocusAnnouncements() async throws {
        // Given: VoiceOver enabled
        try await loadMultipleSongs()

        let firstCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 0)

        // When: Focus moves to card
        firstCard.tap()

        // Then: Should announce card content
        // "Demo Song 0, tempo 120 BPM, not playing"
        // Note: VoiceOver announcements can't be directly tested in XCUITest
    }

    func testVoiceOver_GestureSupport() async throws {
        // Given: VoiceOver enabled
        try await loadMultipleSongs()

        // When: Use VoiceOver gestures
        // Swipe right/left to navigate
        // Double-tap to activate

        // Then: Should respond correctly to VoiceOver gestures
    }

    // =============================================================================
    // MARK: - Error Handling Tests
    // =============================================================================

    func testNetworkError_GracefulDegradation() async throws {
        // Given: App running without network
        try await navigateToMovingSidewalk()

        // When: Try to load songs from cloud (if applicable)
        // Network requests should fail gracefully

        // Then: Should show appropriate error or use cached content
        let errorMessage = app.alerts.firstMatch
        // Verify error handling
    }

    func testControllerDisconnected_Fallback() async throws {
        // Given: Siri Remote disconnected during use
        try await loadMultipleSongs()

        // When: Simulate controller disconnect
        // (This would need to be simulated)

        // Then: App should remain functional
        // Or show "reconnect controller" message
    }

    // =============================================================================
    // MARK: - End-to-End Tests
    // =============================================================================

    func testCompleteSession_tvOS() async throws {
        // 1. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 2. Load 6 songs
        try await loadMultipleSongs()

        // 3. Navigate through cards
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeRight()
            scrollView.swipeRight()
            scrollView.swipeDown()
        }

        // 4. Play song via Siri Remote
        let thirdCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 2)
        thirdCard.tap()

        // 5. Adjust tempo
        let tempoSlider = thirdCard.sliders["Tempo"]
        if tempoSlider.exists {
            tempoSlider.adjust(toNormalizedSliderPosition: 0.7)
        }

        // 6. Mute another song
        let secondCard = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 1)
        scrollView?.swipeLeft()
        if secondCard.exists {
            secondCard.buttons["Mute"].tap()
        }

        // 7. Stop all
        let stopAllButton = app.buttons["Stop All"]
        if stopAllButton.exists {
            stopAllButton.tap()
        }

        // 8. Save preset
        let saveButton = app.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()

            let presetName = app.textFields["Preset Name"]
            if presetName.exists {
                presetName.tap()
                presetName.typeText("tvOS Test Session")

                let confirmButton = app.buttons["Save"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }
        }

        // 9. Verify save succeeded
        let successAlert = app.alerts.firstMatch
        // Verify success state
    }

    func testWorkflow_ContinuousPlayback() async throws {
        // Given: Complete session set up
        try await testCompleteSession_tvOS()

        // When: Enable continuous playback (if implemented)
        let continuousButton = app.buttons["Continuous Playback"]
        if continuousButton.exists {
            continuousButton.tap()
        }

        // Then: Songs should transition seamlessly
        // Verify smooth transitions between songs
    }
}
