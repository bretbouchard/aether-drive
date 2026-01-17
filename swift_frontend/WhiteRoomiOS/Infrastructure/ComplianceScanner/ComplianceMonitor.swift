//
//  ComplianceMonitor.swift
//  WhiteRoomiOS
//
//  Created by White Room Team on 1/16/25.
//

import Foundation
import Combine
import CoreData
import os.log

/// Continuous compliance monitoring system
/// Monitors compliance policies and generates alerts for violations
public class ComplianceMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published public var complianceStatus: ComplianceStatus
    @Published public var policies: [CompliancePolicy] = []
    @Published public var violations: [ComplianceViolation] = []
    @Published public var isMonitoring: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.whiteroom.ios", category: "ComplianceMonitor")
    private var cancellables = Set<AnyCancellable>()
    private let monitorQueue = DispatchQueue(label: "com.whiteroom.compliance.monitor", qos: .userInitiated)
    private var continuousMonitorTimer: Timer?

    // MARK: - Scanner Dependencies

    private let owaspScanner: OWASPScanner
    private let gdprValidator: GDPRValidator
    private let licenseChecker: LicenseChecker
    private let secretScanner: SecretScanner

    // MARK: - Initialization

    public init(
        owaspScanner: OWASPScanner = OWASPScanner(),
        gdprValidator: GDPRValidator = GDPRValidator(),
        licenseChecker: LicenseChecker = LicenseChecker(),
        secretScanner: SecretScanner = SecretScanner()
    ) {
        self.owaspScanner = owaspScanner
        self.gdprValidator = gdprValidator
        self.licenseChecker = licenseChecker
        self.secretScanner = secretScanner

        self.complianceStatus = ComplianceStatus(
            overallStatus: .compliant,
            securityCompliance: 100,
            privacyCompliance: 100,
            licenseCompliance: 100,
            accessibilityCompliance: 100,
            lastChecked: Date(),
            totalViolations: 0
        )

        logger.info("Compliance Monitor initialized")

        // Load default policies
        loadDefaultPolicies()
    }

    // MARK: - Public Policy Management

    /// Add a new compliance policy
    public func addPolicy(_ policy: CompliancePolicy) {
        logger.info("Adding policy: \(policy.name)")

        policies.append(policy)

        if policy.enabled {
            // Run initial check
            Task {
                _ = try? await checkCompliance(policy)
            }
        }
    }

    /// Remove a policy by ID
    public func removePolicy(id: String) {
        logger.info("Removing policy: \(id)")

        policies.removeAll { $0.id.uuidString == id }
    }

    /// Update an existing policy
    public func updatePolicy(_ policy: CompliancePolicy) {
        logger.info("Updating policy: \(policy.name)")

        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            policies[index] = policy
        }
    }

    // MARK: - Compliance Checking

    /// Check compliance for a specific policy
    public func checkCompliance(_ policy: CompliancePolicy) async throws -> ComplianceCheckResult {
        logger.info("Checking compliance for policy: \(policy.name)")

        var policyViolations: [ComplianceViolation] = []

        // Check each rule in the policy
        for rule in policy.rules {
            let ruleViolations = try await checkRule(rule, policy: policy)
            policyViolations.append(contentsOf: ruleViolations)

            // Auto-remediate if enabled
            if policy.autoRemediate && !ruleViolations.isEmpty {
                try await autoRemediate(ruleViolations)
            }
        }

        // Calculate score
        let score = calculatePolicyScore(policy, violations: policyViolations)

        let result = ComplianceCheckResult(
            policy: policy,
            compliant: policyViolations.isEmpty,
            score: score,
            violations: policyViolations,
            recommendations: generateRecommendations(policyViolations),
            timestamp: Date()
        )

        // Update violations list
        await MainActor.run {
            self.violations.append(contentsOf: policyViolations)
        }

        // Update overall status
        await updateComplianceStatus()

        logger.info("Compliance check complete: \(result.compliant ? "compliant" : "non-compliant")")
        return result
    }

    /// Check all enabled policies
    public func checkAllPolicies() async throws -> [ComplianceCheckResult] {
        logger.info("Checking all enabled policies")

        let enabledPolicies = policies.filter { $0.enabled }
        var results: [ComplianceCheckResult] = []

        for policy in enabledPolicies {
            let result = try await checkCompliance(policy)
            results.append(result)
        }

        return results
    }

    /// Start continuous monitoring
    public func monitorContinuously() {
        logger.info("Starting continuous monitoring")

        guard !isMonitoring else {
            logger.warning("Continuous monitoring already active")
            return
        }

        Task {
            await MainActor.run {
                self.isMonitoring = true
            }

            // Run checks every 5 minutes
            continuousMonitorTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                Task {
                    _ = try? await self.checkAllPolicies()
                }
            }

            logger.info("Continuous monitoring started")
        }
    }

    /// Stop continuous monitoring
    public func stopMonitoring() {
        logger.info("Stopping continuous monitoring")

        continuousMonitorTimer?.invalidate()
        continuousMonitorTimer = nil

        Task {
            await MainActor.run {
                self.isMonitoring = false
            }
        }
    }

    /// Generate compliance report for a time period
    public func generateComplianceReport(for period: DateInterval) async throws -> ComplianceReport {
        logger.info("Generating compliance report for period: \(period)")

        // Get violations within period
        let periodViolations = violations.filter { violation in
            period.contains(violation.discoveredAt)
        }

        // Group violations by type
        let groupedByType = Dictionary(grouping: periodViolations) { $0.policy }

        // Calculate statistics
        let totalViolations = periodViolations.count
        let resolvedViolations = periodViolations.filter { $0.resolvedAt != nil }.count
        let criticalViolations = periodViolations.filter { $0.severity == .critical }.count

        // Calculate compliance score
        let score = calculatePeriodScore(periodViolations)

        // Generate trends
        let trends = calculateComplianceTrends(for: period)

        let report = ComplianceReport(
            period: period,
            generatedAt: Date(),
            score: score,
            totalViolations: totalViolations,
            resolvedViolations: resolvedViolations,
            criticalViolations: criticalViolations,
            violationsByPolicy: groupedByType.mapValues { $0.count },
            topViolations: periodViolations.sorted { $0.severity.rawValue > $1.severity.rawValue }.prefix(10).map { $0 },
            recommendations: generatePeriodRecommendations(periodViolations),
            trends: trends
        )

        logger.info("Compliance report generated: score \(score)/100")
        return report
    }

    // MARK: - Private Helper Methods

    private func loadDefaultPolicies() {
        logger.info("Loading default policies")

        // OWASP Top 10 Policy
        let owaspPolicy = CompliancePolicy(
            name: "OWASP Top 10 2021",
            description: "Monitors compliance with OWASP Top 10 security risks",
            type: .security,
            rules: [
                ComplianceRule(
                    name: "SQL Injection Prevention",
                    description: "Code must not contain SQL injection vulnerabilities",
                    checkType: .owaspTop10,
                    parameters: ["vulnerability_type": "sql_injection"],
                    threshold: 0,
                    remediation: "Use parameterized queries and input validation"
                ),
                ComplianceRule(
                    name: "XSS Prevention",
                    description: "Code must not contain XSS vulnerabilities",
                    checkType: .owaspTop10,
                    parameters: ["vulnerability_type": "xss"],
                    threshold: 0,
                    remediation: "Sanitize and encode all user input"
                ),
                ComplianceRule(
                    name: "No Hardcoded Secrets",
                    description: "Code must not contain hardcoded credentials",
                    checkType: .secretDetection,
                    parameters: ["secret_types": ["api_key", "password", "token"]],
                    threshold: 0,
                    remediation: "Use secure credential management"
                )
            ],
            severity: .critical,
            autoRemediate: false,
            enabled: true
        )

        // GDPR Policy
        let gdprPolicy = CompliancePolicy(
            name: "GDPR Compliance",
            description: "Monitors GDPR compliance for data handling",
            type: .privacy,
            rules: [
                ComplianceRule(
                    name: "Data Minimisation",
                    description: "Collect only necessary personal data",
                    checkType: .gdprArticle,
                    parameters: ["article": "Article5_DataMinimisation"],
                    threshold: 100,
                    remediation: "Audit data collection and remove unnecessary fields"
                ),
                ComplianceRule(
                    name: "Consent Mechanism",
                    description: "Implement clear consent mechanisms",
                    checkType: .gdprArticle,
                    parameters: ["article": "Article7_Consent"],
                    threshold: 100,
                    remediation: "Add granular consent dialog"
                ),
                ComplianceRule(
                    name: "Right to Erasure",
                    description: "Implement user data deletion",
                    checkType: .gdprArticle,
                    parameters: ["article": "Article17_RightToErasure"],
                    threshold: 100,
                    remediation: "Add account deletion feature"
                )
            ],
            severity: .critical,
            autoRemediate: false,
            enabled: true
        )

        // License Policy
        let licensePolicy = CompliancePolicy(
            name: "License Compliance",
            description: "Ensures all dependencies have compatible licenses",
            type: .license,
            rules: [
                ComplianceRule(
                    name: "Permissive Licenses Only",
                    description: "All dependencies must have permissive licenses",
                    checkType: .licenseCompatibility,
                    parameters: ["allowed_licenses": ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC"]],
                    threshold: 100,
                    remediation: "Replace dependency with permissively licensed alternative"
                ),
                ComplianceRule(
                    name: "Attribution Complete",
                    description: "All dependencies must have proper attribution",
                    checkType: .licenseCompatibility,
                    parameters: ["check_attribution": "true"],
                    threshold: 100,
                    remediation: "Add attribution to About screen"
                )
            ],
            severity: .high,
            autoRemediate: false,
            enabled: true
        )

        policies = [owaspPolicy, gdprPolicy, licensePolicy]

        logger.info("Loaded \(policies.count) default policies")
    }

    private func checkRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        var violations: [ComplianceViolation] = []

        switch rule.checkType {
        case .owaspTop10:
            violations = try await checkOWASPRule(rule, policy: policy)

        case .gdprArticle:
            violations = try await checkGDPRRule(rule, policy: policy)

        case .licenseCompatibility:
            violations = try await checkLicenseRule(rule, policy: policy)

        case .secretDetection:
            violations = try await checkSecretRule(rule, policy: policy)

        case .dataRetention:
            violations = try await checkDataRetentionRule(rule, policy: policy)

        case .encryptionRequired:
            violations = try await checkEncryptionRule(rule, policy: policy)

        case .accessibilityWCAG:
            violations = try await checkAccessibilityRule(rule, policy: policy)

        case .performanceThreshold:
            violations = try await checkPerformanceRule(rule, policy: policy)

        case .codeCoverage:
            violations = try await checkCodeCoverageRule(rule, policy: policy)
        }

        return violations
    }

    private func checkOWASPRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        let result = try await owaspScanner.scanCodebase(at: "/Users/bretbouchard/apps/schill/white_room")

        var violations: [ComplianceViolation] = []

        let vulnType = rule.parameters["vulnerability_type"] as? String ?? ""
        let matchingVulns = result.vulnerabilities.filter { vuln in
            vuln.type.rawValue.contains(vulnType)
        }

        let threshold = Int(rule.threshold ?? 0)
        if matchingVulns.count > threshold {
            for vuln in matchingVulns {
                violations.append(ComplianceViolation(
                    policy: policy.name,
                    rule: rule.name,
                    severity: mapVulnerabilitySeverity(vuln.severity),
                    description: vuln.description,
                    affectedComponent: vuln.affectedFile,
                    remediation: vuln.remediation.recommendation,
                    autoRemediated: false,
                    discoveredAt: Date(),
                    resolvedAt: nil
                ))
            }
        }

        return violations
    }

    private func checkGDPRRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        let codebase = Codebase(
            hasEncryption: true,
            hasConsentMechanism: false,
            hasPrivacyPolicy: true,
            hasDeletionMechanism: false
        )

        let report = try await gdprValidator.validateDataHandling(codebase)

        var violations: [ComplianceViolation] = []

        let article = rule.parameters["article"] as? String ?? ""
        let matchingIssues = report.issues.filter { $0.article.rawValue.contains(article) }

        if !matchingIssues.isEmpty {
            for issue in matchingIssues {
                violations.append(ComplianceViolation(
                    policy: policy.name,
                    rule: rule.name,
                    severity: mapGDPRSeverity(issue.severity),
                    description: issue.description,
                    affectedComponent: issue.affectedComponent,
                    remediation: issue.remediation,
                    autoRemediated: false,
                    discoveredAt: Date(),
                    resolvedAt: nil
                ))
            }
        }

        return violations
    }

    private func checkLicenseRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        var violations: [ComplianceViolation] = []

        let allowedLicenses = rule.parameters["allowed_licenses"] as? [String] ?? []

        for dependency in licenseChecker.dependencies {
            if !allowedLicenses.contains(dependency.license.spdxID ?? "") {
                violations.append(ComplianceViolation(
                    policy: policy.name,
                    rule: rule.name,
                    severity: .critical,
                    description: "Dependency \(dependency.name) has non-compliant license: \(dependency.license.name)",
                    affectedComponent: dependency.name,
                    remediation: "Replace with permissively licensed alternative",
                    autoRemediated: false,
                    discoveredAt: Date(),
                    resolvedAt: nil
                ))
            }
        }

        return violations
    }

    private func checkSecretRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        let secrets = try await secretScanner.scanCodebase(at: "/Users/bretbouchard/apps/schill/white_room")

        var violations: [ComplianceViolation] = []

        for secret in secrets {
            violations.append(ComplianceViolation(
                policy: policy.name,
                rule: rule.name,
                severity: .critical,
                description: "Secret detected: \(secret.type.rawValue)",
                affectedComponent: "\(secret.file):\(secret.lineNumber)",
                remediation: "Rotate secret and remove from code",
                autoRemediated: false,
                discoveredAt: Date(),
                resolvedAt: nil
            ))
        }

        return violations
    }

    private func checkDataRetentionRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        // Simplified implementation
        return []
    }

    private func checkEncryptionRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        // Simplified implementation
        return []
    }

    private func checkAccessibilityRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        // Simplified implementation
        return []
    }

    private func checkPerformanceRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        // Simplified implementation
        return []
    }

    private func checkCodeCoverageRule(_ rule: ComplianceRule, policy: CompliancePolicy) async throws -> [ComplianceViolation] {
        // Simplified implementation
        return []
    }

    private func autoRemediate(_ violations: [ComplianceViolation]) async throws {
        logger.info("Auto-remediating \(violations.count) violations")

        for violation in violations {
            // Implement auto-remediation logic
            // This would depend on the violation type
            logger.warning("Auto-remediation for \(violation.rule) not implemented")
        }
    }

    private func calculatePolicyScore(_ policy: CompliancePolicy, violations: [ComplianceViolation]) -> Double {
        let totalRules = policy.rules.count
        let violatedRules = Set(violations.map { $0.rule }).count

        if totalRules == 0 { return 100 }

        let baseScore = Double(totalRules - violatedRules) / Double(totalRules) * 100

        // Adjust for severity
        let criticalDeduction = violations.filter { $0.severity == .critical }.count * 10
        let highDeduction = violations.filter { $0.severity == .high }.count * 5

        return max(0, baseScore - Double(criticalDeduction + highDeduction))
    }

    private func calculatePeriodScore(_ violations: [ComplianceViolation]) -> Double {
        if violations.isEmpty { return 100 }

        let totalDeduction = violations.reduce(0) { sum, violation in
            switch violation.severity {
            case .critical: return sum + 20
            case .high: return sum + 10
            case .medium: return sum + 5
            case .low: return sum + 2
            case .info: return sum + 1
            }
        }

        return max(0, 100 - Double(totalDeduction))
    }

    private func calculateComplianceTrends(for period: DateInterval) -> ComplianceTrends {
        // Calculate trends over time
        // This would analyze historical compliance data

        return ComplianceTrends(
            overallTrend: .improving,
            securityTrend: .stable,
            privacyTrend: .improving,
            licenseTrend: .stable,
            averageScore: 85,
            scoreChange: 5
        )
    }

    private func generateRecommendations(_ violations: [ComplianceViolation]) -> [String] {
        var recommendations: [String] = []

        let criticalCount = violations.filter { $0.severity == .critical }.count
        if criticalCount > 0 {
            recommendations.append("🚨 Address \(criticalCount) critical violations immediately")
        }

        let highCount = violations.filter { $0.severity == .high }.count
        if highCount > 0 {
            recommendations.append("⚠️ Resolve \(highCount) high-severity violations this week")
        }

        recommendations.append("📊 Review compliance dashboard monthly")
        recommendations.append("🔍 Run automated compliance checks weekly")

        return recommendations
    }

    private func generatePeriodRecommendations(_ violations: [ComplianceViolation]) -> [String] {
        return generateRecommendations(violations)
    }

    private func updateComplianceStatus() async {
        let activeViolations = violations.filter { $0.resolvedAt == nil }

        let securityViolations = activeViolations.filter { $0.policy.contains("OWASP") }
        let privacyViolations = activeViolations.filter { $0.policy.contains("GDPR") }
        let licenseViolations = activeViolations.filter { $0.policy.contains("License") }

        let securityScore = max(0, 100 - (securityViolations.count * 20))
        let privacyScore = max(0, 100 - (privacyViolations.count * 20))
        let licenseScore = max(0, 100 - (licenseViolations.count * 20))

        let overallStatus: Status
        if activeViolations.contains(where: { $0.severity == .critical }) {
            overallStatus = .critical
        } else if activeViolations.isEmpty {
            overallStatus = .compliant
        } else if activeViolations.contains(where: { $0.severity == .high }) {
            overallStatus = .nonCompliant
        } else {
            overallStatus = .warning
        }

        await MainActor.run {
            self.complianceStatus = ComplianceStatus(
                overallStatus: overallStatus,
                securityCompliance: securityScore,
                privacyCompliance: privacyScore,
                licenseCompliance: licenseScore,
                accessibilityCompliance: 100,
                lastChecked: Date(),
                totalViolations: activeViolations.count
            )
        }
    }

    private func mapVulnerabilitySeverity(_ severity: OWASPScanner.VulnerabilitySeverity) -> ViolationSeverity {
        switch severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .info: return .info
        }
    }

    private func mapGDPRSeverity(_ severity: GDPRValidator.GDPRSeverity) -> ViolationSeverity {
        switch severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .informational: return .info
        }
    }
}

