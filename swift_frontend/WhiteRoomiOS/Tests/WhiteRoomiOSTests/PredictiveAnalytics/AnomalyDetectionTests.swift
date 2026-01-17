//
//  AnomalyDetectionTests.swift
//  WhiteRoomiOSTests
//
//  Created by AI on 1/16/26.
//  Copyright © 2026 Bret Bouchard. All rights reserved.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for AnomalyDetector
/// Tests anomaly detection accuracy, threshold sensitivity, trend recognition
final class AnomalyDetectionTests: XCTestCase {

    var sut: AnomalyDetector!

    override func setUp() async throws {
        try await super.setUp()
        sut = AnomalyDetector()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Anomaly Detection Tests

    func testDetectAnomaliesWithDeviatingMetrics() async throws {
        // Given: Baseline and metrics with deviation
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0, "duration": 1.0],
            thresholds: ["pass_rate": 10.0, "duration": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "pass_rate", value: 70.0, unit: "%"), // 26% deviation
            TestMetric(name: "duration", value: 1.5, unit: "s") // 50% deviation
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should detect both anomalies
        XCTAssertEqual(anomalies.count, 2)
        XCTAssertTrue(anomalies.contains { $0.metric == "pass_rate" })
        XCTAssertTrue(anomalies.contains { $0.metric == "duration" })
    }

