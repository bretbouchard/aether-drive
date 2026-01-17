//
// DailyTestReport.swift
// White Room QA Dashboard
//
// Daily test report generation and formatting
//

import Foundation

/// Daily test report generator
public struct DailyTestReport {
    /// Generate daily report
    public func generate() -> String {
        let summary = loadTestSummary()
        let formatter = ISO8601DateFormatter()

        var report = """
        # White Room Daily Test Report

        **Date:** \(formatter.string(from: summary.date))

        ## Overall Score: \(summary.grade) \(summary.gradeEmoji)

        **Score:** \(String(format: "%.1f", summary.overallScore))%

        """

        // Coverage section
        report += """

        ## 📊 Coverage

        - **SDK:** \(String(format: "%.1f", summary.sdkCoverage))%
        - **Status:** \(summary.sdkCoverage >= 80.0 ? "✅ On Track" : "⚠️ Needs Improvement")

        """

        // Tests section
        report += """

        ## 🧪 Tests

        - **iOS:** \(summary.iosTestsPassed) passed, \(summary.iosTestsFailed) failed
        - **tvOS:** \(summary.tvosTestsPassed) passed, \(summary.tvosTestsFailed) failed
        - **Total:** \(summary.totalTests) tests
        - **Pass Rate:** \(String(format: "%.1f", summary.iosPassRate * 100))%
        - **Status:** \(summary.iosTestsFailed == 0 ? "✅ All Passing" : "❌ Failures Detected")

        """

        // Quality section
        report += """

        ## ✨ Quality

        - **Accessibility:** \(summary.accessibilityErrors) errors, \(summary.accessibilityWarnings) warnings
        - **Performance:** \(summary.performanceRegressions) regressions
        - **Visual:** \(summary.visualRegressions) regressions
        - **Security:** \(summary.securityVulnerabilities) vulnerabilities
        - **Total Issues:** \(summary.qualityIssues)

        """

        // Telemetry section
        report += """

        ## 📈 Telemetry

        - **Crash-Free Users:** \(String(format: "%.2f", summary.crashFreeUsers))%
        - **Active Sessions:** \(summary.activeSessions)
        - **Status:** \(summary.crashFreeUsers >= 99.0 ? "✅ Excellent" : "⚠️ Monitor")

        """

        // Quality gates
        report += """

        ## 🚦 Quality Gates

        - **Pre-Merge:** \(summary.passesPreMergeGates ? "✅ PASS" : "❌ FAIL")
        - **Pre-Release:** \(summary.passesPreReleaseGates ? "✅ PASS" : "❌ FAIL")

        """

        // Trends
        report += loadTrendData()

        // Recommendations
        report += generateRecommendations(summary: summary)

        return report
    }

