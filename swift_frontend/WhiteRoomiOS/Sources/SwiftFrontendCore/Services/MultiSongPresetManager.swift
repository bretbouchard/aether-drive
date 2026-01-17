//
//  MultiSongPresetManager.swift
//  SwiftFrontendCore
//
//  Created by White Room AI
//  Copyright © 2026 White Room. All rights reserved.
//
//  Manages saving, loading, and organizing multi-song presets
//  with undo/redo support and library management.

import Foundation
import Combine

/// Manager for multi-song preset library
public final class MultiSongPresetManager: ObservableObject {

    // MARK: - Published State

    /// All available presets
    @Published public private(set) var presets: [MultiSongPreset] = []

    /// Currently loaded preset
    @Published public private(set) var currentPreset: MultiSongPreset?

    /// Last save time
    @Published public private(set) var lastSaveTime: Date?

    /// Library metadata
    @Published public private(set) var libraryMetadata: PresetLibrary

    // MARK: - Dependencies

    private let undoManager: UndoManager?
    private let fileManager: FileManager = .default

    // MARK: - Paths

    private let presetsDirectory: URL
    private let libraryFilePath: URL

    // MARK: - Thread Safety

    private let queue = DispatchQueue(
        label: "com.whiteroom.audio.preset_manager",
        qos: .userInitiated
    )

