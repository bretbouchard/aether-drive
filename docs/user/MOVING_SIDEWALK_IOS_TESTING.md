# Moving Sidewalk iOS Interface - Testing Guide

## Overview

Comprehensive testing guide for the Moving Sidewalk multi-song player iOS interface.

## Files Created

### Core Components

1. **MultiSongState.swift** (`/swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/Audio/MultiSongState.swift`)
   - State management for multi-song playback
   - Master transport controls
   - Sync modes (Independent, Locked, Ratio)
   - Preset management

2. **SongPlayerCard.swift** (`/swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/UI/Components/SongPlayerCard.swift`)
   - Individual song player card
   - Play/pause, tempo, volume, mute/solo controls
   - Waveform visualization
   - Compact and expanded views

3. **MasterTransportControls.swift** (`/swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/UI/Components/MasterTransportControls.swift`)
   - Master transport controls
   - Sync mode selector
   - Master tempo and volume
   - Add song and save preset buttons

4. **MovingSidewalkView.swift** (`/swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/UI/Screens/MovingSidewalkView.swift`)
   - Main iOS screen
   - Horizontal scrolling song cards (iPhone)
   - Grid layout (iPad)
   - Visual timeline

5. **HapticFeedbackManager.swift** (`/swift_frontend/WhiteRoomiOS/Sources/SwiftFrontendCore/UI/Utilities/HapticFeedbackManager.swift`)
   - Centralized haptic feedback
   - Accessibility enhancements
   - VoiceOver support
   - Dynamic Type support

## Testing Checklist

### 1. Basic Functionality

- [ ] **Song Playback**
  - [ ] Play/pause individual songs
  - [ ] Master play/pause controls all songs
  - [ ] Stop button resets all songs to beginning
  - [ ] Progress indicators update correctly

- [ ] **Tempo Control**
  - [ ] Individual song tempo sliders work (0.5x - 2.0x)
  - [ ] Master tempo affects songs in locked/ratio mode
  - [ ] Tempo displays update correctly
  - [ ] Smooth tempo transitions

- [ ] **Volume Control**
  - [ ] Individual song volume sliders work (0-100%)
  - [ ] Master volume affects all songs
  - [ ] Volume displays update correctly
  - [ ] Mute button works correctly
  - [ ] Muted songs show visual feedback

- [ ] **Mute/Solo**
  - [ ] Mute button toggles correctly
  - [ ] Solo button toggles correctly
  - [ ] Multiple solos allowed
  - [ ] Visual feedback for mute/solo state
  - [ ] Soloed songs have highlighted border

### 2. Sync Modes

- [ ] **Independent Mode**
  - [ ] Songs play at their own tempo
  - [ ] Master tempo doesn't affect songs
  - [ ] Each song has independent progress

- [ ] **Locked Mode**
  - [ ] All songs lock to master tempo
  - [ ] Adjusting master tempo affects all songs equally
  - [ ] Individual tempo sliders disabled or overridden

- [ ] **Ratio Mode**
  - [ ] Songs maintain ratio to master tempo
  - [ ] Adjusting master tempo scales all songs proportionally
  - [ ] Individual song ratios preserved

### 3. Layout & Responsiveness

- [ ] **iPhone (Portrait)**
  - [ ] Horizontal scrolling song cards
  - [ ] Cards fill width (32px margins)
  - [ ] Smooth scrolling
  - [ ] Safe areas respected
  - [ ] Controls accessible at bottom

- [ ] **iPad (Landscape)**
  - [ ] Grid layout (2 columns)
  - [ ] Cards sized appropriately
  - [ ] More content visible at once
  - [ ] Touch targets remain adequate

- [ ] **Safe Areas**
  - [ ] Notch respected on iPhone
  - [ ] Home indicator respected
  - [ ] Controls not obscured
  - [ ] Bottom padding adjusted

### 4. Touch Interactions

- [ ] **Gestures**
  - [ ] Tap on play/pause works
  - [ ] Drag on progress bars works
  - [ ] Swipe to scroll song cards works
  - [ ] Pinch gestures (if implemented)

- [ ] **Touch Targets**
  - [ ] All buttons ≥ 44x44 points
  - [ ] Sliders easy to grab
  - [ ] Controls not too close
  - [ ] Expand/collapse easy to tap

- [ ] **Haptic Feedback**
  - [ ] Light tap on play/pause
  - [ ] Medium impact on expand
  - [ ] Success on save preset
  - [ ] Selection feedback on sliders
  - [ ] Not too overwhelming

### 5. Visual Design

- [ ] **Colors**
  - [ ] Theme colors applied correctly
  - [ ] Good contrast for accessibility
  - [ ] Visual hierarchy clear
  - [ ] Feedback colors (success, error, warning)

