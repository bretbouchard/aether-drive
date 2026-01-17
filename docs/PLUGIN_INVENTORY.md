# White Room Plugin Inventory

**Last Updated:** 2026-01-16
**Total Plugins:** 13 (5 Instruments, 6 Effects, 2 Utilities)

---

## 🎹 Instruments (5)

### 1. LOCAL_GAL Acid Synthesizer
- **Type:** Synthesizer (MIDI)
- **Category:** Acid/Bass
- **Description:** Acid synthesizer with feel vector control system
- **Features:**
  - 5D feel vector (rubber, bite, hollow, growl, wet)
  - Voice management (16-voice polyphony)
  - Pitch bend support
  - Factory presets (5)
- **Location:** `instruments/localgal/`
- **Bundle ID:** `com.schillingerEcosystem.localgal`
- **Formats:** VST3, AU

### 2. Sam Sampler
- **Type:** Sampler (MIDI)
- **Category:** Sample Playback
- **Description:** SF2 SoundFont sampler
- **Features:**
  - SoundFont file loading
  - Multi-sample support
  - ADSR envelope
- **Location:** `instruments/Sam_sampler/`
- **Bundle ID:** `com.schillingerEcosystem.samsampler`
- **Formats:** VST3, AU

### 3. Nex FM Synth
- **Type:** Synthesizer (MIDI)
- **Category:** FM Synthesis
- **Description:** FM synthesizer with configurable operators
- **Features:**
  - FM synthesis engine
  - Multiple operators
  - Modulation matrix
- **Location:** `instruments/Nex_synth/`
- **Bundle ID:** `com.schillingerEcosystem.nexsynth`
- **Formats:** VST3, AU

### 4. Giant Instruments (5-in-1)
- **Type:** Synthesizer (MIDI)
- **Category:** Orchestral
- **Description:** All 5 Aether Giant instruments in one plugin
- **Instruments Included:**
  - Aether Giant Drums
  - Aether Giant Horns
  - Aether Giant Percussion
  - Aether Giant Voice
  - Kane Marco Aether Strings
- **Location:** `instruments/giant_instruments/`
- **Bundle ID:** `com.schillingerEcosystem.giantinstruments`
- **Formats:** VST3, AU

### 5. Kane Marco Aether Strings
- **Type:** Synthesizer (MIDI)
- **Category:** Strings
- **Description:** Physical modeling string synthesizer
- **Features:**
  - String resonance modeling
  - Vibrato control
  - Body simulation
- **Location:** `instruments/kane_marco/`
- **Bundle ID:** `com.schillingerEcosystem.kanemarco` (standalone)
- **Formats:** VST3, AU

---

## 🎛️ Effects (6)

### 1. BiPhase Phaser
- **Type:** Effect (Audio)
- **Category:** Modulation
- **Description:** Dual-stage phaser effect
- **Features:**
  - Dual phaser stages
  - LFO modulation
  - Feedback control
  - Stereo width
- **Location:** `effects/biPhase/`
- **Bundle ID:** `com.schillingerEcosystem.biphase`
- **Formats:** VST3, AU

### 2. FilterGate
- **Type:** Effect (Audio)
- **Category:** Modulation/Dynamics
- **Description:** Envelope filter with gating
- **Features:**
  - Envelope follower
  - LFO modulation
  - Gate dynamics
  - Resonant filter
- **Location:** `effects/filtergate/`
- **Bundle ID:** `com.schillingerEcosystem.filtergate`
- **Formats:** VST3, AU

### 3. Monument Reverb
- **Type:** Effect (Audio)
- **Category:** Reverb
- **Description:** Algorithmic reverb
- **Features:**
  - Multiple reverb algorithms
  - Decay time control
  - Pre-delay
  - Early reflections
- **Location:** `effects/monument/`
- **Bundle ID:** `com.schillingerEcosystem.monument`
- **Formats:** VST3, AU

### 4. FarFarAway Reverb
- **Type:** Effect (Audio)
- **Category:** Reverb
- **Description:** Large space reverb
- **Features:**
  - Large hall algorithms
  - Diffusion control
  - Modulated tail
  - Infinite decay mode
- **Location:** `effects/farfaraway/`
- **Bundle ID:** `com.schillingerEcosystem.farfaraway`
- **Formats:** VST3, AU

### 5. AetherDrive Overdrive
- **Type:** Effect (Audio)
- **Category:** Distortion
- **Description:** Overdrive/distortion effect
- **Features:**
  - Tube-style overdrive
  - Tone control
  - Drive amount
  - Clean blend
