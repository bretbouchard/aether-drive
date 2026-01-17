//
// AlertRouter.swift
// WhiteRoomiOS
//
// Created by AI Assistant on 2026-01-16.
// Part of Phase 3: Advanced Monitoring & Alerting System
//

import Foundation
import Combine

/// Intelligent alert routing system with rule-based matching, severity escalation, and multi-destination support
public class AlertRouter: ObservableObject {

    // MARK: - Published Properties

    @Published public var alertRules: [AlertRule] = []
    @Published public var routingHistory: [RoutedAlert] = []
    @Published public var isRouting: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let emailService: EmailService
    private let slackService: SlackService
    private let smsService: SMSService
    private let pagerDutyService: PagerDutyService
    private let webhookService: WebhookService
    private var recentAlerts: [String: Date] = [:]  // For deduplication and cooldown

    // MARK: - Initialization

    public init(
        emailService: EmailService = .shared,
        slackService: SlackService = .shared,
        smsService: SMSService = .shared,
        pagerDutyService: PagerDutyService = .shared,
        webhookService: WebhookService = .shared
    ) {
        self.emailService = emailService
        self.slackService = slackService
        self.smsService = smsService
        self.pagerDutyService = pagerDutyService
        self.webhookService = webhookService

        loadDefaultRules()
    }

    // MARK: - Public Methods

    /// Add a new alert routing rule
    public func addRule(_ rule: AlertRule) {
        alertRules.append(rule)
        saveRules()
    }

    /// Remove an alert routing rule
    public func removeRule(id: String) {
        alertRules.removeAll { $0.id.uuidString == id }
        saveRules()
    }

    /// Update an existing rule
    public func updateRule(_ rule: AlertRule) {
        if let index = alertRules.firstIndex(where: { $0.id == rule.id }) {
            alertRules[index] = rule
            saveRules()
        }
    }

    /// Route an alert to appropriate destinations based on rules
    public func routeAlert(_ alert: Alert) async throws {
        await MainActor.run {
            self.isRouting = true
        }

        defer {
            Task { @MainActor in
                self.isRouting = false
            }
        }

        // Check cooldown/deduplication
        if let lastSent = recentAlerts[alert.id.uuidString] {
            let cooldown = findCooldownPeriod(for: alert)
            if Date().timeIntervalSince(lastSent) < cooldown {
                print("Alert \(alert.id) is in cooldown, skipping")
                return
            }
        }

        // Find matching rules
        let matchingRules = alertRules.filter { $0.matches(alert) && $0.enabled }

        guard !matchingRules.isEmpty else {
            throw AlertRouterError.noMatchingRules
        }

        // Route to all destinations from matching rules
        var routedDestinations: [AlertDestination] = []

        for rule in matchingRules {
            for destination in rule.destinations {
                // Check throttle
                if shouldThrottle(rule: rule, destination: destination) {
                    print("Throttling alert to destination: \(destination)")
                    continue
                }

                try await routeToDestination(alert, destination: destination)
                routedDestinations.append(destination)
            }
        }

        // Record in history
        let routedAlert = RoutedAlert(
            alert: alert,
            destinations: routedDestinations,
            routedAt: Date(),
            rules: matchingRules
        )

        await MainActor.run {
            routingHistory.append(routedAlert)
            recentAlerts[alert.id.uuidString] = Date()
        }

        // Trim history
        if routingHistory.count > 1000 {
            routingHistory = Array(routingHistory.suffix(1000))
        }
    }

    /// Route alert directly to on-call personnel
    public func routeToOnCall(_ alert: Alert) async throws {
        guard alert.severity >= .error else {
            throw AlertRouterError.insufficientSeverity
        }

        let onCallRule = AlertRule(
            name: "On-Call Escalation",
            enabled: true,
            conditions: [],
            severity: .error,
            destinations: [
                .sms(SMSDestination(
                    phoneNumbers: await getOnCallPhoneNumbers(),
                    provider: .twilio
                )),
                .pagerDuty(PagerDutyDestination(
                    integrationKey: getConfigValue("pagerduty_integration_key"),
                    severity: mapSeverity(alert.severity)
                ))
            ],
            cooldown: 300,  // 5 minutes
            throttle: 1
        )

        try await routeAlert(alert)
    }

