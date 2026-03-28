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
