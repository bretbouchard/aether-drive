//
//  SyncModeController.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  Manages tempo synchronization modes for multi-song playback:
//  - Independent: Each song has its own tempo
//  - Locked: All songs sync to master tempo (1:1 ratio)
//  - Ratio: Maintain tempo ratios when master changes

import Foundation
import Combine

/// Controller for managing tempo synchronization between multiple songs
public final class SyncModeController: ObservableObject {

    // MARK: - Published State

    /// Current sync mode
    @Published public private(set) var syncMode: SyncMode = .independent

    /// Baseline tempos for each song (used for ratio calculations)
    @Published public private(set) var baselineTempos: [String: Double] = [:]

    /// Tempo ratios for each song (relative to master)
    @Published public private(set) var tempoRatios: [String: Double] = [:]

    /// Transition duration for smooth tempo changes (seconds)
    @Published public var transitionDuration: Double = 0.5

    /// Enable smooth tempo transitions
    @Published public var smoothTransitions: Bool = true

    // MARK: - Thread Safety

    private let queue = DispatchQueue(
        label: "com.whiteroom.audio.sync_mode",
        qos: .userInitiated
    )

    // MARK: - State Tracking

    private var activeTransitions: [String: TempoTransition] = [:]

    // MARK: - Initialization

    public init() {}

    // MARK: - Sync Mode Management

    /// Set the current sync mode
    public func setSyncMode(_ mode: SyncMode) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let oldMode = self.syncMode
            self.syncMode = mode

            NSLog("[SyncMode] Changed from \(oldMode) to \(mode)")

            // When switching to ratio mode, capture current tempos as baseline
            if mode == .ratio && oldMode != .ratio {
                self.captureBaselineTempos()
            }
        }
    }

    /// Apply master tempo to all song instances based on sync mode
    public func applyMasterTempo(
        _ masterTempo: Double,
        multiplier: Double,
        to instances: [SongInstance]
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let effectiveTempo = masterTempo * multiplier

            switch self.syncMode {
            case .independent:
                // Independent mode: Don't apply master tempo
                NSLog("[SyncMode] Independent mode: songs maintain own tempos")
                return

            case .locked:
                // Locked mode: All songs sync to master tempo
                self.applyLockedTempo(effectiveTempo, to: instances)

            case .ratio:
                // Ratio mode: Maintain tempo ratios
                self.applyRatioTempo(effectiveTempo, to: instances)
            }
        }
    }

    // MARK: - Independent Mode

    /// In independent mode, songs maintain their own tempos
    /// No action needed - songs are controlled individually

    // MARK: - Locked Mode

    /// Apply master tempo to all songs (1:1 ratio)
    private func applyLockedTempo(_ tempo: Double, to instances: [SongInstance]) {
        NSLog("[SyncMode] Locked mode: Applying \(tempo) BPM to all songs")

        for instance in instances where instance.isActive {
            if smoothTransitions && transitionDuration > 0 {
                smoothlySetTempo(tempo, for: instance)
            } else {
                instance.setTempo(tempo)
            }
        }
    }

    // MARK: - Ratio Mode

    /// Apply tempo while maintaining relative ratios
    private func applyRatioTempo(_ masterTempo: Double, to instances: [SongInstance]) {
        NSLog("[SyncMode] Ratio mode: Applying \(masterTempo) BPM with ratios")

        // Ensure we have baseline tempos
        if baselineTempos.isEmpty {
            captureBaselineTempos(from: instances)
        }

        for instance in instances where instance.isActive {
            let songId = instance.song.id

            // Calculate or retrieve tempo ratio
            let ratio: Double
            if let existingRatio = tempoRatios[songId] {
                ratio = existingRatio
            } else if let baselineTempo = baselineTempos[songId] {
                // Calculate ratio from baseline
                ratio = baselineTempo / masterTempo
                tempoRatios[songId] = ratio
            } else {
                // Default to 1:1 ratio
                ratio = 1.0
                tempoRatios[songId] = ratio
            }

            // Apply tempo with ratio
            let targetTempo = masterTempo * ratio

            if smoothTransitions && transitionDuration > 0 {
                smoothlySetTempo(targetTempo, for: instance)
            } else {
                instance.setTempo(targetTempo)
            }

            NSLog("[SyncMode] Song \(instance.song.name): \(targetTempo) BPM (ratio: \(String(format: "%.2f", ratio))")
        }
    }

    /// Capture current tempos as baseline for ratio calculations
    public func captureBaselineTempos(from instances: [SongInstance]? = nil) {
        let targetInstances = instances ?? []

        if targetInstances.isEmpty {
            NSLog("[SyncMode] WARNING: No instances to capture baseline tempos")
            return
        }

        for instance in targetInstances where instance.isActive {
            let currentTempo = instance.song.metadata.tempo
            baselineTempos[instance.song.id] = currentTempo
            tempoRatios[instance.song.id] = 1.0 // Start with 1:1 ratio
        }

        NSLog("[SyncMode] Captured baseline tempos for \(baselineTempos.count) songs")
    }

    /// Manually set tempo ratio for a specific song
    public func setTempoRatio(_ ratio: Double, forSongId songId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.tempoRatios[songId] = ratio
            NSLog("[SyncMode] Set tempo ratio for song \(songId): \(ratio)")
        }
    }

    /// Reset tempo ratios to 1:1
    public func resetTempoRatios() {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.tempoRatios.removeAll { $0.value == 1.0 }
            for key in self.tempoRatios.keys {
                self.tempoRatios[key] = 1.0
            }

            NSLog("[SyncMode] Reset all tempo ratios to 1:1")
        }
    }

    // MARK: - Smooth Tempo Transitions

    /// Smoothly transition tempo over time to avoid audio glitches
    private func smoothlySetTempo(_ targetTempo: Double, for instance: SongInstance) {
        let songId = instance.song.id

        // Cancel any existing transition for this song
        if let existing = activeTransitions[songId] {
            existing.cancel()
        }

        // Create new transition
        let transition = TempoTransition(
            instance: instance,
            startTempo: instance.song.metadata.tempo,
            targetTempo: targetTempo,
            duration: transitionDuration,
            queue: queue
        )

        activeTransitions[songId] = transition
        transition.start { [weak self] completed in
            if completed {
                self?.activeTransitions.removeValue(forKey: songId)
            }
        }
    }

    /// Cancel all active tempo transitions
    public func cancelAllTransitions() {
        queue.async { [weak self] in
            guard let self = self else { return }

            for transition in self.activeTransitions.values {
                transition.cancel()
            }

            self.activeTransitions.removeAll()
            NSLog("[SyncMode] Cancelled all tempo transitions")
        }
    }

    // MARK: - Tempo Ratio Calculation

    /// Calculate tempo ratio between two songs
    public func calculateRatio(fromTempo tempo1: Double, toTempo tempo2: Double) -> Double {
        guard tempo1 > 0 else { return 1.0 }
        return tempo2 / tempo1
    }

    /// Get tempo ratio for a specific song
    public func getTempoRatio(forSongId songId: String) -> Double? {
        return tempoRatios[songId]
    }

    /// Get all tempo ratios
    public func getAllTempoRatios() -> [String: Double] {
        return tempoRatios
    }

    // MARK: - State Queries

    /// Get current sync mode state
    public func getSyncState() -> SyncModeState {
        SyncModeState(
            syncMode: syncMode,
            baselineTempos: baselineTempos,
            tempoRatios: tempoRatios,
            transitionDuration: transitionDuration,
            smoothTransitions: smoothTransitions
        )
    }

    /// Restore sync mode state
    public func restoreSyncState(_ state: SyncModeState) {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.syncMode = state.syncMode
            self.baselineTempos = state.baselineTempos
            self.tempoRatios = state.tempoRatios
            self.transitionDuration = state.transitionDuration
            self.smoothTransitions = state.smoothTransitions

            NSLog("[SyncMode] Restored sync state: \(state.syncMode)")
        }
    }
}