    /// Test alert routing with a sample alert
    public func testRouting() async throws {
        let testAlert = Alert(
            type: .systemDown,
            severity: .critical,
            title: "TEST: System Down",
            message: "This is a test alert for routing verification",
            source: "AlertRouter.testRouting()",
            context: ["test": "true"],
            metadata: ["testRun": "true"]
        )

        try await routeAlert(testAlert)
    }

    /// Get routing statistics
    public func getRoutingStats() -> RoutingStats {
        let now = Date()
        let last24Hours = routingHistory.filter { now.timeIntervalSince($0.routedAt) <= 86400 }

        let bySeverity = Dictionary(grouping: last24Hours) { $0.alert.severity }
        let byType = Dictionary(grouping: last24Hours) { $0.alert.type }
        let byDestination = last24Hours.flatMap { $0.destinations }

        return RoutingStats(
            totalRouted: routingHistory.count,
            last24Hours: last24Hours.count,
            bySeverity: bySeverity.mapValues { $0.count },
            byType: byType.mapValues { $0.count },
            mostActiveDestinations: Dictionary(grouping: byDestination, by: { type(of: $0) as! Any.Type })
                .mapValues { $0.count },
            averageRoutingTime: calculateAverageRoutingTime()
        )
    }

    // MARK: - Private Methods

    private func loadDefaultRules() {
        alertRules = [
            // Critical alerts - immediate notification
            AlertRule(
                name: "Critical System Alerts",
                enabled: true,
                conditions: [
                    AlertCondition(field: "severity", operator: .greaterThan, value: "3")
                ],
                severity: .critical,
                destinations: [
                    .slack(SlackDestination(
                        webhook: getConfigValue("slack_webhook_critical"),
                        channel: "#alerts-critical",
                        username: "White Room Monitor",
                        iconEmoji: ":rotating_light:"
                    )),
                    .sms(SMSDestination(
                        phoneNumbers: getConfigValue("oncall_phones").components(separatedBy: ","),
                        provider: .twilio
                    )),
                    .pagerDuty(PagerDutyDestination(
                        integrationKey: getConfigValue("pagerduty_integration_key"),
                        severity: .critical
                    ))
                ],
                cooldown: 300,
                throttle: 1
            ),

            // Test failures - team notification
            AlertRule(
                name: "Test Failure Notifications",
                enabled: true,
                conditions: [
                    AlertCondition(field: "type", operator: .equals, value: "testFailure")
                ],
                severity: .error,
                destinations: [
                    .slack(SlackDestination(
                        webhook: getConfigValue("slack_webhook_tests"),
                        channel: "#test-failures",
                        username: "Test Monitor",
                        iconEmoji: ":x:"
                    )),
                    .email(EmailDestination(
                        addresses: getConfigValue("qa_team_email").components(separatedBy: ","),
                        subject: nil,
                        includeContext: true
                    ))
                ],
                cooldown: 60,
                throttle: 5
            ),

            // Performance degradation - warning
            AlertRule(
                name: "Performance Degradation",
                enabled: true,
                conditions: [
                    AlertCondition(field: "type", operator: .equals, value: "performanceDegradation")
                ],
                severity: .warning,
                destinations: [
                    .slack(SlackDestination(
                        webhook: getConfigValue("slack_webhook_performance"),
                        channel: "#performance",
                        username: "Performance Monitor",
                        iconEmoji: ":chart_with_downwards_trend:"
                    ))
                ],
                cooldown: 600,
                throttle: 10
            ),

            // Security vulnerabilities - immediate
            AlertRule(
                name: "Security Vulnerabilities",
                enabled: true,
                conditions: [
                    AlertCondition(field: "type", operator: .equals, value: "securityVulnerability")
                ],
                severity: .critical,
                destinations: [
                    .slack(SlackDestination(
                        webhook: getConfigValue("slack_webhook_security"),
                        channel: "#security-alerts",
                        username: "Security Monitor",
                        iconEmoji: ":lock:"
                    )),
                    .email(EmailDestination(
                        addresses: getConfigValue("security_team_email").components(separatedBy: ","),
                        subject: "[SECURITY] Vulnerability Detected",
                        includeContext: true
                    ))
                ],
                cooldown: 0,
                throttle: 1
            )
        ]
    }

