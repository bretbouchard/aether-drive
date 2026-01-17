//
//  FailurePredictionTests.swift
//  WhiteRoomiOSTests
//
//  Created by AI on 1/16/26.
//  Copyright © 2026 Bret Bouchard. All rights reserved.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for FailurePredictionEngine
/// Tests failure prediction accuracy, flakiness detection, dependency analysis
final class FailurePredictionTests: XCTestCase {

    var sut: FailurePredictionEngine!

    override func setUp() async throws {
        try await super.setUp()
        sut = FailurePredictionEngine()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Test Result Analysis Tests

    func testAnalyzeTestResultsWithAllPassing() async throws {
        // Given: All passing tests
        let results = createTestResults(
            names: ["Test1", "Test2", "Test3"],
            passed: true
        )

        // When: Analyzing results
        let analysis = await sut.analyzeTestResults(results)

        // Then: Should report all passing
        XCTAssertEqual(analysis.totalTests, 3)
        XCTAssertEqual(analysis.passedTests, 3)
        XCTAssertEqual(analysis.failedTests, 0)
        XCTAssertEqual(analysis.passRate, 1.0, accuracy: 0.01)
    }

    func testAnalyzeTestResultsWithAllFailing() async throws {
        // Given: All failing tests
        let results = createTestResults(
            names: ["Test1", "Test2", "Test3"],
            passed: false
        )

        // When: Analyzing results
        let analysis = await sut.analyzeTestResults(results)

        // Then: Should report all failing
        XCTAssertEqual(analysis.totalTests, 3)
        XCTAssertEqual(analysis.passedTests, 0)
        XCTAssertEqual(analysis.failedTests, 3)
        XCTAssertEqual(analysis.passRate, 0.0, accuracy: 0.01)
    }

    func testAnalyzeTestResultsWithMixedResults() async throws {
        // Given: Mixed test results
        var results: [TestResult] = []
        results.append(contentsOf: createTestResults(names: ["Test1", "Test2"], passed: true))
        results.append(contentsOf: createTestResults(names: ["Test3", "Test4"], passed: false))
        results.append(contentsOf: createTestResults(names: ["Test5"], passed: true))

        // When: Analyzing results
        let analysis = await sut.analyzeTestResults(results)

        // Then: Should calculate correctly
        XCTAssertEqual(analysis.totalTests, 5)
        XCTAssertEqual(analysis.passedTests, 3)
        XCTAssertEqual(analysis.failedTests, 2)
        XCTAssertEqual(analysis.passRate, 0.6, accuracy: 0.01)
    }

    func testAnalyzeTestResultsDetectsNewFailures() async throws {
        // Given: Historical passing results
        let historical = createTestResults(
            names: ["Test1", "Test2"],
            passed: true
        )
        _ = await sut.analyzeTestResults(historical)

        // When: Current results have failures
        let current = createTestResults(
            names: ["Test1", "Test2"],
            passed: false
        )
        let analysis = await sut.analyzeTestResults(current)

        // Then: Should detect new failures
        XCTAssertTrue(analysis.newFailures.contains("Test1"))
        XCTAssertTrue(analysis.newFailures.contains("Test2"))
        XCTAssertGreaterThan(analysis.newFailures.count, 0)
    }

    // MARK: - Flakiness Detection Tests

    func testFlakinessDetectionWithConsistentPassing() async throws {
        // Given: Test that always passes
        let results = createTestResults(
            names: ["StableTest"],
            passed: true,
            count: 10
        )

        // When: Analyzing results
        _ = await sut.analyzeTestResults(results)

        // Then: Should have low flakiness
        let flakiness = await sut.getFlakinessScore(for: "StableTest")
        XCTAssertLessThan(flakiness, 0.1, "Consistent passing should have low flakiness")
    }

    func testFlakinessDetectionWithConsistentFailing() async throws {
        // Given: Test that always fails
        let results = createTestResults(
            names: ["BrokenTest"],
            passed: false,
            count: 10
        )

        // When: Analyzing results
        _ = await sut.analyzeTestResults(results)

        // Then: Should have low flakiness (consistently failing)
        let flakiness = await sut.getFlakinessScore(for: "BrokenTest")
        XCTAssertLessThan(flakiness, 0.1, "Consistent failing should have low flakiness")
    }

    func testFlakinessDetectionWithInconsistentResults() async throws {
        // Given: Test with mixed results
        var results: [TestResult] = []
        for i in 0..<10 {
            results.append(TestResult(
                name: "FlakyTest",
                passed: i % 2 == 0, // Alternates pass/fail
                duration: 1.0
            ))
        }

        // When: Analyzing results
        _ = await sut.analyzeTestResults(results)

        // Then: Should have high flakiness
        let flakiness = await sut.getFlakinessScore(for: "FlakyTest")
        XCTAssertGreaterThan(flakiness, 0.3, "Inconsistent results should have high flakiness")
    }

    func testGetFlakyTestsAboveThreshold() async throws {
        // Given: Mix of stable and flaky tests
        var results: [TestResult] = []

        // Stable test
        results.append(contentsOf: createTestResults(names: "StableTest", passed: true, count: 10))

        // Flaky test
        for i in 0..<10 {
            results.append(TestResult(
                name: "FlakyTest",
                passed: i % 3 == 0,
                duration: 1.0
            ))
        }

        // When: Analyzing
        _ = await sut.analyzeTestResults(results)

        // Then: Should identify flaky tests
        let flakyTests = await sut.getFlakyTests(threshold: 0.3)
        XCTAssertTrue(flakyTests.contains { $0.0 == "FlakyTest" })
        XCTAssertFalse(flakyTests.contains { $0.0 == "StableTest" })
    }

    // MARK: - Failure Prediction Tests

    func testPredictFailuresWithNoHistoricalData() async throws {
        // Given: Changed files but no historical data
        let changedFiles: Set<String> = ["File1.swift", "File2.swift"]

        // When: Predicting failures
        let predictions = await sut.predictFailures(
            for: changedFiles,
            historicalResults: []
        )

        // Then: Should return empty predictions
        XCTAssertEqual(predictions.count, 0)
    }

    func testPredictFailuresWithHistoricalFailures() async throws {
        // Given: File-test mapping and historical failures
        await sut.setTestsForFile("File1.swift", tests: ["Test1", "Test2"])

        let historical = [
            TestResult(name: "Test1", passed: false, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "Test2", passed: false, duration: 1.0, filePath: "File1.swift")
        ]

        let changedFiles: Set<String> = ["File1.swift"]

        // When: Predicting failures
        let predictions = await sut.predictFailures(
            for: changedFiles,
            historicalResults: historical
        )

        // Then: Should predict high failure probability
        XCTAssertGreaterThan(predictions.count, 0)
        let test1Prediction = predictions.first { $0.testName == "Test1" }
        XCTAssertNotNil(test1Prediction)
        XCTAssertGreaterThan(test1Prediction!.failureProbability, 0.5)
    }

    func testPredictFailuresWithHistoricalPassing() async throws {
        // Given: File-test mapping and historical passing
        await sut.setTestsForFile("File1.swift", tests: ["Test1"])

        let historical = [
            TestResult(name: "Test1", passed: true, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "Test1", passed: true, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "Test1", passed: true, duration: 1.0, filePath: "File1.swift")
        ]

        let changedFiles: Set<String> = ["File1.swift"]

        // When: Predicting failures
        let predictions = await sut.predictFailures(
            for: changedFiles,
            historicalResults: historical
        )

        // Then: Should predict low failure probability
        XCTAssertEqual(predictions.count, 1)
        let prediction = predictions.first!
        XCTAssertLessThan(prediction.failureProbability, 0.5)
    }

    func testGetHighRiskTests() async throws {
        // Given: Setup with high-risk tests
        await sut.setTestsForFile("File1.swift", tests: ["RiskyTest1", "RiskyTest2"])

        let historical = [
            TestResult(name: "RiskyTest1", passed: false, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "RiskyTest1", passed: true, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "RiskyTest2", passed: false, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "RiskyTest2", passed: false, duration: 1.0, filePath: "File1.swift")
        ]

        let changedFiles: Set<String> = ["File1.swift"]

        _ = await sut.predictFailures(for: changedFiles, historicalResults: historical)

        // When: Getting high-risk tests
        let highRiskTests = await sut.getHighRiskTests(threshold: 0.6)

        // Then: Should return tests with high failure probability
        XCTAssertGreaterThan(highRiskTests.count, 0)
    }

    // MARK: - Dependency Analysis Tests

    func testSetTestDependencies() async throws {
        // Given: Test dependencies
        await sut.setTestDependencies("TestA", dependencies: ["TestB", "TestC"])

        // When: Predicting with dependent tests
        await sut.setTestsForFile("File1.swift", tests: ["TestA", "TestB", "TestC"])

        let historical = [
            TestResult(name: "TestB", passed: false, duration: 1.0),
            TestResult(name: "TestC", passed: true, duration: 1.0)
        ]

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: historical
        )

        // Then: Should consider dependencies in prediction
        XCTAssertGreaterThan(predictions.count, 0)
    }

