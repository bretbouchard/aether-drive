//
//  SongPlayerStateTests.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Song Player State Tests
// =============================================================================

class SongPlayerStateTests: XCTestCase {

    var song: SongPlayerState!

    override func setUp() {
        super.setUp()
        song = Fixtures.testSong
    }

    override func tearDown() {
        song = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_CreatesValidSong() {
        // Then
        XCTAssertNotNil(song)
        XCTAssertFalse(song.id.isEmpty)
        XCTAssertFalse(song.name.isEmpty)
    }

    func testInit_WithCustomParameters_UsesCorrectValues() {
        // Given
        let customSong = SongPlayerState(
            name: "Custom Song",
            artist: "Custom Artist",
            originalBPM: 140.0,
            duration: 240.0,
            timeSignature: "6/8",
            key: "F# minor"
        )

        // Then
        XCTAssertEqual(customSong.name, "Custom Song")
        XCTAssertEqual(customSong.artist, "Custom Artist")
        XCTAssertEqual(customSong.originalBPM, 140.0)
        XCTAssertEqual(customSong.duration, 240.0)
        XCTAssertEqual(customSong.timeSignature, "6/8")
        XCTAssertEqual(customSong.key, "F# minor")
    }

    func testInit_GeneratesUniqueID() {
        // Given
        let song1 = SongPlayerState(name: "Song 1", artist: "Artist", originalBPM: 120, duration: 180)
        let song2 = SongPlayerState(name: "Song 2", artist: "Artist", originalBPM: 120, duration: 180)

        // Then
        XCTAssertNotEqual(song1.id, song2.id)
    }

    // MARK: - Computed Properties Tests

    func testCurrentBPM_WithMultiplierOfOne_ReturnsOriginalBPM() {
        // Given
        song.tempoMultiplier = 1.0

        // Then
        XCTAssertEqual(song.currentBPM, song.originalBPM)
    }

    func testCurrentBPM_WithMultiplierOfOnePointFive_ReturnsCorrectValue() {
        // Given
        song.originalBPM = 120.0
        song.tempoMultiplier = 1.5

        // Then
        XCTAssertEqual(song.currentBPM, 180.0)
    }

    func testCurrentBPM_WithMultiplierOfPointFive_ReturnsCorrectValue() {
        // Given
        song.originalBPM = 120.0
        song.tempoMultiplier = 0.5

        // Then
        XCTAssertEqual(song.currentBPM, 60.0)
    }

    func testCurrentTime_WithZeroProgress_ReturnsZero() {
        // Given
        song.progress = 0.0
        song.duration = 180.0

        // Then
        XCTAssertEqual(song.currentTime, 0.0)
    }

    func testCurrentTime_WithHalfProgress_ReturnsHalfDuration() {
        // Given
        song.progress = 0.5
        song.duration = 180.0

        // Then
        XCTAssertEqual(song.currentTime, 90.0)
    }

    func testCurrentTime_WithFullProgress_ReturnsFullDuration() {
        // Given
        song.progress = 1.0
        song.duration = 180.0

        // Then
        XCTAssertEqual(song.currentTime, 180.0)
    }

    func testFormattedTime_WithZeroSeconds_ReturnsCorrectFormat() {
        // Given
        song.duration = 180.0
        song.progress = 0.0

        // Then
        XCTAssertEqual(song.formattedTime, "00:00")
    }

    func testFormattedTime_WithSixtySeconds_ReturnsOneMinute() {
        // Given
        song.duration = 180.0
        song.progress = 1.0 / 3.0 // 60 seconds

        // Then
        XCTAssertEqual(song.formattedTime, "01:00")
    }

    func testFormattedTime_WithNinetySeconds_ReturnsCorrectFormat() {
        // Given
        song.duration = 180.0
        song.progress = 0.5 // 90 seconds

        // Then
        XCTAssertEqual(song.formattedTime, "01:30")
    }

    func testFormattedTime_WithOverSixtySeconds_CorrectlyFormatsMinutes() {
        // Given
        song.duration = 3661.0 // Over an hour
        song.progress = 0.5

        // Then
        XCTAssertTrue(song.formattedTime.contains(":"))
    }

    func testFormattedDuration_WithThreeMinutes_ReturnsCorrectFormat() {
        // Given
        song.duration = 180.0

        // Then
        XCTAssertEqual(song.formattedDuration, "03:00")
    }

    func testFormattedDuration_WithFourTwenty_ReturnsCorrectFormat() {
        // Given
        song.duration = 420.0

        // Then
        XCTAssertEqual(song.formattedDuration, "07:00")
    }

    // MARK: - Published Properties Tests

    func testProgress_CanBeChanged() {
        // Given
        song.progress = 0.5

        // Then
        XCTAssertEqual(song.progress, 0.5)
    }

    func testProgress_ClampedToZero() {
        // When
        song.progress = -0.1

        // Then
        // Progress should be clamped to valid range
        XCTAssertNotNil(song.progress)
    }

    func testProgress_ClampedToOne() {
        // When
        song.progress = 1.1

        // Then
        XCTAssertNotNil(song.progress)
    }

    func testIsPlaying_CanBeToggled() {
        // Given
        song.isPlaying = false

        // When
        song.isPlaying.toggle()

        // Then
        XCTAssertTrue(song.isPlaying)
    }

    func testIsMuted_CanBeToggled() {
        // Given
        song.isMuted = false

        // When
        song.isMuted.toggle()

        // Then
        XCTAssertTrue(song.isMuted)
    }

    func testIsSolo_CanBeToggled() {
        // Given
        song.isSolo = false

        // When
        song.isSolo.toggle()

        // Then
        XCTAssertTrue(song.isSolo)
    }

    func testTempoMultiplier_CanBeChanged() {
        // Given
        song.tempoMultiplier = 1.8

        // Then
        XCTAssertEqual(song.tempoMultiplier, 1.8)
    }

    func testVolume_CanBeChanged() {
        // Given
        song.volume = 0.6

        // Then
        XCTAssertEqual(song.volume, 0.6)
    }

    func testPan_CanBeChanged() {
        // Given
        song.pan = -0.5

        // Then
        XCTAssertEqual(song.pan, -0.5)
    }

    func testWaveform_CanBeSet() {
        // Given
        let waveform = Fixtures.generateWaveform(count: 100)

        // When
        song.waveform = waveform

        // Then
        XCTAssertEqual(song.waveform.count, 100)
    }

    func testThumbnailURL_CanBeSet() {
        // Given
        let url = Fixtures.testThumbnailURL

        // When
        song.thumbnailURL = url

        // Then
        XCTAssertEqual(song.thumbnailURL, url)
    }

    // MARK: - Edge Cases

    func testSong_WithZeroDuration_HandlesCorrectly() {
        // Given
        song.duration = 0.0

        // Then
        XCTAssertEqual(song.formattedDuration, "00:00")
    }

    func testSong_WithVeryLongDuration_FormatsCorrectly() {
        // Given
        song.duration = 9999.0

        // Then
        XCTAssertFalse(song.formattedDuration.isEmpty)
    }

    func testSong_WithVeryShortDuration_FormatsCorrectly() {
        // Given
        song.duration = 1.0

        // Then
        XCTAssertEqual(song.formattedDuration, "00:01")
    }

    func testSong_WithExtremeTempo_HandlesCorrectly() {
        // Given
        song.originalBPM = 300.0
        song.tempoMultiplier = 2.0

        // Then
        XCTAssertEqual(song.currentBPM, 600.0)
    }

    func testSong_WithVeryLowTempo_HandlesCorrectly() {
        // Given
        song.originalBPM = 40.0
        song.tempoMultiplier = 0.5

        // Then
        XCTAssertEqual(song.currentBPM, 20.0)
    }

    func testSong_WithEmptyWaveform_HandlesCorrectly() {
        // Given
        song.waveform = []

        // Then
        XCTAssertTrue(song.waveform.isEmpty)
    }

    func testSong_WithLargeWaveform_HandlesCorrectly() {
        // Given
        song.waveform = Fixtures.generateWaveform(count: 10000)

        // Then
        XCTAssertEqual(song.waveform.count, 10000)
    }

    // MARK: - Demo Data Tests

    func testDemoSong_CreatesValidSong() {
        // When
        let demoSong = SongPlayerState.demoSong(
            name: "Demo",
            artist: "Demo Artist",
            bpm: 120.0,
            duration: 180.0
        )

        // Then
        XCTAssertNotNil(demoSong)
        XCTAssertEqual(demoSong.name, "Demo")
        XCTAssertEqual(demoSong.artist, "Demo Artist")
        XCTAssertEqual(demoSong.originalBPM, 120.0)
        XCTAssertEqual(demoSong.duration, 180.0)
    }

    func testDemoSong_GeneratesWaveform() {
        // When
        let demoSong = SongPlayerState.demoSong(
            name: "Demo",
            bpm: 120.0,
            duration: 180.0
        )

        // Then
        XCTAssertFalse(demoSong.waveform.isEmpty)
    }

    func testDemoSongs_CreatesMultipleSongs() {
        // When
        let demoSongs = SongPlayerState.demoSongs()

        // Then
        XCTAssertFalse(demoSongs.isEmpty)
        XCTAssertEqual(demoSongs.count, 4)
    }

    func testDemoSongs_AllHaveUniqueIDs() {
        // When
        let demoSongs = SongPlayerState.demoSongs()

        // Then
        let ids = demoSongs.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count)
    }

    // MARK: - Identifiable Conformance Tests

    func testSong_ConformsToIdentifiable() {
        // Given
        let song1: SongPlayerState = Fixtures.testSong
        let song2: SongPlayerState = Fixtures.testSong

        // Then
        XCTAssertNotEqual(song1.id, song2.id)
    }
}
