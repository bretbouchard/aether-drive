//
//  JUCEInstrument.swift
//  White Room Swift Frontend
//
//  Swift wrapper for JUCE InstrumentManager FFI bridge
//  Provides high-level Swift API for loading and controlling instruments
//
//  Usage:
//  ```swift
//  let instrument = JUCEInstrument(pluginId: "LOCAL_GAL")
//  try instrument.load(preset: myPreset)
//  instrument.setParameter("rubber", value: 0.5)
//  instrument.noteOn(note: 60, velocity: 0.8)
//  ```
//

import Foundation

// MARK: - FFI Declarations

/// Opaque instrument handle (pointer to C++ InstrumentInstance)
struct JUCEInstrumentHandle: Hashable {
    let rawValue: OpaquePointer
}

/// Instrument type
public enum JUCEInstrumentType: Int {
    case builtInSynth = 0    // NEX, Sam, LOCAL GAL
    case externalPlugin = 1   // VST3, AU, LV2, AAX
    case audioUnit = 2        // macOS Audio Units
}

/// Instrument information
public struct JUCEInstrumentInfo: Codable, Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public let manufacturer: String
    public let version: String
    public let type: JUCEInstrumentType
    public let isInstrument: Bool
    public let supportsMIDI: Bool
    public let maxVoices: Int
    public let numInputs: Int
    public let numOutputs: Int
}

/// Parameter information
public struct JUCEParameterInfo: Codable, Identifiable {
    public let id: String
    public let name: String
    public let minValue: Float
    public let maxValue: Float
    public let defaultValue: Float
    public let isAutomatable: Bool
    public let unit: String
}

/// Preset information
public struct JUCEPresetInfo: Codable, Identifiable {
    public let id: String
    public let name: String
    public let category: String?
    public let createdTime: Date
}

// MARK: - FFI Function Declarations

internal func sch_instrument_get_available(
    _ engine: OpaquePointer?,
    _ outInstruments: UnsafeMutablePointer<UnsafeMutablePointer<sch_instrument_info_t>?>?,
    _ outCount: UnsafeMutablePointer<size_t>?
) -> SchResult

internal func sch_instrument_get_by_category(
    _ engine: OpaquePointer?,
    _ category: UnsafePointer<CChar>,
    _ outInstruments: UnsafeMutablePointer<UnsafeMutablePointer<sch_instrument_info_t>?>?,
    _ outCount: UnsafeMutablePointer<size_t>?
) -> SchResult

internal func sch_instrument_get_info(
    _ engine: OpaquePointer?,
    _ identifier: UnsafePointer<CChar>,
    _ outInfo: UnsafeMutablePointer<sch_instrument_info_t>?
) -> SchResult

internal func sch_instrument_load(
    _ engine: OpaquePointer?,
    _ identifier: UnsafePointer<CChar>,
    _ presetJson: UnsafePointer<CChar>?,
    _ outInstrument: UnsafeMutablePointer<OpaquePointer?>?
) -> SchResult

internal func sch_instrument_destroy(
    _ instrument: OpaquePointer?
) -> SchResult

internal func sch_instrument_is_available(
    _ engine: OpaquePointer?,
    _ identifier: UnsafePointer<CChar>,
    _ outAvailable: UnsafeMutablePointer<Bool>?
) -> SchResult

internal func sch_instrument_get_parameter_count(
    _ instrument: OpaquePointer?,
    _ outCount: UnsafeMutablePointer<Int>?
) -> SchResult

internal func sch_instrument_get_parameter_info(
    _ instrument: OpaquePointer?,
    _ index: Int,
    _ outInfo: UnsafeMutablePointer<sch_parameter_info_t>?
) -> SchResult

internal func sch_instrument_get_parameter_value(
    _ instrument: OpaquePointer?,
    _ address: UnsafePointer<CChar>,
    _ outValue: UnsafeMutablePointer<Float>?
) -> SchResult

internal func sch_instrument_set_parameter_value(
    _ instrument: OpaquePointer?,
    _ address: UnsafePointer<CChar>,
    _ value: Float
) -> SchResult

internal func sch_instrument_set_parameter_smooth(
    _ instrument: OpaquePointer?,
    _ address: UnsafePointer<CChar>,
    _ value: Float,
    _ timeMs: Double
) -> SchResult

internal func sch_instrument_note_on(
    _ instrument: OpaquePointer?,
    _ midiNote: Int,
    _ velocity: Float,
    _ channel: Int
) -> SchResult

