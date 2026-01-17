//
//  QualityScoringTests.swift
//  WhiteRoomiOSTests
//
//  Created by AI on 1/16/26.
//  Copyright © 2026 Bret Bouchard. All rights reserved.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for QualityScoringModel
/// Tests score calculation, weight distribution, prediction accuracy, and edge cases
final class QualityScoringTests: XCTestCase {

    var sut: QualityScoringModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = QualityScoringModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Score Calculation Tests

    func testScoreCalculationWithPerfectMetrics() async throws {
        // Given: Perfect metrics
        let coverage: Double = 100
        let failureRate: Double = 0
        let complexity: Double = 0
        let performance: Double = 100
        let accessibility: Double = 100

        // When: Calculating score
        let score = await sut.calculateScore(
            coverage: coverage,
            failureRate: failureRate,
            complexity: complexity,
            performance: performance,
            accessibility: accessibility
        )

        // Then: Should get near-perfect score
        XCTAssertEqual(score.overall, 100, "Perfect metrics should yield 100")
        XCTAssertEqual(score.testCoverage, 100)
        XCTAssertEqual(score.stability, 100)
        XCTAssertEqual(score.performance, 100)
        XCTAssertEqual(score.accessibility, 100)
        XCTAssertEqual(score.confidence, 1.0, accuracy: 0.1)
    }

    func testScoreCalculationWithPoorMetrics() async throws {
        // Given: Poor metrics
        let coverage: Double = 20
        let failureRate: Double = 80
        let complexity: Double = 90
        let performance: Double = 30
        let accessibility: Double = 10

        // When: Calculating score
        let score = await sut.calculateScore(
            coverage: coverage,
            failureRate: failureRate,
            complexity: complexity,
            performance: performance,
            accessibility: accessibility
        )

        // Then: Should get low score
        XCTAssertLessThan(score.overall, 40, "Poor metrics should yield low score")
        XCTAssertLessThan(score.testCoverage, 30)
        XCTAssertLessThan(score.stability, 30)
        XCTAssertLessThan(score.performance, 40)
        XCTAssertLessThan(score.accessibility, 20)
    }

    func testScoreCalculationWithAverageMetrics() async throws {
        // Given: Average metrics
        let coverage: Double = 70
        let failureRate: Double = 20
        let complexity: Double = 40
        let performance: Double = 75
        let accessibility: Double = 65

        // When: Calculating score
        let score = await sut.calculateScore(
            coverage: coverage,
            failureRate: failureRate,
            complexity: complexity,
            performance: performance,
            accessibility: accessibility
        )

        // Then: Should get moderate score
        XCTAssertGreaterThan(score.overall, 50)
        XCTAssertLessThan(score.overall, 85)
        XCTAssertEqual(score.confidence, 1.0, accuracy: 0.2)
    }

    func testWeightDistribution() async throws {
        // Given: Known weights
        let customWeights = QualityScoringModel.Weights(
            testCoverage: 0.4,
            stability: 0.3,
            complexity: 0.1,
            performance: 0.1,
            accessibility: 0.1
        )

        let customSut = QualityScoringModel(weights: customWeights)

        // When: Calculating score with one metric at max
        let score1 = await customSut.calculateScore(
            coverage: 100,
            failureRate: 100,
            complexity: 0,
            performance: 0,
            accessibility: 0
        )

        let score2 = await customSut.calculateScore(
            coverage: 0,
            failureRate: 0,
            complexity: 0,
            performance: 0,
            accessibility: 100
        )

        // Then: Coverage should have more impact than accessibility
        XCTAssertGreaterThan(score1.overall, score2.overall)
    }

    // MARK: - Edge Cases Tests

    func testEdgeCaseZeroCoverage() async throws {
        // Given: Zero coverage
        let score = await sut.calculateScore(
            coverage: 0,
            failureRate: 0,
            complexity: 0,
            performance: 100,
            accessibility: 100
        )

        // Then: Should still produce valid score
        XCTAssertEqual(score.testCoverage, 0)
        XCTAssertGreaterThan(score.overall, 0, "Other metrics should contribute")
    }

    func testEdgeCaseCompleteFailure() async throws {
        // Given: 100% failure rate
        let score = await sut.calculateScore(
            coverage: 100,
            failureRate: 100,
            complexity: 0,
            performance: 100,
            accessibility: 100
        )

        // Then: Stability should be 0
        XCTAssertEqual(score.stability, 0)
    }

    func testEdgeCaseMaximumComplexity() async throws {
        // Given: Maximum complexity
        let score = await sut.calculateScore(
            coverage: 100,
            failureRate: 0,
            complexity: 100,
            performance: 100,
            accessibility: 100
        )

        // Then: Should penalize score but not make it zero
        XCTAssertLessThan(score.overall, 90)
        XCTAssertGreaterThan(score.overall, 50)
    }

