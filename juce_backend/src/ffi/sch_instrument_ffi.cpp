//
//  sch_instrument_ffi.cpp
//  White Room JUCE Instrument FFI Bridge
//
//  C++ implementation of FFI bridge for Swift ↔ JUCE InstrumentManager
//  Implements functions declared in sch_instrument_ffi.h
//
//  Design Principles:
//  - All functions are extern "C" (C ABI compatibility)
//  - Error handling: C++ exceptions caught and translated to sch_result_t
//  - Memory management: Output strings allocated with malloc (caller frees)
//  - Thread safety: InstrumentManager handles internal locking
//

// JUCE module includes
#include <juce_core/juce_core.h>
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_devices/juce_audio_devices.h>

// FFI includes
#include "sch_instrument_ffi.h"
#include "sch_engine_ffi.h"

// InstrumentManager includes
#include "../../engine/instruments/InstrumentManager.h"

// Standard library
#include <cstring>
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <vector>
#include <mutex>

// ============================================================================
// Internal Types and Helpers
// ============================================================================

namespace schillinger {
namespace ffi {

// Convert juce::String to C string (caller must free)
static char* juceStringToAllocatedCString(const juce::String& str) {
    if (str.isEmpty()) {
        return nullptr;
    }

    size_t len = str.getNumBytesAsUTF8() + 1; // +1 for null terminator
    char* cstr = static_cast<char*>(std::malloc(len));
    if (cstr) {
        std::memcpy(cstr, str.toUTF8().getAddress(), len);
    }
    return cstr;
}

// Convert SchillingerEcosystem::Instrument::InstrumentType to FFI enum
static sch_instrument_type_t convertInstrumentType(
    SchillingerEcosystem::Instrument::InstrumentType type
) {
    switch (type) {
        case SchillingerEcosystem::Instrument::InstrumentType::BuiltInSynthesizer:
            return SCH_INSTRUMENT_TYPE_BUILTIN_SYNTH;
        case SchillingerEcosystem::Instrument::InstrumentType::ExternalPlugin:
            return SCH_INSTRUMENT_TYPE_EXTERNAL_PLUGIN;
        case SchillingerEcosystem::Instrument::InstrumentType::AudioUnit:
            return SCH_INSTRUMENT_TYPE_AUDIO_UNIT;
        default:
            return SCH_INSTRUMENT_TYPE_BUILTIN_SYNTH;
    }
}

// Convert InstrumentInfo to FFI struct
static sch_result_t convertInstrumentInfo(
    const SchillingerEcosystem::Instrument::InstrumentInfo& info,
    sch_instrument_info_t* out_info
) {
    if (!out_info) {
        return SCH_ERR_INVALID_ARG;
    }

    out_info->identifier = juceStringToAllocatedCString(info.identifier);
    out_info->name = juceStringToAllocatedCString(info.name);
    out_info->category = juceStringToAllocatedCString(info.category);
    out_info->manufacturer = juceStringToAllocatedCString(info.manufacturer);
    out_info->version = juceStringToAllocatedCString(info.version);
    out_info->type = convertInstrumentType(info.type);
    out_info->is_instrument = info.isInstrument;
    out_info->supports_midi = info.supportsMIDI;
    out_info->max_voices = info.maxVoices;
    out_info->num_inputs = info.numInputs;
    out_info->num_outputs = info.numOutputs;

    return SCH_OK;
}

// Get InstrumentManager from engine handle
static SchillingerEcosystem::Instrument::InstrumentManager* getInstrumentManager(
    sch_engine_handle engine
) {
    // For now, we'll use a global instance
    // TODO: Store InstrumentManager pointer in EngineState
    static SchillingerEcosystem::Instrument::InstrumentManager* globalManager = nullptr;
    static std::once_flag initFlag;

    std::call_once(initFlag, [] {
        globalManager = new SchillingerEcosystem::Instrument::InstrumentManager();
    });

    return globalManager;
}

// Get InstrumentInstance from handle
static SchillingerEcosystem::Instrument::InstrumentInstance* getInstrumentInstance(
    sch_instrument_handle instrument
) {
    if (!instrument) {
        return nullptr;
    }
    return reinterpret_cast<SchillingerEcosystem::Instrument::InstrumentInstance*>(instrument);
}

} // namespace ffi
} // namespace schillinger

