import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function hasHebrew(text) {
  return /[\u0590-\u05FF]/.test(text);
}

function processBuffer(code, buffer, parsedItems) {
  let he = '';
  let en = '';
  let it = '';
  let type = 'INFO';

  if (buffer.length === 0) {
    // Empty item?
  } else if (buffer.length === 1) {
    he = buffer[0];
  } else if (buffer.length === 2) {
    he = buffer[0];
    en = buffer[1];
  } else {
    he = buffer[0];
    en = buffer[1];
    it = buffer.slice(2).join(' '); // Join remaining lines as Italian
  }

  // Determine type
  // If we have Italian text, it's likely a LANG card
  if (it && /[a-zA-Z]/.test(it)) {
    type = 'LANG';
  }
  
  parsedItems.push({
    code,
    text_he: he,
    text_en: en,
    text_it: it,
    type
  });
}

async function main() {
  console.log('Reading dump file...');
  const dumpPath = path.join(__dirname, 'lesson5_dump.txt');
  
  try {
    const content = fs.readFileSync(dumpPath, 'utf-8');
    if (!content.trim()) {
      console.log('File is empty. Please paste the content into lesson5_dump.txt');
      return;
    }
    
    const lines = content.split(/\r?\n|\r/);
    const parsedItems = [];

    let currentCode = null;
    let buffer = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Check if line is a code
      // Codes for lesson 5 start with '5-' and are followed by digits
      const normalizedLine = line.replace(/\s+/g, '');
      
      if (normalizedLine.match(/^5-\d+$/)) {
        // If we have a previous code, process its buffer
        if (currentCode) {
          processBuffer(currentCode, buffer, parsedItems);
        }
        
        // Start new item
        currentCode = normalizedLine;
        buffer = [];
      } else if (line.length > 0) {
        // Add to buffer if not empty
        if (currentCode) {
          buffer.push(line);
        }
      }
    }
    
    // Process last item
    if (currentCode) {
      processBuffer(currentCode, buffer, parsedItems);
    }

    // Deduplicate items by code
    const uniqueItems = [];
    const seenCodes = new Set();
    for (const item of parsedItems) {
      if (!seenCodes.has(item.code)) {
        seenCodes.add(item.code);
        uniqueItems.push(item);
      } else {
        console.warn(`Duplicate code found: ${item.code}. Skipping duplicate.`);
      }
    }
    
    console.log(`Parsed ${parsedItems.length} lines. Unique codes: ${uniqueItems.length}`);

    // Get Lesson 5 ID
    const { data: lessons } = await supabase.from('lessons').select('id').eq('index', 5).single();
    if (!lessons) {
      console.error('Lesson 5 not found! Please create it first.');
      return;
    }
    const lessonId = lessons.id;

    // Delete existing lines for this lesson
    console.log('Deleting existing lines for Lesson 5...');
    const { error: deleteError } = await supabase
      .from('lines')
      .delete()
      .eq('lesson_id', lessonId);

    if (deleteError) {
      console.error('Error deleting existing lines:', deleteError.message);
      return;
    }

    // Insert new lines
    console.log('Inserting new lines...');
    // Insert in batches to avoid request size limits
    const BATCH_SIZE = 100;
    for (let i = 0; i < uniqueItems.length; i += BATCH_SIZE) {
      const batch = uniqueItems.slice(i, i + BATCH_SIZE).map(item => {
        const orderNum = parseInt(item.code.split('-')[1], 10);
        return {
          lesson_id: lessonId,
          code: item.code,
          order_num: orderNum,
          text_he: item.text_he,
          text_it: item.text_it,
          text_en: item.text_en,
          type: item.type
        };
      });

      const { error } = await supabase
        .from('lines')
        .insert(batch);
        
      if (error) {
        console.error(`Error inserting batch ${i}:`, error.message);
      } else {
        console.log(`Inserted batch ${i} - ${i + batch.length}`);
      }
    }
    
    console.log('Done!');
    
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
