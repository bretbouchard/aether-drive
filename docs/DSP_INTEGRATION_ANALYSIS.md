# DSP Integration Analysis - iOS App

## Executive Summary

**Critical Finding**: The iOS app's mixing console has a **significant architecture gap** between the UI models and the actual JUCE DSP backend.

### Current State

**✅ What EXISTS:**
1. **JUCE Backend** - Has full internal DSP effect system:
   - `InterchangeableEffectSlot` can load internal effects via `tryLoadInternal()`
   - `UnifiedEffect` interface for all internal effects
   - Built-in effects: Airwindows algorithms, FilterGate, Compressor, etc.
   - Full plugin architecture (LOCAL_GAL, Sam, Nex, Giant, Kane Marco, etc.)

2. **Swift UI Models** - Complete mixing console interface:
   - `InsertSlot` struct with `plugin: String?` and `effect: String?` fields
   - `ChannelStrip` with `inserts: [InsertSlot]` array
   - `MixingConsole` with full channel/bus management
   - `MixingPresets` with 16 professional presets

3. **FFI Bridge** - `JUCEEngine.swift` connects to Schillinger engine:
   - Handles performance blending, transport, tempo
   - Audio engine lifecycle (start/stop)
   - Song loading/saving

**❌ What's MISSING:**

1. **No DSP Effect Loading Layer**
   - `InsertSlot.plugin` and `InsertSlot.effect` are just **string identifiers**
   - No actual plugin instance attached to `InsertSlot`
   - No way to load internal DSP effects into channel strips
   - No FFI bridge to JUCE `InterchangeableEffectSlot`

2. **No Plugin Registry**
   - No mapping of effect names to DSP implementations
   - No way to query available internal effects
   - No parameter automation for loaded effects

