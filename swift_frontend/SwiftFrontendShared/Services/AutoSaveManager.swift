/**
 * White Room AutoSaveManager
 *
 * Intelligent auto-save system with debouncing and periodic saves.
 * Prevents data loss while avoiding excessive writes.
 *
 * Features:
 * - Debounced saves (2-second delay after changes)
 * - Periodic saves (every 60 seconds if dirty)
 * - Automatic pruning (max 10 autosaves per song)
 * - Restore from any autosave
 * - Thread-safe with actor
 */

import Foundation

// MARK: - AutoSave Manager

/// Manages auto-save operations with debouncing and periodic saves
public actor AutoSaveManager: ObservableObject {
  // MARK: - Properties

  private let autoSaveRepository: AutoSaveRepository
  private let songRepository: SongRepository
  private var debounceTimer: Task<Void, Never>?
  private var periodicTimer: Task<Void, Never>?
  private var pendingSave: PendingSave?

  public var currentSongId: String?
  @Published public var lastSaveTime: Date?
  @Published public var isDirty: Bool = false

  private struct PendingSave {
    let songId: String
    let song: Song
    let timestamp: Date
  }

  // MARK: - Configuration

  private var autoSaveEnabled: Bool { true }
  private var debounceDelay: TimeInterval { 2.0 }  // 2 seconds
  private var periodicInterval: TimeInterval { 60.0 }  // 1 minute
  private var maxAutosaves: Int { 10 }

  // MARK: - Initialization

  public init(
    autoSaveRepository: AutoSaveRepository,
    songRepository: SongRepository
  ) {
    self.autoSaveRepository = autoSaveRepository
    self.songRepository = songRepository
    startPeriodicTimer()
  }

  // MARK: - Public Methods

  /// Mark song as dirty and schedule auto-save
  public func markDirty(_ song: Song) async {
    isDirty = true
    currentSongId = song.id

    let pending = PendingSave(
      songId: song.id,
      song: song,
      timestamp: Date()
    )

    // Store pending save
    self.pendingSave = pending

    // Cancel existing timer
    debounceTimer?.cancel()

    // Start new debounce timer
    debounceTimer = Task {
      do {
        try await Task.sleep(for: .seconds(debounceDelay))

        if !Task.isCancelled {
          try? await performAutoSave(pending)
        }
      } catch {
        // Timer cancelled or error
      }
    }
  }

  /// Immediately save current song (skip debounce)
  public func saveNow() async throws {
    guard let pending = pendingSave else {
      throw AutoSaveError.noPendingSave
    }

    try await performAutoSave(pending)
  }

  /// Discard pending changes
  public func discardPendingSave() {
    debounceTimer?.cancel()
    pendingSave = nil
    isDirty = false
  }

  /// Get all autosaves for current song
  public func getAutosaves() async throws -> [AutoSave] {
    guard let songId = currentSongId else {
      throw AutoSaveError.noCurrentSong
    }

    return try await autoSaveRepository.getAllForSong(songId)
  }

  /// Restore from autosave
  public func restoreFromAutosave(_ autosaveId: String) async throws -> Song {
    guard let autosave = try await autoSaveRepository.read(id: autosaveId) else {
      throw AutoSaveError.autosaveNotFound
    }

    // Decode song from JSON
    let songData = autosave.songJSON.data(using: .utf8)!
    return try JSONDecoder().decode(Song.self, from: songData)
  }

  /// Clear all autosaves for current song
  public func clearAutosaves() async throws {
    guard let songId = currentSongId else {
      throw AutoSaveError.noCurrentSong
    }

    try await autoSaveRepository.deleteAllForSong(songId)
  }

  // MARK: - Private Methods

  private func performAutoSave(_ pending: PendingSave) async throws {
    // Encode song to JSON
    let songData = try JSONEncoder().encode(pending.song)
    let songJSON = String(data: songData, encoding: .utf8)!

    // Create autosave
    let autosave = AutoSave(
      id: UUID().uuidString,
      songId: pending.songId,
      songJSON: songJSON,
      timestamp: pending.timestamp,
      description: generateDescription(pending.song)
    )

    // Save to database
    try await autoSaveRepository.create(autosave)

    // Update state
    lastSaveTime = Date()
    isDirty = false
    self.pendingSave = nil

    // Prune old autosaves
    try await pruneOldAutosaves(for: pending.songId)

    NSLog("Auto-saved song: \(pending.song.name)")
  }

  private func startPeriodicTimer() {
    periodicTimer = Task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(periodicInterval))

          if autoSaveEnabled, isDirty, let pending = pendingSave {
            try? await performAutoSave(pending)
          }
        } catch {
          // Timer cancelled or error
          break
        }
      }
    }
  }

  private func pruneOldAutosaves(for songId: String) async throws {
    let autosaves = try await autoSaveRepository.getAllForSong(songId)

    if autosaves.count > maxAutosaves {
      // Sort by timestamp, oldest first
      let sorted = autosaves.sorted { $0.timestamp < $1.timestamp }
      let toDelete = sorted.dropFirst(maxAutosaves)

      for autosave in toDelete {
        try await autoSaveRepository.delete(id: autosave.id)
      }

      NSLog("AutoSaveManager: Pruned \(toDelete.count) old autosaves")
    }
  }

  private func generateDescription(_ song: Song) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium

    let timestamp = formatter.string(from: Date())
    let trackCount = song.trackConfigs.count
    let sectionCount = song.sections.count

    return "Auto-save - \(timestamp) - \(trackCount) tracks, \(sectionCount) sections"
  }

  // MARK: - Cleanup

  deinit {
    debounceTimer?.cancel()
    periodicTimer?.cancel()
  }
}

// MARK: - AutoSave Error

public enum AutoSaveError: LocalizedError {
  case noPendingSave
  case noCurrentSong
  case autosaveNotFound

  public var errorDescription: String? {
    switch self {
    case .noPendingSave:
      return "No pending save available"
    case .noCurrentSong:
      return "No current song to save"
    case .autosaveNotFound:
      return "Auto-save not found"
    }
  }
}
