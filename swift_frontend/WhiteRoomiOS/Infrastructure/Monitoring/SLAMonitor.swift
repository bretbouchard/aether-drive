//
// SLAMonitor.swift
// WhiteRoomiOS
//
// Created by AI Assistant on 2026-01-16.
// Part of Phase 3: Advanced Monitoring & Alerting System
//

import Foundation
import Combine

/// Service Level Agreement (SLA) monitoring and enforcement system
/// Tracks metrics, checks compliance, reports violations, and generates SLA reports
public class SLAMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published public var slaMetrics: [SLAMetric] = []
    @Published public var violations: [SLAViolation] = []
    @Published public var complianceReports: [SLACompliance] = []

    // MARK: - Private Properties

    private var slas: [SLA] = []
    private var metricHistory: [SLA: [SLAMetric]] = [:]
    private var violationHistory: [SLAViolation] = []
    private let storage: SLAStorage
    private let alertRouter: AlertRouter
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        storage: SLAStorage = .shared,
        alertRouter: AlertRouter = .shared
    ) {
        self.storage = storage
        self.alertRouter = alertRouter

        loadSLAs()
        loadViolationHistory()
        loadComplianceReports()

        setupPeriodicChecks()
    }

    // MARK: - Public Methods

    /// Track a metric for SLA monitoring
    public func trackMetric(_ metric: SLAMetric) {
        DispatchQueue.main.async {
            self.slaMetrics.append(metric)
        }

        // Store in history
        for sla in slas where sla.metric == metric.type {
            if metricHistory[sla] == nil {
                metricHistory[sla] = []
            }
            metricHistory[sla]?.append(metric)

            // Check for SLA violation
            checkViolation(sla: sla, metric: metric)
        }

        // Trim history
        if slaMetrics.count > 10000 {
            slaMetrics = Array(slaMetrics.suffix(10000))
        }
    }

    /// Check compliance for a specific SLA
    public func checkCompliance(_ sla: SLA) -> SLACompliance {
        guard let metrics = metricHistory[sla], !metrics.isEmpty else {
            return SLACompliance(
                sla: sla,
                complianceRate: 1.0,
                violations: [],
                currentStatus: .compliant,
                trend: .stable
            )
        }

        let periodMetrics = getMetricsForPeriod(metrics, period: sla.period)
        let slaViolations = periodMetrics.filter { !$0.withinSLA }
        let complianceRate = 1.0 - (Double(slaViolations.count) / Double(periodMetrics.count))

        let currentStatus: ComplianceStatus
        if complianceRate >= 0.95 {
            currentStatus = .compliant
        } else if complianceRate >= 0.85 {
            currentStatus = .atRisk
        } else {
            currentStatus = .nonCompliant
        }

        let trend = calculateTrend(for: sla)

        return SLACompliance(
            sla: sla,
            complianceRate: complianceRate,
            violations: slaViolations.compactMap { violation in
                SLAViolation(
                    sla: sla,
                    actualValue: violation.actualValue,
                    targetValue: violation.targetValue,
                    severity: .minor,
                    timestamp: violation.timestamp,
                    resolved: false,
                    resolutionTime: nil
                )
            },
            currentStatus: currentStatus,
            trend: trend
        )
    }

    /// Report an SLA violation
    public func reportViolation(_ violation: SLAViolation) {
        DispatchQueue.main.async {
            self.violations.append(violation)
        }

        violationHistory.append(violation)

        // Send alert for critical violations
        if violation.severity == .critical {
            Task {
                let alert = Alert(
                    type: .performanceDegradation,
                    severity: .critical,
                    title: "SLA Violation: \(violation.sla.name)",
                    message: "\(violation.sla.name) violated with value \(violation.actualValue) (target: \(violation.targetValue))",
                    source: "SLAMonitor",
                    context: [
                        "slaName": violation.sla.name,
                        "actualValue": "\(violation.actualValue)",
                        "targetValue": "\(violation.targetValue)",
                        "variance": "\(violation.actualValue - violation.targetValue)"
                    ]
                )

                try? await alertRouter.routeAlert(alert)
            }
        }

        // Store violation
        Task {
            await storage.saveViolation(violation)
        }
    }

    /// Generate comprehensive SLA report for a period
    public func generateSLAReport(for period: DateInterval) -> SLAReport {
        var slaCompliances: [SLACompliance] = []

        for sla in slas {
            let compliance = checkCompliance(sla)
            slaCompliances.append(compliance)
        }

        let totalViolations = slaCompliances.reduce(0) { $0 + $1.violations.count }
        let overallCompliance = slaCompliances.reduce(0.0) { $0 + $1.complianceRate } / Double(slaCompliances.count)

        let recommendations = generateRecommendations(slaCompliances)

        return SLAReport(
            period: period,
            slas: slaCompliances,
            overallCompliance: overallCompliance,
            totalViolations: totalViolations,
            recommendations: recommendations
        )
    }

    /// Add a new SLA to monitor
    public func addSLA(_ sla: SLA) {
        slas.append(sla)
        Task {
            await storage.saveSLA(sla)
        }
    }

    /// Remove an SLA
    public func removeSLA(id: String) {
        slas.removeAll { $0.id.uuidString == id }
        Task {
            await storage.deleteSLA(id: id)
        }
    }

    /// Get all SLAs
    public func getSLAs() -> [SLA] {
        return slas
    }

    /// Get SLA by ID
    public func getSLA(id: String) -> SLA? {
        return slas.first { $0.id.uuidString == id }
    }

    /// Get current metrics for a specific SLA
    public func getMetrics(for sla: SLA) -> [SLAMetric] {
        return metricHistory[sla] ?? []
    }

    /// Get compliance trend over time
    public func getComplianceTrend(for sla: SLA, days: Int = 30) -> [ComplianceDataPoint] {
        guard let metrics = metricHistory[sla] else {
            return []
        }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        var dataPoints: [ComplianceDataPoint] = []

        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: day, to: startDate) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayMetrics = metrics.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let compliantCount = dayMetrics.filter { $0.withinSLA }.count
            let complianceRate = dayMetrics.isEmpty ? 1.0 : Double(compliantCount) / Double(dayMetrics.count)

            dataPoints.append(ComplianceDataPoint(
                timestamp: dayStart,
                complianceRate: complianceRate,
                metricCount: dayMetrics.count
            ))
        }

        return dataPoints
    }

    // MARK: - Private Methods

    private func loadSLAs() {
        Task {
            let loadedSLAs = await storage.loadSLAs()

            await MainActor.run {
                if loadedSLAs.isEmpty {
                    self.slas = Self.createDefaultSLAs()
                } else {
                    self.slas = loadedSLAs
                }
            }
        }
    }

    private func loadViolationHistory() {
        Task {
            let history = await storage.loadViolations()

            await MainActor.run {
                self.violationHistory = history
                self.violations = history.filter { !$0.resolved }
            }
        }
    }

    private func loadComplianceReports() {
        Task {
            let reports = await storage.loadComplianceReports()

            await MainActor.run {
                self.complianceReports = reports
            }
        }
    }

    private func setupPeriodicChecks() {
        // Check compliance every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performPeriodicChecks()
            }
        }
    }

    private func performPeriodicChecks() async {
        for sla in slas {
            let compliance = checkCompliance(sla)

            await MainActor.run {
                // Update or add compliance report
                if let index = complianceReports.firstIndex(where: { $0.sla.id == sla.id }) {
                    complianceReports[index] = compliance
                } else {
                    complianceReports.append(compliance)
                }
            }

            // Alert if at risk or non-compliant
            if compliance.currentStatus != .compliant {
                let alert = Alert(
                    type: .performanceDegradation,
                    severity: compliance.currentStatus == .nonCompliant ? .error : .warning,
                    title: "SLA Compliance Alert: \(sla.name)",
                    message: "\(sla.name) is \(compliance.currentStatus.rawValue) with \(Int(compliance.complianceRate * 100))% compliance",
                    source: "SLAMonitor",
                    context: [
                        "slaName": sla.name,
                        "complianceRate": "\(compliance.complianceRate)",
                        "status": compliance.currentStatus.rawValue,
                        "violations": "\(compliance.violations.count)"
                    ]
                )

                try? await alertRouter.routeAlert(alert)
            }

            // Save compliance report
            await storage.saveComplianceReport(compliance)
        }
    }

    private func checkViolation(sla: SLA, metric: SLAMetric) {
        var isViolation = false

        switch sla.target {
        case .lessThan(let target):
            isViolation = metric.actualValue > target

        case .greaterThan(let target):
            isViolation = metric.actualValue < target

        case .percentage(let target):
            isViolation = metric.actualValue < target

        case .count(let target):
            isViolation = metric.actualValue < Double(target)
        }

        if isViolation {
            let variance = metric.actualValue - metric.targetValue
            let severity = calculateSeverity(sla: sla, variance: variance)

            let violation = SLAViolation(
                sla: sla,
                actualValue: metric.actualValue,
                targetValue: metric.targetValue,
                severity: severity,
                timestamp: metric.timestamp,
                resolved: false,
                resolutionTime: nil
            )

            reportViolation(violation)
        }
    }

    private func calculateSeverity(sla: SLA, variance: Double) -> SLAViolation.ViolationSeverity {
        let percentVariance = abs(variance / sla.getTargetAsDouble())

        if percentVariance > 0.5 {
            return .critical
        } else if percentVariance > 0.25 {
            return .major
        } else {
            return .minor
        }
    }

    private func getMetricsForPeriod(_ metrics: [SLAMetric], period: SLA.SLAPeriod) -> [SLAMetric] {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date?

        switch period {
        case .daily:
            startDate = calendar.date(byAdding: .day, value: -1, to: now)
        case .weekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now)
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)
        case .quarterly:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)
        }

        guard let start = startDate else {
            return metrics
        }

        return metrics.filter { $0.timestamp >= start }
    }

    private func calculateTrend(for sla: SLA) -> ComplianceTrend {
        guard let metrics = metricHistory[sla], metrics.count >= 10 else {
            return .stable
        }

        let recentMetrics = Array(metrics.suffix(10))
        let firstHalf = recentMetrics.prefix(5)
        let secondHalf = recentMetrics.suffix(5)

        let firstHalfCompliance = firstHalf.filter { $0.withinSLA }.count
        let secondHalfCompliance = secondHalf.filter { $0.withinSLA }.count

        if secondHalfCompliance > firstHalfCompliance {
            return .improving
        } else if secondHalfCompliance < firstHalfCompliance {
            return .declining
        } else {
            return .stable
        }
    }

    private func generateRecommendations(_ compliances: [SLACompliance]) -> [String] {
        var recommendations: [String] = []

        for compliance in compliances where compliance.currentStatus != .compliant {
            switch compliance.sla.metric {
            case .testExecutionTime:
                recommendations.append("Optimize test suite to reduce execution time. Consider parallelization or test selection strategies.")

            case .testFlakiness:
                recommendations.append("Investigate and fix flaky tests. Implement retry logic and isolate unstable tests.")

            case .buildTime:
                recommendations.append("Optimize build process. Consider incremental builds, caching, and dependency management.")

            case .deploymentSuccessRate:
                recommendations.append("Review deployment pipeline. Implement blue-green deployments and improve rollback mechanisms.")

            case .meanTimeToRecovery:
                recommendations.append("Improve incident response procedures. Enhance monitoring and automate recovery processes.")

            case .uptime:
                recommendations.append("Increase system redundancy. Implement load balancing and failover mechanisms.")

            case .responseTime:
                recommendations.append("Optimize application performance. Review database queries, API calls, and caching strategies.")
            }
        }

        return recommendations
    }

    private static func createDefaultSLAs() -> [SLA] {
        return [
            // Test Execution Time SLA
            SLA(
                name: "Test Execution Time",
                description: "Maximum time for complete test suite execution",
                metric: .testExecutionTime,
                target: .lessThan(300),  // 5 minutes
                period: .daily,
                consequences: "Delayed feedback on code quality",
                owner: "QA Team"
            ),

            // Test Flakiness SLA
            SLA(
                name: "Test Flakiness Rate",
                description: "Maximum acceptable flaky test rate",
                metric: .testFlakiness,
                target: .percentage(0.05),  // 5%
                period: .weekly,
                consequences: "Unreliable test results and wasted debugging time",
                owner: "QA Team"
            ),

            // Build Time SLA
            SLA(
                name: "Build Time",
                description: "Maximum time for complete build process",
                metric: .buildTime,
                target: .lessThan(600),  // 10 minutes
                period: .daily,
                consequences: "Slower development cycle",
                owner: "DevOps Team"
            ),

            // Deployment Success Rate SLA
            SLA(
                name: "Deployment Success Rate",
                description: "Minimum successful deployment rate",
                metric: .deploymentSuccessRate,
                target: .percentage(0.95),  // 95%
                period: .monthly,
                consequences: "Production instability and rollback frequency",
                owner: "DevOps Team"
            ),

            // Mean Time To Recovery SLA
            SLA(
                name: "Mean Time To Recovery (MTTR)",
                description: "Maximum average time to recover from incidents",
                metric: .meanTimeToRecovery,
                target: .lessThan(1800),  // 30 minutes
                period: .monthly,
                consequences: "Extended downtime and user impact",
                owner: "Operations Team"
            ),

            // Uptime SLA
            SLA(
                name: "System Uptime",
                description: "Minimum system availability",
                metric: .uptime,
                target: .percentage(0.99),  // 99%
                period: .monthly,
                consequences: "Service unavailability and user dissatisfaction",
                owner: "Operations Team"
            ),

            // Response Time SLA
            SLA(
                name: "API Response Time",
                description: "Maximum average API response time",
                metric: .responseTime,
                target: .lessThan(0.5),  // 500ms
                period: .weekly,
                consequences: "Poor user experience and slow application performance",
                owner: "Engineering Team"
            )
        ]
    }
}

