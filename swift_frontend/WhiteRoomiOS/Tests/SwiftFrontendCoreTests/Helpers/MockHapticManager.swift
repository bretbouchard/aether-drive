//
//  MockHapticManager.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import UIKit
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Mock Haptic Feedback Manager
// =============================================================================

/**
 Mock implementation of HapticFeedbackManager for testing
 */
public class MockHapticFeedbackManager {

    // MARK: - Tracking Properties

    public var lightImpactCallCount = 0
    public var mediumImpactCallCount = 0
    public var heavyImpactCallCount = 0
    public var successCallCount = 0
    public var warningCallCount = 0
    public var errorCallCount = 0
    public var selectionCallCount = 0

    public var customImpactCalls: [CGFloat] = []
    public var patternCalls: [[(delay: TimeInterval, intensity: CGFloat)]] = []

    // MARK: - Singleton Override

    public static var mock: MockHapticFeedbackManager?

    // MARK: - Impact Feedback

    public func lightImpact() {
        lightImpactCallCount += 1
    }

    public func mediumImpact() {
        mediumImpactCallCount += 1
    }

    public func heavyImpact() {
        heavyImpactCallCount += 1
    }

    public func impact(intensity: CGFloat) {
        customImpactCalls.append(intensity)

        // Also increment specific counter based on intensity
        if intensity < 0.33 {
            lightImpactCallCount += 1
        } else if intensity < 0.66 {
            mediumImpactCallCount += 1
        } else {
            heavyImpactCallCount += 1
        }
    }

    // MARK: - Notification Feedback

    public func success() {
        successCallCount += 1
    }

    public func warning() {
        warningCallCount += 1
    }

    public func error() {
        errorCallCount += 1
    }

    // MARK: - Selection Feedback

    public func selection() {
        selectionCallCount += 1
    }

    // MARK: - Patterned Feedback

    public func playPattern(_ pattern: [(delay: TimeInterval, intensity: CGFloat)]) {
        patternCalls.append(pattern)
    }

    // MARK: - Preset Patterns

    public func heartbeat() {
        playPattern([
            (0.0, 0.7),
            (0.1, 0.5),
            (0.15, 0.0),
            (0.3, 0.7),
            (0.1, 0.5)
        ])
    }

    public func ascending() {
        playPattern([
            (0.0, 0.3),
            (0.1, 0.5),
            (0.1, 0.7),
            (0.1, 1.0)
        ])
    }

    public func descending() {
        playPattern([
            (0.0, 1.0),
            (0.1, 0.7),
            (0.1, 0.5),
            (0.1, 0.3)
        ])
    }

    public func rhythm(beats: Int = 4) {
        var pattern: [(TimeInterval, CGFloat)] = []
        for i in 0..<beats {
            pattern.append((TimeInterval(i) * 0.5, i == 0 ? 1.0 : 0.7))
        }
        playPattern(pattern)
    }

    // MARK: - Reset

    public func reset() {
        lightImpactCallCount = 0
        mediumImpactCallCount = 0
        heavyImpactCallCount = 0
        successCallCount = 0
        warningCallCount = 0
        errorCallCount = 0
        selectionCallCount = 0
        customImpactCalls = []
        patternCalls = []
    }

    // MARK: - Verification Helpers

    /// Verify total impact calls
    public var totalImpactCalls: Int {
        lightImpactCallCount + mediumImpactCallCount + heavyImpactCallCount
    }

    /// Verify any notification was called
    public var totalNotificationCalls: Int {
        successCallCount + warningCallCount + errorCallCount
    }

    /// Verify specific pattern was played
    public func didPlayPattern(_ expected: [(delay: TimeInterval, intensity: CGFloat)]) -> Bool {
        return patternCalls.contains { pattern in
            guard pattern.count == expected.count else { return false }
            return zip(pattern, expected).allSatisfy { $0.0 == $0.1 && $1.0 == $1.1 }
        }
    }

    /// Verify intensity was called within range
    public func didCallImpact(intensity: ClosedRange<CGFloat>) -> Bool {
        return customImpactCalls.contains { intensity.contains($0) }
    }
}

// =============================================================================
// MARK: - UIImpactFeedbackGenerator Mock
// =============================================================================

/**
 Mock UIImpactFeedbackGenerator for testing
 */
public class MockImpactFeedbackGenerator {

    public var impactCallCount = 0
    public var prepareCallCount = 0
    public var lastIntensity: CGFloat?

    public func impactOccurred(intensity: CGFloat = 1.0) {
        impactCallCount += 1
        lastIntensity = intensity
    }

    public func prepare() {
        prepareCallCount += 1
    }

    public func reset() {
        impactCallCount = 0
        prepareCallCount = 0
        lastIntensity = nil
    }
}

// =============================================================================
// MARK: - UINotificationFeedbackGenerator Mock
// =============================================================================

/**
 Mock UINotificationFeedbackGenerator for testing
 */
public class MockNotificationFeedbackGenerator {

    public var notificationCallCount = 0
    public var lastType: UINotificationFeedbackGenerator.FeedbackType?

    public func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationCallCount += 1
        lastType = type
    }

    public func prepare() {
        // Notification generator preparation
    }

    public func reset() {
        notificationCallCount = 0
        lastType = nil
    }
}

// =============================================================================
// MARK: - UISelectionFeedbackGenerator Mock
// =============================================================================

/**
 Mock UISelectionFeedbackGenerator for testing
 */
public class MockSelectionFeedbackGenerator {

    public var selectionChangedCallCount = 0
    public var prepareCallCount = 0

    public func selectionChanged() {
        selectionChangedCallCount += 1
    }

    public func prepare() {
        prepareCallCount += 1
    }

    public func reset() {
        selectionChangedCallCount = 0
        prepareCallCount = 0
    }
}

// =============================================================================
// MARK: - Haptic Test Extensions
// =============================================================================

public extension XCTestCase {

    /// Assert light impact was called specific number of times
    func assertLightImpactCalled(
        _ mock: MockHapticFeedbackManager,
        times: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.lightImpactCallCount,
            times,
            "Expected light impact to be called \(times) times, but was called \(mock.lightImpactCallCount) times",
            file: file,
            line: line
        )
    }

    /// Assert medium impact was called specific number of times
    func assertMediumImpactCalled(
        _ mock: MockHapticFeedbackManager,
        times: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.mediumImpactCallCount,
            times,
            "Expected medium impact to be called \(times) times, but was called \(mock.mediumImpactCallCount) times",
            file: file,
            line: line
        )
    }

    /// Assert heavy impact was called specific number of times
    func assertHeavyImpactCalled(
        _ mock: MockHapticFeedbackManager,
        times: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.heavyImpactCallCount,
            times,
            "Expected heavy impact to be called \(times) times, but was called \(mock.heavyImpactCallCount) times",
            file: file,
            line: line
        )
    }

    /// Assert success notification was called
    func assertSuccessCalled(
        _ mock: MockHapticFeedbackManager,
        times: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.successCallCount,
            times,
            "Expected success to be called \(times) times, but was called \(mock.successCallCount) times",
            file: file,
            line: line
        )
    }

    /// Assert no haptics were called
    func assertNoHaptics(
        _ mock: MockHapticFeedbackManager,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mock.totalImpactCalls,
            0,
            "Expected no impact calls, but got \(mock.totalImpactCalls)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            mock.totalNotificationCalls,
            0,
            "Expected no notification calls, but got \(mock.totalNotificationCalls)",
            file: file,
            line: line
        )
    }
}
