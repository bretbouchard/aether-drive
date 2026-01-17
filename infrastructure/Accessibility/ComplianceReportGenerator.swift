//
//  ComplianceReportGenerator.swift
//  White Room Infrastructure
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - Compliance Report Generator
// =============================================================================

/// Generates WCAG 2.1 AA compliance reports from accessibility audit results.
///
/// This report generator analyzes accessibility issues found during testing
/// and produces comprehensive compliance reports including:
///
/// - WCAG 2.1 AA compliance level (AA, AAA, or Fail)
/// - Total issue count by severity
/// - Categorized recommendations with priorities
/// - Executive summary with actionable next steps
/// - Detailed issue analysis with code locations
///
/// **Usage**:
/// ```swift
/// let generator = ComplianceReportGenerator.shared
/// let issues = AccessibilityInspector(app).audit()
/// let report = generator.generateReport(from: issues)
/// print(report.summary)
/// ```
///
/// **Success Criteria**:
/// - Zero critical issues for WCAG AA compliance
/// - All errors documented with code locations
/// - Prioritized recommendations for fixes
/// - Clear compliance status and next steps
public class ComplianceReportGenerator {

    public static let shared = ComplianceReportGenerator()

    private init() {}

    // =============================================================================
    // MARK: - Report Generation
    // =============================================================================

    /// Generate a comprehensive compliance report from accessibility issues
    public func generateReport(from issues: [AccessibilityIssue]) -> ComplianceReport {
        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }

        let wcagLevel = determineWCAGLevel(errors: errors, warnings: warnings)

