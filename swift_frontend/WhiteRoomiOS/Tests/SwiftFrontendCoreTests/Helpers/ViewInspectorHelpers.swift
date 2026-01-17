//
//  ViewInspectorHelpers.swift
//  SwiftFrontendCoreTests
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwiftFrontendCore

// =============================================================================
// MARK: - View Inspection Helpers
// =============================================================================

public extension View {
    /// Helper to extract InspectableView from SwiftUI View
    func inspect() throws -> InspectableView<ViewType.ClassView> {
        let hostingController = UIHostingController(rootView: self)
        hostingController.beginAppearanceTransition(true, animated: false)
        hostingController.endAppearanceTransition()

        return try self.inspect(hostingController)
    }
}

// =============================================================================
// MARK: - Snapshot Configuration
// =============================================================================

public struct SnapshotConfig {
    public let size: CGSize
    public let displayScale: CGFloat
    public let colorScheme: ColorScheme

    public static let iphone13 = SnapshotConfig(
        size: CGSize(width: 390, height: 844),
        displayScale: 3.0,
        colorScheme: .light
    )

    public static let iphone14Pro = SnapshotConfig(
        size: CGSize(width: 393, height: 852),
        displayScale: 3.0,
        colorScheme: .light
    )

    public static let ipadPro = SnapshotConfig(
        size: CGSize(width: 1024, height: 1366),
        displayScale: 2.0,
        colorScheme: .light
    )

    public init(
        size: CGSize,
        displayScale: CGFloat,
        colorScheme: ColorScheme
    ) {
        self.size = size
        self.displayScale = displayScale
        self.colorScheme = colorScheme
    }
}

// =============================================================================
// MARK: - Test Theme Helper
// =============================================================================

/**
 Test theme for consistent UI testing
 */
public struct TestTheme {
    public let palette: ThemePalette

    public static let light = TestTheme(
        palette: ThemePalette(
            background: BackgroundPalette(
                primary: Color(.systemBackground),
                secondary: Color(.secondarySystemBackground),
                tertiary: Color(.tertiarySystemBackground)
            ),
            text: TextPalette(
                primary: Color(.label),
                secondary: Color(.secondaryLabel),
                tertiary: Color(.tertiaryLabel)
            ),
            accent: AccentPalette(
                primary: Color(.systemBlue),
                secondary: Color(.systemPurple),
                tertiary: Color(.systemTeal)
            ),
            borders: BordersPalette(
                subtle: Color(.separator),
                medium: Color(.separator),
                strong: Color(.systemGray4)
            ),
            feedback: FeedbackPalette(
                success: Color(.systemGreen),
                warning: Color(.systemOrange),
                error: Color(.systemRed)
            )
        )
    )

    public static let dark = TestTheme(
        palette: ThemePalette(
            background: BackgroundPalette(
                primary: Color(.systemBackground),
                secondary: Color(.secondarySystemBackground),
                tertiary: Color(.tertiarySystemBackground)
            ),
            text: TextPalette(
                primary: Color(.label),
                secondary: Color(.secondaryLabel),
                tertiary: Color(.tertiaryLabel)
            ),
            accent: AccentPalette(
                primary: Color(.systemBlue),
                secondary: Color(.systemPurple),
                tertiary: Color(.systemTeal)
            ),
            borders: BordersPalette(
                subtle: Color(.separator),
                medium: Color(.separator),
                strong: Color(.systemGray4)
            ),
            feedback: FeedbackPalette(
                success: Color(.systemGreen),
                warning: Color(.systemOrange),
                error: Color(.systemRed)
            )
        )
    )
}

// =============================================================================
// MARK: - Theme Palettes
// =============================================================================

public struct ThemePalette {
    public let background: BackgroundPalette
    public let text: TextPalette
    public let accent: AccentPalette
    public let borders: BordersPalette
    public let feedback: FeedbackPalette

    public init(
        background: BackgroundPalette,
        text: TextPalette,
        accent: AccentPalette,
        borders: BordersPalette,
        feedback: FeedbackPalette
    ) {
        self.background = background
        self.text = text
        self.accent = accent
        self.borders = borders
        self.feedback = feedback
    }
}

public struct BackgroundPalette {
    public let primary: Color
    public let secondary: Color
    public let tertiary: Color

    public init(primary: Color, secondary: Color, tertiary: Color) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
}

public struct TextPalette {
    public let primary: Color
    public let secondary: Color
    public let tertiary: Color

    public init(primary: Color, secondary: Color, tertiary: Color) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
}

public struct AccentPalette {
    public let primary: Color
    public let secondary: Color
    public let tertiary: Color

    public init(primary: Color, secondary: Color, tertiary: Color) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
}

public struct BordersPalette {
    public let subtle: Color
    public let medium: Color
    public let strong: Color

    public init(subtle: Color, medium: Color, strong: Color) {
        self.subtle = subtle
        self.medium = medium
        self.strong = strong
    }
}

public struct FeedbackPalette {
    public let success: Color
    public let warning: Color
    public let error: Color

    public init(success: Color, warning: Color, error: Color) {
        self.success = success
        self.warning = warning
        self.error = error
    }
}

// =============================================================================
// MARK: - View Layout Helpers
// =============================================================================

public extension View {
    /// Apply test theme to view
    func testTheme(_ theme: TestTheme = .light) -> some View {
        self.environment(\.theme, theme.palette)
    }
}

// =============================================================================
// MARK: - Assertion Helpers
// =============================================================================

public extension XCTestCase {
    /// Assert that view has expected number of children
    func assertViewCount<T>(
        _ view: InspectableView<ViewType.ClassView>,
        _ type: T.Type,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws where T: Inspectable {
        let count = try view.findAll(type).count
        XCTAssertEqual(
            count,
            expected,
            "Expected \(expected) \(type)s, but found \(count)",
            file: file,
            line: line
        )
    }

    /// Assert text content
    func assertText(
        _ view: InspectableView<ViewType.Text>,
        equals expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try view.string()
        XCTAssertEqual(
            actual,
            expected,
            "Expected text '\(expected)', but found '\(actual)'",
            file: file,
            line: line
        )
    }

    /// Assert button exists and has correct label
    func assertButton(
        _ view: InspectableView<ViewType.ClassView>,
        index: Int,
        hasLabel expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let button = try view.button(index)
        let label = try button.labelView().text().string()
        XCTAssertEqual(
            label,
            expected,
            "Expected button label '\(expected)', but found '\(label)'",
            file: file,
            line: line
        )
    }

    /// Assert slider value
    func assertSlider(
        _ view: InspectableView<ViewType.ClassView>,
        index: Int,
        hasValue expected: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let slider = try view.slider(index)
        let value = try slider.value()
        XCTAssertEqual(
            value,
            expected,
            accuracy: 0.01,
            "Expected slider value \(expected), but found \(value)",
            file: file,
            line: line
        )
    }
}

// =============================================================================
// MARK: - Async Testing Helpers
// =============================================================================

public extension XCTestCase {
    /// Wait for async operation with timeout
    func waitForAsync(
        timeout: TimeInterval = 1.0,
        operation: @escaping () async -> Void
    ) async {
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        }

        await operation()
        timeoutTask.cancel()
    }

    /// Wait for published property to change
    func waitForPublished<T: Equatable>(
        _ publisher: Published<T>,
        toEqual expected: T,
        timeout: TimeInterval = 1.0
    ) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if publisher.wrappedValue == expected {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        XCTFail("Expected publisher value \(expected), but found \(publisher.wrappedValue)")
    }
}
