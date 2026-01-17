//
//  TelemetryValidator.swift
//  SwiftFrontendCore
//
//  Custom event validation for telemetry
//

import Foundation

/// Telemetry event validator for quality assurance
public class TelemetryValidator {
    public static let shared = TelemetryValidator()

    private init() {}

    // MARK: - Event Validation

    /// Validate a single telemetry event
    public func validateEvent(_ event: TelemetryEvent) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Validate required fields
        if event.type == .uiInteraction && event.element == nil {
            errors.append("UI interaction events must have an element")
        }

        if event.screen.isEmpty {
            warnings.append("Events without screen context are harder to debug")
        }

        if event.action.isEmpty {
            errors.append("Events must have a non-empty action")
        }

        // Validate timestamps
        if event.timestamp > Date() {
            errors.append("Event timestamp is in the future")
        }

        // Very old events (more than 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        if event.timestamp < thirtyDaysAgo {
            warnings.append("Event timestamp is more than 30 days old")
        }

        // Validate context data
        if event.context.count > 20 {
            warnings.append("Events with >20 context items may impact performance")
        }

        // Check for extremely long values
        for (key, value) in event.context {
            if key.count > 100 {
                warnings.append("Context key '\(key.prefix(20))...' is very long (>100 chars)")
            }
            if value.count > 500 {
                warnings.append("Context value for '\(key)' is very long (>500 chars)")
            }
        }

        // Validate session ID
        if event.sessionId.isEmpty {
            errors.append("Events must have a session ID")
        }

        // Validate user ID format (if present)
        if let userId = event.userId {
            if userId.isEmpty {
                warnings.append("User ID is present but empty")
            } else if userId.count > 100 {
                warnings.append("User ID is very long (>100 chars)")
            }
        }

        // Validate event type consistency
        if event.type == .performance {
            if event.context["duration"] == nil {
                errors.append("Performance events must have duration in context")
            }
            if event.context["threshold"] == nil {
                warnings.append("Performance events should have threshold in context")
            }
        }

        if event.type == .error {
            if event.context["error_description"] == nil && event.element == nil {
                warnings.append("Error events should have error_description or element")
            }
        }

        return ValidationResult(errors: errors, warnings: warnings)
    }

    /// Validate a session of events
    public func validateSession(_ session: [TelemetryEvent]) -> SessionValidationResult {
        var totalEvents = session.count
        var invalidEvents = 0
        var warnings = 0
        var errorDetails: [String] = []
        var warningDetails: [String] = []

        for event in session {
            let result = validateEvent(event)

            if !result.errors.isEmpty {
                invalidEvents += 1
                errorDetails.append(contentsOf: result.errors.map { error in
                    "[\(event.type.rawValue)] \(event.action): \(error)"
                })
            }

            if !result.warnings.isEmpty {
                warnings += 1
                warningDetails.append(contentsOf: result.warnings.map { warning in
                    "[\(event.type.rawValue)] \(event.action): \(warning)"
                })
            }
        }

        // Check session continuity
        if totalEvents > 1 {
            let sortedEvents = session.sorted { $0.timestamp < $1.timestamp }
            let timeGaps = zip(sortedEvents, sortedEvents.dropFirst()).map { current, next in
                next.timestamp.timeIntervalSince(current.timestamp)
            }

            // Check for large time gaps (>5 minutes)
            let largeGaps = timeGaps.filter { $0 > 300 }
            if !largeGaps.isEmpty {
                warningDetails.append("Session has \(largeGaps.count) large time gaps (>5 min)")
            }
        }

        return SessionValidationResult(
            totalEvents: totalEvents,
            validEvents: totalEvents - invalidEvents,
            invalidEvents: invalidEvents,
            warnings: warnings,
            isValid: invalidEvents == 0,
            errorDetails: errorDetails,
            warningDetails: warningDetails
        )
    }

    /// Validate batch of events for transmission
    public func validateBatch(_ batch: TelemetryEventBatch) -> BatchValidationResult {
        let sessionResult = validateSession(batch.events)

        // Additional batch-level validations
        var batchErrors: [String] = []
        var batchWarnings: [String] = []

        // Check batch size
        if batch.count > 1000 {
            batchWarnings.append("Batch size (\(batch.count)) is large (>1000 events)")
        }

        // Check estimated size
        if batch.estimatedSize > 1_000_000 { // >1MB
            batchWarnings.append("Batch estimated size (\(batch.estimatedSize) bytes) is large (>1MB)")
        }

        // Check batch timestamp
        let batchAge = Date().timeIntervalSince(batch.timestamp)
        if batchAge > 3600 { // >1 hour old
            batchWarnings.append("Batch is \(Int(batchAge / 60)) minutes old - consider sending immediately")
        }

        return BatchValidationResult(
            sessionValidation: sessionResult,
            batchErrors: batchErrors,
            batchWarnings: batchWarnings,
            isValid: sessionResult.isValid && batchErrors.isEmpty
        )
    }

    // MARK: - Custom Validation Rules

    /// Validate UI interaction events have proper naming
    public func validateUIInteractionNaming(_ event: TelemetryEvent) -> ValidationResult {
        guard event.type == .uiInteraction else {
            return ValidationResult(errors: [], warnings: [])
        }

        var errors: [String] = []
        var warnings: [String] = []

        // Check element naming convention
        if let element = event.element {
            // Element should be descriptive, not generic
            let genericNames = ["button", "view", "label", "image"]
            if genericNames.contains(element.lowercased()) {
                warnings.append("Element name '\(element)' is too generic - use descriptive names")
            }

            // Element should not contain special characters
            let invalidChars = CharacterSet.alphanumerics.union(CharacterSet.whitespaces).inverted
            if element.rangeOfCharacter(from: invalidChars) != nil {
                errors.append("Element name '\(element)' contains invalid characters")
            }
        }

        // Check action naming
        let genericActions = ["tap", "click", "pressed"]
        if genericActions.contains(event.action.lowercased()) {
            warnings.append("Action '\(event.action)' is generic - include context (e.g., 'tap_save_button')")
        }

        return ValidationResult(errors: errors, warnings: warnings)
    }

    /// Validate performance event thresholds
    public func validatePerformanceThresholds(_ event: TelemetryEvent) -> ValidationResult {
        guard event.type == .performance else {
            return ValidationResult(errors: [], warnings: [])
        }

        var errors: [String] = []
        var warnings: [String] = []

        guard let durationStr = event.context["duration"],
              let duration = Double(durationStr) else {
            errors.append("Performance event missing valid duration")
            return ValidationResult(errors: errors, warnings: warnings)
        }

        // Check if threshold is set
        guard let thresholdStr = event.context["threshold"],
              let threshold = Double(thresholdStr) else {
            warnings.append("Performance event missing threshold")
            return ValidationResult(errors: errors, warnings: warnings)
        }

        // Warn if threshold is too high
        if threshold > 1.0 {
            warnings.append("Performance threshold (\(String(format: "%.0f", threshold * 1000))ms) is very high (>1s)")
        }

        // Warn if threshold is too low (may be too strict)
        if threshold < 0.01 {
            warnings.append("Performance threshold (\(String(format: "%.0f", threshold * 1000))ms) is very low (<10ms)")
        }

        // Check if operation was significantly slower than threshold
        let ratio = duration / threshold
        if ratio > 10 {
            errors.append("Operation is \(Int(ratio))x slower than threshold - may indicate serious performance issue")
        } else if ratio > 5 {
            warnings.append("Operation is \(Int(ratio))x slower than threshold")
        }

        return ValidationResult(errors: errors, warnings: warnings)
    }

    /// Validate error event completeness
    public func validateErrorEventCompleteness(_ event: TelemetryEvent) -> ValidationResult {
        guard event.type == .error else {
            return ValidationResult(errors: [], warnings: [])
        }

        var errors: [String] = []
        var warnings: [String] = []

        // Error events should have error_description
        if event.context["error_description"] == nil {
            warnings.append("Error event missing 'error_description' in context")
        }

        // Error events should have stack trace if possible
        if event.context["stack_trace"] == nil {
            warnings.append("Error event missing 'stack_trace' - include for debugging")
        }

        // Error events should have user impact
        if event.context["user_impact"] == nil {
            warnings.append("Error event missing 'user_impact' - describe how this affects users")
        }

        // Check if error is recoverable
        if event.context["recoverable"] == nil {
            warnings.append("Error event missing 'recoverable' flag - indicate if error is recoverable")
        }

        return ValidationResult(errors: errors, warnings: warnings)
    }

    // MARK: - Statistical Validation

    /// Calculate event type distribution
    public func calculateEventTypeDistribution(_ events: [TelemetryEvent]) -> [TelemetryEventType: Int] {
        Dictionary(grouping: events, by: { $0.type })
            .mapValues { $0.count }
    }

    /// Calculate screen distribution
    public func calculateScreenDistribution(_ events: [TelemetryEvent]) -> [String: Int] {
        Dictionary(grouping: events, by: { $0.screen })
            .mapValues { $0.count }
            .filter { $0.value > 0 }
    }

    /// Find outlier events (very slow operations, frequent errors)
    public func findOutliers(_ events: [TelemetryEvent]) -> [TelemetryEvent] {
        var outliers: [TelemetryEvent] = []

        // Find very slow performance events
        let perfEvents = events.filter { $0.type == .performance }
        for event in perfEvents {
            if let durationStr = event.context["duration"],
               let duration = Double(durationStr),
               duration > 1.0 { // >1 second
                outliers.append(event)
            }
        }

        // Find frequently occurring errors
        let errorCounts = Dictionary(grouping: events.filter { $0.type == .error }, by: { $0.action })
            .mapValues { $0.count }
        for (action, count) in errorCounts where count > 5 {
            if let event = events.first(where: { $0.type == .error && $0.action == action }) {
                outliers.append(event)
            }
        }

        return outliers
    }
}

