//
//  SecretScanner.swift
//  WhiteRoomiOS
//
//  Created by White Room Team on 1/16/25.
//

import Foundation
import Combine
import CryptoKit
import os.log

/// Secret scanner for detecting leaked credentials and sensitive data
/// Uses pattern matching, entropy analysis, and Git history scanning
public class SecretScanner: ObservableObject {

    // MARK: - Published Properties

    @Published public var secretsFound: [Secret] = []
    @Published public var isScanning: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.whiteroom.ios", category: "SecretScanner")
    private var cancellables = Set<AnyCancellable>()
    private let scanQueue = DispatchQueue(label: "com.whiteroom.secret.scan", qos: .userInitiated)

    // MARK: - Secret Detection Patterns

    private static let secretPatterns: [SecretPattern] = [
        // AWS Keys
        SecretPattern(
            type: .awsAccessKey,
            regex: "(?i)(aws_access_key_id|aws_access_key).{0,20}?=.{0,20}?'?([A-Z0-9]{20})'?",
            description: "AWS Access Key ID",
            examples: ["AKIAIOSFODNN7EXAMPLE"],
            falsePositives: ["AKIAEXAMPLE", "AKIA0000000000000000"],
            confidence: 0.95
        ),

        SecretPattern(
            type: .awsSecretKey,
            regex: "(?i)(aws_secret_access_key|aws_secret_key).{0,20}?=.{0,20}?['\\\"]([A-Za-z0-9/+=]{40})['\\\"]",
            description: "AWS Secret Access Key",
            examples: ["wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"],
            falsePositives: [],
            confidence: 0.95
        ),

        // GitHub Tokens
        SecretPattern(
            type: .githubToken,
            regex: "(?i)github[_-]?token.{0,20}?=.{0,20}?['\\\"]([a-zA-Z0-9]{40})['\\\"]",
            description: "GitHub Personal Access Token",
            examples: ["ghp_1234567890abcdefGHIJKLMNOPQRSTUVWXYZ"],
            falsePositives: [],
            confidence: 0.90
        ),

        SecretPattern(
            type: .githubToken,
            regex: "(?i)ghp_[a-zA-Z0-9]{36}",
            description: "GitHub Token (Classic)",
            examples: ["ghp_1234567890abcdefGHIJKLMNOPQRSTUVWXYZ"],
            falsePositives: [],
            confidence: 0.95
        ),

        SecretPattern(
            type: .githubToken,
            regex: "(?i)github_pat_[a-zA-Z0-9_]{82}",
            description: "GitHub Token (Fine-grained)",
            examples: ["github_pat_1234567890abcdefGHIJKLMNOPQRSTUVWXYZ1234567890abcdefGHIJKLMNOPQRSTUVWXYZ"],
            falsePositives: [],
            confidence: 0.95
        ),

        // API Tokens
        SecretPattern(
            type: .apiToken,
            regex: "(?i)api[_-]?key.{0,20}?=.{0,20}?['\\\"]([A-Za-z0-9_\\-]{32,})['\\\"]",
            description: "Generic API Key",
            examples: ["1234567890abcdefGHIJKLMNOPQRSTUVWXYZ"],
            falsePositives: ["example", "test_key"],
            confidence: 0.60
        ),

        // Slack Tokens
        SecretPattern(
            type: .slackToken,
            regex: "(?i)slack[_-]?token.{0,20}?=.{0,20}?['\\\"](xox[pbar]-[0-9]{12}-[0-9]{12}-[0-9]{12}-[a-zA-Z0-9]{24})['\\\"]",
            description: "Slack API Token",
            examples: ["xoxb-123456789012-123456789012-123456789012-AbCdEfGhIjKlMnOpQrStUvWx"],
            falsePositives: [],
            confidence: 0.95
        ),

        // Google API Keys
        SecretPattern(
            type: .googleAPIKey,
            regex: "(?i)google[_-]?api[_-]?key.{0,20}?=.{0,20}?['\\\"]([A-Za-z0-9_\\-]{39})['\\\"]",
            description: "Google API Key",
            examples: ["AIzaSyDaGmWKa4JsXZ-HjGw7ISLn_3namBGewQe"],
            falsePositives: [],
            confidence: 0.90
        ),

        SecretPattern(
            type: .googleAPIKey,
            regex: "(?i)AIza[A-Za-z0-9_\\-]{35}",
            description: "Google API Key (Pattern)",
            examples: ["AIzaSyDaGmWKa4JsXZ-HjGw7ISLn_3namBGewQe"],
            falsePositives: [],
            confidence: 0.85
        ),

        // Firebase Secrets
        SecretPattern(
            type: .firebaseSecret,
            regex: "(?i)firebase[_-]?secret.{0,20}?=.{0,20}?['\\\"]([A-Za-z0-9_\\-]{28})['\\\"]",
            description: "Firebase Secret",
            examples: ["1/2K3j4l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9"],
            falsePositives: [],
            confidence: 0.90
        ),

        // Database URLs
        SecretPattern(
            type: .databaseURL,
            regex: "(?i)(database_url|db_url|mongodb|postgres|mysql).{0,20}?=.{0,20}?['\\\"]?([a-z]+://[^\\s'\"]{20,})['\\\"]?",
            description: "Database URL",
            examples: ["postgresql://user:password@host:5432/database"],
            falsePositives: ["postgresql://localhost:5432/db"],
            confidence: 0.85
        ),

        // Private Keys
        SecretPattern(
            type: .privateKey,
            regex: "-----BEGIN [A-Z]+ PRIVATE KEY-----",
            description: "Private Key (PEM Format)",
            examples: ["-----BEGIN RSA PRIVATE KEY-----"],
            falsePositives: [],
            confidence: 0.98
        ),

        SecretPattern(
            type: .privateKey,
            regex: "-----BEGIN ENCRYPTED PRIVATE KEY-----",
            description: "Encrypted Private Key",
            examples: ["-----BEGIN ENCRYPTED PRIVATE KEY-----"],
            falsePositives: [],
            confidence: 0.98
        ),

        // JWT Tokens
        SecretPattern(
            type: .jwt,
            regex: "(?i)eyJ[A-Za-z0-9_\\-]*\\.[A-Za-z0-9_\\-]*\\.[A-Za-z0-9_\\-]*",
            description: "JWT Token",
            examples: ["eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ"],
            falsePositives: [],
            confidence: 0.70
        ),

        // Stripe Keys
        SecretPattern(
            type: .stripeKey,
            regex: "(?i)stripe[_-]?(api[_-]?)?key.{0,20}?=.{0,20}?['\\\"]?(sk_live_[A-Za-z0-9]{24,})",
            description: "Stripe Secret Key",
            examples: ["sk_live_51H5Xabcdefghijk1234567890"],
            falsePositives: ["sk_test_", "sk_live_test"],
            confidence: 0.95
        ),

        SecretPattern(
            type: .stripeKey,
            regex: "(?i)stripe[_-]?(api[_-]?)?key.{0,20}?=.{0,20}?['\\\"]?(sk_test_[A-Za-z0-9]{24,})",
            description: "Stripe Test Key",
            examples: ["sk_test_51H5Xabcdefghijk1234567890"],
            falsePositives: [],
            confidence: 0.90
        ),

        // Mailchimp Keys
        SecretPattern(
            type: .mailchimpKey,
            regex: "(?i)mailchimp[_-]?api[_-]?key.{0,20}?=.{0,20}?['\\\"]?([A-Za-z0-9_\\-]{34}-us[0-9]{1,2})",
            description: "Mailchimp API Key",
            examples: ["1234567890abcdef1234567890abcd-us12"],
            falsePositives: [],
            confidence: 0.90
        ),

        // Twilio Keys
        SecretPattern(
            type: .twilioKey,
            regex: "(?i)twilio[_-]?account[_-]?sid.{0,20}?=.{0,20}?['\\\"]?(AC[a-zA-Z0-9]{32})",
            description: "Twilio Account SID",
            examples: ["AC1234567890abcdef1234567890abcdef"],
            falsePositives: [],
            confidence: 0.90
        ),

        SecretPattern(
            type: .twilioKey,
            regex: "(?i)twilio[_-]?auth[_-]?token.{0,20}?=.{0,20}?['\\\"]?([a-zA-Z0-9]{32})",
            description: "Twilio Auth Token",
            examples: ["1234567890abcdef1234567890abcdef"],
            falsePositives: [],
            confidence: 0.85
        ),

        // SendGrid Keys
        SecretPattern(
            type: .sendGridKey,
            regex: "(?i)sendgrid[_-]?api[_-]?key.{0,20}?=.{0,20}?['\\\"]?(SG\\.[A-Za-z0-9_\\-]{64})",
            description: "SendGrid API Key",
            examples: ["SG.1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"],
            falsePositives: [],
            confidence: 0.90
        ),

        // Session Tokens
        SecretPattern(
            type: .sessionToken,
            regex: "(?i)session[_-]?token.{0,20}?=.{0,20}?['\\\"]?([A-Za-z0-9_\\-]{32,})",
            description: "Session Token",
            examples: ["abc123def456ghi789jkl012mno345pqr"],
            falsePositives: [],
            confidence: 0.50
        ),

        // OAuth Tokens
        SecretPattern(
            type: .oauthToken,
            regex: "(?i)oauth[_-]?token.{0,20}?=.{0,20}?['\\\"]?([A-Za-z0-9_\\-]{20,})",
            description: "OAuth Token",
            examples: ["ya29.a0AfH6SMBx1234567890abcdef"],
            falsePositives: [],
            confidence: 0.60
        ),

        // Passwords
        SecretPattern(
            type: .password,
            regex: "(?i)password.{0,20}?=.{0,20}?['\\\"]([^\\s'\"]{8,})['\\\"]",
            description: "Password",
            examples: ["SecretPassword123!"],
            falsePositives: ["password", "Password123", "changeme", "secret"],
            confidence: 0.40
        )
    ]