// MARK: - SLA

public struct SLA: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let metric: SLAMetricType
    public let target: SLATarget
    public let period: SLAPeriod
    public let consequences: String
    public let owner: String

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        metric: SLAMetricType,
        target: SLATarget,
        period: SLAPeriod,
        consequences: String,
        owner: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.metric = metric
        self.target = target
        self.period = period
        self.consequences = consequences
        self.owner = owner
    }

    public enum SLAMetricType: String, Codable {
        case testExecutionTime = "Test Execution Time"
        case testFlakiness = "Test Flakiness"
        case buildTime = "Build Time"
        case deploymentSuccessRate = "Deployment Success Rate"
        case meanTimeToRecovery = "Mean Time To Recovery"
        case uptime = "Uptime"
        case responseTime = "Response Time"
    }

    public enum SLATarget: Codable {
        case lessThan(TimeInterval)
        case greaterThan(TimeInterval)
        case percentage(Double)
        case count(Int)

        public func getTargetAsDouble() -> Double {
            switch self {
            case .lessThan(let value):
                return value
            case .greaterThan(let value):
                return value
            case .percentage(let value):
                return value
            case .count(let value):
                return Double(value)
            }
        }
    }

    public enum SLAPeriod: String, Codable {
        case daily
        case weekly
        case monthly
        case quarterly
    }
}

