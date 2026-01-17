import Foundation
import Combine

/// Manages feature flags for dynamic feature toggling and gradual rollouts
public class FeatureFlagManager: ObservableObject {
    // MARK: - Published Properties
    @Published public var flags: [FeatureFlag] = []
    @Published public var flagHistory: [FlagChange] = []
    @Published public var isLoading: Bool = false

    // MARK: - Private Properties
    private var flagStore: FeatureFlagStore
    private var evaluationContext: EvaluationContext
    private var remoteConfig: RemoteConfigProvider
    private var analytics: FlagAnalytics
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    public init(
        flagStore: FeatureFlagStore = CoreDataFlagStore(),
        evaluationContext: EvaluationContext = .default,
        remoteConfig: RemoteConfigProvider = FirebaseRemoteConfig(),
        analytics: FlagAnalytics = .shared
    ) {
        self.flagStore = flagStore
        self.evaluationContext = evaluationContext
        self.remoteConfig = remoteConfig
        self.analytics = analytics

        loadFlags()
        startAutoRefresh()
    }

    // MARK: - Public Methods

    /// Create a new feature flag
    public func createFlag(_ flag: FeatureFlag) async throws {
        NSLog("[FeatureFlag] Creating flag: \(flag.name)")

        // Validate flag
        try validateFlag(flag)

        // Check for duplicate
        if flags.contains(where: { $0.name == flag.name }) {
            throw FeatureFlagError.duplicateFlag(flag.name)
        }

        // Check dependencies exist
        for dependency in flag.dependencies {
            if !flags.contains(where: { $0.name == dependency }) {
                throw FeatureFlagError.dependencyNotFound(dependency)
            }
        }

        // Save flag
        try await flagStore.saveFlag(flag)

        // Add to collection
        flags.append(flag)

        // Record change
        recordChange(
            flagName: flag.name,
            oldValue: nil,
            newValue: flag,
            reason: "Flag created"
        )

        // Track creation
        await analytics.trackFlagEvent(.created, flag: flag)

        NSLog("[FeatureFlag] Flag \(flag.name) created successfully")
    }

    /// Update an existing feature flag
    public func updateFlag(_ flag: FeatureFlag) async throws {
        NSLog("[FeatureFlag] Updating flag: \(flag.name)")

        guard let index = flags.firstIndex(where: { $0.name == flag.name }) else {
            throw FeatureFlagError.flagNotFound(flag.name)
        }

        let oldValue = flags[index]

        // Validate updated flag
        try validateFlag(flag)

        // Check dependencies
        for dependency in flag.dependencies {
            if !flags.contains(where: { $0.name == dependency && $0.name != flag.name }) {
                throw FeatureFlagError.dependencyNotFound(dependency)
            }
        }

        // Save updated flag
        try await flagStore.saveFlag(flag)

        // Update collection
        flags[index] = flag

        // Record change
        recordChange(
            flagName: flag.name,
            oldValue: oldValue,
            newValue: flag,
            reason: "Flag updated"
        )

        // Track update
        await analytics.trackFlagEvent(.updated, flag: flag)

        NSLog("[FeatureFlag] Flag \(flag.name) updated successfully")
    }

    /// Delete a feature flag
    public func deleteFlag(id: String) async throws {
        NSLog("[FeatureFlag] Deleting flag: \(id)")

        guard let index = flags.firstIndex(where: { $0.id.uuidString == id }) else {
            throw FeatureFlagError.flagNotFound(id)
        }

        let flag = flags[index]

        // Check if other flags depend on this one
        let dependents = flags.filter { $0.dependencies.contains(flag.name) }
        if !dependents.isEmpty {
            throw FeatureFlagError.flagHasDependents(flag.name, dependents.map { $0.name })
        }

        // Delete from store
        try await flagStore.deleteFlag(flag)

        // Remove from collection
        flags.remove(at: index)

        // Record change
        recordChange(
            flagName: flag.name,
            oldValue: flag,
            newValue: nil,
            reason: "Flag deleted"
        )

        // Track deletion
        await analytics.trackFlagEvent(.deleted, flag: flag)

        NSLog("[FeatureFlag] Flag \(flag.name) deleted successfully")
    }

    /// Check if a flag is enabled for a given user
    public func isEnabled(_ flagName: String, for user: User?) -> Bool {
        guard let flag = flags.first(where: { $0.name == flagName }) else {
            NSLog("[FeatureFlag] Flag not found: \(flagName)")
            return false
        }

        // Check if flag is enabled globally
        guard flag.enabled else {
            return false
        }

        // Check dependencies
        for dependency in flag.dependencies {
            guard isEnabled(dependency, for: user) else {
                return false
            }
        }

        // Evaluate targeting rules
        return evaluateFlag(flag, for: user)
    }

