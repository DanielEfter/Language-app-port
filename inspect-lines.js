import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

const { data, error } = await supabase
  .from('lines')
  .select('*')
  .eq('code', '1-00201')
  .limit(1);

if (data && data.length > 0) {
  console.log('Line sample:', data[0]);
} else {
  // Try to find lesson 1 first
  const { data: lessons } = await supabase.from('lessons').select('id').eq('index', 1).single();
  if (lessons) {
    console.log('Lesson 1 ID:', lessons.id);
    const { data: lines } = await supabase.from('lines').select('*').eq('lesson_id', lessons.id).limit(1);
    console.log('Line sample:', lines ? lines[0] : 'No lines');
  } else {
    console.log('Lesson 1 not found');
  }
}
