//
//  TestExecutionOptimizer.swift
//  WhiteRoomiOS
//
//  Created by AI Assistant on 1/16/25.
//

import Foundation
import XCTest
import Combine

/// Optimizes test execution with intelligent parallelization and scheduling
public class TestExecutionOptimizer: ObservableObject {

    // MARK: - Published Properties

    @Published public var optimizationInProgress: Bool = false
    @Published public var lastOptimizationDate: Date?
    @Published public var executionPlan: ExecutionPlan?

    // MARK: - Private Properties

    private let performanceHistoryStore: PerformanceHistoryStore
    private let maxParallelism: Int
    private let targetSuiteDuration: TimeInterval = 60.0 // Target 1 minute per suite

    // MARK: - Initialization

    public init(
        performanceHistoryStore: PerformanceHistoryStore = .shared,
        maxParallelism: Int = ProcessInfo.processInfo.processorCount
    ) {
        self.performanceHistoryStore = performanceHistoryStore
        self.maxParallelism = maxParallelism
    }

    // MARK: - Public Methods

    /// Creates an optimized execution plan for running tests
    /// - Parameters:
    ///   - tests: Array of test information
    ///   - availableParallelism: Number of parallel execution contexts
    /// - Returns: Optimized execution plan
    public func optimizeExecutionPlan(
        _ tests: [TestInfo],
        availableParallelism: Int
    ) -> ExecutionPlan {
        optimizationInProgress = true
        defer { optimizationInProgress = false }

        let effectiveParallelism = min(availableParallelism, maxParallelism)

        // Load historical performance data
        let testsWithHistory = addHistoricalData(to: tests)

        // Calculate optimal split
        let suites = calculateOptimalSplit(
            tests: testsWithHistory,
            nodeCount: effectiveParallelism
        )

        // Estimate total time
        let estimatedTime = estimateExecutionTime(for: testsWithHistory)

        // Calculate resource usage
        let resourceUsage = estimateResourceUsage(
            for: suites,
            parallelism: effectiveParallelism
        )

        let plan = ExecutionPlan(
            suites: suites,
            estimatedTotalTime: estimatedTime,
            parallelism: effectiveParallelism,
            resourceUsage: resourceUsage
        )

        executionPlan = plan
        lastOptimizationDate = Date()

        return plan
    }

    /// Calculates optimal test suite distribution
    /// - Parameters:
    ///   - tests: Array of test information
    ///   - nodeCount: Number of execution nodes
    /// - Returns: Array of balanced test suites
    public func calculateOptimalSplit(
        tests: [TestInfo],
        nodeCount: Int
    ) -> [TestSuite] {
        guard nodeCount > 0 else {
            return [createSingleSuite(tests)]
        }

        // Sort tests by duration (descending) for optimal packing
        let sortedTests = tests.sorted { $0.averageDuration > $1.averageDuration }

        // Use longest processing time (LPT) algorithm for load balancing
        var suites = Array(repeating: TestSuite.empty, count: nodeCount)

        for test in sortedTests {
            // Find suite with minimum total duration
            if let minIndex = suites.indices.min(by: {
                suites[$0].estimatedDuration < suites[$1].estimatedDuration
            }) {
                suites[minIndex] = suites[minIndex].addingTest(test)
            }
        }

        // Assign node IDs
        for (index, _) in suites.enumerated() {
            suites[index] = TestSuite(
                name: "Suite-\(index)",
                tests: suites[index].tests,
                estimatedDuration: suites[index].estimatedDuration,
                dependencies: suites[index].dependencies,
                node: index
            )
        }

        return suites.filter { !$0.tests.isEmpty }
    }

    /// Estimates execution time for a set of tests
    /// - Parameter tests: Array of test information
    /// - Returns: Estimated execution time in seconds
    public func estimateExecutionTime(for tests: [TestInfo]) -> TimeInterval {
        let baseTime = tests.reduce(0.0) { $0 + $1.averageDuration }

        // Add variance buffer
        let averageVariance = tests.map { $0.variance }.reduce(0, +) / Double(tests.count)
        let varianceBuffer = averageVariance * 1.5

        // Add setup/teardown overhead
        let overhead = TimeInterval(tests.count) * 0.1

        return baseTime + varianceBuffer + overhead
    }