    private func saveRules() {
        // In production, persist to database or file
        // For now, rules are kept in memory
    }

    private func routeToDestination(_ alert: Alert, destination: AlertDestination) async throws {
        switch destination {
        case .email(let dest):
            try await emailService.sendEmail(alert, destination: dest)

        case .slack(let dest):
            try await slackService.sendSlack(alert, destination: dest)

        case .sms(let dest):
            try await smsService.sendSMS(alert, destination: dest)

        case .pagerDuty(let dest):
            try await pagerDutyService.createIncident(alert, destination: dest)

        case .webhook(let dest):
            try await webhookService.sendWebhook(alert, destination: dest)

        case .custom(let dest):
            try await dest.handler(alert)
        }
    }

    private func findCooldownPeriod(for alert: Alert) -> TimeInterval {
        let matchingRules = alertRules.filter { $0.matches(alert) }
        return matchingRules.map { $0.cooldown }.min() ?? 0
    }

    private func shouldThrottle(rule: AlertRule, destination: AlertDestination) -> Bool {
        let recentCount = routingHistory.filter { routedAlert in
            routedAlert.routedAt.timeIntervalSinceNow > -3600 &&  // Last hour
            routedAlert.alert.type == AlertType(rawValue: rule.conditions.first?.value ?? "") &&
            routedAlert.destinations.contains { $0.hashValue == destination.hashValue }
        }.count

        return recentCount >= rule.throttle
    }

    private func getOnCallPhoneNumbers() async -> [String] {
        // In production, fetch from on-call rotation system
        return getConfigValue("oncall_phones").components(separatedBy: ",")
    }

    private func mapSeverity(_ severity: AlertSeverity) -> PagerDutySeverity {
        switch severity {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        }
    }

    private func getConfigValue(_ key: String) -> String {
        // In production, fetch from secure config system
        // For now, return empty string
        return ""
    }

    private func calculateAverageRoutingTime() -> TimeInterval {
        let recentHistory = routingHistory.suffix(100)
        guard !recentHistory.isEmpty else { return 0 }

        let totalTime = recentHistory.reduce(0.0) { sum, alert in
            sum + alert.routingTime
        }

        return totalTime / Double(recentHistory.count)
    }
}

// MARK: - Alert Rule

public struct AlertRule: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let enabled: Bool
    public let conditions: [AlertCondition]
    public let severity: AlertSeverity
    public let destinations: [AlertDestination]
    public let cooldown: TimeInterval
    public let throttle: Int

    public init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool,
        conditions: [AlertCondition],
        severity: AlertSeverity,
        destinations: [AlertDestination],
        cooldown: TimeInterval,
        throttle: Int
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.conditions = conditions
        self.severity = severity
        self.destinations = destinations
        self.cooldown = cooldown
        self.throttle = throttle
    }

    public func matches(_ alert: Alert) -> Bool {
        // Check if severity matches
        guard alert.severity == severity || alert.severity > severity else {
            return false
        }

        // Check all conditions
        for condition in conditions {
            guard condition.evaluate(alert: alert) else {
                return false
            }
        }

        return true
    }
}

// MARK: - Alert Condition

public struct AlertCondition: Codable {
    public let field: String
    public let operator: ConditionOperator
    public let value: String

