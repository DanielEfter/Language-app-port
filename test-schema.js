import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://yhnupewnkumgmijxwyac.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobnVwZXdua3VtZ21panh3eWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Njk4MjIsImV4cCI6MjA3NjM0NTgyMn0.dt20UlIq3tzpSbja4CoaLjJLuRb34eET9WhnO3LisMA',
  {
    db: {
      schema: 'public'
    }
  }
);

console.log('Testing with explicit public schema...\n');

const testUsername = 'testuser_' + Date.now();
const { data, error } = await supabase
  .from('users')
  .insert({
    username: testUsername,
    password_hash: 'hash123',
    role: 'STUDENT',
    is_active: true
  })
  .select();

if (error) {
  console.error('❌ Error:', error.message);
  console.error('   Code:', error.code);
} else {
  console.log('✅ Success! User created:');
  console.log(data);
}
