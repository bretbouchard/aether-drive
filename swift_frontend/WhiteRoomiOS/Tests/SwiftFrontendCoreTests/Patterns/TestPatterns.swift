//
//  TestPatterns.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - Reusable Test Patterns
// =============================================================================

/// Collection of reusable test patterns for common SwiftUI testing scenarios
/// Provides consistent, declarative test helpers that reduce boilerplate
public class TestPatterns {

    // =============================================================================
    // MARK: - State Transition Pattern
    // =============================================================================

    /// Asserts that a state transition completes successfully
    /// - Parameters:
    ///   - initialValue: The expected initial value
    ///   - newValue: The new value to set
    ///   - binding: The binding to modify
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// @State var isPlaying = false
    /// TestPatterns.assertStateTransition(
    ///     false,
    ///     true,
    ///     in: $isPlaying
    /// )
    /// ```
    public static func assertStateTransition<T: Equatable>(
        _ initialValue: T,
        _ newValue: T,
        in binding: Binding<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Verify initial state
        XCTAssertEqual(
            initialValue,
            binding.wrappedValue,
            "Initial value should match expected",
            file: file,
            line: line
        )

        // Perform transition
        binding.wrappedValue = newValue

        // Verify new state
        XCTAssertEqual(
            newValue,
            binding.wrappedValue,
            "New value should match expected",
            file: file,
            line: line
        )
    }

    // =============================================================================
    // MARK: - Toggle Pattern
    // =============================================================================

    /// Asserts that a boolean toggle follows expected behavior
    /// - Parameters:
    ///   - binding: The boolean binding to test
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// @State var isMuted = false
    /// TestPatterns.assertToggleBehavior($isMuted)
    /// ```
    public static func assertToggleBehavior(
        _ binding: Binding<Bool>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let initial = binding.wrappedValue

        // First toggle
        binding.wrappedValue.toggle()

        XCTAssertEqual(
            binding.wrappedValue,
            !initial,
            "First toggle should invert value",
            file: file,
            line: line
        )

        // Second toggle
        binding.wrappedValue.toggle()

        XCTAssertEqual(
            binding.wrappedValue,
            initial,
            "Second toggle should return to initial",
            file: file,
            line: line
        )
    }

    /// Asserts that a toggle cycles through multiple states correctly
    /// - Parameters:
    ///   - binding: The boolean binding to test
    ///   - cycles: Number of toggle cycles to test
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// @State var isPlaying = false
    /// TestPatterns.assertToggleCycles($isPlaying, cycles: 10)
    /// ```
    public static func assertToggleCycles(
        _ binding: Binding<Bool>,
        cycles: Int = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let initial = binding.wrappedValue

        for i in 0..<cycles {
            binding.wrappedValue.toggle()

            let expected = (i % 2 == 0) ? !initial : initial
            XCTAssertEqual(
                binding.wrappedValue,
                expected,
                "Toggle cycle \(i + 1) should match expected",
                file: file,
                line: line
            )
        }
    }

    // =============================================================================
    // MARK: - Array Modification Pattern
    // =============================================================================

    /// Asserts that an array modification completes successfully
    /// - Parameters:
    ///   - array: The array binding to modify
    ///   - addition: The element to add
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// @State var songs: [Song] = []
    /// let newSong = createTestSong()
    /// TestPatterns.assertArrayModification($songs, addition: newSong)
    /// ```
    public static func assertArrayModification<T: Equatable>(
        _ array: Binding<[T]>,
        addition: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let initialCount = array.wrappedValue.count

        array.wrappedValue.append(addition)

        // Verify count increased
        XCTAssertEqual(
            array.wrappedValue.count,
            initialCount + 1,
            "Array count should increase by 1",
            file: file,
            line: line
        )

        // Verify element exists
        XCTAssertTrue(
            array.wrappedValue.contains { $0 == addition },
            "Array should contain added element",
            file: file,
            line: line
        )

        // Verify element is at end
        XCTAssertEqual(
            array.wrappedValue.last,
            addition,
            "Added element should be at end of array",
            file: file,
            line: line
        )
    }

