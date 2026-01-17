//
// TestSummary.swift
// White Room QA Dashboard
//
// Comprehensive test result summary with quality scoring
//

import Foundation

/// Complete test summary with all metrics
public struct TestSummary: Codable, Equatable {
    /// Timestamp when the summary was generated
    public let date: Date

    /// SDK code coverage percentage (0-100)
    public let sdkCoverage: Double

    /// iOS tests passed
    public let iosTestsPassed: Int

    /// iOS tests failed
    public let iosTestsFailed: Int

    /// tvOS tests passed
    public let tvosTestsPassed: Int

    /// tvOS tests failed
    public let tvosTestsFailed: Int

    /// Accessibility errors found
    public let accessibilityErrors: Int

    /// Accessibility warnings found
    public let accessibilityWarnings: Int

    /// Performance regressions detected
    public let performanceRegressions: Int

    /// Visual regressions detected
    public let visualRegressions: Int

    /// Security vulnerabilities found
    public let securityVulnerabilities: Int

    /// Crash-free users percentage (from telemetry)
    public let crashFreeUsers: Double

    /// Active sessions in last 24 hours
    public let activeSessions: Int

    public init(
        date: Date = Date(),
        sdkCoverage: Double,
        iosTestsPassed: Int,
        iosTestsFailed: Int,
        tvosTestsPassed: Int = 0,
        tvosTestsFailed: Int = 0,
        accessibilityErrors: Int,
        accessibilityWarnings: Int,
        performanceRegressions: Int,
        visualRegressions: Int,
        securityVulnerabilities: Int = 0,
        crashFreeUsers: Double,
        activeSessions: Int = 0
    ) {
        self.date = date
        self.sdkCoverage = sdkCoverage
        self.iosTestsPassed = iosTestsPassed
        self.iosTestsFailed = iosTestsFailed
        self.tvosTestsPassed = tvosTestsPassed
        self.tvosTestsFailed = tvosTestsFailed
        accessibilityErrors = accessibilityErrors
        self.accessibilityWarnings = accessibilityWarnings
        self.performanceRegressions = performanceRegressions
        self.visualRegressions = visualRegressions
        self.securityVulnerabilities = securityVulnerabilities
        self.crashFreeUsers = crashFreeUsers
        self.activeSessions = activeSessions
    }

    /// Calculate overall quality score (0-100)
    public var overallScore: Double {
        var score = 0.0

        // SDK coverage (30% weight)
        score += (sdkCoverage / 100.0) * 30

        // iOS tests pass rate (25% weight)
        let totalTests = iosTestsPassed + iosTestsFailed
        if totalTests > 0 {
            let passRate = Double(iosTestsPassed) / Double(totalTests)
            score += passRate * 25
        }

        // tvOS tests (5% weight)
        let totalTvOSTests = tvosTestsPassed + tvosTestsFailed
        if totalTvOSTests > 0 {
            let passRate = Double(tvosTestsPassed) / Double(totalTvOSTests)
            score += passRate * 5
        }

        // Accessibility (15% weight)
        let axScore = accessibilityErrors == 0 ? 1.0 : max(0.0, 1.0 - (Double(accessibilityErrors) * 0.1))
        score += axScore * 15

        // Performance (10% weight)
        let perfScore = performanceRegressions == 0 ? 1.0 : max(0.0, 1.0 - (Double(performanceRegressions) * 0.2))
        score += perfScore * 10

        // Visual (10% weight)
        let visualScore = visualRegressions == 0 ? 1.0 : max(0.0, 1.0 - (Double(visualRegressions) * 0.2))
        score += visualScore * 10

        // Security (5% weight)
        let securityScore = securityVulnerabilities == 0 ? 1.0 : max(0.0, 1.0 - (Double(securityVulnerabilities) * 0.2))
        score += securityScore * 5

        return min(100.0, max(0.0, score))
    }

    /// Letter grade for overall score
    public var grade: String {
        switch overallScore {
        case 95...100: return "A+"
        case 90..<95: return "A"
        case 85..<90: return "B+"
        case 80..<85: return "B"
        case 75..<80: return "C"
        default: return "F"
        }
    }

    /// Emoji representation of grade
    public var gradeEmoji: String {
        switch grade {
        case "A+": return "🌟"
        case "A": return "✨"
        case "B+": return "👍"
        case "B": return "✅"
        case "C": return "⚠️"
        default: return "❌"
        }
    }

