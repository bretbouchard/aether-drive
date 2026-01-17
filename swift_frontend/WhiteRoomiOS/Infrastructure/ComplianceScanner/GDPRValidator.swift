//
//  GDPRValidator.swift
//  WhiteRoomiOS
//
//  Created by White Room Team on 1/16/25.
//

import Foundation
import Combine
import CoreData
import os.log

/// GDPR compliance validator for data handling and privacy
/// Validates compliance against GDPR articles and data protection requirements
public class GDPRValidator: ObservableObject {

    // MARK: - Published Properties

    @Published public var complianceIssues: [GDPRIssue] = []
    @Published public var complianceScore: GDPRComplianceScore = GDPRComplianceScore()
    @Published public var isValidating: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.whiteroom.ios", category: "GDPRValidator")
    private var cancellables = Set<AnyCancellable>()
    private let validationQueue = DispatchQueue(label: "com.whiteroom.gdpr.validation", qos: .userInitiated)

    // MARK: - GDPR Article Requirements

    private static let gdprArticles: [GDPROrArticle: [String]] = [
        .Article5_DataMinimisation: [
            "Data collected is adequate, relevant and limited to what is necessary",
            "No excessive data collection beyond stated purpose",
            "Data retention periods are defined and enforced"
        ],
        .Article6_LawfulBasis: [
            "Lawful basis for processing is documented",
            "Consent or legitimate interest is clearly established",
            "Purpose of data processing is explicitly stated"
        ],
        .Article7_Consent: [
            "Consent is freely given, specific, informed and unambiguous",
            "Consent can be withdrawn as easily as it was given",
            "Clear affirmative action required for consent",
            "Granular consent options available"
        ],
        .Article9_SpecialCategories: [
            "Explicit consent for processing special category data",
            "Additional safeguards for sensitive data",
            "Data Protection Impact Assessment (DPIA) conducted"
        ],
        .Article12_Transparency: [
            "Privacy policy is clear and transparent",
            "Data processing activities are disclosed",
            "Purpose of data collection is explained"
        ],
        .Article15_RightOfAccess: [
            "Users can request copy of personal data",
            "Data access request mechanism exists",
            "Response within 30 days guaranteed"
        ],
        .Article16_RightToRectification: [
            "Users can correct inaccurate data",
            "Data correction mechanism implemented",
            "Correction processed within 30 days"
        ],
        .Article17_RightToErasure: [
            "Right to deletion implemented",
            "Data deletion mechanism available",
            "Deletion processed within 30 days",
            "Exceptions clearly documented"
        ],
        .Article18_RightToRestrict: [
            "Users can restrict processing",
            "Restriction mechanism available",
            "Data retained during restriction"
        ],
        .Article20_DataPortability: [
            "Data export functionality available",
            "Machine-readable format provided",
            "Direct data transfer supported"
        ],
        .Article25_DataProtectionByDesign: [
            "Privacy by design principles applied",
            "Default privacy settings implemented",
            "Data protection integrated into development"
        ],
        .Article32_DataSecurity: [
            "Technical security measures implemented",
            "Encryption at rest and in transit",
            "Access controls and authentication",
            "Regular security testing"
        ],
        .Article33_BreachNotification: [
            "Breach detection mechanism in place",
            "Notification to authorities within 72 hours",
            "Breach notification procedures documented"
        ]
    ]

    // MARK: - Initialization

    public init() {
        logger.info("GDPR Validator initialized")
    }

    // MARK: - Public Validation Methods