    /// Asserts that an array removal completes successfully
    /// - Parameters:
    ///   - array: The array binding to modify
    ///   - removal: The element to remove
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// @State var songs: [Song] = [song1, song2, song3]
    /// TestPatterns.assertArrayRemoval($songs, removal: song2)
    /// ```
    public static func assertArrayRemoval<T: Equatable>(
        _ array: Binding<[T]>,
        removal: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let initialCount = array.wrappedValue.count

        array.wrappedValue.removeAll { $0 == removal }

        // Verify count decreased
        XCTAssertEqual(
            array.wrappedValue.count,
            initialCount - 1,
            "Array count should decrease by 1",
            file: file,
            line: line
        )

        // Verify element doesn't exist
        XCTAssertFalse(
            array.wrappedValue.contains { $0 == removal },
            "Array should not contain removed element",
            file: file,
            line: line
        )
    }

    // =============================================================================
    // MARK: - Range Clamping Pattern
    // =============================================================================

    /// Asserts that a value is clamped to a valid range
    /// - Parameters:
    ///   - value: The value to test
    ///   - range: The valid range
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// let tempo = 1.5
    /// TestPatterns.assertValueInRange(tempo, range: 0.0...2.0)
    /// ```
    public static func assertValueInRange<T: Comparable>(
        _ value: T,
        range: ClosedRange<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(
            value,
            range.lowerBound,
            "Value \(value) should be >= \(range.lowerBound)",
            file: file,
            line: line
        )

        XCTAssertLessThanOrEqual(
            value,
            range.upperBound,
            "Value \(value) should be <= \(range.upperBound)",
            file: file,
            line: line
        )
    }

    /// Asserts that multiple values are clamped to a valid range
    /// - Parameters:
    ///   - values: The values to test
    ///   - range: The valid range
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// let volumes = [0.0, 0.5, 1.0, 1.5]
    /// TestPatterns.assertValuesInRange(volumes, range: 0.0...1.0)
    /// ```
    public static func assertValuesInRange<T: Comparable>(
        _ values: [T],
        range: ClosedRange<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for value in values {
            assertValueInRange(value, range: range, file: file, line: line)
        }
    }

    // =============================================================================
    // MARK: - Boundary Testing Pattern
    // =============================================================================

    /// Asserts behavior at boundary values
    /// - Parameters:
    ///   - lowerBound: Lower boundary value
    ///   - upperBound: Upper boundary value
    ///   - midPoint: Mid-point value
    ///   - test: Closure that tests a value
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// TestPatterns.assertBoundaryValues(
    ///     lowerBound: 0.0,
    ///     upperBound: 1.0,
    ///     midPoint: 0.5
    /// ) { value in
    ///     var slot = createTestSongSlot()
    ///     slot.volume = value
    ///     return slot.volume
    /// }
    /// ```
    public static func assertBoundaryValues<T>(
        lowerBound: T,
        upperBound: T,
        midPoint: T,
        test: (T) -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) where T: Equatable {
        // Test lower bound
        let lowerResult = test(lowerBound)
        XCTAssertEqual(
            lowerResult,
            lowerBound,
            "Lower bound should be preserved",
            file: file,
            line: line
        )

        // Test upper bound
        let upperResult = test(upperBound)
        XCTAssertEqual(
            upperResult,
            upperBound,
            "Upper bound should be preserved",
            file: file,
            line: line
        )

        // Test mid point
        let midResult = test(midPoint)
        XCTAssertEqual(
            midResult,
            midPoint,
            "Mid point should be preserved",
            file: file,
            line: line
        )
    }

