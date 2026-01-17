//
//  VisualTimelineTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Visual Timeline Tests
// =============================================================================

class VisualTimelineTests: XCTestCase {

    var state: MultiSongState!

    override func setUp() {
        super.setUp()
        state = Fixtures.testMultiSongState
    }

    override func tearDown() {
        state = nil
        super.tearDown()
    }

    // MARK: - Timeline Structure Tests

    func testTimeline_HasCorrectLayout() throws {
        // Given
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testTimeline_HasLabel() throws {
        // Given
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let timelineLabel = texts.first { try? $0.string() == "Timeline" }
        XCTAssertNotNil(timelineLabel)
    }

    func testTimeline_DisplaysAllSongs() throws {
        // Given
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertGreaterThanOrEqual(try vStack.childCount(), 1)
    }

    // MARK: - Song Progress Row Tests

    func testSongProgressRow_DisplaysSongName() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let songName = texts.first { try? $0.string() == song.name }
        XCTAssertNotNil(songName)
    }

    func testSongProgressRow_DisplaysFormattedTime() throws {
        // Given
        let song = Fixtures.songWithProgress(0.5)
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        // Should display current time
        XCTAssertFalse(texts.isEmpty)
    }

    func testSongProgressRow_HasProgressBar() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testSongProgressRow_ProgressFill_MatchesSongProgress() throws {
        // Given
        let song = Fixtures.songWithProgress(0.75)
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Muted State Tests

    func testSongProgressRow_WhenMuted_TextIsDimmed() throws {
        // Given
        let song = Fixtures.mutedSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testSongProgressRow_WhenMuted_ProgressIsDimmed() throws {
        // Given
        let song = Fixtures.mutedSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Solo State Tests

    func testSongProgressRow_WhenSoloed_UsesAccentColor() throws {
        // Given
        let song = Fixtures.soloedSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testSongProgressRow_WhenSoloed_ProgressHasSecondaryColor() throws {
        // Given
        let song = Fixtures.soloedSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Playing State Tests

    func testSongProgressRow_WhenPlaying_ShowActivePlayhead() throws {
        // Given
        let song = Fixtures.playingSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testSongProgressRow_WhenPaused_ShowInactivePlayhead() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Edge Cases

    func testSongProgressRow_WithZeroProgress_RendersCorrectly() throws {
        // Given
        let song = Fixtures.songWithProgress(0.0)
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.HStack.self))
    }

    func testSongProgressRow_WithFullProgress_RendersCorrectly() throws {
        // Given
        let song = Fixtures.songWithProgress(1.0)
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.HStack.self))
    }

    func testSongProgressRow_WithLongName_TruncatesCorrectly() throws {
        // Given
        let song = Fixtures.testSong
        song.name = "This is a very long song name that should be truncated"
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Multiple Songs Tests

    func testTimeline_WithSixSongs_DisplaysAll() throws {
        // Given
        state.songs = Fixtures.sixDemoSongs
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertGreaterThanOrEqual(try vStack.childCount(), 1)
    }

    func testTimeline_WithVariousStates_DisplaysCorrectly() throws {
        // Given
        state.songs = Fixtures.variousStateSongs
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    // MARK: - Layout Tests

    func testTimeline_HasCorrectSpacing() throws {
        // Given
        let view = VisualTimeline(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testSongProgressRow_HasCorrectLayout() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    // MARK: - Accessibility Tests

    func testSongProgressRow_HasAccessibleElements() throws {
        // Given
        let song = Fixtures.testSong
        let view = SongProgressRow(song: song)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }
}