// MARK: - Validation Result

/// Result of validating a single event
public struct ValidationResult {
    public let errors: [String]
    public let warnings: [String]

    public var isValid: Bool {
        return errors.isEmpty
    }

    public var hasWarnings: Bool {
        return !warnings.isEmpty
    }

    /// Combined errors and warnings for display
    public var allIssues: [String] {
        errors.map { "❌ " + $0 } + warnings.map { "⚠️ " + $0 }
    }

    /// Detailed description
    public var description: String {
        guard !errors.isEmpty || !warnings.isEmpty else {
            return "✅ Event is valid"
        }

        var desc = ""

        if !errors.isEmpty {
            desc += "Errors (\(errors.count)):\n"
            desc += errors.map { "  • " + $0 }.joined(separator: "\n")
            desc += "\n"
        }

        if !warnings.isEmpty {
            desc += "Warnings (\(warnings.count)):\n"
            desc += warnings.map { "  • " + $0 }.joined(separator: "\n")
        }

        return desc
    }
}

// MARK: - Session Validation Result

/// Result of validating a session of events
public struct SessionValidationResult {
    public let totalEvents: Int
    public let validEvents: Int
    public let invalidEvents: Int
    public let warnings: Int
    public let isValid: Bool
    public let errorDetails: [String]
    public let warningDetails: [String]

