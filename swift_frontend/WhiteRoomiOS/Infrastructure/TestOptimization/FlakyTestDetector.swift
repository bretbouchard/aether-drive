//
//  FlakyTestDetector.swift
//  WhiteRoomiOS
//
//  Created by AI Assistant on 1/16/25.
//

import Foundation
import XCTest
import Combine

/// Detects and analyzes flaky tests with intelligent pattern recognition
public class FlakyTestDetector: ObservableObject {

    // MARK: - Published Properties

    @Published public var flakyTests: [FlakyTest] = []
    @Published public var detectionInProgress: Bool = false
    @Published public var lastDetectionDate: Date?

    // MARK: - Private Properties

    private let historyStore: TestHistoryStore
    private let quarantinedTestsStore: QuarantinedTestsStore
    private let minimumIterations: Int = 10
    private let flakinessThreshold: Double = 0.3

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        historyStore: TestHistoryStore = .shared,
        quarantinedTestsStore: QuarantinedTestsStore = .shared
    ) {
        self.historyStore = historyStore
        self.quarantinedTestsStore = quarantinedTestsStore
        loadQuarantinedTests()
    }

    // MARK: - Public Methods

    /// Analyzes test results to detect flaky behavior
    /// - Parameter results: Array of test run results
    /// - Returns: Array of detected flaky tests
    public func analyzeTestResults(_ results: [TestRunResult]) -> [FlakyTest] {
        detectionInProgress = true
        defer { detectionInProgress = false }

        var detectedFlakyTests: [FlakyTest] = []
        let groupedResults = Dictionary(grouping: results) { $0.testName }

        for (testName, testAttempts) in groupedResults {
            let flakinessScore = detectFlakiness(for: testName, history: testAttempts)

            if flakinessScore.isTrulyFlaky {
                let flakyTest = createFlakyTest(
                    testName: testName,
                    attempts: testAttempts,
                    score: flakinessScore
                )
                detectedFlakyTests.append(flakyTest)
            }
        }

        flakyTests = detectedFlakyTests
        lastDetectionDate = Date()

        return detectedFlakyTests
    }

    /// Detects flakiness for a specific test
    /// - Parameters:
    ///   - testName: Name of the test
    ///   - history: Array of test attempts
    /// - Returns: Flakiness score with confidence metrics
    public func detectFlakiness(
        for testName: String,
        history: [TestAttempt]
    ) -> FlakinessScore {
        guard history.count >= minimumIterations else {
            return FlakinessScore(
                overall: 0,
                confidence: 0,
                inconsistencyRate: 0,
                isTrulyFlaky: false
            )
        }

        let passCount = history.filter { $0.passed }.count
        let failCount = history.count - passCount

        // Calculate overall flakiness (0 = always passes, 1 = always fails)
        let overall = Double(failCount) / Double(history.count)

        // Calculate confidence based on sample size
        let confidence = min(Double(history.count) / Double(minimumIterations * 2), 1.0)

        // Calculate inconsistency rate (how unpredictable the test is)
        let passRate = Double(passCount) / Double(history.count)
        let inconsistencyRate = 1.0 - abs(passRate - 0.5) * 2 // 1 if 50/50 split, 0 if consistent

        // A test is truly flaky if:
        // 1. It has some failures (overall > 0)
        // 2. It's not always failing (overall < 1)
        // 3. It's somewhat unpredictable
        // 4. We have enough confidence
        let isTrulyFlaky = overall > 0 && overall < 1 &&
                          inconsistencyRate > flakinessThreshold &&
                          confidence > 0.5

        return FlakinessScore(
            overall: overall,
            confidence: confidence,
            inconsistencyRate: inconsistencyRate,
            isTrulyFlaky: isTrulyFlaky
        )
    }

    /// Attempts to automatically fix a flaky test
    /// - Parameter flakyTest: The flaky test to fix
    /// - Returns: Suggested fix or throws if unable to fix
    public func autoFix(_ flakyTest: FlakyTest) throws -> FixSuggestion {
        guard let topCause = flakyTest.likelyCauses.first else {
            throw FlakyTestError.noIdentifiedCause
        }

        let fix = generateFix(for: topCause, test: flakyTest)

        // Store the suggestion for tracking
        historyStore.recordFixSuggestion(fix, for: flakyTest.testName)

        return fix
    }

    /// Quarantines a flaky test to prevent CI failures
    /// - Parameters:
    ///   - testName: Name of the test to quarantine
    ///   - reason: Reason for quarantine
    public func quarantineTest(_ testName: String, reason: String) {
        let quarantine = QuarantinedTest(
            testName: testName,
            reason: reason,
            quarantinedAt: Date(),
            quarantinedBy: "FlakyTestDetector"
        )

        quarantinedTestsStore.add(quarantine)

        // Log the quarantine
        logQuarantine(testName: testName, reason: reason)
    }

    /// Releases a test from quarantine
    /// - Parameter testName: Name of the test to release
    public func releaseFromQuarantine(_ testName: String) {
        quarantinedTestsStore.remove(testName)
    }

    /// Gets all quarantined tests
    /// - Returns: Array of quarantined tests
    public func getQuarantinedTests() -> [QuarantinedTest] {
        return quarantinedTestsStore.getAll()
    }

    /// Runs a test multiple times to detect flakiness
    /// - Parameters:
    ///   - testName: Name of the test
    ///   - iterations: Number of iterations (default: 10)
    /// - Returns: Array of test attempts
    public func runTestMultipleTimes(
        _ testName: String,
        iterations: Int = 10
    ) async throws -> [TestAttempt] {
        var attempts: [TestAttempt] = []

        for iteration in 0..<iterations {
            let result = try await runSingleTestIteration(testName)
            let attempt = TestAttempt(
                testName: testName,
                passed: result.passed,
                duration: result.duration,
                timestamp: Date(),
                iteration: iteration,
                errorMessage: result.errorMessage,
                stackTrace: result.stackTrace
            )
            attempts.append(attempt)
        }

        // Store attempts for future analysis
        historyStore.recordAttempts(attempts, for: testName)

        return attempts
    }

    /// Gets flakiness trends over time for a test
    /// - Parameter testName: Name of the test
    /// - Returns: Array of historical flakiness scores
    public func getFlakinessTrend(for testName: String) -> [FlakinessDataPoint] {
        return historyStore.getFlakinessHistory(for: testName)
    }

    /// Suggests improvements to reduce flakiness
    /// - Parameter flakyTest: The flaky test to improve
    /// - Returns: Array of improvement suggestions
    public func suggestImprovements(for flakyTest: FlakyTest) -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []

        for cause in flakyTest.likelyCauses {
            switch cause {
            case .timingDependency:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .addExplicitWait,
                        description: "Add explicit wait for async operations to complete",
                        priority: .high,
                        codeExample: """
                        // Wait for expectation
                        let expectation = XCTestExpectation(description: "Async operation")
                        asyncOperation { expectation.fulfill() }
                        wait(for: [expectation], timeout: 5.0)
                        """
                    )
                )

            case .asyncRaceCondition:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .synchronizeAsync,
                        description: "Synchronize async operations using expectations or dispatch groups",
                        priority: .high,
                        codeExample: """
                        let group = DispatchGroup()
                        group.enter()
                        group.enter()

                        asyncOperation1 { group.leave() }
                        asyncOperation2 { group.leave() }

                        group.notify(queue: .main) {
                            // Verify both operations completed
                        }
                        """
                    )
                )

            case .sharedState:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .isolateState,
                        description: "Isolate test state or use setUp/tearDown properly",
                        priority: .high,
                        codeExample: """
                        override func setUp() {
                            super.setUp()
                            // Reset shared state
                            SharedStateManager.reset()
                        }

                        override func tearDown() {
                            // Clean up
                            SharedStateManager.reset()
                            super.tearDown()
                        }
                        """
                    )
                )

            case .networkDependency:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .mockNetwork,
                        description: "Mock network calls to avoid external dependencies",
                        priority: .high,
                        codeExample: """
                        let mockSession = MockURLSession()
                        mockSession.data = testData
                        mockSession.statusCode = 200

                        let client = APIClient(session: mockSession)
                        """
                    )
                )

            case .environmentDependency:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .controlEnvironment,
                        description: "Control environment variables or use test-specific configuration",
                        priority: .medium,
                        codeExample: """
                        override func setUp() {
                            super.setUp()
                            // Set test environment
                            ProcessInfo.processInfo.environment["TEST_MODE"] = "true"
                        }
                        """
                    )
                )

            case .orderDependency:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .makeIndependent,
                        description: "Ensure tests don't depend on execution order",
                        priority: .medium,
                        codeExample: """
                        // Each test should be independent
                        func testFeatureA() {
                            // Complete setup for A
                            let context = setupTestContext()
                            // Test A
                        }
                        """
                    )
                )

            case .resourceLeak:
                suggestions.append(
                    ImprovementSuggestion(
                        type: .cleanupResources,
                        description: "Ensure proper cleanup in tearDown",
                        priority: .high,
                        codeExample: """
                        override func tearDown() {
                            // Release resources
                            testResource = nil
                            super.tearDown()
                        }
                        """
                    )
                )
            }
        }

        return suggestions
    }

    // MARK: - Private Methods

    private func createFlakyTest(
        testName: String,
        attempts: [TestAttempt],
        score: FlakinessScore
    ) -> FlakyTest {
        let filePath = extractFilePath(from: testName)
        let failurePatterns = analyzeFailurePatterns(attempts)
        let likelyCauses = determineCauses(patterns: failurePatterns, attempts: attempts)
        let suggestedFixes = generateFixes(for: likelyCauses)

        let failures = attempts.filter { !$0.passed }
        let lastOccurrence = failures.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date()

        return FlakyTest(
            testName: testName,
            filePath: filePath,
            flakinessScore: score.overall,
            failurePatterns: failurePatterns,
            likelyCauses: likelyCauses,
            suggestedFixes: suggestedFixes,
            lastOccurrence: lastOccurrence,
            occurrenceCount: failures.count
        )
    }

    private func analyzeFailurePatterns(_ attempts: [TestAttempt]) -> [FailurePattern] {
        var patterns: [FailurePattern] = []

        let failures = attempts.filter { !$0.passed }
        guard !failures.isEmpty else { return patterns }

        // Analyze timing patterns
        let durations = attempts.map { $0.duration }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let slowFailures = failures.filter { $0.duration > avgDuration * 2 }

        if slowFailures.count > failures.count / 2 {
            patterns.append(.timingRelated)
        }

        // Analyze error message patterns
        let errorMessages = failures.compactMap { $0.errorMessage }
        let uniqueErrors = Set(errorMessages)

        if uniqueErrors.count > 1 {
            patterns.append(.inconsistentErrors)
        }

        // Analyze intermittent pattern
        let passRate = Double(attempts.filter { $0.passed }.count) / Double(attempts.count)
        if passRate > 0.3 && passRate < 0.7 {
            patterns.append(.intermittent)
        }

        // Analyze stack trace patterns
        let stackTraces = failures.compactMap { $0.stackTrace }
        let uniqueTraces = Set(stackTraces)

        if uniqueTraces.count > 1 {
            patterns.append(.multipleFailurePoints)
        }

        return patterns
    }

    private func determineCauses(
        patterns: [FailurePattern],
        attempts: [TestAttempt]
    ) -> [FlakinessCause] {
        var causes: [FlakinessCause] = []

        for pattern in patterns {
            switch pattern {
            case .timingRelated:
                causes.append(.timingDependency)

            case .intermittent:
                causes.append(.asyncRaceCondition)
                causes.append(.sharedState)

            case .inconsistentErrors:
                causes.append(.orderDependency)
                causes.append(.environmentDependency)

            case .multipleFailurePoints:
                causes.append(.resourceLeak)
                causes.append(.sharedState)
            }
        }

        // Analyze error messages for specific causes
        let failures = attempts.filter { !$0.passed }
        for failure in failures {
            if let message = failure.errorMessage {
                if message.contains("timeout") || message.contains("wait") {
                    causes.append(.timingDependency)
                }
                if message.contains("network") || message.contains("connection") {
                    causes.append(.networkDependency)
                }
                if message.contains("nil") || message.contains("unwrapping") {
                    causes.append(.asyncRaceCondition)
                }
            }
        }

        return Array(Set(causes))
    }

    private func generateFixes(for causes: [FlakinessCause]) -> [FixSuggestion] {
        return causes.map { cause in
            FixSuggestion(
                cause: cause,
                description: getDescription(for: cause),
                codeExample: getCodeExample(for: cause),
                priority: getPriority(for: cause)
            )
        }
    }

    private func generateFix(for cause: FlakinessCause, test: FlakyTest) -> FixSuggestion {
        return FixSuggestion(
            cause: cause,
            description: getDescription(for: cause),
            codeExample: getCodeExample(for: cause),
            priority: getPriority(for: cause)
        )
    }

    private func getDescription(for cause: FlakinessCause) -> String {
        switch cause {
        case .timingDependency:
            return "Add explicit waits or increase timeout for async operations"
        case .asyncRaceCondition:
            return "Synchronize async operations to prevent race conditions"
        case .sharedState:
            return "Isolate test state or reset in setUp/tearDown"
        case .networkDependency:
            return "Mock network calls to eliminate external dependencies"
        case .environmentDependency:
            return "Control environment variables for consistent test execution"
        case .orderDependency:
            return "Make tests independent of execution order"
        case .resourceLeak:
            return "Ensure proper cleanup of resources in tearDown"
        }
    }

    private func getCodeExample(for cause: FlakinessCause) -> String {
        switch cause {
        case .timingDependency:
            return """
            let expectation = XCTestExpectation(description: "Async operation")
            asyncOperation { expectation.fulfill() }
            wait(for: [expectation], timeout: 5.0)
            """
        case .asyncRaceCondition:
            return """
            let group = DispatchGroup()
            group.enter()
            asyncOperation { group.leave() }
            group.wait()
            """
        case .sharedState:
            return """
            override func setUp() {
                super.setUp()
                SharedStateManager.reset()
            }
            """
        case .networkDependency:
            return """
            let mockSession = MockURLSession()
            let client = APIClient(session: mockSession)
            """
        case .environmentDependency:
            return """
            override func setUp() {
                ProcessInfo.processInfo.environment["TEST_MODE"] = "true"
            }
            """
        case .orderDependency:
            return """
            func testFeature() {
                let context = setupTestContext()
                // Test logic
            }
            """
        case .resourceLeak:
            return """
            override func tearDown() {
                testResource = nil
                super.tearDown()
            }
            """
        }
    }

    private func getPriority(for cause: FlakinessCause) -> FixPriority {
        switch cause {
        case .timingDependency, .asyncRaceCondition, .sharedState, .networkDependency:
            return .high
        case .environmentDependency, .orderDependency, .resourceLeak:
            return .medium
        }
    }

    private func extractFilePath(from testName: String) -> String {
        // Parse test name to extract file path
        // Format: -[TestClass testMethod] or TestClass/testMethod
        let components = testName.components(separatedBy: "/")
        if components.count > 0 {
            return "\(components[0]).swift"
        }
        return "Unknown.swift"
    }

    private func loadQuarantinedTests() {
        let quarantined = quarantinedTestsStore.getAll()
        for test in quarantined {
            if let index = flakyTests.firstIndex(where: { $0.testName == test.testName }) {
                flakyTests[index].flakinessScore = 1.0 // Mark as quarantined
            }
        }
    }

    private func logQuarantine(testName: String, reason: String) {
        let log = """
        FlakyTestDetector: Quarantined test "\(testName)"
        Reason: \(reason)
        Date: \(Date())
        """

        NSLog(log)
    }

    private func runSingleTestIteration(_ testName: String) async throws -> TestIterationResult {
        // This would integrate with XCTest to run a single test
        // For now, return a placeholder
        return TestIterationResult(
            passed: true,
            duration: 0.1,
            errorMessage: nil,
            stackTrace: nil
        )
    }
}

