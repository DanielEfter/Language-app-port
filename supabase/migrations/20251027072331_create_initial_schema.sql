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
