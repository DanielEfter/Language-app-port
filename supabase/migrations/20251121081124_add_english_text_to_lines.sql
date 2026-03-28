/*
  # Add English text field to lines table

  1. Changes
    - Add `text_en` column to `lines` table for English translations
    - Column is optional (nullable) for backward compatibility
  
  2. Notes
    - Existing lines will have NULL for text_en
    - New lines can include English translations
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lines' AND column_name = 'text_en'
  ) THEN
    ALTER TABLE lines ADD COLUMN text_en text DEFAULT '';
  END IF;
END $$;
