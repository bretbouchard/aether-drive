//
// IncidentResponder.swift
// WhiteRoomiOS
//
// Created by AI Assistant on 2026-01-16.
// Part of Phase 3: Advanced Monitoring & Alerting System
//

import Foundation
import Combine

/// Automated incident response system with predefined playbooks and multi-step action execution
public class IncidentResponder: ObservableObject {

    // MARK: - Published Properties

    @Published public var activeIncidents: [Incident] = []
    @Published public var responsePlaybooks: [ResponsePlaybook] = []
    @Published public var isResponding: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let playbookExecutor: PlaybookExecutor
    private let incidentStore: IncidentStore
    private let alertRouter: AlertRouter

    // MARK: - Initialization

    public init(
        playbookExecutor: PlaybookExecutor = .shared,
        incidentStore: IncidentStore = .shared,
        alertRouter: AlertRouter = .shared
    ) {
        self.playbookExecutor = playbookExecutor
        self.incidentStore = incidentStore
        self.alertRouter = alertRouter

        loadDefaultPlaybooks()
        loadActiveIncidents()
    }

    // MARK: - Public Methods

    /// Handle an incoming alert and create an incident
    public func handleIncident(_ alert: Alert) async throws -> Incident {
        await MainActor.run {
            self.isResponding = true
        }

        defer {
            Task { @MainActor in
                self.isResponding = false
            }
        }

        // Find applicable playbook
        guard let playbook = findPlaybook(for: alert) else {
            // Create incident without playbook
            let incident = Incident(
                alert: alert,
                status: .open,
                severity: mapIncidentSeverity(alert.severity),
                assignedTo: nil,
                playbook: nil
            )

            await addIncident(incident)
            return incident
        }

        // Create incident with playbook
        var incident = Incident(
            alert: alert,
            status: .open,
            severity: mapIncidentSeverity(alert.severity),
            assignedTo: findAssignee(for: alert),
            playbook: playbook
        )

        await addIncident(incident)

        // Auto-execute if configured
        if playbook.autoExecute {
            try await executePlaybook(playbook, for: &incident)
        }

        return incident
    }

    /// Execute a response playbook for an incident
    public func executePlaybook(
        _ playbook: ResponsePlaybook,
        for incident: inout Incident
    ) async throws {
        incident.status = .investigating
        await updateIncident(incident)

        var updatedIncident = incident
        let results = try await playbookExecutor.execute(
            playbook: playbook,
            incident: updatedIncident
        ) { action in
            // Callback for each action
            Task { @MainActor in
                updatedIncident.actions.append(action)
                updatedIncident.timeline.append(TimelineEvent(
                    timestamp: Date(),
                    type: .action,
                    description: action.description,
                    performedBy: action.performedBy
                ))
            }
        }

        // Update incident based on results
        if results.allSatisfy({ $0.isSuccess }) {
            updatedIncident.status = .resolving
        } else {
            updatedIncident.status = .open
        }

        incident = updatedIncident
        await updateIncident(incident)
    }

    /// Update incident status
    public func updateIncident(_ incident: Incident, status: IncidentStatus) {
        Task {
            var updated = incident
            updated.status = status

            await MainActor.run {
                if let index = activeIncidents.firstIndex(where: { $0.id == incident.id }) {
                    activeIncidents[index] = updated
                }
            }

            await incidentStore.save(updated)
        }
    }

    /// Resolve an incident with resolution details
    public func resolveIncident(
        _ incident: Incident,
        resolution: Resolution
    ) {
        Task {
            var resolved = incident
            resolved.status = .resolved
            resolved.resolution = resolution
            resolved.resolvedAt = Date()

            await MainActor.run {
                if let index = activeIncidents.firstIndex(where: { $0.id == incident.id }) {
                    activeIncidents.remove(at: index)
                }
            }

            await incidentStore.save(resolved)
            await incidentStore.archive(resolved)
        }
    }

    /// Add a new playbook
    public func addPlaybook(_ playbook: ResponsePlaybook) {
        responsePlaybooks.append(playbook)
        savePlaybooks()
    }

    /// Remove a playbook
    public func removePlaybook(id: String) {
        responsePlaybooks.removeAll { $0.id.uuidString == id }
        savePlaybooks()
    }

