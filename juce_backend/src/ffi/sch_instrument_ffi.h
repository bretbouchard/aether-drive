//
//  sch_instrument_ffi.h
//  White Room JUCE Instrument FFI Bridge
//
//  C ABI interface for Swift ↔ JUCE InstrumentManager communication
//  Enables loading and controlling instruments from Swift frontend
//
//  Memory Management Rules:
//  - Input strings: Borrowed (caller retains ownership)
//  - Output strings: Allocated with malloc (caller must free with sch_free_string)
//  - Instrument handles: Opaque pointers, must be destroyed with sch_instrument_destroy
//
//  Thread Safety:
//  - All functions are thread-safe (use internal locking in InstrumentManager)
//  - Audio processing happens on audio thread
//  - Control functions can be called from any thread
//

#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// TYPES
// ============================================================================

// Forward declaration from sch_engine_ffi.h
typedef struct sch_engine_t sch_engine_t;
typedef sch_engine_t* sch_engine_handle;

// Opaque instrument handle (pointer to internal C++ InstrumentInstance)
typedef struct sch_instrument_t sch_instrument_t;
typedef sch_instrument_t* sch_instrument_handle;

// Instrument type
typedef enum {
    SCH_INSTRUMENT_TYPE_BUILTIN_SYNTH = 0,  // NEX, Sam, LOCAL GAL
    SCH_INSTRUMENT_TYPE_EXTERNAL_PLUGIN = 1, // VST3, AU, LV2, AAX
    SCH_INSTRUMENT_TYPE_AUDIO_UNIT = 2      // macOS Audio Units
} sch_instrument_type_t;

// Instrument info
typedef struct {
    char* identifier;        // Unique identifier (caller must free)
    char* name;             // Display name (caller must free)
    char* category;         // Category (Synth, Sampler, etc.) (caller must free)
    char* manufacturer;     // Manufacturer/Developer (caller must free)
    char* version;          // Version string (caller must free)
    sch_instrument_type_t type;
    bool is_instrument;     // true = instrument, false = effect
    bool supports_midi;     // Accepts MIDI input
    int max_voices;         // Maximum polyphony (0 = unlimited)
    int num_inputs;         // Audio input channels
    int num_outputs;        // Audio output channels
} sch_instrument_info_t;

// Plugin parameter info
typedef struct {
    char* address;          // Parameter address (caller must free)
    char* name;             // Display name (caller must free)
    float min_value;        // Minimum value
    float max_value;        // Maximum value
    float default_value;    // Default value
    bool is_automatable;    // Can be automated
    char* unit;             // Unit (Hz, %, etc.) (caller must free)
} sch_parameter_info_t;

// Preset info
typedef struct {
    char* name;             // Preset name (caller must free)
    char* category;         // Preset category (caller must free)
    int64_t created_time;   // Creation timestamp (Unix epoch)
} sch_preset_info_t;

// ============================================================================
// INSTRUMENT DISCOVERY
// ============================================================================

/**
 * Get all available instruments
 *
 * @param engine Engine handle
 * @param out_instruments Pointer to receive array of instrument info (caller must free with sch_free_instrument_array)
 * @param out_count Pointer to receive number of instruments
 * @return SCH_OK on success, error code on failure
 */
sch_result_t sch_instrument_get_available(
    sch_engine_handle engine,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
);

/**
 * Get instruments by category
 *
 * @param engine Engine handle
 * @param category Category filter ("Synth", "Sampler", "Effect", etc.)
 * @param out_instruments Pointer to receive array of instrument info (caller must free)
 * @param out_count Pointer to receive number of instruments
 * @return SCH_OK on success, error code on failure
 */
sch_result_t sch_instrument_get_by_category(
    sch_engine_handle engine,
    const char* category,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
);

/**
 * Get instrument info by identifier
 *
 * @param engine Engine handle
 * @param identifier Instrument identifier
 * @param out_info Pointer to receive instrument info (caller must free with sch_free_instrument_info)
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if instrument doesn't exist
 */
sch_result_t sch_instrument_get_info(
    sch_engine_handle engine,
    const char* identifier,
    sch_instrument_info_t* out_info
);

