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
