//
//  Theme.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import SwiftUI

// =============================================================================
// MARK: - Theme Palette
// =============================================================================

/**
 Color palette for the White Room app
 */
struct ThemePalette {
    // Background colors
    let background: BackgroundColors
    let text: TextColors
    let accent: AccentColors
    let borders: BorderColors
    let feedback: FeedbackColors

    struct BackgroundColors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
    }

    struct TextColors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
    }

    struct AccentColors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
    }

    struct BorderColors {
        let subtle: Color
        let medium: Color
        let strong: Color
    }

    struct FeedbackColors {
        let success: Color
        let warning: Color
        let error: Color
        let info: Color
    }
}

// =============================================================================
// MARK: - Theme
// =============================================================================

/**
 App theme containing color palette and typography settings
 */
struct Theme {
    let palette: ThemePalette

    static let light = Theme(
        palette: ThemePalette(
            background: .init(
                primary: Color(.systemBackground),
                secondary: Color(.secondarySystemBackground),
                tertiary: Color(.tertiarySystemBackground)
            ),
            text: .init(
                primary: Color(.label),
                secondary: Color(.secondaryLabel),
                tertiary: Color(.tertiaryLabel)
            ),
            accent: .init(
                primary: Color.blue,
                secondary: Color.purple,
                tertiary: Color.pink
            ),
            borders: .init(
                subtle: Color.gray.opacity(0.2),
                medium: Color.gray.opacity(0.4),
                strong: Color.gray.opacity(0.6)
            ),
            feedback: .init(
                success: Color.green,
                warning: Color.orange,
                error: Color.red,
                info: Color.blue
            )
        )
    )

    static let dark = Theme(
        palette: ThemePalette(
            background: .init(
                primary: Color(.systemBackground),
                secondary: Color(.secondarySystemBackground),
                tertiary: Color(.tertiarySystemBackground)
            ),
            text: .init(
                primary: Color(.label),
                secondary: Color(.secondaryLabel),
                tertiary: Color(.tertiaryLabel)
            ),
            accent: .init(
                primary: Color.blue,
                secondary: Color.purple,
                tertiary: Color.pink
            ),
            borders: .init(
                subtle: Color.gray.opacity(0.2),
                medium: Color.gray.opacity(0.4),
                strong: Color.gray.opacity(0.6)
            ),
            feedback: .init(
                success: Color.green,
                warning: Color.orange,
                error: Color.red,
                info: Color.blue
            )
        )
    )
}

// =============================================================================
// MARK: - Theme Environment Key
// =============================================================================

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// =============================================================================
// MARK: - Themed View Modifier
// =============================================================================

extension View {
    func theme(_ theme: Theme) -> some View {
        self.environment(\.theme, theme)
    }
}
