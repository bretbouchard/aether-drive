//
//  AccessibilityBenchmarks.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import ViewInspector
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Accessibility Performance Benchmarks
// =============================================================================

/// Performance benchmarks for accessibility operations.
///
/// This test suite measures the performance impact of accessibility features
/// to ensure they don't degrade user experience. Benchmarks cover:
///
/// - Audit performance (color contrast, labels, tap targets)
/// - Color contrast calculation performance
/// - VoiceOver navigation performance
/// - Dynamic Type rendering performance
/// - Accessibility tree inspection
///
/// **Performance Targets**:
/// - Full accessibility audit: <1 second
/// - Color contrast calculation (1000 pairs): <100ms
/// - VoiceOver navigation (20 elements): <2 seconds
/// - Dynamic Type rendering (all sizes): <5 seconds
///
/// Success Criteria:
/// - All benchmarks meet performance targets
/// - No accessibility feature causes >10% performance degradation
/// - Accessibility tree inspection is fast enough for real-time updates
class AccessibilityBenchmarks: XCTestCase {

    // =============================================================================
    // MARK: - Audit Performance Benchmarks
    // =============================================================================

    func testBenchmark_AuditEntireScreen_CompleteInUnder1Second() throws {
        // Benchmark: Complete accessibility audit of Moving Sidewalk view

        // Given
        let view = MovingSidewalkView().testTheme()

        // When - measure full audit time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            // Simulate complete accessibility audit
            _ = try view.inspect().findAll(ViewType.Button.self)
            _ = try view.inspect().findAll(ViewType.Slider.self)
            _ = try view.inspect().findAll(ViewType.Text.self)
            _ = try view.inspect().findAll(ViewType.Image.self)
        }

        // Then - verify completes in under 1 second
        // XCTClockMetric automatically measures and reports
        XCTAssertLessThan(metrics.average, 1.0, "Full accessibility audit should complete in under 1 second")
    }

    func testBenchmark_AuditSongPlayerCard_CompleteInUnder100ms() throws {
        // Benchmark: Accessibility audit of single song card

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song).testTheme()

        // When - measure audit time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            _ = try view.inspect().findAll(ViewType.Button.self)
            _ = try view.inspect().findAll(ViewType.Slider.self)
            _ = try view.inspect().findAll(ViewType.Text.self)
        }

        // Then - verify completes in under 100ms
        XCTAssertLessThan(metrics.average, 0.1, "Song card accessibility audit should complete in under 100ms")
    }

    // =============================================================================
    // MARK: - Color Contrast Calculation Benchmarks
    // =============================================================================

    func testBenchmark_ColorContrastCalculation_1000ContrastsInUnder100ms() {
        // Benchmark: Color contrast calculation performance

        // Given
        let calculator = ColorContrastCalculator()
        let iterations = 1000

        // When - measure calculation time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<iterations {
                let fg = UIColor.random()
                let bg = UIColor.random()
                _ = calculator.contrastRatio(foreground: fg, background: bg)
            }
        }

        // Then - verify completes in under 100ms
        XCTAssertLessThan(metrics.average, 0.1, "1000 contrast calculations should complete in under 100ms")
    }

    func testBenchmark_ColorContrastCalculation_SingleContrastInUnder1ms() {
        // Benchmark: Single color contrast calculation

        // Given
        let calculator = ColorContrastCalculator()
        let fg = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        let bg = UIColor.white

        // When - measure single calculation
        let metrics = measure(metrics: [XCTClockMetric()]) {
            _ = calculator.contrastRatio(foreground: fg, background: bg)
        }

        // Then - verify completes in under 1ms
        XCTAssertLessThan(metrics.average, 0.001, "Single contrast calculation should complete in under 1ms")
    }

    // =============================================================================
    // MARK: - VoiceOver Navigation Benchmarks
    // =============================================================================

    func testBenchmark_VoiceOverNavigation_20ElementsInUnder2Seconds() {
        // Benchmark: VoiceOver navigation performance

        // Note: This benchmark requires VoiceOver to be enabled
        // In practice, this would be run in a separate test target with VO enabled

        // Given
        let app = XCUIApplication()
        app.launchArguments = ["VOICEOVER_TEST"]
        app.launch()

        // When - measure navigation time for 20 elements
        let metrics = measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<20 {
                #if os(iOS)
                app.swipeRight()
                #endif
                Thread.sleep(forTimeInterval: 0.01) // Simulate VoiceOver delay
            }
        }

        // Then - verify completes in under 2 seconds
        XCTAssertLessThan(metrics.average, 2.0, "VoiceOver navigation of 20 elements should complete in under 2 seconds")
    }

    // =============================================================================
    // MARK: - Dynamic Type Rendering Benchmarks
    // =============================================================================

    func testBenchmark_DynamicTypeRendering_AllSizesInUnder5Seconds() {
        // Benchmark: Dynamic Type rendering performance

        // Given
        let sizes: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]

        // When - measure rendering time for all sizes
        let metrics = measure(metrics: [XCTClockMetric()]) {
            for size in sizes {
                // Create view with each content size
                let song = Fixtures.testSong
                let view = SongPlayerCard(song: song)
                    .environment(\.sizeCategory, size)
                    .testTheme()

                // Force render
                _ = try? view.inspect().find(ViewType.VStack.self)
            }
        }

        // Then - verify completes in under 5 seconds
        XCTAssertLessThan(metrics.average, 5.0, "Dynamic Type rendering for all sizes should complete in under 5 seconds")
    }

    func testBenchmark_DynamicTypeRendering_SingleSizeInUnder100ms() throws {
        // Benchmark: Single Dynamic Type size rendering

        // Given
        let song = Fixtures.testSong

        // When - measure rendering time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            let view = SongPlayerCard(song: song)
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .testTheme()

            _ = try view.inspect().find(ViewType.VStack.self)
        }

        // Then - verify completes in under 100ms
        XCTAssertLessThan(metrics.average, 0.1, "Single Dynamic Type size rendering should complete in under 100ms")
    }

    // =============================================================================
    // MARK: - Accessibility Tree Inspection Benchmarks
    // =============================================================================

    func testBenchmark_AccessibilityTreeInspection_ComplexViewInUnder50ms() throws {
        // Benchmark: Accessibility tree inspection performance

        // Given
        let state = Fixtures.testMultiSongState
        let view = MovingSidewalkView()
            .testTheme()

        // When - measure inspection time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            _ = try view.inspect().findAll(ViewType.Button.self)
            _ = try view.inspect().findAll(ViewType.Slider.self)
            _ = try view.inspect().findAll(ViewType.Text.self)
            _ = try view.inspect().findAll(ViewType.Image.self)
            _ = try view.inspect().findAll(ViewType.ScrollView.self)
        }

        // Then - verify completes in under 50ms
        XCTAssertLessThan(metrics.average, 0.05, "Complex view accessibility inspection should complete in under 50ms")
    }

    // =============================================================================
    // MARK: - Accessibility Label Retrieval Benchmarks
    // =============================================================================

    func testBenchmark_AccessibilityLabelRetrieval_100ElementsInUnder10ms() throws {
        // Benchmark: Accessibility label retrieval performance

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song).testTheme()

        // When - measure label retrieval time
        let metrics = measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<100 {
                let buttons = try view.inspect().findAll(ViewType.Button.self)
                for button in buttons {
                    _ = try button.accessibilityLabel()
                }
            }
        }

        // Then - verify completes in under 10ms
        XCTAssertLessThan(metrics.average, 0.01, "100 accessibility label retrievals should complete in under 10ms")
    }

    // =============================================================================
    // MARK: - Memory Performance Benchmarks
    // =============================================================================

    func testBenchmark_AccessibilityAudit_MemoryUsageStable() throws {
        // Benchmark: Memory usage during accessibility audit

        // Given
        let song = Fixtures.testSong
        let view = SongPlayerCard(song: song).testTheme()

        // Measure memory before
        let memoryBefore = getMemoryUsage()

        // When - perform multiple audits
        for _ in 0..<100 {
            _ = try view.inspect().findAll(ViewType.Button.self)
            _ = try view.inspect().findAll(ViewType.Slider.self)
        }

        // Measure memory after
        let memoryAfter = getMemoryUsage()

        // Then - verify memory growth is minimal (<10MB)
        let memoryGrowth = memoryAfter - memoryBefore
        XCTAssertLessThan(
            memoryGrowth,
            10_000_000, // 10MB in bytes
            "Accessibility audit should not cause excessive memory growth"
        )
    }

    // =============================================================================
    // MARK: - Helper Methods
    // =============================================================================

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}

