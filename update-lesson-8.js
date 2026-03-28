import fs from 'fs';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Read environment variables
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing Supabase credentials in environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse CSV content
function parseCSV(content) {
  const lines = content.split('\n').slice(1); // Skip header
  const parsedLines = [];
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    // Split by comma, but respect quotes
    const parts = [];
    let current = '';
    let inQuotes = false;
    
    for (let j = 0; j < line.length; j++) {
      const char = line[j];
      
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        parts.push(current);
        current = '';
      } else {
        current += char;
      }
    }
    parts.push(current);
    
    // Clean up quotes
    const cleanParts = parts.map(p => p.replace(/^"(.*)"$/, '$1').replace(/""/g, '"'));
    
    // For lesson 8: מפתח, בעברית, מקבילה באנגלית, הערות, טקסט לאיטלקית
    // Column 2 (בעברית) = text_he for language lines
    // Column 3 (מקבילה באנגלית) = text_en (rarely used)
    // Column 4 (הערות) = notes (unused)
    // Column 5 (טקסט לאיטלקית) = can be Italian OR Hebrew explanation
    const [code, hebrewWord, englishText, notes, col5] = cleanParts;
    
    // Skip if no code (likely a continuation or comment line)
    if (!code || !code.trim()) continue;
    
    // Determine if column 5 is Italian (Latin letters) or Hebrew (explanation)
    let type = 'INFO';
    let text_he = '';
    let text_en = '';
    let text_it = '';
    
    if (col5 && col5.trim()) {
      // Check if column 5 contains Latin letters (Italian) or only Hebrew
      // Count Hebrew vs Latin characters to determine the primary language
      const hebrewChars = (col5.match(/[\u0590-\u05FF]/g) || []).length;
      const latinChars = (col5.match(/[A-Za-z]/g) || []).length;
      
      // If more Hebrew characters than Latin, it's an explanation
      // Otherwise it's Italian (even if it has some Hebrew)
      if (hebrewChars > latinChars) {
        // It's Hebrew explanation - this is an INFO line
        type = 'INFO';
        text_he = col5.trim();
      } else {
        // It's Italian - this is a LANG line
        type = 'LANG';
        text_he = hebrewWord ? hebrewWord.trim() : '';
        text_en = englishText ? englishText.trim() : '';
        text_it = col5.trim();
      }
    } else {
      // No content in column 5, check if there's Hebrew in column 2
      if (hebrewWord && hebrewWord.trim()) {
        type = 'INFO';
        text_he = hebrewWord.trim();
      }
    }
    
    parsedLines.push({
      code: code.trim(),
      text_he: text_he,
      text_en: text_en,
      text_it: text_it,
      type: type
    });
  }
  
  return parsedLines;
}

async function updateLesson8() {
  try {
    console.log('Reading CSV file...');
    const csvContent = fs.readFileSync('Lessons-original-files/מפגש 8.csv', 'utf8');
    
    console.log('Parsing CSV...');
    const lines = parseCSV(csvContent);
    console.log(`Parsed ${lines.length} lines from CSV`);
    
    // Get lesson 8 ID
    console.log('Finding lesson 8...');
    const { data: lesson, error: lessonError } = await supabase
      .from('lessons')
      .select('id')
      .eq('index', 8)
      .single();
    
    if (lessonError || !lesson) {
      console.error('Error finding lesson 8:', lessonError);
      process.exit(1);
    }
    
    console.log(`Found lesson 8 with ID: ${lesson.id}`);
    
    // Delete existing lines
    console.log('Deleting existing lines...');
    const { error: deleteError } = await supabase
      .from('lines')
      .delete()
      .eq('lesson_id', lesson.id);
    
    if (deleteError) {
      console.error('Error deleting lines:', deleteError);
      process.exit(1);
    }
    
    console.log('Existing lines deleted successfully');
    
    // Insert new lines
    console.log('Inserting new lines...');
    let order_num = 1;
    
    for (const line of lines) {
      const lineData = {
        lesson_id: lesson.id,
        order_num: order_num++,
        code: line.code,
        type: line.type,
        text_he: line.text_he || '',
        text_en: line.text_en || '',
        text_it: line.text_it || '',
        stress_rule: null,
        recording_hint: null
      };
      
      const { error: insertError } = await supabase
        .from('lines')
        .insert(lineData);
      
      if (insertError) {
        console.error(`Error inserting line ${line.code}:`, insertError);
        process.exit(1);
      }
      
      if (order_num % 10 === 0) {
        console.log(`Inserted ${order_num - 1} lines...`);
      }
    }
    
    console.log(`\n✅ Successfully updated lesson 8 with ${lines.length} lines!`);
    
  } catch (error) {
    console.error('Unexpected error:', error);
    process.exit(1);
  }
}

updateLesson8();