// MARK: - Supporting Types

public struct FlakyTest: Identifiable, Codable {
    public let id = UUID()
    let testName: String
    let filePath: String
    let flakinessScore: Double
    let failurePatterns: [FailurePattern]
    let likelyCauses: [FlakinessCause]
    let suggestedFixes: [FixSuggestion]
    let lastOccurrence: Date
    let occurrenceCount: Int
}

public struct FlakinessScore {
    let overall: Double
    let confidence: Double
    let inconsistencyRate: Double
    let isTrulyFlaky: Bool
}

public struct TestAttempt: Codable {
    let testName: String
    let passed: Bool
    let duration: TimeInterval
    let timestamp: Date
    let iteration: Int
    let errorMessage: String?
    let stackTrace: String?
}

public struct TestRunResult {
    let testName: String
    let passed: Bool
    let duration: TimeInterval
    let timestamp: Date
    let errorMessage: String?
    let stackTrace: String?
}

public struct TestIterationResult {
    let passed: Bool
    let duration: TimeInterval
    let errorMessage: String?
    let stackTrace: String?
}

public struct FixSuggestion: Identifiable, Codable {
    public let id = UUID()
    let cause: FlakinessCause
    let description: String
    let codeExample: String
    let priority: FixPriority
}

public struct ImprovementSuggestion: Identifiable {
    public let id = UUID()
    let type: ImprovementType
    let description: String
    let priority: FixPriority
    let codeExample: String
}

