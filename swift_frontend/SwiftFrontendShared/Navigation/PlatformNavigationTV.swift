//
//  PlatformNavigationTV.swift
//  SwiftFrontendShared
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import SwiftUI

// =============================================================================
// MARK: - tvOS Navigation View
// =============================================================================

/**
 tvOS-specific navigation using Focus Engine

 Primary Flow: Order Song
 Secondary: Performance Editor, Orchestration (via menu/search)

 Features:
 - Focus engine for remote navigation
 - Tab bar at top
 - Slide-over panels for secondary features
 - Siri Remote gesture support
 - Large focus indicators
 */
@available(iOS 16.0, tvOS 16.0, *)
public struct PlatformNavigationTV: View {

    // MARK: - State

    @StateObject private var navigationManager = NavigationManager()
    @State private var selectedTab: NavigationDestination = .orderSong(contractId: nil)
    @State private var showingMenu: Bool = false

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Top tab bar
            tabBar

            // Main content
            TabView(selection: $selectedTab) {
                // Order Song (Primary)
                OrderSongContainerView()
                    .tag(NavigationDestination.orderSong(contractId: nil))

                // Song Library (Primary)
                SongLibraryView()
                    .tag(NavigationDestination.songLibrary)

                // Performance Strip (Secondary)
                PerformanceStripView()
                    .tag(NavigationDestination.performanceStrip)
            }
            .tvTabViewStyle()
        }
        .slideOverPanel(isPresented: Binding(
            get: { navigationManager.presentedSheet != nil },
            set: { if !$0 { navigationManager.presentedSheet = nil } }
        )) {
            slideOverContent
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 40) {
            ForEach(navigationManager.primaryDestinations, id: \.self) { destination in
                Button {
                    selectedTab = destination
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: destination.iconName)
                            .font(.system(size: 40))
                        Text(destination.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == destination ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .focusableWrapper()
            }

            Spacer()

            // Menu button for secondary features
            Button {
                showingMenu = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 40))
                    Text("More")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .focusableWrapper()
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }

    // MARK: - Slide Over Content

    @ViewBuilder
    private var slideOverContent: some View {
        if let sheet = navigationManager.presentedSheet {
            switch sheet.destination {
            case .performanceEditor(let id):
                PerformanceEditorView(performanceId: id)
            case .orchestrationConsole:
                OrchestrationConsoleView()
            case .settings:
                SettingsView()
            default:
                Text("Unknown")
            }
        }
    }
}

// =============================================================================
// MARK: - tvOS Tab View Style
// =============================================================================

// TODO: Implement custom TabViewStyle for tvOS
// TabViewStyleConfiguration not available in current SDK version
extension View {
    func tvTabViewStyle() -> some View {
        if #available(iOS 17.0, tvOS 17.0, *) {
            return self.tabViewStyle(.page)
        } else {
            return self.tabViewStyle(PageTabViewStyle())
        }
    }

    @ViewBuilder
    func focusableWrapper() -> some View {
        if #available(iOS 17.0, tvOS 17.0, *) {
            self.focusable()
        } else {
            self
        }
    }
}

// =============================================================================
// MARK: - Slide Over Panel Modifier
// =============================================================================

struct SlideOverPanelModifier: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> AnyView

    func body(content: Content) -> some View {
        content
            .overlay(sheetOverlay)
    }

    private var backgroundMaterial: some ShapeStyle {
        if #available(iOS 17.0, tvOS 17.0, *) {
            return .ultraThickMaterial
        } else {
            return Color.black.opacity(0.8)
        }
    }

    @ViewBuilder
    private var sheetOverlay: some View {
        if isPresented {
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    // Dimmed background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isPresented = false
                            }
                        }

                    // Slide over panel
                    content()
                        .frame(width: geometry.size.width * 0.7)
                        .background(backgroundMaterial)
                        .transition(.move(edge: .trailing))
                }
            }
        }
    }
}

extension View {
    func slideOverPanel(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        self.modifier(SlideOverPanelModifier(
            isPresented: isPresented,
            content: { AnyView(content()) }
        ))
    }
}

// =============================================================================
// MARK: - Preview
// =============================================================================

#if DEBUG
@available(iOS 16.0, tvOS 16.0, *)
struct PlatformNavigationTV_Previews: PreviewProvider {
    static var previews: some View {
        PlatformNavigationTV()
    }
}
#endif
