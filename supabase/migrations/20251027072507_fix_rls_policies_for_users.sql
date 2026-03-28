/*
  # Fix RLS Policies for Users Table

  1. Changes
    - Drop all existing policies on users table
    - Create new simple policies that work with anon role
    - Grant all permissions to anon and authenticated roles
  
  2. Security Note
    - These are permissive policies for development
    - In production, should restrict based on authenticated users
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "Anyone can read users" ON users;
DROP POLICY IF EXISTS "Anyone can create users" ON users;
DROP POLICY IF EXISTS "Users can update themselves" ON users;
DROP POLICY IF EXISTS "Anyone can delete users" ON users;

-- Grant table permissions
GRANT ALL ON users TO anon, authenticated;
GRANT ALL ON lessons TO anon, authenticated;
GRANT ALL ON lines TO anon, authenticated;
GRANT ALL ON progress TO anon, authenticated;
GRANT ALL ON notes TO anon, authenticated;
GRANT ALL ON speech_attempts TO anon, authenticated;

-- Create new policies that definitely work
CREATE POLICY "Enable read for all users"
  ON users FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Enable insert for all users"
  ON users FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Enable update for all users"
  ON users FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable delete for all users"
  ON users FOR DELETE
  TO anon, authenticated
  USING (true);
