// Script to check for specific users in the new database
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltamdpamp3eWRqenBycXp4dW5lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM2MjE3NywiZXhwIjoyMDg2OTM4MTc3fQ.oUSgOPESKm4C79KXwfO5GvCCvjyU7V8O8Iavd-ZsQdE';
const FUNCTION_URL = `https://imjgijjwydjzprqzxune.supabase.co/functions/v1/migrate`; // Using existing migrate function which executes SQL

async function checkUsers() {
  // Query both auth.users (if possible) and public.users
  // Note: accessing auth schema requires superuser or specific permissions. 
  // The connection string in Edge Function usually has permissions.
  
  const sql = `
    SELECT 'public.users' as source, email, role FROM public.users WHERE email ILIKE '%admin%' OR email ILIKE '%test%';
    -- We can also try to list from auth.users if permissions allow
    SELECT 'auth.users' as source, email FROM auth.users WHERE email ILIKE '%admin%' OR email ILIKE '%test%';
  `;
  
  try {
    const res = await fetch(FUNCTION_URL, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${SERVICE_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ sql })
    });
    
    const data = await res.json();
    console.log('User Check Result:', JSON.stringify(data, null, 2));

  } catch(e) { console.error(e); }
}

checkUsers();
