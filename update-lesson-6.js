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
    
    // For lesson 6: Key, Hebrew, Italian_Equivalent, Notes_Recording_Text
    // Column 2 (Hebrew) = text_he for language lines
    // Column 3 (Italian_Equivalent) = text_it
    // Column 4 (Notes_Recording_Text) = text_he for explanation lines (INFO type)
    const [code, hebrewWord, italianText, explanationText] = cleanParts;
    
    // Skip if no code (likely a continuation or comment line)
    if (!code || !code.trim()) continue;
    
    // Determine type and fields based on content:
    // If there's Italian text (column 3), it's a LANG line and Hebrew word is in column 2
    // If there's no Italian text but there's explanation text (column 4), it's an INFO line
    let type = 'LANG';
    let text_he = '';
    let text_it = '';
    let text_en = '';
    
    if (italianText && italianText.trim()) {
      // LANG line: has Italian translation
      type = 'LANG';
      text_he = hebrewWord ? hebrewWord.trim() : '';
      text_it = italianText.trim();
    } else if (explanationText && explanationText.trim()) {
      // INFO line: has explanation text in Hebrew
      type = 'INFO';
      text_he = explanationText.trim();
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

async function updateLesson6() {
  try {
    console.log('Reading CSV file...');
    const csvContent = fs.readFileSync('Lessons-original-files/מפגש 6.csv', 'utf8');
    
    console.log('Parsing CSV...');
    const lines = parseCSV(csvContent);
    console.log(`Parsed ${lines.length} lines from CSV`);
    
    // Get lesson 6 ID
    console.log('Finding lesson 6...');
    const { data: lesson, error: lessonError } = await supabase
      .from('lessons')
      .select('id')
      .eq('index', 6)
      .single();
    
    if (lessonError || !lesson) {
      console.error('Error finding lesson 6:', lessonError);
      process.exit(1);
    }
    
    console.log(`Found lesson 6 with ID: ${lesson.id}`);
    
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
    
    console.log(`\n✅ Successfully updated lesson 6 with ${lines.length} lines!`);
    
  } catch (error) {
    console.error('Unexpected error:', error);
    process.exit(1);
  }
}

updateLesson6();