    public init(
        field: String,
        operator: ConditionOperator,
        value: String
    ) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }

    public enum ConditionOperator: String, Codable {
        case equals
        case contains
        case greaterThan
        case lessThan
        case matches
    }

    public func evaluate(alert: Alert) -> Bool {
        let fieldValue = getFieldValue(from: alert, field: field)

        switch `operator` {
        case .equals:
            return fieldValue == value

        case .contains:
            return fieldValue.contains(value)

        case .greaterThan:
            if let fieldDouble = Double(fieldValue),
               let valueDouble = Double(value) {
                return fieldDouble > valueDouble
            }
            return false

        case .lessThan:
            if let fieldDouble = Double(fieldValue),
               let valueDouble = Double(value) {
                return fieldDouble < valueDouble
            }
            return false

        case .matches:
            if let regex = try? NSRegularExpression(pattern: value) {
                let range = NSRange(fieldValue.startIndex..., in: fieldValue)
                return regex.firstMatch(in: fieldValue, range: range) != nil
            }
            return false
        }
    }

    private func getFieldValue(from alert: Alert, field: String) -> String {
        switch field {
        case "type":
            return alert.type.rawValue

        case "severity":
            return "\(alert.severity.rawValue)"

        case "source":
            return alert.source

        case "title":
            return alert.title

        default:
            return alert.context[field] ?? ""
        }
    }
}

// MARK: - Alert Destinations

public enum AlertDestination: Codable {
    case email(EmailDestination)
    case slack(SlackDestination)
    case sms(SMSDestination)
    case pagerDuty(PagerDutyDestination)
    case webhook(WebhookDestination)
    case custom(CustomDestination)

    private enum CodingKeys: String, CodingKey {
        case type, email, slack, sms, pagerDuty, webhook, custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "email":
            self = .email(try container.decode(EmailDestination.self, forKey: .email))
        case "slack":
            self = .slack(try container.decode(SlackDestination.self, forKey: .slack))
        case "sms":
            self = .sms(try container.decode(SMSDestination.self, forKey: .sms))
        case "pagerDuty":
            self = .pagerDuty(try container.decode(PagerDutyDestination.self, forKey: .pagerDuty))
        case "webhook":
            self = .webhook(try container.decode(WebhookDestination.self, forKey: .webhook))
        case "custom":
            self = .custom(try container.decode(CustomDestination.self, forKey: .custom))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid destination type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .email(let dest):
            try container.encode("email", forKey: .type)
            try container.encode(dest, forKey: .email)

        case .slack(let dest):
            try container.encode("slack", forKey: .type)
            try container.encode(dest, forKey: .slack)

        case .sms(let dest):
            try container.encode("sms", forKey: .type)
            try container.encode(dest, forKey: .sms)

        case .pagerDuty(let dest):
            try container.encode("pagerDuty", forKey: .type)
            try container.encode(dest, forKey: .pagerDuty)

        case .webhook(let dest):
            try container.encode("webhook", forKey: .type)
            try container.encode(dest, forKey: .webhook)

        case .custom(let dest):
            try container.encode("custom", forKey: .type)
            try container.encode(dest, forKey: .custom)
        }
    }

    public var hashValue: Int {
        switch self {
        case .email: return 1
        case .slack: return 2
        case .sms: return 3
        case .pagerDuty: return 4
        case .webhook: return 5
        case .custom: return 6
        }
    }
}

public struct EmailDestination: Codable {
    public let addresses: [String]
    public let subject: String?
    public let includeContext: Bool

    public init(
        addresses: [String],
        subject: String? = nil,
        includeContext: Bool = true
    ) {
        self.addresses = addresses
        self.subject = subject
        self.includeContext = includeContext
    }
}

public struct SlackDestination: Codable {
    public let webhook: String
    public let channel: String?
    public let username: String?
    public let iconEmoji: String?

    public init(
        webhook: String,
        channel: String? = nil,
        username: String? = nil,
        iconEmoji: String? = nil
    ) {
        self.webhook = webhook
        self.channel = channel
        self.username = username
        self.iconEmoji = iconEmoji
    }
}

public struct SMSDestination: Codable {
    public let phoneNumbers: [String]
    public let provider: SMSProvider

