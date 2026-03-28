import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://rtgnsganshsnftxexaww.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Z25zZ2Fuc2hzbmZ0eGV4YXd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgwMTMwMCwiZXhwIjoyMDg1Mzc3MzAwfQ.GoCoe6uvgokjcykQZpZAsm_9PtAzCplMJFNZEEXX-9I';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse CSV content with correct logic
function parseCSV(content) {
  const lines = content.split('\n');
  const result = [];
  
  for (let i = 1; i < lines.length; i++) { // Skip header
    const line = lines[i].trim();
    if (!line) continue;
    
    // Handle CSV with possible quoted fields
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
    
    // Columns: מפתח, בעברית, דומה באנגלית, טקסטים להקלטה
    const [code, textHe, englishHint, textEs] = parts;
    
    if (!code && !textHe && !textEs) continue;
    
    // Determine type based on content:
    // LANG = יש טקסט עברי (עמודה 2) וגם יש טקסט ספרדי (עמודה 4)
    // INFO = הסברים - רק עמודה 4 (בלי עמודה 2), או רק עמודה 2
    let type = 'INFO';
    let hebrewText = textHe || '';
    let spanishText = '';
    
    if (textHe && textHe.trim() && textEs && textEs.trim()) {
      // יש גם עברית וגם ספרדית - זה LANG
      type = 'LANG';
      hebrewText = textHe;
      spanishText = textEs;
    } else if (textEs && textEs.trim() && (!textHe || !textHe.trim())) {
      // יש רק עמודה 4 - זה הסבר
      type = 'INFO';
      hebrewText = textEs; // ההסבר הולך לעמודה העברית
      spanishText = '';
    } else if (textHe && textHe.trim()) {
      // יש רק עברית
      type = 'INFO';
      hebrewText = textHe;
    }
    
    result.push({
      code: code || `1-${String(i).padStart(5, '0')}`,
      text_he: hebrewText,
      text_it: spanishText,
      type
    });
  }
  
  return result;
}

async function fixLesson1() {
  console.log('🔧 Fixing lesson 1...\n');
  
  // Get lesson 1 ID
  const { data: lesson, error: lessonError } = await supabase
    .from('lessons')
    .select('id')
    .eq('index', 1)
    .single();
  
  if (lessonError) {
    console.error('Error finding lesson 1:', lessonError);
    return;
  }
  
  console.log('Found lesson 1 with ID:', lesson.id);
  
  // Read CSV file
  const csvContent = fs.readFileSync('Lessons-original-files/מפגש 1.csv', 'utf-8');
  const parsedLines = parseCSV(csvContent);
  
  // Count types
  const langCount = parsedLines.filter(l => l.type === 'LANG').length;
  const infoCount = parsedLines.filter(l => l.type === 'INFO').length;
  console.log(`Parsed ${parsedLines.length} lines: ${langCount} LANG, ${infoCount} INFO`);
  
  // Show some examples
  console.log('\nFirst 5 INFO lines:');
  parsedLines.filter(l => l.type === 'INFO').slice(0, 5).forEach(l => {
    console.log(`  ${l.code}: ${l.text_he.substring(0, 60)}...`);
  });
  
  console.log('\nFirst 5 LANG lines:');
  parsedLines.filter(l => l.type === 'LANG').slice(0, 5).forEach(l => {
    console.log(`  ${l.code}: ${l.text_he} -> ${l.text_it}`);
  });
  
  // Delete existing lines for lesson 1
  const { error: deleteError } = await supabase
    .from('lines')
    .delete()
    .eq('lesson_id', lesson.id);
  
  if (deleteError) {
    console.error('Error deleting existing lines:', deleteError);
    return;
  }
  
  // Insert new lines
  const linesToInsert = parsedLines.map((line, index) => ({
    lesson_id: lesson.id,
    order_num: index + 1,
    code: line.code,
    text_he: line.text_he,
    text_it: line.text_it,
    type: line.type
  }));
  
  // Insert in batches of 100
  for (let i = 0; i < linesToInsert.length; i += 100) {
    const batch = linesToInsert.slice(i, i + 100);
    const { error: insertError } = await supabase.from('lines').insert(batch);
    if (insertError) {
      console.error('Error inserting lines batch:', insertError);
      return;
    }
  }
  
  console.log(`\n✅ Successfully inserted ${linesToInsert.length} lines for lesson 1`);
}

fixLesson1();