// =============================================================================
// MARK: - Color Contrast Calculator (Mock)
// =============================================================================

struct ColorContrastCalculator {

    func contrastRatio(foreground: UIColor, background: UIColor) -> Double {
        // Simplified contrast calculation for benchmarking
        // In production, use WCAG 2.1 formula
        var fgRed: CGFloat = 0, fgGreen: CGFloat = 0, fgBlue: CGFloat = 0, fgAlpha: CGFloat = 0
        var bgRed: CGFloat = 0, bgGreen: CGFloat = 0, bgBlue: CGFloat = 0, bgAlpha: CGFloat = 0

        foreground.getRed(&fgRed, green: &fgGreen, blue: &fgBlue, alpha: &fgAlpha)
        background.getRed(&bgRed, green: &bgGreen, blue: &bgBlue, alpha: &bgAlpha)

        let fgLuminance = 0.2126 * fgRed + 0.7152 * fgGreen + 0.0722 * fgBlue
        let bgLuminance = 0.2126 * bgRed + 0.7152 * bgGreen + 0.0722 * bgBlue

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }
}

// =============================================================================
// MARK: - UIColor Extensions
// =============================================================================

extension UIColor {

    static func random() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}

// =============================================================================
// MARK: - Benchmark Reporter
// =============================================================================

struct BenchmarkReport {

    let name: String
    let averageTime: TimeInterval
    let baseline: TimeInterval
    let performanceChange: Double

    var isWithinTarget: Bool {
        return averageTime <= baseline
    }

    var performanceGrade: String {
        let change = performanceChange
        if change < -0.1 { return "Significantly Improved" }
        if change < -0.05 { return "Improved" }
        if change < 0.05 { return "Stable" }
        if change < 0.1 { return "Degraded" }
        return "Significantly Degraded"
    }
}
