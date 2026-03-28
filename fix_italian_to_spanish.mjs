import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://rtgnsganshsnftxexaww.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Z25zZ2Fuc2hzbmZ0eGV4YXd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgwMTMwMCwiZXhwIjoyMDg1Mzc3MzAwfQ.GoCoe6uvgokjcykQZpZAsm_9PtAzCplMJFNZEEXX-9I';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function main() {
  console.log('🔄 Fixing איטלקית -> ספרדית in lesson 0...');
  
  // Get lesson 0 ID
  const { data: lesson } = await supabase
    .from('lessons')
    .select('id')
    .eq('index', 0)
    .single();
  
  // Get all lines with איטלקית
  const { data: lines } = await supabase
    .from('lines')
    .select('*')
    .eq('lesson_id', lesson.id)
    .ilike('text_he', '%איטלקית%');
  
  console.log(`Found ${lines.length} lines with איטלקית`);
  
  for (const line of lines) {
    const newText = line.text_he.replace(/איטלקית/g, 'ספרדית');
    
    const { error } = await supabase
      .from('lines')
      .update({ text_he: newText })
      .eq('id', line.id);
    
    if (error) {
      console.error(`Error updating line ${line.order_num}:`, error);
    } else {
      console.log(`✅ Updated line ${line.order_num}`);
    }
  }
  
  console.log('Done!');
}

main();