internal func sch_instrument_note_off(
    _ instrument: OpaquePointer?,
    _ midiNote: Int,
    _ velocity: Float,
    _ channel: Int
) -> SchResult

internal func sch_instrument_all_notes_off(
    _ instrument: OpaquePointer?,
    _ channel: Int
) -> SchResult

internal func sch_instrument_pitch_bend(
    _ instrument: OpaquePointer?,
    _ value: Float,
    _ channel: Int
) -> SchResult

internal func sch_instrument_control_change(
    _ instrument: OpaquePointer?,
    _ controller: Int,
    _ value: Float,
    _ channel: Int
) -> SchResult

internal func sch_instrument_get_presets(
    _ engine: OpaquePointer?,
    _ identifier: UnsafePointer<CChar>,
    _ outPresets: UnsafeMutablePointer<UnsafeMutablePointer<sch_preset_info_t>?>?,
    _ outCount: UnsafeMutablePointer<size_t>?
) -> SchResult

internal func sch_instrument_load_preset(
    _ instrument: OpaquePointer?,
    _ presetName: UnsafePointer<CChar>
) -> SchResult

internal func sch_instrument_save_preset(
    _ instrument: OpaquePointer?,
    _ presetName: UnsafePointer<CChar>,
    _ category: UnsafePointer<CChar>?
) -> SchResult

internal func sch_free_instrument_array(
    _ instruments: UnsafeMutablePointer<sch_instrument_info_t>?,
    _ count: size_t
)

internal func sch_free_instrument_info(
    _ info: UnsafeMutablePointer<sch_instrument_info_t>?
)

internal func sch_free_preset_array(
    _ presets: UnsafeMutablePointer<sch_preset_info_t>?,
    _ count: size_t
)

// MARK: - C Struct Definitions

struct sch_instrument_info_t {
    var identifier: UnsafeMutablePointer<CChar>?
    var name: UnsafeMutablePointer<CChar>?
    var category: UnsafeMutablePointer<CChar>?
    var manufacturer: UnsafeMutablePointer<CChar>?
    var version: UnsafeMutablePointer<CChar>?
    var type: sch_instrument_type_t
    var is_instrument: Bool
    var supports_midi: Bool
    var max_voices: Int32
    var num_inputs: Int32
    var num_outputs: Int32
}

enum sch_instrument_type_t: Int32 {
    case builtin_synth = 0
    case external_plugin = 1
    case audio_unit = 2
}

struct sch_parameter_info_t {
    var address: UnsafeMutablePointer<CChar>?
    var name: UnsafeMutablePointer<CChar>?
    var min_value: Float
    var max_value: Float
    var default_value: Float
    var is_automatable: Bool
    var unit: UnsafeMutablePointer<CChar>?
}

struct sch_preset_info_t {
    var name: UnsafeMutablePointer<CChar>?
    var category: UnsafeMutablePointer<CChar>?
    var created_time: Int64
}

// MARK: - JUCEInstrument Class

/// High-level Swift wrapper for JUCE instruments
public class JUCEInstrument {

    // MARK: - Properties

    private let handle: OpaquePointer
    private let engine: OpaquePointer
    public let pluginId: String

    // MARK: - Initialization

    /// Load an instrument by plugin ID
    /// - Parameters:
    ///   - pluginId: Instrument identifier (e.g., "LOCAL_GAL", "Sam", "Nex")
    ///   - preset: Optional preset JSON to load
    /// - Throws: JUCEInstrumentError if loading fails
    public init(pluginId: String, preset: String? = nil) throws {
        guard let engine = JUCEEngine.shared.engineHandle else {
            throw JUCEInstrumentError.engineNotInitialized
        }

        self.engine = engine
        self.pluginId = pluginId

        var instrumentHandle: OpaquePointer?
        let result = pluginId.withCString { pluginIdPtr in
            if let preset = preset {
                return preset.withCString { presetPtr in
                    sch_instrument_load(
                        engine,
                        pluginIdPtr,
                        presetPtr,
                        &instrumentHandle
                    )
                }
            } else {
                return sch_instrument_load(
                    engine,
                    pluginIdPtr,
                    nil,
                    &instrumentHandle
                )
            }
        }

        guard result == .ok, let handle = instrumentHandle else {
            throw JUCEInstrumentError.loadFailed(pluginId: pluginId, code: result)
        }

        self.handle = handle
    }