// ============================================================================
// INSTRUMENT DISCOVERY
// ============================================================================

extern "C" {

sch_result_t sch_instrument_get_available(
    sch_engine_handle engine,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
) {
    using namespace SchillingerEcosystem::Instrument;
    using namespace schillinger::ffi;

    if (!out_instruments || !out_count) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        std::vector<InstrumentInfo> instruments = manager->getAvailableInstruments();

        // Allocate output array
        *out_instruments = static_cast<sch_instrument_info_t*>(
            std::malloc(sizeof(sch_instrument_info_t) * instruments.size())
        );

        if (!*out_instruments) {
            return SCH_ERR_OUT_OF_MEMORY;
        }

        // Convert each instrument info
        for (size_t i = 0; i < instruments.size(); ++i) {
            sch_result_t result = convertInstrumentInfo(
                instruments[i],
                &(*out_instruments)[i]
            );

            if (result != SCH_OK) {
                // Cleanup on failure
                for (size_t j = 0; j < i; ++j) {
                    sch_free_instrument_info(&(*out_instruments)[j]);
                }
                std::free(*out_instruments);
                *out_instruments = nullptr;
                return result;
            }
        }

        *out_count = instruments.size();
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_available: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_get_by_category(
    sch_engine_handle engine,
    const char* category,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
) {
    using namespace SchillingerEcosystem::Instrument;
    using namespace schillinger::ffi;

    if (!category || !out_instruments || !out_count) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        std::vector<InstrumentInfo> instruments = manager->getInstrumentsByCategory(category);

        // Allocate and convert (same as get_available)
        *out_instruments = static_cast<sch_instrument_info_t*>(
            std::malloc(sizeof(sch_instrument_info_t) * instruments.size())
        );

        if (!*out_instruments) {
            return SCH_ERR_OUT_OF_MEMORY;
        }

        for (size_t i = 0; i < instruments.size(); ++i) {
            sch_result_t result = convertInstrumentInfo(
                instruments[i],
                &(*out_instruments)[i]
            );

            if (result != SCH_OK) {
                for (size_t j = 0; j < i; ++j) {
                    sch_free_instrument_info(&(*out_instruments)[j]);
                }
                std::free(*out_instruments);
                *out_instruments = nullptr;
                return result;
            }
        }

        *out_count = instruments.size();
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_by_category: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_get_info(
    sch_engine_handle engine,
    const char* identifier,
    sch_instrument_info_t* out_info
) {
    using namespace SchillingerEcosystem::Instrument;
    using namespace schillinger::ffi;

    if (!identifier || !out_info) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        std::shared_ptr<InstrumentInfo> info = manager->getInstrumentInfo(identifier);
        if (!info) {
            return SCH_ERR_NOT_FOUND;
        }

        return convertInstrumentInfo(*info, out_info);

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_info: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_search(
    sch_engine_handle engine,
    const char* query,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
) {
    using namespace SchillingerEcosystem::Instrument;
    using namespace schillinger::ffi;

    if (!query || !out_instruments || !out_count) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        std::vector<InstrumentInfo> instruments = manager->searchInstruments(query);

        *out_instruments = static_cast<sch_instrument_info_t*>(
            std::malloc(sizeof(sch_instrument_info_t) * instruments.size())
        );

        if (!*out_instruments) {
            return SCH_ERR_OUT_OF_MEMORY;
        }

        for (size_t i = 0; i < instruments.size(); ++i) {
            sch_result_t result = convertInstrumentInfo(
                instruments[i],
                &(*out_instruments)[i]
            );

            if (result != SCH_OK) {
                for (size_t j = 0; j < i; ++j) {
                    sch_free_instrument_info(&(*out_instruments)[j]);
                }
                std::free(*out_instruments);
                *out_instruments = nullptr;
                return result;
            }
        }

        *out_count = instruments.size();
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_search: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// INSTRUMENT LOADING
// ============================================================================

sch_result_t sch_instrument_load(
    sch_engine_handle engine,
    const char* identifier,
    const char* preset_json,
    sch_instrument_handle* out_instrument
) {
    using namespace SchillingerEcosystem::Instrument;
    using namespace schillinger::ffi;

    if (!identifier || !out_instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        // Create instrument instance
        std::unique_ptr<InstrumentInstance> instance = manager->createInstance(identifier);
        if (!instance) {
            return SCH_ERR_NOT_FOUND;
        }

        // Load preset if provided
        if (preset_json && std::strlen(preset_json) > 0) {
            // TODO: Implement preset loading from JSON
            DBG("TODO: Load preset from JSON: " << preset_json);
        }

        // Transfer ownership to caller
        *out_instrument = reinterpret_cast<sch_instrument_handle>(instance.release());
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_load: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_destroy(
    sch_instrument_handle instrument
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        delete instance;
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_destroy: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_is_available(
    sch_engine_handle engine,
    const char* identifier,
    bool* out_available
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!identifier || !out_available) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentManager* manager = getInstrumentManager(engine);
        if (!manager) {
            return SCH_ERR_ENGINE_NULL;
        }

        *out_available = manager->isInstrumentAvailable(identifier);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_is_available: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// PARAMETER CONTROL
// ============================================================================

sch_result_t sch_instrument_get_parameter_count(
    sch_instrument_handle instrument,
    int* out_count
) {
    if (!instrument || !out_count) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement parameter count
        *out_count = 0;
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_parameter_count: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_get_parameter_info(
    sch_instrument_handle instrument,
    int index,
    sch_parameter_info_t* out_info
) {
    if (!instrument || !out_info) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement parameter info
        return SCH_ERR_NOT_IMPLEMENTED;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_parameter_info: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_get_parameter_value(
    sch_instrument_handle instrument,
    const char* address,
    float* out_value
) {
    if (!instrument || !address || !out_value) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement parameter get
        return SCH_ERR_NOT_IMPLEMENTED;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_parameter_value: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_set_parameter_value(
    sch_instrument_handle instrument,
    const char* address,
    float value
) {
    if (!instrument || !address) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement parameter set
        DBG("TODO: Set parameter " << address << " = " << value);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_set_parameter_value: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_set_parameter_smooth(
    sch_instrument_handle instrument,
    const char* address,
    float value,
    double time_ms
) {
    if (!instrument || !address) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement smooth parameter transition
        DBG("TODO: Set parameter " << address << " = " << value << " over " << time_ms << "ms");
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_set_parameter_smooth: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// MIDI CONTROL
// ============================================================================

sch_result_t sch_instrument_note_on(
    sch_instrument_handle instrument,
    int midi_note,
    float velocity,
    int channel
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        if (!instance) {
            return SCH_ERR_ENGINE_NULL;
        }

        // TODO: Implement note-on via InstrumentInstance
        DBG("TODO: Note on: channel=" << channel << " note=" << midi_note << " velocity=" << velocity);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_note_on: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_note_off(
    sch_instrument_handle instrument,
    int midi_note,
    float velocity,
    int channel
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        if (!instance) {
            return SCH_ERR_ENGINE_NULL;
        }

        // TODO: Implement note-off via InstrumentInstance
        DBG("TODO: Note off: channel=" << channel << " note=" << midi_note);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_note_off: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_all_notes_off(
    sch_instrument_handle instrument,
    int channel
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        if (!instance) {
            return SCH_ERR_ENGINE_NULL;
        }

        // TODO: Implement all-notes-off via InstrumentInstance
        DBG("TODO: All notes off: channel=" << channel);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_all_notes_off: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_pitch_bend(
    sch_instrument_handle instrument,
    float value,
    int channel
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        if (!instance) {
            return SCH_ERR_ENGINE_NULL;
        }

        // TODO: Implement pitch bend via InstrumentInstance
        DBG("TODO: Pitch bend: channel=" << channel << " value=" << value);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_pitch_bend: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_control_change(
    sch_instrument_handle instrument,
    int controller,
    float value,
    int channel
) {
    using namespace SchillingerEcosystem::Instrument;

    if (!instrument) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        InstrumentInstance* instance = getInstrumentInstance(instrument);
        if (!instance) {
            return SCH_ERR_ENGINE_NULL;
        }

        // TODO: Implement control change via InstrumentInstance
        DBG("TODO: Control change: channel=" << channel << " controller=" << controller << " value=" << value);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_control_change: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// PRESET MANAGEMENT
// ============================================================================

sch_result_t sch_instrument_get_presets(
    sch_engine_handle engine,
    const char* identifier,
    sch_preset_info_t** out_presets,
    size_t* out_count
) {
    if (!identifier || !out_presets || !out_count) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement preset enumeration
        *out_presets = nullptr;
        *out_count = 0;
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_presets: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_load_preset(
    sch_instrument_handle instrument,
    const char* preset_name
) {
    if (!instrument || !preset_name) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement preset loading
        DBG("TODO: Load preset: " << preset_name);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_load_preset: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_save_preset(
    sch_instrument_handle instrument,
    const char* preset_name,
    const char* category
) {
    if (!instrument || !preset_name) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement preset saving
        DBG("TODO: Save preset: " << preset_name);
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_save_preset: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// AUDIO PROCESSING
// ============================================================================

sch_result_t sch_instrument_process(
    sch_instrument_handle instrument,
    float* audio_buffer,
    int num_samples,
    const uint8_t* midi_data,
    int midi_size
) {
    if (!instrument || !audio_buffer) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement audio processing
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_process: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_get_audio(
    sch_instrument_handle instrument,
    float* audio_buffer,
    int num_samples,
    int* out_samples
) {
    if (!instrument || !audio_buffer || !out_samples) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement audio retrieval
        *out_samples = 0;
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_audio: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

sch_result_t sch_instrument_get_state(
    sch_instrument_handle instrument,
    char** out_json
) {
    if (!instrument || !out_json) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement state serialization
        *out_json = nullptr;
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_get_state: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

sch_result_t sch_instrument_set_state(
    sch_instrument_handle instrument,
    const char* json
) {
    if (!instrument || !json) {
        return SCH_ERR_INVALID_ARG;
    }

    try {
        // TODO: Implement state deserialization
        return SCH_OK;

    } catch (const std::exception& e) {
        DBG("FFI Exception in sch_instrument_set_state: " << e.what());
        return SCH_ERR_INTERNAL;
    }
}

// ============================================================================
// MEMORY MANAGEMENT HELPERS
// ============================================================================

void sch_free_instrument_array(
    sch_instrument_info_t* instruments,
    size_t count
) {
    if (!instruments) {
        return;
    }

    for (size_t i = 0; i < count; ++i) {
        sch_free_instrument_info(&instruments[i]);
    }

    std::free(instruments);
}

void sch_free_instrument_info(
    sch_instrument_info_t* info
) {
    if (!info) {
        return;
    }

    if (info->identifier) std::free(info->identifier);
    if (info->name) std::free(info->name);
    if (info->category) std::free(info->category);
    if (info->manufacturer) std::free(info->manufacturer);
    if (info->version) std::free(info->version);
}

void sch_free_parameter_info(
    sch_parameter_info_t* info
) {
    if (!info) {
        return;
    }

    if (info->address) std::free(info->address);
    if (info->name) std::free(info->name);
    if (info->unit) std::free(info->unit);
}

void sch_free_preset_array(
    sch_preset_info_t* presets,
    size_t count
) {
    if (!presets) {
        return;
    }

    for (size_t i = 0; i < count; ++i) {
        if (presets[i].name) std::free(presets[i].name);
        if (presets[i].category) std::free(presets[i].category);
    }

    std::free(presets);
}

} // extern "C"