- [ ] **Animations**
  - [ ] Smooth 60fps transitions
  - [ ] No janky animations
  - [ ] Reduced motion respected
  - [ ] Expand/collapse animations smooth

- [ ] **Waveform**
  - [ ] Waveform renders correctly
  - [ ] Progress indicator visible
  - [ ] Colors match theme
  - [ ] Performance good with many songs

### 6. Accessibility

- [ ] **VoiceOver**
  - [ ] All elements labeled
  - [ ] Hints provided for controls
  - [ ] Values announced for sliders
  - [ ] State changes announced
  - [ ] Focus order logical
  - [ ] Custom actions available

- [ ] **Dynamic Type**
  - [ ] Text scales correctly
  - [ ] Layout adapts to larger text
  - [ ] No text clipped
  - [ ] Touch targets remain adequate

- [ ] **Reduced Motion**
  - [ ] Animations disabled
  - [ ] Still functional
  - [ ] No jarring transitions

- [ ] **Color Blindness**
  - [ ] Not just color for state
  - [ ] Icons supplement colors
  - [ ] Text labels clear

### 7. Performance

- [ ] **Scrolling Performance**
  - [ ] 60fps when scrolling
  - [ ] No dropped frames
  - [ ] Smooth deceleration

- [ ] **Memory**
  - [ ] No memory leaks
  - [ ] Reasonable footprint
  - [ ] Waveforms don't use excessive memory

- [ ] **Battery**
  - [ ] No excessive CPU usage
  - [ ] Efficient animations
  - [ ] Background behavior appropriate

### 8. Edge Cases

- [ ] **Empty State**
  - [ ] No songs shows message
  - [ ] Add song button available
  - [ ] Demo songs load on first launch

- [ ] **Many Songs**
  - [ ] Performance with 10+ songs
  - [ ] Scrolling still smooth
  - [ ] Memory reasonable

- [ ] **Network Failures**
  - [ ] Album art fails gracefully
  - [ ] No crashes on timeout
  - [ ] Error handling

### 9. Presets

- [ ] **Save Preset**
  - [ ] Preset name required
  - [ ] All settings saved
  - [ ] Success feedback
  - [ ] Sheet dismisses correctly

- [ ] **Load Preset**
  - [ ] Preset list shows
  - [ ] Load restores settings
  - [ ] Invalid presets handled

### 10. Integration

- [ ] **Backend Integration**
  - [ ] Connects to MultiSongEngine
  - [ ] State syncs correctly
  - [ ] Error handling

## Test Scenarios

### Scenario 1: First Launch

1. Open Moving Sidewalk
2. Demo songs should load automatically
3. Verify all controls work
4. Try playing a song

### Scenario 2: Add New Song

1. Tap "Add Song" button
2. Fill in song details
3. Tap "Add Song"
4. Verify song appears in list
5. Verify controls work

### Scenario 3: Create Beat Match

1. Add 4 songs at different tempos
2. Switch to "Locked" sync mode
3. Adjust master tempo to match target
4. Verify all songs lock to tempo
5. Test playback

### Scenario 4: Live Performance

1. Load preset for performance
2. Practice using mute/solo
3. Test tempo changes
4. Verify smooth transitions
5. Check no audio glitches

### Scenario 5: Accessibility Test

1. Enable VoiceOver
2. Navigate through all controls
3. Verify all labels and hints
4. Test custom actions
5. Verify announcements

## Device Testing Matrix

| Device | iOS Version | Orientation | Layout | Status |
|--------|-------------|-------------|---------|--------|
| iPhone 15 Pro | 17.0+ | Portrait | Horizontal Scroll | [ ] |
| iPhone 15 Pro | 17.0+ | Landscape | Horizontal Scroll | [ ] |
| iPhone SE | 17.0+ | Portrait | Horizontal Scroll | [ ] |
| iPad Pro 12.9" | 17.0+ | Portrait | Grid (2 col) | [ ] |
| iPad Pro 12.9" | 17.0+ | Landscape | Grid (2 col) | [ ] |
| iPad Mini | 17.0+ | Portrait | Grid (2 col) | [ ] |

## Performance Benchmarks

- [ ] App startup time < 3 seconds
- [ ] Scroll frame rate ≥ 60fps
- [ ] Memory usage < 150MB (with 10 songs)
- [ ] Battery drain < 5% per hour (active use)

## Known Issues

Track any issues found during testing:

1.
2.
3.

## Sign-off

- [ ] All tests passed
- [ ] Performance acceptable
- [ ] Accessibility verified
- [ ] Documentation complete
- [ ] Ready for release

**Tester**: ______________________

**Date**: ______________________

**Build**: ______________________