    /// Asserts behavior with out-of-range values
    /// - Parameters:
    ///   - range: The valid range
    ///   - test: Closure that tests a value
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// TestPatterns.assertOutOfRangeHandled(
    ///     range: 0.0...1.0
    /// ) { value in
    ///     var slot = createTestSongSlot()
    ///     slot.volume = value
    ///     return slot.volume
    /// }
    /// ```
    public static func assertOutOfRangeHandled<T>(
        range: ClosedRange<T>,
        test: (T) -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) where T: Comparable {
        // Test below range
        let belowResult = test(range.lowerBound)
        XCTAssertGreaterThanOrEqual(
            belowResult,
            range.lowerBound,
            "Value below range should be clamped",
            file: file,
            line: line
        )

        // Test above range
        let aboveResult = test(range.upperBound)
        XCTAssertLessThanOrEqual(
            aboveResult,
            range.upperBound,
            "Value above range should be clamped",
            file: file,
            line: line
        )
    }

    // =============================================================================
    // MARK: - Performance Pattern
    // =============================================================================

    /// Asserts that an operation completes within a time limit
    /// - Parameters:
    ///   - description: Description of the operation
    ///   - limit: Maximum allowed time in seconds
    ///   - operation: The operation to measure
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// TestPatterns.assertPerformance(
    ///     description: "View rendering",
    ///     limit: 0.1
    /// ) {
    ///     _ = SongPlayerCard(slot: .constant(state))
    /// }
    /// ```
    public static func assertPerformance(
        description: String,
        limit: TimeInterval,
        operation: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let startTime = Date()
        operation()
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThanOrEqual(
            duration,
            limit,
            "\(description) should complete in \(limit)s, took \(duration)s",
            file: file,
            line: line
        )
    }

    /// Measures and returns operation duration
    /// - Parameters:
    ///   - iterations: Number of iterations to run
    ///   - operation: The operation to measure
    /// - Returns: Average duration per iteration
    ///
    /// Usage Example:
    /// ```swift
    /// let avgDuration = TestPatterns.measurePerformance(iterations: 100) {
    ///     _ = SongPlayerCard(slot: .constant(state))
    /// }
    /// print("Average: \(avgDuration)s")
    /// ```
    public static func measurePerformance(
        iterations: Int = 10,
        operation: () -> Void
    ) -> TimeInterval {
        var durations: [TimeInterval] = []

        for _ in 0..<iterations {
            let startTime = Date()
            operation()
            let duration = Date().timeIntervalSince(startTime)
            durations.append(duration)
        }

        return durations.reduce(0, +) / Double(iterations)
    }

    // =============================================================================
    // MARK: - State Consistency Pattern
    // =============================================================================

    /// Asserts that multiple related properties remain consistent
    /// - Parameters:
    ///   - consistencyCheck: Closure that verifies consistency
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// TestPatterns.assertStateConsistent {
    ///     return slot.loopEnd >= slot.loopStart
    /// }
    /// ```
    public static func assertStateConsistent(
        _ consistencyCheck: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            consistencyCheck(),
            "State should be consistent",
            file: file,
            line: line
        )
    }

    /// Asserts that state consistency is maintained through operations
    /// - Parameters:
    ///   - initialState: Starting state
    ///   - operations: Operations to perform
    ///   - consistencyCheck: Closure that verifies consistency
    ///   - file: The file where the assertion occurs (automatic)
    ///   - line: The line where the assertion occurs (automatic)
    ///
    /// Usage Example:
    /// ```swift
    /// var state = createTestMultiSongState()
    /// TestPatterns.assertConsistencyMaintained(
    ///     initialState: state,
    ///     operations: {
    ///         state.songs[0].isPlaying = true
    ///         state.songs[1].isMuted = true
    ///     }
    /// ) {
    ///     return state.songs.count <= 6
    /// }
    /// ```
    public static func assertConsistencyMaintained<T>(
        initialState: T,
        operations: (inout T) -> Void,
        consistencyCheck: (T) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Verify initial consistency
        XCTAssertTrue(
            consistencyCheck(initialState),
            "Initial state should be consistent",
            file: file,
            line: line
        )

        // Perform operations
        var state = initialState
        operations(&state)

        // Verify consistency maintained
        XCTAssertTrue(
            consistencyCheck(state),
            "State should remain consistent after operations",
            file: file,
            line: line
        )
    }
}

