//
//  LicenseChecker.swift
//  WhiteRoomiOS
//
//  Created by White Room Team on 1/16/25.
//

import Foundation
import Combine
import os.log

/// License compliance checker for SPDX license identification and compatibility
/// Validates license compatibility and generates attribution requirements
public class LicenseChecker: ObservableObject {

    // MARK: - Published Properties

    @Published public var dependencies: [LicenseDependency] = []
    @Published public var complianceIssues: [LicenseComplianceIssue] = []
    @Published public var isScanning: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.whiteroom.ios", category: "LicenseChecker")
    private var cancellables = Set<AnyCancellable>()
    private let scanQueue = DispatchQueue(label: "com.whiteroom.license.scan", qos: .userInitiated)

    // MARK: - SPDX License Database

    private static let spdxLicenses: [String: LicenseInfo] = [
        "MIT": LicenseInfo(
            id: "MIT",
            name: "MIT License",
            spdxID: "MIT",
            url: "https://opensource.org/licenses/MIT",
            description: "Permissive license that allows reuse within proprietary software",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice"],
            limitations: ["Trademark use", "Liability"],
            licenseType: .permissive,
            requiresAttribution: true,
            copyleft: false,
            patentClause: false,
            liabilityClause: true
        ),
        "Apache-2.0": LicenseInfo(
            id: "Apache-2.0",
            name: "Apache License 2.0",
            spdxID: "Apache-2.0",
            url: "https://opensource.org/licenses/Apache-2.0",
            description: "Permissive license with patent grant and express patent termination",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use", "Patent grant"],
            conditions: ["License and copyright notice", "State changes"],
            limitations: ["Trademark use", "Liability", "Warranty"],
            licenseType: .permissive,
            requiresAttribution: true,
            copyleft: false,
            patentClause: true,
            liabilityClause: true
        ),
        "BSD-2-Clause": LicenseInfo(
            id: "BSD-2-Clause",
            name: "BSD 2-Clause \"Simplified\" License",
            spdxID: "BSD-2-Clause",
            url: "https://opensource.org/licenses/BSD-2-Clause",
            description: "Permissive license similar to MIT",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice"],
            limitations: ["Trademark use", "Liability"],
            licenseType: .permissive,
            requiresAttribution: true,
            copyleft: false,
            patentClause: false,
            liabilityClause: true
        ),
        "BSD-3-Clause": LicenseInfo(
            id: "BSD-3-Clause",
            name: "BSD 3-Clause \"New\" or \"Revised\" License",
            spdxID: "BSD-3-Clause",
            url: "https://opensource.org/licenses/BSD-3-Clause",
            description: "Permissive license with additional no-endorsement clause",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice", "State changes"],
            limitations: ["Trademark use", "Liability", "Endorsement use"],
            licenseType: .permissive,
            requiresAttribution: true,
            copyleft: false,
            patentClause: false,
            liabilityClause: true
        ),
        "ISC": LicenseInfo(
            id: "ISC",
            name: "ISC License",
            spdxID: "ISC",
            url: "https://opensource.org/licenses/ISC",
            description: "Permissive license similar to MIT but simpler language",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice"],
            limitations: ["Liability", "Warranty"],
            licenseType: .permissive,
            requiresAttribution: true,
            copyleft: false,
            patentClause: false,
            liabilityClause: true
        ),
        "LGPL-2.1": LicenseInfo(
            id: "LGPL-2.1",
            name: "GNU Lesser General Public License v2.1",
            spdxID: "LGPL-2.1",
            url: "https://opensource.org/licenses/LGPL-2.1",
            description: "Weak copyleft license for libraries",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source"],
            limitations: ["Liability", "Warranty"],
            licenseType: .weakCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: false,
            liabilityClause: true
        ),
        "LGPL-3.0": LicenseInfo(
            id: "LGPL-3.0",
            name: "GNU Lesser General Public License v3.0",
            spdxID: "LGPL-3.0",
            url: "https://opensource.org/licenses/LGPL-3.0",
            description: "Weak copyleft license with patent termination",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source", "State changes"],
            limitations: ["Liability", "Warranty", "Patent rights"],
            licenseType: .weakCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: true,
            liabilityClause: true
        ),
        "GPL-2.0": LicenseInfo(
            id: "GPL-2.0",
            name: "GNU General Public License v2.0",
            spdxID: "GPL-2.0",
            url: "https://opensource.org/licenses/GPL-2.0",
            description: "Strong copyleft license requiring derivative works to be GPL",
            permissions: ["Commercial use", "Modification", "Distribution"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source", "Same license"],
            limitations: ["Liability", "Warranty"],
            licenseType: .strongCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: false,
            liabilityClause: true
        ),
        "GPL-3.0": LicenseInfo(
            id: "GPL-3.0",
            name: "GNU General Public License v3.0",
            spdxID: "GPL-3.0",
            url: "https://opensource.org/licenses/GPL-3.0",
            description: "Strong copyleft license with patent termination",
            permissions: ["Commercial use", "Modification", "Distribution"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source", "Same license", "State changes"],
            limitations: ["Liability", "Warranty", "Patent rights"],
            licenseType: .strongCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: true,
            liabilityClause: true
        ),
        "AGPL-3.0": LicenseInfo(
            id: "AGPL-3.0",
            name: "GNU Affero General Public License v3.0",
            spdxID: "AGPL-3.0",
            url: "https://opensource.org/licenses/AGPL-3.0",
            description: "Strong copyleft license extending to network use",
            permissions: ["Commercial use", "Modification", "Distribution"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source", "Same license", "State changes", "Network use source"],
            limitations: ["Liability", "Warranty", "Patent rights"],
            licenseType: .strongCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: true,
            liabilityClause: true
        ),
        "MPL-2.0": LicenseInfo(
            id: "MPL-2.0",
            name: "Mozilla Public License 2.0",
            spdxID: "MPL-2.0",
            url: "https://opensource.org/licenses/MPL-2.0",
            description: "Weak copyleft license that is file-based",
            permissions: ["Commercial use", "Modification", "Distribution", "Private use"],
            conditions: ["License and copyright notice", "Provide copy of license", "Disclose source"],
            limitations: ["Liability", "Warranty", "Trademark use"],
            licenseType: .weakCopyleft,
            requiresAttribution: true,
            copyleft: true,
            patentClause: true,
            liabilityClause: true
        )
    ]

    // MARK: - License Policy

    private static let allowedLicenses: Set<String> = [
        "MIT",
        "Apache-2.0",
        "BSD-2-Clause",
        "BSD-3-Clause",
        "ISC",
        "LGPL-2.1",
        "LGPL-3.0",
        "MPL-2.0"
    ]

    private static let requiresSourceCodeLicenses: Set<String> = [
        "LGPL-2.1",
        "LGPL-3.0",
        "GPL-2.0",
        "GPL-3.0",
        "AGPL-3.0",
        "MPL-2.0"
    ]

    // MARK: - Initialization

    public init() {
        logger.info("License Checker initialized")
    }

    // MARK: - Public Scanning Methods

    /// Scan package files to identify all dependencies and their licenses
    public func scanDependencies(_ packageFiles: [PackageFile]) async throws -> [LicenseDependency] {
        logger.info("Scanning \(packageFiles.count) package files for dependencies")

        await MainActor.run {
            self.isScanning = true
        }

        var allDependencies: [LicenseDependency] = []

        for packageFile in packageFiles {
            let deps = try await parsePackageFile(packageFile)
            allDependencies.append(contentsOf: deps)
        }

        // Enrich with license information
        let enrichedDependencies = try await enrichWithLicenseInfo(allDependencies)

        // Check compliance
        let issues = checkCompliance(enrichedDependencies)

        await MainActor.run {
            self.dependencies = enrichedDependencies
            self.complianceIssues = issues
            self.isScanning = false
        }

        logger.info("Found \(enrichedDependencies.count) dependencies, \(issues.count) compliance issues")
        return enrichedDependencies
    }

    /// Validate license compatibility between dependencies
    public func validateLicenseCompatibility(_ licenses: [License]) async throws -> LicenseCompatibilityReport {
        logger.info("Validating compatibility of \(licenses.count) licenses")

        var conflicts: [LicenseConflict] = []
        var compatibleLicenses: [License] = []
        var incompatibleLicenses: [License] = []

        // Check pairwise compatibility
        for i in 0..<licenses.count {
            for j in (i + 1)..<licenses.count {
                let license1 = licenses[i]
                let license2 = licenses[j]

                if let conflict = checkCompatibility(license1, license2) {
                    conflicts.append(conflict)
                    incompatibleLicenses.append(license2)
                } else {
                    if !compatibleLicenses.contains(where: { $0.id == license1.id }) {
                        compatibleLicenses.append(license1)
                    }
                    if !compatibleLicenses.contains(where: { $0.id == license2.id }) {
                        compatibleLicenses.append(license2)
                    }
                }
            }
        }

        let recommendations = generateCompatibilityRecommendations(conflicts)

        let report = LicenseCompatibilityReport(
            compatible: conflicts.isEmpty,
            conflicts: conflicts,
            recommendations: recommendations,
            compatibleLicenses: compatibleLicenses,
            incompatibleLicenses: incompatibleLicenses
        )

        logger.info("Compatibility check complete: \(conflicts.count) conflicts found")
        return report
    }

    /// Check attribution requirements for dependencies
    public func checkAttributionRequirements(_ dependencies: [LicenseDependency]) async throws -> [AttributionRequirement] {
        logger.info("Checking attribution requirements for \(dependencies.count) dependencies")

        var requirements: [AttributionRequirement] = []

        for dependency in dependencies {
            if dependency.requiresAttribution {
                let text = generateAttributionText(for: dependency)
                let location = determineAttributionLocation(for: dependency)
                let format = determineAttributionFormat(for: dependency)

                requirements.append(AttributionRequirement(
                    dependency: dependency,
                    text: text,
                    location: location,
                    format: format
                ))
            }
        }

        logger.info("Generated \(requirements.count) attribution requirements")
        return requirements
    }

    /// Generate attribution file content
    public func generateAttributionFile(_ dependencies: [LicenseDependency]) throws -> String {
        logger.info("Generating attribution file for \(dependencies.count) dependencies")

        var content = """
        # Third-Party Software Attribution

        This project uses the following third-party software and libraries:

        """

        for dependency in dependencies where dependency.requiresAttribution {
            content += """

            ## \(dependency.name)

            **Version:** \(dependency.version)
            **License:** \(dependency.license.name) (\(dependency.license.spdxID ?? "Unknown"))
            **Source:** \(dependency.sourceURL)

            \(dependency.license.description)

            """

            if !dependency.copyrightNotices.isEmpty {
                content += "\n**Copyright Notices:**\n"
                for notice in dependency.copyrightNotices {
                    content += "- \(notice)\n"
                }
            }

            content += "\n---\n"
        }

        content += """

        ## License Information

        For full license texts, please refer to the source URLs provided above.

        Generated by White Room License Checker
        Date: \(Date())
        """

        logger.info("Attribution file generated")
        return content
    }

    /// Check compliance against license policy
    public func checkCompliance(_ policy: LicensePolicy) async throws -> LicenseComplianceReport {
        logger.info("Checking compliance against policy")

        var issues: [LicenseComplianceIssue] = []

        for dependency in dependencies {
            // Check if license is allowed
            if !policy.allowedLicenses.contains(dependency.license.spdxID ?? "") {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .licenseNotAllowed,
                    severity: .critical,
                    remediation: "Remove dependency or obtain approval for license \(dependency.license.name)"
                ))
            }

            // Check if attribution is provided
            if dependency.requiresAttribution && !policy.hasAttribution(for: dependency) {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .missingAttribution,
                    severity: .high,
                    remediation: "Add attribution for \(dependency.name) in \(policy.attributionLocation)"
                ))
            }

            // Check for copyleft violations
            if dependency.copyleft && policy.licenseType == .proprietary {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .copyleftViolation,
                    severity: .critical,
                    remediation: "Cannot use \(dependency.name) under \(dependency.license.name) in proprietary project"
                ))
            }

            // Check if source code needs to be provided
            if Self.requiresSourceCodeLicenses.contains(dependency.license.spdxID ?? "") &&
                !policy.hasSourceCodeAvailable {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .missingSourceCode,
                    severity: .high,
                    remediation: "Make source code available or provide written offer for source code"
                ))
            }
        }

        let score = calculateComplianceScore(issues)

        let report = LicenseComplianceReport(
            compliant: issues.isEmpty,
            score: score,
            issues: issues,
            allowedDependencies: dependencies.filter { dep in
                policy.allowedLicenses.contains(dep.license.spdxID ?? "")
            },
            prohibitedDependencies: dependencies.filter { dep in
                !policy.allowedLicenses.contains(dep.license.spdxID ?? "")
            }
        )

        logger.info("Compliance check complete: score \(score)/100")
        return report
    }

    // MARK: - Private Helper Methods

    private func parsePackageFile(_ packageFile: PackageFile) async throws -> [LicenseDependency] {
        // Parse package file (Podfile, Package.swift, package.json, etc.)
        // This is a simplified implementation

        var dependencies: [LicenseDependency] = []

        switch packageFile.type {
        case .cocoaPods:
            dependencies = try parsePodfile(packageFile)
        case .swiftPackage:
            dependencies = try parseSwiftPackage(packageFile)
        case .npm:
            dependencies = try parsePackageJson(packageFile)
        }

        return dependencies
    }

    private func parsePodfile(_ packageFile: PackageFile) throws -> [LicenseDependency] {
        // Simplified Podfile parsing
        return []
    }

    private func parseSwiftPackage(_ packageFile: PackageFile) throws -> [LicenseDependency] {
        // Simplified Package.swift parsing
        return []
    }

    private func parsePackageJson(_ packageFile: PackageFile) throws -> [LicenseDependency] {
        // Simplified package.json parsing
        return []
    }

    private func enrichWithLicenseInfo(_ dependencies: [LicenseDependency]) async throws -> [LicenseDependency] {
        return dependencies.map { dep in
            var enriched = dep

            if let licenseInfo = Self.spdxLicenses[dep.license.spdxID ?? ""] {
                enriched.license = License(
                    id: licenseInfo.id,
                    name: licenseInfo.name,
                    spdxID: licenseInfo.spdxID,
                    url: licenseInfo.url,
                    description: licenseInfo.description,
                    permissions: licenseInfo.permissions,
                    conditions: licenseInfo.conditions,
                    limitations: licenseInfo.limitations,
                    body: nil
                )
                enriched.licenseType = licenseInfo.licenseType
                enriched.requiresAttribution = licenseInfo.requiresAttribution
                enriched.copyleft = licenseInfo.copyleft
                enriched.patentClause = licenseInfo.patentClause
                enriched.liabilityClause = licenseInfo.liabilityClause
            }

            enriched.allowed = Self.allowedLicenses.contains(dep.license.spdxID ?? "")

            return enriched
        }
    }

    private func checkCompatibility(_ license1: License, _ license2: License) -> LicenseConflict? {
        let info1 = Self.spdxLicenses[license1.spdxID ?? ""]
        let info2 = Self.spdxLicenses[license2.spdxID ?? ""]

        guard let type1 = info1?.licenseType, let type2 = info2?.licenseType else {
            return nil
        }

        // Check for copyleft conflicts
        if type1 == .strongCopyleft && type2 == .proprietary {
            return LicenseConflict(
                dependency1: LicenseDependency.mock(license1),
                dependency2: LicenseDependency.mock(license2),
                conflictType: .copyleftConflict,
                description: "\(license1.name) is incompatible with proprietary licensing",
                resolution: "Remove \(license1.name) dependency or open source your project"
            )
        }

        if type2 == .strongCopyleft && type1 == .proprietary {
            return LicenseConflict(
                dependency1: LicenseDependency.mock(license2),
                dependency2: LicenseDependency.mock(license1),
                conflictType: .copyleftConflict,
                description: "\(license2.name) is incompatible with proprietary licensing",
                resolution: "Remove \(license2.name) dependency or open source your project"
            )
        }

        return nil
    }

    private func generateCompatibilityRecommendations(_ conflicts: [LicenseConflict]) -> [LicenseRecommendation] {
        var recommendations: [LicenseRecommendation] = []

        for conflict in conflicts {
            recommendations.append(LicenseRecommendation(
                priority: .high,
                title: "Resolve license conflict",
                description: conflict.description,
                resolution: conflict.resolution
            ))
        }

        return recommendations
    }

    private func generateAttributionText(for dependency: LicenseDependency) -> String {
        var text = "\(dependency.name) v\(dependency.version)\n"
        text += "Licensed under \(dependency.license.name)\n"
        text += dependency.sourceURL + "\n"

        if !dependency.copyrightNotices.isEmpty {
            text += "Copyright: " + dependency.copyrightNotices.joined(separator: ", ") + "\n"
        }

        return text
    }

    private func determineAttributionLocation(for dependency: LicenseDependency) -> AttributionLocation {
        // Most licenses require attribution in About or Settings
        return .aboutScreen
    }

    private func determineAttributionFormat(for dependency: LicenseDependency) -> AttributionFormat {
        // Text format is most common
        return .text
    }

    private func calculateComplianceScore(_ issues: [LicenseComplianceIssue]) -> Int {
        let criticalIssues = issues.filter { $0.severity == .critical }.count
        let highIssues = issues.filter { $0.severity == .high }.count

        let deduction = (criticalIssues * 20) + (highIssues * 10)
        return max(0, 100 - deduction)
    }

    private func checkCompliance(_ dependencies: [LicenseDependency]) -> [LicenseComplianceIssue] {
        var issues: [LicenseComplianceIssue] = []

        for dependency in dependencies {
            if !dependency.allowed {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .licenseNotAllowed,
                    severity: .critical,
                    remediation: "Review and approve license \(dependency.license.name) for use"
                ))
            }

            if dependency.requiresAttribution {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .missingAttribution,
                    severity: .medium,
                    remediation: "Add attribution for \(dependency.name)"
                ))
            }

            if dependency.copyleft {
                issues.append(LicenseComplianceIssue(
                    dependency: dependency,
                    issue: .copyleftViolation,
                    severity: .high,
                    remediation: "Review copyleft obligations for \(dependency.name)"
                ))
            }
        }

        return issues
    }
}

