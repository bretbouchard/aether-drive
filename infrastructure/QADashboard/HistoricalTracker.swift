//
// HistoricalTracker.swift
// White Room QA Dashboard
//
// Tracks test results over time with trend analysis
//

import Foundation

/// Historical test result tracker with trend analysis
public class HistoricalTracker {
    public static let shared = HistoricalTracker()

    private let historySize = 30 // 30 days
    private let historyURL: URL

    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        historyURL = documentsDirectory.appendingPathComponent("test-history.json")
    }

    // MARK: - Recording

    /// Record a test summary in history
    public func record(_ summary: TestSummary) {
        var history = loadHistory()
        history.append(summary)

        // Keep only last 30 days
        if history.count > historySize {
            history.removeFirst(history.count - historySize)
        }

        saveHistory(history)

        // Also save to file system for persistence
        archiveSummary(summary)
    }

    /// Get all historical data
    public func getHistory() -> [TestSummary] {
        return loadHistory()
    }

    /// Get trend data comparing recent vs older results
    public func getTrend() -> TrendData {
        let history = loadHistory()
        guard history.count >= 2 else {
            return TrendData(
                coverageTrend: 0,
                testTrend: 0,
                qualityTrend: 0,
                accessibilityTrend: 0,
                performanceTrend: 0,
                summary: "Insufficient data for trend analysis"
            )
        }

        let recent = history.suffix(7)
        let older = history.prefix(history.count - 7)

        // Calculate trends
        let recentAvgScore = recent.map { $0.overallScore }.reduce(0, +) / Double(recent.count)
        let olderAvgScore = older.map { $0.overallScore }.reduce(0, +) / Double(older.count)

        let recentAvgCoverage = recent.map { $0.sdkCoverage }.reduce(0, +) / Double(recent.count)
        let olderAvgCoverage = older.map { $0.sdkCoverage }.reduce(0, +) / Double(older.count)

        let recentPassRate = recent.map { summary in
            let total = summary.iosTestsPassed + summary.iosTestsFailed
            return total > 0 ? Double(summary.iosTestsPassed) / Double(total) : 0
        }.reduce(0, +) / Double(recent.count)

        let olderPassRate = older.map { summary in
            let total = summary.iosTestsPassed + summary.iosTestsFailed
            return total > 0 ? Double(summary.iosTestsPassed) / Double(total) : 0
        }.reduce(0, +) / Double(older.count)

        let recentAvgAXErrors = recent.map { Double($0.accessibilityErrors) }.reduce(0, +) / Double(recent.count)
        let olderAvgAXErrors = older.map { Double($0.accessibilityErrors) }.reduce(0, +) / Double(older.count)

        let recentAvgPerfRegressions = recent.map { Double($0.performanceRegressions) }.reduce(0, +) / Double(recent.count)
        let olderAvgPerfRegressions = older.map { Double($0.performanceRegressions) }.reduce(0, +) / Double(older.count)

        return TrendData(
            coverageTrend: recentAvgCoverage - olderAvgCoverage,
            testTrend: recentPassRate - olderPassRate,
            qualityTrend: recentAvgScore - olderAvgScore,
            accessibilityTrend: olderAvgAXErrors - recentAvgAXErrors, // Negative is good (fewer errors)
            performanceTrend: olderAvgPerfRegressions - recentAvgPerfRegressions, // Negative is good (fewer regressions)
            summary: generateTrendSummary(
                coverageTrend: recentAvgCoverage - olderAvgCoverage,
                testTrend: recentPassRate - olderPassRate,
                qualityTrend: recentAvgScore - olderAvgScore,
                accessibilityTrend: olderAvgAXErrors - recentAvgAXErrors,
                performanceTrend: olderAvgPerfRegressions - recentAvgPerfRegressions
            )
        )
    }

    /// Get best and worst scores from history
    public func getExtremes() -> (best: TestSummary?, worst: TestSummary?) {
        let history = loadHistory()
        guard !history.isEmpty else { return (nil, nil) }

        let sorted = history.sorted { $0.overallScore > $1.overallScore }
        return (sorted.first, sorted.last)
    }

    /// Get average score over last N days
    public func getAverageScore(days: Int = 7) -> Double {
        let history = loadHistory()
        let recent = history.suffix(days)

        guard !recent.isEmpty else { return 0.0 }

        return recent.map { $0.overallScore }.reduce(0, +) / Double(recent.count)
    }

    /// Get compliance rate (percentage of builds passing gates)
    public func getComplianceRate(days: Int = 30) -> Double {
        let history = loadHistory()
        let period = history.suffix(days)

        guard !period.isEmpty else { return 0.0 }

        let passing = period.filter { $0.passesPreMergeGates }.count
        return Double(passing) / Double(period.count) * 100
    }

    // MARK: - Private

    private func loadHistory() -> [TestSummary] {
        guard let data = try? Data(contentsOf: historyURL),
              let history = try? JSONDecoder().decode([TestSummary].self, from: data) else {
            return []
        }

        return history
    }

    private func saveHistory(_ history: [TestSummary]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: historyURL)
    }

    private func archiveSummary(_ summary: TestSummary) {
        // Create daily archive
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: summary.date).prefix(10)

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let archiveDir = paths[0].appendingPathComponent("test-archive")
        try? FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)

        let archiveURL = archiveDir.appendingPathComponent("test-summary-\(dateString).json")

        guard let data = try? JSONEncoder().encode(summary) else { return }
        try? data.write(to: archiveURL)
    }

    private func generateTrendSummary(
        coverageTrend: Double,
        testTrend: Double,
        qualityTrend: Double,
        accessibilityTrend: Double,
        performanceTrend: Double
    ) -> String {
        var summary = ""

        // Coverage trend
        if coverageTrend > 1 {
            summary += "📈 Coverage +\(String(format: "%.1f", coverageTrend))% "
        } else if coverageTrend < -1 {
            summary += "📉 Coverage \(String(format: "%.1f", coverageTrend))% "
        }

        // Test pass rate trend
        if testTrend > 0.01 {
            summary += "✅ Test pass rate +\(String(format: "%.1f", testTrend * 100))% "
        } else if testTrend < -0.01 {
            summary += "❌ Test pass rate \(String(format: "%.1f", testTrend * 100))% "
        }

        // Quality score trend
        if qualityTrend > 1 {
            summary += "🌟 Quality score +\(String(format: "%.1f", qualityTrend)) "
        } else if qualityTrend < -1 {
            summary += "⚠️  Quality score \(String(format: "%.1f", qualityTrend)) "
        }

        // Accessibility trend (fewer errors is good)
        if accessibilityTrend > 0.1 {
            summary += "♿ Accessibility -\(String(format: "%.1f", accessibilityTrend)) errors "
        } else if accessibilityTrend < -0.1 {
            summary += "⚠️  Accessibility +\(String(format: "%.1f", -accessibilityTrend)) errors "
        }

        // Performance trend (fewer regressions is good)
        if performanceTrend > 0.1 {
            summary += "⚡ Performance -\(String(format: "%.1f", performanceTrend)) regressions "
        } else if performanceTrend < -0.1 {
            summary += "⚠️  Performance +\(String(format: "%.1f", -performanceTrend)) regressions "
        }

        return summary.isEmpty ? "→ No significant change" : summary
    }
}

