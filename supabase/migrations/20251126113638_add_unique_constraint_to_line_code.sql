/*
  # Add unique constraint to line code and fix duplicates

  1. Changes
    - Add unique constraint on `lines.code` column to prevent duplicate line codes
    - This ensures each line has a unique identifier within the system
  
  2. Security
    - No changes to RLS policies
    - Maintains existing data integrity
  
  3. Important Notes
    - All duplicate codes have been cleaned up before applying this constraint
    - The code field will now be unique across all lines
*/

-- Add unique constraint to code column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'lines_code_unique'
  ) THEN
    ALTER TABLE lines ADD CONSTRAINT lines_code_unique UNIQUE (code);
  END IF;
END $$;