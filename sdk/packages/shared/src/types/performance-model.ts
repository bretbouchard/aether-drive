/**
 * Performance Model Type Definitions
 *
 * Type definitions for performance state, effects, automation, and markers.
 * These types mirror the Swift PerformanceState_v1.swift model.
 *
 * @module types/performance-model
 */

// =============================================================================
// PERFORMANCE STATE
// =============================================================================

/**
 * PerformanceState_v1 - Represents a parallel performance universe
 *
 * One song can have many performances (Piano, SATB, Techno, etc.)
 */
export interface PerformanceState_v1 {
  /** Schema version */
  version: "1";

  /** Unique identifier for this performance */
  id: string;

  /** Human-readable name for this performance */
  name: string;

  /** Musical arrangement style for this performance */
  arrangementStyle: ArrangementStyle;

  /** Note density multiplier (0 = sparse, 1 = full density) */
  density?: number;

  /** Reference to groove template (straight, swing, etc.) */
  grooveProfileId?: string;

  /** Maps roles or track IDs to instrument assignments */
  instrumentationMap: Record<string, PerformanceInstrumentAssignment>;

  /** Reference to ConsoleX profile for mixing settings */
  consoleXProfileId?: string;

  /** Per-role or per-track gain/pan targets */
  mixTargets: Record<string, MixTarget>;

  // NEW FIELDS - Performance Enhancements

  /** Effects chain for this performance */
  effectsChain?: EffectPreset[];

  /** Mix console state */
  mixSettings?: MixSettings;

  /** Automation data for parameters */
  automationPoints?: AutomationPoint[];

  /** Markers and loop points */
  markers?: PerformanceMarker[];

  /** Tempo changes over time */
  tempoMap?: TempoChange[];

  /** Time signature changes over time */
  timeSignatureMap?: TimeSignatureChange[];

  /** Last play timestamp */
  lastPlayedAt?: string; // ISO 8601

  /** Play count */
  playCount?: number;

  /** Practice notes */
  practiceNotes?: string;

  /** ISO 8601 creation timestamp */
  createdAt?: string;

  /** ISO 8601 modification timestamp */
  modifiedAt?: string;

  /** Custom metadata for this performance */
  metadata?: Record<string, string>;
}

// =============================================================================
// ARRANGEMENT STYLES
// =============================================================================

/**
 * Arrangement style enumeration for musical performances
 */
export type ArrangementStyle =
  | "SOLO_PIANO"
  | "SATB"
  | "CHAMBER_ENSEMBLE"
  | "FULL_ORCHESTRA"
  | "JAZZ_COMBO"
  | "JAZZ_TRIO"
  | "ROCK_BAND"
  | "AMBIENT_TECHNO"
  | "ELECTRONIC"
  | "ACAPPELLA"
  | "STRING_QUARTET"
  | "CUSTOM";

// =============================================================================
// INSTRUMENT ASSIGNMENT
// =============================================================================

/**
 * Instrument assignment for a specific role or track
 */
export interface PerformanceInstrumentAssignment {
  /** Instrument identifier (e.g., 'LocalGal', 'KaneMarco', etc.) */
  instrumentId: string;

  /** Optional preset identifier for the instrument */
  presetId?: string;

  /** Custom instrument parameters */
  parameters?: Record<string, number>;
}

// =============================================================================
// MIX TARGET
// =============================================================================

/**
 * Mix target for a specific role or track
 */
export interface MixTarget {
  /** Gain in decibels (-inf to 0 dB) */
  gain: number;

  /** Pan position (-1 = left, 0 = center, 1 = right) */
  pan: number;

  /** Whether this target is stereo */
  stereo?: boolean;
}

// =============================================================================
// EFFECT PRESET
// =============================================================================

/**
 * Effect preset for performance effects chain
 */
export interface EffectPreset {
  /** Unique identifier */
  id: string;

  /** Preset name */
  name: string;

  /** Effect type (reverb, delay, etc.) */
  effectType: string;

  /** Effect parameters */
  parameters: Record<string, number>;

  /** Whether effect is enabled */
  enabled?: boolean;

  /** Position in effects chain */
  position?: number;
}

// =============================================================================
// MIX SETTINGS
// =============================================================================

/**
 * Mix console state for performance
 */
export interface MixSettings {
  /** Master volume (0.0 to 1.0) */
  masterVolume?: number;

  /** Master pan (-1.0 to 1.0) */
  masterPan?: number;

  /** Track volumes */
  trackVolumes?: Record<string, number>;

  /** Track pans */
  trackPans?: Record<string, number>;

  /** Track mutes */
  trackMutes?: Record<string, boolean>;

  /** Track solos */
  trackSolos?: Record<string, boolean>;
}

// =============================================================================
// AUTOMATION POINT
// =============================================================================

/**
 * Automation point for parameter automation
 */
export interface AutomationPoint {
  /** Unique identifier */
  id: string;

  /** Parameter ID to automate */
  parameterId: string;

  /** Optional track ID */
  trackId?: string;

  /** Beat position */
  beatPosition: number;

  /** Parameter value */
  value: number;

  /** Interpolation type (linear, curve, step) */
  interpolationType?: string;
}

// =============================================================================
// PERFORMANCE MARKER
// =============================================================================

/**
 * Performance marker (section markers, loop points, rehearsal marks)
 */
export interface PerformanceMarker {
  /** Unique identifier */
  id: string;

  /** Marker name */
  name: string;

  /** Beat position */
  beatPosition: number;

  /** Marker color (hex string) */
  color?: string;

  /** Marker type */
  type?: MarkerType;

  /** Loop start flag */
  loopStart?: boolean;

  /** Loop end flag */
  loopEnd?: boolean;
}

/**
 * Marker type enumeration
 */
export type MarkerType = "marker" | "section" | "rehearsal" | "cue";

// =============================================================================
// TEMPO CHANGE
// =============================================================================

/**
 * Tempo change event
 */
export interface TempoChange {
  /** Beat position */
  beatPosition: number;

  /** New tempo in BPM */
  tempo: number;

  /** Transition type */
  transition?: TempoTransition;
}

/**
 * Tempo transition type
 */
export type TempoTransition = "immediate" | "ramp" | "gradual";

// =============================================================================
// TIME SIGNATURE CHANGE
// =============================================================================

/**
 * Time signature change event
 */
export interface TimeSignatureChange {
  /** Beat position */
  beatPosition: number;

  /** Numerator (top number) */
  numerator: number;

  /** Denominator (bottom number) */
  denominator: number;
}

// =============================================================================
// VALIDATION RESULT
// =============================================================================

/**
 * Result of performance state validation
 */
export interface PerformanceValidationResult {
  /** Whether validation passed */
  isValid: boolean;

  /** Validation errors */
  errors: string[];
}
