//
//  SmartTestSelector.swift
//  WhiteRoomiOS
//
//  Created by AI Assistant on 1/16/25.
//

import Foundation
import Combine

/// Intelligently selects tests based on code changes to reduce CI time
public class SmartTestSelector: ObservableObject {

    // MARK: - Published Properties

    @Published public var selectionInProgress: Bool = false
    @Published public var lastSelectionDate: Date?
    @Published public var dependencyGraph: TestDependencyGraph?

    // MARK: - Private Properties

    private let codebaseAnalyzer: CodebaseAnalyzer
    private let testMapper: TestFileMapper
    private let impactCalculator: TestImpactCalculator

    // MARK: - Initialization

    public init(
        codebaseAnalyzer: CodebaseAnalyzer = .shared,
        testMapper: TestFileMapper = .shared,
        impactCalculator: TestImpactCalculator = .shared
    ) {
        self.codebaseAnalyzer = codebaseAnalyzer
        self.testMapper = testMapper
        self.impactCalculator = impactCalculator
    }

    // MARK: - Public Methods

    /// Selects tests based on changed files
    /// - Parameters:
    ///   - changedFiles: Set of changed file paths
    ///   - allTests: Array of all available tests
    /// - Returns: Array of selected tests with reasons
    public func selectTestsForChanges(
        _ changedFiles: Set<String>,
        allTests: [TestInfo]
    ) -> [SelectedTest] {
        selectionInProgress = true
        defer { selectionInProgress = false }

        var selectedTests: [SelectedTest] = []

        // Always include smoke tests
        let smokeTests = allTests.filter { $0.tags.contains("smoke") }
        for smokeTest in smokeTests {
            selectedTests.append(SelectedTest(
                test: smokeTest,
                reason: .smokeTest,
                priority: .critical,
                estimatedImpact: 1.0
            ))
        }

        // Build dependency graph if not exists
        if dependencyGraph == nil {
            dependencyGraph = buildDependencyGraph(allTests)
        }

        // Find affected tests
        let affectedTests = findAffectedTests(
            changedFiles: changedFiles,
            allTests: allTests
        )

        // Categorize and prioritize affected tests
        for test in affectedTests {
            let reason = determineSelectionReason(for: test, changedFiles: changedFiles)
            let priority = calculatePriority(for: test, reason: reason)
            let impact = estimateImpact(for: test, changedFiles: changedFiles)

            selectedTests.append(SelectedTest(
                test: test,
                reason: reason,
                priority: priority,
                estimatedImpact: impact
            ))
        }

        // Sort by priority and impact
        selectedTests.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.estimatedImpact > rhs.estimatedImpact
        }

        lastSelectionDate = Date()