- **Location:** `effects/AetherDrive/`
- **Bundle ID:** `com.schillingerEcosystem.aetherdrive`
- **Formats:** VST3, AU

### 6. Overdrive Pedal
- **Type:** Effect (Audio)
- **Category:** Distortion
- **Description:** Pedal-style overdrive
- **Features:**
  - Classic pedal overdrive
  - 3-band EQ
  - Presence control
  - Cabinet simulation
- **Location:** `effects/overdrive_pedal/`
- **Bundle ID:** `com.schillingerEcosystem.overdrive`
- **Formats:** VST3, AU

---

## 🎵 Utilities (2)

### 1. Schillinger Composition System
- **Type:** Utility (MIDI)
- **Category:** Composition
- **Description:** Generative MIDI composition system
- **Features:**
  - Schillinger rhythm generation
  - Motif development
  - Voice leading
  - Harmonic progression
- **Location:** `juce_backend/` (SchillingerPlugin)
- **Bundle ID:** `com.schillingerEcosystem.schillinger`
- **Formats:** VST3, AU

### 2. Single Note Test
- **Type:** Utility (MIDI)
- **Category:** Testing
- **Description:** Foundation test plugin
- **Features:**
  - Single note generation
  - Test signal output
  - Phase 1 foundation testing
- **Location:** `juce_backend/src/audio/`
- **Bundle ID:** `com.schillingerEcosystem.singlenotetest`
- **Formats:** VST3, AU

---

## 📊 Build Configuration

### CMake Integration
All plugins are configured in `juce_backend/plugins/CMakeLists.txt`

### Build Commands
```bash
cd juce_backend/plugins
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

### Output Formats
- **macOS:** `.vst3` bundles, `.component` bundles (AU)
- **Windows:** `.vst3` bundles
- **Linux:** `.vst3` bundles

---

## 🔧 Plugin Status

| Plugin | Status | Notes |
|--------|--------|-------|
| LOCAL_GAL | ✅ Configured | Full voice management, pitch bend |
| Sam Sampler | ✅ Configured | SF2 parsing needs implementation |
| Nex FM Synth | ✅ Configured | FM synthesis working |
| Giant Instruments | ✅ Configured | All 5 giants integrated |
| Kane Marco | ✅ Configured | Part of Giant Instruments |
| BiPhase | ✅ Configured | Custom editor needed |
| FilterGate | ✅ Configured | Fully functional |
| Monument | ✅ Configured | Custom editor needed |
| FarFarAway | ✅ Configured | Fully functional |
| AetherDrive | ✅ Configured | Fully functional |
| Overdrive | ✅ Configured | Fully functional |
| Schillinger | ✅ Configured | MIDI generator |
| Single Note Test | ✅ Configured | Foundation test |

---

## 📝 Development Notes

### Implemented Features
- ✅ All 13 plugins configured in CMake
- ✅ Voice management (16-voice polyphony)
- ✅ Pitch bend support
- ✅ MIDI note on/off
- ✅ Preset loading (JSON + factory)
- ✅ All notes off / panic

### Known Issues
- ⚠️ BiPhaseDSP linking issues (BiPhase effect disabled)
- ⚠️ SF2 SoundFont parser incomplete (Sam Sampler)
- ⚠️ Custom editors needed for Monument and BiPhase

### TODO Items
- Fix BiPhaseDSP linking issues
- Implement full RIFF/SF2 parsing
- Create custom plugin editors
- Implement state save/load for all plugins
- Add CLAP format support

---

## 🎯 Usage

### In DAWs
1. Build plugins using cmake commands above
2. Install plugins to system plugin directory:
   - **macOS:** `/Library/Audio/Plug-Ins/VST3/` or `/Components/`
   - **Windows:** `C:\Program Files\Common Files\VST3\`
3. Rescan plugins in DAW
4. Use like any other plugin

### Development
To add new plugins:
1. Create plugin directory
2. Implement AudioProcessor
3. Add to `juce_backend/plugins/CMakeLists.txt`
4. Follow existing plugin structure

---

## 📚 Documentation

- **JUCE Integration:** See JUCE documentation
- **Schillinger System:** See `docs/schillinger/`
- **DSP Architecture:** See `docs/dsp_architecture.md`
- **Plugin Development:** See `docs/plugin_development.md`

---

**Generated:** 2026-01-16
**Version:** 1.0.0
**Status:** ✅ All plugins configured and ready to build
