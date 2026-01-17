//
//  OWASPScanner.swift
//  WhiteRoomiOS
//
//  Created by White Room Team on 1/16/25.
//

import Foundation
import Combine
import os.log

/// Comprehensive OWASP Top 10 2021 security vulnerability scanner
/// Detects and reports security vulnerabilities in codebases
public class OWASPScanner: ObservableObject {

    // MARK: - Published Properties

    @Published public var vulnerabilities: [SecurityVulnerability] = []
    @Published public var scanResults: [ScanResult] = []
    @Published public var isScanning: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.whiteroom.ios", category: "OWASPScanner")
    private var cancellables = Set<AnyCancellable>()
    private let scanQueue = DispatchQueue(label: "com.whiteroom.owasp.scan", qos: .userInitiated)

    // MARK: - Vulnerability Patterns

    private static let vulnerabilityPatterns: [String: (VulnerabilityType, OWASPCategory)] = [
        // SQL Injection patterns
        "SELECT.*FROM.*WHERE": (.sqlInjection, .A03_2021_Injection),
        "INSERT.*INTO.*VALUES": (.sqlInjection, .A03_2021_Injection),
        "UPDATE.*SET.*WHERE": (.sqlInjection, .A03_2021_Injection),
        "DELETE.*FROM.*WHERE": (.sqlInjection, .A03_2021_Injection),

        // XSS patterns
        "innerHTML\\s*=": (.xss, .A03_2021_Injection),
        "document\\.write": (.xss, .A03_2021_Injection),
        "eval\\(": (.xss, .A03_2021_Injection),

        // Hardcoded secrets
        "password\\s*=\\s*['\"]\\w+['\"]": (.hardcodedSecrets, .A02_2021_CryptographicFailures),
        "api[_-]?key\\s*=\\s*['\"][^'\"]{20,}['\"]": (.hardcodedSecrets, .A02_2021_CryptographicFailures),
        "secret[_-]?key\\s*=\\s*['\"][^'\"]{20,}['\"]": (.hardcodedSecrets, .A02_2021_CryptographicFailures),

        // Weak cryptography
        "MD5\\(": (.weakCryptography, .A02_2021_CryptographicFailures),
        "SHA1\\(": (.weakCryptography, .A02_2021_CryptographicFailures),
        "DES\\(": (.weakCryptography, .A02_2021_CryptographicFailures),

        // Insecure communication
        "http://": (.insecureCommunication, .A02_2021_CryptographicFailures),

        // Command injection
        "system\\(": (.commandInjection, .A03_2021_Injection),
        "exec\\(": (.commandInjection, .A03_2021_Injection),
        "popen\\(": (.commandInjection, .A03_2021_Injection),

        // Path traversal
        "\\.\\./": (.pathTraversal, .A01_2021_BrokenAccessControl),

        // Buffer overflow indicators (C/C++)
        "strcpy\\(": (.bufferOverflow, .A03_2021_Injection),
        "strcat\\(": (.bufferOverflow, .A03_2021_Injection),
        "gets\\(": (.bufferOverflow, .A03_2021_Injection),
        "sprintf\\(": (.bufferOverflow, .A03_2021_Injection),
    ]

    // MARK: - CWE Mapping

    private static let cweMapping: [VulnerabilityType: String] = [
        .sqlInjection: "CWE-89",
        .xss: "CWE-79",
        .csrf: "CWE-352",
        .insecureDataStorage: "CWE-922",
        .weakCryptography: "CWE-327",
        .insecureCommunication: "CWE-319",
        .hardcodedSecrets: "CWE-798",
        .insecureConfiguration: "CWE-16",
        .outdatedDependency: "CWE-937",
        .bufferOverflow: "CWE-120",
        .integerOverflow: "CWE-190",
        .nullPointerDereference: "CWE-476",
        .useAfterFree: "CWE-416",
        .doubleFree: "CWE-415",
        .formatString: "CWE-134",
        .pathTraversal: "CWE-22",
        .commandInjection: "CWE-78",
        .ldapInjection: "CWE-90",
        .xmlInjection: "CWE-91",
        .ssrf: "CWE-918",
        .insecureDeserialization: "CWE-502",
        .raceCondition: "CWE-362",
    ]

