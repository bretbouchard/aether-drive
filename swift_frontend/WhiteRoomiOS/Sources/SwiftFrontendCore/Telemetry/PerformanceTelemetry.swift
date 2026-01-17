//
//  PerformanceTelemetry.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import os.log

// =============================================================================
// MARK: - Performance Telemetry
// =============================================================================

/**
 Performance measurement and monitoring system

 Tracks operation duration and warns when operations exceed thresholds:
 - Measure sync operations
 - Measure async operations
 - Configurable thresholds
 - Automatic recording to Crashlytics
 - Built-in logging

 Usage:
 ```swift
 // Sync operation
 let result = PerformanceTelemetry.measure("Database Query", threshold: 0.1) {
     try database.fetch(query)
 }

 // Async operation
 let songs = await PerformanceTelemetry.measureAsync("Load Songs", threshold: 0.5) {
     try await audioEngine.loadSongs()
 }
 ```
 */
public class PerformanceTelemetry {

    // MARK: - Logging

    private static let logger = Logger(subsystem: "com.whiteroom.telemetry", category: "Performance")

    // MARK: - Sync Measurement

    /**
     Measure a synchronous operation

     - Parameters:
       - operation: Operation name for logging
       - threshold: Warning threshold in seconds (default: 0.1s = 100ms)
       - block: Operation to measure

     - Returns: Result of the operation

     - Throws: Propagates errors from the operation
     */
    public static func measure<T>(
        _ operation: String,
        threshold: TimeInterval = 0.1,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(startTime)

        recordMetric(operation: operation, duration: duration, threshold: threshold)

        return result
    }

    /**
     Measure a synchronous throwing operation without return value

     - Parameters:
       - operation: Operation name for logging
       - threshold: Warning threshold in seconds
       - block: Operation to measure

     - Throws: Propagates errors from the operation
     */
    public static func measure(
        _ operation: String,
        threshold: TimeInterval = 0.1,
        block: () throws -> Void
    ) rethrows {
        let startTime = Date()
        try block()
        let duration = Date().timeIntervalSince(startTime)

        recordMetric(operation: operation, duration: duration, threshold: threshold)
    }

    // MARK: - Async Measurement

    /**
     Measure an async operation

     - Parameters:
       - operation: Operation name for logging
       - threshold: Warning threshold in seconds (default: 0.5s = 500ms)
       - block: Async operation to measure

     - Returns: Result of the operation

     - Throws: Propagates errors from the operation
     */
    public static func measureAsync<T>(
        _ operation: String,
        threshold: TimeInterval = 0.5,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(startTime)

        recordMetric(operation: operation, duration: duration, threshold: threshold)

        return result
    }

    /**
     Measure an async throwing operation without return value

     - Parameters:
       - operation: Operation name for logging
       - threshold: Warning threshold in seconds
       - block: Async operation to measure

     - Throws: Propagates errors from the operation
     */
    public static func measureAsync(
        _ operation: String,
        threshold: TimeInterval = 0.5,
        block: () async throws -> Void
    ) async rethrows {
        let startTime = Date()
        try await block()
        let duration = Date().timeIntervalSince(startTime)

        recordMetric(operation: operation, duration: duration, threshold: threshold)
    }

    // MARK: - Manual Recording

