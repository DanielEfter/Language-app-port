/*
  # Ensure indexes for performance

  1. Changes
    - Add index on lines(lesson_id) if not exists
    - Add index on progress(user_id, lesson_id) if not exists
*/

CREATE INDEX IF NOT EXISTS idx_lines_lesson_id ON lines(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_user_lesson ON progress(user_id, lesson_id);
