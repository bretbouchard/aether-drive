//
//  WhiteRoomiOSApp.swift
//  WhiteRoomiOS
//
//  Created by White Room Team
//  Copyright © 2026 White Room. All rights reserved.
//

import SwiftUI

@main
struct WhiteRoomiOSApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .onAppear {
                    // Set initial theme based on system appearance
                    themeManager.updateTheme()
                }
        }
    }
}

// =============================================================================
// MARK: - Theme Manager
// =============================================================================

/**
 Manages app theme switching between light and dark modes
 */
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .light

    init() {
        // Observe system appearance changes
        NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTheme()
        }
    }

    func updateTheme() {
        let userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        currentTheme = userInterfaceStyle == .dark ? .dark : .light
    }

    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
}

// =============================================================================
// MARK: - Content View
// =============================================================================

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Moving Sidewalk Tab
            NavigationView {
                MovingSidewalkView()
            }
            .tabItem {
                Label("Moving Sidewalk", systemImage: "music.note")
            }
            .tag(0)

            // Library Tab (placeholder for now)
            NavigationView {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(1)

            // Settings Tab
            NavigationView {
                SettingsView(themeManager: themeManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .accentColor(themeManager.currentTheme.palette.accent.primary)
        .theme(themeManager.currentTheme)
    }
}

// =============================================================================
// MARK: - Library View
// =============================================================================

struct LibraryView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(theme.palette.accent.primary)

            Text("Library")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.palette.text.primary)

            Text("Browse and manage your song collection")
                .font(.body)
                .foregroundColor(theme.palette.text.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(theme.palette.accent.secondary)
        }
        .navigationTitle("Library")
        .accessibilityIdentifier("LibraryView")
    }
}

// =============================================================================
// MARK: - Settings View
// =============================================================================

struct SettingsView: View {
    @Environment(\.theme) var theme
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Theme")
                        .foregroundColor(theme.palette.text.primary)
                    Spacer()
                    Text(themeManager.currentTheme == .light ? "Light" : "Dark")
                        .foregroundColor(theme.palette.text.secondary)
                    Image(systemName: themeManager.currentTheme == .light ? "sun.max.fill" : "moon.fill")
                        .foregroundColor(theme.palette.accent.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        themeManager.toggleTheme()
                    }
                }
            } header: {
                Text("Appearance")
                    .foregroundColor(theme.palette.text.secondary)
            }

            Section {
                HStack {
                    Text("Version")
                        .foregroundColor(theme.palette.text.primary)
                    Spacer()
                    Text("0.1.0")
                        .foregroundColor(theme.palette.text.secondary)
                }

                HStack {
                    Text("Build")
                        .foregroundColor(theme.palette.text.primary)
                    Spacer()
                    Text("Development")
                        .foregroundColor(theme.palette.text.secondary)
                }
            } header: {
                Text("About")
                    .foregroundColor(theme.palette.text.secondary)
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("SettingsView")
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ThemeManager())
    }
}
