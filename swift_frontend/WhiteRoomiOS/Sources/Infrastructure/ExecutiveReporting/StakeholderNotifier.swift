import Foundation
import Combine

/// Manages stakeholder notifications via email and Slack
public class StakeholderNotifier: ObservableObject {
    @Published var notificationHistory: [Notification] = []
    @Published var isSending: Bool = false
    @Published var lastError: Error?

    private let emailService: EmailService
    private let slackService: SlackService
    private let subscriptionManager: SubscriptionManager
    private let historyManager: NotificationHistoryManager
    private var cancellables = Set<AnyCancellable>()

    public init(
        emailService: EmailService = EmailService(),
        slackService: SlackService = SlackService(),
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        historyManager: NotificationHistoryManager = NotificationHistoryManager()
    ) {
        self.emailService = emailService
        self.slackService = slackService
        self.subscriptionManager = subscriptionManager
        self.historyManager = historyManager

        setupObservers()
    }

    // MARK: - Public API

    /// Sends report to specified recipients
    public func sendReport(
        _ report: ExecutableReport,
        to recipients: [Stakeholder]
    ) async throws {
        isSending = true
        defer { isSending = false }

        for recipient in recipients {
            // Check preferences
            guard shouldNotify(recipient, for: report.topic) else {
                continue
            }

            // Check quiet hours
            if isInQuietHours(for: recipient) {
                await scheduleForLater(report, recipient: recipient)
                continue
            }

            // Send notifications based on preferences
            try await sendToStakeholder(report, recipient: recipient)
        }

        // Update history
        await recordNotification(report, recipients: recipients)
    }

    /// Sends alert notification
    public func sendAlert(
        _ alert: Alert,
        severity: AlertSeverity
    ) async throws {
        let subscribers = await subscriptionManager.subscribers(for: alert.topic)

        for subscriber in subscribers {
            // Only send alerts if they meet severity threshold
            guard subscriber.alertPreference.shouldSend(severity: severity) else {
                continue
            }

            let notification = Notification(
                id: UUID(),
                type: .alert,
                topic: alert.topic,
                severity: severity,
                title: alert.title,
                message: alert.message,
                timestamp: Date(),
                recipient: subscriber
            )

            if subscriber.preferences.emailEnabled {
                try await emailService.sendAlert(notification)
            }

            if subscriber.preferences.slackEnabled {
                try await slackService.sendAlert(notification)
            }
        }

        // Record in history
        await historyManager.record(alert, severity: severity, sentTo: subscribers)
    }

    /// Subscribe stakeholder to topics
    public func subscribeStakeholder(
        _ stakeholder: Stakeholder,
        to topics: [NotificationTopic]
    ) {
        subscriptionManager.subscribe(stakeholder, to: topics)
    }

    /// Unsubscribe stakeholder from topics
    public func unsubscribeStakeholder(
        _ stakeholder: Stakeholder,
        from topics: [NotificationTopic]
    ) {
        subscriptionManager.unsubscribe(stakeholder, from: topics)
    }

    /// Get notification history for stakeholder
    public func history(for stakeholder: Stakeholder, limit: Int = 50) async -> [Notification] {
        return await historyManager.history(for: stakeholder, limit: limit)
    }

    /// Get pending notifications (scheduled during quiet hours)
    public func pendingNotifications() async -> [ScheduledNotification] {
        return await historyManager.pendingNotifications()
    }

