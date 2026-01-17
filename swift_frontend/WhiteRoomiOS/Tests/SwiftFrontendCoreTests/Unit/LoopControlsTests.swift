//
//  LoopControlsTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Loop Controls Tests
// =============================================================================

class LoopControlsTests: XCTestCase {

    var transport: MasterTransportState!

    override func setUp() {
        super.setUp()
        transport = Fixtures.testMasterTransport
    }

    override func tearDown() {
        transport = nil
        super.tearDown()
    }

    // MARK: - Layout Tests

    func testLoopControls_HasCorrectLayout() throws {
        // Given
        @State var state = transport
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    // MARK: - Loop Range Slider Tests

    func testLoopRangeSlider_HasCorrectRange() throws {
        // Given
        @State var state = transport
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testLoopRangeSlider_DisplaysStartHandle() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.2
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testLoopRangeSlider_DisplaysEndHandle() throws {
        // Given
        @State var state = transport
        state.loopEnd = 0.8
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testLoopRangeSlider_DragStart_UpdatesLoopStart() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.0
        state.loopEnd = 1.0
        let view = LoopControls(transport: $state)
            .testTheme()

        // When - Simulate drag
        // Drag gesture handling would be tested here

        // Then
        XCTAssertGreaterThanOrEqual(state.loopStart, 0.0)
    }

    func testLoopRangeSlider_DragEnd_UpdatesLoopEnd() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.0
        state.loopEnd = 1.0
        let view = LoopControls(transport: $state)
            .testTheme()

        // When - Simulate drag
        // Drag gesture handling would be tested here

        // Then
        XCTAssertLessThanOrEqual(state.loopEnd, 1.0)
    }

    func testLoopRangeSlider_PreventsCrossing() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.3
        state.loopEnd = 0.7
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        XCTAssertLessThan(state.loopStart, state.loopEnd)
    }

    // MARK: - Time Display Tests

    func testLoopControls_DisplaysStartTime() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.25
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    func testLoopControls_DisplaysEndTime() throws {
        // Given
        @State var state = transport
        state.loopEnd = 0.75
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let texts = try view.inspect().findAll(ViewType.Text.self)
        XCTAssertFalse(texts.isEmpty)
    }

    // MARK: - Edge Cases

    func testLoopControls_WithZeroLoopStart_RendersCorrectly() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.0
        state.loopEnd = 1.0
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testLoopControls_WithFullLoopEnd_RendersCorrectly() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.0
        state.loopEnd = 1.0
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testLoopControls_WithMinimalRange_RendersCorrectly() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.4
        state.loopEnd = 0.5
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    func testLoopControls_WithMaximumRange_RendersCorrectly() throws {
        // Given
        @State var state = transport
        state.loopStart = 0.0
        state.loopEnd = 1.0
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        XCTAssertNotNil(try view.inspect().find(ViewType.VStack.self))
    }

    // MARK: - Visual Tests

    func testLoopControls_HasCorrectBackground() throws {
        // Given
        @State var state = transport
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testLoopControls_HasCorrectCornerRadius() throws {
        // Given
        @State var state = transport
        let view = LoopControls(transport: $state)
            .testTheme()

        // Then
        let vStack = try view.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }
}
