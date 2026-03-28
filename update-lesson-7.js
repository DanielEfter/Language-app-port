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
    
    // For lesson 7: Key, Hebrew, English, Italian
    // Column 2 (Hebrew) = text_he for language lines
    // Column 3 (English) = text_en (rarely used)
    // Column 4 (Italian OR Hebrew explanation) = need to detect which one
    const [code, hebrewWord, englishText, col4] = cleanParts;
    
    // Skip if no code (likely a continuation or comment line)
    if (!code || !code.trim()) continue;
    
    // Determine if column 4 is Italian (Latin letters) or Hebrew (explanation)
    let type = 'INFO';
    let text_he = '';
    let text_en = '';
    let text_it = '';
    
    if (col4 && col4.trim()) {
      // Check if column 4 contains Latin letters (Italian) or only Hebrew
      const hasLatin = /[A-Z]/i.test(col4);
      
      if (hasLatin) {
        // It's Italian - this is a LANG line
        type = 'LANG';
        text_he = hebrewWord ? hebrewWord.trim() : '';
        text_en = englishText ? englishText.trim() : '';
        text_it = col4.trim();
      } else {
        // It's Hebrew explanation - this is an INFO line
        type = 'INFO';
        text_he = col4.trim();
      }
    } else {
      // No content in column 4, check if there's Hebrew in column 2
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

async function updateLesson7() {
  try {
    console.log('Reading CSV file...');
    const csvContent = fs.readFileSync('Lessons-original-files/מפגש 7.csv', 'utf8');
    
    console.log('Parsing CSV...');
    const lines = parseCSV(csvContent);
    console.log(`Parsed ${lines.length} lines from CSV`);
    
    // Get lesson 7 ID
    console.log('Finding lesson 7...');
    const { data: lesson, error: lessonError } = await supabase
      .from('lessons')
      .select('id')
      .eq('index', 7)
      .single();
    
    if (lessonError || !lesson) {
      console.error('Error finding lesson 7:', lessonError);
      process.exit(1);
    }
    
    console.log(`Found lesson 7 with ID: ${lesson.id}`);
    
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
    
    console.log(`\n✅ Successfully updated lesson 7 with ${lines.length} lines!`);
    
  } catch (error) {
    console.error('Unexpected error:', error);
    process.exit(1);
  }
}

updateLesson7();