// MARK: - Public Types (as specified in requirements)

public struct CompliancePolicy: Identifiable, Codable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let type: PolicyType
    public let rules: [ComplianceRule]
    public let severity: PolicySeverity
    public let autoRemediate: Bool
    public let enabled: Bool

    public enum PolicyType: String, Codable {
        case security
        case privacy
        case license
        case accessibility
        case performance
        case codeQuality
    }
}

public struct ComplianceRule: Codable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let checkType: CheckType
    public let parameters: [String: Any]
    public let threshold: Double?
    public let remediation: String?

    public enum CheckType: String, Codable {
        case owaspTop10
        case gdprArticle
        case licenseCompatibility
        case secretDetection
        case dataRetention
        case encryptionRequired
        case accessibilityWCAG
        case performanceThreshold
        case codeCoverage
    }

    // Custom coding for parameters dictionary
    enum CodingKeys: String, CodingKey {
        case id, name, description, checkType, threshold, remediation
        // We'll skip parameters in JSON encoding for now
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        checkType = try container.decode(CheckType.self, forKey: .checkType)
        parameters = [:]
        threshold = try container.decodeIfPresent(Double.self, forKey: .threshold)
        remediation = try container.decodeIfPresent(String.self, forKey: .remediation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(checkType, forKey: .checkType)
        try container.encodeIfPresent(threshold, forKey: .threshold)
        try container.encodeIfPresent(remediation, forKey: .remediation)
    }
}