        return ComplianceReport(
            timestamp: Date(),
            wcagLevel: wcagLevel,
            totalIssues: issues.count,
            errors: errors,
            warnings: warnings,
            compliant: errors.isEmpty,
            summary: generateSummary(errors: errors, warnings: warnings),
            recommendations: generateRecommendations(from: issues),
            metrics: generateMetrics(from: issues)
        )
    }

    // =============================================================================
    // MARK: - WCAG Level Determination
    // =============================================================================

    private func determineWCAGLevel(errors: [AccessibilityIssue], warnings: [AccessibilityIssue]) -> WCAGLevel {
        // WCAG 2.1 AA requires zero errors
        if errors.isEmpty && warnings.isEmpty {
            return .AAA // Perfect compliance
        } else if errors.isEmpty {
            return .AA // Compliant with warnings
        } else {
            return .Fail // Non-compliant
        }
    }

    // =============================================================================
    // MARK: - Summary Generation
    // =============================================================================

    private func generateSummary(errors: [AccessibilityIssue], warnings: [AccessibilityIssue]) -> String {
        if errors.isEmpty && warnings.isEmpty {
            return "✅ WCAG 2.1 AAA Compliant - No accessibility issues found"
        } else if errors.isEmpty {
            return "⚠️ WCAG 2.1 AA Compliant - \(warnings.count) warning(s) that should be addressed"
        } else {
            return "❌ Not WCAG Compliant - \(errors.count) error(s), \(warnings.count) warning(s) must be fixed"
        }
    }

    // =============================================================================
    // MARK: - Recommendations Generation
    // =============================================================================

    private func generateRecommendations(from issues: [AccessibilityIssue]) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Group issues by type
        let issuesByType = Dictionary(grouping: issues) { $0.type }

        for (type, typeIssues) in issuesByType {
            let recommendation = Recommendation(
                category: type,
                priority: determinePriority(for: type, severity: typeIssues.first?.severity ?? .warning),
                description: generateDescription(for: type),
                actionItems: typeIssues.map { issue in
                    ActionItem(
                        issue: issue.message,
                        location: issue.location,
                        severity: issue.severity
                    )
                },
                wcagCriteria: wcagCriteria(for: type)
            )
            recommendations.append(recommendation)
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    private func determinePriority(for type: AccessibilityIssue.IssueType, severity: AccessibilityIssue.Severity) -> Priority {
        // Critical errors get highest priority
        if severity == .error {
            switch type {
            case .missingLabel:
                return .critical
            case .contrast:
                return .critical
            case .tapTargetSize:
                return .high
            default:
                return .high
            }
        }

        // Warnings get lower priority
        switch type {
        case .contrast:
            return .high
        case .missingLabel:
            return .medium
        case .tapTargetSize:
            return .medium
        default:
            return .low
        }
    }

    private func generateDescription(for type: AccessibilityIssue.IssueType) -> String {
        switch type {
        case .contrast:
            return "Color contrast issues detected - text may be difficult to read"
        case .missingLabel:
            return "Missing accessibility labels - screen reader users cannot understand elements"
        case .tapTargetSize:
            return "Interactive elements below minimum size - difficult for users with motor impairments"
        case .focusOrder:
            return "Illogical focus order - confusing for keyboard and screen reader users"
        case .missingHint:
            return "Missing accessibility hints - users may not understand element purpose"
        case .missingTrait:
            return "Missing accessibility traits - screen readers announce incorrect element type"
        }
    }

    private func wcagCriteria(for type: AccessibilityIssue.IssueType) -> [String] {
        switch type {
        case .contrast:
            return ["WCAG 2.1 AA 1.4.3 Contrast (Minimum)"]
        case .missingLabel:
            return ["WCAG 2.1 A 1.1.1 Non-text Content", "WCAG 2.1 A 2.4.4 Link Purpose"]
        case .tapTargetSize:
            return ["WCAG 2.1 AAA 2.5.5 Target Size"]
        case .focusOrder:
            return ["WCAG 2.1 A 2.4.3 Focus Order"]
        case .missingHint:
            return ["WCAG 2.1 A 2.5.7 Dragging Movements"]
        case .missingTrait:
            return ["WCAG 2.1 A 4.1.2 Name, Role, Value"]
        }
    }

    // =============================================================================
    // MARK: - Metrics Generation
    // =============================================================================

    private func generateMetrics(from issues: [AccessibilityIssue]) -> ComplianceMetrics {
        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count

        let issuesByType = Dictionary(grouping: issues) { $0.type }
        let issuesByScreen = Dictionary(grouping: issues) { $0.location.screen }

        return ComplianceMetrics(
            totalIssues: issues.count,
            errorCount: errorCount,
            warningCount: warningCount,
            issuesByType: issuesByType.mapValues { $0.count },
            issuesByScreen: issuesByScreen.mapValues { $0.count },
            complianceRate: issues.isEmpty ? 1.0 : 1.0 - (Double(errorCount) / Double(issues.count))
        )
    }

    // =============================================================================
    // MARK: - Report Export
    // =============================================================================

    /// Export report as JSON
    public func exportJSON(_ report: ComplianceReport) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(report)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Export report as Markdown
    public func exportMarkdown(_ report: ComplianceReport) -> String {
        var markdown = "# Accessibility Compliance Report\n\n"

        // Summary
        markdown += "## Summary\n\n"
        markdown += "\(report.summary)\n\n"
        markdown += "- **WCAG Level**: \(report.wcagLevel.rawValue)\n"
        markdown += "- **Total Issues**: \(report.totalIssues)\n"
        markdown += "- **Errors**: \(report.errors.count)\n"
        markdown += "- **Warnings**: \(report.warnings.count)\n"
        markdown += "- **Compliance Rate**: \(String(format: "%.1f%%", report.metrics.complianceRate * 100))\n\n"

        // Metrics
        markdown += "## Metrics\n\n"
        markdown += "### Issues by Type\n\n"
        for (type, count) in report.metrics.issuesByType.sorted(by: { $0.value > $1.value }) {
            markdown += "- **\(type.rawValue)**: \(count)\n"
        }
        markdown += "\n"

        markdown += "### Issues by Screen\n\n"
        for (screen, count) in report.metrics.issuesByScreen.sorted(by: { $0.value > $1.value }) {
            markdown += "- **\(screen)**: \(count)\n"
        }
        markdown += "\n"

        // Recommendations
        markdown += "## Recommendations\n\n"

        let groupedByPriority = Dictionary(grouping: report.recommendations) { $0.priority }

        for priority in [Priority.critical, .high, .medium, .low] {
            if let recommendations = groupedByPriority[priority], !recommendations.isEmpty {
                markdown += "### \(priority.rawValue.uppercased()) Priority\n\n"

                for recommendation in recommendations {
                    markdown += "#### \(recommendation.category.rawValue)\n\n"
                    markdown += "\(recommendation.description)\n\n"

                    if !recommendation.wcagCriteria.isEmpty {
                        markdown += "**WCAG Criteria**: \(recommendation.wcagCriteria.joined(separator: ", "))\n\n"
                    }

                    markdown += "**Action Items**:\n\n"
                    for item in recommendation.actionItems {
                        markdown += "- \(item.severity.rawValue.uppercased()): \(item.issue)"
                        if let location = item.location {
                            markdown += " at `\(location.file):\(location.line)`"
                        }
                        markdown += "\n"
                    }
                    markdown += "\n"
                }
            }
        }

        // Footer
        markdown += "---\n\n"
        markdown += "Generated: \(DateFormatter.reportFormatter.string(from: report.timestamp))\n"
        markdown += "White Room Accessibility Auditor v1.0\n"

        return markdown
    }
}

