//
// QualityGate.swift
// White Room QA Dashboard
//
// Quality gate enforcement for pre-merge and pre-release checks
//

import Foundation

/// Quality gate enforcement system
public class QualityGate {
    public static let shared = QualityGate()

    private init() {}

    /// Quality gate check result
    public enum GateResult {
        case pass
        case fail(reasons: [String])

        /// Check if gate passed
        public var passed: Bool {
            if case .pass = self { return true }
            return false
        }

        /// Failure reasons (empty if passed)
        public var failureReasons: [String] {
            if case .fail(let reasons) = self { return reasons }
            return []
        }
    }

    /// Quality gate enforcement levels
    public enum EnforcementLevel: String, Codable {
        case preMerge
        case preRelease

        /// Display name
        public var displayName: String {
            switch self {
            case .preMerge: return "Pre-Merge"
            case .preRelease: return "Pre-Release"
            }
        }
    }

    /// Validate summary against pre-merge quality gates
    public func validatePreMerge(summary: TestSummary) -> GateResult {
        var failures: [String] = []

        // All tests must pass
        if summary.iosTestsFailed > 0 {
            failures.append("iOS tests failing: \(summary.iosTestsFailed)")
        }

        if summary.tvosTestsFailed > 0 {
            failures.append("tvOS tests failing: \(summary.tvosTestsFailed)")
        }

        // Coverage threshold
        if summary.sdkCoverage < 80.0 {
            failures.append("SDK coverage below 80%: \(String(format: "%.1f", summary.sdkCoverage))%")
        }

        // No accessibility errors
        if summary.accessibilityErrors > 0 {
            failures.append("Accessibility errors: \(summary.accessibilityErrors)")
        }

        // No performance regressions
        if summary.performanceRegressions > 0 {
            failures.append("Performance regressions: \(summary.performanceRegressions)")
        }

        // No visual regressions
        if summary.visualRegressions > 0 {
            failures.append("Visual regressions: \(summary.visualRegressions)")
        }

        return failures.isEmpty ? .pass : .fail(reasons: failures)
    }

    /// Validate summary against pre-release quality gates
    public func validatePreRelease(summary: TestSummary) -> GateResult {
        var failures: [String] = []

        // All pre-merge requirements
        if case .fail(let reasons) = validatePreMerge(summary: summary) {
            failures.append(contentsOf: reasons)
        }

        // Stricter coverage requirement
        if summary.sdkCoverage < 85.0 {
            failures.append("SDK coverage below 85% for release: \(String(format: "%.1f", summary.sdkCoverage))%")
        }

        // Crash rate threshold
        if summary.crashFreeUsers < 99.0 {
            failures.append("Crash-free users below 99%: \(String(format: "%.2f", summary.crashFreeUsers))%")
        }

        // No security vulnerabilities
        if summary.securityVulnerabilities > 0 {
            failures.append("Security vulnerabilities: \(summary.securityVulnerabilities)")
        }

        return failures.isEmpty ? .pass : .fail(reasons: failures)
    }

    /// Enforce quality gates for a given level
    @discardableResult
    public func enforce(summary: TestSummary, level: EnforcementLevel) -> Bool {
        let result: GateResult

        switch level {
        case .preMerge:
            result = validatePreMerge(summary: summary)
        case .preRelease:
            result = validatePreRelease(summary: summary)
        }

        switch result {
        case .pass:
            print("✅ Quality gates PASSED (\(level.rawValue))")
            print("   Score: \(summary.grade) (\(String(format: "%.1f", summary.overallScore))%)")
            return true

        case .fail(let reasons):
            print("❌ Quality gates FAILED (\(level.rawValue))")
            print("   Score: \(summary.grade) (\(String(format: "%.1f", summary.overallScore))%)")
            print("")
            print("   Reasons:")
            for reason in reasons {
                print("   - \(reason)")
            }
            return false
        }
    }