    deinit {
        sch_instrument_destroy(handle)
    }

    // MARK: - Parameter Control

    /// Set parameter value
    /// - Parameters:
    ///   - address: Parameter address (e.g., "rubber", "bite", "hollow")
    ///   - value: Parameter value
    public func setParameter(_ address: String, value: Float) {
        address.withCString { addressPtr in
            sch_instrument_set_parameter_value(handle, addressPtr, value)
        }
    }

    /// Get parameter value
    /// - Parameter address: Parameter address
    /// - Returns: Current parameter value
    public func getParameter(_ address: String) -> Float? {
        var value: Float = 0.0
        let result = address.withCString { addressPtr in
            sch_instrument_get_parameter_value(handle, addressPtr, &value)
        }

        return result == .ok ? value : nil
    }

    /// Set parameter with smooth transition
    /// - Parameters:
    ///   - address: Parameter address
    ///   - value: Target parameter value
    ///   - timeMs: Transition time in milliseconds
    public func setParameter(_ address: String, value: Float, timeMs: Double) {
        address.withCString { addressPtr in
            sch_instrument_set_parameter_smooth(handle, addressPtr, value, timeMs)
        }
    }

    // MARK: - MIDI Control

    /// Send note-on event
    /// - Parameters:
    ///   - note: MIDI note number (0-127)
    ///   - velocity: Velocity (0.0-1.0)
    ///   - channel: MIDI channel (0-15)
    public func noteOn(note: Int, velocity: Float, channel: Int = 0) {
        sch_instrument_note_on(handle, note, velocity, channel)
    }

    /// Send note-off event
    /// - Parameters:
    ///   - note: MIDI note number (0-127)
    ///   - velocity: Release velocity (0.0-1.0)
    ///   - channel: MIDI channel (0-15)
    public func noteOff(note: Int, velocity: Float = 0.0, channel: Int = 0) {
        sch_instrument_note_off(handle, note, velocity, channel)
    }

    /// Send all-notes-off (panic)
    /// - Parameter channel: MIDI channel (-1 for all channels)
    public func allNotesOff(channel: Int = -1) {
        sch_instrument_all_notes_off(handle, channel)
    }

    /// Send pitch bend
    /// - Parameters:
    ///   - value: Pitch bend value (-1.0 to +1.0)
    ///   - channel: MIDI channel (0-15)
    public func pitchBend(value: Float, channel: Int = 0) {
        sch_instrument_pitch_bend(handle, value, channel)
    }

    /// Send MIDI control change
    /// - Parameters:
    ///   - controller: Controller number (0-127)
    ///   - value: Controller value (0.0-1.0)
    ///   - channel: MIDI channel (0-15)
    public func controlChange(controller: Int, value: Float, channel: Int = 0) {
        sch_instrument_control_change(handle, controller, value, channel)
    }

    // MARK: - Preset Management

    /// Load preset by name
    /// - Parameter presetName: Preset name
    /// - Throws: JUCEInstrumentError if loading fails
    public func loadPreset(_ presetName: String) throws {
        let result = presetName.withCString { presetPtr in
            sch_instrument_load_preset(handle, presetPtr)
        }

        guard result == .ok else {
            throw JUCEInstrumentError.presetLoadFailed(name: presetName, code: result)
        }
    }

    /// Save current state as preset
    /// - Parameters:
    ///   - presetName: Preset name
    ///   - category: Preset category (optional)
    /// - Throws: JUCEInstrumentError if saving fails
    public func savePreset(_ presetName: String, category: String? = nil) throws {
        let result = presetName.withCString { presetPtr in
            if let category = category {
                return category.withCString { categoryPtr in
                    sch_instrument_save_preset(handle, presetPtr, categoryPtr)
                }
            } else {
                return sch_instrument_save_preset(handle, presetPtr, nil)
            }
        }

        guard result == .ok else {
            throw JUCEInstrumentError.presetSaveFailed(name: presetName, code: result)
        }
    }
}

// MARK: - JUCEInstrument Registry

public class JUCEInstrumentRegistry {

    public static let shared = JUCEInstrumentRegistry()

    private init() {}