    /**
     Manually record a performance metric

     Use this when you want to record timing data without automatic measurement.

     - Parameters:
       - operation: Operation name
       - duration: Duration in seconds
       - threshold: Warning threshold
     */
    public static func recordMetric(
        operation: String,
        duration: TimeInterval,
        threshold: TimeInterval
    ) {
        // Record to Crashlytics
        CrashReporting.shared.setCustomValue(
            duration,
            forKey: "perf_\(operation)_duration"
        )

        // Log based on performance
        if duration > threshold {
            logger.warning(
                """
                SLOW OPERATION: "\(operation)" took \(String(format: "%.3f", duration))s \
                (threshold: \(String(format: "%.3f", threshold))s)
                """
            )

            // Leave breadcrumb for slow operations
            CrashReporting.shared.leaveBreadcrumb(
                "Slow operation: \(operation)",
                category: "performance",
                level: .warning,
                data: [
                    "duration": String(format: "%.3f", duration),
                    "threshold": String(format: "%.3f", threshold),
                    "exceeded_by": String(format: "%.3f", duration - threshold)
                ]
            )
        } else {
            logger.debug(
                """
                Operation: "\(operation)" took \(String(format: "%.3f", duration))s \
                (within threshold: \(String(format: "%.3f", threshold))s)
                """
            )
        }

        // Record custom metric if available
        if duration > threshold {
            let error = NSError(
                domain: "com.whiteroom.performance",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Slow operation detected",
                    "operation": operation,
                    "duration": duration,
                    "threshold": threshold
                ]
            )
            CrashReporting.shared.recordError(error, context: [
                "performance_issue": "slow_operation",
                "operation": operation,
                "duration": duration,
                "threshold": threshold
            ])
        }
    }

    /**
     Start a manual performance measurement

     Returns a token that can be used to stop the measurement.

     Usage:
     ```swift
     let token = PerformanceTelemetry.startMeasurement("Complex Operation")
     // ... do work ...
     PerformanceTelemetry.stopMeasurement(token, threshold: 1.0)
     ```

     - Parameter operation: Operation name
     - Returns: Measurement token
     */
    public static func startMeasurement(_ operation: String) -> PerformanceMeasurementToken {
        return PerformanceMeasurementToken(operation: operation, startTime: Date())
    }

    /**
     Stop a manual performance measurement

     - Parameters:
       - token: Measurement token from startMeasurement
       - threshold: Warning threshold (default: 0.1s)
     */
    public static func stopMeasurement(
        _ token: PerformanceMeasurementToken,
        threshold: TimeInterval = 0.1
    ) {
        let duration = Date().timeIntervalSince(token.startTime)
        recordMetric(operation: token.operation, duration: duration, threshold: threshold)
    }
}

// =============================================================================
// MARK: - Performance Measurement Token
// =============================================================================

/**
 Token for manual performance measurements
 */
public struct PerformanceMeasurementToken {
    let operation: String
    let startTime: Date
}

// =============================================================================
// MARK: - Performance Scope
// =============================================================================

/**
 Scoped performance measurement that automatically records on deallocation

 Usage:
 ```swift
 func performComplexOperation() {
     let scope = PerformanceScope("Complex Operation", threshold: 1.0)
     // ... do work ...
     // scope records automatically when it goes out of scope
 }
 ```
 */
public struct PerformanceScope {
    private let operation: String
    private let threshold: TimeInterval
    private let startTime: Date

    public init(_ operation: String, threshold: TimeInterval = 0.1) {
        self.operation = operation
        self.threshold = threshold
        self.startTime = Date()
    }

    deinit {
        let duration = Date().timeIntervalSince(startTime)
        PerformanceTelemetry.recordMetric(
            operation: operation,
            duration: duration,
            threshold: threshold
        )
    }
}

// =============================================================================
// MARK: - Performance Thresholds
// =============================================================================

/**
 Predefined performance thresholds for common operations

 Use these constants to maintain consistent performance expectations across the app.
 */
public extension PerformanceTelemetry {
    struct Thresholds {
        /// UI interactions (taps, gestures): 16ms (60fps)
        public static let uiInteraction: TimeInterval = 0.016

        /// Screen transitions: 100ms
        public static let screenTransition: TimeInterval = 0.1

        /// Database operations: 50ms
        public static let databaseQuery: TimeInterval = 0.05

        /// Network requests: 1s
        public static let networkRequest: TimeInterval = 1.0

        /// File I/O: 100ms
        public static let fileIO: TimeInterval = 0.1

        /// Audio processing: 50ms
        public static let audioProcessing: TimeInterval = 0.05

        /// Song loading: 500ms
        public static let songLoading: TimeInterval = 0.5

        /// Preset loading: 200ms
        public static let presetLoading: TimeInterval = 0.2

        /// Navigation: 100ms
        public static let navigation: TimeInterval = 0.1
    }
}
