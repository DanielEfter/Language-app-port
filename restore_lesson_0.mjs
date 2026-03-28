import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://rtgnsganshsnftxexaww.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Z25zZ2Fuc2hzbmZ0eGV4YXd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgwMTMwMCwiZXhwIjoyMDg1Mzc3MzAwfQ.GoCoe6uvgokjcykQZpZAsm_9PtAzCplMJFNZEEXX-9I';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Original parsing logic - all lines are LANG
function parseCSV(content) {
  const lines = content.split('\n');
  const result = [];
  
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    const parts = [];
    let current = '';
    let inQuotes = false;
    
    for (let j = 0; j < line.length; j++) {
      const char = line[j];
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        parts.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    parts.push(current.trim());
    
    const [code, textHe, englishHint, textEs] = parts;
    
    if (!code && !textHe && !textEs) continue;
    
    result.push({
      code: code || `0-${String(i).padStart(5, '0')}`,
      text_he: textHe || '',
      text_it: textEs || '',
      type: 'LANG'
    });
  }
  
  return result;
}

async function main() {
  console.log('🔄 Restoring lesson 0 to original format...');
  
  const { data: lesson, error: lessonError } = await supabase
    .from('lessons')
    .select('id')
    .eq('index', 0)
    .single();
  
  if (lessonError) {
    console.error('Error finding lesson 0:', lessonError);
    return;
  }
  
  const csvContent = fs.readFileSync('Lessons-original-files/מפגש 0.csv', 'utf-8');
  const parsedLines = parseCSV(csvContent);
  
  console.log(`Parsed ${parsedLines.length} lines (all LANG)`);
  
  // Delete existing lines
  await supabase.from('lines').delete().eq('lesson_id', lesson.id);
  
  // Insert new lines
  const linesToInsert = parsedLines.map((line, index) => ({
    lesson_id: lesson.id,
    order_num: index + 1,
    code: line.code,
    text_he: line.text_he,
    text_it: line.text_it,
    type: line.type
  }));
  
  const { error: insertError } = await supabase.from('lines').insert(linesToInsert);
  
  if (insertError) {
    console.error('Error inserting lines:', insertError);
    return;
  }
  
  console.log(`✅ Restored ${linesToInsert.length} lines for lesson 0 (all LANG type)`);
}

main();
