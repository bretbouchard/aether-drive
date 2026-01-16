//
//  MixingPresets.swift
//  White Room Mixing Console
//
//  Preset management system for channel strip configurations
//

import Foundation
import SwiftUI

// MARK: - Preset Category

public enum PresetCategory: String, CaseIterable, Identifiable {
    public var id: String { rawValue }

    case vocal = "Vocal"
    case drums = "Drums"
    case bass = "Bass"
    case guitar = "Guitar"
    case keyboard = "Keyboard"
    case strings = "Strings"
    case brass = "Brass"
    case woodwinds = "Woodwinds"
    case synth = "Synth"
    case fx = "FX"
    case custom = "Custom"

    public var displayName: String {
        rawValue
    }
}

// MARK: - EQ Band

public struct EQBand: Codable, Identifiable, Equatable {
    public let id: String
    public var frequency: Double
    public var gain: Double
    public var q: Double

    public init(frequency: Double, gain: Double, q: Double) {
        self.id = UUID().uuidString
        self.frequency = frequency
        self.gain = gain
        self.q = q
    }
}

// MARK: - Channel Strip Configuration

public struct ChannelStripConfig: Codable, Equatable {
    public var type: ChannelType
    public var eqEnabled: Bool
    public var eqBands: [EQBand]
    public var compressionEnabled: Bool
    public var compressionThreshold: Double
    public var compressionRatio: Double
    public var compressionAttack: Double
    public var compressionRelease: Double
    public var inserts: [InsertSlot]
    public var sends: [Send]

    public init(
        type: ChannelType = .audio,
        eqEnabled: Bool = false,
        eqBands: [EQBand] = [],
        compressionEnabled: Bool = false,
        compressionThreshold: Double = -20.0,
        compressionRatio: Double = 2.0,
        compressionAttack: Double = 10.0,
        compressionRelease: Double = 100.0,
        inserts: [InsertSlot] = [],
        sends: [Send] = []
    ) {
        self.type = type
        self.eqEnabled = eqEnabled
        self.eqBands = eqBands
        self.compressionEnabled = compressionEnabled
        self.compressionThreshold = compressionThreshold
        self.compressionRatio = compressionRatio
        self.compressionAttack = compressionAttack
        self.compressionRelease = compressionRelease
        self.inserts = inserts
        self.sends = sends
    }
}

// MARK: - Channel Strip Preset

public struct ChannelStripPreset: Identifiable, Equatable {
    public let id: String
    public var name: String
    public var category: PresetCategory
    public var description: String
    public var config: ChannelStripConfig
    public var icon: String
    public var color: String
    public var tags: [String]

    public init(
        id: String,
        name: String,
        category: PresetCategory,
        description: String,
        config: ChannelStripConfig,
        icon: String = "slider.horizontal.3",
        color: String = "#8B5CF6",
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.config = config
        self.icon = icon
        self.color = color
        self.tags = tags
    }
}

// MARK: - Mixing Preset Manager

@MainActor
public class MixingPresetManager: ObservableObject {
    @Published public var presets: [ChannelStripPreset]
    private weak var console: MixingConsole?

    public init(console: MixingConsole? = nil) {
        self.console = console
        self.presets = []
        initializeDefaultPresets()
    }

    // MARK: - Default Presets

