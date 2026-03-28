# איך למצוא את ה-Service Role Key

1. כנס ל-Supabase Dashboard: https://supabase.com/dashboard
2. בחר את הפרויקט: yhnupewnkumgmijxwyac
3. לחץ על Settings (הגדרות) בתפריט השמאלי
4. לחץ על API
5. תמצא "Project API keys"
6. העתק את ה-"service_role" key (לא את anon key)
7. הוסף אותו לקובץ .env:

```
VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
```

או שלח לי אותו כאן ואני אוסיף אותו לפרויקט.

⚠️ חשוב: Service Role Key הוא סודי מאוד! אל תשתף אותו באף מקום ציבורי.