    /// Get all available instruments
    /// - Returns: Array of instrument information
    /// - Throws: JUCEInstrumentError if query fails
    public func getAvailableInstruments() throws -> [JUCEInstrumentInfo] {
        guard let engine = JUCEEngine.shared.engineHandle else {
            throw JUCEInstrumentError.engineNotInitialized
        }

        var instrumentsPtr: UnsafeMutablePointer<sch_instrument_info_t>?
        var count: size_t = 0

        let result = sch_instrument_get_available(engine, &instrumentsPtr, &count)

        guard result == .ok else {
            throw JUCEInstrumentError.queryFailed(code: result)
        }

        defer {
            sch_free_instrument_array(instrumentsPtr, count)
        }

        var instruments: [JUCEInstrumentInfo] = []
        for i in 0..<count {
            let info = instrumentsPtr!.advanced(by: Int(i)).pointee
            let instrumentInfo = JUCEInstrumentInfo(
                id: String(cString: info.identifier),
                name: String(cString: info.name),
                category: String(cString: info.category),
                manufacturer: String(cString: info.manufacturer),
                version: String(cString: info.version),
                type: JUCEInstrumentType(rawValue: Int(info.type.rawValue)) ?? .builtInSynth,
                isInstrument: info.is_instrument,
                supportsMIDI: info.supports_midi,
                maxVoices: Int(info.max_voices),
                numInputs: Int(info.num_inputs),
                numOutputs: Int(info.num_outputs)
            )
            instruments.append(instrumentInfo)
        }

        return instruments
    }

    /// Get instruments by category
    /// - Parameter category: Category filter
    /// - Returns: Array of instrument information
    /// - Throws: JUCEInstrumentError if query fails
    public func getInstrumentsByCategory(_ category: String) throws -> [JUCEInstrumentInfo] {
        guard let engine = JUCEEngine.shared.engineHandle else {
            throw JUCEInstrumentError.engineNotInitialized
        }

        var instrumentsPtr: UnsafeMutablePointer<sch_instrument_info_t>?
        var count: size_t = 0

        let result = category.withCString { categoryPtr in
            sch_instrument_get_by_category(engine, categoryPtr, &instrumentsPtr, &count)
        }

        guard result == .ok else {
            throw JUCEInstrumentError.queryFailed(code: result)
        }

        defer {
            sch_free_instrument_array(instrumentsPtr, count)
        }

        var instruments: [JUCEInstrumentInfo] = []
        for i in 0..<count {
            let info = instrumentsPtr!.advanced(by: Int(i)).pointee
            let instrumentInfo = JUCEInstrumentInfo(
                id: String(cString: info.identifier),
                name: String(cString: info.name),
                category: String(cString: info.category),
                manufacturer: String(cString: info.manufacturer),
                version: String(cString: info.version),
                type: JUCEInstrumentType(rawValue: Int(info.type.rawValue)) ?? .builtInSynth,
                isInstrument: info.is_instrument,
                supportsMIDI: info.supports_midi,
                maxVoices: Int(info.max_voices),
                numInputs: Int(info.num_inputs),
                numOutputs: Int(info.num_outputs)
            )
            instruments.append(instrumentInfo)
        }

        return instruments
    }

    /// Check if instrument is available
    /// - Parameter identifier: Instrument identifier
    /// - Returns: True if available
    public func isInstrumentAvailable(_ identifier: String) -> Bool {
        guard let engine = JUCEEngine.shared.engineHandle else {
            return false
        }

        var available: Bool = false
        let result = identifier.withCString { identifierPtr in
            sch_instrument_is_available(engine, identifierPtr, &available)
        }

        return result == .ok && available
    }
}

// MARK: - Errors

/// Instrument errors
public enum JUCEInstrumentError: Error, LocalizedError {
    case engineNotInitialized
    case loadFailed(pluginId: String, code: SchResult)
    case queryFailed(code: SchResult)
    case presetLoadFailed(name: String, code: SchResult)
    case presetSaveFailed(name: String, code: SchResult)
    case parameterNotFound(address: String)

    public var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "JUCE engine is not initialized"
        case .loadFailed(let pluginId, let code):
            return "Failed to load instrument \(pluginId): \(code)"
        case .queryFailed(let code):
            return "Failed to query instruments: \(code)"
        case .presetLoadFailed(let name, let code):
            return "Failed to load preset \(name): \(code)"
        case .presetSaveFailed(let name, let code):
            return "Failed to save preset \(name): \(code)"
        case .parameterNotFound(let address):
            return "Parameter not found: \(address)"
        }
    }
}
