-- Migration 001: Create autosaves table
-- This migration creates the autosaves table for auto-save functionality

-- Create autosaves table
CREATE TABLE IF NOT EXISTS autosaves (
  id TEXT PRIMARY KEY,
  song_id TEXT NOT NULL,
  song_json TEXT NOT NULL,
  timestamp REAL NOT NULL,
  description TEXT NOT NULL,
  FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- Create index on song_id for faster queries
CREATE INDEX IF NOT EXISTS idx_autosaves_song_id
ON autosaves(song_id);

-- Create index on timestamp for sorting
CREATE INDEX IF NOT EXISTS idx_autosaves_timestamp
ON autosaves(timestamp DESC);

-- Create composite index for song + timestamp queries
CREATE INDEX IF NOT EXISTS idx_autosaves_song_timestamp
ON autosaves(song_id, timestamp DESC);

-- Add comments for documentation
COMMENT ON TABLE autosaves IS 'Auto-saved song states for data loss prevention';
COMMENT ON COLUMN autosaves.id IS 'Unique identifier for this autosave';
COMMENT ON COLUMN autosaves.song_id IS 'ID of the song this autosave is for';
COMMENT ON COLUMN autosaves.song_json IS 'Song state serialized as JSON';
COMMENT ON COLUMN autosaves.timestamp IS 'Unix timestamp when autosave was created';
COMMENT ON COLUMN autosaves.description IS 'Human-readable description of autosave';