    /// Get incident statistics
    public func getIncidentStats() -> IncidentStats {
        let now = Date()
        let last24Hours = activeIncidents.filter { now.timeIntervalSince($0.startedAt) <= 86400 }
        let lastWeek = activeIncidents.filter { now.timeIntervalSince($0.startedAt) <= 604800 }

        let bySeverity = Dictionary(grouping: activeIncidents) { $0.severity }
        let byStatus = Dictionary(grouping: activeIncidents) { $0.status }

        let resolvedIn24Hours = activeIncidents.filter {
            if let resolved = $0.resolvedAt {
                return now.timeIntervalSince(resolved) <= 86400
            }
            return false
        }

        let avgResolutionTime = resolvedIn24Hours.reduce(0.0) { sum, incident in
            if let resolved = incident.resolvedAt {
                return sum + resolved.timeIntervalSince(incident.startedAt)
            }
            return sum
        } / Double(resolvedIn24Hours.count)

        return IncidentStats(
            totalActive: activeIncidents.count,
            last24Hours: last24Hours.count,
            lastWeek: lastWeek.count,
            bySeverity: bySeverity.mapValues { $0.count },
            byStatus: byStatus.mapValues { $0.count },
            averageResolutionTime: avgResolutionTime,
            mostCommonPlaybooks: calculateMostCommonPlaybooks()
        )
    }

    // MARK: - Private Methods

    private func loadDefaultPlaybooks() {
        responsePlaybooks = [
            // Test failure playbook
            ResponsePlaybook(
                name: "Test Failure Investigation",
                description: "Automatically investigate and respond to test failures",
                triggers: [.testFailure, .flakyTest],
                steps: [
                    ResponseStep(
                        type: .notification,
                        description: "Notify QA team of test failure",
                        timeout: 30,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Fetch test logs from CI/CD system",
                        command: "GET /api/tests/{{alert.context.testId}}/logs",
                        timeout: 60,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .conditionCheck,
                        description: "Check if test is flaky (failed before in last 7 days)",
                        script: "checkFlakyTest.sh",
                        timeout: 30,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Create GitHub issue for non-flaky test failure",
                        command: "POST /api/issues -d '{\"title\": \"Test Failure: {{alert.title}}\", \"body\": \"{{alert.message}}\"}'",
                        timeout: 60,
                        continueOnError: true
                    )
                ],
                estimatedDuration: 180,
                autoExecute: true
            ),

            // System down playbook
            ResponsePlaybook(
                name: "System Down Recovery",
                description: "Critical system failure response and recovery",
                triggers: [.systemDown],
                steps: [
                    ResponseStep(
                        type: .notification,
                        description: "Page on-call engineer immediately",
                        timeout: 30,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Check system health endpoints",
                        command: "GET /api/health",
                        timeout: 30,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .script,
                        description: "Restart affected services",
                        script: "restartServices.sh {{alert.context.serviceName}}",
                        timeout: 120,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .delay,
                        description: "Wait for services to start",
                        command: "sleep 30",
                        timeout: 35,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .conditionCheck,
                        description: "Verify system health restored",
                        script: "verifyHealth.sh",
                        timeout: 60,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Create incident postmortem ticket",
                        command: "POST /api/incidents -d '{\"type\": \"postmortem\", \"trigger\": \"{{alert.id}}\"}'",
                        timeout: 60,
                        continueOnError: true
                    )
                ],
                estimatedDuration: 300,
                autoExecute: true
            ),

            // Security vulnerability playbook
            ResponsePlaybook(
                name: "Security Vulnerability Response",
                description: "Respond to security vulnerability alerts",
                triggers: [.securityVulnerability],
                steps: [
                    ResponseStep(
                        type: .notification,
                        description: "Notify security team immediately",
                        timeout: 30,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Fetch vulnerability details from security scanner",
                        command: "GET /api/security/{{alert.context.vulnerabilityId}}",
                        timeout: 60,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .script,
                        description: "Run dependency update if fix available",
                        script: "updateDependencies.sh {{alert.context.packageName}}",
                        timeout: 300,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Create security advisory ticket",
                        command: "POST /api/security/tickets -d '{\"vulnerability\": \"{{alert.context.vulnerabilityId}}\", \"severity\": \"{{alert.severity}}\"}'",
                        timeout: 60,
                        continueOnError: true
                    )
                ],
                estimatedDuration: 600,
                autoExecute: false  // Requires human review
            ),

            // Performance degradation playbook
            ResponsePlaybook(
                name: "Performance Degradation Response",
                description: "Investigate and respond to performance issues",
                triggers: [.performanceDegradation],
                steps: [
                    ResponseStep(
                        type: .notification,
                        description: "Notify performance team",
                        timeout: 30,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Fetch performance metrics and profiles",
                        command: "GET /api/metrics/performance?from={{alert.timestamp}}",
                        timeout: 60,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .script,
                        description: "Analyze performance regression",
                        script: "analyzePerformance.sh",
                        timeout: 120,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .manualAction,
                        description: "Review and approve rollback if needed",
                        timeout: 300,
                        continueOnError: true
                    )
                ],
                estimatedDuration: 300,
                autoExecute: false
            ),

            // Deployment failure playbook
            ResponsePlaybook(
                name: "Deployment Failure Recovery",
                description: "Handle deployment failures and rollbacks",
                triggers: [.deploymentFailure],
                steps: [
                    ResponseStep(
                        type: .notification,
                        description: "Notify deployment team",
                        timeout: 30,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .apiCall,
                        description: "Fetch deployment logs",
                        command: "GET /api/deployments/{{alert.context.deploymentId}}/logs",
                        timeout: 60,
                        continueOnError: true
                    ),
                    ResponseStep(
                        type: .script,
                        description: "Automatic rollback to previous stable version",
                        script: "rollback.sh {{alert.context.deploymentId}}",
                        timeout: 180,
                        continueOnError: false
                    ),
                    ResponseStep(
                        type: .conditionCheck,
                        description: "Verify rollback success",
                        script: "verifyRollback.sh",
                        timeout: 60,
                        continueOnError: false
                    )
                ],
                estimatedDuration: 240,
                autoExecute: true
            )
        ]
    }