    func testEdgeCaseNegativeValues() async throws {
        // Given: Negative values (should be clamped to 0)
        let score = await sut.calculateScore(
            coverage: -10,
            failureRate: -5,
            complexity: -20,
            performance: -15,
            accessibility: -10
        )

        // Then: Should handle gracefully
        XCTAssertGreaterThanOrEqual(score.overall, 0)
        XCTAssertLessThanOrEqual(score.overall, 100)
    }

    func testEdgeCaseValuesAbove100() async throws {
        // Given: Values above 100 (should be clamped)
        let score = await sut.calculateScore(
            coverage: 150,
            failureRate: 120,
            complexity: 200,
            performance: 180,
            accessibility: 110
        )

        // Then: Should clamp to valid range
        XCTAssertGreaterThanOrEqual(score.overall, 0)
        XCTAssertLessThanOrEqual(score.overall, 100)
    }

    // MARK: - Grade Calculation Tests

    func testGradeCalculationPerfectScore() async throws {
        let score = await sut.calculateScore(
            coverage: 100,
            failureRate: 0,
            complexity: 0,
            performance: 100,
            accessibility: 100
        )

        XCTAssertEqual(score.overall, 100)
        XCTAssertEqual(score.grade, .plus)
    }

    func testGradeCalculationBRange() async throws {
        let score = await sut.calculateScore(
            coverage: 85,
            failureRate: 15,
            complexity: 30,
            performance: 85,
            accessibility: 80
        )

        XCTAssertGreaterThan(score.overall, 80)
        XCTAssertLessThan(score.overall, 90)
        XCTAssertTrue([.plus, .standard, .minus].contains(score.grade))
    }

    func testGradeCalculationFailing() async throws {
        let score = await sut.calculateScore(
            coverage: 40,
            failureRate: 60,
            complexity: 80,
            performance: 40,
            accessibility: 30
        )

        XCTAssertLessThan(score.overall, 60)
        XCTAssertEqual(score.grade, .standard)
    }

    // MARK: - Prediction Tests

    func testPredictScoreImpactWithPositiveChange() async throws {
        // Given: Baseline score and positive coverage delta
        let baseline = await sut.calculateScore(
            coverage: 60,
            failureRate: 20,
            complexity: 50,
            performance: 70,
            accessibility: 60
        )

        // When: Predicting impact of improvements
        let prediction = await sut.predictScoreImpact(
            changedFiles: ["TestFile.swift"],
            linesChanged: 100,
            testCoverageDelta: 20
        )

        // Then: Should predict improvement
        XCTAssertGreaterThan(prediction.predictedScore.overall, baseline.overall)
        XCTAssertEqual(prediction.impact, .moderateImprovement)
    }

    func testPredictScoreImpactWithNegativeChange() async throws {
        // Given: Baseline score
        _ = await sut.calculateScore(
            coverage: 80,
            failureRate: 10,
            complexity: 30,
            performance: 85,
            accessibility: 80
        )

        // When: Predicting impact of large, risky changes
        let prediction = await sut.predictScoreImpact(
            changedFiles: ["File1.swift", "File2.swift", "File3.swift"],
            linesChanged: 800,
            testCoverageDelta: -15
        )

        // Then: Should predict decline
        XCTAssertEqual(prediction.scoreDelta, prediction.predictedScore.overall - prediction.currentScore.overall)
        XCTAssertTrue([.minorDecline, .moderateDecline, .significantDecline].contains(prediction.impact))
    }

    func testPredictionConfidenceDecreasesWithChangeSize() async throws {
        // Given: Two predictions with different change sizes
        let prediction1 = await sut.predictScoreImpact(
            changedFiles: ["SmallFile.swift"],
            linesChanged: 50,
            testCoverageDelta: 5
        )

        let prediction2 = await sut.predictScoreImpact(
            changedFiles: ["BigFile.swift", "BigFile2.swift"],
            linesChanged: 1000,
            testCoverageDelta: 30
        )

        // Then: Larger changes should have lower confidence
        XCTAssertGreaterThan(prediction1.confidence, prediction2.confidence)
    }

    // MARK: - Recommendation Tests

    func testRecommendationsIncludeCoverageAdvice() async throws {
        // Given: Low coverage scenario
        let prediction = await sut.predictScoreImpact(
            changedFiles: ["File.swift"],
            linesChanged: 100,
            testCoverageDelta: -30
        )

        // Then: Should recommend coverage improvements
        XCTAssertTrue(
            prediction.recommendations.contains { $0.contains("coverage") },
            "Should recommend increasing test coverage"
        )
    }

    func testRecommendationsIncludeStabilityAdvice() async throws {
        // Given: Low stability scenario
        _ = await sut.calculateScore(
            coverage: 90,
            failureRate: 50,
            complexity: 20,
            performance: 80,
            accessibility: 85
        )

        let prediction = await sut.predictScoreImpact(
            changedFiles: ["File.swift"],
            linesChanged: 200,
            testCoverageDelta: 0
        )

        // Then: Should recommend stability improvements
        XCTAssertTrue(
            prediction.recommendations.contains { $0.contains("stability") || $0.contains("failure") },
            "Should recommend improving stability"
        )
    }