    /// Optimizes execution plan based on previous performance
    /// - Parameter previousPlan: Previous execution plan
    /// - Returns: Optimized execution plan
    public func reoptimizePlan(_ previousPlan: ExecutionPlan) -> ExecutionPlan {
        var allTests: [TestInfo] = []

        // Collect all tests from previous plan
        for suite in previousPlan.suites {
            allTests.append(contentsOf: suite.tests)
        }

        // Re-optimize with updated performance data
        return optimizeExecutionPlan(
            allTests,
            availableParallelism: previousPlan.parallelism
        )
    }

    /// Creates a prioritized execution plan
    /// - Parameters:
    ///   - tests: Array of test information
    ///   - priority: Test priority to focus on
    /// - Returns: Execution plan with priority ordering
    public func createPrioritizedPlan(
        _ tests: [TestInfo],
        priority: TestPriority
    ) -> ExecutionPlan {
        // Filter and sort by priority
        let prioritizedTests = tests
            .filter { shouldInclude(test: $0, priority: priority) }
            .sorted { test1, test2 in
                // Sort by priority first, then duration
                if getPriority(for: test1) != getPriority(for: test2) {
                    return getPriority(for: test1) < getPriority(for: test2)
                }
                return test1.averageDuration < test2.averageDuration
            }

        return optimizeExecutionPlan(prioritizedTests, availableParallelism: 1)
    }

    /// Estimates resource usage for an execution plan
    /// - Parameters:
    ///   - suites: Array of test suites
    ///   - parallelism: Degree of parallelism
    /// - Returns: Resource usage estimate
    public func estimateResourceUsage(
        for suites: [TestSuite],
        parallelism: Int
    ) -> ResourceUsage {
        let totalTests = suites.reduce(0) { $0 + $1.tests.count }
        let estimatedMemory = estimateMemoryUsage(
            testCount: totalTests,
            parallelism: parallelism
        )
        let estimatedCPU = Double(parallelism) / Double(ProcessInfo.processInfo.processorCount)

        return ResourceUsage(
            estimatedMemoryMB: estimatedMemory,
            estimatedCPUPercentage: estimatedCPU * 100,
            estimatedDiskIO: 0, // Would be calculated based on test operations
            estimatedNetworkIO: 0 // Would be calculated based on test operations
        )
    }

    /// Validates execution plan for potential issues
    /// - Parameter plan: Execution plan to validate
    /// - Returns: Validation result with warnings and errors
    public func validatePlan(_ plan: ExecutionPlan) -> ValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        // Check for empty suites
        let emptySuites = plan.suites.filter { $0.tests.isEmpty }
        if !emptySuites.isEmpty {
            warnings.append("\(emptySuites.count) empty suites in execution plan")
        }

        // Check for imbalance
        let durations = plan.suites.map { $0.estimatedDuration }
        if let maxDuration = durations.max(),
           let minDuration = durations.min(),
           maxDuration > minDuration * 2 {
            warnings.append("Significant suite imbalance: max \(maxDuration)s vs min \(minDuration)s")
        }

        // Check for resource constraints
        if plan.resourceUsage.estimatedCPUPercentage > 100 {
            errors.append("Estimated CPU usage exceeds 100%")
        }

