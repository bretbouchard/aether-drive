# Creating Your First Song

**Step-by-step tutorial to create your first song in White Room.**

---

## Table of Contents

1. [Step 1: New Project](#step-1-new-project)
2. [Step 2: Add Tracks](#step-2-add-tracks)
3. [Step 3: Compose](#step-3-compose)
4. [Step 4: Mix](#step-4-mix)
5. [Step 5: Export](#step-5-export)

---

## Step 1: New Project

### Launch White Room

1. Open **White Room** from Applications
2. Click **"New Project"** in the welcome window
3. Enter project name: "My First Song"
4. Choose location: `~/Music/White Room/`
5. Set tempo: **120 BPM**
6. Set time signature: **4/4**
7. Set key: **C Major**
8. Click **"Create"**

### Project Setup

Your new project opens with:
- Empty timeline
- No tracks
- Playhead at position 0
- Default tempo and time signature

---

## Step 2: Add Tracks

### Add Piano Track

1. Click **"+"** button in Tracks panel (left sidebar)
2. Select **"Software Instrument"**
3. Choose **"Grand Piano"** from instrument list
4. Name track: "Piano"
5. Click **"Add Track"**

### Add Bass Track

1. Click **"+"** again
2. Select **"Software Instrument"**
3. Choose **"Electric Bass"** from instrument list
4. Name track: "Bass"
5. Click **"Add Track"**

### Add Drum Track

1. Click **"+"** again
2. Select **"Software Instrument"**
3. Choose **"Drum Kit"** from instrument list
4. Name track: "Drums"
5. Click **"Add Track"**

**Your tracks panel should now show**:
- Piano
- Bass
- Drums

---

## Step 3: Compose

### Add Piano Melody

**Option 1: Record with MIDI Keyboard**

1. Select **Piano** track
2. Click **"R"** button (record arm) on track
3. Click **Record** (red circle) in transport
4. Play melody on MIDI keyboard
5. Click **Stop** (square) when done
6. Your melody appears as a region

**Option 2: Draw Notes in Piano Roll**

1. Double-click Piano track to create empty region
2. Double-click region to open Piano Roll
3. Select Pencil tool (or press **P**)
4. Click to add notes:
   - C4 (Middle C) at position 0
   - E4 at position 480
   - G4 at position 960
   - C5 at position 1440
5. Drag note edges to set duration (e.g., 480 ticks each)
6. Close Piano Roll

**Result**: Simple C major scale melody (C-E-G-C)

### Add Bass Line

1. Select **Bass** track
2. Double-click to create region
3. Open Piano Roll
4. Draw notes:
   - C2 (low C) at position 0, duration 1920
   - C2 at position 1920, duration 1920
   - G2 at position 3840, duration 1920
   - F2 at position 5760, duration 1920
5. Close Piano Roll

**Result**: Simple bass line outlining C-G-F progression

### Add Drum Beat

1. Select **Drums** track
2. Double-click to create region
3. Open Piano Roll
4. Draw drum pattern:
   - Kick (C2): positions 0, 960, 1920, 2880
   - Snare (D2): positions 480, 1440, 2400, 3360
   - Hi-hat (G#2): positions 0, 240, 480, 720, 960, etc.
5. Close Piano Roll

**Result**: Basic rock beat

### Arrange Your Song

**Copy Regions**:

1. Select all three regions (Piano, Bass, Drums)
2. **Option+Drag** to copy to bar 2 (position 1920)
3. Repeat for bars 3 and 4

**Your timeline should show**:
- Bar 1: Piano, Bass, Drums
- Bar 2: Piano, Bass, Drums
- Bar 3: Piano, Bass, Drums
- Bar 4: Piano, Bass, Drums

---

## Step 4: Mix

### Set Levels

1. Open Mixer (**View > Show Mixer** or **Cmd+3**)
2. Adjust volume faders:
   - Piano: 0 dB (default)
   - Bass: -2 dB
   - Drums: -4 dB

**Result**: Balanced mix where all instruments are audible

### Add Panning

1. Adjust pan knobs:
   - Piano: Center (0)
   - Bass: Center (0)
   - Drums: Slightly right (+10)

**Result**: Stereo image with drums slightly to the right

### Add Reverb

1. Click **"+"** in Sends section on Piano track
2. Choose **"Reverb Bus"**
3. Adjust send level: **-10 dB**
4. Repeat for Bass and Drums

**Result**: Sense of space and depth

### Add Compression

1. Click empty insert slot on Bass track
2. Choose **"Compressor"**
3. Set parameters:
   - Threshold: -20 dB
   - Ratio: 4:1
   - Attack: 5 ms
   - Release: 50 ms

**Result**: More consistent bass level

---

## Step 5: Export

### Export as Audio

1. **File > Export > Audio Export**
2. Choose settings:
   - Format: **WAV**
   - Sample Rate: **44.1 kHz**
   - Bit Depth: **24-bit**
   - Export Range: **Entire Project**
   - Normalization: **Off**
3. Click **"Export"**
4. Choose location: `~/Music/White Room/Exports/`
5. Name: "My First Song.wav"
6. Click **"Save"**

### Export as MIDI

1. **File > Export > MIDI File**
2. Choose format: **Format 1** (multi-track)
3. Click **"Export"**
4. Choose location: `~/Music/White Room/Exports/`
5. Name: "My First Song.mid"
6. Click **"Save"**

### Export Stems

1. **File > Export > Export Stems**
2. Include effects: **Yes**
3. Click **"Export"**
4. Choose location: `~/Music/White Room/Exports/Stems/`
5. Creates:
   - Piano.wav
   - Bass.wav
   - Drums.wav

---

## Next Steps

**Congratulations!** You've created your first song in White Room!

**Continue Learning**:
- **[User Guide](../user/DAW_USER_GUIDE.md)** - Comprehensive feature documentation
- **[Features Guide](../user/FEATURES.md)** - All features explained
- **[Advanced Tutorials](./)** - More in-depth tutorials

**Try These**:
- Add more instruments (strings, synths, etc.)
- Experiment with different tempos and time signatures
- Create longer arrangements (verse, chorus, bridge)
- Add automation (volume, pan, effects)
- Try different genres (electronic, jazz, orchestral)

---

## Troubleshooting

**No Sound**:
- Check system volume
- Verify audio device in Preferences
- Check track volume faders
- Ensure master isn't muted

**MIDI Not Recording**:
- Check MIDI keyboard is connected
- Verify track is armed (R button)
- Check MIDI input in Preferences

**Can't Export**:
- Check disk space (need ~100MB)
- Verify write permissions
- Try different export location

---

**Last Updated**: January 16, 2026
**Version**: 1.0.0
**Next**: [Plugin Development Tutorial](PLUGIN_DEVELOPMENT.md)

---

*Happy music making!*
