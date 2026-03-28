-- Complete migration script generated on 2026-02-17T21:54:29.564Z

-- Start of 20251027072331_create_initial_schema.sql
/*
  # Initial Schema Setup - Italian Learning Platform

  ## New Tables Created
  
  1. **users** - User accounts (students and admins)
     - `id` (uuid, primary key)
     - `username` (text, unique)
     - `password_hash` (text)
     - `role` (text) - 'ADMIN' or 'STUDENT'
     - `is_active` (boolean) - account status
     - `current_lesson_id` (uuid) - tracks current lesson
     - `created_at` (timestamptz)
  
  2. **lessons** - Course lessons
     - `id` (uuid, primary key)
     - `index` (integer) - lesson order
     - `title` (text)
     - `description` (text)
     - `is_published` (boolean)
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)
  
  3. **lines** - Lesson content lines
     - `id` (uuid, primary key)
     - `lesson_id` (uuid, foreign key)
     - `order_num` (integer)
     - `code` (text)
     - `type` (text) - 'INFO', 'LINK', or 'LANG'
     - `text_he` (text) - Hebrew text
     - `text_it` (text) - Italian text
     - `stress_rule` (text)
     - `recording_hint` (text)
     - `created_at` (timestamptz)
  
  4. **progress** - User lesson progress
     - `id` (uuid, primary key)
     - `user_id` (uuid, foreign key)
     - `lesson_id` (uuid, foreign key)
     - `last_line_order` (integer)
     - `is_completed` (boolean)
     - `updated_at` (timestamptz)
  
  5. **notes** - User notes on lines
     - `id` (uuid, primary key)
     - `user_id` (uuid, foreign key)
     - `line_id` (uuid, foreign key)
     - `content` (text)
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)
  
  6. **speech_attempts** - Speech recognition attempts
     - `id` (uuid, primary key)
     - `user_id` (uuid, foreign key)
     - `line_id` (uuid, foreign key)
     - `transcript` (text)
     - `similarity_score` (numeric)
     - `created_at` (timestamptz)

  ## Security (RLS)
  
  - Enable RLS on all tables
  - Public access policies for initial testing (will be tightened later)
  - Users table allows public insert for registration
*/

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  role text NOT NULL DEFAULT 'STUDENT' CHECK (role IN ('ADMIN', 'STUDENT')),
  is_active boolean DEFAULT true,
  current_lesson_id uuid,
  created_at timestamptz DEFAULT now()
);

-- Create lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  index integer NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  is_published boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create lines table
CREATE TABLE IF NOT EXISTS lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  order_num integer NOT NULL,
  code text NOT NULL,
  type text NOT NULL CHECK (type IN ('INFO', 'LINK', 'LANG')),
  text_he text DEFAULT '',
  text_it text DEFAULT '',
  stress_rule text DEFAULT '',
  recording_hint text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- Create progress table
