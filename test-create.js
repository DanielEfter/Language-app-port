import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://yhnupewnkumgmijxwyac.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobnVwZXdua3VtZ21panh3eWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Njk4MjIsImV4cCI6MjA3NjM0NTgyMn0.dt20UlIq3tzpSbja4CoaLjJLuRb34eET9WhnO3LisMA'
);

console.log('=== Testing Supabase Client ===\n');

// Test 1: Can we read users?
console.log('1. Reading users...');
const { data: users, error: readError } = await supabase.from('users').select('username, role');
if (readError) {
  console.error('❌ Read error:', readError.message);
} else {
  console.log('✅ Can read users:', users?.length || 0, 'users found');
  console.table(users);
}

// Test 2: Can we insert?
console.log('\n2. Trying to insert user...');
const testUsername = 'test_' + Date.now();
const { data: newUser, error: insertError } = await supabase
  .from('users')
  .insert({
    username: testUsername,
    password_hash: 'testhash123',
    role: 'STUDENT',
    is_active: true,
  })
  .select();

if (insertError) {
  console.error('❌ Insert error:', insertError.message);
  console.error('   Code:', insertError.code);
  console.error('   Details:', insertError.details);
  console.error('   Hint:', insertError.hint);
} else {
  console.log('✅ User created successfully!');
  console.log(newUser);
}
