/**
 * Mixing Console Presets System
 *
 * Professional preset management for channel strip configurations
 */

import { MixingConsole, ChannelStrip, InsertSlot, Send } from './MixingConsole'

/**
 * EQ band configuration
 */
export interface EQBand {
  frequency: number
  gain: number
  q: number
}

/**
 * Preset categories for organization
 */
export enum PresetCategory {
  VOCAL = 'vocal',
  DRUMS = 'drums',
  BASS = 'bass',
  GUITAR = 'guitar',
  KEYBOARD = 'keyboard',
  STRINGS = 'strings',
  BRASS = 'brass',
  WOODWINDS = 'woodwinds',
  SYNTH = 'synth',
  FX = 'fx',
  CUSTOM = 'custom'
}

/**
 * Channel strip configuration for presets
 */
export interface ChannelStripConfig {
  type: 'audio' | 'midi' | 'bus' | 'master'

  // EQ settings
  eqEnabled: boolean
  eqBands: EQBand[]

  // Compression
  compressionEnabled: boolean
  compressionThreshold: number
  compressionRatio: number
  compressionAttack: number
  compressionRelease: number

  // Inserts (pre-loaded effects)
  inserts: InsertSlot[]

  // Sends (pre-configured routing)
  sends: Send[]
}

/**
 * Channel strip preset
 */
export interface ChannelStripPreset {
  id: string
  name: string
  category: PresetCategory
  description: string

  // Channel configuration
  config: ChannelStripConfig

  // Icon/Color for UI
  icon: string
  color: string

  // Tags for search
  tags: string[]
}

/**
 * Preset manager for mixing console
 */
export class MixingPresetManager {
  private presets: Map<string, ChannelStripPreset>
  private console: MixingConsole

  constructor(console: MixingConsole) {
    this.presets = new Map()
    this.console = console
    this.initializeDefaultPresets()
  }

