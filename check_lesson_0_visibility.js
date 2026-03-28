
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://imjgijjwydjzprqzxune.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltamdpamp3eWRqenBycXp4dW5lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM2MjE3NywiZXhwIjoyMDg2OTM4MTc3fQ.oUSgOPESKm4C79KXwfO5GvCCvjyU7V8O8Iavd-ZsQdE'
const supabase = createClient(supabaseUrl, supabaseKey)

async function checkLesson0() {
  const { data, error } = await supabase
    .from('lessons')
    .select('*')
    .eq('index', 0)
  
  console.log('Lesson 0 data:', data)
  console.log('Error:', error)
}

checkLesson0()
