//
//  TestSuiteBalancer.swift
//  WhiteRoomiOS
//
//  Created by AI Assistant on 1/16/25.
//

import Foundation
import Combine

/// Balances test suites across CI nodes for optimal execution
public class TestSuiteBalancer: ObservableObject {

    // MARK: - Published Properties

    @Published public var balancingInProgress: Bool = false
    @Published public var lastBalanceDate: Date?
    @Published public var imbalanceThreshold: Double = 0.1 // 10% imbalance threshold

    // MARK: - Private Properties

    private let performanceStore: SuitePerformanceStore
    private let balanceAlgorithm: BalancingAlgorithm

    // MARK: - Initialization

    public init(
        performanceStore: SuitePerformanceStore = .shared,
        balanceAlgorithm: BalancingAlgorithm = .longestProcessingTime
    ) {
        self.performanceStore = performanceStore
        self.balanceAlgorithm = balanceAlgorithm
    }

    // MARK: - Public Methods

    /// Balances tests across multiple nodes
    /// - Parameters:
    ///   - tests: Array of test information
    ///   - nodeCount: Number of CI nodes
    /// - Returns: Array of balanced test suites
    public func balanceTests(
        _ tests: [TestInfo],
        acrossNodes nodeCount: Int
    ) -> [BalancedSuite] {
        balancingInProgress = true
        defer { balancingInProgress = false }

        guard nodeCount > 0 else {
            return [BalancedSuite(nodeId: 0, tests: tests, estimatedDuration: estimateDuration(tests), totalWeight: calculateTotalWeight(tests))]
        }

        let balancedSuites: [BalancedSuite]

        switch balanceAlgorithm {
        case .longestProcessingTime:
            balancedSuites = balanceUsingLPT(tests, acrossNodes: nodeCount)
        case .greedy:
            balancedSuites = balanceUsingGreedy(tests, acrossNodes: nodeCount)
        case .weighted:
            balancedSuites = balanceUsingWeights(tests, acrossNodes: nodeCount)
        }

        lastBalanceDate = Date()

        return balancedSuites
    }

    /// Rebalances suites based on actual performance data
    /// - Parameters:
    ///   - suites: Current balanced suites
    ///   - performance: Actual performance data from previous runs
    /// - Returns: Rebalanced suites
    public func rebalance(
        _ suites: [BalancedSuite],
        basedOn performance: [SuitePerformance]
    ) -> [BalancedSuite] {
        // Update performance data
        for perf in performance {
            performanceStore.updatePerformance(perf)
        }

        // Collect all tests
        var allTests: [TestInfo] = []
        for suite in suites {
            allTests.append(contentsOf: suite.tests)
        }

        // Rebalance with updated performance data
        return balanceTests(allTests, acrossNodes: suites.count)
    }

    /// Analyzes imbalance in current distribution
    /// - Parameter suites: Array of balanced suites
    /// - Returns: Imbalance analysis with recommendations
    public func analyzeImbalance(_ suites: [BalancedSuite]) -> ImbalanceAnalysis {
        guard !suites.isEmpty else {
            return ImbalanceAnalysis(
                timeDifference: 0,
                percentageImbalance: 0,
                recommendations: []
            )
        }

        let durations = suites.map { $0.estimatedDuration }
        guard let maxDuration = durations.max(),
              let minDuration = durations.min() else {
            return ImbalanceAnalysis(
                timeDifference: 0,
                percentageImbalance: 0,
                recommendations: []
            )
        }

        let timeDifference = maxDuration - minDuration
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let percentageImbalance = averageDuration > 0 ? (timeDifference / averageDuration) * 100 : 0

        var recommendations: [String] = []

        if percentageImbalance > imbalanceThreshold * 100 {
            recommendations.append("Significant imbalance detected (\(String(format: "%.1f", percentageImbalance))%)")
            recommendations.append("Consider rebalancing tests across nodes")

            // Find overutilized and underutilized nodes
            let avgTime = averageDuration
            for (index, suite) in suites.enumerated() {
                if suite.estimatedDuration > avgTime * 1.2 {
                    recommendations.append("Node \(suite.nodeId) is overutilized (20%+ above average)")
                } else if suite.estimatedDuration < avgTime * 0.8 {
                    recommendations.append("Node \(suite.nodeId) is underutilized (20%+ below average)")
                }
            }
        } else {
            recommendations.append("Test distribution is well balanced")
        }

        return ImbalanceAnalysis(
            timeDifference: timeDifference,
            percentageImbalance: percentageImbalance,
            recommendations: recommendations
        )
    }