    /// Generate HTML version of report
    public func generateHTML() -> String {
        let summary = loadTestSummary()

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>White Room Daily Test Report</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    max-width: 800px;
                    margin: 40px auto;
                    padding: 20px;
                    background: #f5f5f7;
                }
                .container {
                    background: white;
                    border-radius: 12px;
                    padding: 30px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                h1 {
                    color: #1d1d1f;
                    margin-bottom: 10px;
                }
                .date {
                    color: #86868b;
                    font-size: 14px;
                    margin-bottom: 30px;
                }
                .score {
                    font-size: 72px;
                    font-weight: bold;
                    text-align: center;
                    margin: 30px 0;
                    color: \(gradeColor(summary.grade));
                }
                .grade {
                    font-size: 24px;
                    text-align: center;
                    margin-top: -20px;
                    margin-bottom: 30px;
                }
                .section {
                    margin: 30px 0;
                    padding: 20px;
                    background: #f9f9f9;
                    border-radius: 8px;
                }
                .section-title {
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 15px;
                    color: #1d1d1f;
                }
                .metric {
                    display: flex;
                    justify-content: space-between;
                    padding: 10px 0;
                    border-bottom: 1px solid #e5e5e5;
                }
                .metric:last-child {
                    border-bottom: none;
                }
                .pass { color: #34c759; }
                .fail { color: #ff3b30; }
                .warning { color: #ff9500; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>White Room Daily Test Report</h1>
                <div class="date">\(ISO8601DateFormatter().string(from: summary.date))</div>

                <div class="score">\(String(format: "%.0f", summary.overallScore))%</div>
                <div class="grade">Grade: \(summary.grade) \(summary.gradeEmoji)</div>

        """

        // Coverage
        html += """
                <div class="section">
                    <div class="section-title">📊 Coverage</div>
                    <div class="metric">
                        <span>SDK</span>
                        <span class="\(summary.sdkCoverage >= 80.0 ? "pass" : "warning")">\(String(format: "%.1f", summary.sdkCoverage))%</span>
                    </div>
                </div>
        """

        // Tests
        html += """
                <div class="section">
                    <div class="section-title">🧪 Tests</div>
                    <div class="metric">
                        <span>iOS Passed</span>
                        <span class="pass">\(summary.iosTestsPassed)</span>
                    </div>
                    <div class="metric">
                        <span>iOS Failed</span>
                        <span class="\(summary.iosTestsFailed > 0 ? "fail" : "pass")">\(summary.iosTestsFailed)</span>
                    </div>
                    <div class="metric">
                        <span>Pass Rate</span>
                        <span class="\(summary.iosPassRate >= 0.95 ? "pass" : "warning")">\(String(format: "%.1f", summary.iosPassRate * 100))%</span>
                    </div>
                </div>
        """

        // Quality
        html += """
                <div class="section">
                    <div class="section-title">✨ Quality</div>
                    <div class="metric">
                        <span>Accessibility Errors</span>
                        <span class="\(summary.accessibilityErrors > 0 ? "fail" : "pass")">\(summary.accessibilityErrors)</span>
                    </div>
                    <div class="metric">
                        <span>Performance Regressions</span>
                        <span class="\(summary.performanceRegressions > 0 ? "fail" : "pass")">\(summary.performanceRegressions)</span>
                    </div>
                    <div class="metric">
                        <span>Visual Regressions</span>
                        <span class="\(summary.visualRegressions > 0 ? "fail" : "pass")">\(summary.visualRegressions)</span>
                    </div>
                </div>
        """

        // Gates
        html += """
                <div class="section">
                    <div class="section-title">🚦 Quality Gates</div>
                    <div class="metric">
                        <span>Pre-Merge</span>
                        <span class="\(summary.passesPreMergeGates ? "pass" : "fail")">\(summary.passesPreMergeGates ? "✅ PASS" : "❌ FAIL")</span>
                    </div>
                    <div class="metric">
                        <span>Pre-Release</span>
                        <span class="\(summary.passesPreReleaseGates ? "pass" : "fail")">\(summary.passesPreReleaseGates ? "✅ PASS" : "❌ FAIL")</span>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """

        return html
    }

    /// Load test summary from file
    private func loadTestSummary() -> TestSummary {
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

    /// Load trend data
    private func loadTrendData() -> String {
        // TODO: Implement trend analysis from historical data
        return """

        ## 📈 Trends

        *No historical data available yet. Trends will appear after 7 days of data collection.*

        """
    }

    /// Generate actionable recommendations
    private func generateRecommendations(summary: TestSummary) -> String {
        var recommendations = "\n## 💡 Recommendations\n\n"

        var hasRecommendations = false

        // Coverage recommendations
        if summary.sdkCoverage < 80.0 {
            recommendations += "- ⚠️ **Coverage:** Add tests to reach 80% threshold\n"
            hasRecommendations = true
        } else if summary.sdkCoverage < 85.0 {
            recommendations += "- 💡 **Coverage:** Aim for 85%+ for release quality\n"
            hasRecommendations = true
        }

        // Test failures
        if summary.iosTestsFailed > 0 {
            recommendations += "- 🚨 **Tests:** Fix \(summary.iosTestsFailed) failing iOS tests\n"
            hasRecommendations = true
        }

        // Accessibility
        if summary.accessibilityErrors > 0 {
            recommendations += "- ♿ **Accessibility:** Resolve \(summary.accessibilityErrors) accessibility issues\n"
            hasRecommendations = true
        }

        // Performance
        if summary.performanceRegressions > 0 {
            recommendations += "- ⚡ **Performance:** Investigate \(summary.performanceRegressions) performance regressions\n"
            hasRecommendations = true
        }

        // Visual
        if summary.visualRegressions > 0 {
            recommendations += "- 🎨 **Visual:** Review \(summary.visualRegressions) visual regression(s)\n"
            hasRecommendations = true
        }

        // Security
        if summary.securityVulnerabilities > 0 {
            recommendations += "- 🔒 **Security:** Address \(summary.securityVulnerabilities) vulnerabilities immediately\n"
            hasRecommendations = true
        }

        // Crash rate
        if summary.crashFreeUsers < 99.0 && summary.crashFreeUsers > 0 {
            recommendations += "- 💥 **Stability:** Improve crash-free rate to 99%+\n"
            hasRecommendations = true
        }

        if !hasRecommendations {
            recommendations += "✅ All metrics look great! Keep up the good work.\n"
        }

        return recommendations
    }

    /// Get color for grade
    private func gradeColor(_ grade: String) -> String {
        switch grade {
        case "A+", "A": return "#34c759"
        case "B+", "B": return "#007aff"
        case "C": return "#ff9500"
        default: return "#ff3b30"
        }
    }

    /// Save report to file
    public func save(to url: URL, format: ReportFormat = .markdown) throws {
        let content: String
        switch format {
        case .markdown:
            content = generate()
        case .html:
            content = generateHTML()
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

// MARK: - Report Format

extension DailyTestReport {
    public enum ReportFormat {
        case markdown
        case html
    }
}
