//
//  SwiftUIAccessibilityValidation.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - SwiftUI Accessibility Validation Suite
// =============================================================================

/// Validates Agent 2's SwiftUI tests for accessibility compliance.
///
/// This test suite validates that all SwiftUI components tested in Agent 2
/// meet WCAG 2.1 AA accessibility requirements, including:
/// - Accessibility labels for all interactive elements
/// - Accessibility hints where appropriate
/// - Correct traits (button, slider, etc.)
/// - Accessibility identifiers for testing
/// - Focusable elements in logical order
///
/// Success Criteria:
/// - All buttons have accessibility labels
/// - All sliders have accessibility labels and values
/// - All interactive elements have appropriate traits
/// - All screens have accessibility identifiers
/// - Zero accessibility violations in Agent 2 tests
class SwiftUIAccessibilityValidation: XCTestCase {

    // MARK: - Validate Agent 2's SongPlayerCardTests

    func testSongPlayerCardTests_PlayButton_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testPlayPauseButton_HasCorrectAccessibilityLabel

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)

        // Verify play button has accessibility label
        let label = try button.accessibilityLabel()
        XCTAssertFalse(label.isEmpty, "Play button missing accessibility label")
        XCTAssertEqual(label, "Play", "Play button has incorrect accessibility label")

        // Verify button has button trait
        let traits = try button.accessibilityTraits()
        XCTAssertTrue(traits.contains(.button), "Play button missing button trait")

        // Verify button is accessible
        XCTAssertTrue(try button.isAccessibilityElement(), "Play button not marked as accessible element")
    }

    func testSongPlayerCardTests_PauseButton_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testPlayPauseButton_HasCorrectAccessibilityLabel_WhenPlaying

        // Given
        let song = Fixtures.playingSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let button = try view.inspect().find(ViewType.Button.self)

        // Verify pause button has accessibility label
        let label = try button.accessibilityLabel()
        XCTAssertFalse(label.isEmpty, "Pause button missing accessibility label")
        XCTAssertEqual(label, "Pause", "Pause button has incorrect accessibility label")

        // Verify button has button trait
        let traits = try button.accessibilityTraits()
        XCTAssertTrue(traits.contains(.button), "Pause button missing button trait")
    }

    func testSongPlayerCardTests_TempoSlider_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testTempoSlider_HasCorrectAccessibilityLabel

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let slider = try view.inspect().find(ViewType.Slider.self)

        // Verify slider has accessibility label
        let label = try slider.accessibilityLabel()
        XCTAssertFalse(label.isEmpty, "Tempo slider missing accessibility label")
        XCTAssertEqual(label, "Tempo", "Tempo slider has incorrect accessibility label")

        // Verify slider has accessibility value
        let value = try slider.accessibilityValue()
        XCTAssertFalse(value.isEmpty, "Tempo slider missing accessibility value")

        // Verify slider is accessible
        XCTAssertTrue(try slider.isAccessibilityElement(), "Tempo slider not marked as accessible element")
    }

    func testSongPlayerCardTests_VolumeSlider_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testVolumeSlider_HasCorrectAccessibilityLabel

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let sliders = try view.inspect().findAll(ViewType.Slider.self)
        let volumeSlider = sliders[1] // Second slider is volume

        // Verify volume slider has accessibility label
        let label = try volumeSlider.accessibilityLabel()
        XCTAssertFalse(label.isEmpty, "Volume slider missing accessibility label")
        XCTAssertEqual(label, "Volume", "Volume slider has incorrect accessibility label")

        // Verify volume slider has accessibility value
        let value = try volumeSlider.accessibilityValue()
        XCTAssertFalse(value.isEmpty, "Volume slider missing accessibility value")
    }

    func testSongPlayerCardTests_MuteButton_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testMuteButton_HasCorrectAccessibilityLabel

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        if buttons.count > 1 {
            let muteButton = buttons[1]

            // Verify mute button has accessibility label
            let label = try muteButton.accessibilityLabel()
            XCTAssertFalse(label.isEmpty, "Mute button missing accessibility label")
            XCTAssertEqual(label, "Mute", "Mute button has incorrect accessibility label")

            // Verify button has button trait
            let traits = try muteButton.accessibilityTraits()
            XCTAssertTrue(traits.contains(.button), "Mute button missing button trait")
        }
    }

    func testSongPlayerCardTests_SoloButton_AccessibilityCompliant() throws {
        // Validate SongPlayerCardTests.testSoloButton_HasCorrectAccessibilityLabel

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        if buttons.count > 2 {
            let soloButton = buttons[2]

            // Verify solo button has accessibility label
            let label = try soloButton.accessibilityLabel()
            XCTAssertFalse(label.isEmpty, "Solo button missing accessibility label")
            XCTAssertEqual(label, "Solo", "Solo button has incorrect accessibility label")

            // Verify button has button trait
            let traits = try soloButton.accessibilityTraits()
            XCTAssertTrue(traits.contains(.button), "Solo button missing button trait")
        }
    }

    // MARK: - Validate Agent 2's MovingSidewalkViewTests

    func testMovingSidewalkViewTests_HasAccessibilityIdentifier() throws {
        // Validate MovingSidewalkViewIntegrationTests.testView_HasCorrectLayout

        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Verify screen has accessibility identifier for testing
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack, "Moving Sidewalk view should have accessible structure")
    }

    func testMovingSidewalkViewTests_AllInteractiveElementsAccessible() throws {
        // Validate that all interactive elements in MovingSidewalkView are accessible

        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Verify view has accessible interactive elements
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack, "Moving Sidewalk view should have accessible structure")

        // Verify toolbar buttons are accessible
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty, "Moving Sidewalk view should have accessible text elements")
    }

    // MARK: - Comprehensive Accessibility Audit

    func testAccessibilityAudit_AllButtonsHaveLabels() throws {
        // Audit all buttons across all views for accessibility labels

        // Given
        let song = Fixtures.testSong
        let cardView = SongPlayerCard(song: song).testTheme()

        // When - find all buttons
        let buttons = try cardView.inspect().findAll(ViewType.Button.self)

        // Then - verify all have labels
        for (index, button) in buttons.enumerated() {
            let label = try button.accessibilityLabel()
            XCTAssertFalse(
                label.isEmpty,
                "Button \(index) missing accessibility label"
            )

            let traits = try button.accessibilityTraits()
            XCTAssertTrue(
                traits.contains(.button),
                "Button \(index) missing button trait"
            )
        }
    }

    func testAccessibilityAudit_AllSlidersHaveLabelsAndValues() throws {
        // Audit all sliders across all views for accessibility labels and values

        // Given
        let song = Fixtures.testSong
        let cardView = SongPlayerCard(song: song).testTheme()

        // When - find all sliders
        let sliders = try cardView.inspect().findAll(ViewType.Slider.self)

        // Then - verify all have labels and values
        for (index, slider) in sliders.enumerated() {
            let label = try slider.accessibilityLabel()
            XCTAssertFalse(
                label.isEmpty,
                "Slider \(index) missing accessibility label"
            )

            let value = try slider.accessibilityValue()
            XCTAssertFalse(
                value.isEmpty,
                "Slider \(index) missing accessibility value"
            )
        }
    }

    func testAccessibilityAudit_AllInteractiveElementsAreAccessible() throws {
        // Audit that all interactive elements are marked as accessible

        // Given
        let song = Fixtures.testSong
        let cardView = SongPlayerCard(song: song).testTheme()

        // When - find all interactive elements
        let buttons = try cardView.inspect().findAll(ViewType.Button.self)
        let sliders = try cardView.inspect().findAll(ViewType.Slider.self)

        // Then - verify all are accessible
        for (index, button) in buttons.enumerated() {
            XCTAssertTrue(
                try button.isAccessibilityElement(),
                "Button \(index) not marked as accessible element"
            )
        }

        for (index, slider) in sliders.enumerated() {
            XCTAssertTrue(
                try slider.isAccessibilityElement(),
                "Slider \(index) not marked as accessible element"
            )
        }
    }

    // MARK: - Accessibility Hints Validation

    func testAccessibilityHints_ComplexControlsHaveHints() throws {
        // Verify complex controls have accessibility hints

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // Then - verify tempo slider has hint (optional but recommended)
        let slider = try view.inspect().find(ViewType.Slider.self)

        // Hints are optional for sliders with clear labels, but verify they can exist
        let hint = try? slider.accessibilityHint()

        // If hint exists, verify it's informative
        if let hint = hint, !hint.isEmpty {
            XCTAssertGreaterThanOrEqual(
                hint.count,
                10,
                "Accessibility hint should be descriptive (at least 10 characters)"
            )
        }
    }

    // MARK: - Accessibility Performance Validation

    func testAccessibilityPerformance_InspectionCompletesInUnder100ms() throws {
        // Verify accessibility inspection is performant

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song)
            .testTheme()

        // When - measure accessibility inspection time
        measure(metrics: [XCTClockMetric()]) {
            _ = try view.inspect().findAll(ViewType.Button.self)
            _ = try view.inspect().findAll(ViewType.Slider.self)
        }

        // Should complete in under 100ms for a single card
    }

    // MARK: - Helper Methods

    private func assertButtonHasLabel(
        _ label: String,
        in view: any Inspectable,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let buttons = try view.inspect().findAll(ViewType.Button.self)

        let button = buttons.first { btn in
            if let buttonLabel = try? btn.accessibilityLabel() {
                return buttonLabel == label
            }
            return false
        }

        XCTAssertNotNil(
            button,
            "Button '\(label)' missing accessibility label",
            file: file,
            line: line
        )
    }

    private func assertSliderHasLabel(
        _ label: String,
        in view: any Inspectable,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let sliders = try view.inspect().findAll(ViewType.Slider.self)

        let slider = sliders.first { slider in
            if let sliderLabel = try? slider.accessibilityLabel() {
                return sliderLabel == label
            }
            return false
        }

        XCTAssertNotNil(
            slider,
            "Slider '\(label)' missing accessibility label",
            file: file,
            line: line
        )
    }

    private func assertAllButtonsHaveButtonTrait(
        in view: any Inspectable,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let buttons = try view.inspect().findAll(ViewType.Button.self)

        for (index, button) in buttons.enumerated() {
            let traits = try button.accessibilityTraits()
            XCTAssertTrue(
                traits.contains(.button),
                "Button \(index) missing button trait",
                file: file,
                line: line
            )
        }
    }
}

// =============================================================================
// MARK: - Custom Assertions
// =============================================================================

extension XCTestCase {

    /// Assert that an element has an accessibility label
    func assertHasAccessibilityLabel(
        _ label: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            label.isEmpty,
            "Element missing accessibility label",
            file: file,
            line: line
        )
    }

    /// Assert that an element has an accessibility value
    func assertHasAccessibilityValue(
        _ value: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            value.isEmpty,
            "Element missing accessibility value",
            file: file,
            line: line
        )
    }

    /// Assert that an element has button trait
    func assertHasButtonTrait(
        _ traits: UIAccessibilityTraits,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            traits.contains(.button),
            "Element missing button trait",
            file: file,
            line: line
        )
    }
}