public struct FlakinessDataPoint: Identifiable {
    public let id = UUID()
    let date: Date
    let flakinessScore: Double
    let confidence: Double
}

public struct QuarantinedTest: Identifiable, Codable {
    public let id = UUID()
    let testName: String
    let reason: String
    let quarantinedAt: Date
    let quarantinedBy: String
}

public enum FlakinessCause: String, CaseIterable, Codable {
    case timingDependency = "Timing Dependency"
    case asyncRaceCondition = "Async Race Condition"
    case sharedState = "Shared State"
    case networkDependency = "Network Dependency"
    case environmentDependency = "Environment Dependency"
    case orderDependency = "Order Dependency"
    case resourceLeak = "Resource Leak"
}

public enum FailurePattern: String, CaseIterable {
    case timingRelated = "Timing Related"
    case intermittent = "Intermittent"
    case inconsistentErrors = "Inconsistent Errors"
    case multipleFailurePoints = "Multiple Failure Points"
}

public enum FixPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

public enum ImprovementType {
    case addExplicitWait
    case synchronizeAsync
    case isolateState
    case mockNetwork
    case controlEnvironment
    case makeIndependent
    case cleanupResources
}

public enum FlakyTestError: Error {
    case noIdentifiedCause
    case unableToGenerateFix
}

// MARK: - Store Classes

public class TestHistoryStore {
    public static let shared = TestHistoryStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public func recordAttempts(_ attempts: [TestAttempt], for testName: String) {
        // Store attempts in CoreData or file system
    }

    public func getAttempts(for testName: String) -> [TestAttempt] {
        // Retrieve attempts from storage
        return []
    }

    public func getFlakinessHistory(for testName: String) -> [FlakinessDataPoint] {
        // Retrieve historical flakiness data
        return []
    }

    public func recordFixSuggestion(_ fix: FixSuggestion, for testName: String) {
        // Store fix suggestion
    }
}

public class QuarantinedTestsStore {
    public static let shared = QuarantinedTestsStore()

    private var quarantinedTests: [QuarantinedTest] = []

    public func add(_ test: QuarantinedTest) {
        quarantinedTests.append(test)
    }

    public func remove(_ testName: String) {
        quarantinedTests.removeAll { $0.testName == testName }
    }

    public func getAll() -> [QuarantinedTest] {
        return quarantinedTests
    }
}
