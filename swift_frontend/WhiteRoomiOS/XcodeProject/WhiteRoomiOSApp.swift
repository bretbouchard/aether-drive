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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View (Placeholder for XCUITest)

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                MovingSidewalkPlaceholderView()
                    .navigationTitle("Moving Sidewalk")
            }
            .tabItem {
                Label("Moving Sidewalk", systemImage: "music.note")
            }
            .tag(0)

            NavigationView {
                LibraryPlaceholderView()
                    .navigationTitle("Library")
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(1)

            NavigationView {
                SettingsPlaceholderView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
    }
}

// MARK: - Placeholder Views

struct MovingSidewalkPlaceholderView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<6) { index in
                    SongPlayerCardPlaceholderView(slotNumber: index)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("MovingSidewalkView")
    }
}

struct SongPlayerCardPlaceholderView: View {
    let slotNumber: Int

    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Slot \(slotNumber)")
                .font(.headline)

            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
            }
            .accessibilityIdentifier(isPlaying ? "Pause" : "Play")
            .accessibilityLabel(isPlaying ? "Pause" : "Play")

            Slider(value: .constant(0.5), in: 0...1)
                .accessibilityIdentifier("Tempo")
                .accessibilityLabel("Tempo")

            Button("Load Slot \(slotNumber)") {
                // Load action placeholder
            }
            .accessibilityIdentifier("Load Slot \(slotNumber)")
        }
        .padding()
        .frame(width: 280, height: 350)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .accessibilityIdentifier("SongPlayerCard")
    }
}

struct LibraryPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Library View")
                .font(.largeTitle)
            Text("Content placeholder for testing")
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("LibraryView")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Settings View")
                .font(.largeTitle)
            Text("Content placeholder for testing")
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("SettingsView")
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