// MARK: - SLA Metric

public struct SLAMetric: Identifiable, Codable {
    public let id: UUID
    public let type: SLA.SLAMetricType
    public let actualValue: Double
    public let targetValue: Double
    public let timestamp: Date
    public let withinSLA: Bool
    public let variance: Double

    public init(
        id: UUID = UUID(),
        type: SLA.SLAMetricType,
        actualValue: Double,
        targetValue: Double,
        timestamp: Date = Date(),
        withinSLA: Bool,
        variance: Double
    ) {
        self.id = id
        self.type = type
        self.actualValue = actualValue
        self.targetValue = targetValue
        self.timestamp = timestamp
        self.withinSLA = withinSLA
        self.variance = variance
    }
}

// MARK: - SLA Compliance

public struct SLACompliance: Identifiable, Codable {
    public let id: UUID
    public let sla: SLA
    public let complianceRate: Double
    public let violations: [SLAViolation]
    public let currentStatus: ComplianceStatus
    public let trend: ComplianceTrend

    public init(
        id: UUID = UUID(),
        sla: SLA,
        complianceRate: Double,
        violations: [SLAViolation],
        currentStatus: ComplianceStatus,
        trend: ComplianceTrend
    ) {
        self.id = id
        self.sla = sla
        self.complianceRate = complianceRate
        self.violations = violations
        self.currentStatus = currentStatus
        self.trend = trend
    }