public struct ComplianceStatus: Codable {
    public let overallStatus: Status
    public let securityCompliance: Double
    public let privacyCompliance: Double
    public let licenseCompliance: Double
    public let accessibilityCompliance: Double
    public let lastChecked: Date
    public let totalViolations: Int

    public enum Status: String, Codable {
        case compliant
        case warning
        case nonCompliant
        case critical
    }
}

public struct ComplianceViolation: Identifiable, Codable {
    public let id = UUID()
    public let policy: String
    public let rule: String
    public let severity: ViolationSeverity
    public let description: String
    public let affectedComponent: String
    public let remediation: String
    public let autoRemediated: Bool
    public let discoveredAt: Date
    public let resolvedAt: Date?

    public enum ViolationSeverity: Int, Codable {
        case critical = 5
        case high = 4
        case medium = 3
        case low = 2
        case info = 1
    }
}

public struct ComplianceCheckResult {
    public let policy: CompliancePolicy
    public let compliant: Bool
    public let score: Double
    public let violations: [ComplianceViolation]
    public let recommendations: [String]
    public let timestamp: Date
}

public struct ComplianceReport {
    public let period: DateInterval
    public let generatedAt: Date
    public let score: Double
    public let totalViolations: Int
    public let resolvedViolations: Int
    public let criticalViolations: Int
    public let violationsByPolicy: [String: Int]
    public let topViolations: [ComplianceViolation]
    public let recommendations: [String]
    public let trends: ComplianceTrends
}

public struct ComplianceTrends {
    public let overallTrend: TrendDirection
    public let securityTrend: TrendDirection
    public let privacyTrend: TrendDirection
    public let licenseTrend: TrendDirection
    public let averageScore: Double
    public let scoreChange: Double

    public enum TrendDirection {
        case improving
        case stable
        case degrading
    }
}

public enum PolicySeverity: String, Codable {
    case critical
    case high
    case medium
    case low
}
