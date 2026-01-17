//
//  MultiSongEngine.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import Combine

// =============================================================================
// MARK: - Multi Song Engine Protocol
// =============================================================================

/**
 Engine for managing multi-song playback (Moving Sidewalk)

 This protocol defines the interface for controlling multiple simultaneous
 song playbacks with independent transport controls.
 */
public protocol MultiSongEngine: ObservableObject {

    // MARK: - Published State

    /**
     Current multi-song state
     */
    var state: MultiSongState { get }

    // MARK: - Session Management

    /**
     Create a new empty session
     */
    func createSession() async throws

    /**
     Load an existing session
     */
    func loadSession(id: String) async throws

    /**
     Save current session
     */
    func saveSession() async throws

    /**
     Delete current session
     */
    func deleteSession() async throws

    // MARK: - Slot Management

    /**
     Assign a song to a slot
     */
    func assignSong(_ song: Song, toSlot index: Int) async throws

    /**
     Remove song from a slot
     */
    func removeSong(fromSlot index: Int) async throws

    /**
     Activate a slot in the mix
     */
    func activateSlot(_ index: Int) async throws

    /**
     Deactivate a slot in the mix
     */
    func deactivateSlot(_ index: Int) async throws

    // MARK: - Transport Control

    /**
     Toggle play/pause for a specific slot
     */
    func togglePlaySlot(_ index: Int) async throws

    /**
     Start playing a specific slot
     */
    func playSlot(_ index: Int) async throws

    /**
     Stop playing a specific slot
     */
    func stopSlot(_ index: Int) async throws

    /**
     Set tempo for a specific slot
     */
    func setTempo(_ tempo: Double, forSlot index: Int) async throws

    /**
     Set volume for a specific slot
     */
    func setVolume(_ volume: Double, forSlot index: Int) async throws

    /**
     Toggle mute for a specific slot
     */
    func toggleMute(_ index: Int) async throws

    /**
     Toggle solo for a specific slot
     */
    func toggleSolo(_ index: Int) async throws

    /**
     Seek to position for a specific slot
     */
    func seekTo(_ position: Double, forSlot index: Int) async throws

    // MARK: - Master Control

    /**
     Toggle master play/pause
     */
    func toggleMasterPlay() async throws

    /**
     Start master (plays all active songs)
     */
    func startMaster() async throws

    /**
     Stop master (stops all songs)
     */
    func stopMaster() async throws

    /**
     Set master volume
     */
    func setMasterVolume(_ volume: Double) async throws

    /**
     Set master tempo multiplier
     */
    func setTempoMultiplier(_ multiplier: Double) async throws

    /**
     Set master playback mode
     */
    func setPlaybackMode(_ mode: MasterTransport.PlaybackMode) async throws

    // MARK: - Monitoring

    /**
     Start real-time position updates
     */
    func startMonitoring()

    /**
     Stop real-time position updates
     */
    func stopMonitoring()
}

// =============================================================================
// MARK: - Mock Multi Song Engine
// =============================================================================

/**
 Mock implementation of MultiSongEngine for UI development

 This is a placeholder implementation that simulates multi-song playback
 for UI development and testing. Replace with real implementation that
 connects to JUCE backend.
 */
public class MockMultiSongEngine: MultiSongEngine {

    // MARK: - Published State

    @Published public var state: MultiSongState

    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init() {
        self.state = MultiSongState.createEmptySession()
    }

    public init(state: MultiSongState) {
        self.state = state
    }

    // MARK: - Session Management

    public func createSession() async throws {
        state = MultiSongState.createEmptySession()
    }

    public func loadSession(id: String) async throws {
        // Mock implementation - would load from persistence
        print("Loading session: \(id)")
    }

    public func saveSession() async throws {
        // Mock implementation - would save to persistence
        print("Saving session: \(state.id)")
    }

    public func deleteSession() async throws {
        // Mock implementation - would delete from persistence
        print("Deleting session: \(state.id)")
    }

    // MARK: - Slot Management

    public func assignSong(_ song: Song, toSlot index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].song = song
        state.songs[index].transport.tempo = song.metadata.tempo
    }

    public func removeSong(fromSlot index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].song = nil
        state.songs[index].isActive = false
        state.songs[index].transport = TransportState(isPlaying: false, tempo: 120.0, volume: 0.8)
    }

    public func activateSlot(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].isActive = true
    }

    public func deactivateSlot(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].isActive = false
        state.songs[index].transport.isPlaying = false
    }

    // MARK: - Transport Control

    public func togglePlaySlot(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.isPlaying.toggle()
    }

    public func playSlot(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.isPlaying = true
    }

    public func stopSlot(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.isPlaying = false
        state.songs[index].transport.currentPosition = 0.0
    }

    public func setTempo(_ tempo: Double, forSlot index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.tempo = tempo
    }

    public func setVolume(_ volume: Double, forSlot index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.volume = volume
    }

    public func toggleMute(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.isMuted.toggle()
    }

    public func toggleSolo(_ index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.isSolo.toggle()
    }

    public func seekTo(_ position: Double, forSlot index: Int) async throws {
        guard index >= 0 && index < state.songs.count else {
            throw MultiSongError.invalidSlot(index)
        }

        state.songs[index].transport.currentPosition = position
    }

    // MARK: - Master Control

    public func toggleMasterPlay() async throws {
        state.masterTransport.isPlaying.toggle()

        if state.masterTransport.isPlaying {
            try await startMaster()
        } else {
            try await stopMaster()
        }
    }

    public func startMaster() async throws {
        state.masterTransport.isPlaying = true

        // Start all active songs
        for index in state.songs.indices {
            if state.songs[index].isActive && state.songs[index].song != nil {
                state.songs[index].transport.isPlaying = true
            }
        }
    }

    public func stopMaster() async throws {
        state.masterTransport.isPlaying = false

        // Stop all songs
        for index in state.songs.indices {
            state.songs[index].transport.isPlaying = false
        }
    }

    public func setMasterVolume(_ volume: Double) async throws {
        state.masterTransport.masterVolume = volume
    }

    public func setTempoMultiplier(_ multiplier: Double) async throws {
        state.masterTransport.tempoMultiplier = multiplier
    }

    public func setPlaybackMode(_ mode: MasterTransport.PlaybackMode) async throws {
        state.masterTransport.playbackMode = mode
    }

    // MARK: - Monitoring

    public func startMonitoring() {
        // Mock implementation - simulate position updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePositions()
            }
        }
    }

    public func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Private

    private func updatePositions() {
        for index in state.songs.indices {
            if state.songs[index].transport.isPlaying {
                let tempo = state.songs[index].transport.tempo
                let deltaTime = 0.1 // 100ms

                // Calculate position advance based on tempo
                let beatsPerSecond = tempo / 60.0
                let secondsPerBeat = 1.0 / beatsPerSecond
                let positionAdvance = deltaTime / secondsPerBeat

                state.songs[index].transport.currentPosition += positionAdvance
            }
        }
    }
}

// =============================================================================
// MARK: - Multi Song Error
// =============================================================================

/**
 Errors specific to multi-song operations
 */
public enum MultiSongError: LocalizedError {
    case invalidSlot(Int)
    case slotEmpty(Int)
    case sessionNotFound(String)
    case audioEngineError(String)
    case sessionLimitReached

    public var errorDescription: String? {
        switch self {
        case .invalidSlot(let index):
            return "Invalid slot index: \(index)"
        case .slotEmpty(let index):
            return "Slot \(index) is empty"
        case .sessionNotFound(let id):
            return "Session not found: \(id)"
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        case .sessionLimitReached:
            return "Session limit reached"
        }
    }
}