    /// Get the value of a flag for a given user
    public func getFlagValue<T>(_ flagName: String, for user: User?) -> T? where T: FlagValueCompatible {
        guard let flag = flags.first(where: { $0.name == flagName }) else {
            return nil
        }

        guard isEnabled(flagName, for: user) else {
            return nil
        }

        return flag.value?.as(type: T.self)
    }

    /// Roll out a flag to a percentage of users
    public func rollOutFlag(_ flagName: String, percentage: Int) async throws {
        NSLog("[FeatureFlag] Rolling out flag \(flagName) to \(percentage)%")

        guard (0...100).contains(percentage) else {
            throw FeatureFlagError.invalidPercentage(percentage)
        }

        guard let index = flags.firstIndex(where: { $0.name == flagName }) else {
            throw FeatureFlagError.flagNotFound(flagName)
        }

        var flag = flags[index]

        // Update rollout strategy
        let updatedStrategy = RolloutStrategy(
            type: flag.rolloutStrategy.type,
            percentage: percentage,
            rules: flag.rolloutStrategy.rules,
            schedule: flag.rolloutStrategy.schedule
        )

        flag = FeatureFlag(
            id: flag.id,
            name: flag.name,
            description: flag.description,
            type: flag.type,
            enabled: flag.enabled,
            value: flag.value,
            rolloutStrategy: updatedStrategy,
            targetingRules: flag.targetingRules,
            dependencies: flag.dependencies,
            createdAt: flag.createdAt,
            updatedAt: Date(),
            createdBy: flag.createdBy,
            tags: flag.tags
        )

        try await updateFlag(flag)

        NSLog("[FeatureFlag] Flag \(flagName) rolled out to \(percentage)%")
    }

    /// Enable/disable a flag
    public func setFlagEnabled(_ flagName: String, enabled: Bool) async throws {
        guard let index = flags.firstIndex(where: { $0.name == flagName }) else {
            throw FeatureFlagError.flagNotFound(flagName)
        }

        var flag = flags[index]
        flag.enabled = enabled

        try await updateFlag(flag)

        NSLog("[FeatureFlag] Flag \(flagName) \(enabled ? "enabled" : "disabled")")
    }

    /// Refresh flags from remote source
    public func refreshFlags() async throws {
        NSLog("[FeatureFlag] Refreshing flags from remote")

        isLoading = true

        do {
            let remoteFlags = try await remoteConfig.fetchFlags()

            // Merge remote flags with local flags
            for remoteFlag in remoteFlags {
                if let localIndex = flags.firstIndex(where: { $0.name == remoteFlag.name }) {
                    // Update existing flag
                    flags[localIndex] = remoteFlag
                } else {
                    // Add new flag
                    flags.append(remoteFlag)
                }
            }

            // Save to local store
            try await flagStore.saveFlags(flags)

            NSLog("[FeatureFlag] Refreshed \(remoteFlags.count) flags")

        } catch {
            NSLog("[FeatureFlag] Refresh failed: \(error.localizedDescription)")
            throw error
        }

        isLoading = false
    }

    /// Get flag by name
    public func getFlag(_ name: String) -> FeatureFlag? {
        return flags.first { $0.name == name }
    }

    /// Get flags by tag
    public func getFlagsByTag(_ tag: String) -> [FeatureFlag] {
        return flags.filter { $0.tags.contains(tag) }
    }

    /// Get flag change history
    public func getFlagHistory(_ flagName: String) -> [FlagChange] {
        return flagHistory.filter { $0.flagName == flagName }
            .sorted { $0.changedAt > $1.changedAt }
    }

    // MARK: - Private Methods