// MARK: - Trend Data

/// Trend analysis data comparing recent vs older test results
public struct TrendData: Codable {
    /// Coverage trend percentage (positive = improvement)
    public let coverageTrend: Double

    /// Test pass rate trend (positive = improvement)
    public let testTrend: Double

    /// Quality score trend (positive = improvement)
    public let qualityTrend: Double

    /// Accessibility trend (positive = improvement, fewer errors)
    public let accessibilityTrend: Double

    /// Performance trend (positive = improvement, fewer regressions)
    public let performanceTrend: Double

    /// Human-readable summary
    public let summary: String

    public init(
        coverageTrend: Double,
        testTrend: Double,
        qualityTrend: Double,
        accessibilityTrend: Double,
        performanceTrend: Double,
        summary: String
    ) {
        self.coverageTrend = coverageTrend
        self.testTrend = testTrend
        self.qualityTrend = qualityTrend
        self.accessibilityTrend = accessibilityTrend
        self.performanceTrend = performanceTrend
        self.summary = summary
    }
}

// MARK: - Trend Analysis Extensions

extension HistoricalTracker {
    /// Get detailed trend analysis by category
    public func getTrendAnalysis() -> TrendAnalysis {
        let history = loadHistory()
        guard history.count >= 7 else {
            return TrendAnalysis(
                period: "Insufficient data",
                overallTrend: .unknown,
                categoryTrends: [:],
                recommendations: []
            )
        }

        let recent = history.suffix(7)
        let trends = getTrend()

        // Analyze overall trend
        let overallTrend: TrendDirection
        if trends.qualityTrend > 2 {
            overallTrend = .improving
        } else if trends.qualityTrend < -2 {
            overallTrend = .declining
        } else {
            overallTrend = .stable
        }

        // Category trends
        var categoryTrends: [String: TrendDirection] = [:]

        categoryTrends["coverage"] = trends.coverageTrend > 1 ? .improving :
                                     (trends.coverageTrend < -1 ? .declining : .stable)

        categoryTrends["tests"] = trends.testTrend > 0.01 ? .improving :
                                  (trends.testTrend < -0.01 ? .declining : .stable)

        categoryTrends["accessibility"] = trends.accessibilityTrend > 0.1 ? .improving :
                                         (trends.accessibilityTrend < -0.1 ? .declining : .stable)

        categoryTrends["performance"] = trends.performanceTrend > 0.1 ? .improving :
                                        (trends.performanceTrend < -0.1 ? .declining : .stable)

        // Generate recommendations
        var recommendations: [String] = []

        if trends.coverageTrend < -1 {
            recommendations.append("⚠️  Coverage declining - review test gaps")
        }

        if trends.testTrend < -0.01 {
            recommendations.append("⚠️  Test pass rate declining - investigate failures")
        }

        if trends.accessibilityTrend < -0.1 {
            recommendations.append("⚠️  Accessibility errors increasing - audit UI components")
        }

        if trends.performanceTrend < -0.1 {
            recommendations.append("⚠️  Performance regressions increasing - profile critical paths")
        }

        if overallTrend == .improving && recommendations.isEmpty {
            recommendations.append("✅ All metrics trending positively - keep up the good work!")
        }

        return TrendAnalysis(
            period: "Last 7 days vs previous period",
            overallTrend: overallTrend,
            categoryTrends: categoryTrends,
            recommendations: recommendations
        )
    }
}

// MARK: - Trend Analysis

/// Comprehensive trend analysis with recommendations
public struct TrendAnalysis: Codable {
    /// Time period analyzed
    public let period: String

    /// Overall trend direction
    public let overallTrend: TrendDirection

    /// Category-specific trends
    public let categoryTrends: [String: TrendDirection]

    /// Actionable recommendations
    public let recommendations: [String]

    public init(
        period: String,
        overallTrend: TrendDirection,
        categoryTrends: [String: TrendDirection],
        recommendations: [String]
    ) {
        self.period = period
        self.overallTrend = overallTrend
        self.categoryTrends = categoryTrends
        self.recommendations = recommendations
    }
}

// MARK: - Trend Direction

/// Direction of trend
public enum TrendDirection: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    case unknown = "unknown"

    public var emoji: String {
        switch self {
        case .improving: return "📈"
        case .stable: return "➡️"
        case .declining: return "📉"
        case .unknown: return "❓"
        }
    }

    public var description: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .unknown: return "Unknown"
        }
    }
}
