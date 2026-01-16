/**
 * Tests for Mixing Console with Bus Support
 */

import { describe, it, expect, beforeEach } from 'vitest'
import {
  MixingConsole,
  ChannelStrip,
  BusChannel,
  BusType
} from '../MixingConsole'
import { MixingPresetManager, PresetCategory } from '../MixingPresets'

describe('MixingConsole - Bus Management', () => {
  let console: MixingConsole

  beforeEach(() => {
    console = new MixingConsole()
  })

  describe('Default Bus Initialization', () => {
    it('should create default buses on initialization', () => {
      const buses = console.getAllBuses()

      expect(buses.length).toBeGreaterThan(0)
      expect(buses.some(bus => bus.type === BusType.REVERB)).toBe(true)
      expect(buses.some(bus => bus.type === BusType.DELAY)).toBe(true)
      expect(buses.some(bus => bus.type === BusType.SUBGROUP)).toBe(true)
      expect(buses.some(bus => bus.type === BusType.MASTER)).toBe(true)
    })

    it('should create reverb bus with correct properties', () => {
      const reverbBus = console.getAllBuses().find(b => b.type === BusType.REVERB)

      expect(reverbBus).toBeDefined()
      expect(reverbBus?.name).toBe('Reverb 1')
      expect(reverbBus?.volume).toBe(0.75)
      expect(reverbBus?.isMuted).toBe(false)
      expect(reverbBus?.channels).toEqual([])
    })

    it('should create delay bus with correct properties', () => {
      const delayBus = console.getAllBuses().find(b => b.type === BusType.DELAY)

      expect(delayBus).toBeDefined()
      expect(delayBus?.name).toBe('Delay 1')
      expect(delayBus?.volume).toBe(0.75)
    })

    it('should create subgroup bus for drums', () => {
      const drumsBus = console.getAllBuses().find(b => b.type === BusType.SUBGROUP)

      expect(drumsBus).toBeDefined()
      expect(drumsBus?.name).toBe('Drums')
      expect(drumsBus?.volume).toBe(0.8)
    })
  })

  describe('Bus Management', () => {
    it('should add a new bus', () => {
      const newBus: BusChannel = {
        id: 'bus-custom',
        name: 'Custom Bus',
        type: BusType.AUX,
        channels: [],
        volume: 0.8,
        pan: 0,
        isMuted: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        sends: [],
        icon: 'speaker.wave.2.fill',
        color: '#FF0000'
      }

      console.addBus(newBus)
      const retrievedBus = console.getBus('bus-custom')

      expect(retrievedBus).toBeDefined()
      expect(retrievedBus?.name).toBe('Custom Bus')
      expect(retrievedBus?.type).toBe(BusType.AUX)
    })

    it('should remove a bus', () => {
      const newBus: BusChannel = {
        id: 'bus-temp',
        name: 'Temp Bus',
        type: BusType.AUX,
        channels: [],
        volume: 0.8,
        pan: 0,
        isMuted: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        sends: [],
        icon: 'speaker.wave.2.fill',
        color: '#FF0000'
      }

      console.addBus(newBus)
      expect(console.getBus('bus-temp')).toBeDefined()

      console.removeBus('bus-temp')
      expect(console.getBus('bus-temp')).toBeUndefined()
    })

    it('should get all buses', () => {
      const buses = console.getAllBuses()

      expect(Array.isArray(buses)).toBe(true)
      expect(buses.length).toBeGreaterThan(0)
      expect(buses.every(bus => bus.id)).toBe(true)
    })
  })

  describe('Channel Routing to Buses', () => {
    let testChannel: ChannelStrip

    beforeEach(() => {
      testChannel = {
        id: 'channel-test',
        name: 'Test Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [],
        sends: [],
        outputBus: 'bus-master'
      }

      console.addChannel(testChannel)
    })

    it('should route channel to bus', () => {
      console.routeChannelToBus('channel-test', 'bus-reverb-1')

      const reverbBus = console.getBus('bus-reverb-1')
      expect(reverbBus?.channels).toContain('channel-test')
    })

    it('should not duplicate channel routing', () => {
      console.routeChannelToBus('channel-test', 'bus-reverb-1')
      console.routeChannelToBus('channel-test', 'bus-reverb-1')

      const reverbBus = console.getBus('bus-reverb-1')
      const occurrences = reverbBus?.channels.filter(id => id === 'channel-test').length

      expect(occurrences).toBe(1)
    })

    it('should throw error when routing to non-existent bus', () => {
      expect(() => {
        console.routeChannelToBus('channel-test', 'bus-nonexistent')
      }).toThrow()
    })

    it('should unroute channel from bus', () => {
      console.routeChannelToBus('channel-test', 'bus-reverb-1')
      console.unrouteChannelFromBus('channel-test', 'bus-reverb-1')

      const reverbBus = console.getBus('bus-reverb-1')
      expect(reverbBus?.channels).not.toContain('channel-test')
    })

    it('should route channel to multiple buses', () => {
      console.routeChannelToBus('channel-test', 'bus-reverb-1')
      console.routeChannelToBus('channel-test', 'bus-delay-1')

      const reverbBus = console.getBus('bus-reverb-1')
      const delayBus = console.getBus('bus-delay-1')

      expect(reverbBus?.channels).toContain('channel-test')
      expect(delayBus?.channels).toContain('channel-test')
    })
  })

  describe('Bus Sends', () => {
    it('should add send from one bus to another', () => {
      console.addBusSend('bus-reverb-1', 'bus-delay-1', 0.5)

      const reverbBus = console.getBus('bus-reverb-1')
      expect(reverbBus?.sends.length).toBeGreaterThan(0)

      const send = reverbBus?.sends.find(s => s.bus === 'bus-delay-1')
      expect(send?.amount).toBe(0.5)
    })

    it('should update existing send amount', () => {
      console.addBusSend('bus-reverb-1', 'bus-delay-1', 0.3)
      console.addBusSend('bus-reverb-1', 'bus-delay-1', 0.6)

      const reverbBus = console.getBus('bus-reverb-1')
      const send = reverbBus?.sends.find(s => s.bus === 'bus-delay-1')

      expect(send?.amount).toBe(0.6)
      expect(reverbBus?.sends.length).toBe(1)
    })

    it('should remove bus send', () => {
      console.addBusSend('bus-reverb-1', 'bus-delay-1', 0.5)
      console.removeBusSend('bus-reverb-1', 'bus-delay-1')

      const reverbBus = console.getBus('bus-reverb-1')
      const send = reverbBus?.sends.find(s => s.bus === 'bus-delay-1')

      expect(send).toBeUndefined()
    })

    it('should throw error when adding send from non-existent bus', () => {
      expect(() => {
        console.addBusSend('bus-nonexistent', 'bus-delay-1', 0.5)
      }).toThrow()
    })

    it('should throw error when adding send to non-existent bus', () => {
      expect(() => {
        console.addBusSend('bus-reverb-1', 'bus-nonexistent', 0.5)
      }).toThrow()
    })
  })

  describe('Channel Management', () => {
    let testChannel: ChannelStrip

    beforeEach(() => {
      testChannel = {
        id: 'channel-test',
        name: 'Test Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [],
        sends: [],
        outputBus: 'bus-master'
      }
    })

    it('should remove channel from all buses when deleted', () => {
      console.addChannel(testChannel)
      console.routeChannelToBus('channel-test', 'bus-reverb-1')
      console.routeChannelToBus('channel-test', 'bus-delay-1')

      console.removeChannel('channel-test')

      const reverbBus = console.getBus('bus-reverb-1')
      const delayBus = console.getBus('bus-delay-1')

      expect(reverbBus?.channels).not.toContain('channel-test')
      expect(delayBus?.channels).not.toContain('channel-test')
    })

    it('should duplicate channel with new ID', () => {
      console.addChannel(testChannel)
      const duplicate = console.duplicateChannel('channel-test')

      expect(duplicate.id).not.toBe('channel-test')
      expect(duplicate.name).toBe('Test Channel (copy)')
      expect(console.getChannel(duplicate.id)).toBeDefined()
    })

    it('should throw error when duplicating non-existent channel', () => {
      expect(() => {
        console.duplicateChannel('channel-nonexistent')
      }).toThrow()
    })
  })

  describe('Serialization', () => {
    it('should serialize and deserialize console with buses', () => {
      const testChannel: ChannelStrip = {
        id: 'channel-test',
        name: 'Test Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [],
        sends: [],
        outputBus: 'bus-master'
      }

      console.addChannel(testChannel)
      console.routeChannelToBus('channel-test', 'bus-reverb-1')

      const json = console.toJSON()
      const restoredConsole = MixingConsole.fromJSON(json)

      expect(restoredConsole.getAllBuses().length).toBe(console.getAllBuses().length)
      expect(restoredConsole.getChannel('channel-test')).toBeDefined()

      const reverbBus = restoredConsole.getBus('bus-reverb-1')
      expect(reverbBus?.channels).toContain('channel-test')
    })
  })
})

