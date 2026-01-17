//
// HealthCheckEndpoint.swift
// WhiteRoomiOS
//
// Created by AI Assistant on 2026-01-16.
// Part of Phase 3: Advanced Monitoring & Alerting System
//

import Foundation

/// Health check system for monitoring component availability and performance
/// Provides HTTP endpoints for health monitoring and status reporting
public class HealthCheckEndpoint: ObservableObject {

    // MARK: - Published Properties

    @Published public var latestReport: HealthCheckReport?
    @Published public var isChecking: Bool = false

    // MARK: - Private Properties

    private let config: HealthCheckConfig
    private let urlSession: URLSession
    private var healthCheckResults: [String: ComponentHealth] = [:]

    // MARK: - Initialization

    public init(
        config: HealthCheckConfig = .default,
        urlSession: URLSession = .shared
    ) {
        self.config = config
        self.urlSession = urlSession
    }

    // MARK: - Public Methods

    /// Perform health checks on all configured endpoints
    public func performHealthChecks() async throws -> HealthCheckReport {
        await MainActor.run {
            self.isChecking = true
        }

        defer {
            Task { @MainActor in
                self.isChecking = false
            }
        }

        var components: [String: ComponentHealth] = [:]
        let startTime = Date()

        // Check each endpoint concurrently
        await withTaskGroup(of: (String, ComponentHealth).self) { group in
            for endpoint in config.endpoints {
                group.addTask {
                    let health = await self.checkEndpoint(endpoint)
                    return (endpoint.name, health)
                }
            }

            for await (name, health) in group {
                components[name] = health
                healthCheckResults[name] = health
            }
        }

        // Determine overall status
        let overallStatus = determineOverallStatus(components: components)
        let duration = Date().timeIntervalSince(startTime)

        let report = HealthCheckReport(
            status: overallStatus,
            timestamp: Date(),
            components: components,
            uptime: calculateUptime(),
            version: getVersion(),
            duration: duration
        )

        await MainActor.run {
            self.latestReport = report
        }

        return report
    }

    /// Check a specific component
    public func checkComponent(_ component: String) async throws -> ComponentHealth {
        guard let endpoint = config.endpoints.first(where: { $0.name == component }) else {
            throw HealthCheckError.componentNotFound(component)
        }

        return await checkEndpoint(endpoint)
    }

    /// Get health check report as JSON
    public func getReportAsJSON() async throws -> Data {
        guard let report = latestReport else {
            throw HealthCheckError.noReportAvailable
        }

        return try JSONEncoder().encode(report)
    }

    /// Start scheduled health checks
    public func startScheduledChecks() {
        Task {
            while true {
                try? await performHealthChecks()
                try? await Task.sleep(nanoseconds: UInt64(config.interval * 1_000_000_000))
            }
        }
    }

    /// Get current health status summary
    public func getHealthSummary() -> HealthSummary {
        guard let report = latestReport else {
            return HealthSummary(
                status: .unknown,
                healthyComponents: 0,
                unhealthyComponents: 0,
                lastCheck: nil
            )
        }

        let healthyCount = report.components.values.filter { $0.status == .pass }.count
        let unhealthyCount = report.components.values.filter { $0.status != .pass }.count

        return HealthSummary(
            status: report.status,
            healthyComponents: healthyCount,
            unhealthyComponents: unhealthyCount,
            lastCheck: report.timestamp
        )
    }

    // MARK: - Private Methods

