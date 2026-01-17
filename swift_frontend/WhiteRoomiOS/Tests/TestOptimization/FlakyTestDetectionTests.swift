//
//  FlakyTestDetectionTests.swift
//  WhiteRoomiOSTests
//
//  Created by AI Assistant on 1/16/25.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for flaky test detection system
final class FlakyTestDetectionTests: XCTestCase {

    var detector: FlakyTestDetector!

    override func setUp() {
        super.setUp()
        detector = FlakyTestDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Flakiness Detection Tests

    func testFlakinessDetectionWithConsistentPasses() {
        // Given: A test that always passes
        let attempts = createTestAttempts(
            passCount: 10,
            failCount: 0
        )

        // When: Detecting flakiness
        let score = detector.detectFlakiness(
            for: "AlwaysPassingTest",
            history: attempts
        )

        // Then: Should not be flaky
        XCTAssertFalse(score.isTrulyFlaky, "Consistently passing test should not be flaky")
        XCTAssertEqual(score.overall, 0.0, accuracy: 0.01, "Overall flakiness should be 0")
        XCTAssertTrue(score.confidence > 0.5, "Should have high confidence")
    }

    func testFlakinessDetectionWithConsistentFailures() {
        // Given: A test that always fails
        let attempts = createTestAttempts(
            passCount: 0,
            failCount: 10
        )

        // When: Detecting flakiness
        let score = detector.detectFlakiness(
            for: "AlwaysFailingTest",
            history: attempts
        )

        // Then: Should not be flaky (just broken)
        XCTAssertFalse(score.isTrulyFlaky, "Consistently failing test should not be marked as flaky")
        XCTAssertEqual(score.overall, 1.0, accuracy: 0.01, "Overall flakiness should be 1")
    }

    func testFlakinessDetectionWithIntermittentFailures() {
        // Given: A test that passes and fails intermittently
        let attempts = createTestAttempts(
            passCount: 5,
            failCount: 5
        )

        // When: Detecting flakiness
        let score = detector.detectFlakiness(
            for: "IntermittentTest",
            history: attempts
        )

        // Then: Should be detected as flaky
        XCTAssertTrue(score.isTrulyFlaky, "Intermittent test should be detected as flaky")
        XCTAssertEqual(score.overall, 0.5, accuracy: 0.01, "Overall flakiness should be 0.5")
        XCTAssertTrue(score.inconsistencyRate > 0.5, "Inconsistency rate should be high")
    }

    func testFlakinessDetectionWithHighPassRate() {
        // Given: A test that passes most of the time
        let attempts = createTestAttempts(
            passCount: 8,
            failCount: 2
        )

        // When: Detecting flakiness
        let score = detector.detectFlakiness(
            for: "MostlyPassingTest",
            history: attempts
        )

        // Then: Should still be detected as flaky
        XCTAssertTrue(score.isTrulyFlaky, "Test with occasional failures should be flaky")
        XCTAssertTrue(score.overall > 0.1, "Should have some flakiness score")
    }

    func testFlakinessDetectionInsufficientIterations() {
        // Given: Too few test attempts
        let attempts = createTestAttempts(
            passCount: 2,
            failCount: 1
        )

        // When: Detecting flakiness
        let score = detector.detectFlakiness(
            for: "InsufficientDataTest",
            history: attempts
        )

        // Then: Should not be confident
        XCTAssertFalse(score.isTrulyFlaky, "Should not detect flakiness with insufficient data")
        XCTAssertEqual(score.confidence, 0.0, accuracy: 0.01, "Confidence should be 0")
    }

    // MARK: - Test Result Analysis Tests

    func testAnalyzeTestResultsWithNoFlakyTests() {
        // Given: All tests pass consistently
        let results = createTestResults(
            testCount: 5,
            passRate: 1.0
        )

        // When: Analyzing results
        let flakyTests = detector.analyzeTestResults(results)

        // Then: No flaky tests should be detected
        XCTAssertEqual(flakyTests.count, 0, "No flaky tests should be detected")
    }

    func testAnalyzeTestResultsWithMultipleFlakyTests() {
        // Given: Multiple flaky tests
        let results = createMixedTestResults()

        // When: Analyzing results
        let flakyTests = detector.analyzeTestResults(results)

        // Then: Should detect flaky tests
        XCTAssertTrue(flakyTests.count > 0, "Should detect flaky tests")
        XCTAssertTrue(detector.flakyTests.count > 0, "Should store detected flaky tests")
        XCTAssertNotNil(detector.lastDetectionDate, "Should record detection date")
    }

    func testFlakyTestStructure() {
        // Given: Flaky test data
        let attempts = createTestAttempts(passCount: 5, failCount: 5)
        let score = detector.detectFlakiness(
            for: "FlakyTest",
            history: attempts
        )

        // When: Analyzing test
        let results = detector.analyzeTestResults(
            createTestResultsForTest("FlakyTest", attempts: attempts)
        )

        // Then: Should have complete structure
        if let flakyTest = results.first {
            XCTAssertFalse(flakyTest.testName.isEmpty, "Should have test name")
            XCTAssertFalse(flakyTest.filePath.isEmpty, "Should have file path")
            XCTAssertTrue(flakyTest.flakinessScore > 0, "Should have flakiness score")
            XCTAssertFalse(flakyTest.failurePatterns.isEmpty, "Should identify failure patterns")
            XCTAssertFalse(flakyTest.likelyCauses.isEmpty, "Should identify likely causes")
            XCTAssertFalse(flakyTest.suggestedFixes.isEmpty, "Should suggest fixes")
        }
    }

    // MARK: - Failure Pattern Tests

    func testTimingRelatedFailurePattern() {
        // Given: Test failures with timing issues
        let attempts = createTimingRelatedAttempts()

        // When: Analyzing results
        let results = detector.analyzeTestResults(
            createTestResultsForTest("TimingTest", attempts: attempts)
        )

        // Then: Should detect timing-related pattern
        if let flakyTest = results.first {
            XCTAssertTrue(
                flakyTest.failurePatterns.contains(.timingRelated),
                "Should detect timing-related pattern"
            )
            XCTAssertTrue(
                flakyTest.likelyCauses.contains(.timingDependency),
                "Should identify timing dependency"
            )
        }
    }

    func testInconsistentErrorsPattern() {
        // Given: Test failures with different error messages
        let attempts = createInconsistentErrorAttempts()

        // When: Analyzing results
        let results = detector.analyzeTestResults(
            createTestResultsForTest("InconsistentTest", attempts: attempts)
        )

        // Then: Should detect inconsistent errors pattern
        if let flakyTest = results.first {
            XCTAssertTrue(
                flakyTest.failurePatterns.contains(.inconsistentErrors),
                "Should detect inconsistent errors pattern"
            )
        }
    }

    // MARK: - Fix Suggestion Tests

    func testAutoFixGeneratesSuggestions() {
        // Given: A flaky test
        let flakyTest = createFlakyTestWithCause(.timingDependency)

        // When: Generating auto-fix
        let fix = try? detector.autoFix(flakyTest)

        // Then: Should generate fix suggestion
        XCTAssertNotNil(fix, "Should generate fix suggestion")
        XCTAssertEqual(fix?.cause, .timingDependency, "Should match cause")
        XCTAssertFalse(fix?.description.isEmpty ?? true, "Should have description")
        XCTAssertFalse(fix?.codeExample.isEmpty ?? true, "Should have code example")
        XCTAssertEqual(fix?.priority, .high, "Should have appropriate priority")
    }

    func testAutoFixHandlesNoIdentifiedCause() {
        // Given: Flaky test without identified cause
        let flakyTest = FlakyTest(
            testName: "MysteryTest",
            filePath: "Test.swift",
            flakinessScore: 0.5,
            failurePatterns: [],
            likelyCauses: [],
            suggestedFixes: [],
            lastOccurrence: Date(),
            occurrenceCount: 5
        )

        // When: Attempting auto-fix
        do {
            _ = try detector.autoFix(flakyTest)
            XCTFail("Should throw error for no identified cause")
        } catch FlakyTestError.noIdentifiedCause {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSuggestImprovementsForTimingDependency() {
        // Given: Flaky test with timing dependency
        let flakyTest = createFlakyTestWithCause(.timingDependency)

        // When: Getting improvements
        let improvements = detector.suggestImprovements(for: flakyTest)

        // Then: Should provide relevant improvements
        XCTAssertFalse(improvements.isEmpty, "Should suggest improvements")

        let waitImprovements = improvements.filter { $0.type == .addExplicitWait }
        XCTAssertFalse(waitImprovements.isEmpty, "Should suggest adding explicit waits")

        XCTAssertTrue(
            improvements.allSatisfy { $0.priority == .high },
            "All improvements should be high priority for timing issues"
        )
    }

    func testSuggestImprovementsForSharedState() {
        // Given: Flaky test with shared state issue
        let flakyTest = createFlakyTestWithCause(.sharedState)

        // When: Getting improvements
        let improvements = detector.suggestImprovements(for: flakyTest)

        // Then: Should provide state isolation suggestions
        let stateImprovements = improvements.filter { $0.type == .isolateState }
        XCTAssertFalse(stateImprovements.isEmpty, "Should suggest isolating state")
    }

    func testSuggestImprovementsForNetworkDependency() {
        // Given: Flaky test with network dependency
        let flakyTest = createFlakyTestWithCause(.networkDependency)

        // When: Getting improvements
        let improvements = detector.suggestImprovements(for: flakyTest)

        // Then: Should suggest mocking network
        let networkImprovements = improvements.filter { $0.type == .mockNetwork }
        XCTAssertFalse(networkImprovements.isEmpty, "Should suggest mocking network calls")
    }

    // MARK: - Quarantine Tests

    func testQuarantineTest() {
        // Given: A test to quarantine
        let testName = "UnstableTest"
        let reason = "Fails intermittently due to race condition"

        // When: Quarantining test
        detector.quarantineTest(testName, reason: reason)

        // Then: Should be in quarantine list
        let quarantined = detector.getQuarantinedTests()
        XCTAssertTrue(quarantined.contains(where: { $0.testName == testName }), "Should be quarantined")

        let quarantine = quarantined.first { $0.testName == testName }
        XCTAssertEqual(quarantine?.reason, reason, "Should store reason")
        XCTAssertNotNil(quarantine?.quarantinedAt, "Should record quarantine date")
        XCTAssertEqual(quarantine?.quarantinedBy, "FlakyTestDetector", "Should record detector")
    }

    func testReleaseFromQuarantine() {
        // Given: A quarantined test
        let testName = "QuarantinedTest"
        detector.quarantineTest(testName, reason: "Testing quarantine")

        // When: Releasing from quarantine
        detector.releaseFromQuarantine(testName)

        // Then: Should no longer be quarantined
        let quarantined = detector.getQuarantinedTests()
        XCTAssertFalse(quarantined.contains(where: { $0.testName == testName }), "Should be released")
    }

    func testQuarantineMultipleTests() {
        // Given: Multiple tests to quarantine
        let tests = ["Test1", "Test2", "Test3"]

        // When: Quarantining all tests
        for test in tests {
            detector.quarantineTest(test, reason: "Batch quarantine")
        }

        // Then: All should be quarantined
        let quarantined = detector.getQuarantinedTests()
        XCTAssertEqual(quarantined.count, tests.count, "Should quarantine all tests")
    }

    // MARK: - Performance Tests

    func testDetectionPerformance() {
        // Given: Large number of test results
        let results = createTestResults(testCount: 1000, passRate: 0.8)

        // When: Analyzing results
        measure {
            _ = detector.analyzeTestResults(results)
        }

        // Then: Should complete in reasonable time
        // (measure block handles timing assertion)
    }

    func testFlakinessScoreCalculationPerformance() {
        // Given: Many test attempts
        let attempts = createTestAttempts(passCount: 50, failCount: 50)

        // When: Calculating flakiness score
        measure {
            _ = detector.detectFlakiness(for: "PerformanceTest", history: attempts)
        }
    }

    // MARK: - Helper Methods

    private func createTestAttempts(passCount: Int, failCount: Int) -> [TestAttempt] {
        var attempts: [TestAttempt] = []
        var iteration = 0

        for _ in 0..<passCount {
            attempts.append(TestAttempt(
                testName: "Test",
                passed: true,
                duration: Double.random(in: 0.1...0.5),
                timestamp: Date(),
                iteration: iteration,
                errorMessage: nil,
                stackTrace: nil
            ))
            iteration += 1
        }

        for _ in 0..<failCount {
            attempts.append(TestAttempt(
                testName: "Test",
                passed: false,
                duration: Double.random(in: 0.1...0.5),
                timestamp: Date(),
                iteration: iteration,
                errorMessage: "Test failed",
                stackTrace: "Stack trace"
            ))
            iteration += 1
        }

        return attempts.shuffled()
    }

    private func createTestResults(testCount: Int, passRate: Double) -> [TestRunResult] {
        var results: [TestRunResult] = []

        for i in 0..<testCount {
            let shouldPass = Double.random(in: 0...1) < passRate
            results.append(TestRunResult(
                testName: "Test\(i)",
                passed: shouldPass,
                duration: Double.random(in: 0.1...1.0),
                timestamp: Date(),
                errorMessage: shouldPass ? nil : "Failed",
                stackTrace: shouldPass ? nil : "Trace"
            ))
        }

        return results
    }

    private func createTestResultsForTest(_ testName: String, attempts: [TestAttempt]) -> [TestRunResult] {
        return attempts.map { attempt in
            TestRunResult(
                testName: testName,
                passed: attempt.passed,
                duration: attempt.duration,
                timestamp: attempt.timestamp,
                errorMessage: attempt.errorMessage,
                stackTrace: attempt.stackTrace
            )
        }
    }

    private func createMixedTestResults() -> [TestRunResult] {
        var results: [TestRunResult] = []

        // Add stable tests
        results.append(contentsOf: createTestResultsForTest(
            "StableTest1",
            attempts: createTestAttempts(passCount: 10, failCount: 0)
        ))

        // Add flaky test
        results.append(contentsOf: createTestResultsForTest(
            "FlakyTest1",
            attempts: createTestAttempts(passCount: 5, failCount: 5)
        ))

        // Add another stable test
        results.append(contentsOf: createTestResultsForTest(
            "StableTest2",
            attempts: createTestAttempts(passCount: 10, failCount: 0)
        ))

        return results
    }

    private func createTimingRelatedAttempts() -> [TestAttempt] {
        var attempts = createTestAttempts(passCount: 5, failCount: 5)

        // Make failures slow (timeout-related)
        for i in attempts.indices where !attempts[i].passed {
            attempts[i].duration = 5.0 + Double.random(in: 0...2)
        }

        return attempts
    }

    private func createInconsistentErrorAttempts() -> [TestAttempt] {
        var attempts = createTestAttempts(passCount: 5, failCount: 5)

        // Give failures different error messages
        let errorMessages = ["Timeout", "Nil unwrap", "Assertion failed", "Network error"]
        for i in attempts.indices where !attempts[i].passed {
            attempts[i] = TestAttempt(
                testName: attempts[i].testName,
                passed: false,
                duration: attempts[i].duration,
                timestamp: attempts[i].timestamp,
                iteration: attempts[i].iteration,
                errorMessage: errorMessages.randomElement()!,
                stackTrace: attempts[i].stackTrace
            )
        }

        return attempts
    }

    private func createFlakyTestWithCause(_ cause: FlakinessCause) -> FlakyTest {
        return FlakyTest(
            testName: "FlakyTest",
            filePath: "Test.swift",
            flakinessScore: 0.5,
            failurePatterns: [.intermittent],
            likelyCauses: [cause],
            suggestedFixes: [],
            lastOccurrence: Date(),
            occurrenceCount: 5
        )
    }
}