    public init(
        phoneNumbers: [String],
        provider: SMSProvider
    ) {
        self.phoneNumbers = phoneNumbers
        self.provider = provider
    }
}

public enum SMSProvider: String, Codable {
    case twilio
    case awsSNS
    case custom
}

public struct PagerDutyDestination: Codable {
    public let integrationKey: String
    public let severity: PagerDutySeverity

    public init(
        integrationKey: String,
        severity: PagerDutySeverity
    ) {
        self.integrationKey = integrationKey
        self.severity = severity
    }
}

public enum PagerDutySeverity: String, Codable {
    case info
    case warning
    case error
    case critical
}

public struct WebhookDestination: Codable {
    public let url: String
    public let method: String
    public let headers: [String: String]
    public let bodyTemplate: String?

    public init(
        url: String,
        method: String = "POST",
        headers: [String: String] = [:],
        bodyTemplate: String? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.bodyTemplate = bodyTemplate
    }
}

public struct CustomDestination: Codable {
    public let name: String
    public let config: [String: String]

    public init(
        name: String,
        config: [String: String] = [:]
    ) {
        self.name = name
        self.config = config
    }

    public var handler: (Alert) async throws -> Void {
        // In production, this would be a registered handler
        return { _ in }
    }
}

// MARK: - Routed Alert

public struct RoutedAlert: Identifiable, Codable {
    public let id: UUID
    public let alert: Alert
    public let destinations: [AlertDestination]
    public let routedAt: Date
    public let rules: [AlertRule]
    public let routingTime: TimeInterval

    public init(
        id: UUID = UUID(),
        alert: Alert,
        destinations: [AlertDestination],
        routedAt: Date,
        rules: [AlertRule],
        routingTime: TimeInterval = 0
    ) {
        self.id = id
        self.alert = alert
        self.destinations = destinations
        self.routedAt = routedAt
        self.rules = rules
        self.routingTime = routingTime
    }
}

// MARK: - Routing Stats

public struct RoutingStats {
    public let totalRouted: Int
    public let last24Hours: Int
    public let bySeverity: [AlertSeverity: Int]
    public let byType: [Alert.AlertType: Int]
    public let mostActiveDestinations: [AnyHashable: Int]
    public let averageRoutingTime: TimeInterval

    public init(
        totalRouted: Int,
        last24Hours: Int,
        bySeverity: [AlertSeverity: Int],
        byType: [Alert.AlertType: Int],
        mostActiveDestinations: [AnyHashable: Int],
        averageRoutingTime: TimeInterval
    ) {
        self.totalRouted = totalRouted
        self.last24Hours = last24Hours
        self.bySeverity = bySeverity
        self.byType = byType
        self.mostActiveDestinations = mostActiveDestinations
        self.averageRoutingTime = averageRoutingTime
    }
}

// MARK: - Alert Router Error

public enum AlertRouterError: Error, LocalizedError {
    case noMatchingRules
    case insufficientSeverity
    case destinationUnavailable(String)
    case routingTimeout

    public var errorDescription: String? {
        switch self {
        case .noMatchingRules:
            return "No matching alert rules found"
        case .insufficientSeverity:
            return "Alert severity insufficient for on-call routing"
        case .destinationUnavailable(let dest):
            return "Destination unavailable: \(dest)"
        case .routingTimeout:
            return "Alert routing timed out"
        }
    }
}

// MARK: - Alert Types (Imported from RealTimeMonitor)

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
}

// MARK: - Service Interfaces

public protocol EmailService {
    func sendEmail(_ alert: Alert, destination: EmailDestination) async throws
}

public protocol SlackService {
    func sendSlack(_ alert: Alert, destination: SlackDestination) async throws
}

public protocol SMSService {
    func sendSMS(_ alert: Alert, destination: SMSDestination) async throws
}

public protocol PagerDutyService {
    func createIncident(_ alert: Alert, destination: PagerDutyDestination) async throws
}

public protocol WebhookService {
    func sendWebhook(_ alert: Alert, destination: WebhookDestination) async throws
}