    public enum ComplianceStatus: String, Codable {
        case compliant
        case atRisk
        case nonCompliant
    }

    public enum ComplianceTrend: String, Codable {
        case improving
        case stable
        case declining
    }
}

// MARK: - SLA Violation

public struct SLAViolation: Identifiable, Codable {
    public let id: UUID
    public let sla: SLA
    public let actualValue: Double
    public let targetValue: Double
    public let severity: ViolationSeverity
    public let timestamp: Date
    public let resolved: Bool
    public let resolutionTime: TimeInterval?

    public init(
        id: UUID = UUID(),
        sla: SLA,
        actualValue: Double,
        targetValue: Double,
        severity: ViolationSeverity,
        timestamp: Date,
        resolved: Bool,
        resolutionTime: TimeInterval?
    ) {
        self.id = id
        self.sla = sla
        self.actualValue = actualValue
        self.targetValue = targetValue
        self.severity = severity
        self.timestamp = timestamp
        self.resolved = resolved
        self.resolutionTime = resolutionTime
    }

    public enum ViolationSeverity: String, Codable {
        case minor
        case major
        case critical
    }
}

// MARK: - SLA Report

public struct SLAReport: Codable {
    public let period: DateInterval
    public let slas: [SLACompliance]
    public let overallCompliance: Double
    public let totalViolations: Int
    public let recommendations: [String]

