# JUCE Plugin Build Inventory

**Last Updated**: 2026-01-16
**Total Plugins**: 13
**Build System**: CMake 3.22+ with JUCE 7+

---

## Executive Summary

The White Room JUCE backend has **13 plugin build directories** organized as standalone plugin builds. Each plugin has its own CMakeLists.txt and can build multiple formats (VST3, AU, CLAP, Standalone).

**Status**: All plugin builds are configured and ready for building.

---

## Plugin Inventory

### 1. Aether Giant Horns (Instrument)
**Directory**: `aether_giant_horns_plugin_build/`
**Type**: Instrument (Giant Horns)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.6 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/giant_instruments/src/dsp/AetherGiantHornsPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.AetherGiantHorns`

---

### 2. Aether Giant Voice (Instrument)
**Directory**: `aether_giant_voice_plugin_build/`
**Type**: Instrument (Giant Voice)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.7 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/giant_instruments/src/dsp/AetherGiantVoicePureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.AetherGiantVoice`

---

### 3. Aether Drive (Effect)
**Directory**: `aetherdrive_plugin_build/`
**Type**: Effect (Distortion/Drive)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.5 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../effects/aetherdrive/src/AetherDrivePureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.AetherDrive`

---

### 4. Drum Machine (Instrument)
**Directory**: `drummachine_plugin_build/`
**Type**: Instrument (Percussion/Drums)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (5.1 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/drummachine/src/dsp/DrumMachinePureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.DrumMachine`

---

### 5. Far Far Away (Effect)
**Directory**: `farfaraway_plugin_build/`
**Type**: Effect (Delay/Reverb)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.1 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../effects/farfaraway/src/FarFarAwayPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.FarFarAway`

---

### 6. FilterGate (Effect)
**Directory**: `filtergate_plugin_build/`
**Type**: Effect (Envelope Filter + Gate)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.2 KB)
**Documentation**: `BUILD_SUMMARY.md` exists

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../effects/filtergate/src/FilterGatePureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.FilterGate`

---