/**
 * Search instruments by name/description
 *
 * @param engine Engine handle
 * @param query Search query
 * @param out_instruments Pointer to receive array of instrument info (caller must free)
 * @param out_count Pointer to receive number of instruments
 * @return SCH_OK on success, error code on failure
 */
sch_result_t sch_instrument_search(
    sch_engine_handle engine,
    const char* query,
    sch_instrument_info_t** out_instruments,
    size_t* out_count
);

// ============================================================================
// INSTRUMENT LOADING
// ============================================================================

/**
 * Load an instrument by identifier
 *
 * Creates a new instrument instance. The instance must be destroyed with
 * sch_instrument_destroy when no longer needed.
 *
 * @param engine Engine handle
 * @param identifier Instrument identifier (e.g., "LOCAL_GAL", "Sam", "Nex")
 * @param preset_json Optional preset JSON to load (can be NULL)
 * @param out_instrument Pointer to receive instrument handle
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if instrument doesn't exist
 */
sch_result_t sch_instrument_load(
    sch_engine_handle engine,
    const char* identifier,
    const char* preset_json,
    sch_instrument_handle* out_instrument
);

/**
 * Destroy an instrument instance
 *
 * @param instrument Instrument handle to destroy
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_destroy(
    sch_instrument_handle instrument
);

/**
 * Check if instrument is loaded and available
 *
 * @param engine Engine handle
 * @param identifier Instrument identifier
 * @param out_available Pointer to receive availability
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_is_available(
    sch_engine_handle engine,
    const char* identifier,
    bool* out_available
);

// ============================================================================
// PARAMETER CONTROL
// ============================================================================

/**
 * Get parameter count
 *
 * @param instrument Instrument handle
 * @param out_count Pointer to receive parameter count
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_get_parameter_count(
    sch_instrument_handle instrument,
    int* out_count
);

/**
 * Get parameter info
 *
 * @param instrument Instrument handle
 * @param index Parameter index (0 to parameter_count - 1)
 * @param out_info Pointer to receive parameter info (caller must free with sch_free_parameter_info)
 * @return SCH_OK on success, SCH_ERR_INVALID_ARG if index out of range
 */
sch_result_t sch_instrument_get_parameter_info(
    sch_instrument_handle instrument,
    int index,
    sch_parameter_info_t* out_info
);

/**
 * Get parameter value by address
 *
 * @param instrument Instrument handle
 * @param address Parameter address (e.g., "rubber", "bite", "hollow")
 * @param out_value Pointer to receive parameter value
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if parameter doesn't exist
 */
sch_result_t sch_instrument_get_parameter_value(
    sch_instrument_handle instrument,
    const char* address,
    float* out_value
);

/**
 * Set parameter value by address
 *
 * @param instrument Instrument handle
 * @param address Parameter address
 * @param value Parameter value
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if parameter doesn't exist
 */
sch_result_t sch_instrument_set_parameter_value(
    sch_instrument_handle instrument,
    const char* address,
    float value
);

/**
 * Set parameter value with smooth transition
 *
 * @param instrument Instrument handle
 * @param address Parameter address
 * @param value Target parameter value
 * @param time_ms Transition time in milliseconds
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if parameter doesn't exist
 */
sch_result_t sch_instrument_set_parameter_smooth(
    sch_instrument_handle instrument,
    const char* address,
    float value,
    double time_ms
);

// ============================================================================
// MIDI CONTROL
// ============================================================================