// MARK: - Supporting Types

public struct PackageFile {
    let type: PackageType
    let path: String
    let content: String

    public enum PackageType {
        case cocoaPods
        case swiftPackage
        case npm
        case maven
        case gradle
    }
}

public struct LicenseInfo {
    let id: String
    let name: String
    let spdxID: String?
    let url: String
    let description: String
    let permissions: [String]
    let conditions: [String]
    let limitations: [String]
    let licenseType: LicenseType
    let requiresAttribution: Bool
    let copyleft: Bool
    let patentClause: Bool
    let liabilityClause: Bool
}

public struct LicensePolicy {
    let allowedLicenses: Set<String>
    let licenseType: LicenseType
    let attributionLocation: String
    let hasSourceCodeAvailable: Bool

    func hasAttribution(for dependency: LicenseDependency) -> Bool {
        // Check if attribution exists
        return false
    }
}

// MARK: - Public Types (as specified in requirements)

public struct LicenseDependency: Identifiable, Codable {
    public let id = UUID()
    public let name: String
    public let version: String
    public var license: License
    public var licenseType: LicenseType
    public var allowed: Bool
    public var requiresAttribution: Bool
    public var copyleft: Bool
    public var patentClause: Bool
    public var liabilityClause: Bool
    public let sourceURL: String
    public let copyrightNotices: [String]

