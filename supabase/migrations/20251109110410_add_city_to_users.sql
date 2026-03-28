/*
  # Add city field to users table

  1. Changes
    - Add `city` column to `users` table
      - Type: text
      - Nullable: true (optional field)
      - Default: empty string
    
  2. Notes
    - Allows students to specify their city/location
    - Field is optional and can be updated by admin or student
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'city'
  ) THEN
    ALTER TABLE users ADD COLUMN city text DEFAULT '';
  END IF;
END $$;
