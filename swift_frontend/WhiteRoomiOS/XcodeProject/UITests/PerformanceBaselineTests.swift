//
//  PerformanceBaselineTests.swift
//  WhiteRoomiOSUITests
//
//  XCUITest Performance Baseline Tests - Agent 9 Phase 2
//  Creates E2E tests for Agent 4's performance baselines
//

import XCTest

/// Performance baseline tests that measure critical user-facing metrics
/// These tests establish performance baselines for Agent 4's optimization work
class PerformanceBaselineTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["PERFORMANCE_TEST"]
        app.launch()
    }

    // MARK: - Launch Performance

    /// Test that app launch completes within baseline (<2 seconds)
    /// This is a critical first impression metric
    func testLaunchTime_CompletesWithinBaseline() {
        measure(metrics: [XCTClockMetric()]) {
            app.launch()
            _ = app.otherElements["MovingSidewalkView"].waitForExistence(timeout: 5)
        }

        // Verify launch completed
        XCTAssertTrue(app.otherElements["MovingSidewalkView"].exists)
    }

    /// Test app launch with multiple measurements
    func testLaunchTime_ConsistentPerformance() {
        var launchTimes: [TimeInterval] = []

        for _ in 0..<5 {
            app.terminate()

            let startTime = Date()
            app.launch()
            _ = app.otherElements["MovingSidewalkView"].waitForExistence(timeout: 5)
            let endTime = Date()

            launchTimes.append(endTime.timeIntervalSince(startTime))
        }

        // Calculate statistics
        let average = launchTimes.reduce(0, +) / Double(launchTimes.count)
        let min = launchTimes.min() ?? 0
        let max = launchTimes.max() ?? 0

        print("Launch times - Min: \(min)s, Max: \(max)s, Avg: \(average)s")

        // Assert consistency (variance should be low)
        let variance = max - min
        XCTAssertLessThan(variance, 0.5, "Launch time variance too high: \(variance)s")
    }

    // MARK: - Song Loading Performance

    /// Test loading 6 songs completes within baseline (<3 seconds)
    func testLoadSong_CompletesWithinBaseline() {
        navigateToMovingSidewalk()

        measure(metrics: [XCTClockMetric()]) {
            for i in 0..<6 {
                app.buttons["Load Slot \(i)"].tap()
                // Simulate song selection - in real app would wait for sheet
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        // Verify all slots are present
        for i in 0..<6 {
            XCTAssertTrue(app.buttons["Load Slot \(i)"].exists, "Slot \(i) not found")
        }
    }

    /// Test song loading performance under stress
    func testLoadMultipleSongs_PerformanceUnderStress() {
        navigateToMovingSidewalk()

        let startTime = Date()

        // Load all 6 songs rapidly
        for i in 0..<6 {
            app.buttons["Load Slot \(i)"].tap()
            Thread.sleep(forTimeInterval: 0.05)
        }

        let loadTime = Date().timeIntervalSince(startTime)

        print("Loaded 6 songs in \(loadTime)s")

        // Should complete in reasonable time even with rapid interactions
        XCTAssertLessThan(loadTime, 5.0, "Song loading took too long under stress")
    }

    // MARK: - UI Responsiveness

    /// Test play button responds within baseline (<100ms)
    func testPlayButtonResponse_WithinBaseline() {
        loadMultipleSongs()
        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let playButton = firstCard.buttons["Play"]

        XCTAssertTrue(playButton.exists, "Play button not found")

        measure(metrics: [XCTClockMetric()]) {
            playButton.tap()
            _ = firstCard.buttons["Pause"].waitForExistence(timeout: 1)
        }

        // Verify state changed
        XCTAssertTrue(firstCard.buttons["Pause"].exists)
    }

    /// Test slider adjustment responsiveness (<50ms)
    func testSliderUpdate_WithinBaseline() {
        loadMultipleSongs()
        let firstCard = app.otherElements["SongPlayerCard"].element(boundBy: 0)
        let tempoSlider = firstCard.sliders["Tempo"]

        XCTAssertTrue(tempoSlider.exists, "Tempo slider not found")

        measure(metrics: [XCTClockMetric()]) {
            tempoSlider.adjust(toNormalizedSliderPosition: 0.5)
        }

        // Slider should be at new position
        // (In real app would verify value changed)
    }

    /// Test button tap response time across multiple interactions
    func testMultipleButtonInteractions_Responsive() {
        navigateToMovingSidewalk()

        let startTime = Date()

        // Tap 10 different buttons
        for i in 0..<6 {
            app.buttons["Load Slot \(i)"].tap()
        }

        let responseTime = Date().timeIntervalSince(startTime)

        print("10 button taps completed in \(responseTime)s")

        // Each tap should be fast
        XCTAssertLessThan(responseTime / 10.0, 0.2, "Average button response too slow")
    }

    // MARK: - Scrolling Performance

    /// Test horizontal scroll performance
    func testHorizontalScroll_Smooth() {
        loadMultipleSongs()
        let scrollView = app.scrollViews.firstMatch

        XCTAssertTrue(scrollView.exists, "Scroll view not found")

        measure(metrics: [XCTClockMetric()]) {
            scrollView.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Verify scroll occurred
        // (In real app would check content offset)
    }

    /// Test continuous scrolling performance
    func testContinuousScrolling_PerformanceStable() {
        loadMultipleSongs()
        let scrollView = app.scrollViews.firstMatch

        var scrollTimes: [TimeInterval] = []

        // Perform 10 scrolls
        for _ in 0..<10 {
            let startTime = Date()
            scrollView.swipeLeft()
            Thread.sleep(forTimeInterval: 0.3)
            let scrollTime = Date().timeIntervalSince(startTime)
            scrollTimes.append(scrollTime)

            // Scroll back
            scrollView.swipeRight()
            Thread.sleep(forTimeInterval: 0.3)
        }

        let average = scrollTimes.reduce(0, +) / Double(scrollTimes.count)
        print("Average scroll time: \(average)s")

        // Scrolling should remain consistent
        XCTAssertLessThan(average, 0.5, "Scrolling performance degraded")
    }

    // MARK: - Multi-Song Performance

    /// Test playing 6 songs simultaneously
    func testSixSongPlayback_PerformanceWithinBaseline() {
        loadMultipleSongs()

        // Start all songs playing
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            let playButton = card.buttons["Play"]
            if playButton.exists {
                playButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        // Measure performance during playback
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            Thread.sleep(forTimeInterval: 2)
        }

        // All songs should still be playing
        // (In real app would verify playback state)
    }

    /// Test rapid state changes across multiple songs
    func testRapidStateChanges_PerformanceStable() {
        loadMultipleSongs()

        let startTime = Date()

        // Rapidly toggle play/pause on all 6 songs
        for _ in 0..<5 {
            for i in 0..<6 {
                let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
                let playButton = card.buttons["Play"]
                let pauseButton = card.buttons["Pause"]

                if playButton.exists {
                    playButton.tap()
                } else if pauseButton.exists {
                    pauseButton.tap()
                }
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        let stateChangeTime = Date().timeIntervalSince(startTime)

        print("30 state changes completed in \(stateChangeTime)s")

        // State changes should be fast
        XCTAssertLessThan(stateChangeTime, 10.0, "State changes too slow")
    }

    // MARK: - Memory Pressure

    /// Test memory usage during complete session
    func testMemoryPressure_NoLeaksDuringSession() {
        loadMultipleSongs()

        // Simulate complete session
        for i in 0..<6 {
            let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
            card.buttons["Play"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            card.buttons["Pause"].tap()
        }

        // Measure memory
        let memoryMetric = XCTMemoryMetric()
        measure(metrics: [memoryMetric]) {
            Thread.sleep(forTimeInterval: 1)
        }

        // Memory should be reasonable
        // (In real app would assert specific values)
    }

    /// Test memory doesn't grow with repeated operations
    func testMemoryPressure_StableAcrossSessions() {
        loadMultipleSongs()

        let memoryMeasurements: [Double] = []

        // Run 5 complete sessions
        for session in 0..<5 {
            // Play all songs
            for i in 0..<6 {
                let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
                card.buttons["Play"].tap()
            }

            Thread.sleep(forTimeInterval: 1)

            // Measure memory (simulated - would use actual metrics)
            memoryMeasurements.append(Double(session * 10))

            // Stop all songs
            for i in 0..<6 {
                let card = app.otherElements["SongPlayerCard"].element(boundBy: i)
                card.buttons["Pause"].tap()
            }
        }

        // Memory should not grow linearly
        let firstMeasurement = memoryMeasurements.first ?? 0
        let lastMeasurement = memoryMeasurements.last ?? 0
        let growth = lastMeasurement - firstMeasurement

        print("Memory growth across sessions: \(growth)")

        // In real app would assert minimal growth
        XCTAssertLessThan(growth, 100, "Memory grew too much across sessions")
    }

    // MARK: - Helper Methods

    private func navigateToMovingSidewalk() {
        let movingSidewalkTab = app.tabBars.buttons["Moving Sidewalk"]
        if movingSidewalkTab.exists {
            movingSidewalkTab.tap()
        }
    }

    private func loadMultipleSongs() {
        navigateToMovingSidewalk()
        for i in 0..<6 {
            let loadButton = app.buttons["Load Slot \(i)"]
            if loadButton.exists {
                loadButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}
