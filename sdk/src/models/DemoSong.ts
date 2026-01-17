/**
 * Demo Song System
 *
 * Provides song selection, loading, and management for demo library.
 */

export interface DemoSongMetadata {
  /** Unique song identifier */
  id: string;

  /** Display name */
  name: string;

  /** Category: starter, showcase, advanced, converted */
  category: 'starter' | 'showcase' | 'advanced' | 'converted';

  /** Difficulty level */
  difficulty: 'beginner' | 'intermediate' | 'advanced';

  /** Key concepts demonstrated */
  focus: string[];

  /** Approximate duration in seconds */
  duration_seconds: number;

  /** Active agents for this song */
  agents: Array<'Rhythm' | 'Pitch' | 'Structure' | 'Energy' | 'Harmony'>;

  /** What makes this song interesting */
  description: string;

  /** Tips for best performance */
  performance_notes?: string;

  /** Composer/Creator */
  composer: string;

  /** Date added to library */
  date_added: string;

  /** Song number in category */
  sequence: number;
}

export interface DemoSong extends DemoSongMetadata {
  /** Full session model configuration */
  session_model: any;

  /** Optional preset evolution configuration */
  preset_evolution?: any;

  /** Path to song file */
  file_path: string;
}

export interface DemoSongLibrary {
  /** All available songs */
  songs: DemoSong[];

  /** Songs grouped by category */
  by_category: {
    starter: DemoSong[];
    showcase: DemoSong[];
    advanced: DemoSong[];
    converted: DemoSong[];
  };

  /** Songs grouped by difficulty */
  by_difficulty: {
    beginner: DemoSong[];
    intermediate: DemoSong[];
    advanced: DemoSong[];
  };
}

/**
 * Demo Song Manager
 *
 * Handles loading, filtering, and managing demo songs.
 */
export class DemoSongManager {
  private library: DemoSongLibrary | null = null;
  private currentSong: DemoSong | null = null;

  /**
   * Load all demo songs from the demo_songs directory
   */
  async loadLibrary(): Promise<DemoSongLibrary> {
    // TODO: Implement actual file loading from demo_songs/
    // For now, return empty library structure
    this.library = {
      songs: [],
      by_category: {
        starter: [],
        showcase: [],
        advanced: [],
        converted: []
      },
      by_difficulty: {
        beginner: [],
        intermediate: [],
        advanced: []
      }
    };

    return this.library;
  }

  /**
   * Get all songs in a category
   */
  getSongsByCategory(category: DemoSong['category']): DemoSong[] {
    if (!this.library) return [];
    return this.library.by_category[category];
  }

  /**
   * Get all songs at a difficulty level
   */
  getSongsByDifficulty(difficulty: DemoSong['difficulty']): DemoSong[] {
    if (!this.library) return [];
    return this.library.by_difficulty[difficulty];
  }

  /**
   * Search songs by focus/concept
   */
  searchByFocus(concept: string): DemoSong[] {
    if (!this.library) return [];
    return this.library.songs.filter(song =>
      song.focus.some(f => f.toLowerCase().includes(concept.toLowerCase()))
    );
  }

  /**
   * Load a specific song by ID
   */
  async loadSong(songId: string): Promise<DemoSong | null> {
    if (!this.library) {
      await this.loadLibrary();
    }

    const song = this.library?.songs.find(s => s.id === songId);
    if (song) {
      this.currentSong = song;
    }

    return song || null;
  }

  /**
   * Get the currently loaded song
   */
  getCurrentSong(): DemoSong | null {
    return this.currentSong;
  }

  /**
   * Get recommended next song (learning path)
   */
  getNextSong(currentSongId: string): DemoSong | null {
    if (!this.library) return null;

    const current = this.library.songs.find(s => s.id === currentSongId);
    if (!current) return null;

    // Same category, next sequence
    const next = this.library.songs.find(s =>
      s.category === current.category &&
      s.sequence === current.sequence + 1
    );

    return next || null;
  }

  /**
   * Get recommended previous song
   */
  getPreviousSong(currentSongId: string): DemoSong | null {
    if (!this.library) return null;

    const current = this.library.songs.find(s => s.id === currentSongId);
    if (!current) return null;

    // Same category, previous sequence
    const prev = this.library.songs.find(s =>
      s.category === current.category &&
      s.sequence === current.sequence - 1
    );

    return prev || null;
  }
}

/**
 * Song Selector UI Helpers
 */
export class SongSelector {
  private manager: DemoSongManager;

  constructor(manager: DemoSongManager) {
    this.manager = manager;
  }

  /**
   * Get formatted song list for UI display
   */
  async getSongList(category?: DemoSong['category']): Promise<{
    id: string;
    name: string;
    difficulty: string;
    duration: string;
    focus: string[];
  }[]> {
    await this.manager.loadLibrary();

    let songs = category
      ? this.manager.getSongsByCategory(category)
      : this.manager.loadLibrary().then(lib => lib.songs);

    return (await songs).map(song => ({
      id: song.id,
      name: song.name,
      difficulty: song.difficulty,
      duration: this.formatDuration(song.duration_seconds),
      focus: song.focus
    }));
  }

  /**
   * Format seconds to MM:SS
   */
  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * Get learning path (recommended order)
   */
  getLearningPath(): DemoSong[] {
    // Starter songs in order, then showcase, then advanced
    const manager = this.manager;
    return [
      ...manager.getSongsByCategory('starter').sort((a, b) => a.sequence - b.sequence),
      ...manager.getSongsByCategory('showcase').sort((a, b) => a.sequence - b.sequence),
      ...manager.getSongsByCategory('advanced').sort((a, b) => a.sequence - b.sequence)
    ];
  }
}
