//
//  ExportManager.swift
//  SwiftFrontendShared
//
//  Manages export and import of backups to/from files
//

import Foundation

/// Manages export and import of backups
public actor ExportManager {
    private let backupManager: BackupManager
    private let backupRepository: BackupRepository

    public init(
        backupManager: BackupManager,
        backupRepository: BackupRepository
    ) {
        self.backupManager = backupManager
        self.backupRepository = backupRepository
    }

    // MARK: - Public Methods

    /// Export backup to file
    public func exportBackup(_ backupId: String, to url: URL) async throws {
        guard let backup = try await backupRepository.read(id: backupId) else {
            throw ExportError.backupNotFound
        }

        // Create export data
        let exportData = BackupExportData(
            version: backup.version,
            timestamp: backup.timestamp,
            description: backup.description,
            songs: backup.songsJSON,
            performances: backup.performancesJSON,
            preferences: backup.preferencesJSON
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(exportData)

        // Ensure directory exists
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Write to file
        try jsonData.write(to: url)

        NSLog("Exported backup to: \(url.path)")
    }

    /// Import backup from file
    public func importBackup(from url: URL) async throws -> Backup {
        // Read file
        let jsonData = try Data(contentsOf: url)

        // Decode
        let decoder = JSONDecoder()
        let exportData = try decoder.decode(BackupExportData.self, from: jsonData)

        // Validate data
        guard try JSONDecoder().decode([Song].self, from: exportData.songs.data(using: .utf8)!) is [Song] else {
            throw ExportError.invalidFile
        }

        // Create backup record
        let backup = Backup(
            id: UUID().uuidString,
            timestamp: exportData.timestamp,
            description: "\(exportData.description) (Imported)",
            songsJSON: exportData.songs,
            performancesJSON: exportData.performances,
            preferencesJSON: exportData.preferences,
            size: jsonData.count,
            version: exportData.version
        )

        // Save to database
        try await backupRepository.create(backup)

        NSLog("Imported backup from: \(url.path)")
        return backup
    }

    /// Export songs to individual JSON files
    public func exportSongs(to directoryURL: URL) async throws {
        let songs = try await backupManager.songRepository.getAll()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for song in songs {
            let filename = "\(song.name.replacingOccurrences(of: "/", with: "-")).json"
            let fileURL = directoryURL.appendingPathComponent(filename)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(song)
            try jsonData.write(to: fileURL)
        }

        NSLog("Exported \(songs.count) songs to: \(directoryURL.path)")
    }

    /// Export performances to individual JSON files
    public func exportPerformances(to directoryURL: URL) async throws {
        let performances = try await backupManager.performanceRepository.getAll()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for performance in performances {
            let filename = "\(performance.name.replacingOccurrences(of: "/", with: "-")).json"
            let fileURL = directoryURL.appendingPathComponent(filename)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(performance)
            try jsonData.write(to: fileURL)
        }

        NSLog("Exported \(performances.count) performances to: \(directoryURL.path)")
    }

    /// Export user preferences to JSON file
    public func exportPreferences(to url: URL) async throws {
        let preferences = try await backupManager.userPreferencesRepository.getDefault()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(preferences)

        // Ensure directory exists
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try jsonData.write(to: url)

        NSLog("Exported preferences to: \(url.path)")
    }

    /// Import songs from JSON files
    public func importSongs(from directoryURL: URL) async throws -> Int {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        var importedCount = 0

        for fileURL in fileURLs {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let song = try decoder.decode(Song.self, from: jsonData)

                // Check if song already exists
                if let existing = try await backupManager.songRepository.read(id: song.id) {
                    // Update existing song
                    try await backupManager.songRepository.update(song)
                } else {
                    // Create new song
                    try await backupManager.songRepository.create(song)
                }

                importedCount += 1
            } catch {
                NSLog("Failed to import song from \(fileURL.path): \(error.localizedDescription)")
            }
        }

        NSLog("Imported \(importedCount) songs from: \(directoryURL.path)")
        return importedCount
    }

    /// Get default export directory
    public func getDefaultExportDirectory() throws -> URL {
        let fileManager = FileManager.default

        // Get Application Support directory
        guard let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw ExportError.exportFailed
        }

        // Create app-specific directory
        let appDirectory = appSupportURL.appendingPathComponent("White Room", isDirectory: true)
        let exportsDirectory = appDirectory.appendingPathComponent("Exports", isDirectory: true)

        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)

        return exportsDirectory
    }

    /// Generate default backup filename
    public func generateBackupFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "whiteroom_backup_\(timestamp).json"
    }

    /// Get available exports
    public func getAvailableExports() throws -> [URL] {
        let directory = try getDefaultExportDirectory()

        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ).filter { $0.pathExtension == "json" }

        return fileURLs.sorted { url1, url2 in
            guard let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                  let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                return false
            }
            return date1 > date2
        }
    }

    /// Delete export file
    public func deleteExport(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        NSLog("Deleted export: \(url.path)")
    }
}

/// Export-related errors
public enum ExportError: LocalizedError, Sendable {
    case backupNotFound
    case invalidFile
    case exportFailed
    case importFailed(String)

    public var errorDescription: String? {
        switch self {
        case .backupNotFound:
            return "Backup not found"
        case .invalidFile:
            return "Invalid file format"
        case .exportFailed:
            return "Failed to export backup"
        case .importFailed(let message):
            return "Failed to import backup: \(message)"
        }
    }
}