    /// Optimizes for heterogeneous CI nodes (different performance characteristics)
    /// - Parameters:
    ///   - tests: Array of test information
    ///   - nodes: Array of node specifications
    /// - Returns: Array of balanced suites
    public func balanceForHeterogeneousNodes(
        _ tests: [TestInfo],
        nodes: [NodeSpecification]
    ) -> [BalancedSuite] {
        var remainingTests = tests
        var suites: [BalancedSuite] = []

        // Sort nodes by performance (fastest first)
        let sortedNodes = nodes.sorted { $0.performanceFactor > $1.performanceFactor }

        // Allocate tests proportionally to node performance
        for node in sortedNodes {
            let totalPerformance = sortedNodes.reduce(0.0) { $0 + $1.performanceFactor }
            let nodeShare = node.performanceFactor / totalPerformance
            let targetDuration = estimateTotalDuration(tests) * nodeShare

            let (suiteTests, remaining) = selectTestsForTarget(
                remainingTests,
                targetDuration: targetDuration
            )

            suites.append(BalancedSuite(
                nodeId: node.id,
                tests: suiteTests,
                estimatedDuration: estimateDuration(suiteTests),
                totalWeight: calculateTotalWeight(suiteTests)
            ))

            remainingTests = remaining
        }

        return suites
    }

    /// Validates balanced suite for correctness
    /// - Parameters:
    ///   - suite: Balanced suite to validate
    ///   - allTests: All tests that should be distributed
    /// - Returns: Validation result
    public func validateBalancedSuite(
        _ suite: BalancedSuite,
        allTests: [TestInfo]
    ) -> BalanceValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Check for duplicate tests
        let testNames = suite.tests.map { $0.name }
        let duplicates = Set(testNames.filter { testNames.count(of: $0) > 1 })
        if !duplicates.isEmpty {
            errors.append("Duplicate tests found: \(duplicates.joined(separator: ", "))")
        }

        // Check for missing dependencies
        let suiteTestNames = Set(testNames)
        for test in suite.tests {
            for dependency in test.dependencies {
                if !suiteTestNames.contains(dependency) {
                    warnings.append("Test '\(test.name)' depends on '\(dependency)' which is not in the suite")
                }
            }
        }

        // Check for empty suite
        if suite.tests.isEmpty {
            warnings.append("Suite contains no tests")
        }

        // Check if suite is too long
        if suite.estimatedDuration > 300 { // 5 minutes
            warnings.append("Suite duration exceeds 5 minutes (\(String(format: "%.1f", suite.estimatedDuration))s)")
        }

        return BalanceValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    /// Gets balance metrics for monitoring
    /// - Parameter suites: Array of balanced suites
    /// - Returns: Balance metrics
    public func getBalanceMetrics(_ suites: [BalancedSuite]) -> BalanceMetrics {
        guard !suites.isEmpty else {
            return BalanceMetrics(
                totalDuration: 0,
                averageDuration: 0,
                maxDuration: 0,
                minDuration: 0,
                stdDeviation: 0,
                nodeCount: 0
            )
        }

        let durations = suites.map { $0.estimatedDuration }
        let total = durations.reduce(0, +)
        let average = total / Double(durations.count)
        let max = durations.max() ?? 0
        let min = durations.min() ?? 0

        // Calculate standard deviation
        let variance = durations.map { pow($0 - average, 2) }.reduce(0, +) / Double(durations.count)
        let stdDeviation = sqrt(variance)

        return BalanceMetrics(
            totalDuration: total,
            averageDuration: average,
            maxDuration: max,
            minDuration: min,
            stdDeviation: stdDeviation,
            nodeCount: suites.count
        )
    }

