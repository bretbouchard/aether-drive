//
//  TelemetryMetrics.swift
//  White Room QA Dashboard
//
//  Telemetry metrics integration with QA dashboard
//

import Foundation

/// Telemetry metrics aggregator for QA dashboard
public class TelemetryMetrics {
    public static let shared = TelemetryMetrics()

    private init() {}

    // MARK: - Report Generation

    /// Generate telemetry report from test summary
    public func generateReport(from summary: TestSummary) -> TelemetryReport {
        let uiEvents = countUIEvents(from: summary)
        let performanceMetrics = extractPerformanceMetrics(from: summary)
        let errors = extractErrors(from: summary)

        return TelemetryReport(
            totalUIEvents: uiEvents,
            averageResponseTime: performanceMetrics.averageResponseTime,
            slowOperations: performanceMetrics.slowOperations,
            errorCount: errors.count,
            topErrors: errors.prefix(5).map { $0 },
            crashFreeSessions: summary.crashFreeUsers
        )
    }

    /// Generate telemetry report from raw telemetry events
    public func generateReport(from events: [TelemetryEvent]) -> TelemetryReport {
        let uiEvents = events.filter { $0.type == .uiInteraction }.count
        let performanceEvents = events.filter { $0.type == .performance }
        let errorEvents = events.filter { $0.type == .error }

        let responseTimes = performanceEvents.compactMap { event -> TimeInterval? in
            guard let durationStr = event.context["duration"],
                  let duration = Double(durationStr) else { return nil }
            return duration
        }

        let avgResponseTime = responseTimes.isEmpty ? 0.0 : responseTimes.reduce(0, +) / Double(responseTimes.count)

        let slowOps = performanceEvents.compactMap { event -> SlowOperation? in
            guard let durationStr = event.context["duration"],
                  let duration = Double(durationStr),
                  let thresholdStr = event.context["threshold"],
                  let threshold = Double(thresholdStr),
                  duration > threshold else { return nil }
            return SlowOperation(
                name: event.action,
                duration: duration,
                threshold: threshold
            )
        }

        let errorMetrics = errorEvents.map { event in
            ErrorMetric(
                message: event.action,
                count: 1,
                frequency: 1.0
            )
        }

        return TelemetryReport(
            totalUIEvents: uiEvents,
            averageResponseTime: avgResponseTime,
            slowOperations: slowOps.sorted { $0.duration > $1.duration },
            errorCount: errorEvents.count,
            topErrors: errorMetrics.prefix(5).map { $0 },
            crashFreeSessions: 100.0 // Will be updated from TestSummary
        )
    }

    // MARK: - Private Methods

    private func countUIEvents(from summary: TestSummary) -> Int {
        // Load telemetry events and count UI interactions
        // For now, estimate based on test runs
        // In production, this would load from telemetry storage
        return Int(summary.activeSessions * 10) // Heuristic: ~10 events per session
    }

    private func extractPerformanceMetrics(from summary: TestSummary) -> PerformanceMetrics {
        // Extract performance data from telemetry
        // For now, return empty metrics
        // In production, this would load from telemetry storage
        return PerformanceMetrics(
            averageResponseTime: 0.0,
            slowOperations: []
        )
    }

    private func extractErrors(from summary: TestSummary) -> [ErrorMetric] {
        // Extract error data from telemetry
        // For now, return empty array
        // In production, this would load from telemetry storage
        return []
    }
}

// MARK: - Telemetry Report

/// Complete telemetry report for QA dashboard
public struct TelemetryReport: Codable, Identifiable {
    public let id = UUID()
    public let totalUIEvents: Int
    public let averageResponseTime: TimeInterval
    public let slowOperations: [SlowOperation]
    public let errorCount: Int
    public let topErrors: [ErrorMetric]
    public let crashFreeSessions: Double

    /// Markdown summary for dashboard
    public var summary: String {
        """
        ## Telemetry Summary

        **UI Events:** \(totalUIEvents)
        **Avg Response:** \(String(format: "%.0f", averageResponseTime * 1000))ms
        **Slow Operations:** \(slowOperations.count)
        **Errors:** \(errorCount)
        **Crash-Free:** \(String(format: "%.1f", crashFreeSessions))%

        \(slowOperations.isEmpty ? "" : slowOperationsSummary)

        \(topErrors.isEmpty ? "" : topErrorsSummary)
        """
    }

