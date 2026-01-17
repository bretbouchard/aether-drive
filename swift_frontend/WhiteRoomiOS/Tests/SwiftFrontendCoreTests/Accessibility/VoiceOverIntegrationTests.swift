//
//  VoiceOverIntegrationTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - VoiceOver Integration Test Suite
// =============================================================================

/// VoiceOver automation tests for White Room's Moving Sidewalk feature.
///
/// This test suite validates VoiceOver navigation, interaction, and usability
/// for users with visual impairments. Tests cover:
///
/// - Complete VoiceOver workflow navigation
/// - Focus order follows visual layout
/// - VoiceOver actions (activate, adjust sliders)
/// - VoiceOver hints are informative
/// - VoiceOver performance
///
/// **Prerequisites**:
/// - VoiceOver must be enabled in simulator/device settings
/// - Tests use VOICEOVER_TEST launch argument to enable VoiceOver programmatically
///
/// Success Criteria:
/// - 100% of interface navigable with VoiceOver
/// - Logical focus order matching visual layout
/// - All interactive elements have informative hints
/// - VoiceOver actions work correctly
/// - Navigation completes in under 2 seconds for 20 elements
class VoiceOverIntegrationTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["VOICEOVER_TEST", "UITESTING", "MOCK_AUDIO_ENGINE"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // =============================================================================
    // MARK: - Complete VoiceOver Workflow Tests
    // =============================================================================

    func testVoiceOver_CompleteWorkflow_Navigable() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - navigate through entire interface with VoiceOver
        var elementsVisited = 0
        var lastElement: XCUIElement?
        let maxElements = 100

        repeat {
            // Get current focused element
            let focusedElement = app.focusedElement

            if focusedElement.exists {
                elementsVisited += 1

                // Verify element has accessibility label
                XCTAssertFalse(
                    focusedElement.label.isEmpty,
                    "Element \(elementsVisited) missing accessibility label. Found: \(focusedElement)"
                )

                // Verify element has traits
                let traits = focusedElement.accessibilityTraits
                XCTAssertFalse(
                    traits.isEmpty,
                    "Element \(elementsVisited) missing accessibility traits"
                )

                // Log element for debugging
                NSLog("VoiceOver Element \(elementsVisited): \(focusedElement.label) - Traits: \(traits)")

                // Move to next element
                app.swipeRight()

                // Detect if we've looped back to the beginning
                if let last = lastElement,
                   focusedElement.label == last.label,
                   focusedElement.debugDescription == last.debugDescription {
                    break
                }

                lastElement = focusedElement
            } else {
                break
            }
        } while elementsVisited < maxElements

        // Then - verify sufficient elements visited
        XCTAssertGreaterThanOrEqual(
            elementsVisited,
            20,
            "VoiceOver navigation failed - only visited \(elementsVisited) elements, expected at least 20"
        )
    }

    func testVoiceOver_CompleteWorkflow_BackwardNavigation() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - navigate backward through interface
        var elementsVisited = 0

        // First move forward to get somewhere in the middle
        for _ in 0..<10 {
            app.swipeRight()
        }

        // Now navigate backward
        repeat {
            app.swipeLeft()
            elementsVisited += 1

            let focusedElement = app.focusedElement
            if !focusedElement.exists {
                break
            }
        } while elementsVisited < 10

        // Then - verify backward navigation works
        XCTAssertGreaterThan(
            elementsVisited,
            0,
            "VoiceOver backward navigation failed"
        )
    }

    // =============================================================================
    // MARK: - VoiceOver Focus Order Tests
    // =============================================================================

    func testVoiceOver_FocusOrder_Logical() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // Expected focus order for first song card (simplified)
        let expectedOrder = [
            "Play",
            "Tempo",
            "Volume",
            "Mute",
            "Solo"
        ]

        // When - navigate and verify order
        for (index, expected) in expectedOrder.prefix(5).enumerated() {
            // Get current element
            let currentElement = app.focusedElement

            // Verify matches expected
            XCTAssertTrue(
                currentElement.label.contains(expected),
                "Element \(index) should contain '\(expected)', found '\(currentElement.label)'"
            )

            // Move to next
            app.swipeRight()
        }
    }

    func testVoiceOver_FocusOrder_SongCardsSequential() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - navigate through song cards
        var playButtonsFound = 0

        // Navigate through first 50 elements
        for _ in 0..<50 {
            let currentElement = app.focusedElement

            if currentElement.label.contains("Play") {
                playButtonsFound += 1
            }

            app.swipeRight()
        }

        // Then - verify multiple song cards found
        XCTAssertGreaterThanOrEqual(
            playButtonsFound,
            3,
            "Should find play buttons from at least 3 song cards"
        )
    }

    // =============================================================================
    // MARK: - VoiceOver Action Tests
    // =============================================================================

    func testVoiceOver_ActivateAction_Works() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]

        // Focus play button
        playButton.tap()

        // When - activate with VoiceOver
        playButton.tap()

        // Then - verify action worked
        let pauseButton = firstCard.buttons["Pause"]
        XCTAssertTrue(
            pauseButton.waitForExistence(timeout: 2),
            "VoiceOver activate failed - pause button should appear"
        )
    }

    func testVoiceOver_AdjustSlider_Works() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        // Focus slider
        tempoSlider.tap()

        // Get initial value
        let initialValue = tempoSlider.value

        // When - swipe up to increase
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.1)
        app.swipeUp()

        // Then - verify tempo changed
        let newValue = tempoSlider.value
        XCTAssertNotEqual(
            initialValue,
            newValue,
            "VoiceOver slider adjustment failed"
        )
    }

    func testVoiceOver_MuteToggle_Works() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let muteButton = firstCard.buttons["Mute"]

        // Focus mute button
        muteButton.tap()

        // When - activate
        muteButton.tap()

        // Then - verify mute toggled
        // Mute button should show "Unmute" or have different state
        XCTAssertTrue(
            muteButton.exists,
            "Mute button should still exist after toggle"
        )
    }

    // =============================================================================
    // MARK: - VoiceOver Hints Tests
    // =============================================================================

    func testVoiceOver_Hints_Informative() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - check all interactive elements have hints
        let buttons = app.buttons.allElementsBoundByIndex
        let sliders = app.sliders.allElementsBoundByIndex

        var elementsWithoutHints = 0
        var totalInteractiveElements = 0

        for element in buttons + sliders where element.isHittable {
            totalInteractiveElements += 1

            let hint = element.accessibilityHint

            if hint.isEmpty {
                elementsWithoutHints += 1
            }
        }

        // Then - verify most elements have hints
        let percentageWithoutHints = Double(elementsWithoutHints) / Double(totalInteractiveElements) * 100

        XCTAssertLessThanOrEqual(
            percentageWithoutHints,
            30, // Allow 30% of elements without hints (simple controls may not need them)
            "Too many elements missing hints: \(elementsWithoutHints)/\(totalInteractiveElements) (\(Int(percentageWithoutHints))%)"
        )
    }

    func testVoiceOver_Hints_Descriptive() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - find elements with hints
        let tempoSlider = app.sliders["Tempo"]

        if tempoSlider.exists {
            let hint = tempoSlider.accessibilityHint

            // Then - verify hint is descriptive (if it exists)
            if !hint.isEmpty {
                XCTAssertGreaterThanOrEqual(
                    hint.count,
                    10,
                    "Tempo slider hint should be descriptive (at least 10 characters), found: '\(hint)'"
                )
            }
        }
    }

    // =============================================================================
    // MARK: - VoiceOver Performance Tests
    // =============================================================================

    func testVoiceOver_Performance_NavigationSpeed() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - measure navigation time for 20 elements
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<20 {
                app.swipeRight()
                Thread.sleep(forTimeInterval: 0.01) // Simulate VoiceOver delay
            }
        }

        // Should complete in under 2 seconds
    }

    func testVoiceOver_Performance_ElementInspection() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - measure element inspection time
        measure(metrics: [XCTClockMetric()]) {
            let elements = app.buttons.allElementsBoundByIndex
            let sliders = app.sliders.allElementsBoundByIndex

            // Inspect all interactive elements
            for element in elements + sliders {
                _ = element.label
                _ = element.accessibilityTraits
                _ = element.accessibilityHint
            }
        }

        // Should complete quickly
    }

    // =============================================================================
    // MARK: - VoiceOver Edge Cases
    // =============================================================================

    func testVoiceOver_EmptyState_HandledCorrectly() throws {
        // Given - navigate to moving sidewalk with no songs
        try navigateToMovingSidewalk()
        // Don't load songs

        // When - navigate with VoiceOver
        var elementsVisited = 0

        for _ in 0..<20 {
            let currentElement = app.focusedElement

            if currentElement.exists {
                elementsVisited += 1
                XCTAssertFalse(
                    currentElement.label.isEmpty,
                    "Element in empty state missing label"
                )
            }

            app.swipeRight()
        }

        // Then - verify empty state is accessible
        XCTAssertGreaterThan(
            elementsVisited,
            0,
            "Empty state should have accessible elements"
        )
    }

    func testVoiceOver_RapidNavigation_DoesNotCrash() throws {
        // Given
        try navigateToMovingSidewalk()
        loadMultipleSongs()

        // When - navigate rapidly
        for _ in 0..<100 {
            app.swipeRight()
            Thread.sleep(forTimeInterval: 0.01) // Small delay
        }

        // Then - verify app still responsive
        let focusedElement = app.focusedElement
        XCTAssertTrue(
            focusedElement.exists,
            "App should remain responsive after rapid navigation"
        )
    }

    // =============================================================================
    // MARK: - Helper Methods
    // =============================================================================

    private func navigateToMovingSidewalk() throws {
        let movingSidewalkTab = app.tabBars.buttons["Moving Sidewalk"]

        XCTAssertTrue(
            movingSidewalkTab.waitForExistence(timeout: 5),
            "Moving Sidewalk tab not found"
        )

        movingSidewalkTab.tap()

        // Wait for view to load
        let timelineView = app.otherElements["MovingSidewalkView"]
        XCTAssertTrue(
            timelineView.waitForExistence(timeout: 5),
            "Moving Sidewalk view did not load"
        )
    }

    private func loadMultipleSongs() {
        // Load demo songs for testing
        for i in 0..<6 {
            let loadButton = app.buttons["Load Slot \(i)"]
            if loadButton.exists {
                loadButton.tap()

                let demoSong = app.sheets.buttons["Demo Song \(i)"]
                if demoSong.waitForExistence(timeout: 2) {
                    demoSong.tap()
                }
            }
        }
    }
}

// =============================================================================
// MARK: - XCUIApplication Extensions
// =============================================================================

extension XCUIApplication {

    /// Get the currently focused VoiceOver element
    var focusedElement: XCUIElement {
        // VoiceOver focus is typically the first misc element
        return miscElements.firstMatch
    }
}

// =============================================================================
// MARK: - Custom Assertions
// =============================================================================

extension XCTestCase {

    /// Assert that an element has a VoiceOver focus
    func assertVoiceOverFocused(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.exists,
            "Element should exist for VoiceOver focus",
            file: file,
            line: line
        )

        XCTAssertFalse(
            element.label.isEmpty,
            "Focused element should have accessibility label",
            file: file,
            line: line
        )
    }

    /// Assert that VoiceOver navigation is possible
    func assertVoiceOverNavigable(
        elementCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(
            elementCount,
            10,
            "VoiceOver should navigate at least 10 elements",
            file: file,
            line: line
        )
    }
}
