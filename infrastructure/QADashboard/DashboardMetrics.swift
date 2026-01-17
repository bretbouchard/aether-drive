//
// DashboardMetrics.swift
// White Room QA Dashboard
//
// Dashboard metrics collection and analysis
//

import Foundation

/// Dashboard metrics provider
public class DashboardMetrics {
    public static let shared = DashboardMetrics()

    private init() {}

    /// Generate complete dashboard data
    public func generateDashboard() -> DashboardData {
        let summary = loadLatestSummary()
        let history = loadHistoricalSummaries()
        let trends = calculateTrends(history: history)
        let alerts = generateAlerts(summary: summary)

        return DashboardData(
            current: summary,
            history: history,
            trends: trends,
            alerts: alerts,
            generatedAt: Date()
        )
    }

    /// Load latest test summary
    private func loadLatestSummary() -> TestSummary {
        let path = "/Users/bretbouchard/apps/schill/white_room/TestReports/aggregate-report.json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = try? TestSummary(json: json) else {
            return TestSummary(
                sdkCoverage: 0.0,
                iosTestsPassed: 0,
                iosTestsFailed: 0,
                accessibilityErrors: 0,
                accessibilityWarnings: 0,
                performanceRegressions: 0,
                visualRegressions: 0,
                crashFreeUsers: 0.0
            )
        }

        return summary
    }

    /// Load historical summaries (last 30 days)
    private func loadHistoricalSummaries() -> [TestSummary] {
        // TODO: Implement historical data loading
        // For now, return empty array
        return []
    }

    /// Calculate trends from historical data
    private func calculateTrends(history: [TestSummary]) -> TrendData {
        guard history.count >= 2 else {
            return TrendData(
                coverageTrend: 0.0,
                testTrend: 0.0,
                qualityTrend: 0.0,
                scoreTrend: 0.0
            )
        }

        let recent = history.prefix(7)
        let older = history.dropFirst(7).prefix(7)

        let recentAvgCoverage = recent.map { $0.sdkCoverage }.reduce(0, +) / Double(recent.count)
        let olderAvgCoverage = older.map { $0.sdkCoverage }.reduce(0, +) / Double(older.count)
        let coverageTrend = recentAvgCoverage - olderAvgCoverage

        let recentAvgScore = recent.map { $0.overallScore }.reduce(0, +) / Double(recent.count)
        let olderAvgScore = older.map { $0.overallScore }.reduce(0, +) / Double(older.count)
        let scoreTrend = recentAvgScore - olderAvgScore

        let recentPassRate = recent.map { $0.iosPassRate }.reduce(0, +) / Double(recent.count)
        let olderPassRate = older.map { $0.iosPassRate }.reduce(0, +) / Double(older.count)
        let testTrend = recentPassRate - olderPassRate

        let recentIssues = recent.map { Double($0.qualityIssues) }.reduce(0, +) / Double(recent.count)
        let olderIssues = older.map { Double($0.qualityIssues) }.reduce(0, +) / Double(older.count)
        let qualityTrend = olderIssues - recentIssues // Negative is good (fewer issues)

        return TrendData(
            coverageTrend: coverageTrend,
            testTrend: testTrend,
            qualityTrend: qualityTrend,
            scoreTrend: scoreTrend
        )
    }

    /// Generate alerts from summary
    private func generateAlerts(summary: TestSummary) -> [Alert] {
        var alerts: [Alert] = []

        // Test failures
        if summary.iosTestsFailed > 0 {
            alerts.append(Alert(
                severity: .error,
                title: "iOS Test Failures",
                message: "\(summary.iosTestsFailed) iOS tests failing",
                category: .tests
            ))
        }

        if summary.tvosTestsFailed > 0 {
            alerts.append(Alert(
                severity: .error,
                title: "tvOS Test Failures",
                message: "\(summary.tvosTestsFailed) tvOS tests failing",
                category: .tests
            ))
        }

        // Coverage
        if summary.sdkCoverage < 80.0 {
            alerts.append(Alert(
                severity: .warning,
                title: "Low Coverage",
                message: "SDK coverage is \(String(format: "%.1f", summary.sdkCoverage))%",
                category: .coverage
            ))
        }

        // Accessibility
        if summary.accessibilityErrors > 0 {
            alerts.append(Alert(
                severity: summary.accessibilityErrors > 5 ? .error : .warning,
                title: "Accessibility Issues",
                message: "\(summary.accessibilityErrors) accessibility errors found",
                category: .accessibility
            ))
        }

        // Performance
        if summary.performanceRegressions > 0 {
            alerts.append(Alert(
                severity: .error,
                title: "Performance Regressions",
                message: "\(summary.performanceRegressions) performance regressions detected",
                category: .performance
            ))
        }

        // Visual
        if summary.visualRegressions > 0 {
            alerts.append(Alert(
                severity: .warning,
                title: "Visual Regressions",
                message: "\(summary.visualRegressions) visual regressions detected",
                category: .visual
            ))
        }

        // Security
        if summary.securityVulnerabilities > 0 {
            alerts.append(Alert(
                severity: .critical,
                title: "Security Vulnerabilities",
                message: "\(summary.securityVulnerabilities) security vulnerabilities found",
                category: .security
            ))
        }

        // Crash rate
        if summary.crashFreeUsers < 99.0 && summary.crashFreeUsers > 0 {
            alerts.append(Alert(
                severity: .warning,
                title: "High Crash Rate",
                message: "Crash-free users: \(String(format: "%.2f", summary.crashFreeUsers))%",
                category: .stability
            ))
        }

        return alerts
    }
}

