# Code Examples

**Practical code examples for White Room development.**

---

## Table of Contents

1. [Timeline Operations](#timeline-operations)
2. [Projection Usage](#projection-usage)
3. [MIDI Handling](#midi-handling)
4. [File I/O](#file-io)

---

## Timeline Operations

### Create a Simple Project

```typescript
import { createProject, addTrack, addRegion } from 'white-room-sdk';

// Create project
const project = createProject({
  name: "My Song",
  tempo: 120,
  timeSignature: [4, 4],
  keySignature: "C major",
  sampleRate: 44100
});

// Add piano track
const pianoTrack = addTrack(project, TrackType.SoftwareInstrument);
pianoTrack.name = "Piano";

// Add MIDI region
const midiRegion: Region = {
  id: "region-1",
  start: 0,
  duration: 1920,  // 1 bar
  content: {
    type: "midi",
    notes: [
      { pitch: 60, velocity: 80, start: 0, duration: 480 },    // C4
      { pitch: 64, velocity: 80, start: 480, duration: 480 },  // E4
      { pitch: 67, velocity: 80, start: 960, duration: 480 },  // G4
      { pitch: 72, velocity: 80, start: 1440, duration: 480 }  // C5
    ]
  }
};

addRegion(pianoTrack, midiRegion);
```

### Split and Join Regions

```typescript
// Split region at position 960
const [left, right] = splitRegion(midiRegion, 960);

console.log(`Left region: ${left.start} to ${left.start + left.duration}`);
console.log(`Right region: ${right.start} to ${right.start + right.duration}`);

// Join adjacent regions
const joined = joinRegions([left, right]);
console.log(`Joined region: ${joined.start} to ${joined.start + joined.duration}`);
```

### Duplicate Regions

```typescript
// Duplicate region to bar 2
const duplicated = duplicateRegion(midiRegion);
duplicated.start = 1920;  // Move to bar 2

addRegion(pianoTrack, duplicated);
```

---

## Projection Usage

### Time Projection

```typescript
import { projectTime } from 'white-room-sdk';

// Convert ticks to seconds
const ticksPerBeat = 480;
const beatsPerBar = 4;
const tempo = 120;  // BPM

const ticks = 1920;  // 1 bar
const seconds = projectTime(ticks, TimeScale.Ticks, TimeScale.Seconds, tempo);

console.log(`${ticks} ticks = ${seconds} seconds at ${tempo} BPM`);
// Output: 1920 ticks = 2.0 seconds at 120 BPM
```

### Tempo Change (Time Stretching)

```typescript
// Stretch region from 120 BPM to 140 BPM
const originalTempo = 120;
const newTempo = 140;

const stretched = projectRegion(midiRegion, originalTempo, newTempo);

console.log(`Original duration: ${midiRegion.duration} ticks`);
console.log(`Stretched duration: ${stretched.duration} ticks`);
// Output: Original duration: 1920 ticks
//         Stretched duration: 1645.7 ticks (slower)
```

### Pitch Projection (Transposition)

```typescript
// Transpose melody from C major to D major
const melody = [60, 62, 64, 65, 67];  // C major scale
const fromKey = "C major";
const toKey = "D major";

const transposed = projectPitch(melody, fromKey, toKey);

console.log(`Original: ${melody}`);
console.log(`Transposed: ${transposed}`);
// Output: Original: 60,62,64,65,67
//         Transposed: 62,64,66,67,69 (D major scale)
```

---

## MIDI Handling

### MIDI Input Callback

```typescript
import { MIDIManager } from 'white-room-sdk';

const midiManager = new MIDIManager();

// Register MIDI input callback
midiManager.onMessage = (message) => {
  if (message.status === 0x90 && message.data2 > 0) {
    // Note on
    console.log(`Note ON: ${message.data1}, Velocity: ${message.data2}`);
    playNote(engine, track, message.data1, message.data2);
  } else if (message.status === 0x80 || (message.status === 0x90 && message.data2 === 0)) {
    // Note off
    console.log(`Note OFF: ${message.data1}`);
    stopNote(engine, track, message.data1);
  }
};

// Connect MIDI device
midiManager.connect("USB MIDI Keyboard");
```

### MIDI Recording

```typescript
class MIDIRecorder {
  private recordedNotes: Note[] = [];
  private startTime: number = 0;

  startRecording(engine: AudioEngine) {
    this.startTime = getPosition(engine);
    this.recordedNotes = [];

    midiManager.onMessage = (message) => {
      if (message.status === 0x90 && message.data2 > 0) {
        const note: Note = {
          pitch: message.data1,
          velocity: message.data2,
          start: getPosition(engine) - this.startTime,
          duration: 0  // Will be set on note off
        };
        this.recordedNotes.push(note);
      } else if (message.status === 0x80) {
        const note = this.recordedNotes.find(n => n.pitch === message.data1);
        if (note) {
          note.duration = getPosition(engine) - this.startTime - note.start;
        }
      }
    };
  }

  stopRecording(): MIDIContent {
    return {
      notes: this.recordedNotes,
      tempo: 120,
      timeSignature: { numerator: 4, denominator: 4 }
    };
  }
}
```

---

## File I/O

### Import Audio File

```typescript
import { importAudioFile, addRegion } from 'white-room-sdk';

// Import audio file
const audioPath = "/path/to/drums.wav";
const audioRegion = importAudioFile(audioPath);

// Add to track
const audioTrack = addTrack(project, TrackType.Audio);
audioTrack.name = "Drums";

addRegion(audioTrack, audioRegion);

// Trim to 4 bars
audioRegion.duration = 7680;  // 4 bars at 120 BPM, 4/4
```

### Export Project as Audio

```typescript
import { exportAudio } from 'white-room-sdk';

// Export options
const options: ExportOptions = {
  format: "wav",
  sampleRate: 44100,
  bitDepth: 24,
  startTime: 0,
  endTime: 7680,  // 4 bars
  normalize: true
};

// Export
exportAudio(project, "/path/to/export.wav", options);
console.log("Exported to /path/to/export.wav");
```

### Export MIDI

```typescript
import { exportMIDI } from 'white-room-sdk';

// Export project as MIDI file
exportMIDI(project, "/path/to/export.mid");
console.log("Exported MIDI to /path/to/export.mid");
```

### Export Stems

```typescript
import { exportStems } from 'white-room-sdk';

// Export each track as separate audio file
exportStems(project, "/path/to/stems/");

// Creates:
// - Piano.wav
// - Bass.wav
// - Drums.wav
// - (etc.)

console.log("Exported stems to /path/to/stems/");
```

---

## Swift UI Examples

### Create Timeline View

```swift
import SwiftUI

struct TimelineView: View {
    @StateObject var viewModel: TimelineViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Tracks panel
            TracksPanel(tracks: viewModel.tracks)
                .frame(width: 200)

            Divider()

            // Timeline editor
            TimelineEditor(regions: viewModel.regions)
                .frame(maxWidth: .infinity)

            Divider()

            // Inspector
            InspectorPanel(selection: viewModel.selectedRegion)
                .frame(width: 250)
        }
        .onAppear {
            viewModel.loadProject()
        }
    }
}
```

### Create Piano Roll View

```swift
struct PianoRollView: View {
    @StateObject var viewModel: PianoRollViewModel
    @State private var selectedTool: Tool = .pointer

    var body: some View {
        VStack(spacing: 0) {
            // Piano keyboard
            PianoKeyboard(keyRange: 60...72)
                .frame(height: 200)

            Divider()

            // Note grid
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    // Grid lines
                    GridLines()

                    // Notes
                    ForEach(viewModel.notes) { note in
                        NoteRect(note: note, selected: viewModel.selectedNotes.contains(note))
                            .onTapGesture {
                                viewModel.selectNote(note)
                            }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .main) {
                ToolPicker(selectedTool: $selectedTool)
            }
        }
    }
}
```

### Create Mixer View

```swift
struct MixerView: View {
    @StateObject var viewModel: MixerViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(viewModel.tracks) { track in
                    ChannelStrip(track: track)
                        .frame(width: 80)
                }

                Divider()

                // Master channel
                MasterChannelStrip()
                    .frame(width: 100)
            }
            .padding()
        }
    }
}

struct ChannelStrip: View {
    @ObservedObject var track: Track

    var body: some View {
        VStack(spacing: 12) {
            Text(track.name)
                .font(.caption)
                .lineLimit(1)

            MuteSoloButtons(track: track)

            VolumeFader(volume: $track.volume)

            PanKnob(pan: $track.pan)
                .frame(height: 80)

            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}
```

---

## JUCE C++ Examples

### Create Audio Processor

```cpp
// MyAudioProcessor.h
#pragma once

#include <JuceHeader.h>

class MyAudioProcessor : public juce::AudioProcessor {
public:
    MyAudioProcessor();
    ~MyAudioProcessor() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }

    const juce::String getName() const override { return "My Audio Processor"; }

private:
    juce::AudioProcessorValueTreeState parameters;
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MyAudioProcessor)
};

// MyAudioProcessor.cpp
#include "MyAudioProcessor.h"

MyAudioProcessor::MyAudioProcessor()
    : AudioProcessor(BusesProperties()
        .withInput("Input", juce::AudioChannelSet::stereo(), true)
        .withOutput("Output", juce::AudioChannelSet::stereo(), true))
{
    // Add parameters
    parameters.createAndAddParameter("gain", "Gain", juce::String(),
        0.0f, 1.0f, 0.5f);
}

void MyAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock) {
    // Prepare audio processing
}

void MyAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    juce::ScopedNoDenormals noDenormals;

    // Get gain parameter
    auto gain = *parameters.getRawParameterValue("gain");

    // Apply gain to each channel
    for (int channel = 0; channel < buffer.getNumChannels(); ++channel) {
        buffer.applyGain(channel, 0, buffer.getNumSamples(), gain);
    }
}

juce::AudioProcessorEditor* MyAudioProcessor::createEditor() {
    return new MyAudioProcessorEditor(*this);
}
```

### MIDI Processing

```cpp
void MyAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    // Process MIDI messages
    for (const auto metadata : midiMessages) {
        auto message = metadata.getMessage();

        if (message.isNoteOn()) {
            // Handle note on
            int noteNumber = message.getNoteNumber();
            int velocity = message.getVelocity();
            // Start playing note...
        } else if (message.isNoteOff()) {
            // Handle note off
            int noteNumber = message.getNoteNumber();
            // Stop playing note...
        } else if (message.isController()) {
            // Handle control change
            int controllerNumber = message.getControllerNumber();
            int controllerValue = message.getControllerValue();
            // Update parameter...
        }
    }

    // Clear MIDI buffer
    midiMessages.clear();
}
```

---

**Last Updated**: January 16, 2026
**Version**: 1.0.0
**Previous**: [First Song Tutorial](FIRST_SONG.md)

---

*For more examples, see the GitHub repository: `/examples/`*