    // MARK: - Initialization

    public init() {
        logger.info("Secret Scanner initialized")
    }

    // MARK: - Public Scanning Methods

    /// Scan codebase at given path for secrets
    public func scanCodebase(at path: String) async throws -> [Secret] {
        logger.info("Starting secret scan at: \(path)")

        await MainActor.run {
            self.isScanning = true
        }

        let startTime = Date()

        do {
            let files = try findFilesToScan(in: path)
            var secrets: [Secret] = []

            for file in files {
                let fileSecrets = try await scanFile(file)
                secrets.append(contentsOf: fileSecrets)
            }

            // Filter out false positives
            let filteredSecrets = filterFalsePositives(secrets)

            // Calculate confidence scores
            let scoredSecrets = filteredSecrets.map { secret in
                var scored = secret
                scored.confidence = calculateConfidence(secret)
                return scored
            }

            await MainActor.run {
                self.secretsFound = scoredSecrets
                self.isScanning = false
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Secret scan complete: \(scoredSecrets.count) secrets found in \(duration)s")

            return scoredSecrets

        } catch {
            await MainActor.run {
                self.isScanning = false
            }
            logger.error("Secret scan failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Scan Git commit history for secrets
    public func scanCommitHistory(_ repo: GitRepository) async throws -> [Secret] {
        logger.info("Scanning Git commit history")

        var secrets: [Secret] = []

        // Get all commits
        let commits = try repo.getAllCommits()

        for commit in commits {
            // Get diff for this commit
            let diff = try repo.getDiff(for: commit)

            // Scan diff for secrets
            let commitSecrets = try await scanDiff(diff, commit: commit)
            secrets.append(contentsOf: commitSecrets)
        }

        logger.info("Found \(secrets.count) secrets in commit history")
        return secrets
    }

    /// Validate if a secret is still active/valid
    public func validateSecret(_ secret: Secret) async throws -> SecretValidation {
        logger.info("Validating secret: \(secret.type.rawValue)")

        // Check if secret has expired (based on discovery date)
        let daysSinceDiscovery = Calendar.current.dateComponents([.day], from: secret.discoveredAt, to: Date()).day ?? 0
        let expired = daysSinceDiscovery > 90 // Secrets older than 90 days considered expired

        // Determine risk level
        let risk: SecretValidation.SecurityRisk
        switch secret.type {
        case .awsAccessKey, .awsSecretKey, .stripeKey:
            risk = .critical
        case .githubToken, .databaseURL, .privateKey:
            risk = .high
        case .apiToken, .jwt, .oauthToken:
            risk = .medium
        default:
            risk = .low
        }

        let validation = SecretValidation(
            secret: secret,
            isValid: !expired,
            expired: expired,
            revocationURL: getRevocationURL(for: secret.type),
            rotationInstructions: getRotationInstructions(for: secret.type),
            risk: risk
        )

        logger.info("Secret validation complete: \(expired ? "expired" : "valid")")
        return validation
    }

    /// Rotate a secret (provide instructions)
    public func rotateSecret(_ secret: Secret) async throws {
        logger.info("Initiating rotation for secret: \(secret.type.rawValue)")

        // Log rotation event
        logger.warning("SECRET ROTATION REQUIRED: \(secret.type.rawValue) in \(secret.file)")

        // In production, this would:
        // 1. Revoke the old secret
        // 2. Generate a new secret
        // 3. Update the code/config
        // 4. Test the new secret

        let instructions = getRotationInstructions(for: secret.type)
        logger.info("Rotation instructions: \(instructions)")
    }

    // MARK: - Private Helper Methods

    private func findFilesToScan(in path: String) throws -> [String] {
        let fileManager = FileManager.default
        var filesToScan: [String] = []

        guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path),
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsHiddenFiles]) else {
            throw ScanError.enumerationFailed
        }

        for case let fileURL as URL in enumerator {
            let pathExtension = fileURL.pathExtension.lowercased()

            // Scan source code files
            if ["swift", "m", "mm", "cpp", "c", "h", "hpp", "js", "ts", "py", "java", "kt", "go", "rs"].contains(pathExtension) {
                filesToScan.append(fileURL.path)
            }

            // Scan config files
            if ["json", "yaml", "yml", "xml", "plist", "env", "config", "conf", "ini", "properties"].contains(pathExtension) {
                filesToScan.append(fileURL.path)
            }
        }

        return filesToScan
    }

    private func scanFile(_ path: String) async throws -> [Secret] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        var secrets: [Secret] = []

        for (index, line) in lines.enumerated() {
            let lineSecrets = scanLine(line, lineNumber: index + 1, file: path)
            secrets.append(contentsOf: lineSecrets)
        }

        return secrets
    }

