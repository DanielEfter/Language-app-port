import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

// First get the lesson 5 UUID
const { data: lessons, error: lessonsError } = await supabase
  .from('lessons')
  .select('*')
  .eq('index', 5)
  .single();

if (lessonsError) {
  console.error('Error getting lesson:', lessonsError);
  process.exit(1);
}

console.log('Lesson 5 info:', lessons);

// Now get the lines
const { data: lines, error } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lessons.id)
  .order('order_num', { ascending: true })
  .limit(5);

if (error) {
  console.error('Error getting lines:', error);
} else {
  console.log('\nFirst 5 lines from lesson 5:');
  lines.forEach(line => {
    console.log(`\n--- Order: ${line.order_num} ---`);
    console.log(`Code: ${line.code}`);
    console.log(`Type: ${line.type}`);
    console.log(`Hebrew: ${line.text_he}`);
    console.log(`English: ${line.text_en}`);
    console.log(`Italian: ${line.text_it || '(EMPTY)'}`);
  });
}