    /// Send pending notifications (call after quiet hours end)
    public func sendPendingNotifications() async throws {
        let pending = await pendingNotifications()

        for scheduled in pending {
            try await sendToStakeholder(scheduled.report, recipient: scheduled.recipient)
            await historyManager.markAsSent(scheduled)
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe subscription changes
        subscriptionManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func shouldNotify(
        _ stakeholder: Stakeholder,
        for topic: NotificationTopic
    ) -> Bool {
        return stakeholder.preferences.topics.contains(topic)
    }

    private func isInQuietHours(for stakeholder: Stakeholder) -> Bool {
        guard let quietHours = stakeholder.preferences.quietHours else {
            return false
        }

        let now = Date()
        return quietHours.contains(now)
    }

    private func sendToStakeholder(
        _ report: ExecutableReport,
        recipient: Stakeholder
    ) async throws {
        if recipient.preferences.emailEnabled {
            let email = EmailNotification(
                to: recipient.email,
                subject: report.title,
                body: report.content,
                attachment: report.attachment
            )
            try await emailService.send(email)
        }

        if recipient.preferences.slackEnabled {
            let slackMessage = SlackMessage(
                channel: recipient.slackHandle,
                text: report.summary,
                blocks: report.slackBlocks,
                attachments: report.slackAttachments
            )
            try await slackService.send(slackMessage)
        }
    }

    private func scheduleForLater(
        _ report: ExecutableReport,
        recipient: Stakeholder
    ) async {
        let scheduled = ScheduledNotification(
            id: UUID(),
            report: report,
            recipient: recipient,
            scheduledFor: endOfQuietHours(for: recipient)
        )
        await historyManager.schedule(scheduled)
    }

    private func endOfQuietHours(for stakeholder: Stakeholder) -> Date {
        guard let quietHours = stakeholder.preferences.quietHours else {
            return Date()
        }
        return quietHours.end
    }

    private func recordNotification(
        _ report: ExecutableReport,
        recipients: [Stakeholder]
    ) async {
        let notification = Notification(
            id: UUID(),
            type: .report,
            topic: report.topic,
            severity: .info,
            title: report.title,
            message: report.summary,
            timestamp: Date(),
            recipients: recipients
        )
        await historyManager.record(notification)
    }
}

// MARK: - Stakeholder

public struct Stakeholder: Identifiable, Codable {
    public let id: String
    public let name: String
    public let email: String?
    public let slackHandle: String?
    public let roles: [StakeholderRole]
    public let preferences: NotificationPreferences
    public let alertPreference: AlertPreference

    public init(
        id: String,
        name: String,
        email: String?,
        slackHandle: String?,
        roles: [StakeholderRole],
        preferences: NotificationPreferences,
        alertPreference: AlertPreference = .all
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.slackHandle = slackHandle
        self.roles = roles
        self.preferences = preferences
        self.alertPreference = alertPreference
    }

    public enum StakeholderRole: String, Codable {
        case executive
        case engineeringManager
        case developer
        case qa
        case productManager
        case devops
    }
}

// MARK: - Notification Preferences

public struct NotificationPreferences: Codable {
    public let emailEnabled: Bool
    public let slackEnabled: Bool
    public let frequency: NotificationFrequency
    public let topics: Set<NotificationTopic>
    public let quietHours: DateInterval?

    public init(
        emailEnabled: Bool,
        slackEnabled: Bool,
        frequency: NotificationFrequency,
        topics: Set<NotificationTopic>,
        quietHours: DateInterval? = nil
    ) {
        self.emailEnabled = emailEnabled
        self.slackEnabled = slackEnabled
        self.frequency = frequency
        self.topics = topics
        self.quietHours = quietHours
    }

    enum CodingKeys: String, CodingKey {
        case emailEnabled
        case slackEnabled
        case frequency
        case topics
        case quietHoursStart
        case quietHoursEnd
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emailEnabled = try container.decode(Bool.self, forKey: .emailEnabled)
        slackEnabled = try container.decode(Bool.self, forKey: .slackEnabled)
        frequency = try container.decode(NotificationFrequency.self, forKey: .frequency)
        topics = try container.decode(Set<NotificationTopic>.self, forKey: .topics)

        if let start = try container.decodeIfPresent(Date.self, forKey: .quietHoursStart),
           let end = try container.decodeIfPresent(Date.self, forKey: .quietHoursEnd) {
            quietHours = DateInterval(start: start, end: end)
        } else {
            quietHours = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emailEnabled, forKey: .emailEnabled)
        try container.encode(slackEnabled, forKey: .slackEnabled)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(topics, forKey: .topics)
        try container.encodeIfPresent(quietHours?.start, forKey: .quietHoursStart)
        try container.encodeIfPresent(quietHours?.end, forKey: .quietHoursEnd)
    }
}

public enum NotificationFrequency: String, Codable {
    case immediate
    case hourly
    case daily
    case weekly
}

public enum NotificationTopic: String, Codable, CaseIterable {
    case buildFailures = "Build Failures"
    case qualityGates = "Quality Gates"
    case deploymentRisks = "Deployment Risks"
    case flakyTests = "Flaky Tests"
    case performanceRegressions = "Performance Regressions"
    case securityVulnerabilities = "Security Vulnerabilities"
    case weeklySummary = "Weekly Summary"
    case releaseReadiness = "Release Readiness"
}

public enum AlertPreference: String, Codable {
    case all               // All alerts
    case highAndCritical   // High and critical only
    case criticalOnly      // Critical only
    case none              // No alerts

    func shouldSend(severity: AlertSeverity) -> Bool {
        switch self {
        case .all:
            return true
        case .highAndCritical:
            return severity == .high || severity == .critical
        case .criticalOnly:
            return severity == .critical
        case .none:
            return false
        }
    }
}

// MARK: - Notification Types

public struct Notification: Identifiable {
    public let id: UUID
    public let type: NotificationType
    public let topic: NotificationTopic
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let timestamp: Date
    public var recipients: [Stakeholder] = []
    public var recipient: Stakeholder?

    public init(
        id: UUID = UUID(),
        type: NotificationType,
        topic: NotificationTopic,
        severity: AlertSeverity,
        title: String,
        message: String,
        timestamp: Date = Date(),
        recipients: [Stakeholder] = [],
        recipient: Stakeholder? = nil
    ) {
        self.id = id
        self.type = type
        self.topic = topic
        self.severity = severity
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.recipients = recipients
        self.recipient = recipient
    }

    public enum NotificationType {
        case report
        case alert
        case digest
    }
}

public struct Alert {
    public let title: String
    public let message: String
    public let topic: NotificationTopic
    public let metadata: [String: String]?

    public init(title: String, message: String, topic: NotificationTopic, metadata: [String: String]? = nil) {
        self.title = title
        self.message = message
        self.topic = topic
        self.metadata = metadata
    }
}

public enum AlertSeverity: String {
    case info
    case low
    case medium
    case high
    case critical
}

public struct ExecutableReport {
    public let title: String
    public let summary: String
    public let content: String
    public let attachment: Data?
    public let attachmentName: String?
    public let topic: NotificationTopic
    public let slackBlocks: [[String: Any]]?
    public let slackAttachments: [[String: Any]]?

    public init(
        title: String,
        summary: String,
        content: String,
        attachment: Data? = nil,
        attachmentName: String? = nil,
        topic: NotificationTopic,
        slackBlocks: [[String: Any]]? = nil,
        slackAttachments: [[String: Any]]? = nil
    ) {
        self.title = title
        self.summary = summary
        self.content = content
        self.attachment = attachment
        self.attachmentName = attachmentName
        self.topic = topic
        self.slackBlocks = slackBlocks
        self.slackAttachments = slackAttachments
    }
}

// MARK: - Scheduled Notification

public struct ScheduledNotification: Identifiable {
    public let id: UUID
    public let report: ExecutableReport
    public let recipient: Stakeholder
    public let scheduledFor: Date
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        report: ExecutableReport,
        recipient: Stakeholder,
        scheduledFor: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.report = report
        self.recipient = recipient
        self.scheduledFor = scheduledFor
        self.createdAt = createdAt
    }
}

// MARK: - Email Service

public class EmailService {
    private let smtpConfig: SMTPConfiguration