    private func initializeDefaultPresets() {
        // Vocal presets
        presets.append(ChannelStripPreset(
            id: "preset-vocal-lead",
            name: "Lead Vocal",
            category: .vocal,
            description: "Bright lead vocal with presence and air",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 120, gain: -3, q: 0.7),
                    EQBand(frequency: 1000, gain: 2, q: 1.0),
                    EQBand(frequency: 5000, gain: 4, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -18,
                compressionRatio: 3,
                compressionAttack: 10,
                compressionRelease: 100,
                inserts: [
                    InsertSlot(id: "insert-compressor", enabled: true, effect: "compressor", parameters: [
                        "threshold": -18,
                        "ratio": 3,
                        "attack": 10,
                        "release": 100
                    ])
                ],
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.3, prePost: .post)
                ]
            ),
            icon: "mic.fill",
            color: "#FF6B6B",
            tags: ["vocal", "lead", "bright", "presence"]
        ))

        presets.append(ChannelStripPreset(
            id: "preset-vocal-backing",
            name: "Backing Vocal",
            category: .vocal,
            description: "Warm backing vocal with reverb",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: 2, q: 0.7),
                    EQBand(frequency: 3000, gain: 1, q: 1.0),
                    EQBand(frequency: 8000, gain: -2, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -20,
                compressionRatio: 4,
                compressionAttack: 15,
                compressionRelease: 80,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.5, prePost: .post),
                    Send(id: "send-delay", bus: "bus-delay-1", amount: 0.2, prePost: .post)
                ]
            ),
            icon: "mic.fill",
            color: "#FF8787",
            tags: ["vocal", "backing", "warm", "reverb"]
        ))

        // Drums presets
        presets.append(ChannelStripPreset(
            id: "preset-drums-kit",
            name: "Drum Kit",
            category: .drums,
            description: "Punchy drum kit with room reverb",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 100, gain: 6, q: 0.5),
                    EQBand(frequency: 2000, gain: 3, q: 1.0),
                    EQBand(frequency: 8000, gain: -2, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -12,
                compressionRatio: 4,
                compressionAttack: 5,
                compressionRelease: 50,
                sends: [
                    Send(id: "send-room", bus: "bus-reverb-1", amount: 0.2, prePost: .post)
                ]
            ),
            icon: "drum.fill",
            color: "#4ECDC4",
            tags: ["drums", "punchy", "room"]
        ))

        presets.append(ChannelStripPreset(
            id: "preset-drums-snare",
            name: "Snare Drum",
            category: .drums,
            description: "Crack and body for snare drum",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: 4, q: 0.7),
                    EQBand(frequency: 1000, gain: 2, q: 1.0),
                    EQBand(frequency: 6000, gain: 3, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -15,
                compressionRatio: 4,
                compressionAttack: 5,
                compressionRelease: 40,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.25, prePost: .post)
                ]
            ),
            icon: "speaker.wave.2.fill",
            color: "#45B7D1",
            tags: ["drums", "snare", "crack"]
        ))

        // Bass presets
        presets.append(ChannelStripPreset(
            id: "preset-bass-electric",
            name: "Electric Bass",
            category: .bass,
            description: "Warm electric bass with compression",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 80, gain: 4, q: 0.7),
                    EQBand(frequency: 400, gain: -2, q: 1.0),
                    EQBand(frequency: 1500, gain: 2, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -15,
                compressionRatio: 4,
                compressionAttack: 5,
                compressionRelease: 50
            ),
            icon: "speaker.wave.2.fill",
            color: "#45B7D1",
            tags: ["bass", "warm", "compressed"]
        ))

        presets.append(ChannelStripPreset(
            id: "preset-bass-synth",
            name: "Synth Bass",
            category: .bass,
            description: "Punchy synth bass with sub",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 60, gain: 6, q: 0.5),
                    EQBand(frequency: 800, gain: 3, q: 1.0),
                    EQBand(frequency: 3000, gain: -3, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -12,
                compressionRatio: 5,
                compressionAttack: 3,
                compressionRelease: 30
            ),
            icon: "waveform.path",
            color: "#9B59B6",
            tags: ["bass", "synth", "sub", "punchy"]
        ))

        // Guitar presets
        presets.append(ChannelStripPreset(
            id: "preset-guitar-acoustic",
            name: "Acoustic Guitar",
            category: .guitar,
            description: "Natural acoustic guitar with sparkle",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: -3, q: 0.7),
                    EQBand(frequency: 1000, gain: 2, q: 1.0),
                    EQBand(frequency: 8000, gain: 4, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -20,
                compressionRatio: 3,
                compressionAttack: 10,
                compressionRelease: 80,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.15, prePost: .post)
                ]
            ),
            icon: "guitar",
            color: "#F39C12",
            tags: ["guitar", "acoustic", "natural"]
        ))

        // Keyboard presets
        presets.append(ChannelStripPreset(
            id: "preset-keyboard-piano",
            name: "Piano",
            category: .keyboard,
            description: "Grand piano with natural resonance",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 100, gain: 3, q: 0.5),
                    EQBand(frequency: 1000, gain: 2, q: 1.0),
                    EQBand(frequency: 6000, gain: 3, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -18,
                compressionRatio: 2.5,
                compressionAttack: 15,
                compressionRelease: 100,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.2, prePost: .post)
                ]
            ),
            icon: "pianokeys",
            color: "#3498DB",
            tags: ["keyboard", "piano", "natural"]
        ))

        // Strings presets
        presets.append(ChannelStripPreset(
            id: "preset-strings-section",
            name: "String Section",
            category: .strings,
            description: "Lush string section with reverb",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 300, gain: 3, q: 0.7),
                    EQBand(frequency: 2000, gain: 2, q: 1.0),
                    EQBand(frequency: 8000, gain: 4, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -15,
                compressionRatio: 2,
                compressionAttack: 20,
                compressionRelease: 100,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.4, prePost: .post)
                ]
            ),
            icon: "music.note",
            color: "#E8B4B8",
            tags: ["strings", "lush", "orchestral"]
        ))

        // Synth presets
        presets.append(ChannelStripPreset(
            id: "preset-synth-pad",
            name: "Synth Pad",
            category: .synth,
            description: "Warm ambient pad with delay",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: 4, q: 0.7),
                    EQBand(frequency: 2000, gain: 2, q: 1.0),
                    EQBand(frequency: 6000, gain: -2, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -12,
                compressionRatio: 3,
                compressionAttack: 20,
                compressionRelease: 100,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.5, prePost: .post),
                    Send(id: "send-delay", bus: "bus-delay-1", amount: 0.3, prePost: .post)
                ]
            ),
            icon: "waveform.path",
            color: "#9B59B6",
            tags: ["synth", "pad", "ambient"]
        ))

        presets.append(ChannelStripPreset(
            id: "preset-synth-lead",
            name: "Synth Lead",
            category: .synth,
            description: "Bright cutting lead synth",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: -2, q: 0.7),
                    EQBand(frequency: 2000, gain: 4, q: 1.0),
                    EQBand(frequency: 6000, gain: 5, q: 1.5)
                ],
                compressionEnabled: true,
                compressionThreshold: -10,
                compressionRatio: 4,
                compressionAttack: 5,
                compressionRelease: 30
            ),
            icon: "waveform.path",
            color: "#8E44AD",
            tags: ["synth", "lead", "bright"]
        ))

        // FX presets
        presets.append(ChannelStripPreset(
            id: "preset-fx-ambient",
            name: "Ambient FX",
            category: .fx,
            description: "Atmospheric sound design with heavy reverb",
            config: ChannelStripConfig(
                type: .audio,
                eqEnabled: true,
                eqBands: [
                    EQBand(frequency: 200, gain: 4, q: 0.7),
                    EQBand(frequency: 2000, gain: 2, q: 1.0),
                    EQBand(frequency: 8000, gain: -2, q: 1.0)
                ],
                compressionEnabled: true,
                compressionThreshold: -15,
                compressionRatio: 3,
                compressionAttack: 20,
                compressionRelease: 100,
                sends: [
                    Send(id: "send-reverb", bus: "bus-reverb-1", amount: 0.8, prePost: .post),
                    Send(id: "send-delay", bus: "bus-delay-1", amount: 0.5, prePost: .post)
                ]
            ),
            icon: "sparkles",
            color: "#16A085",
            tags: ["fx", "ambient", "atmospheric"]
        ))
    }

    // MARK: - Preset Management

    public func addPreset(_ preset: ChannelStripPreset) {
        presets.append(preset)
    }

    public func removePreset(id: String) {
        presets.removeAll { $0.id == id }
    }

    public func getPreset(id: String) -> ChannelStripPreset? {
        presets.first { $0.id == id }
    }

    public func getPresetsByCategory(_ category: PresetCategory) -> [ChannelStripPreset] {
        presets.filter { $0.category == category }
    }

    public func searchPresets(_ query: String) -> [ChannelStripPreset] {
        let lowerQuery = query.lowercased()
        return presets.filter { preset in
            preset.name.lowercased().contains(lowerQuery) ||
            preset.description.lowercased().contains(lowerQuery) ||
            preset.tags.contains { $0.lowercased().contains(lowerQuery) }
        }
    }

    // MARK: - Apply Preset

    public func applyPreset(channelId: String, presetId: String) {
        guard let console = console,
              let preset = getPreset(presetId),
              let channel = console.getChannel(channelId) else {
            return
        }

        // Clear existing inserts and sends
        channel.inserts.removeAll()
        channel.sends.removeAll()

        // Apply preset configuration
        channel.inserts.append(contentsOf: preset.config.inserts)
        channel.sends.append(contentsOf: preset.config.sends)

        // Apply EQ
        if preset.config.eqEnabled {
            var eqParams: [String: Double] = [:]
            for (index, band) in preset.config.eqBands.enumerated() {
                eqParams["band_\(index)_freq"] = band.frequency
                eqParams["band_\(index)_gain"] = band.gain
                eqParams["band_\(index)_q"] = band.q
            }

            channel.inserts.append(InsertSlot(
                id: "insert-eq",
                enabled: true,
                effect: "eq",
                parameters: eqParams
            ))
        }

        // Apply compression
        if preset.config.compressionEnabled {
            channel.inserts.append(InsertSlot(
                id: "insert-compressor",
                enabled: true,
                effect: "compressor",
                parameters: [
                    "threshold": preset.config.compressionThreshold,
                    "ratio": preset.config.compressionRatio,
                    "attack": preset.config.compressionAttack,
                    "release": preset.config.compressionRelease
                ]
            ))
        }
    }

    // MARK: - Save Custom Preset

    public func savePreset(
        channelId: String,
        name: String,
        category: PresetCategory,
        description: String? = nil
    ) -> ChannelStripPreset? {
        guard let console = console,
              let channel = console.getChannel(channelId) else {
            return nil
        }

        let preset = ChannelStripPreset(
            id: "preset-custom-\(UUID().uuidString)",
            name: name,
            category: category,
            description: description ?? "Custom preset from \(channel.name)",
            config: ChannelStripConfig(
                type: channel.type,
                eqEnabled: false,
                eqBands: [],
                compressionEnabled: false,
                compressionThreshold: -20,
                compressionRatio: 2,
                compressionAttack: 10,
                compressionRelease: 100,
                inserts: channel.inserts,
                sends: channel.sends
            ),
            icon: "slider.horizontal.3",
            color: "#95A5A6",
            tags: ["custom"]
        )

        presets.append(preset)
        return preset
    }
}