    private func scanLine(_ line: String, lineNumber: Int, file: String) -> [Secret] {
        var secrets: [Secret] = []

        for pattern in Self.secretPatterns {
            if let range = line.range(of: pattern.regex, options: .regularExpression) {
                let value = String(line[range])

                // Redact value
                let redactedValue = redactSecret(value)

                // Find column number
                let columnNumber = line.distance(from: line.startIndex, to: range.lowerBound)

                let secret = Secret(
                    type: pattern.type,
                    value: value,
                    redactedValue: redactedValue,
                    file: file,
                    lineNumber: lineNumber,
                    columnNumber: columnNumber,
                    confidence: pattern.confidence,
                    context: line.trimmingCharacters(in: .whitespaces),
                    discoveredAt: Date(),
                    committedAt: nil,
                    author: nil,
                    commitHash: nil
                )

                secrets.append(secret)
            }
        }

        // Check for high entropy strings (potential secrets)
        let entropySecrets = detectHighEntropyStrings(line, lineNumber: lineNumber, file: file)
        secrets.append(contentsOf: entropySecrets)

        return secrets
    }

    private func detectHighEntropyStrings(_ line: String, lineNumber: Int, file: String) -> [Secret] {
        var secrets: [Secret] = []

        // Split line into words
        let words = line.components(separatedBy: .whitespacesAndNewlines)

        for word in words {
            // Skip short words
            if word.count < 20 { continue }

            // Calculate entropy
            let entropy = calculateEntropy(word)

            // High entropy indicates potential secret (> 4.5)
            if entropy > 4.5 {
                // Check if it's not a known false positive
                if !isKnownFalsePositive(word) {
                    let secret = Secret(
                        type: .apiToken,
                        value: word,
                        redactedValue: redactSecret(word),
                        file: file,
                        lineNumber: lineNumber,
                        columnNumber: 0,
                        confidence: min(0.95, entropy / 6.0), // Scale entropy to confidence
                        context: line.trimmingCharacters(in: .whitespaces),
                        discoveredAt: Date(),
                        committedAt: nil,
                        author: nil,
                        commitHash: nil
                    )
                    secrets.append(secret)
                }
            }
        }

        return secrets
    }

