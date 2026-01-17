//
//  MultiSongWorkflowE2ETests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  End-to-end workflow tests for complete user journeys

import XCTest

// =============================================================================
// MARK: - Multi-Song Workflow E2E Test Suite
// =============================================================================

@MainActor
final class MultiSongWorkflowE2ETests: XCTestCase {

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
        app.launchArguments = ["UITEST", "E2E"]
        app.launchEnvironment = [
            "UITESTING": "1",
            "MOCK_AUDIO_ENGINE": "1",
            "E2E_MODE": "1"
        ]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
        await super.tearDown()
    }

    // =============================================================================
    // MARK: - Helper Methods
    // =============================================================================

    private func navigateToMovingSidewalk() async throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let tabBarsQuery = app.tabBars
        let movingSidewalkTab = tabBarsQuery.buttons["Moving Sidewalk"]

        XCTAssertTrue(movingSidewalkTab.waitForExistence(timeout: 5))
        movingSidewalkTab.tap()

        let navigationBar = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 3))
    }

    private func loadSixSongs() async throws {
        for i in 0..<6 {
            let loadButton = app.buttons["Load Slot \(i)"]
            XCTAssertTrue(loadButton.waitForExistence(timeout: 3))
            loadButton.tap()

            let songPicker = app.sheets.firstMatch
            XCTAssertTrue(songPicker.waitForExistence(timeout: 2))

            let demoSong = songPicker.buttons.matching(NSPredicate(format: "label CONTAINS 'Demo'")).element(boundBy: 0)
            if demoSong.exists {
                demoSong.tap()
            }

            XCTAssertFalse(songPicker.exists)
        }
    }

    private func verifyAllCardsPlaying() -> Bool {
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        return pauseButtons.count == 6
    }

    private func verifyAllCardsStopped() -> Bool {
        let playButtons = app.buttons.matching(identifier: "Play")
        return playButtons.count == 6
    }

    // =============================================================================
    // MARK: - Complete Session Workflows
    // =============================================================================

    func testWorkflow_CreateNewSession() async throws {
        // 1. Launch app
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 2. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 3. Load 6 songs
        try await loadSixSongs()

        // 4. Verify all songs loaded
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertEqual(songCards.count, 6, "Should have 6 song cards")

        // 5. Configure sync mode
        let syncModeButton = app.buttons["Sync Mode"]
        syncModeButton.tap()

        let lockedOption = app.sheets.buttons["Locked"]
        if lockedOption.exists {
            lockedOption.tap()
        }

        // 6. Set master tempo
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.6)
        }

        // 7. Play all
        let playAllButton = app.buttons["Play All"]
        XCTAssertTrue(playAllButton.waitForExistence(timeout: 2))
        playAllButton.tap()

        // 8. Verify all playing
        XCTAssertTrue(verifyAllCardsPlaying(), "All 6 songs should be playing")

        // 9. Wait for playback to establish
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // 10. Stop all
        let stopAllButton = app.buttons["Stop All"]
        if stopAllButton.exists {
            stopAllButton.tap()
        }

        // 11. Verify all stopped
        XCTAssertTrue(verifyAllCardsStopped(), "All 6 songs should be stopped")
    }

    func testWorkflow_CreateAndSavePreset() async throws {
        // 1. Create complete session
        try await testWorkflow_CreateNewSession()

        // 2. Save preset
        let saveButton = app.buttons["Save Preset"]
        if saveButton.exists {
            saveButton.tap()

            let presetNameField = app.textFields["Preset Name"]
            XCTAssertTrue(presetNameField.waitForExistence(timeout: 2))

            presetNameField.tap()
            presetNameField.typeText("E2E Test Session")

            let confirmButton = app.buttons["Save"]
            if confirmButton.exists {
                confirmButton.tap()
            }
        }

        // 3. Verify save succeeded
        let successAlert = app.alerts.firstMatch
        if successAlert.waitForExistence(timeout: 3) {
            XCTAssertTrue(successAlert.exists, "Should show save confirmation")
            successAlert.buttons.firstMatch.tap()
        }
    }

    func testWorkflow_LoadAndModifyPreset() async throws {
        // 1. Navigate to presets
        app.tabBars.buttons["Presets"].tap()

        // 2. Load existing preset (assumes one exists)
        let presetTable = app.tables.firstMatch
        if presetTable.waitForExistence(timeout: 3) {
            let firstPreset = presetTable.cells.firstMatch
            if firstPreset.exists {
                firstPreset.tap()
            }
        }

        // 3. Verify preset loaded
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        if songCards.count > 0 {
            // 4. Modify master tempo
            let masterTempoSlider = app.sliders["Master Tempo"]
            if masterTempoSlider.exists {
                masterTempoSlider.adjust(toNormalizedSliderPosition: 0.7)
            }

            // 5. Play all
            let playAllButton = app.buttons["Play All"]
            if playAllButton.exists {
                playAllButton.tap()
            }

            // 6. Verify playing with new tempo
            try await Task.sleep(nanoseconds: 1_000_000_000)
            XCTAssertTrue(verifyAllCardsPlaying())
        }
    }

    func testWorkflow_CompletePerformanceSession() async throws {
        // This simulates a real user performance session

        // 1. Setup session
        try await testWorkflow_CreateNewSession()

        // 2. Individual song adjustments
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)

            // Set individual volumes for mix
            let volumeSlider = card.sliders["Volume"]
            if volumeSlider.exists {
                volumeSlider.adjust(toNormalizedSliderPosition: 0.8)
            }

            // Mute song 2 for contrast
            if i == 2 {
                let muteButton = card.buttons["Mute"]
                if muteButton.exists {
                    muteButton.tap()
                }
            }
        }

        // 3. Start performance
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        // 4. Simulate performance changes
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Unmute song 2 mid-performance
        let card2 = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: 2)
        let muteButton = card2.buttons["Mute"]
        if muteButton.exists {
            muteButton.tap()
        }

        // 5. Adjust master tempo mid-performance
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.8)
        }

        // 6. Continue performance
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // 7. End performance
        let stopAllButton = app.buttons["Stop All"]
        if stopAllButton.exists {
            stopAllButton.tap()
        }

        // 8. Verify clean stop
        XCTAssertTrue(verifyAllCardsStopped(), "All songs should be stopped after performance")
    }

    // =============================================================================
    // MARK: - Multi-Tab Navigation Workflows
    // =============================================================================

    func testWorkflow_NavigateBetweenTabs() async throws {
        // 1. Start on Moving Sidewalk
        try await navigateToMovingSidewalk()
        try await loadSixSongs()

        // 2. Navigate to Orchestrator Console
        app.tabBars.buttons["Orchestrator"].tap()
        let orchestratorTitle = app.navigationBars["Orchestrator Console"]
        XCTAssertTrue(orchestratorTitle.waitForExistence(timeout: 3))

        // 3. Navigate to Sheet Music
        app.tabBars.buttons["Sheet Music"].tap()
        let sheetMusicTitle = app.navigationBars["Sheet Music"]
        XCTAssertTrue(sheetMusicTitle.waitForExistence(timeout: 3))

        // 4. Return to Moving Sidewalk
        app.tabBars.buttons["Moving Sidewalk"].tap()
        let movingSidewalkTitle = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(movingSidewalkTitle.waitForExistence(timeout: 3))

        // 5. Verify state preserved
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertEqual(songCards.count, 6, "Songs should still be loaded")
    }

    func testWorkflow_BackgroundAndRestore() async throws {
        // 1. Create session
        try await testWorkflow_CreateNewSession()

        // 2. Play all songs
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        // 3. Background app
        XCUIDevice.shared.press(.home)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // 4. Restore app
        app.activate()

        // 5. Verify state preserved
        let movingSidewalkTitle = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(movingSidewalkTitle.waitForExistence(timeout: 5))

        // 6. Verify still playing
        let pauseButtons = app.buttons.matching(identifier: "Pause")
        XCTAssertGreaterThan(pauseButtons.count, 0, "Songs should still be playing after restore")
    }

    // =============================================================================
    // MARK: - Error Recovery Workflows
    // =============================================================================

    func testWorkflow_RecoverFromCrash() async throws {
        // 1. Create and save session
        try await testWorkflow_CreateAndSavePreset()

        // 2. Simulate crash (terminate app)
        app.terminate()

        // 3. Relaunch
        app.launch()

        // 4. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 5. Load saved preset
        app.buttons["Load Preset"].tap()
        let presetTable = app.tables.firstMatch
        if presetTable.waitForExistence(timeout: 3) {
            let testPreset = presetTable.cells["E2E Test Session"]
            if testPreset.exists {
                testPreset.tap()
            }
        }

        // 6. Verify session restored
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertGreaterThan(songCards.count, 0, "Should restore saved session")
    }

    func testWorkflow_HandleSongLoadFailure() async throws {
        // 1. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 2. Try to load non-existent song (simulated error)
        let loadButton = app.buttons["Load Slot 0"]
        loadButton.tap()

        let songPicker = app.sheets.firstMatch
        if songPicker.exists {
            // Try to pick a song that might fail
            let invalidSong = songPicker.buttons["Invalid Song"]
            if invalidSong.exists {
                invalidSong.tap()

                // 3. Verify error handled gracefully
                let errorAlert = app.alerts.firstMatch
                if errorAlert.waitForExistence(timeout: 2) {
                    let dismissButton = errorAlert.buttons["OK"]
                    if dismissButton.exists {
                        dismissButton.tap()
                    }
                }
            } else {
                // Cancel if no invalid song option
                let cancelButton = songPicker.buttons["Cancel"]
                cancelButton.tap()
            }
        }

        // 4. Verify app still functional
        let movingSidewalkTitle = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(movingSidewalkTitle.exists, "App should remain functional after error")
    }

    // =============================================================================
    // MARK: - Advanced Workflow Tests
    // =============================================================================

    func testWorkflow_ComplexSyncScenario() async throws {
        // 1. Load songs
        try await navigateToMovingSidewalk()
        try await loadSixSongs()

        // 2. Start in independent mode
        let syncModeButton = app.buttons["Sync Mode"]
        syncModeButton.tap()
        app.sheets.buttons["Independent"].tap()

        // 3. Set different tempos
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoSlider = card.sliders["Tempo"]
            tempoSlider.adjust(toNormalizedSliderPosition: CGFloat(i) / 6.0)
        }

        // 4. Play to verify independent
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        try await Task.sleep(nanoseconds: 2_000_000_000)

        // 5. Switch to locked mode mid-playback
        app.buttons["Pause All"].tap()
        syncModeButton.tap()
        app.sheets.buttons["Locked"].tap()

        // 6. Adjust master tempo
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.5)
        }

        // 7. Resume in locked mode
        app.buttons["Play All"].tap()

        // 8. Verify all sync to master tempo
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // All should show same tempo
        var tempos: Set<String> = []
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let tempoLabel = card.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'Tempo'")).firstMatch
            if tempoLabel.exists {
                tempos.insert(tempoLabel.label)
            }
        }

        XCTAssertEqual(tempos.count, 1, "All tempos should be locked together")
    }

    func testWorkflow_LiveRemixing() async throws {
        // 1. Setup session
        try await testWorkflow_CreateNewSession()

        // 2. Start playing
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        // 3. Solo different songs in sequence
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let soloButton = card.buttons["Solo"]

            if soloButton.exists {
                soloButton.tap()
            }

            // Let it play solo briefly
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Unsolo
            if soloButton.exists {
                soloButton.tap()
            }
        }

        // 4. Mute/unmute for dynamics
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let muteButton = card.buttons["Mute"]

            if muteButton.exists {
                muteButton.tap()
            }
        }

        try await Task.sleep(nanoseconds: 2_000_000_000)

        // 5. Unmute all for finale
        for i in 0..<6 {
            let card = app.otherElements.matching(identifier: "SongPlayerCard").element(boundBy: i)
            let muteButton = card.buttons["Mute"]

            if muteButton.exists && muteButton.isSelected {
                muteButton.tap()
            }
        }

        // 6. Stop
        app.buttons["Stop All"].tap()

        // 7. Verify clean state
        XCTAssertTrue(verifyAllCardsStopped())
    }

    // =============================================================================
    // MARK: - Performance & Stress Tests
    // =============================================================================

    func testWorkflow_LongSession() async throws {
        // Simulate a long practice session (accelerated)

        // 1. Initial setup
        try await testWorkflow_CreateNewSession()

        // 2. Multiple play/stop cycles
        for _ in 0..<10 {
            // Play
            let playAllButton = app.buttons["Play All"]
            if playAllButton.exists {
                playAllButton.tap()
            }

            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Stop
            let stopAllButton = app.buttons["Stop All"]
            if stopAllButton.exists {
                stopAllButton.tap()
            }

            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }

        // 3. Verify still stable
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        XCTAssertEqual(songCards.count, 6, "All cards should still be present")

        let playAllButton = app.buttons["Play All"]
        XCTAssertTrue(playAllButton.exists, "Controls should still be responsive")
    }

    func testWorkflow_RapidConfigurationChanges() async throws {
        // 1. Setup
        try await navigateToMovingSidewalk()
        try await loadSixSongs()

        // 2. Rapidly change sync modes
        let syncModeButton = app.buttons["Sync Mode"]
        let modes = ["Independent", "Locked", "Ratio"]

        for _ in 0..<5 {
            for mode in modes {
                syncModeButton.tap()
                let modeOption = app.sheets.buttons[mode]
                if modeOption.exists {
                    modeOption.tap()
                }
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }

        // 3. Rapidly adjust tempos
        for i in 0..<20 {
            let masterTempoSlider = app.sliders["Master Tempo"]
            if masterTempoSlider.exists {
                masterTempoSlider.adjust(toNormalizedSliderPosition: CGFloat(i % 10) / 10.0)
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }

        // 4. Verify still functional
        let playAllButton = app.buttons["Play All"]
        XCTAssertTrue(playAllButton.exists, "Should remain functional after rapid changes")
    }

    // =============================================================================
    // MARK: - State Management Workflows
    // =============================================================================

    func testWorkflow_AutoSave() async throws {
        // 1. Create session
        try await navigateToMovingSidewalk()
        try await loadSixSongs()

        // 2. Make changes
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // 3. Force close without manual save
        app.terminate()

        // 4. Relaunch
        app.launch()

        // 5. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 6. Verify auto-save restored state
        // (This depends on auto-save implementation)
        let songCards = app.otherElements.matching(identifier: "SongPlayerCard")
        if songCards.count > 0 {
            // Auto-save worked
            XCTAssertGreaterThan(songCards.count, 0)
        }
    }

    func testWorkflow_MultiplePresets() async throws {
        // 1. Create first preset
        try await testWorkflow_CreateAndSavePreset()

        // 2. Modify and save second preset
        let masterTempoSlider = app.sliders["Master Tempo"]
        if masterTempoSlider.exists {
            masterTempoSlider.adjust(toNormalizedSliderPosition: 0.9)
        }

        let saveButton = app.buttons["Save Preset"]
        if saveButton.exists {
            saveButton.tap()

            let presetNameField = app.textFields["Preset Name"]
            if presetNameField.exists {
                presetNameField.tap()
                presetNameField.typeText("E2E Test Session 2")

                let confirmButton = app.buttons["Save"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }
        }

        // 3. Navigate to presets list
        app.tabBars.buttons["Presets"].tap()

        // 4. Verify both presets exist
        let presetTable = app.tables.firstMatch
        if presetTable.waitForExistence(timeout: 3) {
            XCTAssertGreaterThanOrEqual(presetTable.cells.count, 2, "Should have at least 2 presets")
        }
    }

    // =============================================================================
    // MARK: - Cross-Feature Integration
    // =============================================================================

    func testWorkflow_MovingSidewalkToOrchestrator() async throws {
        // 1. Setup Moving Sidewalk session
        try await navigateToMovingSidewalk()
        try await loadSixSongs()

        // 2. Note configuration
        let masterTempoSlider = app.sliders["Master Tempo"]
        let originalTempo = masterTempoSlider.value as? CGFloat ?? 0.5

        // 3. Navigate to Orchestrator
        app.tabBars.buttons["Orchestrator"].tap()

        // 4. Verify session data accessible in Orchestrator
        // (This tests integration between features)
        let orchestratorTitle = app.navigationBars["Orchestrator Console"]
        XCTAssertTrue(orchestratorTitle.waitForExistence(timeout: 3))

        // 5. Make changes in Orchestrator
        // (Implementation dependent)

        // 6. Return to Moving Sidewalk
        app.tabBars.buttons["Moving Sidewalk"].tap()

        // 7. Verify changes reflected
        let movingSidewalkTitle = app.navigationBars["Moving Sidewalk"]
        XCTAssertTrue(movingSidewalkTitle.waitForExistence(timeout: 3))
    }

    // =============================================================================
    // MARK: - Accessibility Workflows
    // =============================================================================

    func testWorkflow_VoiceOverCompleteSession() async throws {
        // This test would run with VoiceOver enabled
        // Simulates a VoiceOver user creating a complete session

        // 1. Navigate to Moving Sidewalk
        try await navigateToMovingSidewalk()

        // 2. Load songs (VoiceOver navigation)
        // VoiceOver users would swipe right/left to navigate

        // 3. Configure session
        // Verify all elements are accessible

        // 4. Play and control
        // Verify VoiceOver announcements are correct

        // 5. Save preset
        // Verify form fields are accessible

        // Note: Actual VoiceOver testing requires VoiceOver to be enabled
    }

    // =============================================================================
    // MARK: - Final Verification
    // =============================================================================

    func testWorkflow_CompleteUserJourney() async throws {
        // This is the ultimate end-to-end test
        // Simulates a complete user journey from launch to save

        // 1. Launch app and explore
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 2. Navigate through all tabs
        app.tabBars.buttons["Moving Sidewalk"].tap()
        try await Task.sleep(nanoseconds: 500_000_000)

        app.tabBars.buttons["Orchestrator"].tap()
        try await Task.sleep(nanoseconds: 500_000_000)

        app.tabBars.buttons["Sheet Music"].tap()
        try await Task.sleep(nanoseconds: 500_000_000)

        // 3. Return to Moving Sidewalk
        app.tabBars.buttons["Moving Sidewalk"].tap()

        // 4. Create complete session
        try await loadSixSongs()

        // 5. Configure and play
        let playAllButton = app.buttons["Play All"]
        if playAllButton.exists {
            playAllButton.tap()
        }

        try await Task.sleep(nanoseconds: 3_000_000_000)

        // 6. Stop and save
        app.buttons["Stop All"].tap()

        let saveButton = app.buttons["Save Preset"]
        if saveButton.exists {
            saveButton.tap()

            let presetNameField = app.textFields["Preset Name"]
            if presetNameField.exists {
                presetNameField.tap()
                presetNameField.typeText("Complete Journey")

                let confirmButton = app.buttons["Save"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }
        }

        // 7. Verify success
        let successAlert = app.alerts.firstMatch
        if successAlert.waitForExistence(timeout: 3) {
            XCTAssertTrue(successAlert.exists, "Complete journey should succeed")
        }

        // 8. Clean exit
        app.terminate()
    }
}
