import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// New project details
const supabaseUrl = 'https://imjgijjwydjzprqzxune.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltamdpamp3eWRqenBycXp4dW5lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM2MjE3NywiZXhwIjoyMDg2OTM4MTc3fQ.oUSgOPESKm4C79KXwfO5GvCCvjyU7V8O8Iavd-ZsQdE';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse CSV content with correct logic (copied from fix_all_lessons.mjs)
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
    let type = 'INFO';
    let hebrewText = textHe || '';
    let spanishText = ''; // This will be stored in text_it (reusing field name for compatibility)
    // The existing schema likely uses 'text_it' for foreign language text.
    
    if (textHe && textHe.trim() && textEs && textEs.trim()) {
      type = 'LANG';
      spanishText = textEs.trim();
    } else if (textEs && textEs.trim()) {
       // Only foreign text -> treat as LANG or INFO? Usually phrases.
       // The original logic likely handled this.
       // Use existing logic if defined, otherwise assume INFO if significant.
       spanishText = textEs.trim();
       if (!hebrewText) type = 'LANG'; // Assuming phrase practice
    }
    // Wait, original logic:
    // INFO = הסברים - רק עמודה 4 (בלי עמודה 2), או רק עמודה 2
    
    // Let's refine based on the file inspection or assume INFO default.
    if ((textHe && textHe.trim()) && (textEs && textEs.trim())) {
      type = 'LANG';
    }

    // Clean up quotes
    const clean = (s) => s ? s.replace(/^"|"$/g, '').trim() : '';

    result.push({
      code: clean(code),
      text_he: clean(textHe),
      text_it: clean(textEs), // Using text_it column for the target language (Portuguese/Spanish structure)
      english_text: clean(englishHint),
      type,
      order_num: i
    });
  }
  return result;
}

const lessons = {
  // '0': 'מפגש 0.csv', // Usually lesson 0 is special/intro
  '1': 'מפגש 1.csv',
  '2': 'מפגש 2.csv',
  '3': 'מפגש 3.csv',
  '4': 'מפגש 4.csv',
  '5': 'מפגש 5.csv',
  '6': 'מפגש 6.csv',
  '7': 'מפגש 7.csv',
  '8': 'מפגש 8.csv'
};

async function processLessons() {
  console.log('Starting lesson seed...');
  
  for (const [lessonNum, fileName] of Object.entries(lessons)) {
    console.log(`Processing Lesson ${lessonNum} from ${fileName}...`);
    
    // First, find the lesson ID
    const { data: lessonData, error: lessonError } = await supabase
      .from('lessons')
      .select('id')
      .eq('lesson_number', parseInt(lessonNum))
      .single();
      
    if (lessonError) {
      console.error(`Error finding lesson ${lessonNum}:`, lessonError.message);
      // Try to create the lesson if not exists?
      // Or maybe it exists from migration.
      // If schema migration ran, lessons table is populated?
      // Let's assume schema migration created lessons table, but maybe not rows.
      // We might need to insert lesson row first.
      
      const { data: newLesson, error: createError } = await supabase
        .from('lessons')
        .upsert({ 
            lesson_number: parseInt(lessonNum), 
            title: `Lesson ${lessonNum}`,
            description: `Portuguese Lesson ${lessonNum}`,
            is_active: true
        })
        .select()
        .single();
        
      if (createError) {
          console.error(`Failed to create lesson ${lessonNum}:`, createError);
          continue;
      }
      console.log(`Created/Found Lesson ${lessonNum} with ID: ${newLesson.id}`);
      // Use newLesson.id
    }
    
    let lessonId = lessonData?.id;

    if (!lessonId) {
      console.log(`Lesson ${lessonNum} not found, creating...`);
      const { data: newLesson, error: createError } = await supabase
        .from('lessons')
        .upsert({ 
            lesson_number: parseInt(lessonNum), 
            title: `Lesson ${lessonNum}`,
            description: `Portuguese Lesson ${lessonNum}`,
            is_active: true
        })
        .select()
        .single();
        
      if (createError) {
          console.error(`Failed to create lesson ${lessonNum}:`, createError);
          continue;
      }
      lessonId = newLesson.id;
      console.log(`Created Lesson ${lessonNum} with ID: ${lessonId}`);
    }

    // Read CSV
    const filePath = path.join(__dirname, 'Lessons-original-files', fileName);
    if (!fs.existsSync(filePath)) {
      console.error(`File not found: ${filePath}`);
      continue;
    }
    
    const content = fs.readFileSync(filePath, 'utf8');
    const records = parseCSV(content, lessonNum);
    
    // Delete existing lines for this lesson
    const { error: deleteError } = await supabase
      .from('lines')
      .delete()
      .eq('lesson_id', lessonId);
      
    if (deleteError) {
      console.error(`Error clearing lines for lesson ${lessonNum}:`, deleteError);
    }
    
    // Insert new lines
    // Batch insert
    for (const record of records) {
        // Enforce validations
        if (!record.code) record.code = `${lessonNum}-${String(record.order_num).padStart(5, '0')}`;
        
        const { error: insertError } = await supabase
            .from('lines')
            .insert({
                lesson_id: lessonId,
                order_num: record.order_num,
                code: record.code,
                text_he: record.text_he,
                text_it: record.text_it,
                type: record.type,
                english_text: record.english_text
            });
            
        if (insertError) {
            console.error(`Error inserting line ${record.code}:`, insertError);
        }
    }
    
    console.log(`Completed Lesson ${lessonNum}: ${records.length} lines.`);
  }
}

processLessons();
