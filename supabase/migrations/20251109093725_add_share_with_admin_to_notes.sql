/*
  # Add share_with_admin column to notes table

  1. Changes
    - Add `share_with_admin` boolean column to `notes` table
    - Defaults to false (private note)
    - When true, note is visible to admin in management interface
  
  2. Purpose
    - Allow students to optionally share their notes with admin
    - Enables admin to see which students need help or have questions
    - Maintains student privacy by default
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'share_with_admin'
  ) THEN
    ALTER TABLE notes ADD COLUMN share_with_admin boolean DEFAULT false;
  END IF;
END $$;