    /// Validate summary against custom criteria
    public func validateCustom(summary: TestSummary, criteria: QualityCriteria) -> GateResult {
        var failures: [String] = []

        // Test failures
        if let maxFailures = criteria.maxTestFailures {
            let totalFailures = summary.iosTestsFailed + summary.tvosTestsFailed
            if totalFailures > maxFailures {
                failures.append("Test failures (\(totalFailures)) exceed maximum (\(maxFailures))")
            }
        }

        // Coverage threshold
        if let minCoverage = criteria.minCoverage {
            if summary.sdkCoverage < minCoverage {
                failures.append("SDK coverage (\(String(format: "%.1f", summary.sdkCoverage))%) below minimum (\(minCoverage)%)")
            }
        }

        // Quality issues
        if let maxIssues = criteria.maxQualityIssues {
            if summary.qualityIssues > maxIssues {
                failures.append("Quality issues (\(summary.qualityIssues)) exceed maximum (\(maxIssues))")
            }
        }

        // Overall score
        if let minScore = criteria.minScore {
            if summary.overallScore < minScore {
                failures.append("Overall score (\(String(format: "%.1f", summary.overallScore))) below minimum (\(minScore))")
            }
        }

        // Crash rate
        if let minCrashFree = criteria.minCrashFreeUsers {
            if summary.crashFreeUsers < minCrashFree {
                failures.append("Crash-free users (\(String(format: "%.2f", summary.crashFreeUsers))%) below minimum (\(minCrashFree)%)")
            }
        }

        return failures.isEmpty ? .pass : .fail(reasons: failures)
    }

    /// Generate gate report
    public func generateReport(summary: TestSummary, level: EnforcementLevel) -> QualityGateReport {
        let result: GateResult
        switch level {
        case .preMerge:
            result = validatePreMerge(summary: summary)
        case .preRelease:
            result = validatePreRelease(summary: summary)
        }

        return QualityGateReport(
            level: level,
            passed: result.passed,
            score: summary.overallScore,
            grade: summary.grade,
            timestamp: Date(),
            failureReasons: result.failureReasons
        )
    }
}

// MARK: - Quality Criteria

/// Custom quality criteria for validation
public struct QualityCriteria {
    public var maxTestFailures: Int?
    public var minCoverage: Double?
    public var maxQualityIssues: Int?
    public var minScore: Double?
    public var minCrashFreeUsers: Double?

    public init(
        maxTestFailures: Int? = nil,
        minCoverage: Double? = nil,
        maxQualityIssues: Int? = nil,
        minScore: Double? = nil,
        minCrashFreeUsers: Double? = nil
    ) {
        self.maxTestFailures = maxTestFailures
        self.minCoverage = minCoverage
        self.maxQualityIssues = maxQualityIssues
        self.minScore = minScore
        self.minCrashFreeUsers = minCrashFreeUsers
    }

    /// Pre-merge criteria
    public static var preMerge: QualityCriteria {
        return QualityCriteria(
            maxTestFailures: 0,
            minCoverage: 80.0,
            maxQualityIssues: 0,
            minScore: 75.0
        )
    }

    /// Pre-release criteria
    public static var preRelease: QualityCriteria {
        return QualityCriteria(
            maxTestFailures: 0,
            minCoverage: 85.0,
            maxQualityIssues: 0,
            minScore: 85.0,
            minCrashFreeUsers: 99.0
        )
    }
}

// MARK: - Quality Gate Report

/// Report generated from quality gate check
public struct QualityGateReport: Codable {
    /// Enforcement level
    public let level: QualityGate.EnforcementLevel

    /// Whether gates passed
    public let passed: Bool

    /// Overall quality score
    public let score: Double

    /// Letter grade
    public let grade: String

    /// Timestamp of check
    public let timestamp: Date

    /// Failure reasons (empty if passed)
    public let failureReasons: [String]

    /// Markdown representation
    public var markdown: String {
        var md = """
        # Quality Gate Report

        **Level:** \(level.displayName)
        **Status:** \(passed ? "✅ PASSED" : "❌ FAILED")
        **Score:** \(grade) (\(String(format: "%.1f", score))%)
        **Timestamp:** \(ISO8601DateFormatter().string(from: timestamp))

        """

        if !failureReasons.isEmpty {
            md += "## Failure Reasons\n\n"
            for reason in failureReasons {
                md += "- \(reason)\n"
            }
            md += "\n"
        }

        return md
    }
}