        return selectedTests
    }

    /// Builds a dependency graph of tests and source files
    /// - Parameter tests: Array of test information
    /// - Returns: Test dependency graph
    public func buildDependencyGraph(_ tests: [TestInfo]) -> TestDependencyGraph {
        var nodes: [TestNode] = []
        var edges: [DependencyEdge] = []

        // Create nodes for each test
        for test in tests {
            let sourceFiles = testMapper.getSourceFiles(for: test.name)
            let dependencies = testMapper.getDependencies(for: test.name)

            let node = TestNode(
                testName: test.name,
                sourceFiles: sourceFiles,
                dependencies: dependencies,
                tags: test.tags
            )
            nodes.append(node)
        }

        // Create edges based on dependencies
        for node in nodes {
            for dependency in node.dependencies {
                if let dependentNode = nodes.first(where: { $0.testName == dependency }) {
                    let edge = DependencyEdge(
                        from: node.testName,
                        to: dependentNode.testName,
                        type: .directDependency
                    )
                    edges.append(edge)
                }
            }
        }

        // Create edges based on shared source files
        for (i, node1) in nodes.enumerated() {
            for node2 in nodes.dropFirst(i + 1) {
                let sharedFiles = Set(node1.sourceFiles).intersection(Set(node2.sourceFiles))
                if !sharedFiles.isEmpty {
                    let edge = DependencyEdge(
                        from: node1.testName,
                        to: node2.testName,
                        type: .sharedSource
                    )
                    edges.append(edge)
                }
            }
        }

        let graph = TestDependencyGraph(nodes: nodes, edges: edges)
        dependencyGraph = graph

        return graph
    }

    /// Calculates impact of changes on tests
    /// - Parameters:
    ///   - changedFiles: Set of changed file paths
    ///   - tests: Array of test information
    /// - Returns: Impact analysis
    public func calculateImpact(
        of changedFiles: Set<String>,
        on tests: [TestInfo]
    ) -> ImpactAnalysis {
        let totalTests = tests.count

        let selectedTests = selectTestsForChanges(changedFiles, allTests: tests)
        let affectedTests = selectedTests.count

        let reductionPercentage = totalTests > 0 ?
            (1.0 - Double(affectedTests) / Double(totalTests)) * 100 : 0

        let timeSaved = estimateTimeSaved(
            totalTests: tests,
            selectedTests: selectedTests
        )

        let riskLevel = assessRisk(
            changedFiles: changedFiles,
            selectedTests: selectedTests
        )

        return ImpactAnalysis(
            totalTests: totalTests,
            affectedTests: affectedTests,
            reductionPercentage: reductionPercentage,
            riskAssessment: riskLevel,
            timeSaved: timeSaved
        )
    }

    /// Gets comprehensive selection statistics
    /// - Parameters:
    ///   - changedFiles: Set of changed file paths
    ///   - allTests: Array of all available tests
    /// - Returns: Selection statistics
    public func getSelectionStats(
        for changedFiles: Set<String>,
        allTests: [TestInfo]
    ) -> SelectionStats {
        let selectedTests = selectTestsForChanges(changedFiles, allTests: allTests)

        let criticalCount = selectedTests.filter { $0.priority == .critical }.count
        let highCount = selectedTests.filter { $0.priority == .high }.count
        let mediumCount = selectedTests.filter { $0.priority == .medium }.count
        let lowCount = selectedTests.filter { $0.priority == .low }.count

        let reasonCounts = Dictionary(grouping: selectedTests, by: { $0.reason })
            .mapValues { $0.count }

        return SelectionStats(
            totalTests: allTests.count,
            selectedTests: selectedTests.count,
            skippedTests: allTests.count - selectedTests.count,
            criticalCount: criticalCount,
            highCount: highCount,
            mediumCount: mediumCount,
            lowCount: lowCount,
            reasonCounts: reasonCounts,
            estimatedTimeSaved: estimateTimeSaved(
                totalTests: allTests,
                selectedTests: selectedTests
            )
        )
    }

    /// Validates selection to ensure critical tests aren't missed
    /// - Parameters:
    ///   - selectedTests: Array of selected tests
    ///   - allTests: Array of all available tests
    /// - Returns: Validation result
    public func validateSelection(
        _ selectedTests: [SelectedTest],
        allTests: [TestInfo]
    ) -> SelectionValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        // Check for missing smoke tests
        let smokeTests = allTests.filter { $0.tags.contains("smoke") }
        let selectedSmokeTests = selectedTests.filter { $0.test.tags.contains("smoke") }

        if selectedSmokeTests.count < smokeTests.count {
            errors.append("Missing smoke tests - all smoke tests should be included")
        }

        // Check if selection is too small
        let selectionRatio = Double(selectedTests.count) / Double(allTests.count)
        if selectionRatio < 0.1 { // Less than 10%
            warnings.append("Selection is very small (\(String(format: "%.1f", selectionRatio * 100))%) - consider running more tests")
        }

        // Check for missing integration tests
        let integrationTests = allTests.filter { $0.tags.contains("integration") }
        let selectedIntegrationTests = selectedTests.filter { $0.test.tags.contains("integration") }

        if integrationTests.count > 0 && selectedIntegrationTests.count == 0 {
            warnings.append("No integration tests selected - consider adding some for coverage")
        }

        return SelectionValidationResult(
            isValid: errors.isEmpty,
            warnings: warnings,
            errors: errors
        )
    }

    // MARK: - Private Methods

    private func findAffectedTests(
        changedFiles: Set<String>,
        allTests: [TestInfo]
    ) -> [TestInfo] {
        var affected: Set<TestInfo> = []

        guard let graph = dependencyGraph else {
            return allTests
        }

        // Find tests that directly test changed files
        for test in allTests {
            if let node = graph.nodes.first(where: { $0.testName == test.name }) {
                let testFiles = Set(node.sourceFiles)

                if !testFiles.intersection(changedFiles).isEmpty {
                    affected.insert(test)
                }
            }
        }

        // Find tests that depend on affected tests
        var added = true
        while added {
            added = false

            for edge in graph.edges {
                let fromTest = allTests.first { $0.name == edge.from }
                let toTest = allTests.first { $0.name == edge.to }

                if let from = fromTest, let to = toTest {
                    if affected.contains(from) && !affected.contains(to) {
                        affected.insert(to)
                        added = true
                    }
                }
            }
        }

        return Array(affected)
    }

    private func determineSelectionReason(
        for test: TestInfo,
        changedFiles: Set<String>
    ) -> SelectionReason {
        if let node = dependencyGraph?.nodes.first(where: { $0.testName == test.name }) {
            let testFiles = Set(node.sourceFiles)

            if !testFiles.intersection(changedFiles).isEmpty {
                return .directlyTestsChangedCode
            }

            if test.tags.contains("integration") {
                return .integrationTest
            }

            if test.tags.contains("regression") {
                return .regressionTest
            }

            return .testsDependency
        }

        return .smokeTest
    }

    private func calculatePriority(
        for test: TestInfo,
        reason: SelectionReason
    ) -> TestPriority {
        // Check explicit tags first
        if test.tags.contains("critical") {
            return .critical
        } else if test.tags.contains("high") {
            return .high
        } else if test.tags.contains("low") {
            return .low
        }

        // Determine from reason
        switch reason {
        case .smokeTest:
            return .critical
        case .directlyTestsChangedCode:
            return .high
        case .testsDependency:
            return .medium
        case .integrationTest:
            return .high
        case .regressionTest:
            return .medium
        }
    }

    private func estimateImpact(
        for test: TestInfo,
        changedFiles: Set<String>
    ) -> Double {
        var impact = 0.5 // Base impact

        // Increase impact for critical tests
        if test.tags.contains("critical") {
            impact += 0.3
        }

        // Increase impact for tests that directly touch changed code
        if let node = dependencyGraph?.nodes.first(where: { $0.testName == test.name }) {
            let testFiles = Set(node.sourceFiles)
            let intersection = testFiles.intersection(changedFiles)

            if !intersection.isEmpty {
                impact += 0.2
            }
        }

        return min(impact, 1.0)
    }

    private func estimateTimeSaved(
        totalTests: [TestInfo],
        selectedTests: [SelectedTest]
    ) -> TimeInterval {
        let totalTime = totalTests.reduce(0.0) { $0 + $1.averageDuration }
        let selectedTime = selectedTests.reduce(0.0) { $0 + $1.test.averageDuration }

        return totalTime - selectedTime
    }

    private func assessRisk(
        changedFiles: Set<String>,
        selectedTests: [SelectedTest]
    ) -> RiskLevel {
        // Check for critical file changes
        let criticalFiles = changedFiles.filter { file in
            file.contains("Core") || file.contains("Manager") || file.contains("Engine")
        }

        if !criticalFiles.isEmpty && selectedTests.count < 10 {
            return .high
        } else if selectedTests.count < 5 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Supporting Types

public struct SelectedTest: Identifiable, Codable {
    public let id = UUID()
    let test: TestInfo
    let reason: SelectionReason
    let priority: TestPriority
    let estimatedImpact: Double
}

public enum SelectionReason: String, CaseIterable, Codable {
    case directlyTestsChangedCode = "Directly Tests Changed Code"
    case testsDependency = "Tests Dependency"
    case integrationTest = "Integration Test"
    case smokeTest = "Smoke Test"
    case regressionTest = "Regression Test"
}

public struct TestDependencyGraph: Codable {
    let nodes: [TestNode]
    let edges: [DependencyEdge]

    /// Finds all tests affected by changed files
    public func findAffectedTests(changedFiles: Set<String>) -> Set<String> {
        var affected: Set<String> = []

        // Find tests that directly test changed files
        for node in nodes {
            let testFiles = Set(node.sourceFiles)
            if !testFiles.intersection(changedFiles).isEmpty {
                affected.insert(node.testName)
            }
        }

        // Find tests that depend on affected tests
        var added = true
        while added {
            added = false

            for edge in edges {
                if affected.contains(edge.from) && !affected.contains(edge.to) {
                    affected.insert(edge.to)
                    added = true
                }
            }
        }

        return affected
    }

    /// Gets all tests that depend on a given test
    public func getDependents(of testName: String) -> Set<String> {
        var dependents: Set<String> = []

        for edge in edges {
            if edge.from == testName {
                dependents.insert(edge.to)
            }
        }

        return dependents
    }
}

public struct TestNode: Identifiable, Codable {
    public let id = UUID()
    let testName: String
    let sourceFiles: [String]
    let dependencies: [String]
    let tags: [String]
}

public struct DependencyEdge: Identifiable, Codable {
    public let id = UUID()
    let from: String
    let to: String
    let type: EdgeType
}

public enum EdgeType: String, CaseIterable, Codable {
    case directDependency = "Direct Dependency"
    case sharedSource = "Shared Source"
    case transitive = "Transitive"
}

public struct ImpactAnalysis: Identifiable {
    public let id = UUID()
    let totalTests: Int
    let affectedTests: Int
    let reductionPercentage: Double
    let riskAssessment: RiskLevel
    let timeSaved: TimeInterval
}

public enum RiskLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public struct SelectionStats: Identifiable {
    public let id = UUID()
    let totalTests: Int
    let selectedTests: Int
    let skippedTests: Int
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let reasonCounts: [SelectionReason: Int]
    let estimatedTimeSaved: TimeInterval
}

public struct SelectionValidationResult {
    let isValid: Bool
    let warnings: [String]
    let errors: [String]
}

// MARK: - Analyzer Classes

public class CodebaseAnalyzer {
    public static let shared = CodebaseAnalyzer()

    private init() {}

    public func analyzeDependencies(for file: String) -> [String] {
        // Analyze imports and dependencies
        return []
    }
}

public class TestFileMapper {
    public static let shared = TestFileMapper()

    private var testToSourceMap: [String: [String]] = [:]

    private init() {
        buildMapping()
    }

    private func buildMapping() {
        // Map test files to source files
        // This would scan the codebase and build the mapping
    }

    public func getSourceFiles(for testName: String) -> [String] {
        return testToSourceMap[testName] ?? []
    }

    public func getDependencies(for testName: String) -> [String] {
        // Get test dependencies
        return []
    }
}

public class TestImpactCalculator {
    public static let shared = TestImpactCalculator()

    private init() {}

    public func calculateImpact(
        for testName: String,
        changedFiles: Set<String>
    ) -> Double {
        // Calculate impact score
        return 0.5
    }
}