    // MARK: - Initialization

    public init() {
        logger.info("OWASP Scanner initialized")
    }

    // MARK: - Public Scanning Methods

    /// Scan entire codebase at given path
    public func scanCodebase(at path: String) async throws -> ScanResult {
        logger.info("Starting codebase scan at: \(path)")

        await MainActor.run {
            self.isScanning = true
        }

        let startTime = Date()

        do {
            let files = try findSourceFiles(in: path)
            let vulnerabilities = try await scanForCommonVulnerabilities(files)

            let duration = Date().timeIntervalSince(startTime)
            let result = ScanResult(
                scanType: .staticAnalysis,
                timestamp: Date(),
                duration: duration,
                filesScanned: files.count,
                vulnerabilitiesFound: vulnerabilities.count,
                vulnerabilities: vulnerabilities,
                summary: calculateSummary(vulnerabilities)
            )

            await MainActor.run {
                self.scanResults.append(result)
                self.vulnerabilities = vulnerabilities
                self.isScanning = false
            }

            logger.info("Scan complete: \(vulnerabilities.count) vulnerabilities found")
            return result

        } catch {
            await MainActor.run {
                self.isScanning = false
            }
            logger.error("Scan failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Scan dependencies for known vulnerabilities
    public func scanDependencies(_ dependencies: [Dependency]) async throws -> [Vulnerability] {
        logger.info("Scanning \(dependencies.count) dependencies")

        var vulnerabilities: [Vulnerability] = []

        for dependency in dependencies {
            if let knownVulns = await checkVulnerabilityDatabase(for: dependency) {
                vulnerabilities.append(contentsOf: knownVulns)
            }
        }

        logger.info("Found \(vulnerabilities.count) dependency vulnerabilities")
        return vulnerabilities
    }

    /// Scan specific files for common vulnerability patterns
    public func scanForCommonVulnerabilities(_ files: [String]) async throws -> [SecurityVulnerability] {
        logger.info("Scanning \(files.count) files for vulnerabilities")

        return try await withThrowingTaskGroup(of: [SecurityVulnerability].self) { group in
            var allVulnerabilities: [SecurityVulnerability] = []

            for file in files {
                group.addTask {
                    return try await self.scanFile(file)
                }
            }

            for try await vulnerabilities in group {
                allVulnerabilities.append(contentsOf: vulnerabilities)
            }

            return allVulnerabilities
        }
    }

    /// Generate comprehensive security report
    public func generateSecurityReport(_ results: [ScanResult]) throws -> SecurityReport {
        logger.info("Generating security report from \(results.count) scan results")

        let allVulnerabilities = results.flatMap { $0.vulnerabilities }
        let summary = calculateSummary(allVulnerabilities)

        let report = SecurityReport(
            timestamp: Date(),
            scanResults: results,
            overallSummary: summary,
            criticalIssues: allVulnerabilities.filter { $0.severity == .critical },
            highIssues: allVulnerabilities.filter { $0.severity == .high },
            recommendations: generateRecommendations(allVulnerabilities),
            trendAnalysis: calculateTrend(results)
        )

        logger.info("Security report generated: score \(summary.totalScore.overall)")
        return report
    }

    // MARK: - Private Helper Methods

    private func findSourceFiles(in path: String) throws -> [String] {
        let fileManager = FileManager.default
        var sourceFiles: [String] = []

        guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path),
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsHiddenFiles]) else {
            throw ScanError.enumerationFailed
        }

        for case let fileURL as URL in enumerator {
            let pathExtension = fileURL.pathExtension.lowercased()

            if ["swift", "m", "mm", "cpp", "c", "h", "hpp", "js", "ts", "py", "java", "kt"].contains(pathExtension) {
                sourceFiles.append(fileURL.path)
            }
        }

        return sourceFiles
    }

    private func scanFile(_ path: String) async throws -> [SecurityVulnerability] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        var vulnerabilities: [SecurityVulnerability] = []

        for (index, line) in lines.enumerated() {
            let lineVulnerabilities = scanLine(line, lineNumber: index + 1, file: path)
            vulnerabilities.append(contentsOf: lineVulnerabilities)
        }

