{
  "name": "Aphex Snare Hell",
  "instrument": "DrumMachine",
  "instrumentType": "Drum Machine / IDM Breakbeat",
  "bpm": 172,
  "key": "C",
  "duration": "2:30",
  "difficulty": "Advanced",

  "description": "Aggressive Aphex Twin-style drill'n'bass with chaotic snare rolls and micro-bursts",

  "features": {
    "primary": ["Drill Mode", "Burst Generation", "Grid Density", "Mutation Rate"],
    "obscure": ["Automation Lane for Compositional Drill Sequencing", "Fill Policy with Decay", "Gate Policy for Silence Gating", "Per-Step Drill Intent"]
  },

  "kit": {
    "name": "Aphex Drill Kit",
    "voices": {
      "kick": {
        "pitch": 0.7,
        "decay": 0.4,
        "click": 0.6,
        "sweep": 0.2
      },
      "snare": {
        "tone": 0.9,
        "decay": 0.3,
        "snap": 0.95,
        "noise": 0.8
      }
    }
  },

  "drill": {
    "enabled": true,
    "amount": 0.85,
    "mutationRate": 0.6,
    "chaosAmount": 0.7,
    "gridDensity": 0.8,
    "gridChaos": 0.5,
    "burstSizeMin": 4,
    "burstSizeMax": 16,
    "burstSustain": 0.3,
    "burstDecay": 0.4,
    "microTiming": 0.6,
    "swingOverride": 0.0,
    "velocityChaos": 0.5,
    "rhythmFeelMode": "Drill",
    "barsPerPhrase": 4,
    "automation": {
      "points": [
        {"bar": 8, "amount": 0.7},
        {"bar": 16, "amount": 1.0},
        {"bar": 24, "amount": 0.5},
        {"bar": 32, "amount": 0.9}
      ]
    },
    "fillPolicy": {
      "enabled": true,
      "fillLengthSteps": 2,
      "triggerChance": 0.8,
      "fillAmount": 0.9,
      "decayPerStep": 0.15
    },
    "gatePolicy": {
      "enabled": true,
      "silenceChance": 0.25,
      "burstChance": 0.6,
      "minSilentSteps": 1,
      "maxSilentSteps": 3
    }
  },

  "performance": {
    "notes": "Drill mode generates chaotic snare rolls and micro-bursts. High mutation rate (0.6) means patterns evolve quickly. Grid density (0.8) creates sub-16th note bursts. Automation lane increases drill intensity over 32 bars. Fill policy adds 2-step fills with decay. Gate policy creates silence then bursts.",
    "technique": "Start with basic pattern. Enable drill mode. Set amount to 0.85 for heavy drill. Adjust burst size (4-16 notes) for roll length. Use fill policy for automatic fills. Gate policy creates tension with silence.",
    "phrasing": "Bars 1-8: Basic pattern with drill. Bar 8: Fill increases. Bars 9-16: Maximum chaos. Bar 16: Fill. Bars 17-24: Decrease drill. Bars 25-32: Build back up. Automation controls overall amount curve."
  },

  "pattern": {
    "length": 16,
    "swing": 0.5,
    "tracks": [
      {
        "index": 1,
        "type": "Snare",
        "timing_role": "Push",
        "volume": 0.9,
        "pan": 0.0,
        "pitch": 0,
        "drill_override": {
          "use_override": true,
          "enabled": true,
          "amount": 0.9,
          "mutationRate": 0.7,
          "chaosAmount": 0.8,
          "gridDensity": 0.9,
          "gridChaos": 0.6,
          "burstSizeMin": 8,
          "burstSizeMax": 20,
          "burstSustain": 0.2,
          "burstDecay": 0.3,
          "microTiming": 0.7,
          "swingOverride": 0.0,
          "velocityChaos": 0.6
        },
        "steps": [
          {"step": 4, "active": true, "velocity": 120, "probability": 1.0, "use_drill": true, "burst_count": 16, "burst_chaos": 0.8, "burst_dropout": 0.1, "drill_intent": 0.9},
          {"step": 12, "active": true, "velocity": 115, "probability": 1.0, "use_drill": true, "burst_count": 12, "burst_chaos": 0.7, "burst_dropout": 0.15, "drill_intent": 0.85}
        ]
      }
    ]
  },

  "audioCharacteristics": {
    "frequencyRange": "40 Hz (kick) - 15 kHz (snare bursts)",
    "stereoPlacement": "Wide stereo with chaotic bursts",
    "dynamics": "Highly variable, from silence to dense rolls",
    "timbre": "Aggressive, chaotic, complex, evolving"
  },

  "whyThisSong": {
    "educational": "Demonstrates Drum Machine's most advanced feature: Drill Mode",
    "showcase": "Shows complete drill system with 13 parameters per track",
    "obscure": "Automation lane for compositional control of drill intensity",
    "creative": "Fill policy and gate policy create dynamic tension/release"
  },

  "drillModeExplained": {
    "what": "Drill mode generates chaotic breakbeat patterns inspired by Aphex Twin and Venetian Snares",
    "how": "Uses 13 parameters to control burst generation, mutation, chaos, and timing",
    "coreParams": "Amount (intensity), MutationRate (evolution speed), ChaosAmount (randomization), GridDensity (sub-division)",
    "burstParams": "BurstSizeMin/Max (roll length), BurstSustain (duration), BurstDecay (amplitude decay)",
    "timingParams": "MicroTiming (timing deviation), SwingOverride, VelocityChaos",
    "automation": "Automation lane allows compositional sequencing of drill amount over time",
    "fillPolicy": "Automatically generates fills with adjustable length and decay",
    "gatePolicy": "Creates silent runs that explode into bursts for tension"
  },

  "implementation": {
    "swift": "let assignment = InstrumentAssignment(\n    name: \"Aphex Drill\",\n    type: .drums,\n    channel: 10,\n    plugin: PluginInfo(\n        id: \"DrumMachine\",\n        name: \"Schill Drum Machine\",\n        manufacturer: \"Schillinger Ecosystem\",\n        parameters: [\n            \"drill.enabled\": true,\n            \"drill.amount\": 0.85,\n            \"drill.mutationRate\": 0.6,\n            \"drill.chaosAmount\": 0.7,\n            \"drill.gridDensity\": 0.8,\n            \"drill.burstSizeMin\": 4,\n            \"drill.burstSizeMax\": 16\n        ]\n    )\n)\n\ntry manager.assignInstrument(trackId: \"drums\", instrument: assignment)\n\n// Load drill preset\nif let juceInstrument = manager.getJUCEInstrument(trackId: \"drums\") {\n    try juceInstrument.loadPreset(\"02_Aphex_Snare_Hell\")\n}",
    "midi": "Channel 10: Drill mode generates patterns automatically. Use automation to control drill amount over time."
  },

  "advancedTechniques": [
    "Use per-step drill intent to control which steps want more drill",
    "Per-track drill override allows different drill settings per drum voice",
    "Automation lane creates song structures with varying drill intensity",
    "Fill policy adds variety with automatic fills and decay",
    "Gate policy creates tension with sudden silence and explosive bursts",
    "Combine all three policies (drill + fill + gate) for maximum chaos"
  ],

  "drillPresets": [
    "01_Drill_Lite - Subtle variation (140 BPM)",
    "02_Aphex_Snare_Hell - Aggressive drill (172 BPM)"
  ],

  "tags": ["drums", "IDM", "drill", "breakbeat", "aphex twin", "chaos", "bursts", "advanced", "automation"]
}
