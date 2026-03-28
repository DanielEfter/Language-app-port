import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

// First get the lesson 6 UUID
const { data: lesson, error: lessonError } = await supabase
  .from('lessons')
  .select('*')
  .eq('index', 6)
  .single();

if (lessonError) {
  console.error('Error getting lesson:', lessonError);
  process.exit(1);
}

console.log('Lesson 6 info:', lesson);

// Now get the lines
const { data: lines, error } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lesson.id)
  .order('order_num', { ascending: true })
  .limit(10);

if (error) {
  console.error('Error getting lines:', error);
} else {
  console.log('\nFirst 10 lines from lesson 6:');
  lines.forEach(line => {
    console.log(`\n--- Order: ${line.order_num} ---`);
    console.log(`Code: ${line.code}`);
    console.log(`Type: ${line.type}`);
    console.log(`Hebrew: ${line.text_he || '(EMPTY)'}`);
    console.log(`English: ${line.text_en || '(EMPTY)'}`);
    console.log(`Italian: ${line.text_it || '(EMPTY)'}`);
  });
}