        // Check for dependency violations
        for suite in plan.suites {
            let suiteTestNames = Set(suite.tests.map { $0.name })
            for test in suite.tests {
                for dependency in test.dependencies {
                    if !suiteTestNames.contains(dependency) {
                        warnings.append("Test '\(test.name)' depends on '\(dependency)' which may not be in the same suite")
                    }
                }
            }
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            warnings: warnings,
            errors: errors
        )
    }

    /// Gets execution strategy recommendation
    /// - Parameter tests: Array of test information
    /// - Returns: Recommended execution strategy
    public func getExecutionStrategy(for tests: [TestInfo]) -> ExecutionStrategy {
        let totalDuration = estimateExecutionTime(for: tests)
        let testCount = tests.count
        let slowTests = tests.filter { $0.isSlow }.count

        if totalDuration < 30 {
            return .sequential // Fast enough to run sequentially
        } else if slowTests > testCount / 2 {
            return .parallel // Many slow tests, benefit from parallelization
        } else if testCount > 100 {
            return .sharded // Too many tests for single execution
        } else {
            return .parallel // Default to parallel
        }
    }

    // MARK: - Private Methods

    private func addHistoricalData(to tests: [TestInfo]) -> [TestInfo] {
        return tests.map { test in
            let history = performanceHistoryStore.getHistory(for: test.name)

            var updatedTest = test
            if let averageDuration = history?.averageDuration {
                updatedTest = TestInfo(
                    name: test.name,
                    filePath: test.filePath,
                    averageDuration: averageDuration,
                    variance: history?.variance ?? test.variance,
                    dependencies: test.dependencies,
                    isSlow: averageDuration > 1.0,
                    tags: test.tags
                )
            }
            return updatedTest
        }
    }

    private func createSingleSuite(_ tests: [TestInfo]) -> TestSuite {
        return TestSuite(
            name: "DefaultSuite",
            tests: tests,
            estimatedDuration: estimateExecutionTime(for: tests),
            dependencies: [],
            node: 0
        )
    }

    private func shouldInclude(test: TestInfo, priority: TestPriority) -> Bool {
        let testPriority = getPriority(for: test)
        return testPriority.rawValue <= priority.rawValue
    }

    private func getPriority(for test: TestInfo) -> TestPriority {
        if test.tags.contains("critical") {
            return .critical
        } else if test.tags.contains("high") {
            return .high
        } else if test.tags.contains("low") {
            return .low
        } else {
            return .medium
        }
    }

    private func estimateMemoryUsage(testCount: Int, parallelism: Int) -> Int {
        // Base memory per test execution
        let memoryPerTest = 10 // MB
        // Base overhead for test runner
        let overhead = 100 // MB
        return overhead + (testCount * memoryPerTest / parallelism)
    }
}

// MARK: - Supporting Types

public struct ExecutionPlan: Identifiable, Codable {
    public let id = UUID()
    let suites: [TestSuite]
    let estimatedTotalTime: TimeInterval
    let parallelism: Int
    let resourceUsage: ResourceUsage
}

public struct TestSuite: Identifiable, Codable {
    public let id = UUID()
    let name: String
    let tests: [TestInfo]
    let estimatedDuration: TimeInterval
    let dependencies: [String]
    let node: Int?

    static let empty = TestSuite(
        name: "Empty",
        tests: [],
        estimatedDuration: 0,
        dependencies: [],
        node: nil
    )

    func addingTest(_ test: TestInfo) -> TestSuite {
        return TestSuite(
            name: name,
            tests: tests + [test],
            estimatedDuration: estimatedDuration + test.averageDuration,
            dependencies: dependencies,
            node: node
        )
    }
}

public struct TestInfo: Identifiable, Codable {
    public let id = UUID()
    let name: String
    let filePath: String
    let averageDuration: TimeInterval
    let variance: Double
    let dependencies: [String]
    let isSlow: Bool
    let tags: [String]
}

public struct ResourceUsage: Codable {
    let estimatedMemoryMB: Int
    let estimatedCPUPercentage: Double
    let estimatedDiskIO: Int64
    let estimatedNetworkIO: Int64
}

public struct ValidationResult {
    let isValid: Bool
    let warnings: [String]
    let errors: [String]
}

public enum TestPriority: Int, Comparable, Codable {
    case critical = 1
    case high = 2
    case medium = 3
    case low = 4

    public static func < (lhs: TestPriority, rhs: TestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum ExecutionStrategy {
    case sequential
    case parallel
    case sharded
}

// MARK: - Performance History Store

public class PerformanceHistoryStore {
    public static let shared = PerformanceHistoryStore()

    private var history: [String: TestPerformanceHistory] = [:]

    public func getHistory(for testName: String) -> TestPerformanceHistory? {
        return history[testName]
    }

    public func recordPerformance(_ testName: String, duration: TimeInterval) {
        if history[testName] == nil {
            history[testName] = TestPerformanceHistory(
                testName: testName,
                averageDuration: duration,
                variance: 0,
                sampleCount: 1
            )
        } else {
            var updated = history[testName]!
            updated.sampleCount += 1

            // Update average using moving average
            let oldAverage = updated.averageDuration
            updated.averageDuration = (oldAverage * Double(updated.sampleCount - 1) + duration) / Double(updated.sampleCount)

            // Update variance
            let diff = duration - oldAverage
            updated.variance = (updated.variance * Double(updated.sampleCount - 1) + diff * diff) / Double(updated.sampleCount)

            history[testName] = updated
        }
    }

    public func clearHistory() {
        history.removeAll()
    }
}

public struct TestPerformanceHistory {
    let testName: String
    var averageDuration: TimeInterval
    var variance: Double
    var sampleCount: Int
}