    // MARK: - Cancellables

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        presetsDirectory: URL? = nil,
        undoManager: UndoManager? = nil
    ) throws {
        self.undoManager = undoManager

        // Set up directories
        let baseDirectory = presetsDirectory ?? Self.defaultPresetsDirectory()
        self.presetsDirectory = baseDirectory
        self.libraryFilePath = baseDirectory.appendingPathComponent("library.json")

        // Initialize library
        self.libraryMetadata = try Self.loadLibraryMetadata(from: libraryFilePath)
            ?? PresetLibrary()

        // Create presets directory if needed
        try createDirectoryIfNeeded()

        // Load all presets
        try loadAllPresets()

        NSLog("[PresetManager] Initialized with \(presets.count) presets")
    }

    // MARK: - Default Directory

    /// Get default presets directory
    public static func defaultPresetsDirectory() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let whiteRoomDir = appSupport.appendingPathComponent("WhiteRoom", isDirectory: true)
        let presetsDir = whiteRoomDir.appendingPathComponent("Presets", isDirectory: true)

        return presetsDir
    }

    // MARK: - Directory Management

    /// Create presets directory if it doesn't exist
    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: presetsDirectory.path) {
            try fileManager.createDirectory(
                at: presetsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            NSLog("[PresetManager] Created presets directory: \(presetsDirectory.path)")
        }
    }

    // MARK: - Library Management

    /// Load library metadata from disk
    private static func loadLibraryMetadata(from path: URL) throws -> PresetLibrary? {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }

        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(PresetLibrary.self, from: data)
    }

    /// Save library metadata to disk
    private func saveLibraryMetadata() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(libraryMetadata)
        try data.write(to: libraryFilePath, options: .atomic)

        DispatchQueue.main.async { [weak self] in
            self?.lastSaveTime = Date()
        }

        NSLog("[PresetManager] Saved library metadata")
    }

    // MARK: - Load Presets

    /// Load all presets from directory
    private func loadAllPresets() throws {
        let fileURLs = try fileManager.contentsOfDirectory(
            at: presetsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let presetFiles = fileURLs.filter { $0.pathExtension == "json" }

        var loadedPresets: [MultiSongPreset] = []

        for fileURL in presetFiles {
            // Skip library.json
            if fileURL.lastPathComponent == "library.json" {
                continue
            }

            do {
                let data = try Data(contentsOf: fileURL)
                let preset = try JSONDecoder().decode(MultiSongPreset.self, from: data)
                loadedPresets.append(preset)
            } catch {
                NSLog("[PresetManager] WARNING: Failed to load preset from \(fileURL.path): \(error)")
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.presets = loadedPresets.sorted { $0.name < $1.name }
        }

        NSLog("[PresetManager] Loaded \(loadedPresets.count) presets")
    }

    // MARK: - Save Preset

    /// Save current state as a new preset
    public func savePreset(
        name: String,
        description: String? = nil,
        masterState: MasterTransportState,
        syncState: SyncModeState,
        overwrite: Bool = false
    ) throws {
        queue.async { [weak self] in
            guard let self = self else { return }

            do {
                // Create preset from current state
                let preset = MultiSongPreset.fromCurrentState(
                    name: name,
                    description: description,
                    masterState: masterState,
                    syncState: syncState
                )

                // Validate preset
                let validation = preset.validate()
                if !validation.isValid {
                    throw PresetError.validationFailed(validation.errors)
                }

                // Check for existing preset with same name
                if let existing = self.presets.first(where: { $0.name == name }) {
                    if overwrite {
                        // Update existing preset
                        var updated = preset
                        updated.id = existing.id
                        updated.createdAt = existing.createdAt
                        try self.savePresetToFile(updated)
                        self.updatePresetInLibrary(updated)
                    } else {
                        throw PresetError.validationFailed([
                            "Preset '\(name)' already exists. Use overwrite=true to replace it."
                        ])
                    }
                } else {
                    // Save new preset
                    try self.savePresetToFile(preset)
                    self.addPresetToLibrary(preset)
                }

                // Register undo
                if let undoManager = self.undoManager {
                    undoManager.registerUndo(
                        withTarget: self,
                        selector: #selector(self.undoSavePreset(_:)),
                        object: preset.id
                    )
                    undoManager.setActionName("Save Preset")
                }

                NSLog("[PresetManager] Saved preset: \(name)")
            } catch {
                NSLog("[PresetManager] ERROR: Failed to save preset: \(error)")
                throw error
            }
        }
    }

    @objc private func undoSavePreset(_ presetId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            do {
                try self.deletePreset(withId: presetId, undoable: false)
                NSLog("[PresetManager] Undid preset save")
            } catch {
                NSLog("[PresetManager] ERROR: Failed to undo preset save: \(error)")
            }
        }
    }

    /// Save preset to file
    private func savePresetToFile(_ preset: MultiSongPreset) throws {
        let fileName = "\(sanitizedFileName(preset.name)).json"
        let fileURL = presetsDirectory.appendingPathComponent(fileName)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(preset)
        try data.write(to: fileURL, options: .atomic)

        DispatchQueue.main.async { [weak self] in
            self?.lastSaveTime = Date()
        }

        NSLog("[PresetManager] Saved preset to file: \(fileURL.path)")
    }

    // MARK: - Load Preset

    /// Load preset by ID
    public func loadPreset(withId id: String) throws -> MultiSongPreset {
        guard let preset = presets.first(where: { $0.id == id }) else {
            throw PresetError.fileNotFound(presetsDirectory)
        }

        // Validate preset
        let validation = preset.validate()
        if !validation.isValid {
            NSLog("[PresetManager] WARNING: Loaded preset has validation errors: \(validation.errors)")
        }

        DispatchQueue.main.async { [weak self] in
            self?.currentPreset = preset
        }

        // Register undo
        if let undoManager = undoManager {
            undoManager.registerUndo(
                withTarget: self,
                selector: #selector(self.undoLoadPreset),
                object: nil
            )
            undoManager.setActionName("Load Preset")
        }

        NSLog("[PresetManager] Loaded preset: \(preset.name)")

        if let warnings = validation.warningDescription {
            NSLog("[PresetManager] Validation warnings: \(warnings)")
        }

        return preset
    }

    @objc private func undoLoadPreset() {
        // Clear current preset
        DispatchQueue.main.async { [weak self] in
            self?.currentPreset = nil
        }
        NSLog("[PresetManager] Undid preset load")
    }

    /// Load preset from file URL
    public func loadPreset(from url: URL) throws -> MultiSongPreset {
        let data = try Data(contentsOf: url)
        let preset = try JSONDecoder().decode(MultiSongPreset.self, from: data)

        // Validate
        let validation = preset.validate()
        if !validation.isValid {
            throw PresetError.validationFailed(validation.errors)
        }

        return preset
    }

    // MARK: - Delete Preset

    /// Delete preset by ID
    public func deletePreset(withId id: String, undoable: Bool = true) throws {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let preset = self.presets.first(where: { $0.id == id }) else {
                throw PresetError.fileNotFound(self.presetsDirectory)
            }

            // Store for undo
            let presetToDelete = preset

            // Delete file
            let fileName = "\(self.sanitizedFileName(preset.name)).json"
            let fileURL = self.presetsDirectory.appendingPathComponent(fileName)

            if self.fileManager.fileExists(atPath: fileURL.path) {
                try self.fileManager.removeItem(at: fileURL)
            }

            // Remove from library
            self.removePresetFromLibrary(id)

            // Register undo
            if undoable, let undoManager = self.undoManager {
                undoManager.registerUndo(
                    withTarget: self,
                    selector: #selector(self.undoDeletePreset(_:)),
                    object: presetToDelete
                )
                undoManager.setActionName("Delete Preset")
            }

            NSLog("[PresetManager] Deleted preset: \(preset.name)")
        }
    }

    @objc private func undoDeletePreset(_ preset: MultiSongPreset) {
        queue.async { [weak self] in
            guard let self = self else { return }

            do {
                try self.savePresetToFile(preset)
                self.addPresetToLibrary(preset)
                NSLog("[PresetManager] Undid preset delete")
            } catch {
                NSLog("[PresetManager] ERROR: Failed to undo preset delete: \(error)")
            }
        }
    }

    // MARK: - Import/Export

    /// Import preset from file
    public func importPreset(from url: URL, overwrite: Bool = false) throws {
        let preset = try loadPreset(from: url)

        // Check for existing preset with same name
        if let existing = presets.first(where: { $0.name == preset.name }) {
            if overwrite {
                try deletePreset(withId: existing.id, undoable: false)
            } else {
                throw PresetError.validationFailed([
                    "Preset '\(preset.name)' already exists. Use overwrite=true to replace it."
                ])
            }
        }

        // Save to library
        try savePresetToFile(preset)
        addPresetToLibrary(preset)

        NSLog("[PresetManager] Imported preset: \(preset.name)")
    }

    /// Export preset to file
    public func exportPreset(withId id: String, to url: URL) throws {
        guard let preset = presets.first(where: { $0.id == id }) else {
            throw PresetError.fileNotFound(presetsDirectory)
        }

        let data = try preset.exportToJSON()
        try data.write(to: url, options: .atomic)

        NSLog("[PresetManager] Exported preset to: \(url.path)")
    }

    // MARK: - Library Operations

    /// Add preset to library
    private func addPresetToLibrary(_ preset: MultiSongPreset) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.presets.append(preset)
            self.presets.sort { $0.name < $1.name }
            self.libraryMetadata.presets.append(preset)
        }

        try? saveLibraryMetadata()
    }

    /// Update preset in library
    private func updatePresetInLibrary(_ preset: MultiSongPreset) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let index = self.presets.firstIndex(where: { $0.id == preset.id }) {
                self.presets[index] = preset
            }

            if let index = self.libraryMetadata.presets.firstIndex(where: { $0.id == preset.id }) {
                self.libraryMetadata.presets[index] = preset
            }
        }

        try? saveLibraryMetadata()
    }

    /// Remove preset from library
    private func removePresetFromLibrary(_ id: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.presets.removeAll { $0.id == id }
            self.libraryMetadata.presets.removeAll { $0.id == id }
            self.libraryMetadata.defaultPresetIds.removeAll { $0 == id }
        }

        try? saveLibraryMetadata()
    }

    /// Set default presets
    public func setDefaultPresets(_ presetIds: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.libraryMetadata.defaultPresetIds = presetIds
            }

            try? self.saveLibraryMetadata()
            NSLog("[PresetManager] Set \(presetIds.count) default presets")
        }
    }

    // MARK: - Search

    /// Search presets by name
    public func searchPresets(query: String) -> [MultiSongPreset] {
        presets.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    /// Search presets by tag
    public func searchPresetsByTag(_ tag: String) -> [MultiSongPreset] {
        presets.filter {
            $0.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
        }
    }

    // MARK: - Utilities

    /// Sanitize filename
    private func sanitizedFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?*|<>\"")
        return name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Get default presets
    public var defaultPresets: [MultiSongPreset] {
        presets.filter { libraryMetadata.defaultPresetIds.contains($0.id) }
    }

    /// Initialize default presets if library is empty
    public func initializeDefaultPresets() throws {
        guard presets.isEmpty else {
            NSLog("[PresetManager] Library already has presets, skipping initialization")
            return
        }

        let defaults = DefaultPresets.allDefaults()

        for preset in defaults {
            try savePresetToFile(preset)
            addPresetToLibrary(preset)
        }

        // Set first default
        if let first = defaults.first {
            setDefaultPresets([first.id])
        }

        NSLog("[PresetManager] Initialized \(defaults.count) default presets")
    }
}

// MARK: - Preset File Management

extension MultiSongPresetManager {

    /// Get file URL for preset
    public func fileURL(for preset: MultiSongPreset) -> URL {
        let fileName = "\(sanitizedFileName(preset.name)).json"
        return presetsDirectory.appendingPathComponent(fileName)
    }

    /// Check if preset file exists
    public func presetFileExists(for preset: MultiSongPreset) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: preset).path)
    }

    /// Get all preset file URLs
    public func allPresetFileURLs() throws -> [URL] {
        let fileURLs = try fileManager.contentsOfDirectory(
            at: presetsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return fileURLs.filter { $0.pathExtension == "json" }
    }
}