    static func mock(_ license: License) -> LicenseDependency {
        return LicenseDependency(
            name: "Mock Dependency",
            version: "1.0.0",
            license: license,
            licenseType: .permissive,
            allowed: true,
            requiresAttribution: true,
            copyleft: false,
            patentClause: false,
            liabilityClause: true,
            sourceURL: "https://example.com",
            copyrightNotices: []
        )
    }
}

public struct License: Codable {
    public let id: String
    public let name: String
    public let spdxID: String?
    public let url: String?
    public let description: String
    public let permissions: [String]
    public let conditions: [String]
    public let limitations: [String]
    public let body: String?
}

public enum LicenseType: String, Codable {
    case permissive
    case weakCopyleft
    case strongCopyleft
    case proprietary
    case publicDomain
    case unknown
}

public struct LicenseCompatibilityReport {
    let compatible: Bool
    let conflicts: [LicenseConflict]
    let recommendations: [LicenseRecommendation]
    let compatibleLicenses: [License]
    let incompatibleLicenses: [License]
}

public struct LicenseConflict {
    let dependency1: LicenseDependency
    let dependency2: LicenseDependency
    let conflictType: ConflictType
    let description: String
    let resolution: String

    public enum ConflictType {
        case copyleftConflict
        case attributionConflict
        case patentClauseConflict
        case liabilityConflict
        case viralPropagation
    }
}

