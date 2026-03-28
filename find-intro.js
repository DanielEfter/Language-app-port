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

const { data: lines } = await supabase
  .from('lines')
  .select('*')
  .eq('lesson_id', lesson.id)
  .like('text_he', '%בשיעור הזה%');

console.log('Lines with "בשיעור הזה":');
lines.forEach(line => {
  console.log(`\nOrder: ${line.order_num}, Code: ${line.code} (${line.type})`);
  console.log(`  HE: ${line.text_he.substring(0, 50)}...`);
  console.log(`  IT: ${line.text_it || '(empty)'}`);
});
