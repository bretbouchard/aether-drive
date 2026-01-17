//
//  DynamicTypeSnapshotTests.swift
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
 Snapshot tests for Dynamic Type (accessibility text sizing) support.

 Tests cover:
 - Extra small to extra extra extra large text sizes
 - Accessibility size categories
 - Layout adaptability at different sizes
 - Text truncation and wrapping behavior
 */
class DynamicTypeSnapshotTests: XCTestCase {

    // MARK: - Configuration

    let isRecording = false

    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    // MARK: - Song Player Card - Dynamic Type

    func testSongPlayerCard_ExtraSmallText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .extraSmall)
            .frame(width: 350, height: 250)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_extra_small_text"
        )
    }

    func testSongPlayerCard_SmallText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .small)
            .frame(width: 350, height: 250)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_small_text"
        )
    }

    func testSongPlayerCard_MediumText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .medium)
            .frame(width: 350, height: 250)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_medium_text"
        )
    }

    func testSongPlayerCard_LargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .large)
            .frame(width: 350, height: 280)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_large_text"
        )
    }

    func testSongPlayerCard_ExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .extraLarge)
            .frame(width: 350, height: 300)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_extra_large_text"
        )
    }

    func testSongPlayerCard_ExtraExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .extraExtraLarge)
            .frame(width: 350, height: 320)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_xxlarge_text"
        )
    }

    func testSongPlayerCard_ExtraExtraExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            .frame(width: 350, height: 350)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_xxxlarge_text"
        )
    }

    func testSongPlayerCard_AccessibilityMediumText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityMedium)
            .frame(width: 350, height: 400)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_a11y_medium_text"
        )
    }

    func testSongPlayerCard_AccessibilityLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityLarge)
            .frame(width: 350, height: 450)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_a11y_large_text"
        )
    }

    func testSongPlayerCard_AccessibilityExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .frame(width: 350, height: 500)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_a11y_extra_large_text"
        )
    }

    func testSongPlayerCard_AccessibilityExtraExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
            .frame(width: 350, height: 550)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_a11y_xxlarge_text"
        )
    }

    func testSongPlayerCard_AccessibilityExtraExtraExtraLargeText() {
        // Given
        let slot = Fixtures.testSongSlot
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .frame(width: 350, height: 600)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_a11y_xxxlarge_text"
        )
    }

    // MARK: - Moving Sidewalk View - Dynamic Type

    func testMovingSidewalkView_AccessibilityMediumText() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .environment(\.sizeCategory, .accessibilityMedium)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_a11y_medium"
        )
    }

    func testMovingSidewalkView_AccessibilityLargeText() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .environment(\.sizeCategory, .accessibilityLarge)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_a11y_large"
        )
    }

    func testMovingSidewalkView_AccessibilityExtraLargeText() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = configureView(state: state)
            .environment(\.sizeCategory, .accessibilityExtraLarge)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(precision: 0.95, layout: .device(config: .iPhone13Pro)),
            named: "moving_sidewalk_a11y_extra_large"
        )
    }

    // MARK: - Master Transport Controls - Dynamic Type

    func testMasterTransportControls_AccessibilityLargeText() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityLarge)
            .frame(width: 350, height: 120)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_a11y_large"
        )
    }

    func testMasterTransportControls_AccessibilityExtraLargeText() {
        // Given
        let state = Fixtures.testMultiSongState
        let view = MasterTransportControls(state: state)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .frame(width: 350, height: 150)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "master_transport_a11y_extra_large"
        )
    }

    // MARK: - Text Truncation Tests

    func testSongPlayerCard_LongTextWithExtraSmallSize() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.songName = "This is a very long song name that should truncate"
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .extraSmall)
            .frame(width: 300, height: 200)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_long_text_small_size"
        )
    }

    func testSongPlayerCard_LongTextWithAccessibilitySize() {
        // Given
        var slot = Fixtures.testSongSlot
        slot.songName = "This is a very long song name that should wrap"
        let view = SongPlayerCard(song: slot)
            .environment(\.theme, Theme.default)
            .environment(\.sizeCategory, .accessibilityLarge)
            .frame(width: 400, height: 500)

        // Then
        assertSnapshot(
            matching: view,
            as: .image(layout: .sizeThatFits),
            named: "song_card_long_text_a11y_size"
        )
    }

    // MARK: - Helper Methods

    private func configureView(state: MultiSongState) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Visual timeline placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 60)
                        .overlay(
                            Text("Timeline")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                        .padding(.horizontal, 16)

                    // Song cards
                    LazyVStack(spacing: 12) {
                        ForEach(state.songs.prefix(3)) { song in
                            SongPlayerCard(song: song)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Master transport
                    MasterTransportControls(state: state)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 200)
            }
        }
        .environment(\.theme, Theme.default)
    }
}