  /**
   * Initialize built-in presets
   */
  private initializeDefaultPresets(): void {
    // Vocal presets
    this.addPreset({
      id: 'preset-vocal-lead',
      name: 'Lead Vocal',
      category: PresetCategory.VOCAL,
      description: 'Bright lead vocal with presence and air',
      icon: 'mic.fill',
      color: '#FF6B6B',
      tags: ['vocal', 'lead', 'bright', 'presence'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 120, gain: -3, q: 0.7 },  // Low cut
          { frequency: 1000, gain: 2, q: 1.0 }, // Presence
          { frequency: 5000, gain: 4, q: 1.5 }  // Air
        ],
        compressionEnabled: true,
        compressionThreshold: -18,
        compressionRatio: 3,
        compressionAttack: 10,
        compressionRelease: 100,
        inserts: [
          {
            id: 'insert-compressor',
            enabled: true,
            effect: 'compressor',
            parameters: { threshold: -18, ratio: 3, attack: 10, release: 100 }
          }
        ],
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.3, prePost: 'post' }
        ]
      }
    })

    this.addPreset({
      id: 'preset-vocal-backing',
      name: 'Backing Vocal',
      category: PresetCategory.VOCAL,
      description: 'Warm backing vocal with reverb',
      icon: 'mic.fill',
      color: '#FF8787',
      tags: ['vocal', 'backing', 'warm', 'reverb'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: 2, q: 0.7 },  // Warmth
          { frequency: 3000, gain: 1, q: 1.0 }, // Presence
          { frequency: 8000, gain: -2, q: 1.0 } // Reduce harshness
        ],
        compressionEnabled: true,
        compressionThreshold: -20,
        compressionRatio: 4,
        compressionAttack: 15,
        compressionRelease: 80,
        inserts: [],
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.5, prePost: 'post' },
          { id: 'send-delay', bus: 'bus-delay-1', amount: 0.2, prePost: 'post' }
        ]
      }
    })

    // Drums presets
    this.addPreset({
      id: 'preset-drums-kit',
      name: 'Drum Kit',
      category: PresetCategory.DRUMS,
      description: 'Punchy drum kit with room reverb',
      icon: 'drum.fill',
      color: '#4ECDC4',
      tags: ['drums', 'punchy', 'room'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 100, gain: 6, q: 0.5 },  // Bottom
          { frequency: 2000, gain: 3, q: 1.0 }, // Attack
          { frequency: 8000, gain: -2, q: 1.0 } // Sizzle
        ],
        compressionEnabled: true,
        compressionThreshold: -12,
        compressionRatio: 4,
        compressionAttack: 5,
        compressionRelease: 50,
        sends: [
          { id: 'send-room', bus: 'bus-reverb-1', amount: 0.2, prePost: 'post' }
        ]
      }
    })

    this.addPreset({
      id: 'preset-drums-snare',
      name: 'Snare Drum',
      category: PresetCategory.DRUMS,
      description: 'Crack and body for snare drum',
      icon: 'speaker.wave.2.fill',
      color: '#45B7D1',
      tags: ['drums', 'snare', 'crack'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: 4, q: 0.7 },  // Body
          { frequency: 1000, gain: 2, q: 1.0 }, // Crack
          { frequency: 6000, gain: 3, q: 1.5 }  // Snap
        ],
        compressionEnabled: true,
        compressionThreshold: -15,
        compressionRatio: 4,
        compressionAttack: 5,
        compressionRelease: 40,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.25, prePost: 'post' }
        ]
      }
    })

    // Bass presets
    this.addPreset({
      id: 'preset-bass-electric',
      name: 'Electric Bass',
      category: PresetCategory.BASS,
      description: 'Warm electric bass with compression',
      icon: 'speaker.wave.2.fill',
      color: '#45B7D1',
      tags: ['bass', 'warm', 'compressed'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 80, gain: 4, q: 0.7 },   // Low end
          { frequency: 400, gain: -2, q: 1.0 }, // Mud reduction
          { frequency: 1500, gain: 2, q: 1.0 }  // Presence
        ],
        compressionEnabled: true,
        compressionThreshold: -15,
        compressionRatio: 4,
        compressionAttack: 5,
        compressionRelease: 50,
        sends: []
      }
    })

    this.addPreset({
      id: 'preset-bass-synth',
      name: 'Synth Bass',
      category: PresetCategory.BASS,
      description: 'Punchy synth bass with sub',
      icon: 'waveform.path',
      color: '#9B59B6',
      tags: ['bass', 'synth', 'sub', 'punchy'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 60, gain: 6, q: 0.5 },  // Sub
          { frequency: 800, gain: 3, q: 1.0 }, // Punch
          { frequency: 3000, gain: -3, q: 1.0 } // Clean up
        ],
        compressionEnabled: true,
        compressionThreshold: -12,
        compressionRatio: 5,
        compressionAttack: 3,
        compressionRelease: 30,
        sends: []
      }
    })

    // Guitar presets
    this.addPreset({
      id: 'preset-guitar-acoustic',
      name: 'Acoustic Guitar',
      category: PresetCategory.GUITAR,
      description: 'Natural acoustic guitar with sparkle',
      icon: 'guitar',
      color: '#F39C12',
      tags: ['guitar', 'acoustic', 'natural'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: -3, q: 0.7 }, // Reduce boom
          { frequency: 1000, gain: 2, q: 1.0 }, // Body
          { frequency: 8000, gain: 4, q: 1.5 }  // Sparkle
        ],
        compressionEnabled: true,
        compressionThreshold: -20,
        compressionRatio: 3,
        compressionAttack: 10,
        compressionRelease: 80,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.15, prePost: 'post' }
        ]
      }
    })

    this.addPreset({
      id: 'preset-guitar-electric',
      name: 'Electric Guitar',
      category: PresetCategory.GUITAR,
      description: 'Crunchy electric guitar',
      icon: 'guitar',
      color: '#E74C3C',
      tags: ['guitar', 'electric', 'crunch'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 150, gain: 4, q: 0.7 },  // Low end
          { frequency: 1500, gain: 3, q: 1.0 }, // Mid range
          { frequency: 5000, gain: 2, q: 1.0 }  // Presence
        ],
        compressionEnabled: true,
        compressionThreshold: -10,
        compressionRatio: 4,
        compressionAttack: 5,
        compressionRelease: 40,
        sends: []
      }
    })

    // Keyboard presets
    this.addPreset({
      id: 'preset-keyboard-piano',
      name: 'Piano',
      category: PresetCategory.KEYBOARD,
      description: 'Grand piano with natural resonance',
      icon: 'pianokeys',
      color: '#3498DB',
      tags: ['keyboard', 'piano', 'natural'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 100, gain: 3, q: 0.5 },  // Low end
          { frequency: 1000, gain: 2, q: 1.0 }, // Body
          { frequency: 6000, gain: 3, q: 1.5 }  // Clarity
        ],
        compressionEnabled: true,
        compressionThreshold: -18,
        compressionRatio: 2.5,
        compressionAttack: 15,
        compressionRelease: 100,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.2, prePost: 'post' }
        ]
      }
    })

    // Strings presets
    this.addPreset({
      id: 'preset-strings-section',
      name: 'String Section',
      category: PresetCategory.STRINGS,
      description: 'Lush string section with reverb',
      icon: 'music.note',
      color: '#E8B4B8',
      tags: ['strings', 'lush', 'orchestral'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 300, gain: 3, q: 0.7 },  // Warmth
          { frequency: 2000, gain: 2, q: 1.0 }, // Presence
          { frequency: 8000, gain: 4, q: 1.5 }  // Air
        ],
        compressionEnabled: true,
        compressionThreshold: -15,
        compressionRatio: 2,
        compressionAttack: 20,
        compressionRelease: 100,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.4, prePost: 'post' }
        ]
      }
    })

    // Synth presets
    this.addPreset({
      id: 'preset-synth-pad',
      name: 'Synth Pad',
      category: PresetCategory.SYNTH,
      description: 'Warm ambient pad with delay',
      icon: 'waveform.path',
      color: '#9B59B6',
      tags: ['synth', 'pad', 'ambient'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: 4, q: 0.7 },  // Warmth
          { frequency: 2000, gain: 2, q: 1.0 }, // Body
          { frequency: 6000, gain: -2, q: 1.0 } // Smooth
        ],
        compressionEnabled: true,
        compressionThreshold: -12,
        compressionRatio: 3,
        compressionAttack: 20,
        compressionRelease: 100,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.5, prePost: 'post' },
          { id: 'send-delay', bus: 'bus-delay-1', amount: 0.3, prePost: 'post' }
        ]
      }
    })

    this.addPreset({
      id: 'preset-synth-lead',
      name: 'Synth Lead',
      category: PresetCategory.SYNTH,
      description: 'Bright cutting lead synth',
      icon: 'waveform.path',
      color: '#8E44AD',
      tags: ['synth', 'lead', 'bright'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: -2, q: 0.7 }, // Clean up
          { frequency: 2000, gain: 4, q: 1.0 }, // Presence
          { frequency: 6000, gain: 5, q: 1.5 }  // Bite
        ],
        compressionEnabled: true,
        compressionThreshold: -10,
        compressionRatio: 4,
        compressionAttack: 5,
        compressionRelease: 30,
        sends: []
      }
    })

    // FX presets
    this.addPreset({
      id: 'preset-fx-ambient',
      name: 'Ambient FX',
      category: PresetCategory.FX,
      description: 'Atmospheric sound design with heavy reverb',
      icon: 'sparkles',
      color: '#16A085',
      tags: ['fx', 'ambient', 'atmospheric'],
      config: {
        type: 'audio',
        eqEnabled: true,
        eqBands: [
          { frequency: 200, gain: 4, q: 0.7 },  // Warmth
          { frequency: 2000, gain: 2, q: 1.0 }, // Body
          { frequency: 8000, gain: -2, q: 1.0 } // Smooth
        ],
        compressionEnabled: true,
        compressionThreshold: -15,
        compressionRatio: 3,
        compressionAttack: 20,
        compressionRelease: 100,
        sends: [
          { id: 'send-reverb', bus: 'bus-reverb-1', amount: 0.8, prePost: 'post' },
          { id: 'send-delay', bus: 'bus-delay-1', amount: 0.5, prePost: 'post' }
        ]
      }
    })
  }

  /**
   * Add a preset
   */
  addPreset(preset: ChannelStripPreset): void {
    this.presets.set(preset.id, preset)
  }

  /**
   * Remove a preset
   */
  removePreset(presetId: string): void {
    this.presets.delete(presetId)
  }

  /**
   * Get a specific preset
   */
  getPreset(id: string): ChannelStripPreset | undefined {
    return this.presets.get(id)
  }

  /**
   * Get all presets
   */
  getAllPresets(): ChannelStripPreset[] {
    return Array.from(this.presets.values())
  }

  /**
   * Get presets by category
   */
  getPresetsByCategory(category: PresetCategory): ChannelStripPreset[] {
    return Array.from(this.presets.values()).filter(
      preset => preset.category === category
    )
  }

  /**
   * Search presets by tags and name
   */
  searchPresets(query: string): ChannelStripPreset[] {
    const lowerQuery = query.toLowerCase()
    return Array.from(this.presets.values()).filter(preset => {
      return preset.name.toLowerCase().includes(lowerQuery) ||
             preset.description.toLowerCase().includes(lowerQuery) ||
             preset.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
    })
  }

  /**
   * Apply preset to channel
   */
  applyPreset(channelId: string, presetId: string): void {
    const preset = this.presets.get(presetId)
    if (!preset) {
      throw new Error(`Preset ${presetId} not found`)
    }

    const channel = this.console.getChannel(channelId)
    if (!channel) {
      throw new Error(`Channel ${channelId} not found`)
    }

    // Clear existing inserts and sends
    channel.inserts = []
    channel.sends = []

    // Apply preset configuration
    channel.inserts = [...preset.config.inserts]
    channel.sends = [...preset.config.sends]

    // Apply EQ
    if (preset.config.eqEnabled) {
      channel.inserts.push({
        id: 'insert-eq',
        enabled: true,
        effect: 'eq',
        parameters: { bands: preset.config.eqBands }
      })
    }

    // Apply compression
    if (preset.config.compressionEnabled) {
      channel.inserts.push({
        id: 'insert-compressor',
        enabled: true,
        effect: 'compressor',
        parameters: {
          threshold: preset.config.compressionThreshold,
          ratio: preset.config.compressionRatio,
          attack: preset.config.compressionAttack,
          release: preset.config.compressionRelease
        }
      })
    }
  }

  /**
   * Save current channel as preset
   */
  savePreset(channelId: string, name: string, category: PresetCategory, description?: string): ChannelStripPreset {
    const channel = this.console.getChannel(channelId)
    if (!channel) {
      throw new Error(`Channel ${channelId} not found`)
    }

    const preset: ChannelStripPreset = {
      id: `preset-custom-${Date.now()}`,
      name,
      category,
      description: description || `Custom preset from ${channel.name}`,
      icon: 'slider.horizontal.3',
      color: '#95A5A6',
      tags: ['custom'],
      config: {
        type: channel.type as any,
        eqEnabled: false,
        eqBands: [],
        compressionEnabled: false,
        compressionThreshold: -20,
        compressionRatio: 2,
        compressionAttack: 10,
        compressionRelease: 100,
        inserts: channel.inserts,
        sends: channel.sends
      }
    }

    this.presets.set(preset.id, preset)
    return preset
  }

  /**
   * Export presets to JSON
   */
  exportPresets(): object {
    return {
      presets: Array.from(this.presets.entries())
    }
  }

  /**
   * Import presets from JSON
   */
  importPresets(json: any): void {
    if (json.presets) {
      json.presets.forEach(([id, preset]: [string, ChannelStripPreset]) => {
        this.presets.set(id, preset)
      })
    }
  }
}
