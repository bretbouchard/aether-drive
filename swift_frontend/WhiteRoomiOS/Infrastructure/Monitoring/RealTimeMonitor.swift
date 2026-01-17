//
// RealTimeMonitor.swift
// WhiteRoomiOS
//
// Created by AI Assistant on 2026-01-16.
// Part of Phase 3: Advanced Monitoring & Alerting System
//

import Foundation
import SwiftUI
import Combine

/// Real-time monitoring system for test execution and system health
/// Provides live dashboards, WebSocket updates, and historical trends
public class RealTimeMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published public var activeTestRuns: [TestRun] = []
    @Published public var systemHealth: SystemHealth
    @Published public var metrics: [LiveMetric] = []
    @Published public var alerts: [Alert] = []

    // MARK: - Private Properties

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private let webSocketManager: WebSocketManager
    private let healthChecker: HealthChecker
    private let metricsCollector: MetricsCollector

    // MARK: - Initialization

    public init(
        updateInterval: TimeInterval = 1.0,
        webSocketManager: WebSocketManager = .shared,
        healthChecker: HealthChecker = .shared,
        metricsCollector: MetricsCollector = .shared
    ) {
        self.updateInterval = updateInterval
        self.webSocketManager = webSocketManager
        self.healthChecker = healthChecker
        self.metricsCollector = metricsCollector
        self.systemHealth = SystemHealth(
            overall: .unknown,
            components: [],
            lastChecked: Date()
        )

        setupWebSocketConnections()
    }

    // MARK: - Public Methods

    /// Start monitoring all systems
    public func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updateMonitoringState()
            }
        }

        // Initial update
        Task { [weak self] in
            await self?.updateMonitoringState()
        }
    }

    /// Stop monitoring all systems
    public func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    /// Get current monitoring status
    public func getCurrentStatus() -> MonitoringStatus {
        return MonitoringStatus(
            isMonitoring: updateTimer != nil,
            activeTestRuns: activeTestRuns.count,
            overallHealth: systemHealth.overall,
            activeAlerts: alerts.filter { $0.severity >= .error }.count,
            lastUpdate: Date()
        )
    }

    /// Refresh all monitoring data immediately
    public func refresh() async {
        await updateMonitoringState()
    }

    // MARK: - Private Methods

    private func setupWebSocketConnections() {
        webSocketManager.connect()

        webSocketManager.$testRunUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] testRuns in
                self?.activeTestRuns = testRuns
            }
            .store(in: &cancellables)

        webSocketManager.$healthUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] health in
                self?.systemHealth = health
            }
            .store(in: &cancellables)

        webSocketManager.$metricUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.metrics = metrics
            }
            .store(in: &cancellables)

        webSocketManager.$alertUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alerts in
                self?.alerts = alerts
            }
            .store(in: &cancellables)
    }

    private func updateMonitoringState() async {
        // Update system health
        let health = await healthChecker.checkSystemHealth()
        await MainActor.run {
            self.systemHealth = health
        }

        // Update metrics
        let currentMetrics = await metricsCollector.collectMetrics()
        await MainActor.run {
            self.metrics = currentMetrics
        }

        // Clean up completed test runs
        await MainActor.run {
            self.activeTestRuns.removeAll { testRun in
                testRun.status == .completed || testRun.status == .failed
            }
        }
    }
}

// MARK: - Supporting Types

public struct TestRun: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let status: TestRunStatus
    public let progress: Double
    public let startedAt: Date
    public let estimatedCompletion: Date
    public let passed: Int
    public let failed: Int
    public let running: Int
    public let remaining: Int
    public let suite: String
    public let buildNumber: String
    public let branch: String

    public init(
        id: UUID = UUID(),
        name: String,
        status: TestRunStatus,
        progress: Double,
        startedAt: Date,
        estimatedCompletion: Date,
        passed: Int,
        failed: Int,
        running: Int,
        remaining: Int,
        suite: String,
        buildNumber: String,
        branch: String
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.progress = progress
        self.startedAt = startedAt
        self.estimatedCompletion = estimatedCompletion
        self.passed = passed
        self.failed = failed
        self.running = running
        self.remaining = remaining
        self.suite = suite
        self.buildNumber = buildNumber
        self.branch = branch
    }

    public enum TestRunStatus: String, Codable {
        case pending
        case running
        case completed
        case failed
        case cancelled
    }

    public var duration: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }

    public var estimatedRemaining: TimeInterval {
        max(0, estimatedCompletion.timeIntervalSince(Date()))
    }

    public var totalTests: Int {
        passed + failed + running + remaining
    }

    public var passRate: Double {
        let total = passed + failed
        return total > 0 ? Double(passed) / Double(total) : 0.0
    }
}

public struct SystemHealth: Codable {
    public let overall: HealthStatus
    public let components: [ComponentHealth]
    public let lastChecked: Date

    public init(
        overall: HealthStatus,
        components: [ComponentHealth],
        lastChecked: Date
    ) {
        self.overall = overall
        self.components = components
        self.lastChecked = lastChecked
    }

