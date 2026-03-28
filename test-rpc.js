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

console.log('Testing RPC function...\n');

const testUsername = 'rpctest_' + Date.now();
const passwordHash = hashPassword('test123');

const { data, error } = await supabase.rpc('create_user', {
  p_username: testUsername,
  p_password_hash: passwordHash,
  p_role: 'STUDENT'
});

if (error) {
  console.error('❌ Error:', error.message);
} else {
  console.log('✅ Success! User created via RPC:');
  console.log(data);
}
