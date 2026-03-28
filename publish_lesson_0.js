
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://imjgijjwydjzprqzxune.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltamdpamp3eWRqenBycXp4dW5lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM2MjE3NywiZXhwIjoyMDg2OTM4MTc3fQ.oUSgOPESKm4C79KXwfO5GvCCvjyU7V8O8Iavd-ZsQdE'
const supabase = createClient(supabaseUrl, supabaseKey)

async function publishLesson0() {
  console.log('Publishing Lesson 0...') // and others?

  // Update Lesson 0 to be published
  const { error } = await supabase
    .from('lessons')
    .update({ is_published: true })
    .eq('index', 0)
  
  if (error) {
    console.error('Error publishing Lesson 0:', error)
  } else {
    console.log('Lesson 0 published successfully.')
  }

  // Check all lessons
  const { data: lessons } = await supabase.from('lessons').select('index, title, is_published').order('index')
  console.log('All lessons status:', lessons)
}

publishLesson0()
