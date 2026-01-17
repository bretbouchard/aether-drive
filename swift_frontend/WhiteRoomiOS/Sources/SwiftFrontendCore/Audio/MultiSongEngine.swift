//
//  MultiSongEngine.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//

import Foundation
import Combine
import AVFoundation

// =============================================================================
// MARK: - Multi-Song Engine
// =============================================================================

/**
 Coordinates multiple song playback instances with independent and master controls.
 */
@MainActor
public final class MultiSongEngine: ObservableObject {

    // MARK: - Published State

    /// Current multi-song state
    @Published public private(set) var state: MultiSongState

    /// Real-time performance statistics
    @Published public private(set) var statistics: MultiSongStatistics

    /// Current error if any
    @Published public private(set) var currentError: Error?

    // MARK: - Private State

    private let audioEngine: AVAudioEngine
    private let mixerNode: AVAudioMixerNode
    private var songPlayers: [UUID: SongPlayerInstance] = [:]
    private var updateTimer: Timer?
    private let statisticsUpdateInterval: TimeInterval = 0.5

    // MARK: - Initialization

    public init() {
        self.state = MultiSongState()
        self.statistics = MultiSongStatistics()
        self.audioEngine = AVAudioEngine()
        self.mixerNode = AVAudioMixerNode()

        // Setup audio graph
        audioEngine.attach(mixerNode)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: nil)