    // MARK: - Private Methods

    private func balanceUsingLPT(_ tests: [TestInfo], acrossNodes nodeCount: Int) -> [BalancedSuite] {
        // Sort tests by duration (descending)
        let sortedTests = tests.sorted { $0.averageDuration > $1.averageDuration }

        // Initialize suites
        var suites = Array(repeating: BalancedSuite.empty, count: nodeCount)

        // Assign each test to the suite with minimum total duration
        for test in sortedTests {
            if let minIndex = suites.indices.min(by: {
                suites[$0].estimatedDuration < suites[$1].estimatedDuration
            }) {
                suites[minIndex] = suites[minIndex].addingTest(test)
            }
        }

        // Assign proper node IDs
        for (index, _) in suites.enumerated() {
            suites[index] = BalancedSuite(
                nodeId: index,
                tests: suites[index].tests,
                estimatedDuration: suites[index].estimatedDuration,
                totalWeight: suites[index].totalWeight
            )
        }

        return suites.filter { !$0.tests.isEmpty }
    }

    private func balanceUsingGreedy(_ tests: [TestInfo], acrossNodes nodeCount: Int) -> [BalancedSuite] {
        // Sort tests by duration (ascending)
        let sortedTests = tests.sorted { $0.averageDuration < $1.averageDuration }

        // Initialize suites
        var suites = Array(repeating: BalancedSuite.empty, count: nodeCount)

        // Assign each test to the suite with minimum total duration
        for test in sortedTests {
            if let minIndex = suites.indices.min(by: {
                suites[$0].estimatedDuration < suites[$1].estimatedDuration
            }) {
                suites[minIndex] = suites[minIndex].addingTest(test)
            }
        }

        // Assign proper node IDs
        for (index, _) in suites.enumerated() {
            suites[index] = BalancedSuite(
                nodeId: index,
                tests: suites[index].tests,
                estimatedDuration: suites[index].estimatedDuration,
                totalWeight: suites[index].totalWeight
            )
        }

        return suites.filter { !$0.tests.isEmpty }
    }

    private func balanceUsingWeights(_ tests: [TestInfo], acrossNodes nodeCount: Int) -> [BalancedSuite] {
        // Calculate total weight
        let totalWeight = tests.reduce(0.0) { $0 + calculateWeight($1) }
        let targetWeightPerSuite = totalWeight / Double(nodeCount)

        var suites: [BalancedSuite] = []
        var remainingTests = tests

        for nodeId in 0..<nodeCount {
            var suiteTests: [TestInfo] = []
            var currentWeight = 0.0
            var remaining: [TestInfo] = []

            for test in remainingTests {
                let testWeight = calculateWeight(test)
                if currentWeight + testWeight <= targetWeightPerSuite || suiteTests.isEmpty {
                    suiteTests.append(test)
                    currentWeight += testWeight
                } else {
                    remaining.append(test)
                }
            }

            suites.append(BalancedSuite(
                nodeId: nodeId,
                tests: suiteTests,
                estimatedDuration: estimateDuration(suiteTests),
                totalWeight: currentWeight
            ))

            remainingTests = remaining
        }

        // Add any remaining tests to the last suite
        if !remainingTests.isEmpty {
            let lastIndex = suites.count - 1
            let lastSuite = suites[lastIndex]
            let combinedTests = lastSuite.tests + remainingTests

            suites[lastIndex] = BalancedSuite(
                nodeId: lastSuite.nodeId,
                tests: combinedTests,
                estimatedDuration: estimateDuration(combinedTests),
                totalWeight: lastSuite.totalWeight + remainingTests.reduce(0.0) { calculateWeight($1) }
            )
        }

        return suites
    }

