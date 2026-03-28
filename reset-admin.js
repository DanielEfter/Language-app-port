import { createClient } from '@supabase/supabase-js';
import { createHash } from 'crypto';

const supabase = createClient(
  'https://yhnupewnkumgmijxwyac.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobnVwZXdua3VtZ21panh3eWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Njk4MjIsImV4cCI6MjA3NjM0NTgyMn0.dt20UlIq3tzpSbja4CoaLjJLuRb34eET9WhnO3LisMA'
);

function hashPassword(password) {
  const hash = createHash('sha256');
  hash.update(password + 'salt_italian_2024');
  return hash.digest('hex');
}

console.log('יוצר משתמש אדמין...\n');

// Delete existing admin if exists
await supabase.from('users').delete().eq('username', 'tomyadmin');

// Create admin user
const adminHash = hashPassword('tom@1510f');
const { data: admin, error: adminError } = await supabase
  .from('users')
  .insert({
    username: 'tomyadmin',
    password_hash: adminHash,
    role: 'ADMIN',
    is_active: true,
  })
  .select()
  .single();

if (adminError) {
  console.error('❌ שגיאה ביצירת אדמין:', adminError.message);
} else {
  console.log('✅ אדמין נוצר בהצלחה!');
  console.log('   שם משתמש: tomyadmin');
  console.log('   סיסמה: tom@1510f');
}

// Create a test student
console.log('\nיוצר תלמיד לדוגמא...\n');

await supabase.from('users').delete().eq('username', 'student1');

const studentHash = hashPassword('student123');
const { data: student, error: studentError } = await supabase
  .from('users')
  .insert({
    username: 'student1',
    password_hash: studentHash,
    role: 'STUDENT',
    is_active: true,
  })
  .select()
  .single();

if (studentError) {
  console.error('❌ שגיאה ביצירת תלמיד:', studentError.message);
} else {
  console.log('✅ תלמיד נוצר בהצלחה!');
  console.log('   שם משתמש: student1');
  console.log('   סיסמה: student123');
}

// Check all users
console.log('\n=== כל המשתמשים במערכת ===\n');
const { data: allUsers } = await supabase.from('users').select('username, role, is_active');
console.table(allUsers);