        startStatisticsUpdates()
    }

    deinit {
        stopAllPlayers()
        updateTimer?.invalidate()
    }

    // MARK: - Song Management

    /**
     Add a song to the multi-song player.
     */
    public func addSong(_ song: Song) -> SongPlayerState {
        let playerState = SongPlayerState(
            songId: song.id,
            songName: song.name,
            tempo: 1.0,
            volume: 0.8,
            duration: song.metadata.duration ?? 180.0
        )

        state.songs.append(playerState)

        // Create player instance
        let player = SongPlayerInstance(
            songId: song.id,
            audioEngine: audioEngine,
            mixerNode: mixerNode
        )
        songPlayers[playerState.id] = player

        return playerState
    }

    /**
     Remove a song from the multi-song player.
     */
    public func removeSong(playerId: UUID) {
        if let index = state.songs.firstIndex(where: { $0.id == playerId }) {
            state.songs.remove(at: index)

            // Stop and cleanup player
            if let player = songPlayers[playerId] {
                player.stop()
                player.disconnect()
                songPlayers.removeValue(forKey: playerId)
            }
        }
    }

    /**
     Remove all songs and stop playback.
     */
    public func removeAllSongs() {
        stopAllPlayers()

        for player in songPlayers.values {
            player.disconnect()
        }

        songPlayers.removeAll()
        state.songs.removeAll()
        state.masterPlaying = false
    }

    // MARK: - Transport Controls

    /**
     Toggle master playback (affects all songs based on sync mode).
     */
    public func toggleMasterPlayback() {
        state.masterPlaying.toggle()

        if state.masterPlaying {
            startAllPlayers()
        } else {
            stopAllPlayers()
        }
    }

    /**
     Start all song players.
     */
    private func startAllPlayers() {
        for song in state.songs {
            if let player = songPlayers[song.id] {
                player.play()
                if let index = state.songs.firstIndex(where: { $0.id == song.id }) {
                    state.songs[index].isPlaying = true
                }
            }
        }
    }

    /**
     Stop all song players.
     */
    private func stopAllPlayers() {
        for song in state.songs {
            if let player = songPlayers[song.id] {
                player.stop()
                if let index = state.songs.firstIndex(where: { $0.id == song.id }) {
                    state.songs[index].isPlaying = false
                }
            }
        }
    }

    /**
     Stop playback for all songs (emergency stop).
     */
    public func emergencyStop() {
        state.masterPlaying = false
        stopAllPlayers()

        // Reset all positions to start
        for index in state.songs.indices {
            state.songs[index].currentPosition = 0.0
        }
    }

    // MARK: - Song-Specific Controls

    /**
     Toggle playback for a specific song.
     */
    public func toggleSongPlayback(playerId: UUID) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        state.songs[index].isPlaying.toggle()

        if state.songs[index].isPlaying {
            player.play()
        } else {
            player.stop()
        }
    }

    /**
     Set tempo for a specific song.
     */
    public func setTempo(playerId: UUID, tempo: Double) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        let clampedTempo = max(0.5, min(2.0, tempo))
        state.songs[index].tempo = clampedTempo

        // Apply sync mode logic
        applySyncMode(for: playerId)

        player.setTempo(clampedTempo)
    }

    /**
     Set volume for a specific song.
     */
    public func setVolume(playerId: UUID, volume: Double) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        let clampedVolume = max(0.0, min(1.0, volume))
        state.songs[index].volume = clampedVolume
        player.setVolume(clampedVolume)
    }

    /**
     Toggle mute for a specific song.
     */
    public func toggleMute(playerId: UUID) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        state.songs[index].isMuted.toggle()
        player.setMuted(state.songs[index].isMuted)
    }

    /**
     Toggle solo for a specific song.
     */
    public func toggleSolo(playerId: UUID) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }) else {
            return
        }

        // Disable other solos
        for i in state.songs.indices {
            if state.songs[i].id != playerId {
                state.songs[i].isSoloed = false
                if let player = songPlayers[state.songs[i].id] {
                    player.setSoloed(false)
                }
            }
        }

        state.songs[index].isSoloed.toggle()

        if let player = songPlayers[playerId] {
            player.setSoloed(state.songs[index].isSoloed)
        }
    }

    /**
     Seek to position for a specific song.
     */
    public func seek(playerId: UUID, to position: Double) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        let clampedPosition = max(0.0, min(state.songs[index].duration, position))
        state.songs[index].currentPosition = clampedPosition
        player.seek(to: clampedPosition)
    }

    // MARK: - Master Controls

    /**
     Set master tempo.
     */
    public func setMasterTempo(_ tempo: Double) {
        let clampedTempo = max(0.5, min(2.0, tempo))
        state.masterTempo = clampedTempo

        // Apply to all songs based on sync mode
        applySyncModeToAllSongs()
    }

    /**
     Set master volume.
     */
    public func setMasterVolume(_ volume: Double) {
        let clampedVolume = max(0.0, min(1.0, volume))
        state.masterVolume = clampedVolume

        // Apply master volume to all songs
        for song in state.songs {
            if let player = songPlayers[song.id] {
                let effectiveVolume = song.volume * clampedVolume
                player.setVolume(effectiveVolume)
            }
        }
    }

    /**
     Set sync mode.
     */
    public func setSyncMode(_ mode: SyncMode) {
        state.syncMode = mode
        applySyncModeToAllSongs()
    }

    // MARK: - Sync Mode Implementation

    /**
     Apply sync mode to a specific song.
     */
    private func applySyncMode(for playerId: UUID) {
        guard let song = state.songs.first(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        switch state.syncMode {
        case .independent:
            // No change, use individual tempo
            break

        case .locked:
            // Override to master tempo
            player.setTempo(state.masterTempo)

        case .ratio:
            // Maintain ratio with master
            let effectiveTempo = state.masterTempo * song.originalTempoRatio
            player.setTempo(effectiveTempo)
        }
    }

    /**
     Apply sync mode to all songs.
     */
    private func applySyncModeToAllSongs() {
        for song in state.songs {
            applySyncMode(for: song.id)
        }
    }

    // MARK: - Loop Controls

    /**
     Toggle loop for a specific song.
     */
    public func toggleLoop(playerId: UUID) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        state.songs[index].loopEnabled.toggle()
        player.setLoopEnabled(
            state.songs[index].loopEnabled,
            start: state.songs[index].loopStart,
            end: state.songs[index].loopEnd
        )
    }

    /**
     Set loop points for a specific song.
     */
    public func setLoopPoints(playerId: UUID, start: Double, end: Double) {
        guard let index = state.songs.firstIndex(where: { $0.id == playerId }),
              let player = songPlayers[playerId] else {
            return
        }

        let clampedStart = max(0.0, min(start, state.songs[index].duration))
        let clampedEnd = max(clampedStart, min(end, state.songs[index].duration))

        state.songs[index].loopStart = clampedStart
        state.songs[index].loopEnd = clampedEnd

        if state.songs[index].loopEnabled {
            player.setLoopEnabled(true, start: clampedStart, end: clampedEnd)
        }
    }

    // MARK: - Preset Management

    /**
     Save current state as a preset.
     */
    public func savePreset(named name: String) -> MultiSongPreset {
        return MultiSongPreset(name: name, state: state)
    }

    /**
     Load a preset.
     */
    public func loadPreset(_ preset: MultiSongPreset) {
        // Stop all playback
        emergencyStop()

        // Restore state
        state = preset.state

        // Recreate players for each song
        for songState in state.songs {
            let player = SongPlayerInstance(
                songId: songState.songId,
                audioEngine: audioEngine,
                mixerNode: mixerNode
            )
            songPlayers[songState.id] = player
        }
    }

    // MARK: - Statistics Monitoring

    /**
     Start periodic statistics updates.
     */
    private func startStatisticsUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: statisticsUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatistics()
            }
        }
    }

    /**
     Update performance statistics.
     */
    private func updateStatistics() {
        statistics.activeSongCount = state.songs.count

        // In real implementation, these would come from actual measurements
        statistics.cpuUsage = Double(state.songs.count) * 0.05

        let memoryPerSong = 50_000_000
        statistics.memoryUsage = state.songs.count * memoryPerSong

        statistics.audioLatency = audioEngine.outputLatency * 1000

        statistics.uiFrameRate = 60.0
    }

    // MARK: - Audio Engine Control

    /**
     Start the audio engine.
     */
    public func startAudioEngine() throws {
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
    }

    /**
     Stop the audio engine.
     */
    public func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            stopAllPlayers()
        }
    }
}