CREATE TABLE IF NOT EXISTS progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  last_line_order integer DEFAULT 0,
  is_completed boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, lesson_id)
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  line_id uuid NOT NULL REFERENCES lines(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create speech_attempts table
CREATE TABLE IF NOT EXISTS speech_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  line_id uuid NOT NULL REFERENCES lines(id) ON DELETE CASCADE,
  transcript text NOT NULL,
  similarity_score numeric DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Add foreign key for current_lesson_id
ALTER TABLE users 
  ADD CONSTRAINT users_current_lesson_fkey 
  FOREIGN KEY (current_lesson_id) 
  REFERENCES lessons(id) 
  ON DELETE SET NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_current_lesson ON users(current_lesson_id);
CREATE INDEX IF NOT EXISTS idx_lessons_index ON lessons(index);
CREATE INDEX IF NOT EXISTS idx_lessons_published ON lessons(is_published);
CREATE INDEX IF NOT EXISTS idx_lines_lesson ON lines(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lines_order ON lines(lesson_id, order_num);
CREATE INDEX IF NOT EXISTS idx_progress_user ON progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_line ON notes(line_id);
CREATE INDEX IF NOT EXISTS idx_speech_user ON speech_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_speech_line ON speech_attempts(line_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE speech_attempts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Allow anyone to read users (for login)
CREATE POLICY "Anyone can read users"
  ON users FOR SELECT
  USING (true);

-- Allow anyone to insert users (for registration and admin creating users)
CREATE POLICY "Anyone can create users"
  ON users FOR INSERT
  WITH CHECK (true);

-- Allow users to update themselves
CREATE POLICY "Users can update themselves"
  ON users FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Allow deleting users
CREATE POLICY "Anyone can delete users"
  ON users FOR DELETE
  USING (true);

-- RLS Policies for lessons table
CREATE POLICY "Anyone can read published lessons"
  ON lessons FOR SELECT
  USING (true);

CREATE POLICY "Anyone can manage lessons"
  ON lessons FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update lessons"
  ON lessons FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete lessons"
  ON lessons FOR DELETE
  USING (true);

-- RLS Policies for lines table
CREATE POLICY "Anyone can read lines"
  ON lines FOR SELECT
  USING (true);

CREATE POLICY "Anyone can manage lines"
  ON lines FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update lines"
  ON lines FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete lines"
  ON lines FOR DELETE
  USING (true);

-- RLS Policies for progress table
CREATE POLICY "Anyone can read progress"
  ON progress FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create progress"
  ON progress FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update progress"
  ON progress FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete progress"
  ON progress FOR DELETE
  USING (true);

-- RLS Policies for notes table
CREATE POLICY "Anyone can read notes"
  ON notes FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create notes"
  ON notes FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update notes"
  ON notes FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete notes"
  ON notes FOR DELETE
  USING (true);

-- RLS Policies for speech_attempts table
CREATE POLICY "Anyone can read speech attempts"
  ON speech_attempts FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create speech attempts"
  ON speech_attempts FOR INSERT
  WITH CHECK (true);

-- End of 20251027072331_create_initial_schema.sql

-- Start of 20251027072507_fix_rls_policies_for_users.sql
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

-- End of 20251027072507_fix_rls_policies_for_users.sql

-- Start of 20251027072641_create_user_management_functions.sql
/*
  # Create User Management Functions

  1. New Functions
    - `create_user` - Creates a new user (bypasses RLS)
    - `update_user_role` - Updates user role
    - `delete_user_by_id` - Deletes a user
    - `toggle_user_status` - Toggles user active status

  2. Security
    - Functions run with SECURITY DEFINER (as postgres)
    - This bypasses RLS restrictions
*/

-- Function to create a new user
CREATE OR REPLACE FUNCTION create_user(
  p_username text,
  p_password_hash text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, p_password_hash, p_role, true)
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(
  p_user_id uuid,
  p_new_role text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  UPDATE users
  SET role = p_new_role
  WHERE id = p_user_id
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to toggle user status
CREATE OR REPLACE FUNCTION toggle_user_status(
  p_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  UPDATE users
  SET is_active = NOT is_active
  WHERE id = p_user_id
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to delete user
CREATE OR REPLACE FUNCTION delete_user_by_id(
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM users WHERE id = p_user_id;
  RETURN true;
END;
$$;

-- Function to update user password
CREATE OR REPLACE FUNCTION update_user_password(
  p_user_id uuid,
  p_password_hash text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users
  SET password_hash = p_password_hash
  WHERE id = p_user_id;
  RETURN true;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_user TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_user_role TO anon, authenticated;
GRANT EXECUTE ON FUNCTION toggle_user_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION delete_user_by_id TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_user_password TO anon, authenticated;

-- End of 20251027072641_create_user_management_functions.sql

-- Start of 20251027103821_fix_security_issues.sql
/*
  # תיקון בעיות אבטחה

  1. מחיקת אינדקסים שלא בשימוש
    - `idx_users_current_lesson` - אינדקס על users.current_lesson_id
    - `idx_lessons_published` - אינדקס על lessons.is_published
    - `idx_progress_lesson` - אינדקס על progress.lesson_id
    - `idx_speech_line` - אינדקס על speech_attempts.line_id

  2. תיקון search_path בפונקציות
    - הוספת `SET search_path` לכל הפונקציות
    - מניעת פגיעויות אבטחה מסוג search_path manipulation
*/

-- מחיקת אינדקסים שלא בשימוש
DROP INDEX IF EXISTS idx_users_current_lesson;
DROP INDEX IF EXISTS idx_lessons_published;
DROP INDEX IF EXISTS idx_progress_lesson;
DROP INDEX IF EXISTS idx_speech_line;

-- מחיקת פונקציות קיימות
DROP FUNCTION IF EXISTS public.create_user(text, text, text);
DROP FUNCTION IF EXISTS public.update_user_role(uuid, text);
DROP FUNCTION IF EXISTS public.toggle_user_status(uuid);
DROP FUNCTION IF EXISTS public.delete_user_by_id(uuid);
DROP FUNCTION IF EXISTS public.update_user_password(uuid, text);

-- יצירה מחדש עם search_path מאובטח
CREATE FUNCTION public.create_user(
  p_username text,
  p_password text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
  v_user_id uuid;
BEGIN
  v_password_hash := crypt(p_password, gen_salt('bf', 8));
  
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, v_password_hash, p_role, true)
  RETURNING id INTO v_user_id;
  
  RETURN v_user_id;
END;
$$;

CREATE FUNCTION public.update_user_role(
  p_user_id uuid,
  p_role text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE users 
  SET role = p_role
  WHERE id = p_user_id;
END;
$$;

CREATE FUNCTION public.toggle_user_status(
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_new_status boolean;
BEGIN
  UPDATE users 
  SET is_active = NOT is_active
  WHERE id = p_user_id
  RETURNING is_active INTO v_new_status;
  
  RETURN v_new_status;
END;
$$;

CREATE FUNCTION public.delete_user_by_id(
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  DELETE FROM speech_attempts WHERE user_id = p_user_id;
  DELETE FROM notes WHERE user_id = p_user_id;
  DELETE FROM progress WHERE user_id = p_user_id;
  DELETE FROM users WHERE id = p_user_id;
END;
$$;

CREATE FUNCTION public.update_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
BEGIN
  v_password_hash := crypt(p_new_password, gen_salt('bf', 8));
  
  UPDATE users 
  SET password_hash = v_password_hash
  WHERE id = p_user_id;
END;
$$;

-- End of 20251027103821_fix_security_issues.sql

-- Start of 20251027104403_add_login_function.sql
/*
  # הוספת פונקציית התחברות מאובטחת

  1. פונקציה חדשה
    - `verify_user_login` - מאמתת שם משתמש וסיסמה מול bcrypt
    - מחזירה את פרטי המשתמש אם ההתחברות מוצלחת
    - מחזירה NULL אם ההתחברות נכשלה
  
  2. אבטחה
    - שימוש ב-bcrypt לאימות סיסמאות
    - SECURITY DEFINER עם search_path מוגדר
    - בדיקה שהמשתמש פעיל
*/

-- פונקציה לאימות התחברות
CREATE OR REPLACE FUNCTION public.verify_user_login(
  p_username text,
  p_password text
)
RETURNS TABLE(
  id uuid,
  username text,
  role text,
  is_active boolean,
  current_lesson_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.role,
    u.is_active,
    u.current_lesson_id,
    u.created_at
  FROM users u
  WHERE u.username = p_username
    AND u.is_active = true
    AND u.password_hash = crypt(p_password, u.password_hash);
END;
$$;

-- End of 20251027104403_add_login_function.sql

-- Start of 20251027104454_fix_bcrypt_functions.sql
/*
  # תיקון פונקציות bcrypt

  1. תיקון type casting ב-gen_salt
    - הוספת explicit cast ל-'bf'::text
    - תיקון כל הפונקציות שמשתמשות ב-bcrypt
*/

-- מחיקת פונקציות קיימות
DROP FUNCTION IF EXISTS public.create_user(text, text, text);
DROP FUNCTION IF EXISTS public.update_user_password(uuid, text);

-- יצירה מחדש עם type casting תקין
CREATE FUNCTION public.create_user(
  p_username text,
  p_password text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
  v_user_id uuid;
BEGIN
  v_password_hash := crypt(p_password, gen_salt('bf'::text, 8));
  
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, v_password_hash, p_role, true)
  RETURNING id INTO v_user_id;
  
  RETURN v_user_id;
END;
$$;

CREATE FUNCTION public.update_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
BEGIN
  v_password_hash := crypt(p_new_password, gen_salt('bf'::text, 8));
  
  UPDATE users 
  SET password_hash = v_password_hash
  WHERE id = p_user_id;
END;
$$;

-- End of 20251027104454_fix_bcrypt_functions.sql

-- Start of 20251027104515_fix_bcrypt_type_casting.sql
/*
  # תיקון type casting מלא לפונקציות bcrypt

  1. תיקון
    - השמטת הפרמטר השני של gen_salt (cost)
    - gen_salt('bf') משתמש בערך ברירת מחדל של 8
*/

-- מחיקת פונקציות קיימות
DROP FUNCTION IF EXISTS public.create_user(text, text, text);
DROP FUNCTION IF EXISTS public.update_user_password(uuid, text);

-- יצירה מחדש עם gen_salt פשוט יותר
CREATE FUNCTION public.create_user(
  p_username text,
  p_password text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
  v_user_id uuid;
BEGIN
  v_password_hash := crypt(p_password, gen_salt('bf'));
  
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, v_password_hash, p_role, true)
  RETURNING id INTO v_user_id;
  
  RETURN v_user_id;
END;
$$;

CREATE FUNCTION public.update_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_password_hash text;
BEGIN
  v_password_hash := crypt(p_new_password, gen_salt('bf'));
  
  UPDATE users 
  SET password_hash = v_password_hash
  WHERE id = p_user_id;
END;
$$;

-- End of 20251027104515_fix_bcrypt_type_casting.sql

-- Start of 20251027104544_fix_pgcrypto_search_path.sql
/*
  # תיקון search_path לפונקציות עם pgcrypto

  1. תיקון
    - הוספת extensions ל-search_path
    - כך הפונקציות gen_salt ו-crypt יהיו זמינות
*/

-- מחיקת פונקציות קיימות
DROP FUNCTION IF EXISTS public.create_user(text, text, text);
DROP FUNCTION IF EXISTS public.update_user_password(uuid, text);

-- יצירה מחדש עם search_path כולל extensions
CREATE FUNCTION public.create_user(
  p_username text,
  p_password text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_password_hash text;
  v_user_id uuid;
BEGIN
  v_password_hash := crypt(p_password, gen_salt('bf'));
  
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, v_password_hash, p_role, true)
  RETURNING id INTO v_user_id;
  
  RETURN v_user_id;
END;
$$;

CREATE FUNCTION public.update_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_password_hash text;
BEGIN
  v_password_hash := crypt(p_new_password, gen_salt('bf'));
  
  UPDATE users 
  SET password_hash = v_password_hash
  WHERE id = p_user_id;
END;
$$;

-- עדכון גם את פונקציית verify_user_login
DROP FUNCTION IF EXISTS public.verify_user_login(text, text);

CREATE FUNCTION public.verify_user_login(
  p_username text,
  p_password text
)
RETURNS TABLE(
  id uuid,
  username text,
  role text,
  is_active boolean,
  current_lesson_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.role,
    u.is_active,
    u.current_lesson_id,
    u.created_at
  FROM users u
  WHERE u.username = p_username
    AND u.is_active = true
    AND u.password_hash = crypt(p_password, u.password_hash);
END;
$$;

-- End of 20251027104544_fix_pgcrypto_search_path.sql

-- Start of 20251028073220_update_lesson_1_content_part_1.sql
/*
  # עדכון תוכן שיעור 1 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 1
    - הוספת שורות 1-50
*/

-- מחיקת שורות קיימות של שיעור 1
DELETE FROM lines WHERE lesson_id = '9b2b6a79-e1c4-4bdf-9a35-32996a2c6136';

-- הוספת שורות 1-50
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 1, '1-00000', 'BENVENUTI לסדנה איטלקית היחידה שמאפשרת לך להסתדר במדינות דוברות איטלקית אחרי 8 שיעורים בלבד', 'BENVENUTI', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 2, '1-00001', 'בהגדות של "מי מתאים לקורס הזה", אחד התנאים היה ידיעת האנגלית/צרפתית (בדגש על אנגלית) ברמה תיכונית, לפחות.', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 3, '1-00010', 'ונתחיל במה שאנחנו יודעים...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 4, '1-00011', 'במשפטים הבאים רואים את הסיבה לכך שהתעקשתי שאתם תשלטו באנגלית – יש הרבה מילים באיטלקית הדומים למילים באנגלית, כמובן בהבדלי היגוי – עקבו אחרי המשפטים הבאים :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 5, '1-00012', 'ON YOUR ENGLISH VOCABULARY – שימו לב – כמו בערבית (לא כמו באנגלית) תואר השם מופיע אחרי השם !!!', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 6, '1-00201', 'במילון האנגלי שלכם', 'NEL TUO DIZIONARIO INGLESE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 7, '1-00301', 'ואחרי כל ההסברים..באנגלית IN ORDER TO INITIATE ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 8, '1-00302', 'על מנת להתחיל', 'PER INIZIARE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 9, '1-00400', 'באופן מיידי', 'IMMEDIATAMENTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 10, '1-00500', 'TO TRANSFORM HIS ENGLISH VOCABULARY לאיטלקית. – כך שאנחנו לא מתחילים מאפס אלא מיותר מכ-2,000 מילים דומות לאנגלית, שזה לא רע להתחלה !!', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 11, '1-00501', 'להעביר את המילון האנגלי שלו', 'TRASFORMARE IL SUO VOCABOLARIO INGLESE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 12, '1-00600', 'באנגלית - ESPECIALLY ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 13, '1-00601', 'במיוחד', 'PARTICOLARMENTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 14, '1-00700', 'באנגלית IF YOU CONSIDER ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 15, '1-00701', 'אם לוקחים בחשבון', 'SE CONSIDERA', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 16, '1-00702', 'באנגלית THE LIMITATION ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 17, '1-00801', 'המוגבלות', 'LA LIMITAZIONE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 18, '1-00900', 'באנגלית - OF THE ACTIVE VOCABULARY ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 19, '1-00901', 'של אוצר המילים הפעיל', 'DEL VOCABOLARIO ATTIVO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 20, '1-01001', 'בכל שפה, במה שנקרא "אוצר מילים פעיל" – יש רק 500 עד 1,500 מילים !!', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 21, '1-01002', 'כלומר, אם "תופסים את הפטנט" (ויש כזה לרוב המילים !!) אפשר לקבל, מבלי להתאמץ, כ-2000 מילים !!', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 22, '1-01003', 'באנגלית LIMITATION OF THE ACTIVE VOCABULARY ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 23, '1-01004', 'המוגבלות של המילון הפעיל', 'LIMITAZIONE DEL VOCABOLARIO ATTIVO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 24, '1-01101', 'להפוך את אוצר המילים האנגלי שלכם לאיטלקית', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 25, '1-01102', 'להפוך את אוצר המילים האנגלי לאיטלקית', 'TRASFORMARE IL VOCABOLARIO INGLESE ALL''ITALIANO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 26, '1-01103', 'אאפיין לכם 7 קבוצות של סיומות', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 27, '1-01200', 'להלן הקבוצות : (הקבוצות יאופיינו בסיומות המילים)', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 28, '1-01201', 'הקבוצה מס 1 – מילים באנגלית שמסתיימות ב IBLE כמו POSSIBLE או ABLE כמו PROBABLE', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 29, '1-01202', 'באנגלית THE PRONUNCIATION ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 30, '1-01203', 'ההיגוי', 'LA PRONUNCIA', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 31, '1-01300', 'יש לך הבדל בהיגוי – באנגלית YOU HAVE DIFFERENCE IN PRONUNCIATION', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 32, '1-01301', 'יש הבדל היגוי', 'HAI DIFFERENZA IN PRONUNCIA', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 33, '1-01302', 'שתי סיבות עיקריות להבדלים בביטוי', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 34, '1-01303', 'ההבדל השני הוא בצורת ביטוי התנועות (5 תנועות סהכ)', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 35, '1-01401', 'הביטוי זה בעברית או IT IS באנגלית', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 36, '1-01402', 'זה', 'È', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 37, '1-01500', 'זה אפשרי באנגלית יהיה IT IS POSSIBLE', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 38, '1-01501', 'זה אפשרי', 'È POSSIBILE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 39, '1-01600', 'באנגלית IT IS PROBABLE', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 40, '1-01601', 'זה ייתכן', 'È PROBABILE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 41, '1-01700', 'באנגלית IT IS TERRIBLE', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 42, '1-01701', 'זה נורא', 'È TERRIBILE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 43, '1-01800', 'באנגלית IT IS ACCEPTABLE', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 44, '1-01801', 'זה מקובל', 'È ACCETTABILE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 45, '1-01900', 'באנגלית FOR ME', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 46, '1-01901', 'עבורי', 'PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 47, '1-02000', 'באנגלית FOR YOU', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 48, '1-02001', 'עבורך (חברי)', 'PER TE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 49, '1-02100', 'במשפטי שלילה מוסיפים NO שתמיד יופיע ראשון במשפט', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 50, '1-02101', 'זה לא בשבילך, זה בשבילי', 'NON È PER TE, È PER ME', 'LANG');

-- End of 20251028073220_update_lesson_1_content_part_1.sql

-- Start of 20251028073329_update_lesson_1_content_part_2.sql
/*
  # עדכון תוכן שיעור 1 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 51, '1-02200', 'הערה – כמה משפטים יכולים להיות מחוברים ב "," או במילות חיבור', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 52, '1-02500', 'באנגלית IT IS NOT POSSIBLE FOR ME', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 53, '1-02501', 'זה לא אפשרי עבורי', 'NON È POSSIBILE PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 54, '1-02600', 'זה אפשרי עבורך', 'È POSSIBILE PER TE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 55, '1-02700', 'ומילה אחרת שלמדנו..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 56, '1-02701', 'זה מקובל עלי', 'È ACCETTABILE PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 57, '1-02800', 'או בשלילה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 58, '1-02801', 'זה לא מקובל עלי', 'NON È ACCETTABILE PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 59, '1-02900', 'אם אתם רוצים לשאול שאלה באיטלקית, זה מאד פשוט – זה עניין של אינטונציה בלבד', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 60, '1-02901', 'זה מקובל עליכם', 'È ACCETTABILE PER VOI', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 61, '1-03000', 'ובשאלה :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 62, '1-03001', 'האם זה מקובל עליך?', 'È ACCETTABILE PER TE ?', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 63, '1-03100', 'בשלילה ושאלה..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 64, '1-03101', 'האם זה לא מקובל עליך?', 'NON È ACCETTABILE PER TE ?', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 65, '1-03200', 'למה (או לְ-מָה) FOR WHAT ?', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 66, '1-03202', 'למה', 'PERCHÉ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 67, '1-03203', 'ונשתמש במשפט..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 68, '1-03300', 'למה זה לא מקובל עליך ?', 'PERCHÉ NON È ACCETTABILE PER TE ?', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 69, '1-03400', 'מילה קטנה אבל מאד שימושית באיטלקית היא :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 70, '1-03401', 'כך, בדרך זו', 'COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 71, '1-03402', 'איך כותבים COSÌ ? יש דגש מעל ה Í', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 72, '1-03403', 'ואם נרצה לשלב את המילה במשפט הכי פשוט – זה ככה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 73, '1-03500', 'זה כך', 'È COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 74, '1-03501', 'ובשלילה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 75, '1-03600', 'זה לא כך', 'NON È COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 76, '1-03601', 'קצת הרחבה...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 77, '1-03700', 'זה בלתי אפשרי כך', 'NON È POSSIBILE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 78, '1-03701', 'או בחיוב עם מילה שלישית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 79, '1-03702', 'זה בלתי אפשרי כך', 'È IMPOSSIBILE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 80, '1-03703', 'ונרחיב את יריעה..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 81, '1-03800', 'זה לא מקובל עלי כך', 'NON È ACCETTABILE PER ME COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 82, '1-03801', 'ואם בשאלות עסקינן...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 83, '1-03900', 'למה זה לא מקובל עליך כך ?', 'PERCHÉ NON È ACCETTABILE COSÌ PER TE ?', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 84, '1-04000', 'ביטוי שכדאי שתפנימו היטב, זה עוזר לצאת ממצבים מביכים .', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 85, '1-04001', 'אני מצטער', 'MI DISPIACE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 86, '1-04002', 'המילה DISPIACE אומר לא מוצא חן כי MI PIACE אומר – זה מוצא חן בעיניי', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 87, '1-04100', 'ומילה קטנה שבאה להציל את כבודנו הלאומי...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 88, '1-04101', 'אבל', 'MA', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 89, '1-04102', 'אפשר גם PERO ...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 90, '1-04103', 'אם נצטרך להגיד "סליחה" תמיד נוכל לתרץ את הפאשלה ב "אבל"', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 91, '1-04204', 'אני מצטער, אבל', 'MI DISPIACE MA...', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 92, '1-04205', 'בהזדמנות זו אני מזכיר לכם לא לשכוח – להשתמש בשיטת ה-LEGO', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 93, '1-04206', 'לדוגמא...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 94, '1-04301', 'אני מצטער אבל זה לא מקובל עלי כך', 'MI DISPIACE MA NON È ACCETTABILE PER ME COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 95, '1-04302', 'או...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 96, '1-04400', 'אני מצטער אבל זה בלתי אפשרי כך', 'MI DISPIACE MA NON È POSSIBILE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 97, '1-04401', 'או...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 98, '1-04402', 'אני מצטער אבל זה בלתי אפשרי כך', 'MI DISPIACE MA È IMPOSSIBILE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 99, '1-04403', 'מילה נוספת שימושית מאד :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 100, '1-04500', 'עכשיו', 'ORA', 'LANG');

-- End of 20251028073329_update_lesson_1_content_part_2.sql

-- Start of 20251028073448_update_lesson_1_content_part_3.sql
/*
  # עדכון תוכן שיעור 1 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 101, '1-04501', 'עכשיו – ORA – AT (THIS) HOUR - לא קוראים את ה "H"', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 102, '1-04600', 'הקבוצה מס 2 – מילים באנגלית שמסתיימות ב ENT או ANT', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 103, '1-04601', 'באנגלית DIFFERENT ובאיטלקית :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 104, '1-04602', 'שונה', 'DIFFERENTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 105, '1-04603', 'באיטלקית - F במקום FF – אמרנו שהאיטלקים חסכנים..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 106, '1-04700', 'באנגלית IMPORTANT ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 107, '1-04701', 'חשוב', 'IMPORTANTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 108, '1-04800', 'באנגלית, RESTAURANT ובאיטלקית..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 109, '1-04801', 'מסעדה', 'RISTORANTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 110, '1-04802', 'שימו לב שבאנגלית AU ייקרא אוֹ ובאיטלקית קוראים כל אות כמו שצריך', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 111, '1-04803', 'עוד משפטים..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 112, '1-04900', 'זה חשוב לי', 'È IMPORTANTE PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 113, '1-04901', 'או במשפט אחר :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 114, '1-05000', 'זה לא שונה בדרך זו', 'NON È DIFFERENTE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 115, '1-05001', 'ועכשיו למשהו טוב...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 116, '1-05100', 'טוב – עומד בפני עצמו', 'BENE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 117, '1-05400', 'מאד זה...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 118, '1-05401', 'מאד – כשזה מתאר תכונה כמו טוב מאד', 'MOLTO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 119, '1-05402', 'כמו..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 120, '1-05403', 'זה טוב מאד', 'È MOLTO BENE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 121, '1-05404', 'ובשלילה – זיכרו שהמלה, NON המתארת שלילה באה בראש המשפט', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 122, '1-05500', 'זה לא טוב מאד', 'NON È MOLTO BENE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 123, '1-05501', 'ובתיאור תכונה אחרת ..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 124, '1-05600', 'זה לא מאד שונה כך', 'NON È MOLTO DIFFERENTE COSÌ', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 125, '1-05601', 'ובמשפט קצת יותר מורכב..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 126, '1-05700', 'אבל זה מאד חשוב לי', 'MA È MOLTO IMPORTANTE PER ME', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 127, '1-05701', 'זיכרו – לפעמים יש תועלת בתרגום מקדמי לאנגלית', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 128, '1-05800', 'כל שפה מאפשרת הדגשה של הברה אחת בלבד לכל מילה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 129, '1-05801', 'כלל הדגשה ראשון :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 130, '1-05802', 'אם מילה מסתיימת בהברה פתוחה (תנועה), ההדגשה תהיה תמיד על ההברה הלפני אחרונה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 131, '1-05803', 'חשוב', 'IMPORTANTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 132, '1-05900', 'מסעדה', 'RISTORANTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 133, '1-06000', 'שונה', 'DIFFERENTE', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 134, '1-06001', 'וכו – הכלל הזה סוחף - במקרים שזה לא כך – יבוא סימן מיוחד ושמו – דגש', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 135, '1-06100', 'ועכשיו נתעסק באחד הפעלים השימושיים ביותר..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 136, '1-06101', 'יש לי', 'HO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 137, '1-06103', 'האות O בסוף הפועל אומר שזה הווה, גוף ראשון, יחיד', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 138, '1-06104', 'המושאים MI, TI, LO, NOI, VOI, LORO', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 139, '1-06106', 'רק להדגשה, אם שואלים "למי יש את זה" ? נענה :', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 140, '1-06107', 'יש לי את זה', 'io L''HO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 141, '1-06108', 'שם הגוף, ה- IO (אני) זה רק לצורך הדגשה כי סיומת O אומר גוף ראשון הווה', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 142, '1-06109', 'ובשלילה..', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 143, '1-06200', 'אין לי', 'NO CE L''HO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 144, '1-06400', 'כנ"ל אם האוביאקט שהזכרנו הוא ממין בנקבה...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 145, '1-06401', 'אין לי אותה', 'NO CE L''HA', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 146, '1-06402', 'ואם גם רוצים להתנצל על כך....', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 147, '1-06500', 'אני מצטער אין לי אותו אבל', 'MI DISPIACE MA NON CE L''HO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 148, '1-06501', 'ולמילה אחרת בעלת שימוש רחב...', '', 'INFO'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 149, '1-06600', 'אני רוצה', 'VOGLIO', 'LANG'),
('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 150, '1-06700', 'אני רוצה את זה', 'LO VOGLIO', 'LANG');

-- End of 20251028073448_update_lesson_1_content_part_3.sql

-- Start of 20251028074607_update_lesson_2_content_part_1.sql
/*
  # עדכון תוכן שיעור 2 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 2
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 2
DELETE FROM lines WHERE lesson_id = '6bd8ef08-6771-466b-8abf-eba439a1665b';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('6bd8ef08-6771-466b-8abf-eba439a1665b', 1, '2-00100', 'טיפלנו ב-2 קבוצות של מילים דומות בון שתי השפות', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 2, '2-00101', 'קבוצה מס 3 - כמעט כל המילים שבאנגלית מסתיימים ב ARY כמו CONTRARY, NECESSARY, VOCABULARY', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 3, '2-00200', 'הכרחי', 'NECESSARIO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 4, '2-00400', 'וו החיבור הוא E המכונה באיטלקית', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 5, '2-00401', 'למשל, משפט מורכב שלושה משפטים בו משתמשים ב-וו החיבור ופעם בפסיק...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 6, '2-00402', 'אני מצטער, אבל אין לי את זה ואני לא רוצה את זה בגלל שאני לא צריך את זה עכשיו', 'MI DISPIACE, MA NON CE L''HO E NON LO VOGLIO, PERCHÉ NON LO BISOGNIO ADESSO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 7, '2-00500', 'ההפך באנגלית - CONTRARY ובאיטלקית..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 8, '2-00501', 'ההפך', 'CONTRARIO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 9, '2-00502', 'ומכאן הביטוי...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 10, '2-00600', 'להפך', 'AL CONTRARIO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 11, '2-00700', 'מילון באנגלית VOCABULARY ובאיטלקית..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 12, '2-00701', 'מילון', 'VOCABULARIO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 13, '2-00702', 'פועל קצר וחשוב..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 14, '2-00800', 'לראות', 'VEDERE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 15, '2-00900', 'אם השימוש בפועל הוא במשפט כשהפועל הוא לא הראשון מצמידים את המושא בסוף הפועל בשמו המלא', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 16, '2-00901', 'לראות אותו', 'VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 17, '2-01000', 'אבל אם הפועל הוא יחיד ו/או ראשון, יש הטייה של הפועל והמושא יבוא לפניו..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 18, '2-01001', 'אני רואה אותו', 'LO VEDO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 19, '2-01002', 'אבל, כשיש פועל אחר לפניו, המושא יבוא צמוד לפועל במצבו המקורי...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 20, '2-01100', 'אני רוצה לראות אותו', 'VOGLIO VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 21, '2-01200', 'כנ"ל בשלילה..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 22, '2-01201', 'לא רוצה לראות אותו', 'NON VOGLIO VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 23, '2-01300', 'אבל, כמו שאמרנו קודם – אם הפועל מופיע לבד, יש לו הטייה והמושא לפניו..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 24, '2-01301', 'אני רוצה אותו', 'LO VOGLIO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 25, '2-01400', 'והבא נתחכמה לה – פעמיים אותו פועל', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 26, '2-01401', 'אני רוצה לרצות אותו', 'VOGLIO VOLERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 27, '2-01402', 'עוד דוגמא..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 28, '2-01500', 'למה אתה לא רוצה לראות אותו ?', 'PERCHÉ NON VUOI VEDERLO ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 29, '2-01502', 'ודוגמא נוספת..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 30, '2-01600', 'אני לא יכול לראות אותו', 'NON POSSO VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 31, '2-01601', 'ובגוף שני...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 32, '2-01700', 'אתה לא יכול לראות אותו', 'NON PUOI VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 33, '2-01800', 'ועכשיו שוב למשמעות של המושאים', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 34, '2-01900', 'אתה יכול לראות את הספר ?', 'PUOI VEDERE IL LIBRO ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 35, '2-01901', 'אבל אחרי שכולם יודעים על מה מדובר...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 36, '2-01902', 'אתה יכול לראות אותו ?', 'PUOI VEDERLO ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 37, '2-01903', 'ולסיכום – במקרה של פועל שני והלאה, המושא הישר מופיע צמוד לפועל ואחריו', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 38, '2-02000', 'למה אתה לא יכול לראות אותו ?', 'PERCHÉ NON PUOI VEDERLO ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 39, '2-02100', 'מה אתה יכול לראות ?', 'COSA PUOI VEDERE ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 40, '2-02101', 'גם כאן, כמו שכבר ראינו, במקום CHE בא COSA – זה פשוט יותר איטלקי...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 41, '2-02200', 'אתה רוצה לראות אותו', 'VUOI VEDERLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 42, '2-02300', 'רוצה לעשות את זה', 'VUOI FARLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 43, '2-02301', 'אתה יכול להגיד לי', 'PUOI DIRMI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 44, '2-02302', 'אני רוצה לראות אותך', 'VOGLIO VEDERTI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 45, '2-02303', 'ואם רוצים להדגיש...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 46, '2-02400', 'אני רוצה לעשות את זה !', 'VOGLIO FARLO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 47, '2-02401', 'ובשלילה – זיכרו - ה - NON הוא תמיד בראש המשפט...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 48, '2-02500', 'אני לא רוצה לעשות את זה כך', 'NON VOGLIO FARLO COSÌ', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 49, '2-02501', 'ובשאלה ?', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 50, '2-02600', 'בגלל שאני לא יכול לעשות אותו', 'PERCHÉ NON POSSO FARLO', 'LANG');

-- End of 20251028074607_update_lesson_2_content_part_1.sql

-- Start of 20251028074714_update_lesson_2_content_part_2.sql
/*
  # עדכון תוכן שיעור 2 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('6bd8ef08-6771-466b-8abf-eba439a1665b', 51, '2-02601', 'ובגוף שני...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 52, '2-02700', 'למה אינך יכול לעשות את זה ?', 'PERCHÉ NON PUOI FARLO ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 53, '2-02701', 'ומשפט יותר מפורט..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 54, '2-02800', 'אני רוצה לדעת למה אינך יכול לעשות את זה כך', 'VOGLIO SAPERE PERCHÉ NON PUOI FARLO COSÌ', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 55, '2-02900', 'קבוצה מס 4 - מילים באנגלית שנגמרים ב ENCE או ANCE', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 56, '2-02901', 'דוגמאות..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 57, '2-02902', 'המילה הבדל באנגלית היא DIFFERENCE ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 58, '2-02903', 'הבדל', 'DIFFERENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 59, '2-02906', 'הבדל אחד', 'UNA DIFFERENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 60, '2-03000', 'איזה הבדל', 'CHE DIFFERENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 61, '2-03001', 'בד"כ נאמר בפליאה : CHÉ DIFFERENZA !?! איזה הבדל ?!', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 62, '2-03002', 'המילה חשיבות באנגלית היא IMPORTANCE ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 63, '2-03101', 'חשיבות', 'IMPORTANZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 64, '2-03200', 'המילה השפעה באנגלית היא INFLUENCE ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 65, '2-03201', 'השפעה', 'INFLUENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 66, '2-03300', 'המילה נוכחות באנגלית היא PRESENCE ובאיטלקית', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 67, '2-03301', 'נוכחות', 'PRESENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 68, '2-03400', 'המילה העדפה באנגלית היא PREFERENCE ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 69, '2-03401', 'העדפה', 'PREFERENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 70, '2-03402', 'ובשילוב במשפטי שאלה..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 71, '2-03500', 'יש לך העדפה ?', 'HAI UNA PREFERENZA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 72, '2-03600', 'איזה העדפה יש לך ?', 'CHÉ PREFERENZA HAI ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 73, '2-03700', 'איזה מסעדה אתה מעדיף (יש לך העדפה) ?', 'PER QUALE RISTORANTE HAI UNA PREFERENZA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 74, '2-03800', 'כש QUESTA זה "הזה" ו NOTTE הוא נקבי', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 75, '2-03801', 'הלילה הזה', 'QUESTA NOTTE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 76, '2-03802', 'או..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 77, '2-03900', 'זה ללילה (ערב) הזה', 'È PER QUESTA NOTTE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 78, '2-03901', 'ובמשפט ארוך..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 79, '2-04000', '(ל)איזה מסעדה אתה מעדיף הלילה ?', 'PER QUALE RISTORANTE HAI UNA PREFERENZA, QUESTA NOTTE ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 80, '2-04001', 'בתרגום מילולי – עבור איזה מסעדה יש לך העדפה הלילה ?', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 81, '2-04100', '(ל)איזה מסעדה אתה מעדיף ל הלילה ?', 'PER QUALE RISTORANTE HAI UNA PREFERENZA PER QUESTA SERA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 82, '2-04101', 'זה בדיוק המשפט הקודם, רק במקום פסיק יש את מילת הקישור PER', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 83, '2-04200', 'ועכשיו למילת שאלה מאד חשובה, במיוחד עבור תייר..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 84, '2-04201', 'איפה', 'DOVE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 85, '2-04300', 'איפה אתה רוצה לאכול ?', 'DOVE VUOI MANGIARE ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 86, '2-04400', 'ארוחת ערב', 'CENA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 87, '2-04401', 'יבוטא "צֶ׳נָה"', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 88, '2-04402', 'וכמו באנגלית DINNER=ארוחת ערב ו TO DINE=לאכול ארוחת ערב...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 89, '2-04500', 'לאכול ארוחת ערב', 'CENARE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 90, '2-04501', 'ובמשפט..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 91, '2-04600', 'איפה תרצה לאכול ארוחת ערב הערב ?', 'DOVE VUOI CENARE QUESTA SERA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 92, '2-04700', 'יש לך העדפה ?', 'HAI UNA PREFERENZA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 93, '2-04701', 'ונדנוד נוסף...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 94, '2-04800', 'מה ההעדפה שלך ?', 'QUAL È LA TUA PREFERENZA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 95, '2-04801', 'או..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 96, '2-04802', 'איזה העדפה יש לך ?', 'CHÉ PREFERENZA HAI ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 97, '2-04803', 'ובשאלה מלאה...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 98, '2-04900', 'לאיזה מסעדה תעדיף הלילה ?', 'PER QUALE RESTORANTE HAI UNA PREFERENZA STASERA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 99, '2-05001', 'קבוצה מס 5 - כל המילים האנגליות המסתיימות ב ION באנגלית', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 100, '2-05002', 'המילה דיעה באנגלית היא OPINION ובאיטלקית :', '', 'INFO');

-- End of 20251028074714_update_lesson_2_content_part_2.sql

-- Start of 20251028074822_update_lesson_2_content_part_3.sql
/*
  # עדכון תוכן שיעור 2 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('6bd8ef08-6771-466b-8abf-eba439a1665b', 101, '2-05003', 'דעה', 'OPINIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 102, '2-05100', 'קבוצה מס 6 - כל מילה המסתיימת באנגלית ב-TION (קבוצה הגדולה ביותר יש כ 1,200 כאלה)', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 103, '2-05101', 'יוצא מן הכלל לנ"ל המילה באנגלית TELEVISION שיהיה', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 104, '2-05102', 'טלויזיה', 'TELEVISIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 105, '2-05200', 'המילה תנאי באנגלית היא CONDITION ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 106, '2-05201', 'מצב', 'CONDIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 107, '2-05300', 'המילה עמדה באנגלית היא POSITION ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 108, '2-05301', 'עמדה', 'POSIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 109, '2-05400', 'המילה הזמנה באנגלית היא RESERVATION ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 110, '2-05401', 'הזמנה (מראש)', 'RESERVAZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 111, '2-05402', 'וגם...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 112, '2-05500', 'הרשמה מראש', 'PRENOTAZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 113, '2-05501', 'אישור', 'CONFIRMAZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 114, '2-05502', 'וגם...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 115, '2-05503', 'אישור', 'CONFERMA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 116, '2-05504', 'ונשלב את זה במשפט..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 117, '2-05600', 'יש לך אישור בשבילי ללילה ?', 'HAI UNA PRENOTAZIONE PER ME PER STASERA', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 118, '2-05701', 'המילה תנאי באנגלית היא CONDITION ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 119, '2-05702', 'תנאי', 'CONDIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 120, '2-05703', 'התנאי', 'LA CONDIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 121, '2-05704', 'תנאי אחד', 'UNA CONDIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 122, '2-05705', 'איזה תנאי', 'CHE CONDIZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 123, '2-05906', 'מילת חיבור קטנה אבל מאד חשובה .', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 124, '2-06000', 'של', 'DI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 125, '2-06001', 'ומשפט ארוך שמילת החיבור הזו משתלב בה...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 126, '2-06100', 'יש לכם את האישור להזמנה עבורי לערב הזה ?', 'HAI LA CONFIRMAZIONE DI LA RESERVAZIONE PER ME PER QUESTA SERA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 127, '2-06101', 'אגב, כל המילים הדומות לאנגלית הן ממין נקבה', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 128, '2-06200', 'המילה טיפוס באנגלית היא TYPE ובאיטלקית :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 129, '2-06201', 'סוג, מין, טיפוס', 'TIPO', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 130, '2-06202', 'ומשולב במשפטים..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 131, '2-06300', 'איזה סוג של הזמנה יש לכם עבורי ללילה הזה ?', 'CHÉ TIPO DI RESERVAZIONE HAI PER ME PER STASERA ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 132, '2-06301', 'שוב פעמים המילה PER, פעם "בשביל" ופעם "עבור"', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 133, '2-06400', 'איזה סוג של הזמנה היית רוצה ?', 'CHÉ TIPO DI RESERVAZIONE VUOI ?', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 134, '2-06401', 'כאמור, קרוב ל 1,200 מילים באנגלית ובאיטלקים יש להם את הסיומת TION', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 135, '2-06402', '2 יוצאים מן הכלל – (TWO EXCEPTIONS) -ובאיטלקית', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 136, '2-06500', 'DUE ECCEPZIONI', 'DUE ECCEPZIONI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 137, '2-06501', 'יוצא מן הכלל ראשון – תרגום – באנגלית TRANSLATION ובאיטלקית לא TRANSLAZIONE אלא :', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 138, '2-06502', 'תרגום', 'TRADUZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 139, '2-06504', 'וכמה משפטים עם זה...', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 140, '2-06600', 'יש לי צורך בתרגום', 'HO BISOGNO DI UNA TRADUZIONE', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 141, '2-06700', 'עשה בבקשה תרגום בשבילי', 'PUOI FARE UNA TRADUZIONE PER ME', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 142, '2-06701', 'שימו לב שצורת הדיבור הזו PUOI FARE היא פנייה מנומסת', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 143, '2-06702', 'ועתה - מילים חשובות להתנהלות במחרב הזמן..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 144, '2-06900', 'היום', 'OGGI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 145, '2-06902', 'מחר', 'DOMANI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 146, '2-06903', 'אתמול', 'IERI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 147, '2-06904', 'מחרתיים', 'DOPODOMANI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 148, '2-06905', 'שלשום', 'L''ATRO IERI', 'LANG'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 149, '2-06906', 'וניזכר שוב – המושאים אחרי הפועל השני והלאה נמצאים אחריהם ו"דבוקים" להם..', '', 'INFO'),
('6bd8ef08-6771-466b-8abf-eba439a1665b', 150, '2-07000', 'לעשות אותו', 'FARLO', 'LANG');

-- End of 20251028074822_update_lesson_2_content_part_3.sql

-- Start of 20251028075335_update_lesson_3_content_part_1.sql
/*
  # עדכון תוכן שיעור 3 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 3
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 3
DELETE FROM lines WHERE lesson_id = '44faec16-0a8a-4452-ac23-dca79cba04f7';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('44faec16-0a8a-4452-ac23-dca79cba04f7', 1, '3-00100', 'בשיעור הזה נתמקד יותר במשפטי שאלה ומשפטים מורכבים מכמה משפטים פשוטים', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 2, '3-00200', 'יקר', 'CARO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 3, '3-00201', 'אפשר גם...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 4, '3-00203', 'יקר, בעל מחיר גבוה', 'COSTOSO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 5, '3-00204', 'קארו זה גם סימן היהלום בקלפים - לא להתבלבל עם CARRO=עגלה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 6, '3-00300', 'יקר מאד', 'MOLTO CARO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 7, '3-00400', 'יותר מדי יקר', 'TROPPO CARO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 8, '3-00402', 'הטיית הפועל.. AVERE', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 9, '3-00500', 'הטיית הפועל AVERE', 'HO , HAI , HA , ABBIAMO , … , HANNO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 10, '3-00600', 'ובגוף שני..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 11, '3-00700', 'יש לך', 'HAI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 12, '3-00701', 'ובשאלה...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 13, '3-00702', 'יש לך את זה ?', 'LO HAI ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 14, '3-00800', 'ובמשפט ארוך יותר..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 15, '3-00801', 'למה אין לך את זה עבורי ?', 'PERCHÉ NON CE L''HAI PER ME ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 16, '3-01000', 'האחראי לכל הטוב הזה הוא הפועל ..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 17, '3-01001', 'TO HAVE (אין מקבילה בעברית)', 'AVERE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 18, '3-01002', 'משפט מלא שיש בו פעמיים המושא LO בשני אופנים שונים', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 19, '3-01003', 'אני רוצה שיהיה לי את זה כי אני צריך את זה', 'VOGLIO AVERLO PERCHÉ NE HO BISOGNO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 20, '3-01004', 'אפשר גם להגיד..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 21, '3-01006', 'אני רוצה שיהיה לי את זה כי אני צריך את זה', 'VOGLIO AVERLO PERCHÉ LO BISOGNO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 22, '3-01404', 'ועכשיו לבילויים..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 23, '3-01405', 'מושאים שימושיים...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 24, '3-01406', 'אתי , אתך , אתו , אתנו , אתכם , אתם', 'CON ME , CON TE , CON LUI , CON NOI , CON VOI, CON LORO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 25, '3-01407', 'וניזכר..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 26, '3-01408', 'אני צריך לעשות', 'BISOGNO FARE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 27, '3-01409', 'ועכשיו לבילויים..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 28, '3-01500', 'לרקוד', 'BALLARE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 29, '3-01501', 'מכאן..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 30, '3-01600', 'רקדנית', 'BALLERINA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 31, '3-01700', 'ובמשפט..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 32, '3-01701', 'אני צריך לרקוד אתך היום', 'BISOGNO BALLARE CON TE OGGI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 33, '3-01802', 'ועכשיו לפרידות...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 34, '3-01900', 'לעזוב, לצאת', 'PARTIRE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 35, '3-01901', 'או..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 36, '3-01902', 'לצאת', 'USCIRE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 37, '3-01904', 'ומכאן, שלט שתראו בכל אולם או שדה תעופה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 38, '3-02000', 'יציאה', 'USCITA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 39, '3-02001', 'ולפני הפרידה...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 40, '3-02100', 'אני חייב לעזוב', 'DEVO PARTIRE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 41, '3-02101', 'ומאד חשוב – ההטיות של הפועל בהווה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 42, '3-02102', 'ההטיות להיות חייב בהווה - DOVERE', 'DEVO , DEVI , DEVE , DOBBIAMO , …, DEVONO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 43, '3-02200', 'ראינו ש ל"עכשיו" יש לנו את :', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 44, '3-02201', 'עכשיו', 'ADESSO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 45, '3-02300', 'אבל אם זה ממש, ממש, דחוף..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 46, '3-02301', 'בהקדם,מיד', 'SUBITO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 47, '3-02400', 'ומכאן, אם רוצים לבטא דחיפות..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 48, '3-02401', 'אני צריך לעזוב מיד', 'DEVO PARTIRE SUBITO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 49, '3-02402', 'גם "אני מוכרח" וגם "בהקדם" – זה כנראה ממש דחוף...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 50, '3-02500', 'הפועל DOVERE נכון בכל הגופים, כמובן – למשל :', '', 'INFO');

-- End of 20251028075335_update_lesson_3_content_part_1.sql

-- Start of 20251028075440_update_lesson_3_content_part_2.sql
/*
  # עדכון תוכן שיעור 3 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('44faec16-0a8a-4452-ac23-dca79cba04f7', 51, '3-02600', 'אתה צריך לעשות את זה', 'DEVI FARLO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 52, '3-02700', 'מתי', 'QUANDO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 53, '3-02800', 'ובשילוב של שני הנ"ל', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 54, '3-02801', 'מתי אתה צריך לעשות את זה ?', 'QUANDO DEVI FARLO ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 55, '3-02802', 'יש לנו שוב תופעת "הפועל השני"', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 56, '3-02900', 'ניזכר ש..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 57, '3-02901', 'לאמור או להגיד', 'DIRE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 58, '3-03000', 'מכאן שאם הפועל מופיע באמצע המשפט כפועל שני נקבל..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 59, '3-03001', 'להגיד לו', 'DIRLO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 60, '3-03100', 'או אם מדובר בי..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 61, '3-03101', 'להגיד לי', 'DIRMI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 62, '3-03201', 'או בך..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 63, '3-03202', 'להגיד לך', 'DIRTI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 64, '3-03203', 'או פנייה מנומסת...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 65, '3-03300', 'תוכל להגיד לי', 'PUOI DIRMI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 66, '3-03301', 'או בשאלה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 67, '3-03401', 'האם תוכל להגיד לי', 'PUOI DIRMI ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 68, '3-03500', 'או שאלה רחבה יותר..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 69, '3-03501', 'אתה יכול להגיד לי למה אתה לא יכול לעשות את זה כך', 'PUOI DIRMI PERCHÉ NON PUOI FARLO COSÌ ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 70, '3-03600', 'קבוצה מס 7 - מילים באנגלית שמסתיימות ב ICAL כמו POLITICAL', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 71, '3-03601', 'באנגלית POLITICAL ובאיטלקית..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 72, '3-03602', 'פוליטי/ת', 'POLITICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 73, '3-03603', 'או במין נקבה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 74, '3-03604', 'פוליטית', 'POLITICA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 75, '3-03700', 'באנגלית ECONOMICAL ובאיטלקית..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 76, '3-03701', 'כלכלי', 'ECONOMICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 77, '3-03702', 'או במין נקבה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 78, '3-03703', 'כלכלית', 'ECONOMICA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 79, '3-03704', 'שימו לב - זו לא ההאקונומיקה לניקוי הבית ...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 80, '3-03705', 'דוגמא לנ"ל – תיאור של שם עצם נקבי', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 81, '3-03706', 'מצב כלכלי', 'LA SITUAZIONE POLITICA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 82, '3-03800', 'באנגלית PHILOSOFICAL ובאיטלקית..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 83, '3-03801', 'פילוסופי', 'FILOSOFICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 84, '3-03802', 'שימו לב שבאיטלקית ה"F" הוא לא "PH"....', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 85, '3-03803', 'פילוסופית', 'FILOSOFICA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 86, '3-03804', 'באנגלית LOGICAL ובאיטלקית', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 87, '3-03901', 'לוגי', 'LOGICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 88, '3-03902', 'אבל נבטא את זה "לוֹגִ׳יקוֹֹ"', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 89, '3-03903', 'באנגלית PRACTICAL ובאיטלקית', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 90, '3-03904', 'פרקטי', 'PRATICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 91, '3-03905', 'שימו לב – חסרה אות "סי"', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 92, '3-03906', 'ובמשפט משולב.', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 93, '3-04000', 'זה לא לוגי אבל זה מאד פרקטי כך', 'NON È LOGICO MA È MOLTO PRATICO COSÌ', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 94, '3-04100', 'ומילה חיבור קטנה אך מאד, מאד שימושית...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 95, '3-04101', 'ב ....', 'IN', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 96, '3-04200', 'ובמשפט..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 97, '3-04201', 'המצב הפוליטי באיטליה', 'LA SITUAZIONE POLITICA IN ITALIA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 98, '3-04301', 'או..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 99, '3-04302', 'המצב הכלכלי בספרד', 'LA SITUAZIONE ECONOMICA IN SPAGNA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 100, '3-04303', 'אחד ממילות החיבור החשובות בכל שפה...', '', 'INFO');

-- End of 20251028075440_update_lesson_3_content_part_2.sql

-- Start of 20251028075548_update_lesson_3_content_part_3.sql
/*
  # עדכון תוכן שיעור 3 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('44faec16-0a8a-4452-ac23-dca79cba04f7', 101, '3-04400', 'וו החיבור', 'E', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 102, '3-04402', 'המצב הפוליטי והכלכלי', 'LA SITUAZIONE POLITICA ED ECONOMICA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 103, '3-04500', 'בספרד', 'IN SPAGNA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 104, '3-04601', 'במקסיקו', 'IN MESSICO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 105, '3-04701', 'בארגנטינה', 'IN ARGENTINA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 106, '3-04702', 'ייקרא "אָרְגֶ׳נְטִינָה"', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 107, '3-04801', 'איזה רושם יש לך על המצב הפוליטי והכלכלי באיטליה עכשיו ?', 'CHÉ IMPRESSIONE HAI DELLA SITUAZIONE POLITICA ED ECONOMICA IN ITALIA, ADESSO ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 108, '3-04802', 'ונמשיך..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 109, '3-04900', 'כמה', 'QUANTO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 110, '3-04901', 'זכרו – QUANTITY באנגלית זה כמות – ולא להתבלבל עם QUANDO שזה מתי', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 111, '3-04902', 'מילת קישור קטנה וסופר חשובה...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 112, '3-05000', 'אם, (גם - כן)', 'SE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 113, '3-05002', 'ונשלב את זה במשפט (הארוך, בסוף..)...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 114, '3-05100', 'אנא אמור לי כמה זה', 'PUOI DIRMI QUANTO È', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 115, '3-05101', 'המשך טבעי...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 116, '3-05200', 'כי אני צריך את זה', 'PERCHÉ NE HO BISOGNO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 117, '3-05201', 'ונחבר אליו עוד משפט..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 118, '3-05300', 'ואני רוצה שיהיה לי את זה', 'E VOGLIO AVERLO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 119, '3-05301', 'שוב, שימו לב AVERE זה שם הפועל כי הוא מופיע שני', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 120, '3-05302', 'ועוד משפט אחד....', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 121, '3-05400', 'ואני רוצה לקנות אותו', 'E VOGLIO COMPRARLO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 122, '3-05401', 'והמשפט האחרון – שורת המחץ !!', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 123, '3-05500', 'אם זה לא יקר מדי', 'SE NON È TROPPO CARO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 124, '3-05501', 'ונחבר הכל בעזרת E – יוצא לנו משפט ממש ארוך...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 125, '3-05600', 'אנא אמור לי כמה זה כי אני צריך את זה ואני רוצה שיהיה לי את זה ואני רוצה לקנות אותו אם זה לא יקר מדי', 'PUOI DIRMI QUANTO È PERCHÉ NE LO BISOGNO E VOGLIO AVERLO E VOGLIO COMPRARLO SE NON È TROPPO CARO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 126, '3-05601', 'עכשיו עולים כתה....', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 127, '3-05700', 'הטיות הפועל "להיות" - ESSERE', 'SONO , SEI , È , SIAMO , … , SONO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 128, '3-05702', 'באנגלית נגיד I AM OCCUPIED באיטלקית :', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 129, '3-05800', 'אני עסוק', 'SONO OCCUPATO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 130, '3-05801', 'אם הדוברת אישה,', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 131, '3-05900', 'אני עסוקה', 'SONO OCCUPATA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 132, '3-05901', 'או מילה נפוצה אחרת..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 133, '3-06000', 'עייף', 'STANCO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 134, '3-06001', 'אם הדוברת אישה...', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 135, '3-06002', 'עייפה', 'STANCA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 136, '3-06202', 'ונחזור לשימוש של I AM (SONO)', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 137, '3-06300', 'אני עייף', 'SONO STANCO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 138, '3-06301', 'אם הדוברת אישה', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 139, '3-06400', 'אני עייפה', 'SONO STANCA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 140, '3-06600', 'אני לא עייף מדי היום', 'NON SONO TROPPO STANCO, OGGI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 141, '3-06700', 'נמשיך עם הפועל הזה..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 142, '3-06701', 'אתה..YOU ARE', 'SEI', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 143, '3-06702', 'ובמשפט', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 144, '3-06800', 'אתה עסוק', 'SEI OCCUPATO', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 145, '3-06801', 'ובשאלה..', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 146, '3-06900', 'את עסוקה כרגע ?', 'SEI OCCUPATA ADESSO ?', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 147, '3-06901', 'אבל שימו לב ל "QUESTA" - ללא דגש זה "זה" - נתרגל....', '', 'INFO'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 148, '3-07000', 'הלילה הזה', 'QUESTA NOTTE', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 149, '3-07100', 'הבית הזה', 'QUESTA CASA', 'LANG'),
('44faec16-0a8a-4452-ac23-dca79cba04f7', 150, '3-07200', 'השולחן הזה', 'QUESTO TAVOLO', 'LANG');

-- End of 20251028075548_update_lesson_3_content_part_3.sql

-- Start of 20251028080316_update_lesson_4_content_part_1.sql
/*
  # עדכון תוכן שיעור 4 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 4
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 4
DELETE FROM lines WHERE lesson_id = '8ae7189d-70fb-4db3-bf53-9848e3e73ad2';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 1, '4-00100', 'בשיעור הזה נתעסק בעיקר בפעלים...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 2, '4-00101', 'ונתחיל בפועל הנפוץ – להיות – בשתי צורותיו ESSERE ו STARE– זמני וקבוע..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 3, '4-00200', 'אני רוצה לדעת איך מאוריציו מרגיש היום', 'VOGLIO SAPERE COME STA MAURICIO OGGI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 4, '4-00300', 'מאוריציו חולה היום', 'MAURICIO STA MALATO OGGI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 5, '4-00400', 'חולה', 'MALATO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 6, '4-00402', 'ומה שונה כ"כ במשפט הדומה ?!?? – הרי רק השתמשנו בוורסיה אחרת של "להיות"...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 7, '4-00500', 'מאוריציו הוא אדם חולני', 'MAURICIO È MALATO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 8, '4-00501', 'È - להבדיל מ STA (בא מהפועל STARE ולא מהפועל ESSERE)', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 9, '4-00502', 'עוד דוגמא כמו הנ"ל..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 10, '4-00600', 'שיכור', 'UBRIACO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 11, '4-00700', 'מאוריציו שיכור היום', 'MAURICIO STA UBRIACO OGGI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 12, '4-00701', 'שמשמעותו שמצבו הרגעי, העכשווי, היום, של מאוריציו הוא שהוא שיכור ולכן השתמשנו ב STARE', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 13, '4-00800', 'מאוריציו הוא אלכוהוליסט', 'MAURICIO È UBRIACO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 14, '4-00801', 'אנחנו מתכוונים לכך שמאוריציו תמיד שיכור, שתיין, זה הופך לתכונה שלו', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 15, '4-00802', 'ע"מ להמחיש את זה יותר טוב, אשתמש בבדיחה – מספרים שחברת פרלמנט מהאופוזיציה אמרה לצ׳רצ׳יל', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 16, '4-00803', 'אני מקווה שההבדל בין STARE ל ESSERE יותר ברור עתה', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 17, '4-00804', 'דוגמה נוספת..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 18, '4-00900', 'לבוש', 'VESTITO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 19, '4-01000', 'לבוש טוב', 'BEN VESTITO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 20, '4-01100', 'מאוריציו לבוש טוב היום', 'MAURICIO STA BEN VESTITO OGGI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 21, '4-01101', 'כי זה מצב חד פעמי שעונה לשאלה "איך הוא היום"', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 22, '4-01102', 'אבל, אם נרצה להגיד שזאת תכונה של מאוריציו, נגיד..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 23, '4-01200', 'מאוריציו מתלבש תמיד יפה תמיד', 'MAURICIO È VESTITO SEMPRE BENE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 24, '4-01300', 'תמיד', 'SEMPRE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 25, '4-01301', 'דוגמא נוספת :', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 26, '4-01400', 'אני מורה', 'SONO UN INSEGNANTE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 27, '4-01401', 'כלומר, הוראה זה המקצוע שלי', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 28, '4-01402', 'להבדיל מ...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 29, '4-01500', 'אני מורה כרגע (שחקן אולי)', 'STO UN INSEGNANTE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 30, '4-01501', 'יכול להגיד שחקן תיאטרון שמשחק תפקיד של מורה', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 31, '4-01802', 'עוד פעלים :', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 32, '4-01900', 'לדבר', 'PARLARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 33, '4-02000', 'לקחת', 'PRENDERE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 34, '4-02001', 'ראינו שהפועל הזה שימושי גם לשתות למשקאות חריפים...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 35, '4-02100', 'להגיד', 'DIRE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 36, '4-02200', 'לאכול', 'MANGIARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 37, '4-02300', 'לקנות', 'COMPRARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 38, '4-02301', 'באנגלית זה TO PREPARE ובאיטלקית..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 39, '4-02500', 'להכין', 'PREPARARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 40, '4-02501', 'ובמשפט...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 41, '4-02600', 'אתה יכול להכין את ארוחת הערב עבורי', 'PUOI PREPARARE LA CENA PER ME', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 42, '4-02601', 'משפט ברבים..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 43, '4-02700', 'אתם יכולים לקבל את התנאי ?', 'POTETE ACCETTARE LA CONDIZIONE ?', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 44, '4-02702', 'ההטיות של הפועל POTERE', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 45, '4-02800', 'הטיות הווה לפועל POTERE', 'POSSO, PUOI, PUÓ, POSSIAMO, POTETE, POSSONO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 46, '4-02801', 'ולמילה מאד שימושית נוספת...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 47, '4-02802', 'באנגלית זה MUCH ובאיטלקית..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 48, '4-02900', 'הרבה', 'MOLTO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 49, '4-02901', 'ובמשפט "מפוצץ" במילים...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 50, '4-03000', 'אני רוצה מאד לקבל את התנאי אבל אני מצטער אני לא יכול לקבל אותו כי זה לא מקובל עלי כך', 'VOGLIO MOLTO ACCETTARE LA CONDIZIONE MA, MI DISPIACE, NON PUOI ACCETTARLA PERCHÉ NON È ACCETTABILE PER ME COSÌ', 'LANG');

-- End of 20251028080316_update_lesson_4_content_part_1.sql

-- Start of 20251028080422_update_lesson_4_content_part_2.sql
/*
  # עדכון תוכן שיעור 4 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 51, '4-03001', 'המשפט הארוך הזה בעצם מורכב מכמה משפטים קצרים', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 52, '4-03002', 'אני רוצה מאד לקבל את התנאי', 'VOGLIO MOLTO ACCETTARE LA CONDIZIONE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 53, '4-03003', 'מילה קישור..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 54, '4-03004', 'אבל – מילת קישור', 'MA', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 55, '4-03005', 'אני מצטער', 'MI DISPIACE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 56, '4-03006', 'לא יכול לקבל אותה', 'NON PUOI ACCETTARLA', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 57, '4-03007', 'שוב מילת קישור..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 58, '4-03008', 'בגלל ש.- מילת קישור', 'PERCHÉ', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 59, '4-03009', 'זה לא מקובל עלי כך', 'NON È ACCETTABILE PER ME COSÌ', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 60, '4-03302', 'התצורה הבסיסית של הפעלים - הסיומות הן ARE ERE ו IRE', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 61, '4-03400', 'לדבר', 'PARLARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 62, '4-03500', 'להסתכל', 'GUARDARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 63, '4-03600', 'לקנות', 'COMPRARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 64, '4-03700', 'להבין', 'CAPIRE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 65, '4-03800', 'לעשות', 'FARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 66, '4-03900', 'להכין', 'PREPARARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 67, '4-04000', 'לקבל', 'ACCETTARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 68, '4-04100', 'לבוא', 'VENIRE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 69, '4-04101', 'תזכורת - יבוטא בֶּנִיר', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 70, '4-04102', 'ועכשיו נתעסק מעט עם מילות קישור...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 71, '4-04200', 'עם', 'CON', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 72, '4-04300', 'ללא', 'SENZA', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 73, '4-04400', 'איתי', 'CON ME', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 74, '4-04500', 'אתך', 'CON TE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 75, '4-04800', 'איתו', 'CON LUI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 76, '4-04801', 'איתה', 'CON LEI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 77, '4-04900', 'אתנו', 'CON NOI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 78, '4-04901', 'אתכם', 'CON VOI', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 79, '4-04902', 'איתם', 'CON LORO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 80, '4-04903', 'ונראה איך זה נראה במשפט...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 81, '4-05000', 'האם אתה יכול לדבר איטלקית איתי', 'PUOI PARLARE ITALIANO CON ME ?', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 82, '4-05001', 'כמו שכבר ראינו, אם יש שניים או יותר פעלים רציפים במשפט', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 83, '4-05002', 'ודוגמא נוספת..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 84, '4-05100', 'אתה יכול לבוא איתי', 'PUOI VENIRE CON ME ?', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 85, '4-05101', 'נחזור לעתיד הקרוב..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 86, '4-05200', 'אני הולך לראות את הסרט אתך הלילה', 'VADO A VEDERE IL FILM CON TE STASERA', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 87, '4-05201', 'או..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 88, '4-05300', 'אני הולך לראות את הסרט אתך הלילה', 'VADO A VEDERE IL FILM CON TE QUESTA NOTTE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 89, '4-05302', 'ועכשיו לנושא אחר..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 90, '4-05400', 'סרט', 'FILM', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 91, '4-05401', 'באנגלית CINEMA ובאיטלקית..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 92, '4-05402', 'קולנוע', 'CINEMA', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 93, '4-05403', 'אני הולך לראות את הסרט אתך הלילה', 'VADO A VEDERE IL FILM CON TE QUESTA NOTTE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 94, '4-05404', 'או', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 95, '4-05500', 'אתה יכול לבוא הלילה לראות איתי סרט', 'PUOI VENIRE STASERA A VEDERE UN FILM CON ME', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 96, '4-05501', 'או בקיצור, אחרי שכל הנוכחים יודעים במה מדובר..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 97, '4-05600', 'אתה יכול לבוא לראות אותה', 'PUOI VENIRE A VEDERLO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 98, '4-05700', 'ללכת באיטלקית זה ANDARE – מאד יוצא דופן', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 99, '4-05701', 'ניזכר - ההטייה בהווה של הפועל ANDARE', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 100, '4-05702', 'הטיות הווה לפועל ANDARE = ללכת', 'VADO , VAI , VA , ANDIAMO,…,VANNO', 'LANG');

-- End of 20251028080422_update_lesson_4_content_part_2.sql

-- Start of 20251028080532_update_lesson_4_content_part_3.sql
/*
  # עדכון תוכן שיעור 4 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 101, '4-05703', 'אם נרצה להגיד :', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 102, '4-05800', 'אני מוכרח ללכת לראות את זה', 'DEVO ANDARE A VEDERLO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 103, '4-05801', 'גם כאן הפועל ANDARE בא שני, לכן הוא מופיע לא בהטייה', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 104, '4-06001', 'ומשפט נוסף עם "אני חייב" DEVO', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 105, '4-06100', 'אני מוכרח לדבר אתך (חברי)', 'DEVO PARLARE CON TE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 106, '4-06103', 'משפט ארוך – בחלקו הראשון הווה ובחלקו השני, אחרי PERCHÉ – עתיד קרוב', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 107, '4-06300', 'אני מצטער אבל איני יכול לראותך היום כי אני הולך להיות מאד עסוק', 'MI DISPIACE MA NON POSSO VEDERTI OGGI PERCHÉ VADO A ESSERE MOLTO OCCUPATO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 108, '4-06301', 'ולעניינים אחרים...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 109, '4-06400', 'ספר', 'LIBRO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 110, '4-06401', 'זוכרים – מאד חשוב לתיירים ?', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 111, '4-06500', 'לקנות', 'COMPRARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 112, '4-06600', 'אני מוכרח לקנות את הספר', 'DEVO COMPRARE QUESTO LIBRO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 113, '4-06601', 'המשך המשפט..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 114, '4-06700', 'אבל אני לא יכול לקנות אותו כי הוא מאד יקר', 'MA NON POSSO COMPRARLO PERCHÉ È MOLTO COSTOSO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 115, '4-06701', 'וביחד..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 116, '4-06800', 'אני מוכרח לקנות את הספר אבל אני לא יכול לקנות אותו כי הוא מאד יקר', 'DEVO COMPRARE QUESTO LIBRO MA NON POSSO COMPRARLO PERCHÉ È MOLTO COSTOSO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 117, '4-06801', 'בשתי הפעמים שהמילה COMPRARE מופיעה, הוא פועל שני', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 118, '4-06802', 'גם וגם, המשפט הארוך מורכב משלושה משפטים קצרים', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 119, '4-06900', 'שאלות חשובות :', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 120, '4-06901', 'איפה זה ?', 'DOV''È ?', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 121, '4-07000', 'כמה זה ?', 'QUANTO È', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 122, '4-07001', 'שאלה זו מתייחסת למחירים שפעם היו כנראה קבועים...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 123, '4-07002', 'ניזכר שלפגוש או למצא זה..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 124, '4-07200', 'למצוא, לפגוש', 'TROVARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 125, '4-07201', 'וגם...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 126, '4-07202', 'למצוא', 'TROVARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 127, '4-07203', 'ובמשפט..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 128, '4-07204', 'אני לא יכול למצוא את זה', 'NON POSSO TROVARLO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 129, '4-07205', 'ניזכר שאם הפועל בא שני, כמו TROVARE, המושא LO יבוא אחריו', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 130, '4-07206', 'וניזכר שלפועל SAPERE יש גוף ראשון הווה אנומליה – יהיה SO', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 131, '4-07400', 'אני לא יודע איפה זה', 'NON SO DOV''È', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 132, '4-07402', 'תוכל להגיד לי איפה זה כי אינני יכול למצוא אותו', 'PUOI DIRMI DOVE È, PERCHÉ NON POSSO TROVARLO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 133, '4-07404', 'ושוב נתעסק בפעלים כי זה עמוד השדרה של כל שפה ..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 134, '4-07500', 'לדבר', 'PARLARE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 135, '4-07601', 'ניזכר שכשפועל בא לבד (או ראשון) המושא, כמו LO בא לפני ההטייה שלו', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 136, '4-07602', 'אני קונה את זה', 'LO COMPRO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 137, '4-07603', 'ובשלילה..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 138, '4-07604', 'אני לא קונה את זה', 'NON LO COMPRO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 139, '4-07701', 'ומילה לא פחות חשובה לתייר...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 140, '4-07800', 'למכור', 'VENDERE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 141, '4-07801', 'ייקרא בֶּנְדֶר', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 142, '4-07802', 'ובהטייה (אני מוכר) כשהמושא לפניו..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 143, '4-07900', 'אני מוכר את זה', 'LO VENDO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 144, '4-07901', 'ובשלילה..', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 145, '4-08000', 'אני לא מוכר את זה', 'NON LO VENDO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 146, '4-08001', 'ועכשיו לתובנות...', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 147, '4-08100', 'להבין', 'CAPIRE', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 148, '4-08101', 'הטיות הפועל....', '', 'INFO'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 149, '4-08200', 'הטיות הפועל CAPIRE', 'CAPISCO, CAPISCI, CAPISCE, CAPIAMO, …, CAPISCONO', 'LANG'),
('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 150, '4-08400', 'אני מבין את זה היטב', 'LO CAPISCO MOLTO BENE', 'LANG');

-- End of 20251028080532_update_lesson_4_content_part_3.sql

-- Start of 20251028081216_update_lesson_5_content_part_1.sql
/*
  # עדכון תוכן שיעור 5 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 5
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 5
DELETE FROM lines WHERE lesson_id = '56e9a5fe-3c79-4c46-8894-92988329ed76';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('56e9a5fe-3c79-4c46-8894-92988329ed76', 1, '5-00100', 'בשיעור הזה נתעסק בעיקר בדקויות שפה והטיית פעלים...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 2, '5-00200', 'מי', 'CHI', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 3, '5-00201', 'ונשלב במשפט שאלה..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 4, '5-00300', 'מי מדבר אנגלית פה ?', 'CHI PARLA INGLESE QUI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 5, '5-00301', 'אחת התשובות האפשריות..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 6, '5-00400', 'אף אחד', 'NESSUNO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 7, '5-00500', 'אף אחד לא מדבר אנגלית כאן', 'NESSUNO PARLA INGLESE QUI', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 8, '5-00501', 'לעומת זאת...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 9, '5-00600', 'כולם', 'TUTTI', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 10, '5-00701', 'שימו לב שהפועל בגוף שלישי יחיד כי הוא מתייחס לקהל הכללי', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 11, '5-00703', 'כולם מדברים איטלקית', 'TUTTI PARLANO ITALIANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 12, '5-00704', 'במשפט הזה הוספנו N וזה עבר לגוף שלישי רבים PARLANO', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 13, '5-00705', 'ואלה שכבר יודעים קצת איטלקית ישאלו..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 14, '5-00800', 'למה אתה לא מדבר איטלקית איתי ?', 'PERCHÉ NON PARLI ITALIANO CON ME ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 15, '5-00801', 'ונעבור לנושא לא פחות רלוונטי – קניות ..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 16, '5-00900', 'לקנות', 'COMPRARE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 17, '5-01000', 'אני קונה את זה', 'LO COMPRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 18, '5-01001', 'תזכורת – כשהפועל ראשון או יחד, המושא (LO למשל) בא לפניו והפועל בא בהטייה', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 19, '5-01002', 'ובשלילה..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 20, '5-01100', 'אני לא קונה את זה', 'NON LO COMPRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 21, '5-01101', 'ושאלה של מוכרנים לתיירים...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 22, '5-01200', 'למה אינך קונה את זה ?', 'PERCHÉ NON LO COMPRI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 23, '5-01201', 'והתשובה..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 24, '5-01300', 'אני לא יודע למה אני לא קונה את זה', 'NON SO PERCHÉ NON LO COMPRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 25, '5-01301', 'או..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 26, '5-01302', 'אני לא קונה את זה כי אני לא רוצה לקנות אותו', 'NON LO COMPRO PERCHÉ NON VOGLIO COMPRARLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 27, '5-01303', 'שימו לב – כאן המושא בא פעם לפני ופעם אחרי הפועל, תלוי במיקומו...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 28, '5-01304', 'ומנושא לנושא באותו נושא..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 29, '5-01305', 'למכור', 'VENDERE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 30, '5-01400', 'למה אתה לא מוכר את זה ?', 'PERCHÉ NON LO VENDI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 31, '5-01401', 'והתשובה המפורטת – בעברית – "ככה" ובאיטלקית ..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 32, '5-01500', 'אני לא מוכר את זה כי אני לא רוצה למכור את זה', 'NON LO VENDO PERCHÉ NON VOGLIO VENDERLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 33, '5-01600', 'חזרה קצרה...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 34, '5-01601', 'הטיות הפועל לדבר..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 35, '5-01602', 'הטיות הפועל לדבר..PARLARE', 'PARLO, PARLI, PARLA , PARLIAMO .. , PARLANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 36, '5-01603', 'פועל חשוב אחר', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 37, '5-01800', 'להבין', 'CAPIRE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 38, '5-01900', 'אני מבין', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 39, '5-01901', 'הטיות הפועל להבין - CAPIRE', 'CAPISCO, CAPISCI, CAPISCE, CAPIAMO, …, CAPISCONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 40, '5-02002', 'ועוד דוגמאות..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 41, '5-02100', 'לעזוב', 'PARTIRE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 42, '5-02400', 'אתם, הם מדברים', 'PARLANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 43, '5-02500', 'אתם, הם מבינים', 'CAPISCONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 44, '5-02600', 'הם עוזבים', 'PARTONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 45, '5-02700', 'הם באים', 'ARRIVANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 46, '5-02800', 'הם עושים זאת', 'LO FANNO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 47, '5-02900', 'הם קונים את זה', 'LO COMPRANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 48, '5-03000', 'הם מוכרים את זה', 'LO VENDONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 49, '5-03001', 'עוד שאלות, ובאיטלקית...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 50, '5-03200', 'למה אתה לא מוכר את זה ?', 'PERCHÉ NON LO VENDI ?', 'LANG');

-- End of 20251028081216_update_lesson_5_content_part_1.sql

-- Start of 20251028081325_update_lesson_5_content_part_2.sql
/*
  # עדכון תוכן שיעור 5 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('56e9a5fe-3c79-4c46-8894-92988329ed76', 51, '5-03201', 'ושאלת תוכחה !', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 52, '5-03300', 'למה אתה לא עושה את זה', 'PERCHÉ NON LO FAI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 53, '5-03301', 'וגם ברבים :', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 54, '5-03500', 'למה אתם לא עושים את זה ? (מנומס) כי משתמשים בגוף שלישי רבים', 'PERCHÉ NON LO FANNO , VOI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 55, '5-03601', 'קבלו כאן כמה הטיות הווה של פעלים שימושיים..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 56, '5-03602', 'הטיות הווה לפועל PARLARE לדבר', 'PARLO, PARLI, PARLA , PARLIAMO …, PARLANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 57, '5-03700', 'הטיות הווה לפועל MANGIARE לאכול', 'MANGIO, MANGI, MANGIA, MANGIAMO, .., MANGIANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 58, '5-03800', 'הטיות הווה לפועל CAPIRE להבין', 'CAPISCO, CAPISCI, CAPISCE, CAPIAMO, …, CAPISCONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 59, '5-03900', 'הטיות הווה לפועל VENIRE לבוא', 'VENGO, VIENI, VIENE, VENIAMO,…, VENGONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 60, '5-04000', 'הטיות הווה לפועל PARTIRE לעזוב', 'PARTO, PARTI, PARTE, PARTIAMO, …., PARTONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 61, '5-04100', 'הטיות הווה לפועל FARE לעשות', 'FACCIO , FAI , FA , FACCIAMO,…,FANNO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 62, '5-04200', 'הטיות הווה לפועל DIRE להגיד', 'DICO , DICI , DICE , DICIAMO, … , DICONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 63, '5-04201', 'ונמשיך ב "בודדת"..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 64, '5-04300', 'אני רוצה', 'VOGLIO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 65, '5-04400', 'אתה רוצה', 'VUOI', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 66, '5-04500', 'אני יכול', 'POSSO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 67, '5-04600', 'אני מדבר', 'PARLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 68, '5-04700', 'אני לא מדבר', 'NON PARLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 69, '5-04800', 'אני מבין', 'CAPISCO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 70, '5-04900', 'אני לא מבין', 'NON CAPISCO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 71, '5-05000', 'אתה מבין', 'CAPISCI', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 72, '5-05001', 'שאלות מאד חשובות לתייר...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 73, '5-05100', 'אתה מבין את זה ?', 'LO CAPISCI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 74, '5-05200', 'אתה מבין אותי ?', 'MI CAPISCI?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 75, '5-05300', 'אתה לא מבין אותי ?', 'NON MI CAPISCI?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 76, '5-05301', 'והשאלה המתבקשת...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 77, '5-05400', 'למה אתה לא מבין אותי ?', 'PERCHÉ NON MI CAPISCI?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 78, '5-05401', 'וגוף שלישי רבים..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 79, '5-05500', 'הם מבינים', 'CAPISCONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 80, '5-05600', 'הם מדברים', 'PARLANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 81, '5-05700', 'אני הולך -מהפועל ANDARE', 'VADO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 82, '5-05701', 'I AM – מהפועל STARE', 'STO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 83, '5-05702', 'I AM – מהפועל ESSERE', 'SONO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 84, '5-05703', 'אני נותן – מהפועל DARE', 'DO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 85, '5-05704', 'יוצא מן הכלל, אבל לגמרי, זה הגוף הראשון של הפועל SAPERE', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 86, '5-05800', 'אני יודע – מהפועל SAPERE', 'SO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 87, '5-05801', 'ובשלילה..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 88, '5-05900', 'אני לא יודע', 'NON SO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 89, '5-06000', 'אני לא יודע את זה', 'NON LO SO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 90, '5-06100', 'דוגמאות לפעלים מקבוצת ה ARE', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 91, '5-06101', 'דוגמאות לפעלי "AR" - להתחיל, לאכול ארוחת ערב, לקנות, להתחתן, לקרא (למישהו), לדבר, להכין, להסכים, לפגוש', 'INIZIARE, CENARE, COMPRARE, SPOSARE, CHIAMARE, PARLARE, PREPARARE, ACCETTARE, INCONTRARE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 92, '5-06200', 'דוגמאות לפעלים מקבוצת ה-לא AR', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 93, '5-06201', 'דוגמאות לפעלי לא-"AR" – להבין, לאכול, לשתות, להרגיש, לרצות, להיות מסוגל, למכור, לתרגם, לכתוב', 'CAPIRE, MANGIARE, BERE, SENTIRE, VOLERE, POTERE, VENDERE, TRADURRE, SCRIVERE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 94, '5-06300', 'חזרה קצרה בענייני קנייה-מכירה...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 95, '5-06301', 'למה אתה לא קונה את זה ?', 'PERCHÉ NON LO COMPRI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 96, '5-06302', 'ומצד השני..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 97, '5-06303', 'למכור', 'VENDERE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 98, '5-06400', 'אני מוכר את זה', 'LO VENDO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 99, '5-06500', 'למה אתה לא מוכר את זה?', 'PERCHÉ NON LO VENDI ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 100, '5-06600', 'למה אתם לא מוכרים את זה', 'PERCHÉ NON LO VENDONO ?', 'LANG');

-- End of 20251028081325_update_lesson_5_content_part_2.sql

-- Start of 20251028081427_update_lesson_5_content_part_3.sql
/*
  # עדכון תוכן שיעור 5 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('56e9a5fe-3c79-4c46-8894-92988329ed76', 101, '5-06900', 'הם לא קונים את זה', 'NON LO COMPRANO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 102, '5-06901', 'והשאלה המתבקשת...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 103, '5-07000', 'למה אתם לא קונים את זה', 'PERCHÉ NON LO COMPRANO ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 104, '5-07001', 'עכשיו נלמד את מילות הגוף הנפוצות - ה"זה, זאת, אלה"', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 105, '5-07100', 'ההוא', 'QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 106, '5-07101', 'ההיא', 'QUELLA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 107, '5-07102', 'ההוא (בלי לציין מין) – בא לבד', 'QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 108, '5-07103', 'הזה', 'QUESTO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 109, '5-07104', 'הזאת', 'QUESTA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 110, '5-07105', 'הזה (בלי לציין מין) – בא לבד', 'QUESTO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 111, '5-07107', 'כמה דוגמאות...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 112, '5-07200', 'הלילה הזה (מה לעשות, הלילה הוא נקבי באיטלקית)', 'QUESTA NOTTE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 113, '5-07300', 'השולחן הזה (מה לעשות, השולחן הוא נקבי באיטלקית)', 'QUESTO TAVOLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 114, '5-07400', 'הבית הזה (מה לעשות, הבית הוא נקבי באיטלקית)', 'QUESTA CASA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 115, '5-07500', 'הבית ההוא (מה לעשות, הבית הוא נקבי באיטלקית)', 'QUELLA CASA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 116, '5-07600', 'הספר הזה', 'QUESTO LIBRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 117, '5-07700', 'הספר ההוא', 'QUELLO LIBRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 118, '5-07900', 'אני רוצה לראות את ההוא', 'VOGLIO VEDERE QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 119, '5-07901', 'ועכשיו, שילוב של שני דברים שלמדנו – "עתיד קרוב" ו"זה"', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 120, '5-08000', 'אני הולך לקנות את זה – בד"כ מצביעים', 'VADO A COMPRARE QUESTO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 121, '5-08001', 'או...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 122, '5-08100', 'רוצה לקנות את ההוא - בד"כ מצביעים', 'VOGLIO COMPRARE QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 123, '5-08200', 'למה אתה לא קונה את הספר הזה ?', 'PERCHÉ NON COMPRI QUESTO LIBRO ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 124, '5-08201', 'ונחזור על הנ"ל...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 125, '5-08300', 'הלילה הזה', 'QUESTA NOTTE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 126, '5-08301', 'נזכור ש"לילה" באיטלקית זה ממין נקבה', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 127, '5-08400', 'השולחן הזה', 'QUESTO TAVOLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 128, '5-08401', 'גם "שולחן" הוא ממין נקבה באיטלקית', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 129, '5-08500', 'הבית הזה', 'QUESTA CASA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 130, '5-08502', 'וכמה דוגמאות ל"זה" המרוחק (לא פה, שם..)', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 131, '5-08600', 'הבית ההוא', 'QUELLA CASA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 132, '5-08601', 'השולחן ההוא', 'QUELLO TAVOLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 133, '5-08602', 'הלילה ההוא', 'QUELLA NOTTE', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 134, '5-08700', 'הספר ההוא', 'QUELLO LIBRO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 135, '5-08701', 'ו"זה" כללי, כשלא יודעים את שם/מין האוביאקט שמצביעים עליו...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 136, '5-08900', 'הזה', 'QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 137, '5-08901', 'או..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 138, '5-08902', 'הזאת', 'QUELLA', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 139, '5-08903', 'למשל...', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 140, '5-09000', 'אני רוצה לראות את זה - בד"כ מצביעים', 'VOGLIO VEDERE QUESTO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 141, '5-09001', 'או..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 142, '5-09100', 'אני הולך לקנות את זה - בד"כ מצביעים', 'VADO A COMPRARE QUESTO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 143, '5-09101', 'או..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 144, '5-09200', 'רוצה לקנות את ההוא - בד"כ מצביעים', 'VOGLIO COMPRARE QUELLO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 145, '5-09201', 'או במשפט שאלה..', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 146, '5-09300', 'למה אתה לא קונה את הספר הזה ?', 'PERCHÉ NON COMPRI QUESTO LIBRO ?', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 147, '5-09301', 'ונתקדם בהטיות....', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 148, '5-09302', 'גוף ראשון רבים הווה יסתיים תמיד בסיומת AMO כמו המילה המוכרת ANDIAMO', '', 'INFO'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 149, '5-09400', 'אנחנו מדברים', 'PARLIAMO', 'LANG'),
('56e9a5fe-3c79-4c46-8894-92988329ed76', 150, '5-09600', 'אנחנו אוכלים', 'MANGIAMO', 'LANG');

-- End of 20251028081427_update_lesson_5_content_part_3.sql

-- Start of 20251028081821_update_lesson_6_content_part_1.sql
/*
  # עדכון תוכן שיעור 6 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 6
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 6
DELETE FROM lines WHERE lesson_id = '97409ed0-8b55-424d-b361-0c20a7fbdfaf';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 1, '6-00100', 'בשיעור הזה נתעסק במעט זמנני "התפעל" כמו למשל - להשאיר (רגיל) להישאר (התפעל)', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 2, '6-00101', 'חזרה קצרה...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 3, '6-00200', 'יש לנו', 'ABBIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 4, '6-00201', 'כזכור, לעשות זה FARE', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 5, '6-00300', 'אנחנו עושים את זה', 'LO FACCIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 6, '6-00301', 'ניזכר בהטיות AVERE', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 7, '6-00400', 'הטיות הווה של הפועל AVERE', 'HO, HAI, HA, ABBIAMO,…,HANNO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 8, '6-00401', 'פעלים שימושיים נוספים...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 9, '6-00700', 'להתחיל', 'COMINCIARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 10, '6-00701', 'וההטיות בהווה...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 11, '6-00800', 'הטיות הווה של הפועל COMINCIARE', 'COMINCIO, COMINCI, COMINCIA, COMINCIAMO,…COMINCIANO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 12, '6-00801', 'ובמשפט..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 13, '6-00900', 'באיזה שעה אתה מתחיל', 'A CHE ORA COMINCI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 14, '6-00901', 'או...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 15, '6-01000', 'באיזה שעה מתחיל הסרט ?', 'A CHE ORA COMINCIA IL FILM ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 16, '6-01001', 'אפשר גם...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 17, '6-01002', 'באיזה שעה מתחיל הסרט ?', 'A CHE ORA INIZIA IL FILM ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 18, '6-01003', 'כש...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 19, '6-01100', 'סרט', 'FILM', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 20, '6-01101', 'או בגוף אחר..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 21, '6-01400', 'באיזה שעה אנחנו מתחילים ?', 'A CHE ORA COMINCIAMO ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 22, '6-01500', 'ראינו שיש מילה נוספת ל להתחיל וזה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 23, '6-01501', 'להתחיל', 'INIZIARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 24, '6-01701', 'ועכשיו נתעסק בפועל ממש חשוב...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 25, '6-01800', 'לחשוב', 'PENSARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 26, '6-01801', 'גם כאן יש "שבירה" של ה E ל IE', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 27, '6-01900', 'הטיות הווה של הפועל PENSARE', 'PENSO, PENSI, PENSA, PENSIAMO, …, PENSANO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 28, '6-02001', 'מה אתה חושב ?', 'COSA PENSI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 29, '6-02002', 'אפשר לראות שע"מ להיות יותר "איטלקי" משתמשים ב COSA במקום CHE', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 30, '6-02101', 'או יותר בפירוט..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 31, '6-02200', 'אתה חושב על המצב ?', 'COSA PENSI DELLA SITUAZIONE ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 32, '6-02201', 'אבל בגוף ראשון רבים, כמו שאמרנו...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 33, '6-02300', 'אנחנו חושבים', 'PENSIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 34, '6-02301', 'אני מזכיר – ה-E לא "נשבר" כי הדגש על "A".', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 35, '6-02500', 'אני מתכנן לעזוב בקרוב', 'PENSO PARTIRE PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 36, '6-02600', 'מתי אתה מתכנן לעזוב ?', 'QUANDO PENSI PARTIRE ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 37, '6-02601', 'ועכשיו נתעסק מעט בנושא ההבנות...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 38, '6-02700', 'להבין', 'CAPIRE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 39, '6-02701', 'ושוב, ההטיות של הפועל בהווה', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 40, '6-02702', 'ההטיות של הפועל CAPIRE בהווה', 'CAPISCO, CAPISCI, CAPISCE, CAPIAMO, …, CAPISCONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 41, '6-02703', 'וכמו בפועל רגיל , גוף ראשון יחיד הווה מקבל "O" ותו לא...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 42, '6-02800', 'אני מבין את זה', 'LO CAPISCO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 43, '6-02801', 'או להבין לעומק..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 44, '6-02902', 'אם אומרים לנו משהו ואנחנו לא מבינים, וכתיירים זה יקרה לנו הרבה, נגיד ...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 45, '6-02903', 'אני לא מבין את זה', 'NON LO CAPISCO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 46, '6-03100', 'ויותר ספציפי...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 47, '6-03200', 'אני לא מבין אותך (חברה)', 'NON TI CAPISCO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 48, '6-03201', 'אבל, באותה המידה לגיטימי לשאול את בן שיחנו..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 49, '6-03300', 'האם אתה מבין אותי ?', 'MI CAPISCI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 50, '6-03301', 'ואם מדברים אלינו (כקבוצה) ואנחנו לא מבינים, נוכל להגיד..', '', 'INFO');

-- End of 20251028081821_update_lesson_6_content_part_1.sql

-- Start of 20251028081927_update_lesson_6_content_part_2.sql
/*
  # עדכון תוכן שיעור 6 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 51, '6-03500', 'אנחנו לא מבינים אותך', 'NON TI CAPIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 52, '6-03501', 'שמתם לב ? ה E לא נשבר ל IE כי ההדגשה לא עליו', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 53, '6-03502', 'ועכשיו, נושא אחר – רצונות..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 54, '6-03600', 'לרצות, לאהוב', 'VOLERE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 55, '6-03601', 'וההטיות של זה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 56, '6-03700', 'הטיות הווה של הפועל VOLERE', 'VOGLIO, VUOI, VUOLE, VOGLIAMO, …, VOGLIONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 57, '6-03704', 'למשל, חברנו המוכר POTERE', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 58, '6-03800', 'הטיות הווה של הפועל POTERE', 'POSSO , PUOI , PUO , POSSIAMO ,…, POSSONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 59, '6-03901', 'פועל נפוץ נוסף ...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 60, '6-04000', 'למצוא', 'TROVARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 61, '6-04100', 'הטיות הווה של הפועל TROVARE = למצא', 'TROVO, TROVI, TROVA, TROVIAMO, …, TROVANO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 62, '6-04300', 'לזכור זה RICORDARE (הטייפ-רקורדר "זוכר" את מה שמקליטים עליו)', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 63, '6-04400', 'הטיות הווה של הפועל RICORDARE', 'RICORDO , RICORDI , RICORDA, RICORDIAMO, …, RICORDONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 64, '6-04600', 'הטיות הווה של הפועל RITORNARE', 'RITORNARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 65, '6-04700', 'אני חוזר בקרוב', 'RITORNO PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 66, '6-04701', 'ושאלה מתבקשת...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 67, '6-04800', 'באיזו שעה אתה חוזר ?', 'A CHE ORA RITORNI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 68, '6-04801', 'עוד משפטים עם הפועל הזה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 69, '6-05100', 'אנחנו חוזרים בקרוב', 'RITORNIAMO PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 70, '6-05101', 'ופועל אחר...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 71, '6-05400', 'לקום, להרים (גם לקום בבוקר)', 'ALZARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 72, '6-05401', 'או..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 73, '6-05500', 'להתעורר', 'SVEGLIARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 74, '6-05501', 'ובמשפט יותר שלם...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 75, '6-05600', 'למה אתה לא מרים את זה ?', 'PERCHÉ NON LO ALZI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 76, '6-05608', 'וגוף ראשון ...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 77, '6-05800', 'אני קם', 'MI ALZO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 78, '6-05802', 'שפירושו לקום בבוקר מהמיטה, אני מקים עצמי...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 79, '6-05900', 'אתה יכול להעיר אותי ?', 'PUOI SVEGLIARMI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 80, '6-05901', 'או..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 81, '6-06100', 'אתה יכול להעיר אותנו?', 'PUOI SVEGLIARCI ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 82, '6-06104', 'שימושים נוספים בהתפעל...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 83, '6-06200', 'רוברטו, אתה קם ?', 'TI SVEGLI ? ROBERTO,', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 84, '6-06300', 'באיזה שעה את קמה, רוברטה ?', 'A CHE ORA TI SVEGLI, ROBERTA ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 85, '6-06700', 'הם קמים מוקדם', 'SVEGLIANO PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 86, '6-06701', 'ושילוב עם עתיד קרוב...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 87, '6-06800', 'אני הולך לקום מוקדם', 'VADO A SVEGLIARE PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 88, '6-06801', 'או...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 89, '6-06900', 'אני מוכרח לקום מוקדם', 'DEVO SVEGLIARE PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 90, '6-06901', 'או..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 91, '6-07000', 'אנחנו הולכים לקום מוקדם', 'ANDIAMO A SVEGLIARCI PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 92, '6-07001', 'או...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 93, '6-07002', 'אנחנו קמים מוקדם', 'CI ALZIAMO PRESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 94, '6-07003', 'או...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 95, '6-07100', 'אנחנו מוכרחים לקום', 'DOBBIAMO SVEGLIARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 96, '6-07200', 'באיזו שעה אנחנו צריכים לקום ?', 'A CHÉ ORA DOBBIAMO SVEGLIARE ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 97, '6-07201', 'ועוד פועל מתאים להתפעל..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 98, '6-07202', 'להשאיר', 'LASCIARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 99, '6-07400', 'ואם מוסיפים מסוף SE - זה נהיה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 100, '6-07401', 'ולהישאר', 'RESTARE', 'LANG');

-- End of 20251028081927_update_lesson_6_content_part_2.sql

-- Start of 20251028082026_update_lesson_6_content_part_3.sql
/*
  # עדכון תוכן שיעור 6 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 101, '6-07500', 'ובכל הגופים בהווה....', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 102, '6-07501', 'הטיות הווה של הפועל RESTARE', 'RESTO , RESTI, RESTA, RESTIAMO, …, RESTONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 103, '6-07502', 'ובשלילה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 104, '6-07600', 'אני לא נשאר', 'NON MI RESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 105, '6-07700', 'כמה', 'QUANTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 106, '6-07800', 'כמה זמן', 'QUANTO TEMPO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 107, '6-07801', 'ומשפט שלם...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 108, '6-07900', 'אני לא יודע כמה זמן אני נשאר', 'NON SO QUANTO TEMPO MI RESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 109, '6-07901', 'או בעתיד קרוב..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 110, '6-08000', 'אני לא יודע כמה זמן אני הולך להישאר', 'NON LO SO QUANTO TEMPO MI RESTO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 111, '6-08001', 'או..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 112, '6-08100', 'אני לא יודע כמה זמן אני יכול להישאר', 'NON LO SO QUANTO TEMPO VADO A RESTARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 113, '6-08101', 'בשילוב עם עתיד קרוב..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 114, '6-08300', 'אנחנו הולכים להישאר כאן כמה ימים', 'ANDIAMO A RESTARE QUI ALCUNI GIORNI', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 115, '6-08801', 'קודם נגדיר את הקהל..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 116, '6-08900', 'האנשים', 'PERSONE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 117, '6-09000', 'הרבה אנשים', 'MOLTI PERSONE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 118, '6-09001', 'ועכשיו נשתמש בנ"ל..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 119, '6-09100', 'יש כאן הרבה אנשים', 'CI SONO MOLTE PERSONE QUI', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 120, '6-09101', 'או, שימוש יומיומי...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 121, '6-09200', 'מה קורה, מה יש לך ?', 'CHE COSA SUCCEDE ?', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 122, '6-09203', 'או שימוש נוסף...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 123, '6-09300', 'אין בעיה', 'NESSUN PROBLEMA', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 124, '6-09400', 'אמרנו שלהיות חייב זה', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 125, '6-09500', 'צריך', 'DOVERE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 126, '6-09501', 'וההטיה של הפועל...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 127, '6-09502', 'וההטיה של הפועל DOVERE', 'DEVO , DEVI, DEVE, DOBBIAMO, DOVETE, DEVONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 128, '6-09600', 'להצטרך', 'BISOGNARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 129, '6-09700', 'אני צריך ללכת לים', 'BISOGNO DI ANDARE AL MARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 130, '6-09701', 'לעומת...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 131, '6-09702', 'אני מוכרח ללכת לים', 'DEVO ANDARE AL MARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 132, '6-09703', 'בעתיד קרוב...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 133, '6-09900', 'אני לא יודע כמה זמן (אנחנו) הולכים להישאר כאן', 'NON LO SO QUANTO TEMPO ANDIAMO A STARE QUI', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 134, '6-09901', 'לעומת עתיד רגיל..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 135, '6-09902', 'אני לא יודע כמה זמן (אנחנו) הולכים להשאיר כאן', 'NON LO SO QUANTO TEMPO RESTEREMO QUI', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 136, '6-09904', 'ומילה חדשה ושימושית..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 137, '6-10000', 'עדיין', 'ANCORA', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 138, '6-10001', 'ומשפט עם זה...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 139, '6-10300', 'אני עדיין לא יודע כמה זמן אני הולך להישאר', 'ANCORA NON SO QUANTO TEMPO VADO A STARE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 140, '6-10301', 'ועוד פועל שימושי מאד..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 141, '6-10400', 'לראות', 'VEDERE', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 142, '6-10401', 'וההטיות בהווה...', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 143, '6-10500', 'הטיות הווה של הפועל VEDERE', 'VEDO, VEDI, VEDE, VEDIAMO, VEDETE, VEDONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 144, '6-10501', 'דוגמאות..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 145, '6-10600', 'אנחנו רואים אותו', 'LO VEDIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 146, '6-10700', 'אתה לא רואה את זה', 'TU NON LO VEDI', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 147, '6-10800', 'הם רואים את זה', 'LO VEDONO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 148, '6-11100', 'אנחנו מתראים, (אנחנו רואים את עצמנו)', 'CI VEDIAMO', 'LANG'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 149, '6-11102', 'ובשלילה..', '', 'INFO'),
('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 150, '6-11200', 'אנחנו לא מתראים', 'NON CI VEDIAMO', 'LANG');

-- End of 20251028082026_update_lesson_6_content_part_3.sql

-- Start of 20251028082515_update_lesson_7_content_part_1.sql
/*
  # עדכון תוכן שיעור 7 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 7
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 7
DELETE FROM lines WHERE lesson_id = 'ffb3252b-a516-4828-8385-58cb2c23eb2c';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 1, '7-00100', 'נמשיך עם העתיד הפשוט', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 2, '7-00200', 'להתחיל', 'COMINCIARE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 3, '7-00201', 'בעתיד קרוב זה יהיה..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 4, '7-00300', 'אני הולך להתחיל', 'VADO A COMINCIARE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 5, '7-00301', 'ובעתיד רגיל', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 6, '7-00302', 'אתחיל', 'COMINCIERÒ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 7, '7-00400', 'אני הולך לקנות את זה', 'VADO A COMPRARLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 8, '7-00500', 'אנחנו הולכים לקנות את זה', 'ANDIAMO A COMPRARLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 9, '7-00800', 'אנחנו הולכים לקרא לך, לטלפן לך יותר מאוחר', 'ANDIAMO A CHIAMARTE PIU TARDI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 10, '7-00801', 'ובעתיד רגיל', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 11, '7-00802', 'נקרא לך יותר מאוחר', 'TI CHIAMERÒ PIU TARDI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 12, '7-00803', 'ואשאל אותך...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 13, '7-00900', 'באיזה שעה אתה הולך לקרא לי', 'A CHE ORA VAI A CHIAMARMI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 14, '7-01000', 'באיזה שעה הם הולכים לקרא לי', 'A CHE ORA VANNO A CHIAMARMI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 15, '7-01001', 'והתשובה לא אחרה לבוא..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 16, '7-01300', 'הם הולכים לקרוא לי מאוחר יותר', 'VANNO A CHIAMARMI PIU TARDI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 17, '7-01301', 'ובעתיד אמיתי..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 18, '7-01400', 'אנחנו נקרא לך', 'TI CHIAMEREMO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 19, '7-01401', 'ועכשיו חזרה קצרה...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 20, '7-01600', 'להישאר', 'RIMANERE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 21, '7-02300', 'כמה זמן אתה הולך להישאר כאן', 'QUANTO TEMPO VAI A RIMANERE QUI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 22, '7-02500', 'כמה זמן אנחנו הולכים להישאר ?', 'QUANTO TEMPO ANDIAMO A RIMANERE ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 23, '7-02501', 'ומשפט מתוחכם...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 24, '7-02600', 'עדיין אינני יודע כמה זמן הולכים להישאר', 'ANCORA NON LO SO QUANTO TEMPO ANDIAMO A RIMANERE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 25, '7-02601', 'ובעתיד אמיתי..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 26, '7-02602', 'עדיין אינני יודע כמה זמן נישאר', 'ANCORA NON LO SO QUANTO TEMPO RIMANEREMO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 27, '7-02902', 'החזרה לעתיד', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 28, '7-03000', 'אני אקנה את זה', 'LO COMPRARÒ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 29, '7-03100', 'אנחנו נקנה את זה', 'LO COMPRAREMO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 30, '7-03200', 'הוא יקנה את זה', 'LUI LO COMPRARÁ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 31, '7-03400', 'איפה תקנו את זה?', 'DOVE LO COMPRARÁN ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 32, '7-03500', 'איפה תקנה את זה', 'DOVE LO COMPRAI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 33, '7-03501', 'ובמשפט שלם..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 34, '7-03600', 'הם לא הולכים לקנות את זה כי זה יקר מאד', 'NON LO COMPRARÁN PERCHÉ SONO MOLTO COSTOSO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 35, '7-03601', 'ואיך נגיד בעתיד הקרוב ?', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 36, '7-03700', 'הם לא יקנו אותם כי הם יקרים מדי', 'NON VANNO A COMPRARLI PERCHÉ SONO TROPPO COSTOSO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 37, '7-03701', 'ושוב, חזרה לעתיד הפשוט...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 38, '7-03800', 'אהיה כאן', 'SARÒ QUI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 39, '7-03900', 'אנחנו נהיה כאן מחר', 'SAREMO QUI DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 40, '7-04100', 'זה יהיה מוכן עבורך מחר', 'SARÀ PRONTO PER TE DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 41, '7-04101', 'אתה תהיה כאן', 'SARAI QUI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 42, '7-04200', 'הם יהיו כאן בהקדם', 'SARANNO QUI PRESTO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 43, '7-04201', 'ושוב, בעתיד קרוב..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 44, '7-04300', 'הם הולכים להיות כאן בהקדם', 'VANNO A ESSERE QUI PRESTO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 45, '7-04501', 'ומה העתיד של ANDARE ? - הפתעה !! חוזרים לשם הפועל !!', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 46, '7-04600', 'אני אלך לראות אותו', 'ANDRÒ A VEDERLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 47, '7-04700', 'אנחנו נלך לראות אותו', 'ANDREMO A VEDERLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 48, '7-04800', 'ובעתיד הקרוב..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 49, '7-04801', 'אנחנו הולכים ללכת לראות אותו', 'ANDIAMO A ANDARE A VEDERLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 50, '7-04900', 'הוא ילך לראות אותו', 'ANDRÁ A VEDERLO', 'LANG');

-- End of 20251028082515_update_lesson_7_content_part_1.sql

-- Start of 20251028082623_update_lesson_7_content_part_2.sql
/*
  # עדכון תוכן שיעור 7 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 51, '7-05000', 'הם יילכו לראות אותו בהקדם', 'ANDRANNO A VEDERLO PRESTO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 52, '7-05100', 'ואתה, רוברטו, תלך לראות אותו מחר', 'E TU ROBERTA ANDRAI A VEDERLO DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 53, '7-05101', 'הטיות העתיד של AVERE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 54, '7-05300', 'הטיות עתיד הפועל AVERE = TO HAVE', 'AVRÒ, AVRAI, AVRÁ, AVREMO, …, AVRANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 55, '7-05301', 'ההטיות של PARTIRE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 56, '7-05900', 'הטיות עתיד הפועל PARTIRE = לצאת', 'PARTIRÒ, PARTIRAI, PARTIRÁ, PARTIREMO, … , PARTIRANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 57, '7-05901', 'ההטיות העתיד של METTERE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 58, '7-06500', 'הטיות עתיד הפועל METTERE = לשים', 'METTERÒ, METTERAI, METTERÁ, METTEREMO, … , METTERANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 59, '7-06501', 'ההטיות של ARRIVARE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 60, '7-07100', 'הטיות עתיד הפועל ARRIVARE = לבוא', 'ARRIVERÒ, ARRIVERAI, ARRIVERÁ, ARRIVEREMO, …, ARRIVERANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 61, '7-07101', 'שני הפעלים החשובים FARE ו DIRE שונים – מקצרים אותם', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 62, '7-07102', 'ההטיות העתיד של FARE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 63, '7-07600', 'הטיות עתיד הפועל FARE', 'FARÒ, FARAI, FARÁ, FAREMO, …, FARANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 64, '7-07601', 'ההטיות העתיד של DIRE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 65, '7-08200', 'הטיות עתיד הפועל DIRE', 'DIRÒ, DIRAI, DIRÁ, DIREMO, … , DIRANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 66, '7-08201', 'כמה שימושים..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 67, '7-08700', 'אגיד לך את זה יותר מאוחר', 'TE LO DIRÒ PIU TARDI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 68, '7-08900', 'אנחנו נגיד לך (מנומס)', 'TE DIREMO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 69, '7-09000', 'הוא יגיד לך', 'TE DIRÁ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 70, '7-09100', 'הוא יגיד לי', 'ME DIRÁ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 71, '7-09200', 'מתי תגיד לי את זה ?', 'QUANDO ME LO DIRAI ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 72, '7-09401', 'ועכשיו, לטעם אישי..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 73, '7-09402', 'מוצא חן בעיני', 'MI PIACE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 74, '7-09403', 'ומשפטים עם זה...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 75, '7-09500', 'אני אוהב מאד לראות אותו', 'MI PIACE MOLTO VEDERLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 76, '7-09501', 'או בשילוב עם "התפעל"..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 77, '7-09600', 'אני לא אוהב להישאר כאן', 'NON MI PIACE STARE QUI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 78, '7-09601', 'זה "תופס" גם בגופים אחרים..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 79, '7-09700', 'מוצא חן בעיניך, או אתה אוהב', 'TI PIACE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 80, '7-09701', 'ובשאלה..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 81, '7-09800', 'זה מוצא חן בעיניך ?', 'TI PIACE ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 82, '7-09802', 'ומכאן קפיצה למשלוחים..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 83, '7-09900', 'לשלוח', 'MANDARE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 84, '7-10000', 'אתה שולח את זה', 'LO MANDA', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 85, '7-10100', 'אתה שולח את זה אלי', 'ME LO MANDI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 86, '7-10101', 'נרכיב משפט ארוך...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 87, '7-10200', 'הוא לא שולח את זה אלי היום', 'NON ME LO MANDA OGGI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 88, '7-10300', 'אבל הוא ישלח את זה אלי מחר', 'MA ME LO MANDARÀ DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 89, '7-10301', 'ויחד, למשפט הארוך..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 90, '7-10302', 'הוא לא שולח את זה אלי היום אבל הוא ישלח את זה אלי מחר', 'NON ME LO MANDA OGGI MA ME LO MANDARÀ DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 91, '7-10303', 'את המשפט השני אפשר להגיד גם בעתיד קרוב..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 92, '7-10400', 'אבל הוא שולח את זה אלי מחר', 'MA VA A MANDARMELO DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 93, '7-10401', 'או בהווה, כי יש רמז לעתיד..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 94, '7-10500', 'אבל אתה שולח את זה אלי מחר', 'MA ME LO MANDA DOMANI', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 95, '7-10700', 'אני שולח לך משהו', 'TE MANDO QUALCOSA', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 96, '7-10800', 'אני שולח אותם אליך', 'TE LI MANDO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 97, '7-11401', 'במשפט שאלה..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 98, '7-11500', 'תוכל לשלוח את זה אלי ?', 'PUOI MANDARMELO ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 99, '7-11501', 'או..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 100, '7-11600', 'תוכל לשלוח את זה אליו ?', 'PUOI MANDARSELO A LUI ?', 'LANG');

-- End of 20251028082623_update_lesson_7_content_part_2.sql

-- Start of 20251028082731_update_lesson_7_content_part_3.sql
/*
  # עדכון תוכן שיעור 7 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 101, '7-11601', 'חזרה קצרה....', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 102, '7-11700', 'אוהב לראות את זה', 'MI PIACE VEDERLO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 103, '7-11802', 'ושוב ניזכר משפט עם העתיד של הפועל ESSERE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 104, '7-11900', 'זה לא יהיה הכרחי', 'NON SARÀ NECESSARIO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 105, '7-11901', 'ולא פחות חשוב - איך נפליג אל העבר?', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 106, '7-11902', 'מה שנלמד זו הטיית העבר הקרוב – זה קל ושימושי', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 107, '7-11903', 'הטיות הווה לפועל AVERE', 'HO, HAI, HA, ABBIAMO, … ,HANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 108, '7-11904', 'אבל, להבדיל מההטייה בעתיד, כאן צריך לזכור את ההטייה במלואה..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 109, '7-11905', 'תצורת הפועל העיקרי נקרא לה ATO/UTO כי אלה הסיומות', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 110, '7-11907', 'כמה דוגמאות ...', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 111, '7-12000', 'קניתי', 'HO COMPRATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 112, '7-12001', 'דיברתי', 'HO PARLATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 113, '7-12002', 'הבאת', 'HO PORTATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 114, '7-12003', 'לקחו', 'HANNO PRENDUTO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 115, '7-12004', 'אכלנו', 'ABBIAMO MANGIATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 116, '7-12005', 'דוגמאות נוספות..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 117, '7-12200', 'קניתי משהו', 'HO COMPRATO QUALCOSA', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 118, '7-12300', 'אנחנו קנינו משהו', 'ABBIAMO COMPRATO QUALCOSA', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 119, '7-12400', 'קנינו את זה', 'LO ABBIAMO COMPRATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 120, '7-12500', 'הוא קנה את זה', 'L''A COMPRATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 121, '7-12600', 'הוא לא קנה את זה', 'NON L''A COMPRATO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 122, '7-12700', 'איפה קנית את זה ?', 'DOVE LO HAI COMPRATO ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 123, '7-12800', 'הוא מכר את זה', 'L''HO VENDUTO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 124, '7-13401', 'ועוד פעלים רגילים..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 125, '7-13500', 'לחכות, לקוות', 'SPERARE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 126, '7-13600', 'אני מחכה', 'SPERO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 127, '7-13700', 'הוא מחכה', 'SPERA', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 128, '7-13800', 'ליידע', 'INFORMARE', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 129, '7-13801', 'ומשפט בנושא..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 130, '7-13900', 'אני רוצה לגלות איפה זה', 'VOGLIO INFORMARE DOVE È', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 131, '7-14201', 'ומשפט תלונה נפוץ..', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 132, '7-14300', 'למה אתה לא מחכה לי ?', 'PERCHÉ NON ME SPERA ?', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 133, '7-14400', 'עתיד של ANDARE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 134, '7-14401', 'הטיות עתיד ANDARE', 'ANDRÒ, ANDRAI, ANDRÀ, ANDREMO, ANDRANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 135, '7-14500', 'עתיד של ESSERE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 136, '7-14501', 'הטיות עתיד ESSERE', 'SARÒ, SARAI, SARÀ, SAREMO, SARANNO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 137, '7-14600', 'עבר קרוב - מבנה', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 138, '7-14601', 'פעלי ARE מקבלים ATO ופעלי לא-ARE מקבלים UTO', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 139, '7-14700', 'דוגמאות לעבר קרוב ARE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 140, '7-14701', 'PARLARE -> PARLATO, MANGIARE -> MANGIATO, COMPRARE -> COMPRATO', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 141, '7-14800', 'דוגמאות לעבר קרוב לא-ARE', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 142, '7-14801', 'VENDERE -> VENDUTO, CAPIRE -> CAPITO, PARTIRE -> PARTITO', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 143, '7-14900', 'משפטים מורכבים בעבר', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 144, '7-14901', 'אתמול דיברתי עם חבר שלי', 'IERI HO PARLATO CON IL MIO AMICO', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 145, '7-15000', 'שילוב עתיד ועבר', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 146, '7-15001', 'אתמול קניתי ומחר אמכור', 'IERI HO COMPRATO E DOMANI VENDERÒ', 'LANG'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 147, '7-15100', 'סיכום זמנים', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 148, '7-15101', 'הווה: PARLO, עבר: HO PARLATO, עתיד: PARLERÒ', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 149, '7-15200', 'תרגול מסכם', '', 'INFO'),
('ffb3252b-a516-4828-8385-58cb2c23eb2c', 150, '7-15201', 'אתמול דיברתי, היום אני מדבר, מחר אדבר', 'IERI HO PARLATO, OGGI PARLO, DOMANI PARLERÒ', 'LANG');

-- End of 20251028082731_update_lesson_7_content_part_3.sql

-- Start of 20251028083810_update_lesson_8_content_part_1.sql
/*
  # עדכון תוכן שיעור 8 - חלק 1 (שורות 1-50)

  1. שינויים
    - מחיקת כל השורות הקיימות של שיעור 8
    - הוספת שורות 1-50 מהתוכן החדש
*/

-- מחיקת שורות קיימות של שיעור 8
DELETE FROM lines WHERE lesson_id = '97a3284f-1ed2-4263-8a15-22cb4ea4b696';

-- הוספת שורות חדשות
INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 1, '8-00100', 'השיעור הזה כולל גם משפטי יום-יום ומעט סלנג', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 2, '8-00200', 'באנגלית וגם בעברית אנחנו אומרים - מחכה ל...מישהו, באיטלקית אנחנו פשוט נחכה את...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 3, '8-00300', 'הוא מחכה לך', 'TI ASPETTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 4, '8-00400', 'הם מחכים לי', 'MI ASPETTANO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 5, '8-00500', 'למה הם מחכים?', 'PERCHÉ ASPETTANO?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 6, '8-00600', 'חברה, למה את מחכה לי ?', 'PERCHÉ MI ASPETTI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 7, '8-00700', 'אנחנו מחכים', 'ASPETTIAMO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 8, '8-00800', 'למה אתה לא מחכה לי (אדוני)', 'PERCHÉ NON MI ASPETTI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 9, '8-01000', 'למה הם לא מחכים לי', 'PERCHÉ NON MI ASPETTANO ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 10, '8-01101', 'ונמשיך בדוגמאות..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 11, '8-01200', 'אנחנו מחכים לך', 'TI ASPETTIAMO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 12, '8-01300', 'האם נחכה לך ?', 'TI ASPETTIAMO ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 13, '8-01301', 'ולנושא שמעניין תיירים – שכר-מכר...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 14, '8-01500', 'אנחנו קונים את זה', 'LO COMPRIAMO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 15, '8-01600', 'אנחנו לא קונים את זה', 'NON LO COMPRIAMO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 16, '8-02100', 'אני מחכה לו', 'LO ASPETTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 17, '8-02101', 'ונחזור אל העבר הקרוב..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 18, '8-02300', 'חיכיתי', 'HO SPERATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 19, '8-02400', 'עזבתי', 'HO PARTITO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 20, '8-02401', 'ניזכר שוב בהטיות של הפועל AVERE כי הוא עומד ביסוד העבר', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 21, '8-02402', 'הטיות הפועל AVERE', 'HO, HAI, HA, ABBIAMO, … , HANNO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 22, '8-02403', 'ודוגמאות..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 23, '8-02800', 'לא הבנתי את מה שאתה אומר לי', 'NON HO CAPITO COSA MI DICE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 24, '8-03000', 'קנינו', 'ABBIAMO COMPRATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 25, '8-03100', 'עזבתי', 'HO PARTITO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 26, '8-03200', 'אתה, חבר, מכרת', 'HAI VENDUTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 27, '8-03300', 'הכנתם את זה', 'LO HANNO PREPARATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 28, '8-03800', 'הכנתי את זה', 'L''HO PREPARATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 29, '8-03900', 'ארוחת הערב הוכנה', 'LA CENA HA PREPARATA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 30, '8-04000', 'קיבלתי את התנאי', 'HO ACCEPTATO LA CONDIZIONE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 31, '8-04100', 'יוצאים מהכלל בכתיב הם ... FARE=FATTO ו DIRE=DITTO', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 32, '8-04301', 'יוצא מן הכלל נוסף הוא התצורה של הפועל VEDERE = VISTO', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 33, '8-04302', 'ובמשפט..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 34, '8-04400', 'ראיתי אותו', 'L`HO VISTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 35, '8-04401', 'במקום LO HO VISTO – בד"כ שיש שתי הברות רצופות בא במקומם פסיק', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 36, '8-04500', 'לא ראיתי אותו עדיין', 'ANCORA NON L`HO VISTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 37, '8-04501', 'יוצא מן הכלל נוסף יהיה METTERE – הופך בעבר ל MESSO', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 38, '8-04600', 'איפה שמת את זה ?', 'DOVE LO HAI MESSO ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 39, '8-04700', 'שמנו אותו כאן ?', 'LO ABBIAMO MESSO QUI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 40, '8-04701', 'ועכשיו לנושא שמעסיק את הגיל השלישי, במיוחד...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 41, '8-04800', 'לשכוח', 'DIMENTICARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 42, '8-04900', 'לא אשכח את זה – עתיד פשוט', 'NON LO DIMENTICHERÒ', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 43, '8-05000', 'בטוח', 'SICURO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 44, '8-05001', 'והנקבי..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 45, '8-05002', 'בטוחה', 'SICURA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 46, '8-05100', 'אני בטוח שלא נשכח את זה', 'SONO SICURO CHE NON LO DIMENTICHEREMO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 47, '8-05101', 'ובעבר הקרוב...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 48, '8-05300', 'לא שכחתי את זה', 'NON L`HO DIMENTICATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 49, '8-05500', 'מילה חדשה', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 50, '8-05501', 'הודעה', 'MESSAGGIO', 'LANG');

-- End of 20251028083810_update_lesson_8_content_part_1.sql

-- Start of 20251028083933_update_lesson_8_content_part_2.sql
/*
  # עדכון תוכן שיעור 8 - חלק 2 (שורות 51-100)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 51, '8-05600', 'השארתי הודעה עבורך', 'HO LASCIATO UN MESSAGGIO PER TE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 52, '8-05700', 'לבלות זמן, לבזבז זמן, להעביר זמן זה...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 53, '8-05701', 'לבלות זמן, לבזבז זמן, להעביר זמן', 'PASSARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 54, '8-05702', 'ובעבר הקרוב..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 55, '8-05800', 'בילינו הרבה זמן', 'ABBIAMO PASSATO MOLTO TEMPO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 56, '8-05900', 'לא בזבזנו הרבה זמן', 'NON ABBIAMO PASSATO MOLTO TEMPO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 57, '8-05901', 'כמה זמן עבר, כמה זמן בוזבז ?', 'QUANTO TEMPO HA PASSATO ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 58, '8-05902', 'ובלי שום קשר...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 59, '8-06100', 'זה רעיון טוב', 'QUESTO È UNA BUONA IDEA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 60, '8-06101', 'זה רעיון לא רע', 'NON È UNA CATTIVA IDEA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 61, '8-06102', 'ומילה שנתקלנו בה כבר..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 62, '8-06300', 'להעדיף', 'PREFERIRE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 63, '8-06301', 'הטיות הפועל בהווה...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 64, '8-06302', 'הטיות הפועל PREFERIRE בהווה...', 'PREFERISCO ,PREFERISCI, PREFERISCE, PREFERIAMO,…,PREFERISCONO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 65, '8-06401', 'ודוגמה..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 66, '8-06500', 'אני מעדיף להישאר כאן', 'PREFERISCO STARE QUI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 67, '8-06501', 'וקצת סלנג ומילים שימושיות....', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 68, '8-06600', 'בסדר , O.K', 'VA BENE !!', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 69, '8-06700', 'הבט !', 'GUARDA !', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 70, '8-06800', 'שמע ! היי !', 'ASCOLTA !', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 71, '8-06900', 'החשבון, בבקשה', 'IL CONTO PER FAVORE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 72, '8-07000', 'לשכור', 'NOLEGGIARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 73, '8-07100', 'סוכנות להשכרת מכוניות', 'AGENZIA DI NOLEGGIO AUTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 74, '8-07200', 'מכנסי ג''ינס', 'JEANS', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 75, '8-07300', 'להתראות אפשר להגיד בהרבה דרכים, תלוי בזמן הפרידה...', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 76, '8-07301', 'להתראות', 'CIAO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 77, '8-07302', 'להתראות', 'ADDIO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 78, '8-07303', 'להתראות', 'A RIVEDERCI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 79, '8-07304', 'נתראה מחר', 'CI VEDIAMO DOMANI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 80, '8-07305', 'להתראות בשבוע הבא', 'CI VEDIAMO LA PROSSIMA SETTIMANA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 81, '8-07306', 'להתראות בשנה הבאה', 'CI VEDIAMO LA PROSSIMO ANNO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 82, '8-07400', 'מיץ', 'SUCCO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 83, '8-07450', 'משקפיים', 'BICCHIERI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 84, '8-07501', 'או..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 85, '8-07502', 'משקפיים (לפני העיינים)', 'OCCHIALI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 86, '8-07503', 'משקפי שמש', 'OCCHIALI DA SOLE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 87, '8-07504', 'מאד חשוב – בעיקר לא לאבד !!', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 88, '8-07600', 'כרטיס אשראי', 'CARTA DI CREDITO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 89, '8-07700', 'כתובת מייל', 'INDIRIZZO E-MAIL', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 90, '8-07701', 'ולשם שינוי – ציווי !', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 91, '8-07800', 'אמור לי', 'DIMMI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 92, '8-07900', 'שמע אותי', 'ASCOLTAMI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 93, '8-08000', 'להיות חייב ל....', 'BISOGNARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 94, '8-08101', 'ובמשפט..', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 95, '8-08200', 'אתה חייב לקנות את זה', 'BISOGNA COMPRARE QUESTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 96, '8-08500', 'אני רוצה להישאר כאן', 'VOGLIO STARE QUI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 97, '8-09000', 'לשאול', 'DOMANDARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 98, '8-09100', 'לשם, על מנת', 'PER', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 99, '8-09200', 'סיכום שיעור - משפטים יומיומיים', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 100, '8-10000', 'בדיוק', 'APPENA', 'LANG');

-- End of 20251028083933_update_lesson_8_content_part_2.sql

-- Start of 20251028084050_update_lesson_8_content_part_3.sql
/*
  # עדכון תוכן שיעור 8 - חלק 3 (שורות 101-150)
*/

INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type) VALUES
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 101, '8-10100', 'בדיוק ראיתי אותו', 'L''HO APPENA VISTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 102, '8-10200', 'הוא בדיוק עזב', 'È APPENA PARTITO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 103, '8-10300', 'בדיוק עזבנו', 'SIAMO APPENA PARTITI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 104, '8-10400', 'משפטי יום-יום נפוצים', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 105, '8-11000', 'היום לא אלך לעבודה כי אני מרגיש לא טוב', 'OGGI NON ANDRÒ A LAVORARE PERCHÉ NON MI SENTO BENE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 106, '8-11100', 'אשתי לקחה את הילדים לקולנוע', 'MIA MOGLIE HA PORTATO I BAMBINI AL CINEMA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 107, '8-11200', 'החברים שלי הולכים לבקר אותנו בסוף השבוע', 'I MIEI AMICI VERRANNO A VISITARCI NEL FINE SETTIMANA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 108, '8-11300', 'כמה זמן אני צריך עוד לחכות ?', 'QUANTO TEMPO DEVO ANCORA ASPETTARE ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 109, '8-11400', 'אתם באים לראות אותנו מחר ?', 'VENITE A VEDERCI DOMANI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 110, '8-11500', 'אני לא יוצא להליכה כי יורד גשם עכשיו', 'NON ESCO A CAMMINARE PERCHÉ PIOVE ADESSO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 111, '8-11600', 'אתמול ירד גשם', 'IERI È PIOVUTO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 112, '8-11700', 'לשכן שלי יש אוטו חדש', 'IL MIO VICINO HA UNA MACCHINA NUOVA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 113, '8-11800', 'אני ואשתי מנקים היום את הבית', 'MIA MOGLIE ED IO PULIAMO LA CASA OGGI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 114, '8-11900', 'לא הלכנו הרבה זמן לסרט', 'È PASSATO MOLTO TEMPO DA QUANDO SIAMO ANDATI AL CINEMA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 115, '8-12000', 'איך הילדים היום ? כולם בריאים ?', 'COME STANNO I BAMBINI OGGI ? SONO TUTTI SANI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 116, '8-12100', 'היום נלך לרקוד עם חברים במועדון הריקודים', 'OGGI ANDREMO A BALLARE CON GLI AMICI NEL CLUB DI BALLO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 117, '8-12200', 'למרות המגפה נלך כולנו לאכול במסעדה', 'NONOSTANTE LA PANDEMIA, ANDREMO TUTTI A MANGIARE AL RISTORANTE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 118, '8-12300', 'למה לא קנית לחם וזיתים ?', 'PERCHÉ NON HAI COMPRATO PANE E OLIVE ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 119, '8-12400', 'שכחת לקנות חלב ? אז איך נשתה קפה ?', 'HAI DIMENTICATO DI COMPRARE LATTE ? ALLORA COME PRENDEREMO IL CAFFÈ ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 120, '8-12500', 'איפה שמת את המשקפיים שלי ?', 'DOVE HAI MESSO I MIEI OCCHIALI ?', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 121, '8-12600', 'מאד נהניתי בחברתכם', 'HO GODUTO MOLTO DELLA VOSTRA COMPAGNIA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 122, '8-12700', 'מילים שימושיות נוספות', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 123, '8-12800', 'לסופר', 'AL SUPERMERCATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 124, '8-12900', 'מצרכים', 'INGREDIENTI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 125, '8-13000', 'ארוחת ערב', 'CENA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 126, '8-13100', 'עבודה', 'LAVORO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 127, '8-13200', 'חולה', 'MALATO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 128, '8-13300', 'ילדים', 'BAMBINI', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 129, '8-13400', 'קולנוע', 'CINEMA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 130, '8-13500', 'סוף שבוע', 'FINE SETTIMANA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 131, '8-13600', 'לבקר', 'VISITARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 132, '8-13700', 'בית ספר', 'SCUOLA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 133, '8-13800', 'גשם', 'PIOGGIA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 134, '8-13900', 'שכן', 'VICINO', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 135, '8-14000', 'מכונית', 'MACCHINA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 136, '8-14100', 'לנקות', 'PULIRE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 137, '8-14200', 'בית', 'CASA', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 138, '8-14300', 'לרקוד', 'BALLARE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 139, '8-14400', 'מסעדה', 'RISTORANTE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 140, '8-14500', 'לחם', 'PANE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 141, '8-14600', 'זיתים', 'OLIVE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 142, '8-14700', 'חלב', 'LATTE', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 143, '8-14800', 'קפה', 'CAFFÈ', 'LANG'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 144, '8-14900', 'סיכום השיעור', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 145, '8-15000', 'למדנו משפטי יום-יום שימושיים', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 146, '8-15100', 'למדנו סלנג ומילים נפוצות', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 147, '8-15200', 'תרגלנו עבר קרוב ויוצאים מהכלל', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 148, '8-15300', 'למדנו ציווי ומשפטים מעשיים', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 149, '8-15400', 'סיימנו את 8 השיעורים!', '', 'INFO'),
('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 150, '8-15500', 'בהצלחה בלימוד האיטלקית!', 'BUONA FORTUNA CON L''ITALIANO!', 'LANG');

-- End of 20251028084050_update_lesson_8_content_part_3.sql

-- Start of 20251109093725_add_share_with_admin_to_notes.sql
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
-- End of 20251109093725_add_share_with_admin_to_notes.sql

-- Start of 20251109110410_add_city_to_users.sql
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

-- End of 20251109110410_add_city_to_users.sql

-- Start of 20251121081124_add_english_text_to_lines.sql
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

-- End of 20251121081124_add_english_text_to_lines.sql

-- Start of 20251126113638_add_unique_constraint_to_line_code.sql
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
-- End of 20251126113638_add_unique_constraint_to_line_code.sql

-- Start of 20251126113654_add_trigger_to_update_line_code.sql
/*
  # Add trigger to automatically update line code

  1. Changes
    - Create a trigger function that updates the `code` field whenever `order_num` changes
    - Create a trigger that calls this function on INSERT or UPDATE
  
  2. Purpose
    - Ensures that the `code` field is always in sync with the `order_num`
    - Prevents duplicate codes from being created when order numbers change
  
  3. Important Notes
    - This trigger runs before INSERT or UPDATE operations
    - The code format is: {lesson_index}-{order_num_padded_5_digits}
*/

-- Create function to update line code
CREATE OR REPLACE FUNCTION update_line_code()
RETURNS TRIGGER AS $$
BEGIN
  -- Get the lesson index and update the code
  NEW.code := (
    SELECT index || '-' || LPAD(NEW.order_num::text, 5, '0')
    FROM lessons
    WHERE id = NEW.lesson_id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update code
DROP TRIGGER IF EXISTS trigger_update_line_code ON lines;
CREATE TRIGGER trigger_update_line_code
  BEFORE INSERT OR UPDATE OF order_num, lesson_id
  ON lines
  FOR EACH ROW
  EXECUTE FUNCTION update_line_code();
-- End of 20251126113654_add_trigger_to_update_line_code.sql

-- Start of 20251215100623752_update_lesson_7_content.sql
/*
  # Update Lesson 7 Content
*/

DO $$
DECLARE
  l_id uuid;
BEGIN
  -- Find or create lesson
  SELECT id INTO l_id FROM lessons WHERE index = 7;
  
  IF l_id IS NULL THEN
    INSERT INTO lessons (index, title, is_published) 
    VALUES (7, 'Lesson 7', true) 
    RETURNING id INTO l_id;
  END IF;

  -- Delete existing lines
  DELETE FROM lines WHERE lesson_id = l_id;

  -- Insert new lines
  INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type)
  SELECT l_id, v.order_num, v.code, v.text_he, v.text_it, v.type
  FROM (VALUES
    (1, '7-00100', 'השיעור הזה יוקדש כולו לשאלת שאלות והתעסקות במילות שאלה...', '', 'INFO'),
    (2, '7-00200', 'מה (איזה)', 'CHE', 'LANG'),
    (3, '7-00300', 'מה (איזה)', 'COSA', 'LANG'),
    (4, '7-00400', 'מאיזה', 'DI CHE', 'LANG'),
    (5, '7-00500', 'לאיזה (לכיוון)', 'A CHE', 'LANG'),
    (6, '7-00600', 'עם איזה', 'CON CHE', 'LANG'),
    (7, '7-00700', 'בשביל איזה', 'PER CHE', 'LANG'),
    (8, '7-00800', 'מילת שאלה נוספת...', '', 'INFO'),
    (9, '7-00900', 'איזה (מבין כמה)', 'QUALE', 'LANG'),
    (10, '7-01000', 'ובריבוי...', '', 'INFO'),
    (11, '7-01100', 'אילו (מבין כמה)', 'QUALI', 'LANG'),
    (12, '7-01200', 'עם איזה', 'CON QUALE', 'LANG'),
    (13, '7-01300', 'לאיזה', 'A QUALE', 'LANG'),
    (14, '7-01400', 'בשביל איזה', 'PER QUALE', 'LANG'),
    (15, '7-01500', 'מאיזה', 'DI QUALE', 'LANG'),
    (16, '7-01600', 'כמה', 'QUANTO', 'LANG'),
    (17, '7-01700', 'כמה (נקבה)', 'QUANTA', 'LANG'),
    (18, '7-01800', 'כמה (רבים)', 'QUANTI', 'LANG'),
    (19, '7-01900', 'כמה (רבות)', 'QUANTE', 'LANG'),
    (20, '7-02000', 'מילת שאלה חשובה...', '', 'INFO'),
    (21, '7-02100', 'מתי', 'QUANDO', 'LANG'),
    (22, '7-02200', 'ממתי', 'DA QUANDO', 'LANG'),
    (23, '7-02300', 'עד מתי', 'FINO A QUANDO', 'LANG'),
    (24, '7-02400', 'עוד מילת שאלה...', '', 'INFO'),
    (25, '7-02500', 'איפה', 'DOVE', 'LANG'),
    (26, '7-02600', 'מאיפה', 'DI DOVE', 'LANG'),
    (27, '7-02700', 'מאיפה (כיוון)', 'DA DOVE', 'LANG'),
    (28, '7-02800', 'שימו לב להבדל : DI DOVE זה מנין אתה (מוצא),DA DOVE זה מאיפה אתה בא (פיזית)', '', 'INFO'),
    (29, '7-02900', 'מילת שאלה נוספת...', '', 'INFO'),
    (30, '7-03000', 'מי', 'CHI', 'LANG'),
    (31, '7-03100', 'עם מי', 'CON CHI', 'LANG'),
    (32, '7-03200', 'בשביל מי', 'PER CHI', 'LANG'),
    (33, '7-03300', 'של מי', 'DI CHI', 'LANG'),
    (34, '7-03400', 'למי', 'A CHI', 'LANG'),
    (35, '7-03500', 'מילת שאלה אחרונה להיום...', '', 'INFO'),
    (36, '7-03600', 'איך', 'COME', 'LANG'),
    (37, '7-03700', 'ועכשיו,נתרגל משפטים עם מילות השאלה...', '', 'INFO'),
    (38, '7-03800', 'מה אתה רוצה ?', 'CHE COSA VUOI ?', 'LANG'),
    (39, '7-03900', 'איזה ספר אתה רוצה ?', 'QUALE LIBRO VUOI ?', 'LANG'),
    (40, '7-04000', 'כמה זה עולה ?', 'QUANTO COSTA ?', 'LANG'),
    (41, '7-04100', 'מתי אתה מגיע ?', 'QUANDO ARRIVI ?', 'LANG'),
    (42, '7-04200', 'איפה אתה גר ?', 'DOVE ABITI ?', 'LANG'),
    (43, '7-04300', 'מי זה ?', 'CHI È ?', 'LANG'),
    (44, '7-04400', 'איך קוראים לך ?', 'COME TI CHIAMI ?', 'LANG'),
    (45, '7-04500', 'נחזור לפועל ללכת (ANDARE) ולשימוש שלו עם מילות שאלה...', '', 'INFO'),
    (46, '7-04600', 'לאן אתה הולך ?', 'DOVE VAI ?', 'LANG'),
    (47, '7-04700', 'עם מי אתה הולך ?', 'CON CHI VAI ?', 'LANG'),
    (48, '7-04800', 'מתי אתה הולך ?', 'QUANDO VAI ?', 'LANG'),
    (49, '7-04900', 'איך אתה הולך ? (ברגל,באוטו...)', 'COME VAI ?', 'LANG'),
    (50, '7-05000', 'וכעת,שאלות עם הפועל לעשות (FARE)...', '', 'INFO'),
    (51, '7-05100', 'מה אתה עושה ?', 'CHE COSA FAI ?', 'LANG'),
    (52, '7-05200', 'איך אתה עושה את זה ?', 'COME LO FAI ?', 'LANG'),
    (53, '7-05300', 'מתי אתה עושה את זה ?', 'QUANDO LO FAI ?', 'LANG'),
    (54, '7-05400', 'עם מי אתה עושה את זה ?', 'CON CHI LO FAI ?', 'LANG'),
    (55, '7-05500', 'למה אתה עושה את זה ?', 'PERCHÉ LO FAI ?', 'LANG')
  ) AS v(order_num, code, text_he, text_it, type);

END $$;

-- End of 20251215100623752_update_lesson_7_content.sql

-- Start of 20251215100623860_update_lesson_8_content.sql
/*
  # Update Lesson 8 Content
*/

DO $$
DECLARE
  l_id uuid;
BEGIN
  -- Find or create lesson
  SELECT id INTO l_id FROM lessons WHERE index = 8;
  
  IF l_id IS NULL THEN
    INSERT INTO lessons (index, title, is_published) 
    VALUES (8, 'Lesson 8', true) 
    RETURNING id INTO l_id;
  END IF;

  -- Delete existing lines
  DELETE FROM lines WHERE lesson_id = l_id;

  -- Insert new lines
  INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type)
  SELECT l_id, v.order_num, v.code, v.text_he, v.text_it, v.type
  FROM (VALUES
    (1, '8-00100', 'בשיעור הזה נתעסק בפעלים,בעיקר בפעלי תנועה ובפעלים רפלקסיביים...', '', 'INFO'),
    (2, '8-00200', 'ללכת (מקום למקום)', 'ANDARE', 'LANG'),
    (3, '8-00201', 'כבר למדנו את הפועל הזה,נחזור על ההטיות :', '', 'INFO'),
    (4, '8-00300', 'הטיות הפועל ANDARE', 'VADO, VAI, VA, ANDIAMO, ANDATE, VANNO', 'LANG'),
    (5, '8-00400', 'פועל דומה במשמעות אבל שונה בשימוש...', '', 'INFO'),
    (6, '8-00401', 'ללכת (באופן כללי,לטייל)', 'CAMMINARE', 'LANG'),
    (7, '8-00402', 'הטיות הפועל CAMMINARE (פועל רגיל - ARE) :', '', 'INFO'),
    (8, '8-00500', 'הטיות הפועל CAMMINARE', 'CAMMINO, CAMMINI, CAMMINA, CAMMINIAMO, CAMMINATE, CAMMINANO', 'LANG'),
    (9, '8-00600', 'אני הולך ברגל', 'VADO A PIEDI', 'LANG'),
    (10, '8-00601', 'שימו לב : A PIEDI ולא IN PIEDI או CON PIEDI', '', 'INFO'),
    (11, '8-00700', 'אני הולך לטייל', 'VADO A CAMMINARE', 'LANG'),
    (12, '8-00701', 'פועל נוסף...', '', 'INFO'),
    (13, '8-00800', 'לרוץ', 'CORRERE', 'LANG'),
    (14, '8-00801', 'הטיות הפועל CORRERE (פועל רגיל - ERE) :', '', 'INFO'),
    (15, '8-00900', 'הטיות הפועל CORRERE', 'CORRO, CORRI, CORRE, CORRIAMO, CORRETE, CORRONO', 'LANG'),
    (16, '8-01000', 'למה אתה רץ ?', 'PERCHÉ CORRI ?', 'LANG'),
    (17, '8-01001', 'תשובה...', '', 'INFO'),
    (18, '8-01100', 'אני רץ כי אני ממהר', 'CORRO PERCHÉ HO FRETTA', 'LANG'),
    (19, '8-01101', 'ממהר = AVERE FRETTA (יש לי חיפזון)', '', 'INFO'),
    (20, '8-01200', 'פועל נוסף...', '', 'INFO'),
    (21, '8-01201', 'לנהוג', 'GUIDARE', 'LANG'),
    (22, '8-01202', 'הטיות הפועל GUIDARE (פועל רגיל - ARE) :', '', 'INFO'),
    (23, '8-01300', 'הטיות הפועל GUIDARE', 'GUIDO, GUIDI, GUIDA, GUIDIAMO, GUIDATE, GUIDANO', 'LANG'),
    (24, '8-01400', 'אתה נוהג טוב', 'GUIDI BENE', 'LANG'),
    (25, '8-01401', 'עכשיו נתעסק בפעלים רפלקסיביים (מתייחסים לעצמי)...', '', 'INFO'),
    (26, '8-01500', 'לקום (את עצמי)', 'ALZARSI', 'LANG'),
    (27, '8-01501', 'הטיות הפועל ALZARSI :', '', 'INFO'),
    (28, '8-01600', 'הטיות הפועל ALZARSI', 'MI ALZO, TI ALZI, SI ALZA, CI ALZIAMO, VI ALZATE, SI ALZANO', 'LANG'),
    (29, '8-01700', 'מתי אתה קם בבוקר ?', 'A CHE ORA TI ALZI LA MATTINA ?', 'LANG'),
    (30, '8-01701', 'תשובה...', '', 'INFO'),
    (31, '8-01800', 'אני קם ב-7', 'MI ALZO ALLE SETTE', 'LANG'),
    (32, '8-01900', 'פועל נוסף...', '', 'INFO'),
    (33, '8-01901', 'להתרחץ (את עצמי)', 'LAVARSI', 'LANG'),
    (34, '8-01902', 'הטיות הפועל LAVARSI :', '', 'INFO'),
    (35, '8-02000', 'הטיות הפועל LAVARSI', 'MI LAVO, TI LAVI, SI LAVA, CI LAVIAMO, VI LAVATE, SI LAVANO', 'LANG'),
    (36, '8-02100', 'אני מתרחץ כל יום', 'MI LAVO TUTTI I GIORNI', 'LANG'),
    (37, '8-02200', 'פועל נוסף...', '', 'INFO'),
    (38, '8-02201', 'להתלבש (את עצמי)', 'VESTIRSI', 'LANG'),
    (39, '8-02202', 'הטיות הפועל VESTIRSI :', '', 'INFO'),
    (40, '8-02300', 'הטיות הפועל VESTIRSI', 'MI VESTO, TI VESTI, SI VESTE, CI VESTIAMO, VI VESTITE, SI VESTONO', 'LANG'),
    (41, '8-02400', 'איך אתה מתלבש ?', 'COME TI VESTI ?', 'LANG'),
    (42, '8-02401', 'תשובה...', '', 'INFO'),
    (43, '8-02500', 'אני מתלבש יפה', 'MI VESTO BENE', 'LANG'),
    (44, '8-02600', 'פועל נוסף...', '', 'INFO'),
    (45, '8-02601', 'להרגיש (את עצמי)', 'SENTIRSI', 'LANG'),
    (46, '8-02602', 'הטיות הפועל SENTIRSI :', '', 'INFO'),
    (47, '8-02700', 'הטיות הפועל SENTIRSI', 'MI SENTO, TI SENTI, SI SENTE, CI SENTIAMO, VI SENTITE, SI SENTONO', 'LANG'),
    (48, '8-02800', 'איך אתה מרגיש ?', 'COME TI SENTI ?', 'LANG'),
    (49, '8-02801', 'תשובה...', '', 'INFO'),
    (50, '8-02900', 'אני מרגיש טוב', 'MI SENTO BENE', 'LANG'),
    (51, '8-02901', 'או...', '', 'INFO'),
    (52, '8-03000', 'אני מרגיש רע', 'MI SENTO MALE', 'LANG'),
    (53, '8-03100', 'פועל נוסף...', '', 'INFO'),
    (54, '8-03101', 'להיקרא (בשם)', 'CHIAMARSI', 'LANG'),
    (55, '8-03102', 'הטיות הפועל CHIAMARSI :', '', 'INFO'),
    (56, '8-03200', 'הטיות הפועל CHIAMARSI', 'MI CHIAMO, TI CHIAMI, SI CHIAMA, CI CHIAMIAMO, VI CHIAMATE, SI CHIAMANO', 'LANG'),
    (57, '8-03300', 'איך קוראים לך ?', 'COME TI CHIAMI ?', 'LANG'),
    (58, '8-03301', 'תשובה...', '', 'INFO'),
    (59, '8-03400', 'קוראים לי... (השם שלך)', 'MI CHIAMO...', 'LANG'),
    (60, '8-03500', 'לסיום,כמה מילים על זמנים...', '', 'INFO'),
    (61, '8-03501', 'בוקר', 'MATTINA', 'LANG'),
    (62, '8-03502', 'צהריים', 'MEZZOGIORNO', 'LANG'),
    (63, '8-03503', 'אחר הצהריים', 'POMERIGGIO', 'LANG'),
    (64, '8-03504', 'ערב', 'SERA', 'LANG'),
    (65, '8-03505', 'לילה', 'NOTTE', 'LANG'),
    (66, '8-03600', 'בבוקר', 'LA MATTINA', 'LANG'),
    (67, '8-03700', 'בצהריים', 'A MEZZOGIORNO', 'LANG'),
    (68, '8-03800', 'אחר הצהריים', 'IL POMERIGGIO', 'LANG'),
    (69, '8-03900', 'בערב', 'LA SERA', 'LANG'),
    (70, '8-04000', 'בלילה', 'DI NOTTE', 'LANG')
  ) AS v(order_num, code, text_he, text_it, type);

END $$;

-- End of 20251215100623860_update_lesson_8_content.sql

-- Start of 20251215103000_ensure_indexes.sql
/*
  # Ensure indexes for performance

  1. Changes
    - Add index on lines(lesson_id) if not exists
    - Add index on progress(user_id, lesson_id) if not exists
*/

CREATE INDEX IF NOT EXISTS idx_lines_lesson_id ON lines(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_user_lesson ON progress(user_id, lesson_id);

-- End of 20251215103000_ensure_indexes.sql

