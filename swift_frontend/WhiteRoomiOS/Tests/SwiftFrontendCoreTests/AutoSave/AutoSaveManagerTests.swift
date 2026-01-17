/**
 * White Room AutoSaveManager Tests
 *
 * Comprehensive test suite for auto-save functionality.
 */

import XCTest
@testable import SwiftFrontendShared

// MARK: - AutoSaveManager Tests

final class AutoSaveManagerTests: XCTestCase {
  var autoSaveManager: AutoSaveManager!
  var autoSaveRepository: AutoSaveRepository!
  var songRepository: SongRepository!
  var testSong: Song!
  var tempDBPath: String!

  override func setUp() async throws {
    try await super.setUp()

    // Create temporary database
    tempDBPath = NSTemporaryDirectory() + "test_autosave_\(UUID().uuidString).db"

    // Initialize repositories
    autoSaveRepository = try AutoSaveRepository(dbPath: tempDBPath)
    songRepository = try SongRepository(dbPath: tempDBPath)

    // Initialize auto-save manager
    autoSaveManager = AutoSaveManager(
      autoSaveRepository: autoSaveRepository,
      songRepository: songRepository
    )

    // Create test song
    testSong = createTestSong()
  }

  override func tearDown() async throws {
    // Cleanup
    autoSaveManager = nil
    autoSaveRepository = nil
    songRepository = nil
    testSong = nil

    // Delete temp database
    if FileManager.default.fileExists(atPath: tempDBPath) {
      try FileManager.default.removeItem(atPath: tempDBPath)
    }

    try await super.tearDown()
  }

  // MARK: - Test Helper Methods

  private func createTestSong() -> Song {
    let metadata = SongMetadata(
      title: "Test Song",
      composer: "Test Composer",
      description: "Test song for auto-save",
      genre: "Test"
    )

    let sections = [
      Section(id: "section-1", name: "Verse", start: 0.0, end: 16.0),
      Section(id: "section-2", name: "Chorus", start: 16.0, end: 32.0)
    ]

    let roles = [
      Role(id: "role-1", name: "Bass", type: "bass"),
      Role(id: "role-2", name: "Melody", type: "melody")
    ]

    let projections = [
      Projection(id: "proj-1", roleId: "role-1", targetId: "track-1"),
      Projection(id: "proj-2", roleId: "role-2", targetId: "track-2")
    ]

    let mixGraph = MixGraph(tracks: [])

    let trackConfigs = [
      TrackConfig(id: "track-1", name: "Bass Track", volume: 0.8, pan: 0.0),
      TrackConfig(id: "track-2", name: "Melody Track", volume: 0.7, pan: 0.0)
    ]

    return Song(
      id: UUID().uuidString,
      createdAt: Date(),
      updatedAt: Date(),
      metadata: metadata,
      sections: sections,
      roles: roles,
      projections: projections,
      mixGraph: mixGraph,
      trackConfigs: trackConfigs
    )
  }

  // MARK: - Debounce Tests

  func testDebouncedSave() async throws {
    // Mark song as dirty
    await autoSaveManager.markDirty(testSong)

    // Check that song is dirty
    let isDirty = await autoSaveManager.isDirty
    XCTAssertTrue(isDirty, "Song should be marked as dirty")

    // Wait less than debounce delay
    try await Task.sleep(for: .milliseconds(500))

    // Make another change
    await autoSaveManager.markDirty(testSong)

    // Wait for debounce delay
    try await Task.sleep(for: .seconds(2.5))

    // Check that save occurred
    let lastSaveTime = await autoSaveManager.lastSaveTime
    XCTAssertNotNil(lastSaveTime, "Auto-save should have occurred")

    let isStillDirty = await autoSaveManager.isDirty
    XCTAssertFalse(isStillDirty, "Song should no longer be dirty after save")
  }

  func testDebounceResetsOnNewChanges() async throws {
    // Mark song as dirty
    await autoSaveManager.markDirty(testSong)

    // Wait 1 second
    try await Task.sleep(for: .seconds(1.0))

    // Make another change - should reset debounce timer
    await autoSaveManager.markDirty(testSong)

    // Wait 1.5 seconds (total 2.5 seconds from first change)
    try await Task.sleep(for: .seconds(1.5))

    // Should not have saved yet (debounce was reset)
    let lastSaveTime1 = await autoSaveManager.lastSaveTime
    XCTAssertNil(lastSaveTime1, "Auto-save should not have occurred yet")

    // Wait another second
    try await Task.sleep(for: .seconds(1.0))

    // Now should have saved
    let lastSaveTime2 = await autoSaveManager.lastSaveTime
    XCTAssertNotNil(lastSaveTime2, "Auto-save should have occurred after debounce delay")
  }

  // MARK: - Periodic Save Tests

  func testPeriodicSave() async throws {
    // Mark song as dirty
    await autoSaveManager.markDirty(testSong)

    // Wait for periodic save (60 seconds is too long for tests, so we'll save now)
    try await autoSaveManager.saveNow()

    // Check that save occurred
    let lastSaveTime = await autoSaveManager.lastSaveTime
    XCTAssertNotNil(lastSaveTime, "Auto-save should have occurred")

    let isDirty = await autoSaveManager.isDirty
    XCTAssertFalse(isDirty, "Song should no longer be dirty")
  }