    private func checkEndpoint(_ endpoint: HealthEndpoint) async -> ComponentHealth {
        let startTime = Date()
        var details: [String: String] = [:]
        var metrics: [String: Double] = [:]

        var attempt = 0
        var lastError: Error?

        while attempt < config.retries {
            do {
                let result = try await performRequest(endpoint)
                let duration = Date().timeIntervalSince(startTime)

                details["statusCode"] = "\(result.statusCode)"
                details["attempt"] = "\(attempt + 1)"
                metrics["responseTime"] = duration
                metrics["responseSize"] = Double(result.data?.count ?? 0)

                let status: ComponentStatus = result.statusCode == endpoint.expectedStatus ? .pass : .fail

                return ComponentHealth(
                    status: status,
                    responseTime: duration,
                    lastCheck: Date(),
                    details: details,
                    metrics: metrics
                )

            } catch {
                lastError = error
                attempt += 1

                if attempt < config.retries {
                    // Exponential backoff
                    let delay = UInt64(pow(2.0, Double(attempt)) * 100_000_000) // 100ms base
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        // All retries failed
        let duration = Date().timeIntervalSince(startTime)
        details["error"] = lastError?.localizedDescription ?? "Unknown error"
        details["attempts"] = "\(config.retries)"

        return ComponentHealth(
            status: .fail,
            responseTime: duration,
            lastCheck: Date(),
            details: details,
            metrics: metrics
        )
    }

    private func performRequest(_ endpoint: HealthEndpoint) async throws -> RequestResult {
        guard let url = URL(string: endpoint.url) else {
            throw HealthCheckError.invalidURL(endpoint.url)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let startTime = Date()
        let (data, response) = try await urlSession.data(for: request)
        let duration = Date().timeIntervalSince(startTime)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthCheckError.invalidResponse
        }

        return RequestResult(
            statusCode: httpResponse.statusCode,
            data: data,
            duration: duration
        )
    }

    private func determineOverallStatus(components: [String: ComponentHealth]) -> OverallStatus {
        guard !components.isEmpty else {
            return .fail
        }

        let statuses = components.values.map { $0.status }

        if statuses.allSatisfy({ $0 == .pass }) {
            return .pass
        } else if statuses.contains(where: { $0 == .fail }) {
            return .fail
        } else {
            return .degrade
        }
    }

    private func calculateUptime() -> TimeInterval {
        // In production, calculate from historical data
        // For now, return system uptime
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        let uptime = Double(mach_absolute_time()) * Double(info.numer) / Double(info.denom) / 1_000_000_000
        return uptime
    }

    private func getVersion() -> String {
        // In production, read from app bundle or config
        return "1.0.0"
    }
}

// MARK: - Health Check Report

public struct HealthCheckReport: Codable {
    public let status: OverallStatus
    public let timestamp: Date
    public let components: [String: ComponentHealth]
    public let uptime: TimeInterval
    public let version: String
    public let duration: TimeInterval

    public init(
        status: OverallStatus,
        timestamp: Date,
        components: [String: ComponentHealth],
        uptime: TimeInterval,
        version: String,
        duration: TimeInterval
    ) {
        self.status = status
        self.timestamp = timestamp
        self.components = components
        self.uptime = uptime
        self.version = version
        self.duration = duration
    }

    public enum OverallStatus: String, Codable {
        case pass
        case fail
        case degrade
    }
}

// MARK: - Component Health

public struct ComponentHealth: Codable {
    public let status: ComponentStatus
    public let responseTime: TimeInterval
    public let lastCheck: Date
    public let details: [String: String]
    public let metrics: [String: Double]

    public init(
        status: ComponentStatus,
        responseTime: TimeInterval,
        lastCheck: Date,
        details: [String: String] = [:],
        metrics: [String: Double] = [:]
    ) {
        self.status = status
        self.responseTime = responseTime
        self.lastCheck = lastCheck
        self.details = details
        self.metrics = metrics
    }

    public enum ComponentStatus: String, Codable {
        case pass
        case fail
        case warn
    }
}

// MARK: - Health Check Configuration

public struct HealthCheckConfig {
    public let endpoints: [HealthEndpoint]
    public let interval: TimeInterval
    public let timeout: TimeInterval
    public let retries: Int

    public init(
        endpoints: [HealthEndpoint],
        interval: TimeInterval = 60,
        timeout: TimeInterval = 10,
        retries: Int = 3
    ) {
        self.endpoints = endpoints
        self.interval = interval
        self.timeout = timeout
        self.retries = retries
    }

    public static var `default`: HealthCheckConfig {
        return HealthCheckConfig(
            endpoints: [
                // API Health
                HealthEndpoint(
                    name: "API",
                    url: "http://localhost:3000/health",
                    method: .get,
                    expectedStatus: 200,
                    timeout: 5,
                    headers: [:]
                ),

                // Database Health
                HealthEndpoint(
                    name: "Database",
                    url: "http://localhost:5432/health",
                    method: .get,
                    expectedStatus: 200,
                    timeout: 5,
                    headers: [:]
                ),

                // CI/CD Health
                HealthEndpoint(
                    name: "CI/CD",
                    url: "http://localhost:8080/health",
                    method: .get,
                    expectedStatus: 200,
                    timeout: 5,
                    headers: [:]
                ),

                // Monitoring Health
                HealthEndpoint(
                    name: "Monitoring",
                    url: "http://localhost:9090/health",
                    method: .get,
                    expectedStatus: 200,
                    timeout: 5,
                    headers: [:]
                ),

                // Analytics Health
                HealthEndpoint(
                    name: "Analytics",
                    url: "http://localhost:6060/health",
                    method: .get,
                    expectedStatus: 200,
                    timeout: 5,
                    headers: [:]
                )
            ],
            interval: 60,
            timeout: 10,
            retries: 3
        )
    }
}

// MARK: - Health Endpoint

public struct HealthEndpoint: Codable {
    public let name: String
    public let url: String
    public let method: HTTPMethod
    public let expectedStatus: Int
    public let timeout: TimeInterval
    public let headers: [String: String]

    public init(
        name: String,
        url: String,
        method: HTTPMethod,
        expectedStatus: Int,
        timeout: TimeInterval,
        headers: [String: String]
    ) {
        self.name = name
        self.url = url
        self.method = method
        self.expectedStatus = expectedStatus
        self.timeout = timeout
        self.headers = headers
    }
}

public enum HTTPMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}

// MARK: - Health Summary

public struct HealthSummary {
    public let status: HealthCheckReport.OverallStatus
    public let healthyComponents: Int
    public let unhealthyComponents: Int
    public let lastCheck: Date?

    public init(
        status: HealthCheckReport.OverallStatus,
        healthyComponents: Int,
        unhealthyComponents: Int,
        lastCheck: Date?
    ) {
        self.status = status
        self.healthyComponents = healthyComponents
        self.unhealthyComponents = unhealthyComponents
        self.lastCheck = lastCheck
    }
}

// MARK: - Request Result

private struct RequestResult {
    let statusCode: Int
    let data: Data?
    let duration: TimeInterval
}

// MARK: - Health Check Error

public enum HealthCheckError: Error, LocalizedError {
    case componentNotFound(String)
    case noReportAvailable
    case invalidURL(String)
    case invalidResponse
    case timeout

    public var errorDescription: String? {
        switch self {
        case .componentNotFound(let name):
            return "Component not found: \(name)"
        case .noReportAvailable:
            return "No health check report available"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .timeout:
            return "Health check timed out"
        }
    }
}

// MARK: - HTTP Health Check Server

/// Simple HTTP server for health check endpoints
public class HealthCheckServer {
    private var listener: NWListener?
    private let port: UInt16
    private let healthCheckEndpoint: HealthCheckEndpoint

    public init(
        port: UInt16 = 9090,
        healthCheckEndpoint: HealthCheckEndpoint = .init()
    ) {
        self.port = port
        self.healthCheckEndpoint = healthCheckEndpoint
    }

    public func start() throws {
        let config = NWParameters.tcp
        config.allowLocalEndpointReuse = true
        config.allowFastOpen = true

        listener = try NWListener(using: config, on: NWEndpoint.Port(rawValue: port)!)

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: .main)
        print("Health check server started on port \(port)")
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, let request = String(data: data, encoding: .utf8) {
                if request.contains("GET /health") {
                    Task {
                        let report = try? await self?.healthCheckEndpoint.performHealthChecks()
                        let responseData = try? JSONEncoder().encode(report)

                        if let responseData = responseData {
                            let response = "HTTP/1.1 200 OK\r\n" +
                                "Content-Type: application/json\r\n" +
                                "Content-Length: \(responseData.count)\r\n" +
                                "\r\n" +
                                String(data: responseData, encoding: .utf8)!

                            if let responseBytes = response.data(using: .utf8) {
                                connection.send(content: responseBytes, completion: .contentProcessed { _ in
                                    connection.cancel()
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Network Framework Support

#if canImport(Network)
import Network

extension HealthCheckServer {
    // NWListener and NWConnection are available when Network framework is imported
}
#endif

// MARK: - CLI Health Check Tool

public class HealthCheckCLI {
    private let healthCheckEndpoint: HealthCheckEndpoint

    public init(healthCheckEndpoint: HealthCheckEndpoint = .init()) {
        self.healthCheckEndpoint = healthCheckEndpoint
    }

    public func run() async throws {
        let report = try await healthCheckEndpoint.performHealthChecks()

        print("Health Check Report")
        print("==================")
        print("Status: \(report.status.rawValue.uppercased())")
        print("Timestamp: \(report.timestamp)")
        print("Version: \(report.version)")
        print("Duration: \(String(format: "%.3f", report.duration))s")
        print("Uptime: \(String(format: "%.0f", report.uptime))s")
        print()

        print("Components:")
        for (name, health) in report.components.sorted(by: { $0.key < $1.key }) {
            let statusIcon = health.status == .pass ? "✓" : "✗"
            print("  \(statusIcon) \(name): \(health.status.rawValue) (\(String(format: "%.3f", health.responseTime))s)")

            if !health.details.isEmpty {
                for (key, value) in health.details.sorted(by: { $0.key < $1.key }) {
                    print("      \(key): \(value)")
                }
            }
        }

        print()
        print("Summary:")
        let healthy = report.components.values.filter { $0.status == .pass }.count
        let total = report.components.count
        print("  \(healthy)/\(total) components healthy")

        // Exit with appropriate code
        exit(report.status == .pass ? 0 : 1)
    }

    public func watch(interval: TimeInterval = 60) async {
        while true {
            do {
                try await run()
            } catch {
                print("Health check failed: \(error)")
            }

            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }
}

// MARK: - Export for testing

extension HealthCheckEndpoint {
    public static func createTestReport() -> HealthCheckReport {
        return HealthCheckReport(
            status: .pass,
            timestamp: Date(),
            components: [
                "API": ComponentHealth(
                    status: .pass,
                    responseTime: 0.045,
                    lastCheck: Date(),
                    details: ["statusCode": "200"],
                    metrics: ["responseTime": 0.045]
                ),
                "Database": ComponentHealth(
                    status: .pass,
                    responseTime: 0.012,
                    lastCheck: Date(),
                    details: ["statusCode": "200"],
                    metrics: ["responseTime": 0.012]
                ),
                "CI/CD": ComponentHealth(
                    status: .pass,
                    responseTime: 0.078,
                    lastCheck: Date(),
                    details: ["statusCode": "200"],
                    metrics: ["responseTime": 0.078]
                )
            ],
            uptime: 3600,
            version: "1.0.0",
            duration: 0.135
        )
    }
}
