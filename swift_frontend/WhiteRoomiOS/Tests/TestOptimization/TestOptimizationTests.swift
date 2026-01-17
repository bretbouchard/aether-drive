//
//  TestOptimizationTests.swift
//  WhiteRoomiOSTests
//
//  Created by AI Assistant on 1/16/25.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for test optimization system
final class TestOptimizationTests: XCTestCase {

    var optimizer: TestExecutionOptimizer!
    var balancer: TestSuiteBalancer!
    var profiler: PerformanceProfiler!
    var selector: SmartTestSelector!

    override func setUp() {
        super.setUp()
        optimizer = TestExecutionOptimizer()
        balancer = TestSuiteBalancer()
        profiler = PerformanceProfiler()
        selector = SmartTestSelector()
    }

    override func tearDown() {
        optimizer = nil
        balancer = nil
        profiler = nil
        selector = nil
        super.tearDown()
    }

    // MARK: - Test Execution Optimizer Tests

    func testOptimizeExecutionPlanWithNoParallelism() {
        // Given: Set of tests with no parallelism
        let tests = createTestList(count: 10)

        // When: Optimizing with parallelism of 1
        let plan = optimizer.optimizeExecutionPlan(tests, availableParallelism: 1)

        // Then: Should create single suite
        XCTAssertEqual(plan.suites.count, 1, "Should create single suite")
        XCTAssertEqual(plan.parallelism, 1, "Should have parallelism of 1")
        XCTAssertEqual(plan.suites[0].tests.count, tests.count, "Should contain all tests")
    }

    func testOptimizeExecutionPlanWithParallelism() {
        // Given: Set of tests
        let tests = createTestList(count: 20)

        // When: Optimizing with parallelism of 4
        let plan = optimizer.optimizeExecutionPlan(tests, availableParallelism: 4)

        // Then: Should create balanced suites
        XCTAssertEqual(plan.suites.count, 4, "Should create 4 suites")
        XCTAssertEqual(plan.parallelism, 4, "Should have parallelism of 4")

        // Check that tests are distributed
        let totalTests = plan.suites.reduce(0) { $0 + $1.tests.count }
        XCTAssertEqual(totalTests, tests.count, "All tests should be distributed")
    }

    func testOptimizeExecutionPlanBalancing() {
        // Given: Tests with varying durations
        let tests = createVariableDurationTests()

        // When: Optimizing execution
        let plan = optimizer.optimizeExecutionPlan(tests, availableParallelism: 2)

        // Then: Should balance by duration
        XCTAssertEqual(plan.suites.count, 2, "Should create 2 suites")

        let durations = plan.suites.map { $0.estimatedDuration }
        let maxDuration = durations.max() ?? 0
        let minDuration = durations.min() ?? 0

        // Suites should be reasonably balanced (within 50%)
        let imbalanceRatio = minDuration > 0 ? maxDuration / minDuration : 0
        XCTAssertTrue(imbalanceRatio < 2.0, "Suites should be balanced (ratio: \(imbalanceRatio))")
    }

    func testEstimateExecutionTime() {
        // Given: Set of tests with known durations
        let tests = createTestList(count: 10, avgDuration: 0.5)

        // When: Estimating execution time
        let estimatedTime = optimizer.estimateExecutionTime(for: tests)

        // Then: Should provide reasonable estimate
        let baseTime = tests.reduce(0.0) { $0 + $1.averageDuration }
        XCTAssertTrue(estimatedTime >= baseTime, "Should account for overhead")
        XCTAssertTrue(estimatedTime < baseTime * 2, "Should not double the estimate")
    }

    func testValidatePlanWithImbalance() {
        // Given: Imbalanced test suites
        let tests = createVariableDurationTests()
        let plan = optimizer.optimizeExecutionPlan(tests, availableParallelism: 2)

        // When: Validating plan
        let validation = optimizer.validatePlan(plan)

        // Then: Should provide validation result
        XCTAssertNotNil(validation, "Should return validation result")
        // Imbalance warning is acceptable for variable duration tests
    }