describe('MixingPresetManager', () => {
  let console: MixingConsole
  let presetManager: MixingPresetManager

  beforeEach(() => {
    console = new MixingConsole()
    presetManager = new MixingPresetManager(console)
  })

  describe('Preset Initialization', () => {
    it('should initialize with built-in presets', () => {
      const presets = presetManager.getAllPresets()

      expect(presets.length).toBeGreaterThan(10)
    })

    it('should have vocal presets', () => {
      const vocalPresets = presetManager.getPresetsByCategory(PresetCategory.VOCAL)

      expect(vocalPresets.length).toBeGreaterThan(0)
      expect(vocalPresets.some(p => p.name === 'Lead Vocal')).toBe(true)
    })

    it('should have drum presets', () => {
      const drumPresets = presetManager.getPresetsByCategory(PresetCategory.DRUMS)

      expect(drumPresets.length).toBeGreaterThan(0)
      expect(drumPresets.some(p => p.name === 'Drum Kit')).toBe(true)
    })

    it('should have bass presets', () => {
      const bassPresets = presetManager.getPresetsByCategory(PresetCategory.BASS)

      expect(bassPresets.length).toBeGreaterThan(0)
      expect(bassPresets.some(p => p.name === 'Electric Bass')).toBe(true)
    })

    it('should have guitar presets', () => {
      const guitarPresets = presetManager.getPresetsByCategory(PresetCategory.GUITAR)

      expect(guitarPresets.length).toBeGreaterThan(0)
      expect(guitarPresets.some(p => p.name === 'Acoustic Guitar')).toBe(true)
    })

    it('should have keyboard presets', () => {
      const keyboardPresets = presetManager.getPresetsByCategory(PresetCategory.KEYBOARD)

      expect(keyboardPresets.length).toBeGreaterThan(0)
      expect(keyboardPresets.some(p => p.name === 'Piano')).toBe(true)
    })

    it('should have strings presets', () => {
      const stringsPresets = presetManager.getPresetsByCategory(PresetCategory.STRINGS)

      expect(stringsPresets.length).toBeGreaterThan(0)
      expect(stringsPresets.some(p => p.name === 'String Section')).toBe(true)
    })

    it('should have synth presets', () => {
      const synthPresets = presetManager.getPresetsByCategory(PresetCategory.SYNTH)

      expect(synthPresets.length).toBeGreaterThan(0)
      expect(synthPresets.some(p => p.name === 'Synth Pad')).toBe(true)
    })

    it('should have FX presets', () => {
      const fxPresets = presetManager.getPresetsByCategory(PresetCategory.FX)

      expect(fxPresets.length).toBeGreaterThan(0)
      expect(fxPresets.some(p => p.name === 'Ambient FX')).toBe(true)
    })
  })

  describe('Preset Application', () => {
    let testChannel: ChannelStrip

    beforeEach(() => {
      testChannel = {
        id: 'channel-test',
        name: 'Test Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [],
        sends: [],
        outputBus: 'bus-master'
      }

      console.addChannel(testChannel)
    })

    it('should apply vocal preset to channel', () => {
      presetManager.applyPreset('channel-test', 'preset-vocal-lead')

      const channel = console.getChannel('channel-test')
      expect(channel?.inserts.length).toBeGreaterThan(0)
      expect(channel?.sends.length).toBeGreaterThan(0)
    })

    it('should apply drum preset to channel', () => {
      presetManager.applyPreset('channel-test', 'preset-drums-kit')

      const channel = console.getChannel('channel-test')
      expect(channel?.inserts.length).toBeGreaterThan(0)
    })

    it('should throw error when applying non-existent preset', () => {
      expect(() => {
        presetManager.applyPreset('channel-test', 'preset-nonexistent')
      }).toThrow()
    })

    it('should throw error when applying preset to non-existent channel', () => {
      expect(() => {
        presetManager.applyPreset('channel-nonexistent', 'preset-vocal-lead')
      }).toThrow()
    })

    it('should replace existing inserts when applying preset', () => {
      const initialInsert = {
        id: 'insert-initial',
        enabled: true,
        effect: 'reverb',
        parameters: {}
      }

      testChannel.inserts.push(initialInsert)
      presetManager.applyPreset('channel-test', 'preset-vocal-lead')

      const channel = console.getChannel('channel-test')
      expect(channel?.inserts.some(i => i.id === 'insert-initial')).toBe(false)
    })
  })

  describe('Preset Search', () => {
    it('should search presets by name', () => {
      const results = presetManager.searchPresets('vocal')

      expect(results.length).toBeGreaterThan(0)
      expect(results.every(p => p.name.toLowerCase().includes('vocal'))).toBe(true)
    })

    it('should search presets by tag', () => {
      const results = presetManager.searchPresets('bright')

      expect(results.length).toBeGreaterThan(0)
      expect(results.every(p => p.tags.some(t => t.includes('bright')))).toBe(true)
    })

    it('should search presets by description', () => {
      const results = presetManager.searchPresets('warm')

      expect(results.length).toBeGreaterThan(0)
    })

    it('should return empty array for non-matching search', () => {
      const results = presetManager.searchPresets('xyznonexistent')
      expect(results).toEqual([])
    })
  })

  describe('Custom Presets', () => {
    let testChannel: ChannelStrip

    beforeEach(() => {
      testChannel = {
        id: 'channel-test',
        name: 'Test Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [
          {
            id: 'insert-custom',
            enabled: true,
            effect: 'reverb',
            parameters: { roomSize: 0.8, damping: 0.5 }
          }
        ],
        sends: [
          { id: 'send-custom', bus: 'bus-reverb-1', amount: 0.4, prePost: 'post' }
        ],
        outputBus: 'bus-master'
      }

      console.addChannel(testChannel)
    })

    it('should save custom preset from channel', () => {
      const customPreset = presetManager.savePreset(
        'channel-test',
        'My Custom Preset',
        PresetCategory.CUSTOM,
        'My awesome preset'
      )

      expect(customPreset.name).toBe('My Custom Preset')
      expect(customPreset.category).toBe(PresetCategory.CUSTOM)
      expect(customPreset.description).toBe('My awesome preset')
      expect(customPreset.inserts.length).toBe(1)
      expect(customPreset.config.inserts[0].effect).toBe('reverb')
    })

    it('should retrieve custom preset after saving', () => {
      const customPreset = presetManager.savePreset(
        'channel-test',
        'My Custom Preset',
        PresetCategory.CUSTOM
      )

      const retrieved = presetManager.getPreset(customPreset.id)
      expect(retrieved).toBeDefined()
      expect(retrieved?.name).toBe('My Custom Preset')
    })

    it('should apply custom preset to another channel', () => {
      const customPreset = presetManager.savePreset(
        'channel-test',
        'My Custom Preset',
        PresetCategory.CUSTOM
      )

      const anotherChannel: ChannelStrip = {
        id: 'channel-another',
        name: 'Another Channel',
        type: 'audio',
        volume: 0.75,
        pan: 0,
        isMuted: false,
        isSolo: false,
        levelL: -60,
        levelR: -60,
        peakL: -60,
        peakR: -60,
        inserts: [],
        sends: [],
        outputBus: 'bus-master'
      }

      console.addChannel(anotherChannel)
      presetManager.applyPreset('channel-another', customPreset.id)

      const channel = console.getChannel('channel-another')
      expect(channel?.inserts.length).toBeGreaterThan(0)
      expect(channel?.inserts[0].effect).toBe('reverb')
    })

    it('should throw error when saving preset from non-existent channel', () => {
      expect(() => {
        presetManager.savePreset('channel-nonexistent', 'My Preset', PresetCategory.CUSTOM)
      }).toThrow()
    })
  })

  describe('Preset Management', () => {
    it('should add custom preset', () => {
      const customPreset = {
        id: 'preset-custom-test',
        name: 'Test Preset',
        category: PresetCategory.CUSTOM,
        description: 'Test description',
        config: {
          type: 'audio' as const,
          eqEnabled: false,
          eqBands: [],
          compressionEnabled: false,
          compressionThreshold: -20,
          compressionRatio: 2,
          compressionAttack: 10,
          compressionRelease: 100,
          inserts: [],
          sends: []
        },
        icon: 'test',
        color: '#000000',
        tags: ['test']
      }

      presetManager.addPreset(customPreset)
      const retrieved = presetManager.getPreset('preset-custom-test')

      expect(retrieved).toBeDefined()
      expect(retrieved?.name).toBe('Test Preset')
    })

    it('should remove preset', () => {
      const customPreset = {
        id: 'preset-custom-removable',
        name: 'Removable Preset',
        category: PresetCategory.CUSTOM,
        description: 'Test',
        config: {
          type: 'audio' as const,
          eqEnabled: false,
          eqBands: [],
          compressionEnabled: false,
          compressionThreshold: -20,
          compressionRatio: 2,
          compressionAttack: 10,
          compressionRelease: 100,
          inserts: [],
          sends: []
        },
        icon: 'test',
        color: '#000000',
        tags: []
      }

      presetManager.addPreset(customPreset)
      expect(presetManager.getPreset('preset-custom-removable')).toBeDefined()

      presetManager.removePreset('preset-custom-removable')
      expect(presetManager.getPreset('preset-custom-removable')).toBeUndefined()
    })
  })

  describe('Preset Serialization', () => {
    it('should export presets to JSON', () => {
      const json = presetManager.exportPresets()

      expect(json).toBeDefined()
      expect(json.presets).toBeDefined()
      expect(Array.isArray(json.presets)).toBe(true)
    })

    it('should import presets from JSON', () => {
      const customPreset = {
        id: 'preset-custom-import',
        name: 'Import Test',
        category: PresetCategory.CUSTOM,
        description: 'Test',
        config: {
          type: 'audio' as const,
          eqEnabled: false,
          eqBands: [],
          compressionEnabled: false,
          compressionThreshold: -20,
          compressionRatio: 2,
          compressionAttack: 10,
          compressionRelease: 100,
          inserts: [],
          sends: []
        },
        icon: 'test',
        color: '#000000',
        tags: []
      }

      presetManager.addPreset(customPreset)
      const json = presetManager.exportPresets()

      const newManager = new MixingPresetManager(new MixingConsole())
      newManager.importPresets(json)

      const imported = newManager.getPreset('preset-custom-import')
      expect(imported).toBeDefined()
      expect(imported?.name).toBe('Import Test')
    })
  })
})