    private func validateFlag(_ flag: FeatureFlag) throws {
        // Validate name
        guard !flag.name.isEmpty else {
            throw FeatureFlagError.invalidName("Flag name cannot be empty")
        }

        guard flag.name.matches(regex: "^[a-zA-Z0-9_-]+$") else {
            throw FeatureFlagError.invalidName("Flag name can only contain alphanumeric characters, hyphens, and underscores")
        }

        // Validate type and value match
        switch (flag.type, flag.value) {
        case (.boolean, .boolean(let value)):
            if value != true && value != false {
                throw FeatureFlagError.typeMismatch("Boolean flag requires boolean value")
            }
        case (.string, .string):
            break
        case (.number, .number):
            break
        case (.json, .json):
            break
        case (_, .none):
            break // No value is okay
        default:
            throw FeatureFlagError.typeMismatch("Flag type and value type do not match")
        }

        // Validate rollout strategy
        if flag.rolloutStrategy.type == .canary && flag.rolloutStrategy.percentage == 0 {
            throw FeatureFlagError.invalidRolloutStrategy("Canary rollout requires percentage > 0")
        }

        // Validate targeting rules
        for rule in flag.targetingRules {
            for condition in rule.conditions {
                try validateCondition(condition)
            }
        }
    }

    private func validateCondition(_ condition: RuleCondition) throws {
        // Validate condition operator and value
        switch condition.operator {
        case .equals, .contains, .startsWith, .endsWith:
            break // These operators work with any value
        case .matches:
            guard condition.value.starts(with: "^") || condition.value.contains(".*") else {
                throw FeatureFlagError.invalidCondition("Regex pattern must be valid")
            }
        case .in, .notIn:
            // Value should be comma-separated list
            break
        }
    }

    private func evaluateFlag(_ flag: FeatureFlag, for user: User?) -> Bool {
        // Apply targeting rules in priority order
        let sortedRules = flag.targetingRules.sorted { $0.priority > $1.priority }

        for rule in sortedRules {
            if matchesRule(rule, user: user) {
                return rule.value
            }
        }

        // Fall back to rollout strategy
        return evaluateRolloutStrategy(flag.rolloutStrategy, user: user)
    }

    private func matchesRule(_ rule: TargetingRule, user: User?) -> Bool {
        guard let user = user else {
            return false
        }

        // All conditions must match
        for condition in rule.conditions {
            if !matchesCondition(condition, user: user) {
                return false
            }
        }

        return true
    }

    private func matchesCondition(_ condition: RuleCondition, user: User) -> Bool {
        let attributeValue: String?

        switch condition.type {
        case .userId:
            attributeValue = user.id
        case .userEmail:
            attributeValue = user.email
        case .userAttribute:
            attributeValue = user.attributes[condition.value] as? String
        case .country:
            attributeValue = user.country
        case .deviceType:
            attributeValue = user.deviceType
        case .appVersion:
            attributeValue = user.appVersion
        case .custom:
            attributeValue = user.customAttributes[condition.value] as? String
        }

        guard let value = attributeValue else {
            return false
        }

        return evaluateCondition(value, against: condition)
    }

    private func evaluateCondition(_ value: String, against condition: RuleCondition) -> Bool {
        switch condition.operator {
        case .equals:
            return value == condition.value
        case .contains:
            return value.contains(condition.value)
        case .startsWith:
            return value.hasPrefix(condition.value)
        case .endsWith:
            return value.hasSuffix(condition.value)
        case .matches:
            return value.matches(regex: condition.value)
        case .in:
            let values = condition.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return values.contains(value)
        case .notIn:
            let values = condition.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return !values.contains(value)
        }
    }

    private func evaluateRolloutStrategy(_ strategy: RolloutStrategy, user: User?) -> Bool {
        switch strategy.type {
        case .allOrNothing:
            return strategy.percentage == 100
        case .gradual:
            return evaluatePercentageRollout(strategy.percentage, user: user)
        case .canary:
            return evaluatePercentageRollout(strategy.percentage, user: user)
        case .targeted:
            return false // Handled by targeting rules
        case .experiment:
            return evaluatePercentageRollout(strategy.percentage, user: user)
        }
    }

    private func evaluatePercentageRollout(_ percentage: Int, user: User?) -> Bool {
        guard let user = user else {
            return false
        }

        // Use consistent hashing for the same user
        let hash = user.id.hashValue
        let bucket = abs(hash % 100)

        return bucket < percentage
    }

    private func loadFlags() {
        Task {
            do {
                flags = try await flagStore.loadFlags()
                NSLog("[FeatureFlag] Loaded \(flags.count) flags")
            } catch {
                NSLog("[FeatureFlag] Failed to load flags: \(error.localizedDescription)")
            }
        }
    }

    private func startAutoRefresh() {
        // Refresh flags every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try? await self?.refreshFlags()
            }
        }
    }

    private func recordChange(flagName: String, oldValue: FeatureFlag?, newValue: FeatureFlag?, reason: String) {
        let change = FlagChange(
            flagName: flagName,
            oldValue: oldValue,
            newValue: newValue ?? oldValue!,
            changedBy: evaluationContext.currentUser?.id ?? "system",
            changedAt: Date(),
            reason: reason
        )

        flagHistory.append(change)
    }
}