3. **Audio Processing Gap**
   - Mixing console UI exists but doesn't process audio
   - Presets configure InsertSlots but don't load actual DSP
   - Channel strips can't route to internal effects

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS Swift UI Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ ChannelStrip │  │ InsertSlot   │  │ MixingPreset │       │
│  │              │  │              │  │              │       │
│  │ inserts: [   │  │ plugin: String?  │ (configures │       │
│  │   InsertSlot │  │ effect: String?  │  InsertSlots)│       │
│  │ ]            │  │ parameters: [│  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ ❌ MISSING BRIDGE
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   JUCE C++ Backend Layer                     │
│  ┌──────────────────┐  ┌──────────────────────────────────┐ │
│  │ Interchangeable  │  │     UnifiedEffect Interface       │ │
│  │ EffectSlot       │  │                                  │ │
│  │                  │  │ • AirwindowsInternalProcessor     │ │
│  │ • tryLoadInternal│  │ • FilterGate                      │ │
│  │   (effectName)   │  │ • Compressor                      │ │
│  │ • loadEffect()   │  │ • MonumentReverb                  │ │
│  │ • process()      │  │ • FarFarAwayReverb                │ │
│  └──────────────────┘  │ • AetherDrive                     │ │
│                         │ • BiPhase                         │ │
│                         └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## The Problem in Detail

### Current Code Behavior

When a user applies a preset in the iOS app:

```swift
// MixingPresets.swift line 501-547
public func applyPreset(channelId: String, presetId: String) {
    guard let preset = getPreset(presetId),
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
            effect: "eq",  // ← JUST A STRING!
            parameters: eqParams
        ))
    }

    // Apply compression
    if preset.config.compressionEnabled {
        channel.inserts.append(InsertSlot(
            id: "insert-compressor",
            enabled: true,
            effect: "compressor",  // ← JUST A STRING!
            parameters: [
                "threshold": preset.config.compressionThreshold,
                "ratio": preset.config.compressionRatio,
                "attack": preset.config.compressionAttack,
                "release": preset.config.compressionRelease
            ]
        ))
    }
}
```

**What actually happens:**
1. ✅ `InsertSlot` is created with `effect: "compressor"`
2. ✅ `InsertSlot` is added to `channel.inserts` array
3. ✅ UI updates to show the compressor
4. ❌ **No actual compressor DSP is instantiated**
5. ❌ **No audio processing occurs**
6. ❌ **The "compressor" is just a string label**

### What SHOULD Happen

```swift
// Hypothetical correct implementation
public func applyPreset(channelId: String, presetId: String) {
    // ... (preset lookup code)

    // Apply compression
    if preset.config.compressionEnabled {
        // 1. Load actual DSP effect from JUCE backend
        guard let effect = PluginRegistry.loadEffect(
            name: "Compressor",
            type: .internal
        ) else {
            NSLog("Failed to load Compressor effect")
            return
        }

        // 2. Configure parameters
        effect.setParameters([
            "threshold": preset.config.compressionThreshold,
            "ratio": preset.config.compressionRatio,
            "attack": preset.config.compressionAttack,
            "release": preset.config.compressionRelease
        ])

        // 3. Attach to channel strip
        channel.inserts.append(InsertSlot(
            id: "insert-compressor",
            enabled: true,
            effect: "compressor",
            plugin: effect,  // ← ACTUAL DSP INSTANCE
            parameters: [...]
        ))

        // 4. Route audio through effect
        channel.audioChain.insertEffect(effect, at: 2)
    }
}
```

## Solution Requirements

To connect the iOS mixing console to the JUCE DSP backend, we need:

### 1. **FFI Bridge Extension** (`JUCEEngine.swift`)

Add C functions to bridge Swift to JUCE effect loading:

```swift
// C++ Side (JUCE backend)
extern "C" {
    sch_effect_handle_t sch_engine_load_effect(
        sch_engine_t* engine,
        const char* effect_name,
        sch_effect_type_t type
    );

    sch_result_t sch_effect_set_parameter(
        sch_effect_handle_t effect,
        const char* parameter_name,
        double value
    );

    sch_result_t sch_effect_process(
        sch_effect_handle_t effect,
        float* audio_buffer,
        int num_samples
    );

    sch_result_t sch_engine_destroy_effect(
        sch_effect_handle_t effect
    );
}

// Swift Side (JUCEEngine.swift)
internal func sch_engine_load_effect(
    _ engine: OpaquePointer?,
    _ effectName: UnsafePointer<CChar>,
    _ type: sch_effect_type_t
) -> OpaquePointer?

internal func sch_effect_set_parameter(
    _ effect: OpaquePointer?,
    _ parameterName: UnsafePointer<CChar>,
    _ value: Double
) -> SchResult

// etc...
```

### 2. **Plugin Registry** (New Swift file)

Create a registry to manage available DSP effects:

```swift
// PluginRegistry.swift
public class PluginRegistry {
    public static let shared = PluginRegistry()

    private var availableEffects: [String: EffectInfo] = [:]

    public struct EffectInfo {
        let name: String
        let type: EffectType
        let category: EffectCategory
        let parameters: [ParameterInfo]
    }

    public enum EffectType {
        case internal  // Built-in JUCE effects
        case external  // AUv3/VST3 plugins
        case hybrid    // Combined
    }

    public enum EffectCategory {
        case dynamics, reverb, delay, eq, distortion, modulation
    }

    public func loadEffect(name: String, type: EffectType) -> DSPEffectInstance? {
        // Call FFI to load effect from JUCE backend
        // Return wrapper instance
    }
}

public class DSPEffectInstance {
    private let handle: OpaquePointer

    public func setParameter(_ name: String, value: Double) {
        // FFI call to set parameter
    }

    public func process(_ buffer: AudioBuffer) {
        // FFI call to process audio
    }
}
```

### 3. **Updated InsertSlot Model**

Modify to hold actual DSP instance:

```swift
public class InsertSlot: Identifiable, ObservableObject {
    public let id: String
    @Published public var enabled: Bool
    @Published public var plugin: String?
    @Published public var effect: String?
    @Published public var parameters: [String: Double]

    // NEW: Actual DSP instance
    private var dspInstance: DSPEffectInstance?

    public init(
        id: String,
        enabled: Bool = true,
        plugin: String? = nil,
        effect: String? = nil,
        parameters: [String: Double] = [:]
    ) {
        self.id = id
        self.enabled = enabled
        self.plugin = plugin
        self.effect = effect
        self.parameters = parameters

        // Load DSP if effect specified
        if let effect = effect {
            loadDSP(effect: effect)
        }
    }

    private func loadDSP(effect: String) {
        self.dspInstance = PluginRegistry.shared.loadEffect(
            name: effect,
            type: .internal
        )

        // Apply parameters
        for (name, value) in parameters {
            dspInstance?.setParameter(name, value: value)
        }
    }

    func processAudio(_ buffer: AudioBuffer) {
        guard enabled, let dsp = dspInstance else { return }
        dsp.process(buffer)
    }
}
```

### 4. **Audio Chain Integration**

Connect channel strips to actual audio processing:

```swift
public class ChannelStrip: ObservableObject, Identifiable {
    // ... existing properties ...

    // NEW: Audio processing chain
    private let audioChain = AudioChain()

    public func processAudio(_ inputBuffer: AudioBuffer) -> AudioBuffer {
        guard !isMuted else { return AudioBuffer.silent() }

        var buffer = inputBuffer

        // Apply gain
        buffer.applyGain(volume)

        // Apply pan
        buffer.applyPan(pan)

        // Process inserts
        for insert in inserts where insert.enabled {
            insert.processAudio(buffer)
        }

        // Process sends
        for send in sends {
            if let bus = console.getBus(send.bus) {
                bus.processAudio(buffer, amount: send.amount)
            }
        }

        return buffer
    }
}
```

## Available Internal DSP Effects

Based on `InterchangeableEffectSlot.cpp`, these internal effects are available:

### Dynamics
- **Compressor** - Full compression with threshold, ratio, attack, release
- **Limiter** - Brickwall limiting
- **FilterGate** - Noise gate with filtering

### Reverb
- **GalacticReverb** - Algorithmic reverb
- **Monument** - Plate reverb (already in CMakeLists.txt)
- **FarFarAway** - Hall reverb (already in CMakeLists.txt)

### EQ
- **Everglade** - Parametric EQ
- **Density** - EQ/character

### Distortion
- **AetherDrive** - Overdrive (already in CMakeLists.txt)
- **Overdrive** - Classic overdrive (already in CMakeLists.txt)

### Airwindows Collection (100+ effects)
All Airwindows algorithms available via `AirwindowsInternalProcessor`

## Implementation Priority

### P0 - Critical Foundation
1. **FFI Bridge Extension** - Add effect loading C functions
2. **Plugin Registry** - Create effect registry and query system
3. **Basic DSP Loading** - Load one simple effect (Compressor)
4. **Parameter Binding** - Connect UI controls to DSP parameters

### P1 - Core Integration
1. **Audio Chain** - Implement actual audio processing through inserts
2. **Preset System** - Connect presets to real DSP instances
3. **Effect Bypass** - Enable/disable effects in real-time
4. **Metering** - Real audio level metering from DSP

### P2 - Advanced Features
1. **Plugin Scanning** - Auto-discover available effects
2. **Preset Management** - Save/load custom effect presets
3. **Automation** - Parameter automation over time
4. **External Plugins** - AUv3 plugin loading support

## Conclusion

The iOS mixing console is a **complete UI simulation** with no audio backend connection. To make it functional:

1. ✅ **Presets exist and configure InsertSlots** - Working
2. ❌ **InsertSlots load actual DSP effects** - **NOT IMPLEMENTED**
3. ❌ **Audio processes through effects** - **NOT IMPLEMENTED**

**The good news:** All the building blocks exist in the JUCE backend. We just need to build the FFI bridge to connect Swift to C++ DSP effects.

**Estimated effort:** 2-3 weeks for full P0+P1 implementation
