import fs from 'fs';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function updateLesson7() {
  console.log('Reading dump file...');
  const dumpPath = path.join(__dirname, 'lesson7_dump.txt');
  
  try {
    const content = fs.readFileSync(dumpPath, 'utf-8');
    console.log('First 100 chars:', JSON.stringify(content.substring(0, 100)));
    const lines = content.split(/\r?\n|\r/);
    
    console.log(`Parsed ${lines.length} lines.`);
    
    for (const line of lines) {
      if (!line.trim()) continue;
      
      // Split by tab
      const parts = line.split('\t');
      
      // We expect at least ID and some content
      if (parts.length < 2) continue;
      
      const id = parts[0].trim();
      
      // Skip if ID doesn't look like a lesson ID (e.g. "7-00100")
      if (!id.match(/^7-\d{5}$/)) continue;
      
      // Determine if this is a LANG line or INFO line based on columns
      // Based on previous lessons:
      // LANG lines usually have: ID, Hebrew, Italian, English (optional)
      // INFO lines usually have: ID, Text
      
      // Let's try to detect the structure
      let hebrew = '';
      let italian = '';
      let english = '';
      let text = '';
      let type = 'INFO'; // Default to INFO
      
      // Check if it has Italian/Hebrew characteristics
      // Usually column 2 is Hebrew, Column 3 is Italian in LANG lines
      // But sometimes it varies. Let's look at the previous logic.
      
      // Logic from previous scripts:
      // If we have 3+ columns, it's likely LANG: ID, Hebrew, Italian
      // If we have 2 columns, it's likely INFO: ID, Text
      
      if (parts.length >= 3) {
        // Likely LANG
        // But we need to be careful. Sometimes INFO lines have empty columns.
        // Let's check if column 3 (Italian) contains latin characters
        const col2 = parts[1].trim();
        const col3 = parts[2].trim();
        const col4 = parts.length > 3 ? parts[3].trim() : '';
        
        if (col3 && /[a-zA-Z]/.test(col3)) {
           type = 'LANG';
           hebrew = col2;
           italian = col3;
           english = col4;
        } else {
           // Maybe INFO
           text = col2;
           // If col2 is empty but col3 has something (unlikely for INFO but possible)
           if (!text && col3) text = col3;
        }
      } else {
        // 2 columns
        text = parts[1].trim();
      }
      
      console.log(`Processing ${id}: Type=${type}`);
      
      if (type === 'LANG') {
        const { error } = await supabase
          .from('lines')
          .update({
            type: 'LANG',
            hebrew: hebrew,
            italian: italian,
            text_en: english || null, // Update English if present
            text: null // Clear text if it was previously INFO
          })
          .eq('id', id);
          
        if (error) console.error(`Error updating ${id}:`, error);
      } else {
        const { error } = await supabase
          .from('lines')
          .update({
            type: 'INFO',
            text: text,
            hebrew: null,
            italian: null,
            text_en: null
          })
          .eq('id', id);
          
        if (error) console.error(`Error updating ${id}:`, error);
      }
    }
    
    console.log('Done!');
    
  } catch (err) {
    console.error('Error reading or processing file:', err);
  }
}

updateLesson7();