        return vulnerabilities
    }

    private func scanLine(_ line: String, lineNumber: Int, file: String) -> [SecurityVulnerability] {
        var vulnerabilities: [SecurityVulnerability] = []

        for (pattern, (type, owaspCategory)) in Self.vulnerabilityPatterns {
            if let range = line.range(of: pattern, options: .regularExpression) {
                let vulnerability = SecurityVulnerability(
                    type: type,
                    severity: determineSeverity(for: type),
                    title: generateTitle(for: type),
                    description: generateDescription(for: type, context: line),
                    affectedFile: file,
                    lineNumber: lineNumber,
                    cwe: Self.cweMapping[type],
                    owaspCategory: owaspCategory,
                    remediation: generateRemediation(for: type),
                    references: generateReferences(for: type),
                    discoveredAt: Date()
                )
                vulnerabilities.append(vulnerability)
            }
        }

        return vulnerabilities
    }

    private func checkVulnerabilityDatabase(for dependency: Dependency) async -> [Vulnerability]? {
        // Simulated vulnerability database lookup
        // In production, this would query CVE database, NVD, or Snyk
        return nil
    }

    private func calculateSummary(_ vulnerabilities: [SecurityVulnerability]) -> ScanSummary {
        let critical = vulnerabilities.filter { $0.severity == .critical }.count
        let high = vulnerabilities.filter { $0.severity == .high }.count
        let medium = vulnerabilities.filter { $0.severity == .medium }.count
        let low = vulnerabilities.filter { $0.severity == .low }.count
        let info = vulnerabilities.filter { $0.severity == .info }.count

        let score = calculateSecurityScore(critical: critical, high: high, medium: medium, low: low, info: info)

        return ScanSummary(
            criticalCount: critical,
            highCount: high,
            mediumCount: medium,
            lowCount: low,
            infoCount: info,
            totalScore: score
        )
    }

    private func calculateSecurityScore(critical: Int, high: Int, medium: Int, low: Int, info: Int) -> ScanSummary.SecurityScore {
        // Weighted scoring: critical=40, high=20, medium=10, low=5, info=1
        let penalty = (critical * 40) + (high * 20) + (medium * 10) + (low * 5) + (info * 1)
        let score = max(0, 100 - penalty)

        let grade: ScanSummary.SecurityScore.Grade
        switch score {
        case 90...100: grade = .excellent
        case 75..<90: grade = .good
        case 60..<75: grade = .fair
        case 40..<60: grade = .poor
        default: grade = .critical
        }

        return ScanSummary.SecurityScore(overall: score, grade: grade)
    }

    private func determineSeverity(for type: VulnerabilityType) -> VulnerabilitySeverity {
        switch type {
        case .sqlInjection, .hardcodedSecrets, .commandInjection, .ssrf, .insecureDeserialization:
            return .critical
        case .xss, .csrf, .pathTraversal, .bufferOverflow, .useAfterFree, .doubleFree:
            return .high
        case .weakCryptography, .insecureCommunication, .insecureDataStorage, .integerOverflow:
            return .medium
        case .outdatedDependency, .insecureConfiguration, .raceCondition:
            return .low
        default:
            return .info
        }
    }

    private func generateTitle(for type: VulnerabilityType) -> String {
        switch type {
        case .sqlInjection: return "SQL Injection Vulnerability"
        case .xss: return "Cross-Site Scripting (XSS)"
        case .csrf: return "Cross-Site Request Forgery (CSRF)"
        case .hardcodedSecrets: return "Hardcoded Credentials"
        case .weakCryptography: return "Weak Cryptographic Algorithm"
        case .commandInjection: return "Command Injection"
        case .pathTraversal: return "Path Traversal Vulnerability"
        default: return "Security Vulnerability: \(type)"
        }
    }

    private func generateDescription(for type: VulnerabilityType, context: String) -> String {
        switch type {
        case .sqlInjection:
            return "Potential SQL injection detected. User input may be concatenated directly into SQL queries, allowing attackers to manipulate database queries."
        case .xss:
            return "Cross-site scripting vulnerability detected. Untrusted data may be rendered without proper sanitization."
        case .hardcodedSecrets:
            return "Hardcoded credentials detected in source code. Secrets should be stored in secure credential managers."
        default:
            return "Security vulnerability detected: \(context)"
        }
    }

    private func generateRemediation(for type: VulnerabilityType) -> Remediation {
        let recommendation: String
        let codeExample: String?
        let priority: Remediation.RemediationPriority

        switch type {
        case .sqlInjection:
            recommendation = "Use parameterized queries or prepared statements instead of string concatenation."
            codeExample = """
            // Vulnerable:
            let query = "SELECT * FROM users WHERE id = \\(userId)"

            // Secure:
            let query = "SELECT * FROM users WHERE id = ?"
            db.execute(query, parameters: [userId])
            """
            priority = .immediate

        case .xss:
            recommendation = "Sanitize and encode all untrusted data before rendering. Use frameworks with built-in XSS protection."
            codeExample = """
            // Sanitize output:
            let sanitized = input.replacingOccurrences(of: "<", with: "&lt;")
                                .replacingOccurrences(of: ">", with: "&gt;")
            """
            priority = .high

        case .hardcodedSecrets:
            recommendation = "Move secrets to environment variables or secure vault services. Never commit secrets to version control."
            codeExample = """
            // Use environment variables:
            let apiKey = ProcessInfo.processInfo.environment["API_KEY"]

            // Or use Keychain:
            let apiKey = try Keychain().get("api_key")
            """
            priority = .immediate

        default:
            recommendation = "Review and remediate the vulnerability according to OWASP guidelines."
            codeExample = nil
            priority = .high
        }

        return Remediation(
            recommendation: recommendation,
            codeExample: codeExample,
            priority: priority,
            estimatedEffort: estimateEffort(for: type),
            references: generateReferences(for: type)
        )
    }

    private func estimateEffort(for type: VulnerabilityType) -> String {
        switch type {
        case .hardcodedSecrets: return "< 1 hour"
        case .xss: return "1-2 hours"
        case .sqlInjection: return "2-4 hours"
        case .weakCryptography: return "4-8 hours"
        default: return "2-4 hours"
        }
    }

    private func generateReferences(for type: VulnerabilityType) -> [String] {
        var refs: [String] = []

        switch type {
        case .sqlInjection:
            refs = [
                "https://owasp.org/www-community/attacks/SQL_Injection",
                "https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html"
            ]
        case .xss:
            refs = [
                "https://owasp.org/www-community/attacks/xss/",
                "https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html"
            ]
        default:
            refs = ["https://owasp.org/"]
        }

        return refs
    }

    private func generateRecommendations(_ vulnerabilities: [SecurityVulnerability]) -> [String] {
        var recommendations: [String] = []

        let criticalCount = vulnerabilities.filter { $0.severity == .critical }.count
        if criticalCount > 0 {
            recommendations.append("🚨 \(criticalCount) critical vulnerabilities require immediate remediation")
        }

        let secretCount = vulnerabilities.filter { $0.type == .hardcodedSecrets }.count
        if secretCount > 0 {
            recommendations.append("🔑 Rotate \(secretCount) hardcoded secrets immediately")
        }

        recommendations.append("📚 Implement OWASP ASVS security requirements")
        recommendations.append("🔒 Enable automated security scanning in CI/CD pipeline")
        recommendations.append("📊 Conduct quarterly security assessments")

        return recommendations
    }

    private func calculateTrend(_ results: [ScanResult]) -> TrendAnalysis? {
        guard results.count >= 2 else { return nil }

        let latest = results.last!
        let previous = results[results.count - 2]

        let scoreChange = latest.summary.totalScore.overall - previous.summary.totalScore.overall
        let vulnChange = latest.vulnerabilitiesFound - previous.vulnerabilitiesFound

        let trend: TrendDirection
        if scoreChange > 0 {
            trend = .improving
        } else if scoreChange < 0 {
            trend = .degrading
        } else {
            trend = .stable
        }

        return TrendAnalysis(
            direction: trend,
            scoreChange: scoreChange,
            vulnerabilityCountChange: vulnChange,
            period: DateInterval(start: previous.timestamp, end: latest.timestamp)
        )
    }
}