### 7. Giant Instruments (Instrument Collection)
**Directory**: `giant_instruments_plugin_build/`
**Type**: Instrument (All 5 Giants in One Plugin)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (6.0 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/giant_instruments/src/dsp/AetherGiantDrumsPureDSP.cpp`
- `../instruments/giant_instruments/src/dsp/AetherGiantHornsPureDSP.cpp`
- `../instruments/giant_instruments/src/dsp/AetherGiantPercussionPureDSP.cpp`
- `../instruments/giant_instruments/src/dsp/AetherGiantVoicePureDSP.cpp`
- `../instruments/kane_marco/src/dsp/KaneMarcoAetherStringPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.GiantInstruments`

**Included Giants**:
1. Aether Giant Drums
2. Aether Giant Horns
3. Aether Giant Percussion
4. Aether Giant Voice
5. Kane Marco Aether String

---

### 8. Kane Marco Aether String (Instrument)
**Directory**: `kane_marco_aether_string_plugin_build/`
**Type**: Instrument (Physical Modeling String)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.7 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/kane_marco/src/dsp/KaneMarcoAetherStringPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.KaneMarcoAetherString`

---

### 9. Kane Marco (Instrument)
**Directory**: `kane_marco_plugin_build/`
**Type**: Instrument (Hybrid Virtual Analog)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.6 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/kane_marco/src/dsp/KaneMarcoPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.KaneMarco`

---

### 10. Local Galaxy (Instrument)
**Directory**: `localgal_plugin_build/`
**Type**: Instrument (Feel-Vector Synthesizer)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.7 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/localgal/src/dsp/LocalGalPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.LocalGal`

---

### 11. Monument (Effect)
**Directory**: `monument_plugin_build/`
**Type**: Effect (Phaser)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.1 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../effects/monument/src/MonumentPureDSP.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.Monument`

---

### 12. Nex Synth (Instrument)
**Directory**: `nex_synth_plugin_build/`
**Type**: Instrument (FM Synthesizer)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.3 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/Nex_synth/src/dsp/NexSynthDSP_Pure.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.NexSynth`

---

### 13. Sam Sampler (Instrument)
**Directory**: `sam_sampler_plugin_build/`
**Type**: Instrument (SF2 Sampler)
**Status**: ✅ Configured
**CMakeLists.txt**: Exists (4.6 KB)

**Formats**:
- VST3 (default ON)
- AU (default OFF)
- CLAP (default ON)
- Standalone (default ON)

**Source Files**:
- `../instruments/Sam_sampler/src/dsp/SamSamplerDSP_Pure.cpp`
- `../include/dsp/LookupTables.cpp`

**Output Bundle ID**: `com.schillinger.SamSampler`

---

## Build System Architecture

### Current Structure

```
juce_backend/
├── CMakeLists.txt                    # Main DAW + iOS backend build
├── plugins/                          # Old-style plugins (being phased out)
│   └── CMakeLists.txt               # Builds LOCAL_GAL, SamSampler, NexSynth
├── *_plugin_build/                   # New standalone plugin builds (13 total)
│   ├── CMakeLists.txt               # Each plugin has its own build config
│   └── (can build independently)
├── instruments/                      # DSP source code
│   ├── localgal/
│   ├── kane_marco/
│   ├── Nex_synth/
│   ├── Sam_sampler/
│   ├── drummachine/
│   └── giant_instruments/
├── effects/                          # Effects DSP source code
│   ├── filtergate/
│   ├── aetherdrive/
│   ├── farfaraway/
│   └── monument/
└── include/dsp/                      # Shared DSP headers
    └── LookupTables.cpp
```

### Build Methods

#### Method 1: Build Individual Plugin (Recommended)
```bash
cd juce_backend/<plugin_name>_plugin_build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8
```

#### Method 2: Build All Plugins (Script)
```bash
cd juce_backend
./build_all_plugins.sh  # TODO: Create this script
```

#### Method 3: Build from Main CMakeLists (Not Yet Implemented)
```bash
cd juce_backend
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8
```

---

## Platform Support

### macOS (Apple Silicon & Intel)
- ✅ VST3
- ✅ AU (disabled by default, can be enabled)
- ✅ CLAP
- ✅ Standalone

### Windows (x86_64)
- ✅ VST3
- ❌ AU (not supported)
- ✅ CLAP
- ✅ Standalone

### Linux (x86_64, ARM)
- ✅ VST3
- ❌ AU (not supported)
- ✅ CLAP
- ✅ Standalone

### iOS (arm64)
- ✅ AUv3 (via separate Xcode build)
- ❌ VST3 (not supported on iOS)
- ❌ CLAP (not supported on iOS)
- ❌ Standalone (not applicable)

---

## Dependencies

### Required
- **CMake**: 3.22 or higher
- **JUCE**: 7.0+ (external/JUCE submodule)
- **C++ Standard**: C++17
- **C Standard**: C11

### Optional
- **CLAP support**: clap-juce-extensions (external/clap-juce-extensions submodule)
- **AU support**: macOS SDK (10.15+)
- **CLAP extensions**: CLAP JUCE Extensions

### Build Tools
- **macOS**: Xcode 13+ and/or Command Line Tools
- **Windows**: Visual Studio 2019 or newer
- **Linux**: GCC 9+ or Clang 10+

---

## Build Configuration Options

Each plugin supports the following CMake options:

```bash
# Format Selection
-DBUILD_VST3=ON     # Build VST3 format (default: ON)
-DBUILD_AU=OFF      # Build AU format (default: OFF)
-DBUILD_CLAP=ON     # Build CLAP format (default: ON)
-DBUILD_STANDALONE=ON  # Build Standalone app (default: ON)

# Build Type
-DCMAKE_BUILD_TYPE=Release  # Release build (optimized)
-DCMAKE_BUILD_TYPE=Debug    # Debug build (with symbols)

# Platform-Specific
-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"  # macOS Universal Binary
```

---

## Output Locations

### macOS
- **VST3**: `/Library/Audio/Plug-Ins/VST3/` or `~/Library/Audio/Plug-Ins/VST3/`
- **AU**: `/Library/Audio/Plug-Ins/Components/` or `~/Library/Audio/Plug-Ins/Components/`
- **CLAP**: `/Library/Audio/Plug-Ins/CLAP/` or `~/Library/Audio/Plug-Ins/CLAP/`
- **Standalone**: `build/<PluginName>_artefacts/Release/`

### Windows
- **VST3**: `C:\Program Files\Common Files\VST3\`
- **CLAP**: `C:\Program Files\Common Files\CLAP\`
- **Standalone**: `build\<PluginName>_artefacts\Release\`

### Linux
- **VST3**: `/usr/lib/vst3/` or `~/.vst3/`
- **CLAP**: `/usr/lib/clap/` or `~/.clap/`
- **Standalone**: `build/<PluginName>_artefacts/Release/`

---

## Troubleshooting

### Common Issues

#### 1. JUCE Not Found
**Error**: `JUCE not found at ../external/JUCE`
**Solution**:
```bash
git submodule update --init --recursive external/JUCE
```

#### 2. CLAP Extensions Not Found
**Error**: `clap-juce-extensions not found`
**Solution**:
```bash
git submodule update --init --recursive external/clap-juce-extensions
# Or disable CLAP: -DBUILD_CLAP=OFF
```

#### 3. AU Build Failures on macOS
**Error**: `AU SDK compatibility issues`
**Solution**: AU is disabled by default. To enable:
```bash
-DBUILD_AU=ON
```
Note: AU may require macOS SDK 10.15+.

#### 4. Missing DSP Source Files
**Error**: `Source file not found: ../instruments/...`
**Solution**: Ensure instrument/effect submodules are initialized:
```bash
git submodule update --init --recursive
```

---

## Next Steps

### Immediate Actions
1. ✅ All plugin builds are configured
2. ✅ Build inventory documented
3. 🔧 Create build-all script (TODO)
4. 🔧 Add plugin builds to main CMakeLists.txt (Optional)
5. 🔧 Set up CI/CD for plugin builds (TODO)

### Future Enhancements
1. **Build Monitoring**: Create automated build health checking
2. **Build Scoring**: Implement build success tracking and reporting
3. **Automated Testing**: Add plugin load/save tests
4. **Performance Benchmarks**: Track DSP performance across plugins
5. **Dependency Management**: Automate submodule updates

---

## Maintenance

### Adding New Plugins
1. Create new `*_plugin_build/` directory
2. Copy CMakeLists.txt from existing plugin
3. Update source paths and bundle ID
4. Add to this inventory document
5. Test build on all target platforms

### Updating Plugin Versions
1. Update `VERSION` in CMakeLists.txt
2. Update `PLUGIN_VERSION` in juce_add_plugin()
3. Update this inventory document
4. Tag release in git

---

## Related Documentation

- **Build System Summary**: [BUILD_SYSTEM_SUMMARY.md](BUILD_SYSTEM_SUMMARY.md)
- **Build Matrix**: [BUILD_MATRIX.md](BUILD_MATRIX.md)
- **Testing Guide**: [TESTING.md](TESTING.md)
- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Support

For build issues:
1. Check troubleshooting section above
2. Review CMake output logs
3. Check JUCE documentation: https://docs.juce.com/
4. Open GitHub issue with detailed error logs

---

**Document Version**: 1.0.0
**Last Modified**: 2026-01-16
**Maintained By**: DevOps Automator