    public init(
        period: DateInterval,
        slas: [SLACompliance],
        overallCompliance: Double,
        totalViolations: Int,
        recommendations: [String]
    ) {
        self.period = period
        self.slas = slas
        self.overallCompliance = overallCompliance
        self.totalViolations = totalViolations
        self.recommendations = recommendations
    }
}

// MARK: - Compliance Data Point

public struct ComplianceDataPoint: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let complianceRate: Double
    public let metricCount: Int

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        complianceRate: Double,
        metricCount: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.complianceRate = complianceRate
        self.metricCount = metricCount
    }
}

// MARK: - SLA Storage

public class SLAStorage {
    public static let shared = SLAStorage()

    private init() {}

    public func saveSLA(_ sla: SLA) async {
        // In production, save to database
        print("Saving SLA: \(sla.name)")
    }

    public func loadSLAs() async -> [SLA] {
        // In production, load from database
        return []
    }

    public func deleteSLA(id: String) async {
        // In production, delete from database
        print("Deleting SLA: \(id)")
    }

    public func saveViolation(_ violation: SLAViolation) async {
        // In production, save to database
        print("Saving violation: \(violations.count)")
    }

    public func loadViolations() async -> [SLAViolation] {
        // In production, load from database
        return []
    }

    public func saveComplianceReport(_ report: SLACompliance) async {
        // In production, save to database
        print("Saving compliance report: \(report.sla.name)")
    }

    public func loadComplianceReports() async -> [SLACompliance] {
        // In production, load from database
        return []
    }
}

// MARK: - Alert Router Mock

public class AlertRouter {
    public static let shared = AlertRouter()

    private init() {}

    public func routeAlert(_ alert: Alert) async throws {
        // In production, route to actual alert system
        print("Routing alert: \(alert.title)")
    }
}

// MARK: - Alert Model

public struct Alert: Identifiable, Codable {
    public let id: UUID
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let source: String
    public let context: [String: String]

    public init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        source: String,
        context: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.source = source
        self.context = context
    }

    public enum AlertType: String, Codable {
        case testFailure
        case buildFailure
        case performanceDegradation
        case securityVulnerability
        case flakyTest
        case deploymentFailure
        case systemDown
    }

    public enum AlertSeverity: Int, Codable {
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4
    }
}