/**
 * Send note-on event
 *
 * @param instrument Instrument handle
 * @param midi_note MIDI note number (0-127)
 * @param velocity Velocity (0.0-1.0)
 * @param channel MIDI channel (0-15)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_note_on(
    sch_instrument_handle instrument,
    int midi_note,
    float velocity,
    int channel
);

/**
 * Send note-off event
 *
 * @param instrument Instrument handle
 * @param midi_note MIDI note number (0-127)
 * @param velocity Release velocity (0.0-1.0)
 * @param channel MIDI channel (0-15)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_note_off(
    sch_instrument_handle instrument,
    int midi_note,
    float velocity,
    int channel
);

/**
 * Send all-notes-off (panic)
 *
 * @param instrument Instrument handle
 * @param channel MIDI channel (-1 for all channels)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_all_notes_off(
    sch_instrument_handle instrument,
    int channel
);

/**
 * Send pitch bend
 *
 * @param instrument Instrument handle
 * @param value Pitch bend value (-1.0 to +1.0)
 * @param channel MIDI channel (0-15)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_pitch_bend(
    sch_instrument_handle instrument,
    float value,
    int channel
);

/**
 * Send MIDI control change
 *
 * @param instrument Instrument handle
 * @param controller Controller number (0-127)
 * @param value Controller value (0.0-1.0)
 * @param channel MIDI channel (0-15)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_control_change(
    sch_instrument_handle instrument,
    int controller,
    float value,
    int channel
);

// ============================================================================
// PRESET MANAGEMENT
// ============================================================================

/**
 * Get available presets for instrument
 *
 * @param engine Engine handle
 * @param identifier Instrument identifier
 * @param out_presets Pointer to receive array of preset info (caller must free with sch_free_preset_array)
 * @param out_count Pointer to receive number of presets
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_get_presets(
    sch_engine_handle engine,
    const char* identifier,
    sch_preset_info_t** out_presets,
    size_t* out_count
);

/**
 * Load preset by name
 *
 * @param instrument Instrument handle
 * @param preset_name Preset name
 * @return SCH_OK on success, SCH_ERR_NOT_FOUND if preset doesn't exist
 */
sch_result_t sch_instrument_load_preset(
    sch_instrument_handle instrument,
    const char* preset_name
);

/**
 * Save current state as preset
 *
 * @param instrument Instrument handle
 * @param preset_name Preset name
 * @param category Preset category (can be NULL)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_save_preset(
    sch_instrument_handle instrument,
    const char* preset_name,
    const char* category
);

// ============================================================================
// AUDIO PROCESSING
// ============================================================================

/**
 * Process audio through instrument
 *
 * This is called internally by the audio engine. Usually you don't need to
 * call this directly from Swift - just let the JUCE audio engine handle it.
 *
 * @param instrument Instrument handle
 * @param audio_buffer Audio buffer (interleaved stereo)
 * @param num_samples Number of samples to process
 * @param midi_data MIDI message data
 * @param midi_size Size of MIDI data
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_process(
    sch_instrument_handle instrument,
    float* audio_buffer,
    int num_samples,
    const uint8_t* midi_data,
    int midi_size
);

/**
 * Get output audio from instrument
 *
 * @param instrument Instrument handle
 * @param audio_buffer Audio buffer to fill (interleaved stereo)
 * @param num_samples Maximum number of samples to retrieve
 * @param out_samples Pointer to receive actual number of samples retrieved
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_get_audio(
    sch_instrument_handle instrument,
    float* audio_buffer,
    int num_samples,
    int* out_samples
);

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

/**
 * Get current instrument state as JSON
 *
 * @param instrument Instrument handle
 * @param out_json Pointer to receive JSON string (caller must free with sch_free_string)
 * @return SCH_OK on success
 */
sch_result_t sch_instrument_get_state(
    sch_instrument_handle instrument,
    char** out_json
);

/**
 * Set instrument state from JSON
 *
 * @param instrument Instrument handle
 * @param json JSON state string
 * @return SCH_OK on success, SCH_ERR_PARSE_FAILED if JSON is invalid
 */
sch_result_t sch_instrument_set_state(
    sch_instrument_handle instrument,
    const char* json
);

// ============================================================================
// MEMORY MANAGEMENT HELPERS
// ============================================================================

/**
 * Free instrument info array
 *
 * @param instruments Instrument array
 * @param count Number of instruments
 */
void sch_free_instrument_array(
    sch_instrument_info_t* instruments,
    size_t count
);

/**
 * Free single instrument info
 *
 * @param info Instrument info
 */
void sch_free_instrument_info(
    sch_instrument_info_t* info
);

/**
 * Free parameter info
 *
 * @param info Parameter info
 */
void sch_free_parameter_info(
    sch_parameter_info_t* info
);

/**
 * Free preset array
 *
 * @param presets Preset array
 * @param count Number of presets
 */
void sch_free_preset_array(
    sch_preset_info_t* presets,
    size_t count
);

// Forward declare from sch_engine_ffi.h
void sch_free_string(char** str);

#ifdef __cplusplus
}
#endif
