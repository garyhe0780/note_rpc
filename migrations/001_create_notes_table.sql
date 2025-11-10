-- Migration: Create notes table
-- Description: Initial schema for notes storage
-- Date: 2025-11-09

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id VARCHAR(36) PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Create index for sorting by creation date
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- Create full-text search index for title and content
CREATE INDEX IF NOT EXISTS idx_notes_search 
ON notes USING gin(to_tsvector('english', title || ' ' || content));

-- Add comments for documentation
COMMENT ON TABLE notes IS 'Stores user notes with full-text search capabilities';
COMMENT ON COLUMN notes.id IS 'Unique identifier (UUID v4)';
COMMENT ON COLUMN notes.title IS 'Note title (max 200 characters recommended)';
COMMENT ON COLUMN notes.content IS 'Note content (max 10000 characters recommended)';
COMMENT ON COLUMN notes.created_at IS 'Timestamp when note was created';
COMMENT ON COLUMN notes.updated_at IS 'Timestamp when note was last updated';