// MARK: - Supporting Types

public struct Dependency: Codable {
    let name: String
    let version: String
    let source: String
}

public struct Vulnerability: Codable {
    let id: String
    let title: String
    let severity: String
    let description: String
    let affectedVersions: [String]
    let patchedVersions: [String]
    let references: [String]
}

public struct SecurityReport {
    let timestamp: Date
    let scanResults: [ScanResult]
    let overallSummary: ScanSummary
    let criticalIssues: [SecurityVulnerability]
    let highIssues: [SecurityVulnerability]
    let recommendations: [String]
    let trendAnalysis: TrendAnalysis?
}

public struct TrendAnalysis {
    let direction: TrendDirection
    let scoreChange: Int
    let vulnerabilityCountChange: Int
    let period: DateInterval

    public enum TrendDirection {
        case improving
        case stable
        case degrading
    }
}

public enum ScanError: Error {
    case enumerationFailed
    case fileNotFound(String)
    case invalidFormat
}

// MARK: - Public Types (as specified in requirements)

public struct SecurityVulnerability: Identifiable, Codable {
    public let id = UUID()
    public let type: VulnerabilityType
    public let severity: VulnerabilitySeverity
    public let title: String
    public let description: String
    public let affectedFile: String
    public let lineNumber: Int?
    public let cwe: String?
    public let owaspCategory: OWASPCategory
    public let remediation: Remediation
    public let references: [String]
    public let discoveredAt: Date