    private func calculateEntropy(_ string: String) -> Double {
        let characterCounts = string.reduce(into: [Character: Int]()) { counts, character in
            counts[character, default: 0] += 1
        }

        let length = Double(string.count)
        var entropy = 0.0

        for count in characterCounts.values {
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }

        return entropy
    }

    private func isKnownFalsePositive(_ string: String) -> Bool {
        let falsePositives = [
            "http://",
            "https://",
            "example.com",
            "localhost",
            "127.0.0.1",
            "test",
            "example",
            "sample"
        ]

        return falsePositives.contains { string.lowercased().contains($0) }
    }

    private func scanDiff(_ diff: String, commit: GitCommit) async throws -> [Secret] {
        var secrets: [Secret] = []

        let lines = diff.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            // Only check added lines
            if line.hasPrefix("+") && !line.hasPrefix("+++") {
                let lineWithoutPrefix = String(line.dropFirst())

                for pattern in Self.secretPatterns {
                    if let range = lineWithoutPrefix.range(of: pattern.regex, options: .regularExpression) {
                        let value = String(lineWithoutPrefix[range])

                        let secret = Secret(
                            type: pattern.type,
                            value: value,
                            redactedValue: redactSecret(value),
                            file: "commit \(commit.hash)",
                            lineNumber: index + 1,
                            columnNumber: 0,
                            confidence: pattern.confidence,
                            context: lineWithoutPrefix.trimmingCharacters(in: .whitespaces),
                            discoveredAt: Date(),
                            committedAt: commit.date,
                            author: commit.author,
                            commitHash: commit.hash
                        )

                        secrets.append(secret)
                    }
                }
            }
        }