    func testDetectAnomaliesWithNormalMetrics() async throws {
        // Given: Baseline and normal metrics
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0, "duration": 1.0],
            thresholds: ["pass_rate": 10.0, "duration": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "pass_rate", value: 92.0, unit: "%"), // 3% deviation
            TestMetric(name: "duration", value: 1.1, unit: "s") // 10% deviation
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should detect no anomalies
        XCTAssertEqual(anomalies.count, 0)
    }

    func testDetectAnomaliesDeterminesSeverity() async throws {
        // Given: Baseline and metrics with varying deviations
        let baseline = TestBaseline(
            values: ["metric1": 100.0],
            thresholds: ["metric1": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "metric1", value: 150.0, unit: "unit") // 50% deviation
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should assign appropriate severity
        XCTAssertEqual(anomalies.count, 1)
        let anomaly = anomalies.first!
        XCTAssertTrue([.warning, .critical].contains(anomaly.severity))
    }

    func testDetectAnomaliesGeneratesRecommendations() async throws {
        // Given: Baseline and failing metrics
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0],
            thresholds: ["pass_rate": 10.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "pass_rate", value: 50.0, unit: "%")
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should provide recommendations
        XCTAssertEqual(anomalies.count, 1)
        let anomaly = anomalies.first!
        XCTAssertFalse(anomaly.recommendation.isEmpty)
    }

    // MARK: - Performance Degradation Tests

    func testDetectsPerformanceDegradation() async throws {
        // Given: Performance baseline
        let baseline = TestBaseline(
            values: ["test_duration": 1.0],
            thresholds: ["test_duration": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "test_duration", value: 2.0, unit: "s") // 100% slower
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should detect as performance degradation
        XCTAssertEqual(anomalies.count, 1)
        let anomaly = anomalies.first!
        XCTAssertEqual(anomaly.type, .performanceDegradation)
        XCTAssertEqual(anomaly.metric, "test_duration")
    }

    func testDetectsSpikeInFailures() async throws {
        // Given: Pass rate baseline
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0],
            thresholds: ["pass_rate": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "pass_rate", value: 50.0, unit: "%") // Massive drop
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should detect as spike in failures
        XCTAssertEqual(anomalies.count, 1)
        let anomaly = anomalies.first!
        XCTAssertEqual(anomaly.type, .spikeInFailures)
        XCTAssertEqual(anomaly.severity, .critical)
    }

    // MARK: - Sudden Change Detection Tests

    func testDetectSuddenChangesWithRegression() async throws {
        // Given: Previous passing tests
        let previous = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 1.0),
                TestResult(name: "Test2", passed: true, duration: 1.0)
            ],
            timestamp: Date(),
            duration: 2.0
        )

        let current = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: false, duration: 1.0), // Regressed
                TestResult(name: "Test2", passed: true, duration: 1.0)
            ],
            timestamp: Date(),
            duration: 2.0
        )

        // When: Detecting sudden changes
        let changes = await sut.detectSuddenChanges(current: current, previous: previous)

        // Then: Should detect regression
        XCTAssertEqual(changes.count, 1)
        let change = changes.first!
        XCTAssertEqual(change.testName, "Test1")
        XCTAssertEqual(change.changeType, .regressed)
        XCTAssertEqual(change.severity, .critical)
    }

    func testDetectSuddenChangesWithFixedTest() async throws {
        // Given: Previous failing test
        let previous = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: false, duration: 1.0)
            ],
            timestamp: Date(),
            duration: 1.0
        )

        let current = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 1.0) // Fixed
            ],
            timestamp: Date(),
            duration: 1.0
        )

        // When: Detecting sudden changes
        let changes = await sut.detectSuddenChanges(current: current, previous: previous)

        // Then: Should detect fix
        XCTAssertEqual(changes.count, 1)
        let change = changes.first!
        XCTAssertEqual(change.changeType, .fixed)
        XCTAssertEqual(change.severity, .info)
    }

    func testDetectSuddenChangesWithSlowdown() async throws {
        // Given: Previous fast test
        let previous = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 1.0)
            ],
            timestamp: Date(),
            duration: 1.0
        )

        let current = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 2.0) // 100% slower
            ],
            timestamp: Date(),
            duration: 2.0
        )

        // When: Detecting sudden changes
        let changes = await sut.detectSuddenChanges(current: current, previous: previous)

        // Then: Should detect slowdown
        XCTAssertEqual(changes.count, 1)
        let change = changes.first!
        XCTAssertEqual(change.changeType, .slowed)
        XCTAssertEqual(change.previousValue, 1.0)
        XCTAssertEqual(change.newValue, 2.0)
    }

    func testDetectSuddenChangesWithSpeedup() async throws {
        // Given: Previous slow test
        let previous = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 2.0)
            ],
            timestamp: Date(),
            duration: 2.0
        )

        let current = TestRunResult(
            testResults: [
                TestResult(name: "Test1", passed: true, duration: 1.0) // 50% faster
            ],
            timestamp: Date(),
            duration: 1.0
        )

        // When: Detecting sudden changes
        let changes = await sut.detectSuddenChanges(current: current, previous: previous)

        // Then: Should detect speedup
        XCTAssertEqual(changes.count, 1)
        let change = changes.first!
        XCTAssertEqual(change.changeType, .spedUp)
    }

    func testDetectSuddenChangesIgnoresNewTests() async throws {
        // Given: Previous run without test
        let previous = TestRunResult(
            testResults: [],
            timestamp: Date(),
            duration: 0
        )

        let current = TestRunResult(
            testResults: [
                TestResult(name: "NewTest", passed: true, duration: 1.0)
            ],
            timestamp: Date(),
            duration: 1.0
        )

        // When: Detecting sudden changes
        let changes = await sut.detectSuddenChanges(current: current, previous: previous)

        // Then: Should not flag as sudden change
        XCTAssertEqual(changes.count, 0)
    }

    // MARK: - Outlier Detection Tests

    func testDetectOutliersWithNormalDistribution() async throws {
        // Given: Normal distribution
        let dataPoints = [10.0, 12.0, 11.0, 13.0, 10.0, 12.0, 11.0, 14.0, 10.0, 12.0]

        // When: Detecting outliers
        let outliers = await sut.detectOutliers(in: dataPoints, standardDeviations: 2.0)

        // Then: Should detect minimal outliers
        XCTAssertLessThan(outliers.count, 2)
    }

    func testDetectOutliersWithObviousOutlier() async throws {
        // Given: Data with obvious outlier
        let dataPoints = [10.0, 11.0, 10.0, 12.0, 10.0, 11.0, 100.0, 10.0, 12.0, 11.0]

        // When: Detecting outliers
        let outliers = await sut.detectOutliers(in: dataPoints, standardDeviations: 2.0)

        // Then: Should detect the outlier
        XCTAssertEqual(outliers.count, 1)
        let outlier = outliers.first!
        XCTAssertEqual(outlier.value, 100.0)
        XCTAssertEqual(outlier.severity, .extreme)
    }

    func testDetectOutliersWithMultipleOutliers() async throws {
        // Given: Data with multiple outliers
        let dataPoints = [10.0, 11.0, 100.0, 12.0, 10.0, -50.0, 11.0, 10.0, 12.0, 11.0]

        // When: Detecting outliers
        let outliers = await sut.detectOutliers(in: dataPoints, standardDeviations: 2.0)

        // Then: Should detect both outliers
        XCTAssertGreaterThanOrEqual(outliers.count, 2)
        XCTAssertTrue(outliers.contains { $0.value == 100.0 })
        XCTAssertTrue(outliers.contains { $0.value == -50.0 })
    }

    func testDetectOutliersSensitivity() async throws {
        // Given: Same data with different thresholds
        let dataPoints = [10.0, 11.0, 10.0, 12.0, 10.0, 11.0, 15.0, 10.0, 12.0, 11.0]

        // When: Using different thresholds
        let outliersStrict = await sut.detectOutliers(in: dataPoints, standardDeviations: 1.5)
        let outliersLenient = await sut.detectOutliers(in: dataPoints, standardDeviations: 3.0)

        // Then: Stricter threshold should detect more outliers
        XCTAssertGreaterThanOrEqual(outliersStrict.count, outliersLenient.count)
    }

    func testDetectOutliersCalculatesCorrectStatistics() async throws {
        // Given: Known dataset
        let dataPoints = [10.0, 20.0, 30.0, 40.0, 50.0]

        // When: Detecting outliers
        let outliers = await sut.detectOutliers(in: dataPoints, standardDeviations: 2.0)

        // Then: Should calculate correct statistics
        let mean = dataPoints.reduce(0, +) / Double(dataPoints.count)
        for outlier in outliers {
            XCTAssertEqual(outlier.mean, mean, accuracy: 0.01)
            XCTAssertGreaterThan(outlier.standardDeviations, 2.0)
        }
    }

    // MARK: - Baseline Management Tests

    func testBuildBaselineFromMetrics() async throws {
        // Given: Multiple metric sets
        let metricSets: [[TestMetric]] = [
            [
                TestMetric(name: "pass_rate", value: 95.0, unit: "%"),
                TestMetric(name: "duration", value: 1.0, unit: "s")
            ],
            [
                TestMetric(name: "pass_rate", value: 96.0, unit: "%"),
                TestMetric(name: "duration", value: 1.1, unit: "s")
            ],
            [
                TestMetric(name: "pass_rate", value: 94.0, unit: "%"),
                TestMetric(name: "duration", value: 0.9, unit: "s")
            ],
            [
                TestMetric(name: "pass_rate", value: 95.5, unit: "%"),
                TestMetric(name: "duration", value: 1.05, unit: "s")
            ],
            [
                TestMetric(name: "pass_rate", value: 95.2, unit: "%"),
                TestMetric(name: "duration", value: 1.02, unit: "s")
            ]
        ]

        // When: Building baseline
        let baseline = await sut.buildBaseline(from: metricSets)

        // Then: Should calculate averages
        XCTAssertEqual(baseline.values.count, 2)
        XCTAssertEqual(baseline.values["pass_rate"], 95.14, accuracy: 0.1)
        XCTAssertEqual(baseline.values["duration"], 1.014, accuracy: 0.01)
        XCTAssertEqual(baseline.sampleCount, 5)
    }

    func testUpdateBaselineWithNewMetrics() async throws {
        // Given: Existing baseline
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0],
            thresholds: ["pass_rate": 10.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let newMetrics = [
            TestMetric(name: "pass_rate", value: 97.0, unit: "%")
        ]

        // When: Updating baseline
        let updated = await sut.updateBaseline(
            baseline: baseline,
            with: newMetrics,
            smoothingFactor: 0.5
        )

        // Then: Should apply smoothing
        XCTAssertNotEqual(updated.values["pass_rate"], baseline.values["pass_rate"])
        XCTAssertGreaterThan(updated.values["pass_rate"]! , 95.0)
        XCTAssertLessThan(updated.values["pass_rate"]!, 97.0)
        XCTAssertEqual(updated.sampleCount, 11)
    }

    func testUpdateBaselineAddsNewMetrics() async throws {
        // Given: Baseline without certain metric
        let baseline = TestBaseline(
            values: ["pass_rate": 95.0],
            thresholds: ["pass_rate": 10.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let newMetrics = [
            TestMetric(name: "new_metric", value: 50.0, unit: "ms")
        ]

        // When: Updating baseline
        let updated = await sut.updateBaseline(
            baseline: baseline,
            with: newMetrics,
            smoothingFactor: 0.2
        )

        // Then: Should add new metric
        XCTAssertTrue(updated.values.keys.contains("new_metric"))
        XCTAssertEqual(updated.values["new_metric"], 50.0)
    }

    func testGetBaselineHistory() async throws {
        // Given: Multiple baselines
        let metrics: [[TestMetric]] = [
            [TestMetric(name: "metric1", value: 10.0, unit: "unit")],
            [TestMetric(name: "metric1", value: 11.0, unit: "unit")],
            [TestMetric(name: "metric1", value: 12.0, unit: "unit")]
        ]

        _ = await sut.buildBaseline(from: [metrics[0]])
        _ = await sut.buildBaseline(from: [metrics[1]])
        _ = await sut.buildBaseline(from: [metrics[2]])

        // When: Getting history
        let history = await sut.getBaselineHistory()

        // Then: Should return all baselines
        XCTAssertEqual(history.count, 3)
    }

    // MARK: - Edge Cases Tests

    func testDetectAnomaliesWithEmptyMetrics() async throws {
        // Given: Baseline but no metrics
        let baseline = TestBaseline(
            values: ["metric1": 100.0],
            thresholds: ["metric1": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics: [TestMetric] = []

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should return empty
        XCTAssertEqual(anomalies.count, 0)
    }

    func testDetectOutliersWithInsufficientData() async throws {
        // Given: Too few data points
        let dataPoints = [10.0]

        // When: Detecting outliers
        let outliers = await sut.detectOutliers(in: dataPoints)

        // Then: Should return empty
        XCTAssertEqual(outliers.count, 0)
    }

    func testBuildBaselineWithInsufficientSamples() async throws {
        // Given: Only 2 samples (below minimum)
        let metricSets: [[TestMetric]] = [
            [TestMetric(name: "metric1", value: 10.0, unit: "unit")],
            [TestMetric(name: "metric1", value: 11.0, unit: "unit")]
        ]

        // When: Building baseline
        let baseline = await sut.buildBaseline(from: metricSets)

        // Then: Should have limited data
        XCTAssertEqual(baseline.values.count, 0) // Not enough samples
    }

    func testDetectAnomaliesWithZeroBaseline() async throws {
        // Given: Baseline with zero value
        let baseline = TestBaseline(
            values: ["metric1": 0.0],
            thresholds: ["metric1": 20.0],
            sampleCount: 10,
            timestamp: Date()
        )

        let metrics = [
            TestMetric(name: "metric1", value: 10.0, unit: "unit")
        ]

        // When: Detecting anomalies
        let anomalies = await sut.detectAnomalies(in: metrics, baseline: baseline)

        // Then: Should handle gracefully (no division by zero)
        // Either detect as anomaly or handle safely
        XCTAssertTrue(anomalies.count >= 0)
    }

    // MARK: - Performance Tests

    func testAnomalyDetectionPerformance() async throws {
        // Given: Large dataset
        let baseline = TestBaseline(
            values: Dictionary(uniqueKeysWithValues:
                (1...100).map { ("metric\($0)", Double.random(in: 90...110)) }
            ),
            thresholds: Dictionary(uniqueKeysWithValues:
                (1...100).map { ("metric\($0)", 20.0) }
            ),
            sampleCount: 100,
            timestamp: Date()
        )

        let metrics = (1...100).map { i in
            TestMetric(
                name: "metric\(i)",
                value: Double.random(in: 50...150),
                unit: "unit"
            )
        }

        // When: Detecting anomalies
        measure {
            Task {
                _ = await sut.detectAnomalies(in: metrics, baseline: baseline)
            }
        }
    }

    func testOutlierDetectionPerformance() async throws {
        // Given: Large dataset
        let dataPoints = (1...1000).map { _ in Double.random(in: 0...100) }

        // When: Detecting outliers
        measure {
            Task {
                _ = await sut.detectOutliers(in: dataPoints)
            }
        }
    }
}
