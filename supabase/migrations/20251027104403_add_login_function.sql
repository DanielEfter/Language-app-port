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