    private func selectTestsForTarget(
        _ tests: [TestInfo],
        targetDuration: TimeInterval
    ) -> ([TestInfo], [TestInfo]) {
        var selected: [TestInfo] = []
        var remaining = tests
        var currentDuration: TimeInterval = 0

        // Sort by descending duration for better packing
        remaining.sort { $0.averageDuration > $1.averageDuration }

        for test in remaining {
            if currentDuration + test.averageDuration <= targetDuration || selected.isEmpty {
                selected.append(test)
                currentDuration += test.averageDuration
            } else {
                break
            }
        }

        let remainingTests = Array(remaining.dropFirst(selected.count))
        return (selected, remainingTests)
    }

    private func calculateWeight(_ test: TestInfo) -> Double {
        // Weight is based on duration with variance adjustment
        return test.averageDuration * (1 + test.variance)
    }

    private func calculateTotalWeight(_ tests: [TestInfo]) -> Double {
        return tests.reduce(0.0) { $0 + calculateWeight($1) }
    }

    private func estimateDuration(_ tests: [TestInfo]) -> TimeInterval {
        return tests.reduce(0.0) { $0 + $1.averageDuration }
    }

    private func estimateTotalDuration(_ tests: [TestInfo]) -> TimeInterval {
        return tests.reduce(0.0) { $0 + $1.averageDuration }
    }
}

// MARK: - Supporting Types

public struct BalancedSuite: Identifiable, Codable {
    public let id = UUID()
    let nodeId: Int
    let tests: [TestInfo]
    let estimatedDuration: TimeInterval
    let totalWeight: Double

    static let empty = BalancedSuite(
        nodeId: -1,
        tests: [],
        estimatedDuration: 0,
        totalWeight: 0
    )

    func addingTest(_ test: TestInfo) -> BalancedSuite {
        return BalancedSuite(
            nodeId: nodeId,
            tests: tests + [test],
            estimatedDuration: estimatedDuration + test.averageDuration,
            totalWeight: totalWeight + TestSuiteBalancer.calculateWeight(test)
        )
    }
}

public struct SuitePerformance: Identifiable, Codable {
    public let id = UUID()
    let nodeId: Int
    let actualDuration: TimeInterval
    let testCount: Int
    let passRate: Double
    let timestamp: Date
}

public struct ImbalanceAnalysis: Identifiable {
    public let id = UUID()
    let timeDifference: TimeInterval
    let percentageImbalance: Double
    let recommendations: [String]
}

public struct BalanceValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

public struct BalanceMetrics {
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let maxDuration: TimeInterval
    let minDuration: TimeInterval
    let stdDeviation: TimeInterval
    let nodeCount: Int
}

public struct NodeSpecification: Identifiable {
    public let id = UUID()
    let nodeId: Int
    let performanceFactor: Double // 1.0 = baseline, >1.0 = faster
    let memoryMB: Int
    let cpuCores: Int
}

public enum BalancingAlgorithm {
    case longestProcessingTime
    case greedy
    case weighted
}

// MARK: - Performance Store

public class SuitePerformanceStore {
    public static let shared = SuitePerformanceStore()

    private var performanceHistory: [String: [SuitePerformance]] = [:]

    public func updatePerformance(_ performance: SuitePerformance) {
        let key = "\(performance.nodeId)"
        if performanceHistory[key] == nil {
            performanceHistory[key] = []
        }
        performanceHistory[key]?.append(performance)
    }

    public func getAveragePerformance(for nodeId: Int) -> SuitePerformance? {
        let key = "\(nodeId)"
        guard let performances = performanceHistory[key], !performances.isEmpty else {
            return nil
        }

        let count = performances.count
        let avgDuration = performances.reduce(0.0) { $0 + $1.actualDuration } / Double(count)
        let avgPassRate = performances.reduce(0.0) { $0 + $1.passRate } / Double(count)

        return SuitePerformance(
            nodeId: nodeId,
            actualDuration: avgDuration,
            testCount: performances[0].testCount,
            passRate: avgPassRate,
            timestamp: Date()
        )
    }

    public func clearHistory() {
        performanceHistory.removeAll()
    }
}

// MARK: - Static Helper Extension

extension TestSuiteBalancer {
    static func calculateWeight(_ test: TestInfo) -> Double {
        return test.averageDuration * (1 + test.variance)
    }
}
