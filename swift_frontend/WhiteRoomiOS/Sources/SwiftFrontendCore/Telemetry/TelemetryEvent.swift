//
//  TelemetryEvent.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - Telemetry Event
// =============================================================================

/**
 Core telemetry event data model

 Represents a single telemetry event with complete context:
 - Unique identifier for deduplication
 - Timestamp for temporal analysis
 - Event type categorization
 - Screen and element context
 - User and session association
 - Custom metadata

 Thread-safe and Codable for persistence.
 */
public struct TelemetryEvent: Codable, Sendable {
    // MARK: - Properties

    /// Unique event identifier
    public let id: UUID

    /// Event timestamp
    public let timestamp: Date

    /// Event type categorization
    public let type: TelemetryEventType

    /// Screen where event occurred
    public let screen: String

    /// UI element identifier (optional)
    public let element: String?

    /// Action description
    public let action: String

    /// Additional context data
    public let context: [String: String]

    /// User identifier (optional)
    public let userId: String?

    /// Session identifier
    public let sessionId: String

    // MARK: - Initialization

    /**
     Create a new telemetry event

     - Parameters:
       - type: Event type
       - screen: Screen name
       - element: Element identifier (optional)
       - action: Action description
       - context: Additional context data
       - userId: User identifier (optional)
       - sessionId: Session identifier (defaults to new UUID)
     */
    public init(
        type: TelemetryEventType,
        screen: String,
        element: String? = nil,
        action: String,
        context: [String: String] = [:],
        userId: String? = nil,
        sessionId: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.screen = screen
        self.element = element
        self.action = action
        self.context = context
        self.userId = userId
        self.sessionId = sessionId ?? UUID().uuidString
    }

    // MARK: - Coding Keys

    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case type
        case screen
        case element
        case action
        case context
        case userId
        case sessionId
    }
}

// =============================================================================
// MARK: - Telemetry Event Type
// =============================================================================

/**
 Event type categorization for filtering and analysis
 */
public enum TelemetryEventType: String, Codable, CaseIterable {
    /// User interaction (tap, gesture, etc.)
    case uiInteraction = "ui_interaction"

    /// Performance measurement
    case performance = "performance"

    /// Screen navigation
    case navigation = "navigation"

    /// Error or exception
    case error = "error"

    /// Custom event type
    case custom = "custom"

    /// User-readable description
    public var description: String {
        switch self {
        case .uiInteraction:
            return "UI Interaction"
        case .performance:
            return "Performance"
        case .navigation:
            return "Navigation"
        case .error:
            return "Error"
        case .custom:
            return "Custom"
        }
    }

    /// Category for breadcrumb logging
    public var breadcrumbCategory: String {
        switch self {
        case .uiInteraction:
            return "ui"
        case .performance:
            return "performance"
        case .navigation:
            return "navigation"
        case .error:
            return "error"
        case .custom:
            return "custom"
        }
    }
}

// =============================================================================
// MARK: - Telemetry Context Builder
// =============================================================================

/**
 Builder for creating telemetry context with common fields

 Usage:
 ```swift
 let context = TelemetryContextBuilder()
     .addValue("preset_name", preset.name)
     .addValue("bpm", String(tempo))
     .addUserInfo()
     .build()
 ```
 */
public struct TelemetryContextBuilder {
    private var context: [String: String] = [:]

    public init() {}

    /**
     Add a key-value pair

     - Parameters:
       - key: Context key
       - value: Context value
     - Returns: Builder for chaining
     */
    public func addValue(_ key: String, _ value: String) -> TelemetryContextBuilder {
        var builder = self
        builder.context[key] = value
        return builder
    }

    /**
     Add an integer value

     - Parameters:
       - key: Context key
       - value: Integer value
     - Returns: Builder for chaining
     */
    public func addInt(_ key: String, _ value: Int) -> TelemetryContextBuilder {
        var builder = self
        builder.context[key] = String(value)
        return builder
    }

    /**
     Add a double value

     - Parameters:
       - key: Context key
       - value: Double value
     - Returns: Builder for chaining
     */
    public func addDouble(_ key: String, _ value: Double) -> TelemetryContextBuilder {
        var builder = self
        builder.context[key] = String(format: "%.2f", value)
        return builder
    }

    /**
     Add a boolean value

     - Parameters:
       - key: Context key
       - value: Boolean value
     - Returns: Builder for chaining
     */
    public func addBool(_ key: String, _ value: Bool) -> TelemetryContextBuilder {
        var builder = self
        builder.context[key] = value ? "true" : "false"
        return builder
    }

