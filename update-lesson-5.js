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
    
    // For lesson 5: מפתח, בעברית, ומהמקבילה באנגלית (אם יש), (ריק), טקסטים להקלטה
    // Column 2 (בעברית) = text_he for language lines
    // Column 3 (ומהמקבילה באנגלית) = text_en (rarely used)
    // Column 4 = sometimes Italian (short words like CHI, NESSUNO)
    // Column 5 (טקסטים להקלטה) = can be Italian OR Hebrew explanation
    const [code, hebrewWord, englishText, col4, col5] = cleanParts;
    
    // Skip if no code (likely a continuation or comment line)
    if (!code || !code.trim()) continue;
    
    // Determine the type and fields based on content
    let type = 'INFO';
    let text_he = '';
    let text_en = '';
    let text_it = '';
    
    // Priority: check col5 first, then col4
    if (col5 && col5.trim()) {
      // Column 5 has content - determine if it's Italian or Hebrew
      // Count Hebrew vs Latin characters to determine the primary language
      const hebrewChars = (col5.match(/[\u0590-\u05FF]/g) || []).length;
      const latinChars = (col5.match(/[A-Za-z]/g) || []).length;
      
      if (hebrewChars > latinChars) {
        // It's Hebrew explanation - INFO line
        type = 'INFO';
        text_he = col5.trim();
      } else {
        // It's Italian - LANG line
        type = 'LANG';
        text_he = hebrewWord ? hebrewWord.trim() : '';
        text_en = englishText ? englishText.trim() : '';
        text_it = col5.trim();
      }
    } else if (col4 && col4.trim()) {
      // Column 4 has content - usually short Italian words
      type = 'LANG';
      text_he = hebrewWord ? hebrewWord.trim() : '';
      text_en = englishText ? englishText.trim() : '';
      text_it = col4.trim();
    } else if (hebrewWord && hebrewWord.trim()) {
      // Only Hebrew word, no Italian - INFO line
      type = 'INFO';
      text_he = hebrewWord.trim();
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

async function updateLesson5() {
  try {
    console.log('Reading CSV file...');
    const csvContent = fs.readFileSync('Lessons-original-files/מפגש 5.csv', 'utf8');
    
    console.log('Parsing CSV...');
    const lines = parseCSV(csvContent);
    console.log(`Parsed ${lines.length} lines from CSV`);
    
    // Get lesson 5 ID
    console.log('Finding lesson 5...');
    const { data: lesson, error: lessonError } = await supabase
      .from('lessons')
      .select('id')
      .eq('index', 5)
      .single();
    
    if (lessonError || !lesson) {
      console.error('Error finding lesson 5:', lessonError);
      process.exit(1);
    }
    
    console.log(`Found lesson 5 with ID: ${lesson.id}`);
    
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
    
    console.log(`\n✅ Successfully updated lesson 5 with ${lines.length} lines!`);
    
  } catch (error) {
    console.error('Unexpected error:', error);
    process.exit(1);
  }
}

updateLesson5();