    private var slowOperationsSummary: String {
        var summary = "\n### Slow Operations\n\n"
        for op in slowOperations.prefix(5) {
            summary += "- **\(op.name)**: \(String(format: "%.0f", op.duration * 1000))ms " +
                      "(threshold: \(String(format: "%.0f", op.threshold * 1000))ms)\n"
        }
        return summary
    }

    private var topErrorsSummary: String {
        var summary = "\n### Top Errors\n\n"
        for error in topErrors {
            summary += "- **\(error.message)**: \(error.count)x " +
                      "(\(String(format: "%.1f", error.frequency * 100))%)\n"
        }
        return summary
    }

    /// Check if telemetry meets quality thresholds
    public var meetsQualityThresholds: Bool {
        averageResponseTime < 0.2 && // < 200ms
        slowOperations.filter { $0.duration > ($0.threshold * 2) }.count == 0 &&
        crashFreeSessions >= 99.0
    }
}

// MARK: - Performance Metrics

/// Performance metrics extracted from telemetry
public struct PerformanceMetrics: Codable {
    public let averageResponseTime: TimeInterval
    public let slowOperations: [SlowOperation]
}

// MARK: - Slow Operation

/// Slow operation detected in telemetry
public struct SlowOperation: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let duration: TimeInterval
    public let threshold: TimeInterval

    /// Severity level based on how much it exceeds threshold
    public var severity: String {
        let ratio = duration / threshold
        switch ratio {
        case 1.0..<1.5: return "Warning"
        case 1.5..<2.0: return "Minor"
        case 2.0..<3.0: return "Moderate"
        default: return "Severe"
        }
    }

    /// Duration over threshold in milliseconds
    public var excessDuration: TimeInterval {
        duration - threshold
    }
}

// MARK: - Error Metric

/// Error metric from telemetry
public struct ErrorMetric: Codable, Identifiable {
    public let id = UUID()
    public let message: String
    public let count: Int
    public let frequency: Double
}

// MARK: - Dashboard Integration

extension DashboardData {
    /// Add telemetry report to dashboard data
    public func withTelemetry(_ telemetry: TelemetryReport) -> DashboardData {
        // Create a new dashboard data with telemetry integrated
        // Note: This is a conceptual extension - in production, DashboardData would have a telemetry property
        return DashboardData(
            current: current,
            history: history,
            trends: trends,
            alerts: alerts + telemetryAlerts(from: telemetry),
            generatedAt: generatedAt
        )
    }

    private func telemetryAlerts(from telemetry: TelemetryReport) -> [Alert] {
        var alerts: [Alert] = []

        // Slow operations
        if !telemetry.slowOperations.isEmpty {
            let severeSlowOps = telemetry.slowOperations.filter { $0.severity == "Severe" }
            if !severeSlowOps.isEmpty {
                alerts.append(Alert(
                    severity: .warning,
                    title: "Slow Operations Detected",
                    message: "\(severeSlowOps.count) operations exceeding 2x threshold",
                    category: .performance
                ))
            }
        }

        // High error rate
        if telemetry.errorCount > 10 {
            alerts.append(Alert(
                severity: .error,
                title: "High Error Rate",
                message: "\(telemetry.errorCount) errors in telemetry",
                category: .stability
            ))
        }

        // Slow response time
        if telemetry.averageResponseTime > 0.2 {
            alerts.append(Alert(
                severity: .warning,
                title: "Slow Response Time",
                message: "Avg response: \(String(format: "%.0f", telemetry.averageResponseTime * 1000))ms",
                category: .performance
            ))
        }

        // Low crash-free sessions
        if telemetry.crashFreeSessions < 99.0 && telemetry.crashFreeSessions > 0 {
            alerts.append(Alert(
                severity: telemetry.crashFreeSessions < 95.0 ? .error : .warning,
                title: "Crash Rate Warning",
                message: "Crash-free sessions: \(String(format: "%.1f", telemetry.crashFreeSessions))%",
                category: .stability
            ))
        }

        return alerts
    }
}

// MARK: - Test Summary Extension

extension TestSummary {
    /// Create test instance for testing
    public static var testInstance: TestSummary {
        TestSummary(
            sdkCoverage: 85.0,
            iosTestsPassed: 150,
            iosTestsFailed: 2,
            tvosTestsPassed: 50,
            tvosTestsFailed: 0,
            accessibilityErrors: 0,
            accessibilityWarnings: 3,
            performanceRegressions: 1,
            visualRegressions: 0,
            securityVulnerabilities: 0,
            crashFreeUsers: 99.5,
            activeSessions: 25
        )
    }
}