// MARK: - Default Service Implementations

public class EmailServiceImpl: EmailService {
    public static let shared = EmailServiceImpl()

    private init() {}

    public func sendEmail(_ alert: Alert, destination: EmailDestination) async throws {
        // Implement email sending logic
        print("Sending email for alert: \(alert.title) to \(destination.addresses)")
    }
}

public class SlackServiceImpl: SlackService {
    public static let shared = SlackServiceImpl()

    private init() {}

    public func sendSlack(_ alert: Alert, destination: SlackDestination) async throws {
        let payload: [String: Any] = [
            "text": alert.message,
            "channel": destination.channel ?? "#alerts",
            "username": destination.username ?? "White Room Monitor",
            "icon_emoji": destination.iconEmoji ?? ":warning:",
            "attachments": [
                [
                    "color": severityColor(alert.severity),
                    "title": alert.title,
                    "fields": [
                        ["title": "Severity", "value": "\(alert.severity)", "short": true],
                        ["title": "Source", "value": alert.source, "short": true],
                        ["title": "Time", "value": ISO8601DateFormatter().string(from: alert.timestamp), "short": true]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: destination.webhook) else {
            throw AlertRouterError.destinationUnavailable("Invalid webhook URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpValue = try? JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw AlertRouterError.destinationUnavailable("Slack returned \(httpResponse.statusCode)")
        }
    }

    private func severityColor(_ severity: AlertSeverity) -> String {
        switch severity {
        case .info: return "good"
        case .warning: return "warning"
        case .error: return "danger"
        case .critical: return "#FF0000"
        }
    }
}

public class SMSServiceImpl: SMSService {
    public static let shared = SMSServiceImpl()

    private init() {}

    public func sendSMS(_ alert: Alert, destination: SMSDestination) async throws {
        print("Sending SMS for alert: \(alert.title) to \(destination.phoneNumbers)")
        // Implement SMS sending logic based on provider
    }
}

public class PagerDutyServiceImpl: PagerDutyService {
    public static let shared = PagerDutyServiceImpl()

    private init() {}

    public func createIncident(_ alert: Alert, destination: PagerDutyDestination) async throws {
        let payload: [String: Any] = [
            "routing_key": destination.integrationKey,
            "event_action": "trigger",
            "payload": [
                "summary": alert.title,
                "severity": destination.severity.rawValue,
                "source": alert.source,
                "timestamp": ISO8601DateFormatter().string(from: alert.timestamp),
                "custom_details": alert.context
            ]
        ]

        guard let url = URL(string: "https://events.pagerduty.com/v2/enqueue") else {
            throw AlertRouterError.destinationUnavailable("Invalid PagerDuty URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpValue = try? JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 202 {
            throw AlertRouterError.destinationUnavailable("PagerDuty returned \(httpResponse.statusCode)")
        }
    }
}

public class WebhookServiceImpl: WebhookService {
    public static let shared = WebhookServiceImpl()

    private init() {}

    public func sendWebhook(_ alert: Alert, destination: WebhookDestination) async throws {
        guard let url = URL(string: destination.url) else {
            throw AlertRouterError.destinationUnavailable("Invalid webhook URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = destination.method

        for (key, value) in destination.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let bodyTemplate = destination.bodyTemplate {
            let body = bodyTemplate.replacingOccurrences(of: "{{alert.title}}", with: alert.title)
                .replacingOccurrences(of: "{{alert.message}}", with: alert.message)
            request.httpValue = body.data(using: .utf8)
        } else {
            let alertData = try? JSONEncoder().encode(alert)
            request.httpValue = alertData
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw AlertRouterError.destinationUnavailable("Webhook returned \(httpResponse.statusCode)")
        }
    }
}

typealias EmailService = EmailServiceImpl
typealias SlackService = SlackServiceImpl
typealias SMSService = SMSServiceImpl
typealias PagerDutyService = PagerDutyServiceImpl
typealias WebhookService = WebhookServiceImpl

// MARK: - Alert Model (Shared)

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
}