// MARK: - Supporting Types

public struct FeatureFlag: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let type: FlagType
    public var enabled: Bool
    public let value: FlagValue?
    public var rolloutStrategy: RolloutStrategy
    public let targetingRules: [TargetingRule]
    public let dependencies: [String]
    public let createdAt: Date
    public let updatedAt: Date
    public let createdBy: String
    public let tags: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: FlagType,
        enabled: Bool,
        value: FlagValue?,
        rolloutStrategy: RolloutStrategy,
        targetingRules: [TargetingRule],
        dependencies: [String],
        createdAt: Date,
        updatedAt: Date,
        createdBy: String,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.enabled = enabled
        self.value = value
        self.rolloutStrategy = rolloutStrategy
        self.targetingRules = targetingRules
        self.dependencies = dependencies
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.tags = tags
    }

    public enum FlagType: String, Codable {
        case boolean = "boolean"
        case string = "string"
        case number = "number"
        case json = "json"
    }
}

public enum FlagValue: Codable {
    case boolean(Bool)
    case string(String)
    case number(Double)
    case json([String: Any])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            self = .boolean(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let jsonValue = try? container.decode([String: String].self) {
            // Simplified JSON handling
            var dict: [String: Any] = [:]
            for (key, value) in jsonValue {
                dict[key] = value
            }
            self = .json(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "FlagValue cannot be decoded"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .boolean(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .json(let value):
            try container.encode(value)
        }
    }

    public func `as`<T>(type: T.Type) -> T? where T: FlagValueCompatible {
        switch self {
        case .boolean(let value):
            return value as? T
        case .string(let value):
            return value as? T
        case .number(let value):
            return value as? T
        case .json:
            return nil
        }
    }
}

public protocol FlagValueCompatible {}
extension Bool: FlagValueCompatible {}
extension String: FlagValueCompatible {}
extension Double: FlagValueCompatible {}

public struct RolloutStrategy: Codable {
    public let type: StrategyType
    public let percentage: Int
    public let rules: [RolloutRule]
    public let schedule: RolloutSchedule?

    public init(
        type: StrategyType,
        percentage: Int,
        rules: [RolloutRule],
        schedule: RolloutSchedule?
    ) {
        self.type = type
        self.percentage = percentage
        self.rules = rules
        self.schedule = schedule
    }

    public enum StrategyType: String, Codable {
        case allOrNothing = "all_or_nothing"
        case gradual = "gradual"
        case canary = "canary"
        case targeted = "targeted"
        case experiment = "experiment"
    }
}

public struct RolloutRule: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let condition: RuleCondition
    public let value: Bool
    public let priority: Int

    public init(
        id: UUID = UUID(),
        name: String,
        condition: RuleCondition,
        value: Bool,
        priority: Int
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.value = value
        self.priority = priority
    }
}

public struct RuleCondition: Codable {
    public let type: ConditionType
    public let `operator`: ConditionOperator
    public let value: String

    public init(
        type: ConditionType,
        operator: ConditionOperator,
        value: String
    ) {
        self.type = type
        self.operator = `operator`
        self.value = value
    }

    public enum ConditionType: String, Codable {
        case userId = "user_id"
        case userEmail = "user_email"
        case userAttribute = "user_attribute"
        case country = "country"
        case deviceType = "device_type"
        case appVersion = "app_version"
        case custom = "custom"
    }

    public enum ConditionOperator: String, Codable {
        case equals = "equals"
        case contains = "contains"
        case startsWith = "starts_with"
        case endsWith = "ends_with"
        case matches = "matches"
        case `in` = "in"
        case notIn = "not_in"
    }
}

public struct TargetingRule: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let conditions: [RuleCondition]
    public let percentage: Int
    public let value: FlagValue?

    public init(
        id: UUID = UUID(),
        name: String,
        conditions: [RuleCondition],
        percentage: Int,
        value: FlagValue?
    ) {
        self.id = id
        self.name = name
        self.conditions = conditions
        self.percentage = percentage
        self.value = value
    }
}

public struct RolloutSchedule: Codable {
    public let startAt: Date
    public let endAt: Date?
    public let steps: [ScheduledStep]
}