        return secrets
    }

    private func filterFalsePositives(_ secrets: [Secret]) -> [Secret] {
        return secrets.filter { secret in
            // Filter by confidence threshold
            guard secret.confidence >= 0.5 else { return false }

            // Check against known false positives
            for pattern in Self.secretPatterns where pattern.type == secret.type {
                return !pattern.falsePositives.contains { secret.value.contains($0) }
            }

            return true
        }
    }

    private func calculateConfidence(_ secret: Secret) -> Double {
        var confidence = secret.confidence

        // Increase confidence for specific file types
        let configFileExtensions = ["env", "config", "conf", "ini", "properties"]
        if configFileExtensions.contains(secret.file.components(separatedBy: ".").last?.lowercased() ?? "") {
            confidence = min(1.0, confidence + 0.2)
        }

        // Increase confidence if found in variable assignment context
        let context = secret.context.lowercased()
        if context.contains("key") || context.contains("secret") || context.contains("token") || context.contains("password") {
            confidence = min(1.0, confidence + 0.1)
        }

        return confidence
    }

    private func redactSecret(_ secret: String) -> String {
        if secret.count <= 8 {
            return String(repeating: "*", count: secret.count)
        } else {
            let prefix = String(secret.prefix(4))
            let suffix = String(secret.suffix(4))
            let stars = String(repeating: "*", count: secret.count - 8)
            return "\(prefix)\(stars)\(suffix)"
        }
    }

    private func getRevocationURL(for type: SecretType) -> String? {
        switch type {
        case .awsAccessKey, .awsSecretKey:
            return "https://console.aws.amazon.com/iam/home#/security_credentials"
        case .githubToken:
            return "https://github.com/settings/tokens"
        case .stripeKey:
            return "https://dashboard.stripe.com/apikeys"
        default:
            return nil
        }
    }

    private func getRotationInstructions(for type: SecretType) -> String {
        switch type {
        case .awsAccessKey, .awsSecretKey:
            return "1. Log into AWS Console\n2. Navigate to IAM > Security Credentials\n3. Delete old access key\n4. Create new access key\n5. Update application with new key"
        case .githubToken:
            return "1. Go to GitHub Settings > Developer settings > Personal access tokens\n2. Revoke old token\n3. Generate new token\n4. Update application with new token"
        case .stripeKey:
            return "1. Log into Stripe Dashboard\n2. Navigate to API keys\n3. Delete old key\n4. Create new key\n5. Update application with new key"
        default:
            return "Rotate secret by regenerating in the service's dashboard and updating all references in code"
        }
    }
}