    /// Percentage of valid events
    public var validityPercentage: Double {
        guard totalEvents > 0 else { return 100 }
        return Double(validEvents) / Double(totalEvents) * 100
    }

    /// Detailed description
    public var description: String {
        var desc = """
        Session Validation:
        Total Events: \(totalEvents)
        Valid: \(validEvents) (\(String(format: "%.1f", validityPercentage))%)
        Invalid: \(invalidEvents)
        Warnings: \(warnings)
        Status: \(isValid ? "✅ VALID" : "❌ INVALID")

        """

        if !errorDetails.isEmpty {
            desc += "\nErrors:\n"
            errorDetails.prefix(10).forEach { desc += "  • \($0)\n" }
            if errorDetails.count > 10 {
                desc += "  ... and \(errorDetails.count - 10) more\n"
            }
        }

        if !warningDetails.isEmpty {
            desc += "\nWarnings:\n"
            warningDetails.prefix(10).forEach { desc += "  • \($0)\n" }
            if warningDetails.count > 10 {
                desc += "  ... and \(warningDetails.count - 10) more\n"
            }
        }

        return desc
    }
}

// MARK: - Batch Validation Result

/// Result of validating a batch of events
public struct BatchValidationResult {
    public let sessionValidation: SessionValidationResult
    public let batchErrors: [String]
    public let batchWarnings: [String]
    public let isValid: Bool

    /// Combined description
    public var description: String {
        var desc = sessionValidation.description

        if !batchErrors.isEmpty {
            desc += "\nBatch Errors:\n"
            batchErrors.forEach { desc += "  • \($0)\n" }
        }

        if !batchWarnings.isEmpty {
            desc += "\nBatch Warnings:\n"
            batchWarnings.forEach { desc += "  • \($0)\n" }
        }

        return desc
    }

    /// Should batch be sent
    public var shouldSend: Bool {
        return isValid && sessionValidation.validEvents > 0
    }
}

// MARK: - Convenience Extensions

extension TelemetryValidator {
    /// Quick validation - returns true if valid
    public func isValid(_ event: TelemetryEvent) -> Bool {
        return validateEvent(event).isValid
    }

    /// Quick session validation - returns true if all valid
    public func isSessionValid(_ events: [TelemetryEvent]) -> Bool {
        return validateSession(events).isValid
    }
}

// MARK: - Validation Statistics

extension TelemetryValidator {
    /// Calculate validation statistics for multiple sessions
    public func calculateStatistics(sessions: [[TelemetryEvent]]) -> ValidationStatistics {
        var totalEvents = 0
        var totalInvalid = 0
        var totalWarnings = 0
        var validSessions = 0
        var invalidSessions = 0

        for session in sessions {
            let result = validateSession(session)
            totalEvents += result.totalEvents
            totalInvalid += result.invalidEvents
            totalWarnings += result.warnings

            if result.isValid {
                validSessions += 1
            } else {
                invalidSessions += 1
            }
        }

        let validityRate = totalEvents > 0 ? Double(totalEvents - totalInvalid) / Double(totalEvents) * 100 : 100

        return ValidationStatistics(
            totalSessions: sessions.count,
            validSessions: validSessions,
            invalidSessions: invalidSessions,
            totalEvents: totalEvents,
            invalidEvents: totalInvalid,
            totalWarnings: totalWarnings,
            overallValidityRate: validityRate
        )
    }
}

/// Statistics for multiple validation sessions
public struct ValidationStatistics {
    public let totalSessions: Int
    public let validSessions: Int
    public let invalidSessions: Int
    public let totalEvents: Int
    public let invalidEvents: Int
    public let totalWarnings: Int
    public let overallValidityRate: Double

    /// Summary description
    public var description: String {
        """
        Validation Statistics:
        Sessions: \(validSessions)/\(totalSessions) valid (\(String(format: "%.1f", overallValidityRate))%)
        Events: \(totalEvents - invalidEvents)/\(totalEvents) valid
        Warnings: \(totalWarnings)
        """
    }
}