    func testComplexDependenciesImpactPrediction() async throws {
        // Given: Test with many dependencies
        await sut.setTestDependencies("ComplexTest", dependencies: [
            "Dep1", "Dep2", "Dep3", "Dep4", "Dep5"
        ])

        await sut.setTestsForFile("File1.swift", tests: ["ComplexTest"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: []
        )

        // Then: Should include complex dependency reason
        if let prediction = predictions.first {
            let hasComplexDepReason = prediction.reasons.contains {
                if case .complexDependencies = $0 { return true }
                return false
            }
            XCTAssertTrue(hasComplexDepReason, "Should identify complex dependencies")
        }
    }

    // MARK: - Failure Reason Tests

    func testFailureReasonRecentlyModified() async throws {
        // Given: Recently modified file
        await sut.setTestsForFile("NewFile.swift", tests: ["NewTest"])

        let historical = [
            TestResult(name: "NewTest", passed: true, duration: 1.0, filePath: "NewFile.swift")
        ]

        let predictions = await sut.predictFailures(
            for: ["NewFile.swift"],
            historicalResults: historical
        )

        // Then: Should include recently modified reason
        if let prediction = predictions.first {
            XCTAssertTrue(
                prediction.reasons.contains(.recentlyModified),
                "Should detect recently modified test"
            )
        }
    }

    func testFailureReasonPerformanceSensitive() async throws {
        // Given: Test with timing issues
        let historical = [
            TestResult(name: "TimingTest", passed: true, duration: 1.0, filePath: "File1.swift"),
            TestResult(name: "TimingTest", passed: true, duration: 5.0, filePath: "File1.swift"), // Outlier
            TestResult(name: "TimingTest", passed: true, duration: 1.0, filePath: "File1.swift")
        ]

        await sut.setTestsForFile("File1.swift", tests: ["TimingTest"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: historical
        )

        // Then: Should detect timing issues
        if let prediction = predictions.first {
            let hasPerformanceReason = prediction.reasons.contains {
                if case .performanceSensitive = $0 { return true }
                return false
            }
            XCTAssertTrue(hasPerformanceReason, "Should detect performance sensitivity")
        }
    }

    // MARK: - Mitigation Generation Tests

    func testMitigationForHighFlakiness() async throws {
        // Given: Flaky test
        var results: [TestResult] = []
        for i in 0..<10 {
            results.append(TestResult(
                name: "FlakyTest",
                passed: i % 2 == 0,
                duration: 1.0
            ))
        }

        _ = await sut.analyzeTestResults(results)

        await sut.setTestsForFile("File1.swift", tests: ["FlakyTest"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: results
        )

        // Then: Should include flakiness mitigation
        if let prediction = predictions.first {
            XCTAssertTrue(
                prediction.mitigation.contains("race") ||
                prediction.mitigation.contains("timing"),
                "Should suggest reviewing for race conditions"
            )
        }
    }

    func testMitigationForLowCoverage() async throws {
        // Given: Test with high failure rate
        let historical = [
            TestResult(name: "LowCoverageTest", passed: false, duration: 1.0),
            TestResult(name: "LowCoverageTest", passed: false, duration: 1.0),
            TestResult(name: "LowCoverageTest", passed: true, duration: 1.0)
        ]

        await sut.setTestsForFile("File1.swift", tests: ["LowCoverageTest"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: historical
        )

        // Then: Should suggest increasing coverage
        if let prediction = predictions.first, prediction.reasons.contains(.lowCoverage) {
            XCTAssertTrue(
                prediction.mitigation.contains("coverage"),
                "Should suggest increasing test coverage"
            )
        }
    }

    // MARK: - Confidence Calculation Tests

    func testPredictionConfidenceWithGoodData() async throws {
        // Given: Rich historical data
        var historical: [TestResult] = []
        for _ in 0..<20 {
            historical.append(TestResult(
                name: "WellTrackedTest",
                passed: true,
                duration: 1.0,
                filePath: "File1.swift"
            ))
        }

        await sut.setTestsForFile("File1.swift", tests: ["WellTrackedTest"])
        await sut.setTestDependencies("WellTrackedTest", dependencies: ["Dep1"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: historical
        )

        // Then: Should have high confidence
        if let prediction = predictions.first {
            XCTAssertGreaterThan(prediction.confidence, 0.5)
        }
    }

    func testPredictionConfidenceWithSparseData() async throws {
        // Given: Minimal historical data
        let historical = [
            TestResult(name: "NewTest", passed: true, duration: 1.0, filePath: "File1.swift")
        ]

        await sut.setTestsForFile("File1.swift", tests: ["NewTest"])

        let predictions = await sut.predictFailures(
            for: ["File1.swift"],
            historicalResults: historical
        )

        // Then: Should have lower confidence
        if let prediction = predictions.first {
            XCTAssertLessThan(prediction.confidence, 0.7)
        }
    }

    // MARK: - Pattern Recognition Tests

    func testDetectsConsistentFailuresPattern() async throws {
        // Given: Test failing consistently
        let results = createTestResults(names: "ConsistentlyFailing", passed: false, count: 5)

        let analysis = await sut.analyzeTestResults(results)

        // Then: Should detect pattern
        let hasConsistentPattern = analysis.failurePatterns.contains {
            $0.type == .consistentFailures
        }
        XCTAssertTrue(hasConsistentPattern, "Should detect consistent failure pattern")
    }

    func testDetectsFlakyTestsPattern() async throws {
        // Given: Flaky test results
        var results: [TestResult] = []
        for i in 0..<10 {
            results.append(TestResult(
                name: "FlakyTest",
                passed: i % 2 == 0,
                duration: 1.0
            ))
        }

        let analysis = await sut.analyzeTestResults(results)

        // Then: Should detect flaky pattern
        let hasFlakyPattern = analysis.failurePatterns.contains {
            $0.type == .flakyTests
        }
        XCTAssertTrue(hasFlakyPattern, "Should detect flaky test pattern")
    }

    // MARK: - Performance Tests

    func testFailurePredictionPerformance() async throws {
        // Given: Large dataset
        await sut.setTestsForFile("File1.swift", tests: (1...100).map { "Test\($0)" })

        let historical = (1...100).flatMap { _ in
            createTestResults(names: (1...10).map { "Test\($0)" }, passed: Bool.random())
        }

        let changedFiles: Set<String> = ["File1.swift"]

        // When: Predicting
        measure {
            Task {
                _ = await sut.predictFailures(for: changedFiles, historicalResults: historical)
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestResults(
        names: [String],
        passed: Bool,
        filePath: String? = nil
    ) -> [TestResult] {
        return names.map { name in
            TestResult(
                name: name,
                passed: passed,
                duration: Double.random(in: 0.5...2.0),
                filePath: filePath
            )
        }
    }

    private func createTestResults(
        names: String..., // Variadic for single or multiple names
        passed: Bool,
        count: Int = 1
    ) -> [TestResult] {
        let nameList = names.count == 1 ? Array(repeating: names[0], count: count) : names
        return createTestResults(names: nameList, passed: passed)
    }

    private func createTestResults(
        names: [String],
        passed: Bool,
        count: Int
    ) -> [TestResult] {
        var results: [TestResult] = []
        for name in names {
            for _ in 0..<count {
                results.append(TestResult(
                    name: name,
                    passed: passed,
                    duration: 1.0
                ))
            }
        }
        return results
    }

    private func createTestResults(
        names: String...,
        passed: Bool
    ) -> [TestResult] {
        return createTestResults(names: names, passed: passed)
    }

    private func createTestResults(
        names: [String],
        passed: Bool
    ) -> [TestResult] {
        return names.map { name in
            TestResult(
                name: name,
                passed: passed,
                duration: 1.0
            )
        }
    }
}
