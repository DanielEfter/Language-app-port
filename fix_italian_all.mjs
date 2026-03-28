import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://rtgnsganshsnftxexaww.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Z25zZ2Fuc2hzbmZ0eGV4YXd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgwMTMwMCwiZXhwIjoyMDg1Mzc3MzAwfQ.GoCoe6uvgokjcykQZpZAsm_9PtAzCplMJFNZEEXX-9I';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function main() {
  console.log('🔄 Searching for איטלקית in ALL lessons...');
  
  // Get all lines with איטלקית in text_he
  const { data: lines1 } = await supabase
    .from('lines')
    .select('id, text_he, order_num, lesson_id')
    .ilike('text_he', '%איטלקית%');
  
  console.log(`Found ${lines1?.length || 0} lines with איטלקית in text_he`);
  
  // Get all lines with איטלקית in text_it
  const { data: lines2 } = await supabase
    .from('lines')
    .select('id, text_it, order_num, lesson_id')
    .ilike('text_it', '%איטלקית%');
  
  console.log(`Found ${lines2?.length || 0} lines with איטלקית in text_it`);
  
  // Update text_he
  for (const line of (lines1 || [])) {
    const newText = line.text_he.replace(/איטלקית/g, 'ספרדית');
    await supabase.from('lines').update({ text_he: newText }).eq('id', line.id);
    console.log(`✅ Updated text_he line ${line.order_num}`);
  }
  
  // Update text_it
  for (const line of (lines2 || [])) {
    const newText = line.text_it.replace(/איטלקית/g, 'ספרדית');
    await supabase.from('lines').update({ text_it: newText }).eq('id', line.id);
    console.log(`✅ Updated text_it line ${line.order_num}`);
  }
  
  console.log('Done!');
}

main();