public struct LicenseComplianceIssue {
    let dependency: LicenseDependency
    let issue: ComplianceIssueType
    let severity: ComplianceIssueSeverity
    let remediation: String

    public enum ComplianceIssueType {
        case licenseNotAllowed
        case missingAttribution
        case copyleftViolation
        case outdatedVersion
        case unknownLicense
        case missingSourceCode
    }

    public enum ComplianceIssueSeverity {
        case critical
        case high
        case medium
        case low
    }
}

public struct LicenseComplianceReport {
    let compliant: Bool
    let score: Int
    let issues: [LicenseComplianceIssue]
    let allowedDependencies: [LicenseDependency]
    let prohibitedDependencies: [LicenseDependency]
}

public struct AttributionRequirement {
    let dependency: LicenseDependency
    let text: String
    let location: AttributionLocation
    let format: AttributionFormat

    public enum AttributionLocation {
        case aboutScreen
        case settingsScreen
        case licenseFile
        case documentation
        case splashScreen
    }

    public enum AttributionFormat {
        case text
        case html
        case markdown
        case link
    }
}

public struct LicenseRecommendation {
    let priority: RecommendationPriority
    let title: String
    let description: String
    let resolution: String

    public enum RecommendationPriority {
        case critical
        case high
        case medium
        case low
    }
}