    public init(smtpConfig: SMTPConfiguration = SMTPConfiguration()) {
        self.smtpConfig = smtpConfig
    }

    public func send(_ email: EmailNotification) async throws {
        // Validate email
        guard email.to.contains("@") else {
            throw EmailError.invalidAddress
        }

        // Send via SMTP
        try await sendViaSMTP(email)
    }

    public func sendAlert(_ notification: Notification) async throws {
        guard let recipientEmail = notification.recipient?.email else {
            throw EmailError.noRecipientEmail
        }

        let email = EmailNotification(
            to: recipientEmail,
            subject: "[\(notification.severity.rawValue.uppercased())] \(notification.title)",
            body: notification.message,
            attachment: nil
        )

        try await send(email)
    }

    private func sendViaSMTP(_ email: EmailNotification) async throws {
        // Implementation would use a library like Postal or direct SMTP
        // This is a placeholder for the actual implementation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second simulation
    }
}

public struct EmailNotification {
    public let to: String
    public let subject: String
    public let body: String
    public let attachment: Data?

    public init(to: String, subject: String, body: String, attachment: Data? = nil) {
        self.to = to
        self.subject = subject
        self.body = body
        self.attachment = attachment
    }
}

public struct SMTPConfiguration {
    public let host: String
    public let port: Int
    public let username: String
    public let password: String
    public let useTLS: Bool

    public init(
        host: String = "",
        port: Int = 587,
        username: String = "",
        password: String = "",
        useTLS: Bool = true
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.useTLS = useTLS
    }
}

public enum EmailError: Error {
    case invalidAddress
    case noRecipientEmail
    case smtpFailure(String)
}

// MARK: - Slack Service

public class SlackService {
    private let apiToken: String
    private let webhookURL: URL?

    public init(apiToken: String = "", webhookURL: URL? = nil) {
        self.apiToken = apiToken
        self.webhookURL = webhookURL
    }