    private func loadActiveIncidents() {
        Task {
            let incidents = await incidentStore.loadActive()
            await MainActor.run {
                self.activeIncidents = incidents
            }
        }
    }

    private func addIncident(_ incident: Incident) async {
        await MainActor.run {
            activeIncidents.append(incident)
        }
        await incidentStore.save(incident)
    }

    private func updateIncident(_ incident: Incident) async {
        await MainActor.run {
            if let index = activeIncidents.firstIndex(where: { $0.id == incident.id }) {
                activeIncidents[index] = incident
            }
        }
        await incidentStore.save(incident)
    }

    private func findPlaybook(for alert: Alert) -> ResponsePlaybook? {
        return responsePlaybooks.first { $0.canHandle(alert) }
    }

    private func findAssignee(for alert: Alert) -> String? {
        // In production, query on-call rotation system
        switch alert.type {
        case .systemDown, .securityVulnerability:
            return "oncall"
        case .testFailure, .flakyTest:
            return "qa-team"
        case .performanceDegradation:
            return "performance-team"
        case .deploymentFailure:
            return "devops-team"
        case .buildFailure:
            return "build-team"
        }
    }

    private func mapIncidentSeverity(_ severity: AlertSeverity) -> IncidentSeverity {
        switch severity {
        case .info:
            return .low
        case .warning:
            return .medium
        case .error:
            return .high
        case .critical:
            return .critical
        }
    }

    private func savePlaybooks() {
        // In production, persist to database
    }

    private func calculateMostCommonPlaybooks() -> [(String, Int)] {
        let playbookCounts = Dictionary(grouping: activeIncidents) { $0.playbook?.name ?? "None" }
            .mapValues { $0.count }
        return playbookCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
}

// MARK: - Incident

public struct Incident: Identifiable, Codable {
    public let id: UUID
    public let alert: Alert
    public var status: IncidentStatus
    public let severity: IncidentSeverity
    public let assignedTo: String?
    public let playbook: ResponsePlaybook?
    public let startedAt: Date
    public var resolvedAt: Date?
    public var actions: [IncidentAction]
    public var timeline: [TimelineEvent]
    public var resolution: Resolution?