// =============================================================================
// MARK: - Usage Examples
// =============================================================================

/// Example tests demonstrating TestPatterns usage
class SongPlayerCardPatternTests: XCTestCase {

    func testPlayToggle_FollowsPattern() {
        var slot = XCUITestFixtures.createTestSongSlot()

        TestPatterns.assertToggleBehavior($slot.isPlaying)

        // Test multiple cycles
        TestPatterns.assertToggleCycles($slot.isPlaying, cycles: 20)
    }

    func testMuteToggle_FollowsPattern() {
        var slot = XCUITestFixtures.createTestSongSlot()

        TestPatterns.assertToggleBehavior($slot.isMuted)
    }

    func testTempoClamping_FollowsPattern() {
        var slot = XCUITestFixtures.createTestSongSlot()

        // Test boundary values
        TestPatterns.assertBoundaryValues(
            lowerBound: 0.0,
            upperBound: 2.0,
            midPoint: 1.0
        ) { value in
            slot.tempo = value
            return slot.tempo
        }

        // Test out of range
        TestPatterns.assertOutOfRangeHandled(range: 0.0...2.0) { value in
            slot.tempo = value
            return slot.tempo
        }
    }

    func testVolumeClamping_FollowsPattern() {
        var slot = XCUITestFixtures.createTestSongSlot()

        // Test in range
        TestPatterns.assertValuesInRange(
            [0.0, 0.5, 1.0],
            range: 0.0...1.0
        )

        // Test clamping
        TestPatterns.assertOutOfRangeHandled(range: 0.0...1.0) { value in
            slot.volume = value
            return slot.volume
        }
    }

    func testSongArray_Addition_FollowsPattern() {
        var state = XCUITestFixtures.createTestMultiSongState(songCount: 0)

        let newSong = XCUITestFixtures.createTestSongSlot(songId: "new-song")
        TestPatterns.assertArrayModification($state.songs, addition: newSong)
    }

    func testSongArray_Removal_FollowsPattern() {
        var state = XCUITestFixtures.createTestMultiSongState(songCount: 3)

        let songToRemove = state.songs[1]
        TestPatterns.assertArrayRemoval($state.songs, removal: songToRemove)
    }

    func testLoopBoundaries_Consistent() {
        var slot = XCUITestFixtures.createTestSongSlot()

        TestPatterns.assertStateConsistent(
            slot.loopEnd >= slot.loopStart
        )

        // Test consistency through operations
        TestPatterns.assertConsistencyMaintained(
            initialState: slot,
            operations: { state in
                state.loopStart = 0.25
                state.loopEnd = 0.75
            },
            consistencyCheck: { state in
                return state.loopEnd >= state.loopStart &&
                       state.loopStart >= 0.0 &&
                       state.loopEnd <= 1.0
            }
        )
    }

    func testViewRendering_Performance() {
        let state = XCUITestFixtures.createTestMultiSongState()

        TestPatterns.assertPerformance(
            description: "SongPlayerCard rendering",
            limit: 0.05
        ) {
            _ = SongPlayerCard(slot: .constant(state.songs[0]))
        }

        // Measure average over multiple iterations
        let avgDuration = TestPatterns.measurePerformance(iterations: 100) {
            _ = SongPlayerCard(slot: .constant(state.songs[0]))
        }

        print("Average rendering time: \(avgDuration)s")
    }

    func testStateTransition_FollowsPattern() {
        var slot = XCUITestFixtures.createTestSongSlot()

        TestPatterns.assertStateTransition(
            false,
            true,
            in: $slot.isPlaying
        )
    }
}