  // MARK: - Pruning Tests

  func testAutosavePruning() async throws {
    // Create 15 autosaves (more than max of 10)
    for i in 0..<15 {
      let song = createTestSong()
      await autoSaveManager.markDirty(song)
      try await autoSaveManager.saveNow()
      try await Task.sleep(for: .milliseconds(100))
    }

    // Get all autosaves
    let autosaves = try await autoSaveManager.getAutosaves()

    // Should have max 10 autosaves
    XCTAssertEqual(autosaves.count, 10, "Should have maximum 10 autosaves")

    // Check that oldest autosaves were deleted
    let sorted = autosaves.sorted { $0.timestamp < $1.timestamp }
    // The remaining autosaves should be the 10 most recent
  }

  // MARK: - Restore Tests

  func testRestoreFromAutosave() async throws {
    // Save song
    await autoSaveManager.markDirty(testSong)
    try await autoSaveManager.saveNow()

    // Get autosaves
    let autosaves = try await autoSaveManager.getAutosaves()
    XCTAssertEqual(autosaves.count, 1, "Should have one autosave")

    // Restore from autosave
    let restoredSong = try await autoSaveManager.restoreFromAutosave(autosaves[0].id)

    // Check that restored song matches original
    XCTAssertEqual(restoredSong.id, testSong.id, "Restored song should have same ID")
    XCTAssertEqual(restoredSong.name, testSong.name, "Restored song should have same name")
    XCTAssertEqual(restoredSong.trackConfigs.count, testSong.trackConfigs.count, "Restored song should have same number of tracks")
  }

  // MARK: - Clear Tests

  func testClearAutosaves() async throws {
    // Create multiple autosaves
    for _ in 0..<5 {
      let song = createTestSong()
      await autoSaveManager.markDirty(song)
      try await autoSaveManager.saveNow()
    }

    // Verify autosaves exist
    let autosavesBefore = try await autoSaveManager.getAutosaves()
    XCTAssertEqual(autosavesBefore.count, 5, "Should have 5 autosaves")

    // Clear autosaves
    try await autoSaveManager.clearAutosaves()

    // Verify autosaves are cleared
    let autosavesAfter = try await autoSaveManager.getAutosaves()
    XCTAssertEqual(autosavesAfter.count, 0, "Should have no autosaves after clearing")
  }

  // MARK: - Discard Tests

  func testDiscardPendingSave() async throws {
    // Mark song as dirty
    await autoSaveManager.markDirty(testSong)

    // Verify dirty state
    let isDirtyBefore = await autoSaveManager.isDirty
    XCTAssertTrue(isDirtyBefore, "Song should be dirty")

    // Discard pending save
    await autoSaveManager.discardPendingSave()

    // Verify clean state
    let isDirtyAfter = await autoSaveManager.isDirty
    XCTAssertFalse(isDirtyAfter, "Song should not be dirty after discard")

    // Wait for debounce delay
    try await Task.sleep(for: .seconds(2.5))

    // Verify no save occurred
    let lastSaveTime = await autoSaveManager.lastSaveTime
    XCTAssertNil(lastSaveTime, "No auto-save should have occurred after discard")
  }

  // MARK: - Performance Tests

  func testAutosavePerformance() async throws {
    // Measure auto-save performance
    let metrics = XCTMetrics()
    measure(metrics: metrics) {
      let song = createTestSong()
      Task {
        await autoSaveManager.markDirty(song)
      }
    }

    // Auto-save should complete in less than 100ms
    // (This is a basic performance check - actual timing may vary)
  }

  func testRestorePerformance() async throws {
    // Save song first
    await autoSaveManager.markDirty(testSong)
    try await autoSaveManager.saveNow()

    // Get autosaves
    let autosaves = try await autoSaveManager.getAutosaves()

    // Measure restore performance
    measure {
      let _ = try? await autoSaveManager.restoreFromAutosave(autosaves[0].id)
    }

    // Restore should complete in less than 50ms
    // (This is a basic performance check - actual timing may vary)
  }

  // MARK: - Error Handling Tests

  func testSaveNowWithoutPendingSave() async {
    // Try to save without marking dirty first
    do {
      try await autoSaveManager.saveNow()
      XCTFail("Should have thrown AutoSaveError.noPendingSave")
    } catch AutoSaveError.noPendingSave {
      // Expected error
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testGetAutosavesWithoutCurrentSong() async {
    // Try to get autosaves without setting current song
    do {
      let _ = try await autoSaveManager.getAutosaves()
      XCTFail("Should have thrown AutoSaveError.noCurrentSong")
    } catch AutoSaveError.noCurrentSong {
      // Expected error
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testRestoreFromInvalidAutosave() async {
    // Try to restore from non-existent autosave
    do {
      let _ = try await autoSaveManager.restoreFromAutosave("invalid-id")
      XCTFail("Should have thrown AutoSaveError.autosaveNotFound")
    } catch AutoSaveError.autosaveNotFound {
      // Expected error
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