    /// Validate data handling practices against GDPR requirements
    public func validateDataHandling(_ codebase: Codebase) async throws -> GDPRComplianceReport {
        logger.info("Starting GDPR compliance validation")

        await MainActor.run {
            self.isValidating = true
        }

        let startTime = Date()

        do {
            var issues: [GDPRIssue] = []

            // Check each GDPR article
            for (article, requirements) in Self.gdprArticles {
                let articleIssues = try await validateArticle(article, requirements: requirements, codebase: codebase)
                issues.append(contentsOf: articleIssues)
            }

            // Validate consent mechanisms
            let consentIssues = try await checkConsentMechanisms(AppConfiguration())
            issues.append(contentsOf: consentIssues.map { consentToGDPRIssue($0) })

            // Validate data storage
            let storageIssues = try await validateDataStorage(DataStorage.mock)
            issues.append(contentsOf: storageIssues.map { storageToGDPRIssue($0) })

            let duration = Date().timeIntervalSince(startTime)
            let score = calculateGDPRScore(issues)

            let report = GDPRComplianceReport(
                timestamp: Date(),
                overallCompliance: determineComplianceLevel(score),
                score: score,
                issues: issues,
                recommendations: generateRecommendations(issues),
                articleViolations: groupByArticle(issues)
            )

            await MainActor.run {
                self.complianceIssues = issues
                self.complianceScore = GDPRComplianceScore(
                    overall: score,
                    dataMinimisation: calculateArticleScore(.Article5_DataMinimisation, issues),
                    lawfulBasis: calculateArticleScore(.Article6_LawfulBasis, issues),
                    consent: calculateArticleScore(.Article7_Consent, issues),
                    dataRights: calculateDataRightsScore(issues),
                    security: calculateArticleScore(.Article32_DataSecurity, issues)
                )
                self.isValidating = false
            }

            logger.info("GDPR validation complete: score \(score)/100")
            return report

        } catch {
            await MainActor.run {
                self.isValidating = false
            }
            logger.error("GDPR validation failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check consent mechanisms for GDPR compliance
    public func checkConsentMechanisms(_ app: AppConfiguration) async throws -> [ConsentIssue] {
        logger.info("Checking consent mechanisms")

        var issues: [ConsentIssue] = []

        // Check if consent dialog exists
        if !hasConsentDialog(app) {
            issues.append(ConsentIssue(
                type: .dataCollection,
                issue: "No consent dialog found for data collection",
                recommendation: "Implement clear, granular consent dialog before collecting any personal data"
            ))
        }

        // Check if consent can be withdrawn
        if !hasConsentWithdrawal(app) {
            issues.append(ConsentIssue(
                type: .dataCollection,
                issue: "Users cannot easily withdraw consent",
                recommendation: "Add consent withdrawal mechanism in settings, as easy as giving consent"
            ))
        }

        // Check for granular consent options
        if !hasGranularConsent(app) {
            issues.append(ConsentIssue(
                type: .dataCollection,
                issue: "Consent is not granular - all-or-nothing approach",
                recommendation: "Provide granular consent options for different data types (analytics, marketing, etc.)"
            ))
        }

        // Check analytics consent
        if !hasAnalyticsConsent(app) {
            issues.append(ConsentIssue(
                type: .analytics,
                issue: "Analytics tracking without explicit consent",
                recommendation: "Implement opt-in consent for analytics tracking"
            ))
        }

        // Check marketing consent
        if !hasMarketingConsent(app) {
            issues.append(ConsentIssue(
                type: .marketing,
                issue: "Marketing communications without consent",
                recommendation: "Implement explicit opt-in for marketing communications"
            ))
        }

        logger.info("Found \(issues.count) consent issues")
        return issues
    }

    /// Validate data storage practices
    public func validateDataStorage(_ storage: DataStorage) async throws -> [StorageIssue] {
        logger.info("Validating data storage practices")

        var issues: [StorageIssue] = []

        // Check encryption at rest
        if storage.encryptionAtRest == false {
            issues.append(StorageIssue(
                data: .personalData,
                location: "Local database",
                encryptionStatus: .notEncrypted,
                retentionPeriod: nil,
                issue: "Personal data stored without encryption at rest"
            ))
        }

        // Check encryption in transit
        if storage.encryptionInTransit == false {
            issues.append(StorageIssue(
                data: .personalData,
                location: "Network communication",
                encryptionStatus: .notEncrypted,
                retentionPeriod: nil,
                issue: "Data transmitted without encryption (HTTPS/TLS required)"
            ))
        }

        // Check data retention
        if storage.retentionPeriod == nil {
            issues.append(StorageIssue(
                data: .personalData,
                location: "All storage",
                encryptionStatus: .encrypted,
                retentionPeriod: nil,
                issue: "No data retention policy defined - data kept indefinitely"
            ))
        }

        // Check for special category data
        if storage.containsSpecialCategoryData && !storage.hasExplicitConsent {
            issues.append(StorageIssue(
                data: .healthData,
                location: "Special category storage",
                encryptionStatus: .encrypted,
                retentionPeriod: storage.retentionPeriod,
                issue: "Special category data without explicit consent"
            ))
        }

        logger.info("Found \(issues.count) storage issues")
        return issues
    }

    /// Check data retention policies
    public func checkDataRetention(_ policies: [RetentionPolicy]) async throws -> [RetentionPolicyIssue] {
        logger.info("Checking \(policies.count) data retention policies")

        var issues: [RetentionPolicyIssue] = []

        for policy in policies {
            // Check if policy has defined retention period
            if policy.retentionPeriod == nil {
                issues.append(RetentionPolicyIssue(
                    policy: policy.name,
                    issue: "No retention period defined",
                    recommendation: "Define specific retention period based on purpose and legal requirements"
                ))
            }

            // Check if retention period is excessive
            if let period = policy.retentionPeriod, period > 365 * 2 { // More than 2 years
                issues.append(RetentionPolicyIssue(
                    policy: policy.name,
                    issue: "Retention period may be excessive (\(period) days)",
                    recommendation: "Review and justify retention period, consider data minimization"
                ))
            }

            // Check if deletion mechanism exists
            if !policy.hasDeletionMechanism {
                issues.append(RetentionPolicyIssue(
                    policy: policy.name,
                    issue: "No automatic deletion mechanism",
                    recommendation: "Implement automatic deletion after retention period expires"
                ))
            }

            // Check if user is informed
            if !policy.userInformed {
                issues.append(RetentionPolicyIssue(
                    policy: policy.name,
                    issue: "User not informed about retention period",
                    recommendation: "Clearly state retention period in privacy policy"
                ))
            }
        }

        logger.info("Found \(issues.count) retention policy issues")
        return issues
    }

    /// Validate right to erasure (GDPR Article 17)
    public func validateRightToDeletion(_ user: User) async throws -> DeletionCompliance {
        logger.info("Validating right to deletion for user: \(user.id)")

        var deletableData: [DataType] = []
        var retainedData: [DataType] = []
        var retentionReasons: [String] = []

        // Check profile data
        if canDeleteProfileData(user) {
            deletableData.append(.personalData)
        } else {
            retainedData.append(.personalData)
            retentionReasons.append("Profile data required for account functionality")
        }

        // Check analytics data
        if canDeleteAnalyticsData(user) {
            deletableData.append(.cookies)
        } else {
            retainedData.append(.cookies)
            retentionReasons.append("Analytics data anonymized after 30 days")
        }

        // Check usage logs
        if canDeleteUsageLogs(user) {
            deletableData.append(.deviceID)
        } else {
            retainedData.append(.deviceID)
            retentionReasons.append("Usage logs retained for security audit (90 days)")
        }

        let canDelete = retainedData.isEmpty
        let deletionProcess = generateDeletionProcess(canDelete)

        return DeletionCompliance(
            canDelete: canDelete,
            deletableData: deletableData,
            retainedData: retainedData,
            retentionReasons: retentionReasons,
            deletionProcess: deletionProcess
        )
    }

    // MARK: - Private Helper Methods

    private func validateArticle(_ article: GDPROrArticle, requirements: [String], codebase: Codebase) async throws -> [GDPRIssue] {
        var issues: [GDPRIssue] = []

        for requirement in requirements {
            let isCompliant = try await checkRequirement(requirement, in: codebase)

            if !isCompliant {
                let issue = GDPRIssue(
                    article: article,
                    title: "Non-compliance: \(article.rawValue)",
                    description: requirement,
                    severity: determineSeverity(for: article),
                    affectedComponent: determineComponent(for: article),
                    remediation: generateRemediation(for: article),
                    references: getReferences(for: article)
                )
                issues.append(issue)
            }
        }

        return issues
    }

    private func checkRequirement(_ requirement: String, in codebase: Codebase) async throws -> Bool {
        // Simulated compliance check
        // In production, this would analyze code, configurations, and documentation

        if requirement.contains("encryption") {
            return codebase.hasEncryption
        } else if requirement.contains("consent") {
            return codebase.hasConsentMechanism
        } else if requirement.contains("policy") {
            return codebase.hasPrivacyPolicy
        } else if requirement.contains("deletion") {
            return codebase.hasDeletionMechanism
        }

        return false // Default to non-compliant
    }

    private func calculateGDPRScore(_ issues: [GDPRIssue]) -> Int {
        let totalArticles = GDPROrArticle.allCases.count
        let compliantArticles = totalArticles - Set(issues.map { $0.article }).count

        let baseScore = (compliantArticles * 100) / totalArticles

        // Deduct points for severity
        let criticalDeduction = issues.filter { $0.severity == .critical }.count * 10
        let highDeduction = issues.filter { $0.severity == .high }.count * 5
        let mediumDeduction = issues.filter { $0.severity == .medium }.count * 2

        return max(0, baseScore - criticalDeduction - highDeduction - mediumDeduction)
    }

    private func calculateArticleScore(_ article: GDPROrArticle, _ issues: [GDPRIssue]) -> Int {
        let articleIssues = issues.filter { $0.article == article }
        return articleIssues.isEmpty ? 100 : max(0, 100 - (articleIssues.count * 20))
    }

    private func calculateDataRightsScore(_ issues: [GDPRIssue]) -> Int {
        let dataRightsArticles: [GDPROrArticle] = [
            .Article15_RightOfAccess,
            .Article16_RightToRectification,
            .Article17_RightToErasure,
            .Article18_RightToRestrict,
            .Article20_DataPortability
        ]

        let compliantCount = dataRightsArticles.filter { article in
            !issues.contains { $0.article == article }
        }.count

        return (compliantCount * 100) / dataRightsArticles.count
    }

    private func determineComplianceLevel(_ score: Int) -> ComplianceLevel {
        switch score {
        case 90...100: return .fullyCompliant
        case 75..<90: return .substantiallyCompliant
        case 60..<75: return .partiallyCompliant
        case 40..<60: return .nonCompliant
        default: return .criticallyNonCompliant
        }
    }

    private func determineSeverity(for article: GDPROrArticle) -> GDPRSeverity {
        switch article {
        case .Article17_RightToErasure, .Article32_DataSecurity, .Article9_SpecialCategories:
            return .critical
        case .Article6_LawfulBasis, .Article7_Consent, .Article33_BreachNotification:
            return .high
        case .Article5_DataMinimisation, .Article15_RightOfAccess, .Article25_DataProtectionByDesign:
            return .medium
        default:
            return .low
        }
    }

    private func determineComponent(for article: GDPROrArticle) -> String {
        switch article {
        case .Article32_DataSecurity: return "Data storage and encryption"
        case .Article7_Consent: return "Consent management system"
        case .Article17_RightToErasure: return "User data deletion"
        default: return "Privacy implementation"
        }
    }

    private func generateRemediation(for article: GDPROrArticle) -> String {
        switch article {
        case .Article7_Consent:
            return "Implement clear, granular consent dialog with easy withdrawal mechanism"
        case .Article17_RightToErasure:
            return "Add 'Delete Account' feature in settings with automated data deletion"
        case .Article32_DataSecurity:
            return "Enable encryption at rest (Data Protection) and in transit (certificate pinning)"
        case .Article5_DataMinimisation:
            return "Audit data collection and remove unnecessary data fields"
        default:
            return "Review GDPR requirements and implement compliant solution"
        }
    }

    private func getReferences(for article: GDPROrArticle) -> [String] {
        return [
            "https://gdpr-info.eu/\(article.rawValue.split(separator: " ").first ?? "")",
            "https://ico.org.uk/for-organisations/guide-to-data-protection/guide-to-the-general-data-protection-regulation-gdpr/"
        ]
    }

    private func generateRecommendations(_ issues: [GDPRIssue]) -> [GDPRRecommendation] {
        var recommendations: [GDPRRecommendation] = []

        let criticalIssues = issues.filter { $0.severity == .critical }
        if !criticalIssues.isEmpty {
            recommendations.append(GDPRRecommendation(
                priority: .immediate,
                title: "Address critical GDPR violations",
                description: "\(criticalIssues.count) critical issues require immediate attention"
            ))
        }

        recommendations.append(GDPRRecommendation(
            priority: .high,
            title: "Implement privacy by design",
            description: "Integrate data protection into development from the start"
        ))

        recommendations.append(GDPRRecommendation(
            priority: .medium,
            title: "Conduct DPIA",
            description: "Data Protection Impact Assessment for high-risk processing"
        ))

        recommendations.append(GDPRRecommendation(
            priority: .low,
            title: "Review privacy policy",
            description: "Ensure policy is clear, transparent, and comprehensive"
        ))

        return recommendations
    }

    private func groupByArticle(_ issues: [GDPRIssue]) -> [ArticleViolation] {
        let grouped = Dictionary(grouping: issues) { $0.article }

        return grouped.map { article, issues in
            ArticleViolation(
                article: article,
                violationCount: issues.count,
                severity: issues.map { $0.severity }.max() ?? .informational,
                issues: issues
            )
        }.sorted { $0.article.rawValue < $1.article.rawValue }
    }

    private func consentToGDPRIssue(_ consent: ConsentIssue) -> GDPRIssue {
        return GDPRIssue(
            article: .Article7_Consent,
            title: "Consent mechanism issue",
            description: consent.issue,
            severity: .high,
            affectedComponent: "Consent management",
            remediation: consent.recommendation,
            references: []
        )
    }

    private func storageToGDPRIssue(_ storage: StorageIssue) -> GDPRIssue {
        return GDPRIssue(
            article: .Article32_DataSecurity,
            title: "Data storage security issue",
            description: storage.issue,
            severity: storage.encryptionStatus == .notEncrypted ? .critical : .high,
            affectedComponent: storage.location,
            remediation: "Implement encryption: \(storage.encryptionStatus == .notEncrypted ? 'none' : 'partial')",
            references: []
        )
    }

    private func hasConsentDialog(_ app: AppConfiguration) -> Bool {
        // Check if app implements consent dialog
        return true // Simulated
    }

    private func hasConsentWithdrawal(_ app: AppConfiguration) -> Bool {
        return false // Simulated - issue detected
    }

    private func hasGranularConsent(_ app: AppConfiguration) -> Bool {
        return false // Simulated - issue detected
    }

    private func hasAnalyticsConsent(_ app: AppConfiguration) -> Bool {
        return true // Simulated
    }

    private func hasMarketingConsent(_ app: AppConfiguration) -> Bool {
        return false // Simulated - issue detected
    }

    private func canDeleteProfileData(_ user: User) -> Bool {
        return true
    }

    private func canDeleteAnalyticsData(_ user: User) -> Bool {
        return true
    }

    private func canDeleteUsageLogs(_ user: User) -> Bool {
        return false
    }

    private func generateDeletionProcess(_ canDelete: Bool) -> [DeletionStep] {
        var steps: [DeletionStep] = []

        steps.append(DeletionStep(
            step: 1,
            title: "Verify user identity",
            description: "Confirm user authentication before processing deletion"
        ))

        steps.append(DeletionStep(
            step: 2,
            title: "Identify data to delete",
            description: "Map all user data across systems"
        ))

        steps.append(DeletionStep(
            step: 3,
            title: "Execute deletion",
            description: "Securely delete user data from all systems"
        ))

        steps.append(DeletionStep(
            step: 4,
            title: "Confirm deletion",
            description: "Verify all data has been deleted and generate confirmation"
        ))

        return steps
    }
}

// MARK: - Supporting Types

public struct Codebase {
    let hasEncryption: Bool
    let hasConsentMechanism: Bool
    let hasPrivacyPolicy: Bool
    let hasDeletionMechanism: Bool
}

public struct AppConfiguration {
    // Configuration properties
}

public struct DataStorage {
    let encryptionAtRest: Bool
    let encryptionInTransit: Bool
    let retentionPeriod: Int?
    let containsSpecialCategoryData: Bool
    let hasExplicitConsent: Bool

    static let mock = DataStorage(
        encryptionAtRest: true,
        encryptionInTransit: false,
        retentionPeriod: nil,
        containsSpecialCategoryData: false,
        hasExplicitConsent: true
    )
}

public struct RetentionPolicy {
    let name: String
    let retentionPeriod: Int?
    let hasDeletionMechanism: Bool
    let userInformed: Bool
}

public struct User {
    let id: String
    let email: String
    let data: [DataType]
}

// MARK: - Public Types (as specified in requirements)

public struct GDPRComplianceReport {
    let timestamp: Date
    let overallCompliance: ComplianceLevel
    let score: Int
    let issues: [GDPRIssue]
    let recommendations: [GDPRRecommendation]
    let articleViolations: [ArticleViolation]

    public enum ComplianceLevel {
        case fullyCompliant
        case substantiallyCompliant
        case partiallyCompliant
        case nonCompliant
        case criticallyNonCompliant
    }
}

public struct GDPRComplianceScore {
    let overall: Int = 0
    let dataMinimisation: Int = 0
    let lawfulBasis: Int = 0
    let consent: Int = 0
    let dataRights: Int = 0
    let security: Int = 0
}

public struct GDPRIssue: Identifiable, Codable {
    public let id = UUID()
    public let article: GDPROrArticle
    public let title: String
    public let description: String
    public let severity: GDPRSeverity
    public let affectedComponent: String
    public let remediation: String
    public let references: [String]

    public enum GDPROrArticle: String, Codable, CaseIterable {
        case Article5_DataMinimisation = "Article 5 - Data Minimisation"
        case Article6_LawfulBasis = "Article 6 - Lawful Basis for Processing"
        case Article7_Consent = "Article 7 - Conditions for Consent"
        case Article9_SpecialCategories = "Article 9 - Processing of Special Categories"
        case Article12_Transparency = "Article 12 - Transparent Information"
        case Article15_RightOfAccess = "Article 15 - Right of Access by Data Subject"
        case Article16_RightToRectification = "Article 16 - Right to Rectification"
        case Article17_RightToErasure = "Article 17 - Right to Erasure"
        case Article18_RightToRestrict = "Article 18 - Right to Restrict Processing"
        case Article19_RightToBeNotified = "Article 19 - Right to be Notified"
        case Article20_DataPortability = "Article 20 - Right to Data Portability"
        case Article21_RightToObject = "Article 21 - Right to Object"
        case Article22_AutomatedDecisionMaking = "Article 22 - Automated Decision Making"
        case Article25_DataProtectionByDesign = "Article 25 - Data Protection by Design and by Default"
        case Article32_DataSecurity = "Article 32 - Security of Processing"
        case Article33_BreachNotification = "Article 33 - Notification of Personal Data Breach"
    }

    public enum GDPRSeverity: String, Codable {
        case critical
        case high
        case medium
        case low
        case informational
    }
}

public struct GDPRRecommendation {
    let priority: RecommendationPriority
    let title: String
    let description: String

    public enum RecommendationPriority {
        case immediate
        case high
        case medium
        case low
    }
}

public struct ArticleViolation {
    let article: GDPROrArticle
    let violationCount: Int
    let severity: GDPRSeverity
    let issues: [GDPRIssue]
}

public struct ConsentIssue {
    let type: ConsentType
    let issue: String
    let recommendation: String

    public enum ConsentType {
        case dataCollection
        case analytics
        case marketing
        case thirdPartySharing
        case cookies
        case locationTracking
        case biometricData
        case healthData
    }
}

public struct StorageIssue {
    let data: DataType
    let location: String
    let encryptionStatus: EncryptionStatus
    let retentionPeriod: RetentionPeriod?
    let issue: String

    public enum DataType {
        case personalData
        case sensitivePersonalData
        case healthData
        case biometricData
        case locationData
        case cookies
        case ipAddress
        case deviceID
    }

    public enum EncryptionStatus {
        case encrypted
        case encryptedAtRest
        case encryptedInTransit
        case notEncrypted
        case unknown
    }

    public typealias RetentionPeriod = Int
}

public struct RetentionPolicyIssue {
    let policy: String
    let issue: String
    let recommendation: String
}

public struct DeletionCompliance {
    let canDelete: Bool
    let deletableData: [DataType]
    let retainedData: [DataType]
    let retentionReasons: [String]
    let deletionProcess: [DeletionStep]
}

public struct DeletionStep {
    let step: Int
    let title: String
    let description: String
}