// =============================================================================
// MARK: - Compliance Report
// =============================================================================

public struct ComplianceReport: Codable {

    public let timestamp: Date
    public let wcagLevel: WCAGLevel
    public let totalIssues: Int
    public let errors: [AccessibilityIssue]
    public let warnings: [AccessibilityIssue]
    public let compliant: Bool
    public let summary: String
    public let recommendations: [Recommendation]
    public let metrics: ComplianceMetrics

    public enum WCAGLevel: String, Codable {
        case AAA = "AAA"
        case AA = "AA"
        case Fail = "Fail"
    }
}

// =============================================================================
// MARK: - Recommendation
// =============================================================================

public struct Recommendation: Codable {

    public let category: AccessibilityIssue.IssueType
    public let priority: Priority
    public let description: String
    public let actionItems: [ActionItem]
    public let wcagCriteria: [String]

    public enum Priority: String, Codable {
        case critical = "CRITICAL"
        case high = "HIGH"
        case medium = "MEDIUM"
        case low = "LOW"

        var rawValue: String {
            return self.rawValue
        }
    }
}

// =============================================================================
// MARK: - Action Item
// =============================================================================

public struct ActionItem: Codable {

    public let issue: String
    public let location: IssueLocation?
    public let severity: AccessibilityIssue.Severity
}

// =============================================================================
// MARK: - Compliance Metrics
// =============================================================================

public struct ComplianceMetrics: Codable {

    public let totalIssues: Int
    public let errorCount: Int
    public let warningCount: Int
    public let issuesByType: [AccessibilityIssue.IssueType: Int]
    public let issuesByScreen: [String: Int]
    public let complianceRate: Double
}

// =============================================================================
// MARK: - Accessibility Issue
// =============================================================================

public struct AccessibilityIssue: Codable {

    public let type: IssueType
    public let severity: Severity
    public let message: String
    public let location: IssueLocation?

    public enum IssueType: String, Codable {
        case contrast = "Color Contrast"
        case missingLabel = "Missing Label"
        case tapTargetSize = "Tap Target Size"
        case focusOrder = "Focus Order"
        case missingHint = "Missing Hint"
        case missingTrait = "Missing Trait"
    }

    public enum Severity: String, Codable {
        case error = "ERROR"
        case warning = "WARNING"
    }

    public init(
        type: IssueType,
        severity: Severity,
        message: String,
        location: IssueLocation? = nil
    ) {
        self.type = type
        self.severity = severity
        self.message = message
        self.location = location
    }
}

// =============================================================================
// MARK: - Issue Location
// =============================================================================

public struct IssueLocation: Codable {

    public let file: String
    public let line: Int
    public let function: String
    public let screen: String
}

// =============================================================================
// MARK: - Date Formatter Extension
// =============================================================================

extension DateFormatter {

    static let reportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
