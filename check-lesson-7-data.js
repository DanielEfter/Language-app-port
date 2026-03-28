import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

// First get the lesson 7 UUID
const { data: lesson, error: lessonError } = await supabase
  .from('lessons')
  .select('*')
  .eq('index', 7)
  .single();

if (lessonError) {
  console.error('Error getting lesson:', lessonError);
  process.exit(1);
}

console.log('Lesson 7 info:', lesson);

// Now get the lines
const { data: lines, error } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lesson.id)
  .order('order_num', { ascending: true })
  .limit(15);

if (error) {
  console.error('Error getting lines:', error);
} else {
  console.log(`\nFirst 15 lines from lesson 7 (total count coming...):`);
  lines.forEach(line => {
    console.log(`\n--- Order: ${line.order_num} ---`);
    console.log(`Code: ${line.code}`);
    console.log(`Type: ${line.type}`);
    console.log(`Hebrew: ${line.text_he || '(EMPTY)'}`);
    console.log(`English: ${line.text_en || '(EMPTY)'}`);
    console.log(`Italian: ${line.text_it || '(EMPTY)'}`);
  });
}

// Get total count
const { count } = await supabase
  .from('lines')
  .select('*', { count: 'exact', head: true })
  .eq('lesson_id', lesson.id);

console.log(`\n\nTotal lines in lesson 7: ${count}`);