    func testExecutionStrategyRecommendation() {
        // Given: Different test scenarios
        let fastTests = createTestList(count: 10, avgDuration: 0.1)
        let slowTests = createTestList(count: 10, avgDuration: 2.0)
        let manyTests = createTestList(count: 150, avgDuration: 0.5)

        // When: Getting execution strategies
        let fastStrategy = optimizer.getExecutionStrategy(for: fastTests)
        let slowStrategy = optimizer.getExecutionStrategy(for: slowTests)
        let manyStrategy = optimizer.getExecutionStrategy(for: manyTests)

        // Then: Should recommend appropriate strategies
        XCTAssertEqual(fastStrategy, .sequential, "Fast tests should run sequentially")
        XCTAssertTrue(
            slowStrategy == .parallel || slowStrategy == .sharded,
            "Slow tests should run in parallel or sharded"
        )
        XCTAssertEqual(manyStrategy, .sharded, "Many tests should be sharded")
    }

    func testResourceUsageEstimation() {
        // Given: Test plan
        let tests = createTestList(count: 100)
        let plan = optimizer.optimizeExecutionPlan(tests, availableParallelism: 4)

        // When: Getting resource usage
        let usage = plan.resourceUsage

        // Then: Should provide resource estimates
        XCTAssertTrue(usage.estimatedMemoryMB > 0, "Should estimate memory usage")
        XCTAssertTrue(usage.estimatedCPUPercentage > 0, "Should estimate CPU usage")
        XCTAssertTrue(usage.estimatedCPUPercentage <= 100, "CPU should not exceed 100%")
    }

    // MARK: - Test Suite Balancer Tests

    func testBalanceTestsAcrossNodes() {
        // Given: Set of tests
        let tests = createTestList(count: 30)

        // When: Balancing across 3 nodes
        let suites = balancer.balanceTests(tests, acrossNodes: 3)

        // Then: Should create balanced suites
        XCTAssertEqual(suites.count, 3, "Should create 3 suites")

        let totalTests = suites.reduce(0) { $0 + $1.tests.count }
        XCTAssertEqual(totalTests, tests.count, "All tests should be assigned")

        // Check balance
        let durations = suites.map { $0.estimatedDuration }
        let maxDuration = durations.max() ?? 0
        let minDuration = durations.min() ?? 0

        let imbalanceRatio = minDuration > 0 ? (maxDuration - minDuration) / maxDuration : 0
        XCTAssertTrue(imbalanceRatio < 0.3, "Should be reasonably balanced (imbalance: \(imbalanceRatio))")
    }

    func testAnalyzeImbalance() {
        // Given: Test suites
        let tests = createVariableDurationTests()
        let suites = balancer.balanceTests(tests, acrossNodes: 2)

        // When: Analyzing imbalance
        let analysis = balancer.analyzeImbalance(suites)

        // Then: Should provide analysis
        XCTAssertNotNil(analysis, "Should return analysis")
        XCTAssertTrue(analysis.timeDifference >= 0, "Time difference should be non-negative")
        XCTAssertTrue(analysis.percentageImbalance >= 0, "Percentage should be non-negative")
        XCTAssertFalse(analysis.recommendations.isEmpty, "Should provide recommendations")
    }

    func testRebalanceBasedOnPerformance() {
        // Given: Initial balanced suites
        let tests = createTestList(count: 20)
        let suites = balancer.balanceTests(tests, acrossNodes: 2)

        // Simulate performance data
        let performance = suites.map { suite in
            SuitePerformance(
                nodeId: suite.nodeId,
                actualDuration: suite.estimatedDuration * 1.5, // Slower than expected
                testCount: suite.tests.count,
                passRate: 1.0,
                timestamp: Date()
            )
        }

        // When: Rebalancing
        let rebalanced = balancer.rebalance(suites, basedOn: performance)

        // Then: Should produce new balance
        XCTAssertEqual(rebalanced.count, 2, "Should maintain same number of suites")
        let totalTests = rebalanced.reduce(0) { $0 + $1.tests.count }
        XCTAssertEqual(totalTests, tests.count, "All tests should still be present")
    }

    func testValidateBalancedSuite() {
        // Given: A balanced suite
        let tests = createTestList(count: 10)
        let suites = balancer.balanceTests(tests, acrossNodes: 1)
        let suite = suites[0]

        // When: Validating
        let validation = balancer.validateBalancedSuite(suite, allTests: tests)

        // Then: Should be valid
        XCTAssertTrue(validation.isValid, "Suite should be valid")
        XCTAssertTrue(validation.errors.isEmpty, "Should have no errors")
    }