// MARK: - Supporting Types

public struct GitRepository {
    let path: String

    func getAllCommits() throws -> [GitCommit] {
        // Simulated - in production, would use Git commands
        return []
    }

    func getDiff(for commit: GitCommit) throws -> String {
        // Simulated
        return ""
    }
}

public struct GitCommit {
    let hash: String
    let author: String
    let date: Date
    let message: String
}

public enum ScanError: Error {
    case enumerationFailed
    case fileNotFound(String)
    case invalidGitRepository
}

// MARK: - Public Types (as specified in requirements)

public struct Secret: Identifiable, Codable {
    public let id = UUID()
    public let type: SecretType
    public let value: String
    public let redactedValue: String
    public let file: String
    public let lineNumber: Int
    public let columnNumber: Int
    public var confidence: Double
    public let context: String
    public let discoveredAt: Date
    public let committedAt: Date?
    public let author: String?
    public let commitHash: String?

    public enum SecretType: String, Codable {
        case awsAccessKey = "AWS Access Key"
        case awsSecretKey = "AWS Secret Key"
        case apiToken = "API Token"
        case githubToken = "GitHub Token"
        case slackToken = "Slack Token"
        case googleAPIKey = "Google API Key"
        case firebaseSecret = "Firebase Secret"
        case databaseURL = "Database URL"
        case privateKey = "Private Key"
        case certificate = "Certificate"
        case password = "Password"
        case jwt = "JWT Token"
        case sessionToken = "Session Token"
        case oauthToken = "OAuth Token"
        case stripeKey = "Stripe Key"
        case mailchimpKey = "Mailchimp Key"
        case twilioKey = "Twilio Key"
        case sendGridKey = "SendGrid Key"
    }
}

public struct SecretValidation {
    public let secret: Secret
    public let isValid: Bool
    public let expired: Bool
    public let revocationURL: String?
    public let rotationInstructions: String
    public let risk: SecurityRisk

    public enum SecurityRisk {
        case critical
        case high
        case medium
        case low
        case informational
    }
}

public struct SecretPattern: Codable {
    public let type: SecretType
    public let regex: String
    public let description: String
    public let examples: [String]
    public let falsePositives: [String]
    public let confidence: Double
}
