import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://yhnupewnkumgmijxwyac.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobnVwZXdua3VtZ21panh3eWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Njk4MjIsImV4cCI6MjA3NjM0NTgyMn0.dt20UlIq3tzpSbja4CoaLjJLuRb34eET9WhnO3LisMA'
);

console.log('=== בודק חיבור ל-Supabase ===\n');

console.log('1. בודק אם טבלת users קיימת...');
const { data: users, error: usersError } = await supabase.from('users').select('count');
if (usersError) {
  console.error('❌ שגיאה:', usersError.message);
  console.error('קוד:', usersError.code);
  console.error('פרטים:', usersError.details);
} else {
  console.log('✅ טבלת users קיימת');
}

console.log('\n2. מנסה ליצור משתמש...');
const { data: newUser, error: createError } = await supabase.from('users').insert({
  username: 'test_' + Date.now(),
  password_hash: '$2a$10$abcdefghijklmnopqrstuv',
  role: 'STUDENT'
}).select();

if (createError) {
  console.error('❌ שגיאה ביצירה:', createError.message);
  console.error('קוד:', createError.code);
  console.error('פרטים:', createError.details);
  console.error('רמז:', createError.hint);
} else {
  console.log('✅ משתמש נוצר בהצלחה:', newUser);
}

console.log('\n3. בודק טבלאות אחרות...');
const { data: lessons, error: lessonsError } = await supabase.from('lessons').select('count');
if (lessonsError) {
  console.error('❌ טבלת lessons:', lessonsError.message);
} else {
  console.log('✅ טבלת lessons קיימת');
}