    public func send(_ message: SlackMessage) async throws {
        guard let webhookURL = webhookURL else {
            throw SlackError.noWebhookURL
        }

        var request = URLRequest(url: webhookURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "channel": message.channel,
            "text": message.text,
            "blocks": message.blocks ?? [],
            "attachments": message.attachments ?? []
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SlackError.sendFailed
        }
    }

    public func sendAlert(_ notification: Notification) async throws {
        guard let slackHandle = notification.recipient?.slackHandle else {
            throw SlackError.noRecipientHandle
        }

        let color = alertColor(for: notification.severity)

        let message = SlackMessage(
            channel: slackHandle,
            text: notification.title,
            blocks: nil,
            attachments: [[
                "color": color,
                "title": notification.title,
                "text": notification.message,
                "ts": Int(notification.timestamp.timeIntervalSince1970)
            ]]
        )

        try await send(message)
    }

    private func alertColor(for severity: AlertSeverity) -> String {
        switch severity {
        case .info: return "#808080"
        case .low: return "#36a64f"
        case .medium: return "#ff9900"
        case .high: return "#ff6600"
        case .critical: return "#ff0000"
        }
    }
}

public struct SlackMessage {
    public let channel: String
    public let text: String
    public let blocks: [[String: Any]]?
    public let attachments: [[String: Any]]?

    public init(
        channel: String,
        text: String,
        blocks: [[String: Any]]? = nil,
        attachments: [[String: Any]]? = nil
    ) {
        self.channel = channel
        self.text = text
        self.blocks = blocks
        self.attachments = attachments
    }
}

public enum SlackError: Error {
    case noWebhookURL
    case noRecipientHandle
    case sendFailed
}

// MARK: - Subscription Manager

public class SubscriptionManager: ObservableObject {
    @Published private var subscriptions: [Stakeholder: Set<NotificationTopic>] = [:]

    public init() {
        loadSubscriptions()
    }

    public func subscribe(_ stakeholder: Stakeholder, to topics: [NotificationTopic]) {
        if subscriptions[stakeholder] == nil {
            subscriptions[stakeholder] = []
        }

        subscriptions[stakeholder]?.formUnion(topics)
        saveSubscriptions()
    }

    public func unsubscribe(_ stakeholder: Stakeholder, from topics: [NotificationTopic]) {
        subscriptions[stakeholder]?.subtract(topics)
        saveSubscriptions()
    }

    public func subscribers(for topic: NotificationTopic) async -> [Stakeholder] {
        return subscriptions.filter { $0.value.contains(topic) }
            .map { $0.key }
            .filter { stakeholder in
                stakeholder.preferences.topics.contains(topic)
            }
    }

    private func loadSubscriptions() {
        // Load from persistent storage
        // This is a placeholder
    }

    private func saveSubscriptions() {
        // Save to persistent storage
        // This is a placeholder
    }
}

// MARK: - Notification History Manager

public class NotificationHistoryManager {
    private var history: [Notification] = []
    private var pending: [ScheduledNotification] = []

    public init() {
        loadHistory()
    }

    public func record(_ notification: Notification) async {
        history.insert(notification, at: 0)
        saveHistory()
    }

    public func record(_ alert: Alert, severity: AlertSeverity, sentTo: [Stakeholder]) async {
        let notification = Notification(
            type: .alert,
            topic: alert.topic,
            severity: severity,
            title: alert.title,
            message: alert.message,
            timestamp: Date(),
            recipients: sentTo
        )

        await record(notification)
    }

    public func history(for stakeholder: Stakeholder, limit: Int = 50) async -> [Notification] {
        return history.filter { notification in
            notification.recipients.contains(stakeholder) ||
            notification.recipient?.id == stakeholder.id
        }
        .prefix(limit)
        .map { $0 }
    }

    public func schedule(_ scheduled: ScheduledNotification) async {
        pending.append(scheduled)
        savePending()
    }

    public func pendingNotifications() async -> [ScheduledNotification] {
        return pending.filter { $0.scheduledFor <= Date() }
    }

    public func markAsSent(_ scheduled: ScheduledNotification) async {
        pending.removeAll { $0.id == scheduled.id }
        savePending()
    }

    private func loadHistory() {
        // Load from persistent storage
        // This is a placeholder
    }

    private func saveHistory() {
        // Save to persistent storage
        // This is a placeholder
    }

    private func savePending() {
        // Save to persistent storage
        // This is a placeholder
    }

    private func loadPending() {
        // Load from persistent storage
        // This is a placeholder
    }
}