// MARK: - Dashboard Data

/// Complete dashboard data
public struct DashboardData: Codable {
    /// Current test summary
    public let current: TestSummary

    /// Historical summaries
    public let history: [TestSummary]

    /// Trend analysis
    public let trends: TrendData

    /// Active alerts
    public let alerts: [Alert]

    /// When dashboard was generated
    public let generatedAt: Date

    /// Markdown representation
    public var markdown: String {
        var md = """
        # White Room QA Dashboard

        **Last Updated:** \(ISO8601DateFormatter().string(from: generatedAt))

        ## Overall Score: \(current.grade) \(current.gradeEmoji)

        **Score:** \(String(format: "%.1f", current.overallScore))%

        ## Coverage

        - **SDK:** \(String(format: "%.1f", current.sdkCoverage))%
        - **Trend:** \(trendArrow(trends.coverageTrend)) \(String(format: "%.1f", trends.coverageTrend))%

        ## Tests

        - **iOS:** \(current.iosTestsPassed) passed, \(current.iosTestsFailed) failed
        - **tvOS:** \(current.tvosTestsPassed) passed, \(current.tvosTestsFailed) failed
        - **Pass Rate:** \(String(format: "%.1f", current.iosPassRate * 100))%
        - **Trend:** \(trendArrow(trends.testTrend)) \(String(format: "%.1f", trends.testTrend * 100))%

        ## Quality

        - **Accessibility:** \(current.accessibilityErrors) errors, \(current.accessibilityWarnings) warnings
        - **Performance:** \(current.performanceRegressions) regressions
        - **Visual:** \(current.visualRegressions) regressions
        - **Security:** \(current.securityVulnerabilities) vulnerabilities
        - **Total Issues:** \(current.qualityIssues)

        ## Telemetry

        - **Crash-Free Users:** \(String(format: "%.2f", current.crashFreeUsers))%
        - **Active Sessions:** \(current.activeSessions)

        ## Quality Gates

        - **Pre-Merge:** \(current.passesPreMergeGates ? "✅ PASS" : "❌ FAIL")
        - **Pre-Release:** \(current.passesPreReleaseGates ? "✅ PASS" : "❌ FAIL")

        """

        if !alerts.isEmpty {
            md += "\n## Alerts\n\n"
            for alert in alerts.sorted(by: { $0.severity > $1.severity }) {
                md += "\(alert.severity.emoji) **\(alert.title)**\n"
                md += "\(alert.message)\n\n"
            }
        }

        return md
    }

    /// Helper for trend arrows
    private func trendArrow(_ value: Double) -> String {
        if value > 0.5 { return "📈" }
        if value < -0.5 { return "📉" }
        return "➡️"
    }
}

// MARK: - Trend Data

/// Trend analysis data
public struct TrendData: Codable {
    /// Coverage trend percentage points (positive = improving)
    public let coverageTrend: Double

    /// Test pass rate trend (positive = improving)
    public let testTrend: Double

    /// Quality issues trend (positive = improving, fewer issues)
    public let qualityTrend: Double

    /// Overall score trend (positive = improving)
    public let scoreTrend: Double
}

// MARK: - Alert

/// Dashboard alert
public struct Alert: Codable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Severity level
    public let severity: Severity

    /// Alert title
    public let title: String

    /// Alert message
    public let message: String

    /// Alert category
    public let category: Category

    /// When alert was generated
    public let timestamp: Date

    public init(severity: Severity, title: String, message: String, category: Category) {
        self.id = UUID()
        self.severity = severity
        self.title = title
        self.message = message
        self.category = category
        self.timestamp = Date()
    }

    /// Severity levels
    public enum Severity: Int, Codable {
        case info
        case warning
        case error
        case critical

        /// Emoji representation
        public var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }

        /// Color (for UI)
        public var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "yellow"
            case .error: return "red"
            case .critical: return "purple"
            }
        }
    }

    /// Alert categories
    public enum Category: String, Codable {
        case tests
        case coverage
        case accessibility
        case performance
        case visual
        case security
        case stability
    }
}

// MARK: - Alert Filtering

extension Array where Element == Alert {
    /// Filter alerts by severity
    public func filtered(by severity: Alert.Severity) -> [Alert] {
        return filter { $0.severity == severity }
    }

    /// Filter alerts by category
    public func filtered(by category: Alert.Category) -> [Alert] {
        return filter { $0.category == category }
    }

    /// Get only critical alerts
    public var critical: [Alert] {
        return filter { $0.severity == .critical }
    }

    /// Get only error alerts
    public var errors: [Alert] {
        return filter { $0.severity == .error }
    }

    /// Get only warning alerts
    public var warnings: [Alert] {
        return filter { $0.severity == .warning }
    }
}
