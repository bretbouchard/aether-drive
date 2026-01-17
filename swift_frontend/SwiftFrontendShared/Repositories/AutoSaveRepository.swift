/**
 * White Room AutoSaveRepository
 *
 * Repository for managing auto-saved song states in SQLite database.
 * Provides CRUD operations and query methods for autosave management.
 *
 * Auto-saves prevent data loss by storing snapshots of song state
 * at regular intervals or when changes occur.
 */

import Foundation
import SQLite3

// MARK: - AutoSave Model

/// Auto-save snapshot of a song
public struct AutoSave: Codable, Sendable {
  /// Unique identifier for this autosave
  public let id: String

  /// ID of the song this autosave is for
  public let songId: String

  /// Song state serialized as JSON
  public let songJSON: String

  /// When this autosave was created
  public let timestamp: Date

  /// Human-readable description
  public let description: String

  public init(
    id: String,
    songId: String,
    songJSON: String,
    timestamp: Date,
    description: String
  ) {
    self.id = id
    self.songId = songId
    self.songJSON = songJSON
    self.timestamp = timestamp
    self.description = description
  }
}

// MARK: - AutoSave Repository

/// Repository for auto-save operations
public actor AutoSaveRepository {
  // MARK: - Properties

  private let db: OpaquePointer?
  private let tableName = "autosaves"

  // MARK: - Errors

  public enum AutoSaveRepositoryError: Error, LocalizedError {
    case databaseNotFound
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notFound(String)

    public var errorDescription: String? {
      switch self {
      case .databaseNotFound:
        return "Database not found"
      case .queryFailed(let message):
        return "Query failed: \(message)"
      case .insertFailed(let message):
        return "Insert failed: \(message)"
      case .updateFailed(let message):
        return "Update failed: \(message)"
      case .deleteFailed(let message):
        return "Delete failed: \(message)"
      case .notFound(let message):
        return "Not found: \(message)"
      }
    }
  }

  // MARK: - Initialization

  public init(dbPath: String) throws {
    // Open database connection
    var db: OpaquePointer?
    let result = sqlite3_open_v2(
      dbPath,
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
      nil
    )

    guard result == SQLITE_OK, let database = db else {
      throw AutoSaveRepositoryError.databaseNotFound
    }

    self.db = database

    // Create table if not exists
    try createTable()
    try createIndexes()
  }

  deinit {
    if let db = db {
      sqlite3_close(db)
    }
  }

  // MARK: - Table Creation

  private func createTable() throws {
    let createTableSQL = """
    CREATE TABLE IF NOT EXISTS \(tableName) (
      id TEXT PRIMARY KEY,
      song_id TEXT NOT NULL,
      song_json TEXT NOT NULL,
      timestamp REAL NOT NULL,
      description TEXT NOT NULL,
      FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
    );
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    NSLog("AutoSaveRepository: Table '\(tableName)' ready")
  }

  private func createIndexes() throws {
    // Index on song_id for faster queries
    let createSongIdIndexSQL = """
    CREATE INDEX IF NOT EXISTS idx_\(tableName)_song_id
    ON \(tableName)(song_id);
    """

    // Index on timestamp for sorting
    let createTimestampIndexSQL = """
    CREATE INDEX IF NOT EXISTS idx_\(tableName)_timestamp
    ON \(tableName)(timestamp DESC);
    """

    // Composite index for song + timestamp queries
    let createCompositeIndexSQL = """
    CREATE INDEX IF NOT EXISTS idx_\(tableName)_song_timestamp
    ON \(tableName)(song_id, timestamp DESC);
    """

    for sql in [createSongIdIndexSQL, createTimestampIndexSQL, createCompositeIndexSQL] {
      var statement: OpaquePointer?
      defer {
        sqlite3_finalize(statement)
      }

      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        let error = String(cString: sqlite3_errmsg(db))
        throw AutoSaveRepositoryError.queryFailed(error)
      }

      guard sqlite3_step(statement) == SQLITE_DONE else {
        let error = String(cString: sqlite3_errmsg(db))
        throw AutoSaveRepositoryError.queryFailed(error)
      }
    }

    NSLog("AutoSaveRepository: Indexes created")
  }

  // MARK: - CRUD Operations

  /// Create a new autosave
  public func create(_ autosave: AutoSave) throws {
    let insertSQL = """
    INSERT INTO \(tableName) (id, song_id, song_json, timestamp, description)
    VALUES (?, ?, ?, ?, ?);
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.insertFailed(error)
    }

    // Bind parameters
    sqlite3_bind_text(statement, 1, (autosave.id as NSString).utf8String, -1, nil)
    sqlite3_bind_text(statement, 2, (autosave.songId as NSString).utf8String, -1, nil)
    sqlite3_bind_text(statement, 3, (autosave.songJSON as NSString).utf8String, -1, nil)
    sqlite3_bind_double(statement, 4, autosave.timestamp.timeIntervalSince1970)
    sqlite3_bind_text(statement, 5, (autosave.description as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.insertFailed(error)
    }

    NSLog("AutoSaveRepository: Created autosave '\(autosave.id)' for song '\(autosave.songId)'")
  }

  /// Read an autosave by ID
  public func read(id: String) throws -> AutoSave? {
    let selectSQL = """
    SELECT id, song_id, song_json, timestamp, description
    FROM \(tableName)
    WHERE id = ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return nil
    }

    return try mapRowToAutoSave(statement: statement)
  }

  /// Update an existing autosave
  public func update(_ autosave: AutoSave) throws {
    let updateSQL = """
    UPDATE \(tableName)
    SET song_json = ?, timestamp = ?, description = ?
    WHERE id = ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.updateFailed(error)
    }

    sqlite3_bind_text(statement, 1, (autosave.songJSON as NSString).utf8String, -1, nil)
    sqlite3_bind_double(statement, 2, autosave.timestamp.timeIntervalSince1970)
    sqlite3_bind_text(statement, 3, (autosave.description as NSString).utf8String, -1, nil)
    sqlite3_bind_text(statement, 4, (autosave.id as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.updateFailed(error)
    }

    NSLog("AutoSaveRepository: Updated autosave '\(autosave.id)'")
  }

  /// Delete an autosave by ID
  public func delete(id: String) throws {
    let deleteSQL = """
    DELETE FROM \(tableName)
    WHERE id = ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    NSLog("AutoSaveRepository: Deleted autosave '\(id)'")
  }

  // MARK: - Query Methods

  /// Get all autosaves for a specific song
  public func getAllForSong(_ songId: String) throws -> [AutoSave] {
    let selectSQL = """
    SELECT id, song_id, song_json, timestamp, description
    FROM \(tableName)
    WHERE song_id = ?
    ORDER BY timestamp DESC;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    sqlite3_bind_text(statement, 1, (songId as NSString).utf8String, -1, nil)

    var results: [AutoSave] = []
    while sqlite3_step(statement) == SQLITE_ROW {
      try results.append(mapRowToAutoSave(statement: statement))
    }

    return results
  }

  /// Get the latest autosave for a song
  public func getLatestForSong(_ songId: String) throws -> AutoSave? {
    let selectSQL = """
    SELECT id, song_id, song_json, timestamp, description
    FROM \(tableName)
    WHERE song_id = ?
    ORDER BY timestamp DESC
    LIMIT 1;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    sqlite3_bind_text(statement, 1, (songId as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return nil
    }

    return try mapRowToAutoSave(statement: statement)
  }

  /// Get all autosaves (for admin/debugging)
  public func getAll() throws -> [AutoSave] {
    let selectSQL = """
    SELECT id, song_id, song_json, timestamp, description
    FROM \(tableName)
    ORDER BY timestamp DESC;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    var results: [AutoSave] = []
    while sqlite3_step(statement) == SQLITE_ROW {
      try results.append(mapRowToAutoSave(statement: statement))
    }

    return results
  }

  /// Get count of autosaves for a song
  public func countForSong(_ songId: String) throws -> Int {
    let countSQL = """
    SELECT COUNT(*) as count
    FROM \(tableName)
    WHERE song_id = ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.queryFailed(error)
    }

    sqlite3_bind_text(statement, 1, (songId as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return 0
    }

    return Int(sqlite3_column_int64(statement, 0))
  }

  // MARK: - Batch Operations

  /// Delete all autosaves for a specific song
  public func deleteAllForSong(_ songId: String) throws {
    let deleteSQL = """
    DELETE FROM \(tableName)
    WHERE song_id = ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    sqlite3_bind_text(statement, 1, (songId as NSString).utf8String, -1, nil)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    let changes = sqlite3_changes(db)
    NSLog("AutoSaveRepository: Deleted \(changes) autosaves for song '\(songId)'")
  }

  /// Delete old autosaves (older than specified date)
  public func deleteOlderThan(_ date: Date) throws -> Int {
    let deleteSQL = """
    DELETE FROM \(tableName)
    WHERE timestamp < ?;
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    sqlite3_bind_double(statement, 1, date.timeIntervalSince1970)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    let changes = sqlite3_changes(db)
    NSLog("AutoSaveRepository: Deleted \(changes) autosaves older than \(date)")
    return Int(changes)
  }

  /// Delete all autosaves (for admin/debugging)
  public func deleteAll() throws {
    let deleteSQL = """
    DELETE FROM \(tableName);
    """

    var statement: OpaquePointer?
    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let error = String(cString: sqlite3_errmsg(db))
      throw AutoSaveRepositoryError.deleteFailed(error)
    }

    let changes = sqlite3_changes(db)
    NSLog("AutoSaveRepository: Deleted all \(changes) autosaves")
  }

  // MARK: - Helper Methods

  private func mapRowToAutoSave(statement: OpaquePointer?) throws -> AutoSave {
    guard let statement = statement else {
      throw AutoSaveRepositoryError.queryFailed("Invalid statement")
    }

    let id = String(cString: sqlite3_column_text(statement, 0))
    let songId = String(cString: sqlite3_column_text(statement, 1))
    let songJSON = String(cString: sqlite3_column_text(statement, 2))
    let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
    let description = String(cString: sqlite3_column_text(statement, 4))

    return AutoSave(
      id: id,
      songId: songId,
      songJSON: songJSON,
      timestamp: timestamp,
      description: description
    )
  }
}
