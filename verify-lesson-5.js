import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

const { data: lesson, error: lessonError } = await supabase
  .from('lessons')
  .select('*')
  .eq('index', 5)
  .single();

if (lessonError) {
  console.error('Error:', lessonError);
  process.exit(1);
}

console.log('Lesson 5:', lesson.title);

// Check some key lines from the CSV
const checkCodes = ['5-00100', '5-00200', '5-00300', '5-00400', '5-00500', '5-00703', '5-01000', '5-01001', '5-01602'];

for (const code of checkCodes) {
  const { data: line } = await supabase
    .from('lines')
    .select('*')
    .eq('lesson_id', lesson.id)
    .eq('code', code)
    .single();
    
  if (line) {
    console.log(`\n--- ${code} (Type: ${line.type}) ---`);
    console.log(`Hebrew: ${line.text_he || '(EMPTY)'}`);
    console.log(`English: ${line.text_en || '(EMPTY)'}`);
    console.log(`Italian: ${line.text_it || '(EMPTY)'}`);
  }
}

// Count totals
const { count: totalLines } = await supabase
  .from('lines')
  .select('*', { count: 'exact', head: true })
  .eq('lesson_id', lesson.id);

const { count: langLines } = await supabase
  .from('lines')
  .select('*', { count: 'exact', head: true })
  .eq('lesson_id', lesson.id)
  .eq('type', 'LANG');

const { count: infoLines } = await supabase
  .from('lines')
  .select('*', { count: 'exact', head: true })
  .eq('lesson_id', lesson.id)
  .eq('type', 'INFO');

console.log(`\n\nTotal lines: ${totalLines}`);
console.log(`LANG lines: ${langLines}`);
console.log(`INFO lines: ${infoLines}`);
