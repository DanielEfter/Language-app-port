-- הכנס משתמש ישירות (בעקיפת RLS)
-- הרץ את זה ב-Supabase SQL Editor

-- תחילה בדוק אם המשתמש קיים
SELECT * FROM users WHERE username = 'student1';

-- אם לא קיים, הכנס אותו
INSERT INTO users (username, password_hash, role, is_active)
VALUES ('student1', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'STUDENT', true)
ON CONFLICT (username) DO NOTHING;

-- בדוק שנוצר
SELECT id, username, role, is_active FROM users WHERE username = 'student1';
