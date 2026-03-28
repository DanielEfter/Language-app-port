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

async function main() {
  console.log('Reading dump file...');
  const dumpPath = path.join(__dirname, 'lesson8_dump.txt');
  
  try {
    const content = fs.readFileSync(dumpPath, 'utf-8');
    if (!content.trim()) {
      console.log('File is empty. Please paste the content into lesson8_dump.txt');
      return;
    }
    
    const lines = content.split(/\r?\n|\r/).filter(l => l.trim().length > 0);
    const parsedItems = [];

    for (const line of lines) {
      // Split by tab
      const parts = line.split('\t').map(p => p.trim());
      
      // Expecting at least the code in the first column
      let code = parts[0];
      
      // Normalize code (remove spaces, ensure format 8-XXXXX)
      code = code.replace(/\s+/g, '');
      
      if (!code.startsWith('8-')) {
        // Skip lines that don't look like codes (headers, empty lines)
        continue;
      }

      let he = parts[1] || '';
      let en = parts[2] || '';
      let it = parts[3] || '';

      // Logic to handle misplaced Hebrew in Italian column (common in copy-paste from RTL tables)
      if (hasHebrew(it) && !hasHebrew(he)) {
        if (he) he += ' ' + it;
        else he = it;
        it = ''; 
      }

      // Determine type
      let type = 'INFO';
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

    console.log(`Parsed ${parsedItems.length} lines.`);

    // Get Lesson 8 ID
    const { data: lessons } = await supabase.from('lessons').select('id').eq('index', 8).single();
    if (!lessons) {
      console.error('Lesson 8 not found! Please create it first.');
      return;
    }
    const lessonId = lessons.id;

    // Update DB
    for (const item of parsedItems) {
      console.log(`Processing ${item.code}: Type=${item.type}`);

      // Check if line exists
      const { data: existing } = await supabase
        .from('lines')
        .select('id')
        .eq('lesson_id', lessonId)
        .eq('code', item.code)
        .maybeSingle();

      const orderNum = parseInt(item.code.split('-')[1], 10);

      const lineData = {
        lesson_id: lessonId,
        code: item.code,
        order_num: orderNum,
        text_he: item.text_he,
        text_it: item.text_it,
        text_en: item.text_en,
        type: item.type
      };

      if (existing) {
        const { error } = await supabase
          .from('lines')
          .update(lineData)
          .eq('id', existing.id);
        
        if (error) console.error(`Error updating ${item.code}:`, error.message);
      } else {
        const { error } = await supabase
          .from('lines')
          .insert(lineData);
          
        if (error) console.error(`Error inserting ${item.code}:`, error.message);
      }
    }
    console.log('Done!');
    
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