public struct ScheduledStep: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let percentage: Int
    public let notifyStakeholders: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        percentage: Int,
        notifyStakeholders: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.percentage = percentage
        self.notifyStakeholders = notifyStakeholders
    }
}

public struct FlagChange: Identifiable, Codable {
    public let id: UUID
    public let flagName: String
    public let oldValue: FeatureFlag?
    public let newValue: FeatureFlag
    public let changedBy: String
    public let changedAt: Date
    public let reason: String?

    public init(
        id: UUID = UUID(),
        flagName: String,
        oldValue: FeatureFlag?,
        newValue: FeatureFlag,
        changedBy: String,
        changedAt: Date,
        reason: String?
    ) {
        self.id = id
        self.flagName = flagName
        self.oldValue = oldValue
        self.newValue = newValue
        self.changedBy = changedBy
        self.changedAt = changedAt
        self.reason = reason
    }
}

public enum FeatureFlagError: LocalizedError {
    case duplicateFlag(String)
    case flagNotFound(String)
    case dependencyNotFound(String)
    case flagHasDependents(String, [String])
    case invalidName(String)
    case typeMismatch(String)
    case invalidRolloutStrategy(String)
    case invalidCondition(String)
    case invalidPercentage(Int)

    public var errorDescription: String? {
        switch self {
        case .duplicateFlag(let name):
            return "Flag '\(name)' already exists"
        case .flagNotFound(let name):
            return "Flag '\(name)' not found"
        case .dependencyNotFound(let name):
            return "Dependency '\(name)' not found"
        case .flagHasDependents(let name, let dependents):
            return "Flag '\(name)' has dependents: \(dependents.joined(separator: ", "))"
        case .invalidName(let message):
            return "Invalid flag name: \(message)"
        case .typeMismatch(let message):
            return "Type mismatch: \(message)"
        case .invalidRolloutStrategy(let message):
            return "Invalid rollout strategy: \(message)"
        case .invalidCondition(let message):
            return "Invalid condition: \(message)"
        case .invalidPercentage(let percentage):
            return "Invalid percentage: \(percentage)"
        }
    }
}

// MARK: - Supporting Protocols

public protocol FeatureFlagStore {
    func saveFlag(_ flag: FeatureFlag) async throws
    func saveFlags(_ flags: [FeatureFlag]) async throws
    func loadFlags() async throws -> [FeatureFlag]
    func deleteFlag(_ flag: FeatureFlag) async throws
}

public class CoreDataFlagStore: FeatureFlagStore {
    public init() {}

    public func saveFlag(_ flag: FeatureFlag) async throws {
        // In production, save to CoreData
        NSLog("[FlagStore] Saved flag: \(flag.name)")
    }

    public func saveFlags(_ flags: [FeatureFlag]) async throws {
        NSLog("[FlagStore] Saved \(flags.count) flags")
    }

    public func loadFlags() async throws -> [FeatureFlag] {
        return []
    }

    public func deleteFlag(_ flag: FeatureFlag) async throws {
        NSLog("[FlagStore] Deleted flag: \(flag.name)")
    }
}

public protocol RemoteConfigProvider {
    func fetchFlags() async throws -> [FeatureFlag]
}

public class FirebaseRemoteConfig: RemoteConfigProvider {
    public init() {}

    public func fetchFlags() async throws -> [FeatureFlag] {
        // In production, fetch from Firebase Remote Config
        return []
    }
}

public struct EvaluationContext {
    let currentUser: User?
    let environment: String
    let deviceInfo: DeviceInfo

    public static let `default` = EvaluationContext(
        currentUser: nil,
        environment: "production",
        deviceInfo: DeviceInfo()
    )
}

public struct User {
    let id: String
    let email: String?
    let country: String?
    let deviceType: String?
    let appVersion: String?
    let attributes: [String: Any]
    let customAttributes: [String: Any]
}

public struct DeviceInfo {
    let platform: String
    let osVersion: String
    let model: String

    init() {
        self.platform = "iOS"
        self.osVersion = "17.0"
        self.model = "iPhone"
    }
}

public class FlagAnalytics {
    public static let shared = FlagAnalytics()

    private init() {}

    public func trackFlagEvent(_ event: FlagEventType, flag: FeatureFlag) async {
        NSLog("[Analytics] Flag event: \(event) for \(flag.name)")
    }

    public enum FlagEventType {
        case created
        case updated
        case deleted
        case evaluated
        case enabled
        case disabled
    }
}

// MARK: - String Extensions

private extension String {
    func matches(regex: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regex) else {
            return false
        }

        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