    /**
     Add user information (if available)

     - Returns: Builder for chaining
     */
    public func addUserInfo() -> TelemetryContextBuilder {
        var builder = self

        // Add device info
        builder.context["device_model"] = UIDevice.current.model
        builder.context["system_version"] = UIDevice.current.systemVersion

        // Add app info
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            builder.context["app_version"] = version
        }

        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            builder.context["build_number"] = build
        }

        return builder
    }

    /**
     Build the context dictionary

     - Returns: Context dictionary
     */
    public func build() -> [String: String] {
        context
    }
}

// =============================================================================
// MARK: - Telemetry Event Extensions
// =============================================================================

public extension TelemetryEvent {

    // MARK: - Convenience Initializers

    /**
     Create a UI interaction event

     - Parameters:
       - screen: Screen name
       - element: Element identifier
       - action: Action description
       - context: Additional context

     - Returns: Configured telemetry event
     */
    static func uiInteraction(
        screen: String,
        element: String,
        action: String,
        context: [String: String] = [:]
    ) -> TelemetryEvent {
        TelemetryEvent(
            type: .uiInteraction,
            screen: screen,
            element: element,
            action: action,
            context: context
        )
    }

    /**
     Create a performance event

     - Parameters:
       - screen: Screen name
       - operation: Operation name
       - duration: Duration in seconds
       - threshold: Warning threshold
       - context: Additional context

     - Returns: Configured telemetry event
     */
    static func performance(
        screen: String,
        operation: String,
        duration: TimeInterval,
        threshold: TimeInterval,
        context: [String: String] = [:]
    ) -> TelemetryEvent {
        var augmentedContext = context
        augmentedContext["operation"] = operation
        augmentedContext["duration"] = String(format: "%.3f", duration)
        augmentedContext["threshold"] = String(format: "%.3f", threshold)
        augmentedContext["exceeded_threshold"] = duration > threshold ? "true" : "false"

        return TelemetryEvent(
            type: .performance,
            screen: screen,
            element: nil,
            action: "Performance: \(operation)",
            context: augmentedContext
        )
    }

    /**
     Create a navigation event

     - Parameters:
       - from: Source screen
       - to: Destination screen
       - context: Additional context

     - Returns: Configured telemetry event
     */
    static func navigation(
        from: String,
        to: String,
        context: [String: String] = [:]
    ) -> TelemetryEvent {
        var augmentedContext = context
        augmentedContext["destination"] = to

        return TelemetryEvent(
            type: .navigation,
            screen: from,
            element: nil,
            action: "Navigate to \(to)",
            context: augmentedContext
        )
    }

    /**
     Create an error event

     - Parameters:
       - screen: Screen name
       - error: Error description
       - element: Related element (optional)
       - context: Additional context

     - Returns: Configured telemetry event
     */
    static func error(
        screen: String,
        error: String,
        element: String? = nil,
        context: [String: String] = [:]
    ) -> TelemetryEvent {
        var augmentedContext = context
        augmentedContext["error"] = error

        return TelemetryEvent(
            type: .error,
            screen: screen,
            element: element,
            action: "Error: \(error)",
            context: augmentedContext
        )
    }

    // MARK: - Validation

    /**
     Validate event has required fields

     - Returns: True if valid
     */
    var isValid: Bool {
        !screen.isEmpty && !action.isEmpty
    }

    // MARK: - Description

    /**
     Human-readable description
     */
    var description: String {
        var parts: [String] = []

        parts.append("[\(type.rawValue)]")

        if let element = element {
            parts.append(element)
        }

        parts.append(action)

        if !context.isEmpty {
            let contextStr = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("(\(contextStr))")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Export

    /**
     Convert to dictionary for Crashlytics context

     - Returns: Dictionary representation
     */
    func toCrashlyticsContext() -> [String: Any] {
        var dict: [String: Any] = [
            "event_id": id.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "type": type.rawValue,
            "screen": screen,
            "action": action,
            "session_id": sessionId
        ]

        if let element = element {
            dict["element"] = element
        }

        if let userId = userId {
            dict["user_id"] = userId
        }

        for (key, value) in context {
            dict["context_\(key)"] = value
        }

        return dict
    }
}

// =============================================================================
// MARK: - Telemetry Event Batch
// =============================================================================

/**
 Batch of telemetry events for efficient transmission
 */
public struct TelemetryEventBatch: Codable {
    public let events: [TelemetryEvent]
    public let timestamp: Date
    public let sessionId: String

    public init(events: [TelemetryEvent], sessionId: String) {
        self.events = events
        self.timestamp = Date()
        self.sessionId = sessionId
    }

    /// Check if batch is empty
    public var isEmpty: Bool {
        events.isEmpty
    }

    /// Get event count
    public var count: Int {
        events.count
    }

    /// Get batch size in bytes (estimated)
    public var estimatedSize: Int {
        // Rough estimate: 500 bytes per event
        events.count * 500
    }
}
