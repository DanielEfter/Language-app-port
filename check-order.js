import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

const { data: lesson } = await supabase
  .from('lessons')
  .select('*')
  .eq('index', 5)
  .single();

// Get first 5 lines by order_num
const { data: lines } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lesson.id)
  .order('order_num', { ascending: true })
  .limit(5);

console.log('First 5 lines by order_num:');
lines.forEach(line => {
  console.log(`\n${line.order_num}. ${line.code} (${line.type})`);
  console.log(`  HE: ${line.text_he || '(empty)'}`);
  console.log(`  IT: ${line.text_it || '(empty)'}`);
});

// Get lines with code 5-00100
const { data: code100 } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lesson.id)
  .eq('code', '5-00100');

console.log('\n\nLines with code 5-00100:', code100.length);
code100.forEach(line => {
  console.log(`\nOrder ${line.order_num}: ${line.code} (${line.type})`);
  console.log(`  HE: ${line.text_he || '(empty)'}`);
  console.log(`  IT: ${line.text_it || '(empty)'}`);
});