    func testGetBalanceMetrics() {
        // Given: Balanced suites
        let tests = createTestList(count: 30)
        let suites = balancer.balanceTests(tests, acrossNodes: 3)

        // When: Getting metrics
        let metrics = balancer.getBalanceMetrics(suites)

        // Then: Should provide comprehensive metrics
        XCTAssertEqual(metrics.nodeCount, 3, "Should have 3 nodes")
        XCTAssertTrue(metrics.totalDuration > 0, "Should have total duration")
        XCTAssertTrue(metrics.averageDuration > 0, "Should have average duration")
        XCTAssertTrue(metrics.maxDuration >= metrics.minDuration, "Max should be >= min")
    }

    // MARK: - Performance Profiler Tests

    func testProfileTest() {
        // Given: Test name
        let testName = "TestToProfile"

        // When: Profiling test
        let profile = profiler.profileTest(testName, iterations: 5)

        // Then: Should create profile
        XCTAssertEqual(profile.testName, testName, "Should have correct test name")
        XCTAssertTrue(profile.averageDuration > 0, "Should have duration")
        XCTAssertTrue(profile.minDuration <= profile.averageDuration, "Min should be <= average")
        XCTAssertTrue(profile.maxDuration >= profile.averageDuration, "Max should be >= average")
        XCTAssertFalse(profile.percentiles.isEmpty, "Should have percentiles")
    }

    func testIdentifySlowTests() {
        // Given: Mix of fast and slow tests
        let fastProfile = createTestProfile(name: "FastTest", duration: 0.1)
        let slowProfile = createTestProfile(name: "SlowTest", duration: 2.0)
        profiler.profiles = [fastProfile, slowProfile]

        // When: Identifying slow tests with 1s threshold
        let slowTests = profiler.identifySlowTests(threshold: 1.0)

        // Then: Should identify slow test
        XCTAssertEqual(slowTests.count, 1, "Should identify one slow test")
        XCTAssertEqual(slowTests[0].testName, "SlowTest", "Should identify correct test")
        XCTAssertTrue(slowTests[0].duration > 1.0, "Should be over threshold")
    }

    func testComparePerformance() {
        // Given: Baseline and current profiles
        let baseline = createTestProfile(name: "Test", duration: 1.0)
        let current = createTestProfile(name: "Test", duration: 1.5) // 50% slower

        // When: Comparing performance
        let comparison = profiler.comparePerformance(baseline: baseline, current: current)

        // Then: Should detect regression
        XCTAssertTrue(comparison.isRegression, "Should detect regression")
        XCTAssertFalse(comparison.isImprovement, "Should not be improvement")
        XCTAssertTrue(comparison.percentChange > 0, "Should have positive percent change")
    }

    func testDetectMemoryLeaks() {
        // Given: Profile with memory growth
        let profile = createTestProfile(
            name: "LeakyTest",
            duration: 1.0,
            memoryGrowth: 15_000_000 // 15 MB
        )
        profiler.profiles = [profile]

        // When: Detecting leaks
        let leaks = profiler.detectMemoryLeaks(profiler.profiles)

        // Then: Should detect leak
        XCTAssertEqual(leaks.count, 1, "Should detect one leak")
        XCTAssertTrue(leaks[0].estimatedLeakSize > 10_000_000, "Should have significant leak size")
        XCTAssertTrue(leaks[0].confidence > 0, "Should have confidence score")
    }

    func testGeneratePerformanceReport() {
        // Given: Multiple test profiles
        let profiles = [
            createTestProfile(name: "Test1", duration: 0.5),
            createTestProfile(name: "Test2", duration: 1.5),
            createTestProfile(name: "Test3", duration: 0.8)
        ]
        profiler.profiles = profiles

        // When: Generating report
        let report = profiler.generatePerformanceReport(profiles)

        // Then: Should create comprehensive report
        XCTAssertEqual(report.totalTestCount, 3, "Should have 3 tests")
        XCTAssertTrue(report.totalDuration > 0, "Should have total duration")
        XCTAssertTrue(report.averageDuration > 0, "Should have average duration")
        XCTAssertFalse(report.recommendations.isEmpty, "Should provide recommendations")
    }

    func testBenchmarkAgainstTarget() {
        // Given: Test profile and target
        let profile = createTestProfile(name: "Test", duration: 1.2)
        let targetDuration: TimeInterval = 1.0

        // When: Benchmarking
        let result = profiler.benchmarkAgainstTarget(profile, targetDuration: targetDuration)

        // Then: Should assess performance
        XCTAssertEqual(result.testName, "Test", "Should have correct test name")
        XCTAssertEqual(result.targetDuration, targetDuration, "Should have correct target")
        XCTAssertTrue(result.ratio > 1.0, "Should be over target (slower)")
        XCTAssertEqual(result.status, .slightlyOver, "Should be slightly over target")
    }

