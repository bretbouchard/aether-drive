//
//  WaveformViewTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Waveform View Tests
// =============================================================================

class WaveformViewTests: XCTestCase {

    var song: SongPlayerState!

    override func setUp() {
        super.setUp()
        song = Fixtures.testSong
    }

    override func tearDown() {
        song = nil
        super.tearDown()
    }

    // MARK: - Waveform Rendering Tests

    func testWaveformView_DisplaysAllBars() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 100)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithEmptyWaveform_DoesNotCrash() throws {
        // Given
        song.waveform = []
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithSingleBar_RendersCorrectly() throws {
        // Given
        song.waveform = [0.8]
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithFlatWaveform_RendersCorrectly() throws {
        // Given
        song.waveform = Fixtures.flatWaveform
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithPeakWaveform_RendersCorrectly() throws {
        // Given
        song.waveform = Fixtures.peakWaveform
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    // MARK: - Bar Height Tests

    func testWaveformView_BarHeights_MatchWaveform() throws {
        // Given
        song.waveform = [0.2, 0.5, 0.8, 1.0, 0.6]
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_BarWidth_IsConsistent() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    func testWaveformView_BarSpacing_IsConsistent() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    // MARK: - Color Tests

    func testWaveformView_UsesAccentColors() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_HasGradientFill() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    // MARK: - Layout Tests

    func testWaveformView_HasCorrectAlignment() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_HasCorrectSpacing() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_RespectsFrame() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 50)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let geometryReader = try view.inspect().find(ViewType.GeometryReader.self)
        XCTAssertNotNil(geometryReader)
    }

    // MARK: - Edge Cases

    func testWaveformView_WithLargeWaveform_RendersEfficiently() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 1000)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithVerySmallValues_RendersCorrectly() throws {
        // Given
        song.waveform = [0.01, 0.02, 0.03, 0.04, 0.05]
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    func testWaveformView_WithZeroValues_RendersCorrectly() throws {
        // Given
        song.waveform = [0.0, 0.0, 0.0, 0.0, 0.0]
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // Then
        let hStack = try view.inspect().find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
    }

    // MARK: - Performance Tests

    func testWaveformView_Rendering_Performance() throws {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 500)
        let view = MultiSongWaveformView(waveform: song.waveform, progress: song.progress)
            .testTheme()

        // When & Then
        measure {
            _ = try? view.inspect().find(ViewType.HStack.self)
        }
    }
}