    // MARK: - Trend Detection Tests

    func testDetectImprovingTrend() async throws {
        // Given: Increasing scores over time
        _ = await sut.calculateScore(coverage: 50, failureRate: 30, complexity: 50, performance: 60, accessibility: 50)
        _ = await sut.calculateScore(coverage: 60, failureRate: 25, complexity: 45, performance: 65, accessibility: 55)
        _ = await sut.calculateScore(coverage: 70, failureRate: 20, complexity: 40, performance: 70, accessibility: 60)
        _ = await sut.calculateScore(coverage: 80, failureRate: 15, complexity: 35, performance: 75, accessibility: 65)
        _ = await sut.calculateScore(coverage: 85, failureRate: 10, complexity: 30, performance: 80, accessibility: 70)

        // When: Detecting trend
        let trend = await sut.detectQualityTrend()

        // Then: Should detect improvement
        XCTAssertEqual(trend.direction, .improving)
        XCTAssertGreaterThan(trend.magnitude, 0)
        XCTAssertGreaterThan(trend.confidence, 0.5)
    }

    func testDetectDecliningTrend() async throws {
        // Given: Decreasing scores over time
        _ = await sut.calculateScore(coverage: 90, failureRate: 5, complexity: 10, performance: 95, accessibility: 90)
        _ = await sut.calculateScore(coverage: 80, failureRate: 15, complexity: 20, performance: 85, accessibility: 80)
        _ = await sut.calculateScore(coverage: 70, failureRate: 25, complexity: 30, performance: 75, accessibility: 70)
        _ = await sut.calculateScore(coverage: 60, failureRate: 35, complexity: 40, performance: 65, accessibility: 60)
        _ = await sut.calculateScore(coverage: 50, failureRate: 45, complexity: 50, performance: 55, accessibility: 50)

        // When: Detecting trend
        let trend = await sut.detectQualityTrend()

        // Then: Should detect decline
        XCTAssertEqual(trend.direction, .declining)
        XCTAssertGreaterThan(trend.magnitude, 0)
    }

    func testDetectStableTrend() async throws {
        // Given: Consistent scores
        _ = await sut.calculateScore(coverage: 75, failureRate: 15, complexity: 25, performance: 75, accessibility: 75)
        _ = await sut.calculateScore(coverage: 76, failureRate: 14, complexity: 26, performance: 76, accessibility: 74)
        _ = await sut.calculateScore(coverage: 75, failureRate: 16, complexity: 24, performance: 75, accessibility: 76)
        _ = await sut.calculateScore(coverage: 74, failureRate: 15, complexity: 25, performance: 74, accessibility: 75)
        _ = await sut.calculateScore(coverage: 75, failureRate: 15, complexity: 25, performance: 75, accessibility: 75)

        // When: Detecting trend
        let trend = await sut.detectQualityTrend()

        // Then: Should detect stability
        XCTAssertEqual(trend.direction, .stable)
    }

    func testMovingAverageCalculation() async throws {
        // Given: Multiple scores
        _ = await sut.calculateScore(coverage: 60, failureRate: 20, complexity: 40, performance: 70, accessibility: 60)
        _ = await sut.calculateScore(coverage: 70, failureRate: 15, complexity: 35, performance: 75, accessibility: 65)
        _ = await sut.calculateScore(coverage: 80, failureRate: 10, complexity: 30, performance: 80, accessibility: 70)

        // When: Getting moving average
        let average = await sut.getMovingAverage(windowSize: 3)

        // Then: Should calculate correctly
        XCTAssertNotNil(average)
        XCTAssertGreaterThan(average!, 60)
        XCTAssertLessThan(average!, 90)
    }

    // MARK: - Confidence Calculation Tests

    func testConfidenceHighWithCompleteData() async throws {
        let score = await sut.calculateScore(
            coverage: 75,
            failureRate: 15,
            complexity: 35,
            performance: 80,
            accessibility: 70
        )

        XCTAssertGreaterThan(score.confidence, 0.8)
    }

    func testConfidenceLowerWithPoorData() async throws {
        let score = await sut.calculateScore(
            coverage: 30,
            failureRate: 70,
            complexity: 80,
            performance: 20,
            accessibility: 10
        )

        XCTAssertLessThan(score.confidence, 0.8)
    }

    // MARK: - Performance Tests

    func testScoreCalculationPerformance() async throws {
        measure {
            Task {
                for _ in 0..<100 {
                    _ = await sut.calculateScore(
                        coverage: Double.random(in: 0...100),
                        failureRate: Double.random(in: 0...100),
                        complexity: Double.random(in: 0...100),
                        performance: Double.random(in: 0...100),
                        accessibility: Double.random(in: 0...100)
                    )
                }
            }
        }
    }
}