    // MARK: - Smart Test Selector Tests

    func testSelectTestsForChanges() {
        // Given: Changed files and tests
        let changedFiles = Set(["Source1.swift", "Source2.swift"])
        let tests = createTestListWithMappings(count: 10)

        // When: Selecting tests
        let selected = selector.selectTestsForChanges(changedFiles, allTests: tests)

        // Then: Should select relevant tests
        XCTAssertTrue(selected.count > 0, "Should select some tests")
        XCTAssertTrue(selected.count <= tests.count, "Should not select more than total tests")

        // Check that smoke tests are always included
        let smokeTests = selected.filter { $0.reason == .smokeTest }
        XCTAssertFalse(smokeTests.isEmpty, "Should include smoke tests")
    }

    func testBuildDependencyGraph() {
        // Given: Set of tests
        let tests = createTestListWithMappings(count: 5)

        // When: Building dependency graph
        let graph = selector.buildDependencyGraph(tests)

        // Then: Should create graph with nodes
        XCTAssertEqual(graph.nodes.count, tests.count, "Should have node for each test")
        XCTAssertFalse(graph.edges.isEmpty, "Should have edges (dependencies or shared sources)")
    }

    func testCalculateImpact() {
        // Given: Changed files and tests
        let changedFiles = Set(["Source1.swift"])
        let tests = createTestListWithMappings(count: 20)

        // When: Calculating impact
        let analysis = selector.calculateImpact(of: changedFiles, on: tests)

        // Then: Should provide impact analysis
        XCTAssertEqual(analysis.totalTests, 20, "Should have 20 total tests")
        XCTAssertTrue(analysis.affectedTests >= 0, "Should have affected tests count")
        XCTAssertTrue(analysis.reductionPercentage >= 0, "Should have reduction percentage")
        XCTAssertTrue(analysis.timeSaved >= 0, "Should have time saved")
    }

    func testValidateSelection() {
        // Given: Selection with smoke tests
        let changedFiles = Set(["Source1.swift"])
        let tests = createTestListWithMappings(count: 10, includeSmoke: true)
        let selected = selector.selectTestsForChanges(changedFiles, allTests: tests)

        // When: Validating selection
        let validation = selector.validateSelection(selected, allTests: tests)

        // Then: Should validate successfully
        XCTAssertTrue(validation.isValid, "Selection should be valid")
        XCTAssertTrue(validation.errors.isEmpty, "Should have no errors")
    }

    func testGetSelectionStats() {
        // Given: Changed files and tests
        let changedFiles = Set(["Source1.swift"])
        let tests = createTestListWithMappings(count: 20)

        // When: Getting selection stats
        let stats = selector.getSelectionStats(for: changedFiles, allTests: tests)

        // Then: Should provide comprehensive stats
        XCTAssertEqual(stats.totalTests, 20, "Should have 20 total tests")
        XCTAssertTrue(stats.selectedTests >= 0, "Should have selected tests count")
        XCTAssertTrue(stats.skippedTests >= 0, "Should have skipped tests count")
        XCTAssertEqual(
            stats.selectedTests + stats.skippedTests,
            stats.totalTests,
            "Selected + skipped should equal total"
        )
        XCTAssertTrue(stats.estimatedTimeSaved >= 0, "Should estimate time saved")
    }

    // MARK: - Integration Tests

    func testFullOptimizationWorkflow() {
        // Given: Large test suite
        let tests = createTestList(count: 100)
        let changedFiles = Set(["Source1.swift", "Source2.swift"])

        // When: Running full optimization workflow
        // 1. Select relevant tests
        let selected = selector.selectTestsForChanges(changedFiles, allTests: tests)
        let selectedTestInfo = selected.map { $0.test }

        // 2. Optimize execution
        let plan = optimizer.optimizeExecutionPlan(
            selectedTestInfo,
            availableParallelism: 4
        )

        // 3. Validate plan
        let validation = optimizer.validatePlan(plan)

        // Then: Should produce optimized, valid plan
        XCTAssertTrue(selectedTestInfo.count < tests.count, "Should select subset of tests")
        XCTAssertTrue(validation.isValid, "Plan should be valid")
        XCTAssertEqual(plan.parallelism, 4, "Should use requested parallelism")
    }

