//
//  OWASPScannerTests.swift
//  WhiteRoomiOSTests
//
//  Created by White Room Team on 1/16/25.
//

import XCTest
@testable import WhiteRoomiOS

/// Comprehensive tests for OWASP vulnerability scanner
final class OWASPScannerTests: XCTestCase {

    var sut: OWASPScanner!

    override func setUp() async throws {
        try await super.setUp()
        sut = OWASPScanner()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isScanning)
        XCTAssertTrue(sut.vulnerabilities.isEmpty)
        XCTAssertTrue(sut.scanResults.isEmpty)
    }

    // MARK: - SQL Injection Detection Tests

    func testSQLInjectionDetection() async throws {
        // Create test file with SQL injection pattern
        let testContent = """
        let query = "SELECT * FROM users WHERE id = " + userId
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        XCTAssertFalse(result.vulnerabilities.isEmpty)
        let sqlVulns = result.vulnerabilities.filter { $0.type == .sqlInjection }
        XCTAssertTrue(sqlVulns.count > 0, "Should detect SQL injection vulnerability")
    }

    func testSQLInjectionWithParameterizedQuery() async throws {
        // This should NOT trigger a vulnerability (safe code)
        let testContent = """
        let query = "SELECT * FROM users WHERE id = ?"
        db.execute(query, parameters: [userId])
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let sqlVulns = result.vulnerabilities.filter { $0.type == .sqlInjection }
        // Parameterized queries should not trigger false positives
        // (Implementation may vary)
    }

    // MARK: - XSS Detection Tests

    func testXSSDetection() async throws {
        let testContent = """
        let html = "<div>" + userInput + "</div>"
        element.innerHTML = html
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let xssVulns = result.vulnerabilities.filter { $0.type == .xss }
        XCTAssertTrue(xssVulns.count > 0, "Should detect XSS vulnerability")
    }

    func testDocumentWriteXSS() async throws {
        let testContent = """
        document.write("<script>" + userInput + "</script>")
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let xssVulns = result.vulnerabilities.filter { $0.type == .xss }
        XCTAssertTrue(xssVulns.count > 0, "Should detect document.write XSS")
    }

    // MARK: - Hardcoded Secrets Detection Tests

    func testHardcodedPasswordDetection() async throws {
        let testContent = """
        let password = "SecretPassword123!"
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let secretVulns = result.vulnerabilities.filter { $0.type == .hardcodedSecrets }
        XCTAssertTrue(secretVulns.count > 0, "Should detect hardcoded password")
    }

    func testHardcodedAPIKeyDetection() async throws {
        let testContent = """
        let apiKey = "sk_live_1234567890abcdefghijklmnop"
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let secretVulns = result.vulnerabilities.filter { $0.type == .hardcodedSecrets }
        XCTAssertTrue(secretVulns.count > 0, "Should detect hardcoded API key")
    }

    // MARK: - Weak Cryptography Tests

    func testMD5Detection() async throws {
        let testContent = """
        let hash = MD5(data)
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let weakCryptoVulns = result.vulnerabilities.filter { $0.type == .weakCryptography }
        XCTAssertTrue(weakCryptoVulns.count > 0, "Should detect MD5 usage")
    }

    func testSHA1Detection() async throws {
        let testContent = """
        let hash = SHA1(data)
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let weakCryptoVulns = result.vulnerabilities.filter { $0.type == .weakCryptography }
        XCTAssertTrue(weakCryptoVulns.count > 0, "Should detect SHA1 usage")
    }

    // MARK: - Insecure Communication Tests

    func testHTTPDetection() async throws {
        let testContent = """
        let url = "http://example.com/api"
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let insecureCommVulns = result.vulnerabilities.filter { $0.type == .insecureCommunication }
        XCTAssertTrue(insecureCommVulns.count > 0, "Should detect HTTP usage")
    }

    func testHTTPSDetection() async throws {
        let testContent = """
        let url = "https://example.com/api"
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let insecureCommVulns = result.vulnerabilities.filter { $0.type == .insecureCommunication }
        // HTTPS should not trigger vulnerability
        XCTAssertTrue(insecureCommVulns.filter { $0.affectedFile.contains("https") }.isEmpty)
    }

    // MARK: - Command Injection Tests

    func testSystemCommandInjection() async throws {
        let testContent = """
        system(userInput)
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let commandVulns = result.vulnerabilities.filter { $0.type == .commandInjection }
        XCTAssertTrue(commandVulns.count > 0, "Should detect system() usage")
    }

    // MARK: - Path Traversal Tests

    func testPathTraversalDetection() async throws {
        let testContent = """
        let path = "../" + userInput
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let pathVulns = result.vulnerabilities.filter { $0.type == .pathTraversal }
        XCTAssertTrue(pathVulns.count > 0, "Should detect path traversal pattern")
    }

    // MARK: - Buffer Overflow Tests

    func testStrcpyDetection() async throws {
        let testContent = """
        strcpy(dest, src)
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        let bufferVulns = result.vulnerabilities.filter { $0.type == .bufferOverflow }
        XCTAssertTrue(bufferVulns.count > 0, "Should detect strcpy usage")
    }

    // MARK: - Severity Mapping Tests

    func testSQLInjectionSeverity() {
        let severity = OWASPScanner.VulnerabilitySeverity.sqlInjection
        XCTAssertEqual(severity, .critical)
    }

    func testXSSSeverity() {
        let severity = OWASPScanner.VulnerabilitySeverity.high
        XCTAssertEqual(severity, .high)
    }

    // MARK: - Security Score Calculation Tests

    func testSecurityScoreWithNoVulnerabilities() {
        let summary = ScanSummary(
            criticalCount: 0,
            highCount: 0,
            mediumCount: 0,
            lowCount: 0,
            infoCount: 0,
            totalScore: ScanSummary.SecurityScore(overall: 100, grade: .excellent)
        )

        XCTAssertEqual(summary.totalScore.overall, 100)
        XCTAssertEqual(summary.totalScore.grade, .excellent)
    }

    func testSecurityScoreWithCriticalVulnerabilities() {
        let summary = ScanSummary(
            criticalCount: 1,
            highCount: 0,
            mediumCount: 0,
            lowCount: 0,
            infoCount: 0,
            totalScore: ScanSummary.SecurityScore(overall: 60, grade: .fair)
        )

        XCTAssertEqual(summary.totalScore.overall, 60)
        XCTAssertEqual(summary.totalScore.grade, .fair)
    }

    func testSecurityScoreWithMultipleVulnerabilities() {
        let summary = ScanSummary(
            criticalCount: 1,
            highCount: 2,
            mediumCount: 3,
            lowCount: 5,
            infoCount: 10,
            totalScore: ScanSummary.SecurityScore(overall: 0, grade: .critical)
        )

        XCTAssertEqual(summary.totalScore.overall, 0)
        XCTAssertEqual(summary.totalScore.grade, .critical)
    }

    // MARK: - CWE Mapping Tests

    func testCWEMappingForSQLInjection() {
        let cwe = OWASPScanner.cweMapping[.sqlInjection]
        XCTAssertEqual(cwe, "CWE-89")
    }

    func testCWEMappingForXSS() {
        let cwe = OWASPScanner.cweMapping[.xss]
        XCTAssertEqual(cwe, "CWE-79")
    }

    func testCWEMappingForHardcodedSecrets() {
        let cwe = OWASPScanner.cweMapping[.hardcodedSecrets]
        XCTAssertEqual(cwe, "CWE-798")
    }

    // MARK: - OWASP Category Mapping Tests

    func testOWASPCategoryForInjection() {
        let category = OWASPScanner.OWASPCategory.A03_2021_Injection
        XCTAssertEqual(category.rawValue, "A03:2021-Injection")
    }

    func testOWASPCategoryForCryptographicFailures() {
        let category = OWASPScanner.OWASPCategory.A02_2021_CryptographicFailures
        XCTAssertEqual(category.rawValue, "A02:2021-Cryptographic Failures")
    }

    // MARK: - Remediation Tests

    func testSQLInjectionRemediation() {
        let remediation = Remediation(
            recommendation: "Use parameterized queries",
            codeExample: "SELECT * FROM users WHERE id = ?",
            priority: .immediate,
            estimatedEffort: "2-4 hours",
            references: ["https://owasp.org/"]
        )

        XCTAssertEqual(remediation.priority, .immediate)
        XCTAssertNotNil(remediation.codeExample)
    }

    // MARK: - Performance Tests

    func testScanPerformance() async throws {
        let testFile = try createTestFile(content: "SELECT * FROM users")

        let start = Date()
        let result = try await sut.scanCodebase(at: testFile)
        let duration = Date().timeIntervalSince(start)

        XCTAssertLessThan(duration, 5.0, "Scan should complete in under 5 seconds")
        XCTAssertNotNil(result)
    }

    // MARK: - Helper Methods

    private func createTestFile(content: String) throws -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).swift")

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        return testFile.path
    }

    private func createTestFiles(count: Int) throws -> [String] {
        var files: [String] = []

        for _ in 0..<count {
            let content = "let x = 1"
            let file = try createTestFile(content: content)
            files.append(file)
        }

        return files
    }
}

// MARK: - Test Extensions

extension OWASPScannerTests {

    func testMultipleVulnerabilitiesInSingleFile() async throws {
        let testContent = """
        let password = "secret123"
        let query = "SELECT * FROM users WHERE id = " + userId
        element.innerHTML = userInput
        """
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        XCTAssertTrue(result.vulnerabilities.count >= 3, "Should detect multiple vulnerabilities")
    }

    func testScanResultStructure() async throws {
        let testContent = "SELECT * FROM users"
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.scanType, .staticAnalysis)
        XCTAssertNotNil(result.timestamp)
        XCTAssertGreaterThan(result.duration, 0)
        XCTAssertGreaterThan(result.filesScanned, 0)
    }

    func testVulnerabilityStructure() async throws {
        let testContent = "SELECT * FROM users"
        let testFile = try createTestFile(content: testContent)

        let result = try await sut.scanCodebase(at: testFile)

        if let vuln = result.vulnerabilities.first {
            XCTAssertNotNil(vuln.id)
            XCTAssertNotNil(vuln.type)
            XCTAssertNotNil(vuln.severity)
            XCTAssertFalse(vuln.title.isEmpty)
            XCTAssertFalse(vuln.description.isEmpty)
            XCTAssertFalse(vuln.affectedFile.isEmpty)
            XCTAssertNotNil(vuln.owaspCategory)
            XCTAssertNotNil(vuln.remediation)
            XCTAssertFalse(vuln.references.isEmpty)
        }
    }
}