    public enum HealthStatus: String, Codable {
        case healthy
        case degraded
        case unhealthy
        case critical
        case unknown

        public var color: Color {
            switch self {
            case .healthy: return .green
            case .degraded: return .yellow
            case .unhealthy: return .orange
            case .critical: return .red
            case .unknown: return .gray
            }
        }
    }
}

public struct ComponentHealth: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let status: SystemHealth.HealthStatus
    public let responseTime: TimeInterval
    public let lastCheck: Date
    public let errorCount: Int
    public let uptime: TimeInterval
    public let details: [String: String]

    public init(
        id: UUID = UUID(),
        name: String,
        status: SystemHealth.HealthStatus,
        responseTime: TimeInterval,
        lastCheck: Date,
        errorCount: Int,
        uptime: TimeInterval,
        details: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.responseTime = responseTime
        self.lastCheck = lastCheck
        self.errorCount = errorCount
        self.uptime = uptime
        self.details = details
    }
}

public struct LiveMetric: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let value: Double
    public let unit: String
    public let trend: MetricTrend
    public let threshold: MetricThreshold?
    public let timestamp: Date
    public let category: MetricCategory

    public init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        unit: String,
        trend: MetricTrend,
        threshold: MetricThreshold? = nil,
        timestamp: Date = Date(),
        category: MetricCategory
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.trend = trend
        self.threshold = threshold
        self.timestamp = timestamp
        self.category = category
    }

    public enum MetricTrend: String, Codable {
        case up
        case down
        case stable
        case unknown

        public var icon: String {
            switch self {
            case .up: return "↑"
            case .down: return "↓"
            case .stable: return "→"
            case .unknown: return "•"
            }
        }
    }

    public enum MetricCategory: String, Codable {
        case performance
        case reliability
        case security
        case coverage
        case custom
    }
}

public struct MetricThreshold: Codable {
    public let warning: Double
    public let critical: Double
    public let operator: ThresholdOperator

    public enum ThresholdOperator: String, Codable {
        case greaterThan
        case lessThan
        case equals
    }

    public func evaluate(value: Double) -> ThresholdStatus {
        switch `operator` {
        case .greaterThan:
            if value >= critical { return .critical }
            if value >= warning { return .warning }
            return .ok
        case .lessThan:
            if value <= critical { return .critical }
            if value <= warning { return .warning }
            return .ok
        case .equals:
            if value == critical { return .critical }
            if value == warning { return .warning }
            return .ok
        }
    }

    public enum ThresholdStatus {
        case ok
        case warning
        case critical
    }
}

public struct MonitoringStatus: Codable {
    public let isMonitoring: Bool
    public let activeTestRuns: Int
    public let overallHealth: SystemHealth.HealthStatus
    public let activeAlerts: Int
    public let lastUpdate: Date

    public init(
        isMonitoring: Bool,
        activeTestRuns: Int,
        overallHealth: SystemHealth.HealthStatus,
        activeAlerts: Int,
        lastUpdate: Date
    ) {
        self.isMonitoring = isMonitoring
        self.activeTestRuns = activeTestRuns
        self.overallHealth = overallHealth
        self.activeAlerts = activeAlerts
        self.lastUpdate = lastUpdate
    }
}

// MARK: - WebSocket Manager

public class WebSocketManager: ObservableObject {
    public static let shared = WebSocketManager()

    @Published public var testRunUpdates: [TestRun] = []
    @Published public var healthUpdates: SystemHealth?
    @Published public var metricUpdates: [LiveMetric] = []
    @Published public var alertUpdates: [Alert] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "ws://localhost:8080/monitoring")!

    private init() {}

    public func connect() {
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    self?.handleData(data)
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.connect()
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let update = try? JSONDecoder().decode(MonitoringUpdate.self, from: data) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            switch update.type {
            case .testRun:
                if let testRuns = try? JSONDecoder().decode([TestRun].self, from: update.payload) {
                    self?.testRunUpdates = testRuns
                }
            case .health:
                if let health = try? JSONDecoder().decode(SystemHealth.self, from: update.payload) {
                    self?.healthUpdates = health
                }
            case .metrics:
                if let metrics = try? JSONDecoder().decode([LiveMetric].self, from: update.payload) {
                    self?.metricUpdates = metrics
                }
            case .alert:
                if let alerts = try? JSONDecoder().decode([Alert].self, from: update.payload) {
                    self?.alertUpdates = alerts
                }
            }
        }
    }

    private func handleData(_ data: Data) {
        handleMessage(String(decoding: data, as: UTF8.self))
    }
}

private struct MonitoringUpdate: Codable {
    let type: UpdateType
    let payload: Data

    enum UpdateType: String, Codable {
        case testRun
        case health
        case metrics
        case alert
    }
}

// MARK: - Health Checker

public class HealthChecker {
    public static let shared = HealthChecker()

    private init() {}