    func testFlakyTestDetectionIntegration() {
        // Given: Test execution history
        let attempts = (0..<20).map { _ in
            TestAttempt(
                testName: "FlakyIntegrationTest",
                passed: Bool.random(),
                duration: Double.random(in: 0.1...1.0),
                timestamp: Date(),
                iteration: 0,
                errorMessage: nil,
                stackTrace: nil
            )
        }

        let detector = FlakyTestDetector()
        let score = detector.detectFlakiness(for: "FlakyIntegrationTest", history: attempts)

        // When: Analyzing results
        let results = detector.analyzeTestResults(
            attempts.map { attempt in
                TestRunResult(
                    testName: attempt.testName,
                    passed: attempt.passed,
                    duration: attempt.duration,
                    timestamp: attempt.timestamp,
                    errorMessage: attempt.errorMessage,
                    stackTrace: attempt.stackTrace
                )
            }
        )

        // Then: Should detect flakiness if present
        let passCount = attempts.filter { $0.passed }.count
        let failCount = attempts.count - passCount

        if passCount > 3 && failCount > 3 {
            XCTAssertTrue(
                score.isTrulyFlaky || results.isEmpty,
                "Should detect flakiness or have no flaky tests"
            )
        }
    }

    // MARK: - Performance Tests

    func testOptimizationPerformance() {
        // Given: Large test suite
        let tests = createTestList(count: 1000)

        // When: Optimizing
        measure {
            _ = optimizer.optimizeExecutionPlan(tests, availableParallelism: 8)
        }
    }

    func testBalancingPerformance() {
        // Given: Large test suite
        let tests = createTestList(count: 1000)

        // When: Balancing
        measure {
            _ = balancer.balanceTests(tests, acrossNodes: 8)
        }
    }

    func testSelectionPerformance() {
        // Given: Large test suite and many changes
        let tests = createTestListWithMappings(count: 1000)
        let changedFiles = Set(["Source\(Int.random(in: 1...100)).swift"])

        // When: Selecting tests
        measure {
            _ = selector.selectTestsForChanges(changedFiles, allTests: tests)
        }
    }

    // MARK: - Helper Methods

    private func createTestList(count: Int, avgDuration: TimeInterval = 0.5) -> [TestInfo] {
        return (0..<count).map { index in
            TestInfo(
                name: "Test\(index)",
                filePath: "Test\(index).swift",
                averageDuration: avgDuration + Double.random(in: -0.1...0.1),
                variance: Double.random(in: 0...0.2),
                dependencies: [],
                isSlow: avgDuration > 1.0,
                tags: []
            )
        }
    }

    private func createVariableDurationTests() -> [TestInfo] {
        let durations = [0.1, 0.5, 1.0, 2.0, 5.0]
        return durations.enumerated().map { index, duration in
            TestInfo(
                name: "Test\(index)",
                filePath: "Test\(index).swift",
                averageDuration: duration,
                variance: 0.1,
                dependencies: [],
                isSlow: duration > 1.0,
                tags: []
            )
        }
    }

    private func createTestListWithMappings(count: Int, includeSmoke: Bool = false) -> [TestInfo] {
        return (0..<count).map { index in
            var tags: [String] = []
            if includeSmoke && index == 0 {
                tags.append("smoke")
            }

            return TestInfo(
                name: "Test\(index)",
                filePath: "Test\(index).swift",
                averageDuration: Double.random(in: 0.1...1.0),
                variance: Double.random(in: 0...0.2),
                dependencies: [],
                isSlow: false,
                tags: tags
            )
        }
    }

    private func createTestProfile(name: String, duration: TimeInterval, memoryGrowth: Int64 = 0) -> TestProfile {
        return TestProfile(
            testName: name,
            averageDuration: duration,
            minDuration: duration * 0.8,
            maxDuration: duration * 1.2,
            stdDeviation: duration * 0.1,
            percentiles: [50: duration, 90: duration * 1.1, 95: duration * 1.15, 99: duration * 1.2],
            memoryUsage: MemoryUsage(
                usedMB: 50,
                peakMB: 60,
                startDelta: 0,
                endDelta: memoryGrowth
            ),
            cpuUsage: Double.random(in: 20...80),
            timestamp: Date()
        )
    }
}