    public init(
        id: UUID = UUID(),
        alert: Alert,
        status: IncidentStatus,
        severity: IncidentSeverity,
        assignedTo: String?,
        playbook: ResponsePlaybook?,
        startedAt: Date = Date(),
        resolvedAt: Date? = nil,
        actions: [IncidentAction] = [],
        timeline: [TimelineEvent] = [],
        resolution: Resolution? = nil
    ) {
        self.id = id
        self.alert = alert
        self.status = status
        self.severity = severity
        self.assignedTo = assignedTo
        self.playbook = playbook
        self.startedAt = startedAt
        self.resolvedAt = resolvedAt
        self.actions = actions
        self.timeline = timeline
        self.resolution = resolution
    }

    public enum IncidentStatus: String, Codable {
        case open
        case acknowledged
        case investigating
        case resolving
        case resolved
        case closed
    }

    public enum IncidentSeverity: String, Codable {
        case low
        case medium
        case high
        case critical
    }
}

// MARK: - Response Playbook

public struct ResponsePlaybook: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let triggers: [AlertType]
    public let steps: [ResponseStep]
    public let estimatedDuration: TimeInterval
    public let autoExecute: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        triggers: [AlertType],
        steps: [ResponseStep],
        estimatedDuration: TimeInterval,
        autoExecute: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.triggers = triggers
        self.steps = steps
        self.estimatedDuration = estimatedDuration
        self.autoExecute = autoExecute
    }

    public func canHandle(_ alert: Alert) -> Bool {
        return triggers.contains(alert.type)
    }
}

// MARK: - Response Step

public struct ResponseStep: Identifiable, Codable {
    public let id: UUID
    public let type: StepType
    public let description: String
    public let command: String?
    public let script: String?
    public let timeout: TimeInterval
    public let continueOnError: Bool

    public init(
        id: UUID = UUID(),
        type: StepType,
        description: String,
        command: String? = nil,
        script: String? = nil,
        timeout: TimeInterval,
        continueOnError: Bool
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.command = command
        self.script = script
        self.timeout = timeout
        self.continueOnError = continueOnError
    }

    public enum StepType: String, Codable {
        case notification
        case script
        case apiCall
        case manualAction
        case delay
        case conditionCheck
    }
}

// MARK: - Incident Action

public struct IncidentAction: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: ActionType
    public let description: String
    public let performedBy: String
    public let result: ActionResult

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: ActionType,
        description: String,
        performedBy: String,
        result: ActionResult
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
        self.performedBy = performedBy
        self.result = result
    }

    public enum ActionType: String, Codable {
        case automated
        case manual
        case notification
        case escalation
    }

    public enum ActionResult: Codable {
        case success
        case failure(String)
        case partial(String)
        case skipped

        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }
    }
}

// MARK: - Timeline Event

public struct TimelineEvent: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: EventType
    public let description: String
    public let performedBy: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        description: String,
        performedBy: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
        self.performedBy = performedBy
    }

    public enum EventType: String, Codable {
        case created
        case acknowledged
        case action
        case statusChange
        case resolved
        case escalated
    }
}

// MARK: - Resolution

public struct Resolution: Codable {
    public let summary: String
    public let rootCause: String
    public let fix: String
    public let preventiveActions: [String]
    public let resolvedBy: String
    public let timestamp: Date

    public init(
        summary: String,
        rootCause: String,
        fix: String,
        preventiveActions: [String],
        resolvedBy: String,
        timestamp: Date = Date()
    ) {
        self.summary = summary
        self.rootCause = rootCause
        self.fix = fix
        self.preventiveActions = preventiveActions
        self.resolvedBy = resolvedBy
        self.timestamp = timestamp
    }
}

// MARK: - Incident Stats

public struct IncidentStats {
    public let totalActive: Int
    public let last24Hours: Int
    public let lastWeek: Int
    public let bySeverity: [Incident.IncidentSeverity: Int]
    public let byStatus: [Incident.IncidentStatus: Int]
    public let averageResolutionTime: TimeInterval
    public let mostCommonPlaybooks: [(String, Int)]

    public init(
        totalActive: Int,
        last24Hours: Int,
        lastWeek: Int,
        bySeverity: [Incident.IncidentSeverity: Int],
        byStatus: [Incident.IncidentStatus: Int],
        averageResolutionTime: TimeInterval,
        mostCommonPlaybooks: [(String, Int)]
    ) {
        self.totalActive = totalActive
        self.last24Hours = last24Hours
        self.lastWeek = lastWeek
        self.bySeverity = bySeverity
        self.byStatus = byStatus
        self.averageResolutionTime = averageResolutionTime
        self.mostCommonPlaybooks = mostCommonPlaybooks
    }
}

