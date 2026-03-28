import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://yhnupewnkumgmijxwyac.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobnVwZXdua3VtZ21panh3eWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Njk4MjIsImV4cCI6MjA3NjM0NTgyMn0.dt20UlIq3tzpSbja4CoaLjJLuRb34eET9WhnO3LisMA';

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('=== בודק מדיניות RLS ===\n');

const { data, error } = await supabase.rpc('exec_sql', {
  sql: `
    SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies
    WHERE tablename = 'users'
    ORDER BY policyname;
  `
});

if (error) {
  console.log('לא ניתן לבדוק RLS ישירות');
  console.log('נסה להתחבר כאדמין...');
  
  const { data: adminLogin, error: loginError } = await supabase.auth.signInWithPassword({
    email: 'admin@test.com',
    password: 'test123'
  });
  
  if (loginError) {
    console.log('אין אימות מוגדר');
  }
} else {
  console.log('מדיניות RLS:', data);
}
