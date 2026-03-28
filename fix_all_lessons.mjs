import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://rtgnsganshsnftxexaww.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Z25zZ2Fuc2hzbmZ0eGV4YXd3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgwMTMwMCwiZXhwIjoyMDg1Mzc3MzAwfQ.GoCoe6uvgokjcykQZpZAsm_9PtAzCplMJFNZEEXX-9I';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse CSV content with correct logic
function parseCSV(content, lessonNum) {
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
      code: code || `${lessonNum}-${String(i).padStart(5, '0')}`,
      text_he: hebrewText,
      text_it: spanishText,
      type
    });
  }
  
  return result;
}

async function fixLesson(lessonIndex, filename) {
  console.log(`\n📚 Fixing lesson ${lessonIndex}...`);
  
  // Get lesson ID
  const { data: lesson, error: lessonError } = await supabase
    .from('lessons')
    .select('id')
    .eq('index', lessonIndex)
    .single();
  
  if (lessonError) {
    console.error(`Error finding lesson ${lessonIndex}:`, lessonError);
    return false;
  }
  
  // Read CSV file
  const csvPath = `Lessons-original-files/${filename}`;
  if (!fs.existsSync(csvPath)) {
    console.error(`File not found: ${csvPath}`);
    return false;
  }
  
  const csvContent = fs.readFileSync(csvPath, 'utf-8');
  const parsedLines = parseCSV(csvContent, lessonIndex);
  
  // Count types
  const langCount = parsedLines.filter(l => l.type === 'LANG').length;
  const infoCount = parsedLines.filter(l => l.type === 'INFO').length;
  console.log(`   Parsed ${parsedLines.length} lines: ${langCount} LANG, ${infoCount} INFO`);
  
  // Delete existing lines for this lesson
  const { error: deleteError } = await supabase
    .from('lines')
    .delete()
    .eq('lesson_id', lesson.id);
  
  if (deleteError) {
    console.error(`Error deleting existing lines for lesson ${lessonIndex}:`, deleteError);
    return false;
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
      console.error(`Error inserting lines batch for lesson ${lessonIndex}:`, insertError);
      return false;
    }
  }
  
  console.log(`   ✅ Inserted ${linesToInsert.length} lines`);
  return true;
}

async function main() {
  console.log('🔧 Fixing all lessons with correct LANG/INFO logic...');
  
  const lessons = [
    { index: 0, file: 'מפגש 0.csv' },
    { index: 2, file: 'מפגש 2.csv' },
    { index: 3, file: 'מפגש 3.csv' },
    { index: 4, file: 'מפגש 4.csv' },
    { index: 5, file: 'מפגש 5.csv' },
    { index: 6, file: 'מפגש 6.csv' },
    { index: 7, file: 'מפגש 7.csv' },
    { index: 8, file: 'מפגש 8.csv' },
  ];
  
  let successCount = 0;
  
  for (const lesson of lessons) {
    const success = await fixLesson(lesson.index, lesson.file);
    if (success) successCount++;
  }
  
  console.log(`\n✅ Fixed ${successCount}/${lessons.length} lessons`);
}

main();