    /// iOS test pass rate
    public var iosPassRate: Double {
        let total = iosTestsPassed + iosTestsFailed
        guard total > 0 else { return 0.0 }
        return Double(iosTestsPassed) / Double(total)
    }

    /// tvOS test pass rate
    public var tvosPassRate: Double {
        let total = tvosTestsPassed + tvosTestsFailed
        guard total > 0 else { return 0.0 }
        return Double(tvosTestsPassed) / Double(total)
    }

    /// Total test count across all platforms
    public var totalTests: Int {
        return iosTestsPassed + iosTestsFailed + tvosTestsPassed + tvosTestsFailed
    }

    /// Total failed tests across all platforms
    public var totalFailures: Int {
        return iosTestsFailed + tvosTestsFailed
    }

    /// Quality issues count (errors + regressions + vulnerabilities)
    public var qualityIssues: Int {
        return accessibilityErrors + performanceRegressions + visualRegressions + securityVulnerabilities
    }

    /// Check if summary meets pre-merge quality gates
    public var passesPreMergeGates: Bool {
        return iosTestsFailed == 0 &&
               sdkCoverage >= 80.0 &&
               accessibilityErrors == 0 &&
               performanceRegressions == 0 &&
               visualRegressions == 0
    }

    /// Check if summary meets pre-release quality gates
    public var passesPreReleaseGates: Bool {
        return passesPreMergeGates &&
               sdkCoverage >= 85.0 &&
               crashFreeUsers >= 99.0 &&
               securityVulnerabilities == 0
    }
}

// MARK: - Convenience Initializers

extension TestSummary {
    /// Create from aggregate report JSON
    public init?(json: [String: Any]) throws {
        guard let timestampString = json["timestamp"] as? String,
              let timestamp = ISO8601DateFormatter().date(from: timestampString) else {
            return nil
        }

        self.init(
            date: timestamp,
            sdkCoverage: json["sdkCoverage"] as? Double ?? 0.0,
            iosTestsPassed: json["iosTestsPassed"] as? Int ?? 0,
            iosTestsFailed: json["iosTestsFailed"] as? Int ?? 0,
            tvosTestsPassed: json["tvosTestsPassed"] as? Int ?? 0,
            tvosTestsFailed: json["tvosTestsFailed"] as? Int ?? 0,
            accessibilityErrors: json["accessibilityErrors"] as? Int ?? 0,
            accessibilityWarnings: json["accessibilityWarnings"] as? Int ?? 0,
            performanceRegressions: json["performanceRegressions"] as? Int ?? 0,
            visualRegressions: json["visualRegressions"] as? Int ?? 0,
            securityVulnerabilities: json["securityVulnerabilities"] as? Int ?? 0,
            crashFreeUsers: json["crashFreeUsers"] as? Double ?? 0.0,
            activeSessions: json["activeSessions"] as? Int ?? 0
        )
    }

    /// Load from file
    public static func load(from url: URL) throws -> TestSummary {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TestSummary.self, from: data)
    }

    /// Save to file
    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}

// MARK: - Debugging

extension TestSummary {
    /// Detailed description for debugging
    public var detailedDescription: String {
        """
        White Room Test Summary
        Date: \(ISO8601DateFormatter().string(from: date))

        Overall Score: \(grade) (\(String(format: "%.1f", overallScore))%) \(gradeEmoji)

        Coverage:
        - SDK: \(String(format: "%.1f", sdkCoverage))%

        Tests:
        - iOS: \(iosTestsPassed) passed, \(iosTestsFailed) failed (\(String(format: "%.1f", iosPassRate * 100))%)
        - tvOS: \(tvosTestsPassed) passed, \(tvosTestsFailed) failed (\(String(format: "%.1f", tvosPassRate * 100))%)
        - Total: \(totalTests) tests, \(totalFailures) failures

        Quality:
        - Accessibility: \(accessibilityErrors) errors, \(accessibilityWarnings) warnings
        - Performance: \(performanceRegressions) regressions
        - Visual: \(visualRegressions) regressions
        - Security: \(securityVulnerabilities) vulnerabilities
        - Total Issues: \(qualityIssues)

        Telemetry:
        - Crash-Free Users: \(String(format: "%.2f", crashFreeUsers))%
        - Active Sessions: \(activeSessions)

        Gates:
        - Pre-Merge: \(passesPreMergeGates ? "✅ PASS" : "❌ FAIL")
        - Pre-Release: \(passesPreReleaseGates ? "✅ PASS" : "❌ FAIL")
        """
    }
}