// =============================================================================
// MARK: - Song Player Instance
// =============================================================================

/**
 Individual song player instance managed by MultiSongEngine.
 */
private final class SongPlayerInstance {

    private let songId: String
    private let audioEngine: AVAudioEngine
    private let mixerNode: AVAudioMixerNode
    private var playerNode: AVAudioPlayerNode
    private var tempoNode: AVAudioUnitTimePitch
    private var volumeNode: AVAudioMixerNode

    private var isPlaying = false
    private var currentTempo: Double = 1.0
    private var currentVolume: Double = 0.8
    private var isMuted = false
    private var isSoloed = false
    private var loopEnabled = false
    private var loopStart: Double = 0.0
    private var loopEnd: Double = 0.0

    init(songId: String, audioEngine: AVAudioEngine, mixerNode: AVAudioMixerNode) {
        self.songId = songId
        self.audioEngine = audioEngine
        self.mixerNode = mixerNode
        self.playerNode = AVAudioPlayerNode()
        self.tempoNode = AVAudioUnitTimePitch()
        self.volumeNode = AVAudioMixerNode()

        setupAudioGraph()
    }

    private func setupAudioGraph() {
        audioEngine.attach(playerNode)
        audioEngine.attach(tempoNode)
        audioEngine.attach(volumeNode)

        // Connect: player -> tempo -> volume -> mixer
        audioEngine.connect(playerNode, to: tempoNode, format: nil)
        audioEngine.connect(tempoNode, to: volumeNode, format: nil)
        audioEngine.connect(volumeNode, to: mixerNode, format: nil)
    }

    func play() {
        if !isPlaying {
            playerNode.play()
            isPlaying = true
        }
    }

    func stop() {
        if isPlaying {
            playerNode.stop()
            isPlaying = false
        }
    }

    func setTempo(_ tempo: Double) {
        currentTempo = tempo
        tempoNode.rate = Float(tempo)
    }

    func setVolume(_ volume: Double) {
        currentVolume = volume
        volumeNode.volume = isMuted ? 0.0 : Float(volume)
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        volumeNode.volume = muted ? 0.0 : Float(currentVolume)
    }

    func setSoloed(_ soloed: Bool) {
        isSoloed = soloed
    }

    func setLoopEnabled(_ enabled: Bool, start: Double, end: Double) {
        loopEnabled = enabled
        loopStart = start
        loopEnd = end
    }

    func seek(to position: Double) {
        // In real implementation, would seek player node
    }

    func disconnect() {
        playerNode.stop()
        audioEngine.disconnectNodeInput(playerNode)
        audioEngine.disconnectNodeInput(tempoNode)
        audioEngine.disconnectNodeInput(volumeNode)
        audioEngine.detach(playerNode)
        audioEngine.detach(tempoNode)
        audioEngine.detach(volumeNode)
    }
}

// =============================================================================
// MARK: - Errors
// =============================================================================

public enum MultiSongEngineError: LocalizedError {
    case songNotFound(String)
    case audioEngineFailure(String)
    case invalidTempo(String)
    case invalidPosition(String)

    public var errorDescription: String? {
        switch self {
        case .songNotFound(let id):
            return "Song not found: \(id)"
        case .audioEngineFailure(let reason):
            return "Audio engine failure: \(reason)"
        case .invalidTempo(let reason):
            return "Invalid tempo: \(reason)"
        case .invalidPosition(let reason):
            return "Invalid position: \(reason)"
        }
    }
}
