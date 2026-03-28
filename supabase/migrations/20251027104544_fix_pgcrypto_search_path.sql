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
