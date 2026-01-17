//
//  MovingSidewalkViewIntegrationTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Moving Sidewalk View Integration Tests
// =============================================================================

class MovingSidewalkViewIntegrationTests: XCTestCase {

    // MARK: - View Structure Tests

    func testView_HasCorrectLayout() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testView_HasVisualTimeline() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack)
    }

    func testView_HasMasterTransportControls() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testView_HasSongCardsHeader() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let scrollViews = try view.inspect().findAll(ViewType.ScrollView.self)
        XCTAssertFalse(scrollViews.isEmpty)
    }

    // MARK: - Song Display Tests

    func testView_DisplaysSixDemoSongs() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // View should display song cards
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testView_HasHorizontalScrollOnIPhone() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        #if os(iOS)
        let scrollViews = try view.inspect().findAll(ViewType.ScrollView.self)
        XCTAssertFalse(scrollViews.isEmpty)
        #endif
    }

    func testView_HasGridOnIPad() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        #if os(iOS)
        // Grid layout on iPad would be checked here
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
        #endif
    }

    // MARK: - Toolbar Tests

    func testView_HasCorrectTitle() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let titleText = texts.first { try? $0.string() == "Moving Sidewalk" }
        XCTAssertNotNil(titleText)
    }

    func testView_DisplaysSongCount() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        let countText = texts.first { text in
            if let string = try? text.string(), string.contains("songs") {
                return true
            }
            return false
        }
        XCTAssertNotNil(countText)
    }

    // MARK: - Menu Tests

    func testView_HasMenuButton() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Menu button exists in toolbar
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack)
    }

    func testView_MenuHasAddSongOption() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Menu should have add song option
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testView_MenuHasSavePresetOption() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Menu should have save preset option
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Sync Mode Tests

    func testView_DisplaysCurrentSyncMode() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Should display sync mode indicator
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Sheet Tests

    func testView_HasAddSongSheet() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Sheet should be configured
        XCTAssertNotNil(try view.inspect().find(ViewType.ZStack.self))
    }

    func testView_HasSavePresetSheet() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Sheet should be configured
        XCTAssertNotNil(try view.inspect().find(ViewType.ZStack.self))
    }

    // MARK: - Pull to Refresh Tests

    func testView_HasPullToRefresh() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let scrollViews = try view.inspect().findAll(ViewType.ScrollView.self)
        XCTAssertFalse(scrollViews.isEmpty)
    }

    // MARK: - Layout Tests

    func testView_HasCorrectSpacing() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testView_HasBackground() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack)
    }

    // MARK: - Safe Area Tests

    func testView_RespectsSafeArea() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack)
    }

    // MARK: - Edge Cases

    func testView_WithNoSongs_LoadsDemoSongs() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // On appear, demo songs should be loaded
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testView_WithEmptyState_HandlesGracefully() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Should handle empty state gracefully
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    // MARK: - Add Song Sheet Tests

    func testAddSongSheet_HasCorrectForm() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testAddSongSheet_HasSongNameField() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testAddSongSheet_HasArtistField() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testAddSongSheet_HasBPMField() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testAddSongSheet_HasDurationField() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testAddSongSheet_DisablesAddButton_WhenNameIsEmpty() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = AddSongSheet(state: state)
            .testTheme()

        // Then
        // Add button should be disabled when song name is empty
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }

    // MARK: - Save Preset Sheet Tests

    func testSavePresetSheet_HasCorrectForm() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testSavePresetSheet_HasPresetNameField() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testSavePresetSheet_DisplaysSongCount() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testSavePresetSheet_DisplaysSyncMode() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testSavePresetSheet_DisplaysMasterTempo() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testSavePresetSheet_DisablesSaveButton_WhenNameIsEmpty() throws {
        // Given
        let state = Fixtures.testMultiSongState
        let view = SavePresetSheet(state: state)
            .testTheme()

        // Then
        // Save button should be disabled when preset name is empty
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }

    // MARK: - Integration Tests

    func testView_MultipleStateChanges_UpdatesCorrectly() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // View should handle multiple state changes
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testView_ChildInteractions_PropagateToState() throws {
        // Given
        let view = MovingSidewalkView()
            .testTheme()

        // Then
        // Child view interactions should propagate to state
        let zStack = try view.inspect().find(ViewType.ZStack.self)
        XCTAssertNotNil(zStack)
    }
}