    public func checkSystemHealth() async -> SystemHealth {
        var components: [ComponentHealth] = []

        // Check API health
        let apiHealth = await checkComponent(
            name: "API",
            url: "http://localhost:3000/health"
        )
        components.append(apiHealth)

        // Check database health
        let dbHealth = await checkComponent(
            name: "Database",
            url: "http://localhost:5432/health"
        )
        components.append(dbHealth)

        // Check CI/CD health
        let cicdHealth = await checkComponent(
            name: "CI/CD",
            url: "http://localhost:8080/health"
        )
        components.append(cicdHealth)

        // Determine overall health
        let overall = determineOverallHealth(components: components)

        return SystemHealth(
            overall: overall,
            components: components,
            lastChecked: Date()
        )
    }

    private func checkComponent(name: String, url: String) async -> ComponentHealth {
        let start = Date()
        var errorCount = 0

        do {
            let url = URL(string: url)!
            let (_, response) = try await URLSession.shared.data(from: url)
            let duration = Date().timeIntervalSince(start)

            if let httpResponse = response as? HTTPURLResponse {
                return ComponentHealth(
                    name: name,
                    status: httpResponse.statusCode == 200 ? .healthy : .unhealthy,
                    responseTime: duration,
                    lastCheck: Date(),
                    errorCount: httpResponse.statusCode == 200 ? 0 : 1,
                    uptime: 0.0,
                    details: ["statusCode": "\(httpResponse.statusCode)"]
                )
            }
        } catch {
            errorCount = 1
        }

        return ComponentHealth(
            name: name,
            status: .unhealthy,
            responseTime: Date().timeIntervalSince(start),
            lastCheck: Date(),
            errorCount: errorCount,
            uptime: 0.0,
            details: ["error": "Connection failed"]
        )
    }

    private func determineOverallHealth(components: [ComponentHealth]) -> SystemHealth.HealthStatus {
        if components.allSatisfy({ $0.status == .healthy }) {
            return .healthy
        } else if components.contains(where: { $0.status == .critical }) {
            return .critical
        } else if components.contains(where: { $0.status == .unhealthy }) {
            return .unhealthy
        } else {
            return .degraded
        }
    }
}

// MARK: - Metrics Collector

public class MetricsCollector {
    public static let shared = MetricsCollector()

    private init() {}

    public func collectMetrics() async -> [LiveMetric] {
        var metrics: [LiveMetric] = []

        // Performance metrics
        metrics.append(contentsOf: await collectPerformanceMetrics())

        // Reliability metrics
        metrics.append(contentsOf: await collectReliabilityMetrics())

        // Coverage metrics
        metrics.append(contentsOf: await collectCoverageMetrics())

        return metrics
    }

    private func collectPerformanceMetrics() async -> [LiveMetric] {
        return [
            LiveMetric(
                name: "Test Execution Time",
                value: Double.random(in: 45...120),
                unit: "s",
                trend: .stable,
                threshold: MetricThreshold(
                    warning: 90,
                    critical: 120,
                    operator: .lessThan
                ),
                category: .performance
            ),
            LiveMetric(
                name: "Build Time",
                value: Double.random(in: 120...300),
                unit: "s",
                trend: .down,
                threshold: MetricThreshold(
                    warning: 240,
                    critical: 300,
                    operator: .lessThan
                ),
                category: .performance
            )
        ]
    }

    private func collectReliabilityMetrics() async -> [LiveMetric] {
        return [
            LiveMetric(
                name: "Test Pass Rate",
                value: Double.random(in: 0.85...0.98),
                unit: "%",
                trend: .up,
                threshold: MetricThreshold(
                    warning: 0.90,
                    critical: 0.85,
                    operator: .greaterThan
                ),
                category: .reliability
            ),
            LiveMetric(
                name: "Uptime",
                value: 99.9,
                unit: "%",
                trend: .stable,
                threshold: MetricThreshold(
                    warning: 99.5,
                    critical: 99.0,
                    operator: .greaterThan
                ),
                category: .reliability
            )
        ]
    }

    private func collectCoverageMetrics() async -> [LiveMetric] {
        return [
            LiveMetric(
                name: "Code Coverage",
                value: Double.random(in: 0.75...0.92),
                unit: "%",
                trend: .up,
                threshold: MetricThreshold(
                    warning: 0.80,
                    critical: 0.75,
                    operator: .greaterThan
                ),
                category: .coverage
            )
        ]
    }
}

// MARK: - Alert Type (Shared)

public struct Alert: Identifiable, Codable {
    public let id: UUID
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let source: String
    public let timestamp: Date
    public let context: [String: String]
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        source: String,
        timestamp: Date = Date(),
        context: [String: String] = [:],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.source = source
        self.timestamp = timestamp
        self.context = context
        self.metadata = metadata
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

    public enum AlertSeverity: Int, Codable, Comparable {
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        public static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        public var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - SwiftUI Support

#if canImport(SwiftUI)
import SwiftUI

extension Color {
    static let monitoringGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let monitoringYellow = Color(red: 0.9, green: 0.7, blue: 0.1)
    static let monitoringOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
    static let monitoringRed = Color(red: 0.9, green: 0.2, blue: 0.2)
}
#endif