// MARK: - Tempo Transition

/// Manages smooth tempo transitions to prevent audio glitches
private final class TempoTransition {

    private let instance: SongInstance
    private let startTempo: Double
    private let targetTempo: Double
    private let duration: Double
    private let queue: DispatchQueue

    private var timer: DispatchSourceTimer?
    private var isCancelled = false
    private let startTime = Date()
    private let updateInterval: Double = 0.01 // 10ms updates

    init(
        instance: SongInstance,
        startTempo: Double,
        targetTempo: Double,
        duration: Double,
        queue: DispatchQueue
    ) {
        self.instance = instance
        self.startTempo = startTempo
        self.targetTempo = targetTempo
        self.duration = duration
        self.queue = queue
    }

    func start(completion: @escaping (Bool) -> Void) {
        // If duration is very short, just set directly
        if duration < 0.01 {
            instance.setTempo(targetTempo)
            completion(true)
            return
        }

        // Create timer for smooth transition
        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer = timer

        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(Int(updateInterval * 1000))
        )

        timer.setEventHandler { [weak self] in
            guard let self = self,
                  !self.isCancelled else {
                completion(false)
                return
            }

            let elapsed = Date().timeIntervalSince(self.startTime)
            let progress = min(elapsed / self.duration, 1.0)

            // Apply easing for smoother transition
            let easedProgress = self.easeInOutCubic(progress)
            let currentTempo = self.startTempo + (self.targetTempo - self.startTempo) * easedProgress

            self.instance.setTempo(currentTempo)

            if progress >= 1.0 {
                self.timer?.cancel()
                completion(true)
            }
        }

        timer.resume()
    }

    func cancel() {
        isCancelled = true
        timer?.cancel()
        timer = nil
    }

    // Easing function for smooth transitions
    private func easeInOutCubic(_ x: Double) -> Double {
        return x < 0.5
            ? 4 * x * x * x
            : 1 - pow(-2 * x + 2, 3) / 2
    }
}

// MARK: - Supporting Types

/// Sync mode state snapshot
public struct SyncModeState: Codable, Sendable {
    public let syncMode: SyncMode
    public let baselineTempos: [String: Double]
    public let tempoRatios: [String: Double]
    public let transitionDuration: Double
    public let smoothTransitions: Bool

    public init(
        syncMode: SyncMode,
        baselineTempos: [String: Double],
        tempoRatios: [String: Double],
        transitionDuration: Double,
        smoothTransitions: Bool
    ) {
        self.syncMode = syncMode
        self.baselineTempos = baselineTempos
        self.tempoRatios = tempoRatios
        self.transitionDuration = transitionDuration
        self.smoothTransitions = smoothTransitions
    }
}