// MARK: - Playbook Executor

public class PlaybookExecutor {
    public static let shared = PlaybookExecutor()

    private init() {}

    public func execute(
        playbook: ResponsePlaybook,
        incident: Incident,
        actionCallback: @escaping (IncidentAction) -> Void
    ) async throws -> [ActionResult] {
        var results: [ActionResult] = []

        for step in playbook.steps {
            let result = try await executeStep(
                step: step,
                incident: incident
            )

            results.append(result)

            let action = IncidentAction(
                type: .automated,
                description: step.description,
                performedBy: "PlaybookExecutor",
                result: result
            )

            actionCallback(action)

            // Stop on failure if not continuing
            case .failure(let error):
                if !step.continueOnError {
                    throw PlaybookExecutionError.stepFailed(step.id, error)
                }

            case .partial:
                if !step.continueOnError {
                    break
                }

            case .success, .skipped:
                break
            }
        }

        return results
    }

    private func executeStep(
        step: ResponseStep,
        incident: Incident
    ) async throws -> ActionResult {
        switch step.type {
        case .notification:
            return await sendNotification(step: step, incident: incident)

        case .script:
            return try await executeScript(step: step, incident: incident)

        case .apiCall:
            return try await executeAPICall(step: step, incident: incident)

        case .manualAction:
            return .partial("Awaiting manual intervention")

        case .delay:
            try await executeDelay(step: step)
            return .success

        case .conditionCheck:
            return try await executeConditionCheck(step: step, incident: incident)
        }
    }

    private func sendNotification(step: ResponseStep, incident: Incident) async -> ActionResult {
        // Send notification via alert router
        // For now, return success
        return .success
    }

    private func executeScript(step: ResponseStep, incident: Incident) async throws -> ActionResult {
        guard let script = step.script else {
            return .failure("No script specified")
        }

        // Execute script with timeout
        let startTime = Date()

        // In production, execute script in isolated environment
        // For now, simulate execution
        try await Task.sleep(nanoseconds: UInt64(step.timeout * 1_000_000_000))

        let elapsed = Date().timeIntervalSince(startTime)

        if elapsed > step.timeout {
            return .failure("Script execution timed out")
        }

        return .success
    }

    private func executeAPICall(step: ResponseStep, incident: Incident) async throws -> ActionResult {
        guard let command = step.command else {
            return .failure("No command specified")
        }

        // Parse command and execute API call
        let startTime = Date()

        // In production, execute actual API call
        // For now, simulate execution
        try await Task.sleep(nanoseconds: UInt64(step.timeout * 1_000_000_000))

        let elapsed = Date().timeIntervalSince(startTime)

        if elapsed > step.timeout {
            return .failure("API call timed out")
        }

        return .success
    }

    private func executeDelay(step: ResponseStep) async throws {
        guard let command = step.command else {
            try await Task.sleep(nanoseconds: UInt64(step.timeout * 1_000_000_000))
            return
        }

        // Parse sleep command
        // For now, use timeout
        try await Task.sleep(nanoseconds: UInt64(step.timeout * 1_000_000_000))
    }

    private func executeConditionCheck(step: ResponseStep, incident: Incident) async throws -> ActionResult {
        guard let script = step.script else {
            return .failure("No script specified")
        }

        // Execute condition check script
        // For now, return success
        return .success
    }
}

public enum PlaybookExecutionError: Error {
    case stepFailed(UUID, String)
    case playbookNotFound
    case executionTimeout
}

// MARK: - Incident Store

public class IncidentStore {
    public static let shared = IncidentStore()

    private init() {}

    public func save(_ incident: Incident) async {
        // In production, save to database
        print("Saving incident: \(incident.id)")
    }

    public func loadActive() async -> [Incident] {
        // In production, load from database
        return []
    }

    public func archive(_ incident: Incident) async {
        // In production, archive to cold storage
        print("Archiving incident: \(incident.id)")
    }
}

// MARK: - Shared Types

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

public struct Alert: Identifiable, Codable {
    public let id: UUID
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let source: String
    public let timestamp: Date
    public let context: [String: String]

    public init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        source: String,
        timestamp: Date = Date(),
        context: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.source = source
        self.timestamp = timestamp
        self.context = context
    }
}