    public enum VulnerabilityType: String, Codable {
        case sqlInjection
        case xss
        case csrf
        case insecureDataStorage
        case weakCryptography
        case insecureCommunication
        case hardcodedSecrets
        case insecureConfiguration
        case outdatedDependency
        case bufferOverflow
        case integerOverflow
        case nullPointerDereference
        case useAfterFree
        case doubleFree
        case formatString
        case pathTraversal
        case commandInjection
        case ldapInjection
        case xmlInjection
        case ssrf
        case insecureDeserialization
        case raceCondition
    }

    public enum VulnerabilitySeverity: Int, Comparable, Codable {
        case info = 1
        case low = 2
        case medium = 3
        case high = 4
        case critical = 5

        public static func < (lhs: VulnerabilitySeverity, rhs: VulnerabilitySeverity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    public enum OWASPCategory: String, Codable {
        case A01_2021_BrokenAccessControl = "A01:2021-Broken Access Control"
        case A02_2021_CryptographicFailures = "A02:2021-Cryptographic Failures"
        case A03_2021_Injection = "A03:2021-Injection"
        case A04_2021_InsecureDesign = "A04:2021-Insecure Design"
        case A05_2021_SecurityMisconfiguration = "A05:2021-Security Misconfiguration"
        case A06_2021_VulnerableComponents = "A06:2021-Vulnerable and Outdated Components"
        case A07_2021_AuthenticationFailures = "A07:2021-Identification and Authentication Failures"
        case A08_2021_DataIntegrityFailures = "A08:2021-Software and Data Integrity Failures"
        case A09_2021_LoggingFailures = "A09:2021-Security Logging and Monitoring Failures"
        case A10_2021_SSRF = "A10:2021-Server-Side Request Forgery"
    }
}

public struct Remediation: Codable {
    public let recommendation: String
    public let codeExample: String?
    public let priority: RemediationPriority
    public let estimatedEffort: String
    public let references: [String]

    public enum RemediationPriority: String, Codable {
        case immediate
        case high
        case medium
        case low
        case optional
    }
}

public struct ScanResult: Identifiable, Codable {
    public let id = UUID()
    public let scanType: ScanType
    public let timestamp: Date
    public let duration: TimeInterval
    public let filesScanned: Int
    public let vulnerabilitiesFound: Int
    public let vulnerabilities: [SecurityVulnerability]
    public let summary: ScanSummary

    public enum ScanType: String, Codable {
        case staticAnalysis
        case dependencyScan
        case configurationScan
        case secretScan
        case fullSecurityAudit
    }
}

public struct ScanSummary: Codable {
    public let criticalCount: Int
    public let highCount: Int
    public let mediumCount: Int
    public let lowCount: Int
    public let infoCount: Int
    public let totalScore: SecurityScore

    public struct SecurityScore: Codable {
        public let overall: Int
        public let grade: Grade

        public enum Grade: String, Codable {
            case excellent
            case good
            case fair
            case poor
            case critical
        }
    }
}
