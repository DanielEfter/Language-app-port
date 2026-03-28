import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const lessonNum = process.argv[2];
const csvPath = process.argv[3];

if (!lessonNum || !csvPath) {
  console.error('Usage: node generate_migration.js <lesson_num> <csv_path>');
  process.exit(1);
}

const fullCsvPath = path.resolve(process.cwd(), csvPath);
console.log(`Reading CSV from: ${fullCsvPath}`);

const csvContent = fs.readFileSync(fullCsvPath, 'utf-8');
const lines = csvContent.split('\n').filter(l => l.trim());

// Simple CSV parser that handles quotes
function parseCSVLine(text) {
  const result = [];
  let cell = '';
  let inQuotes = false;
  
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(cell.trim());
      cell = '';
    } else {
      cell += char;
    }
  }
  result.push(cell.trim());
  return result;
}

// Helper to check for Hebrew characters
const hasHebrew = (str) => /[\u0590-\u05FF]/.test(str);

const sqlValues = [];
let orderNum = 1;

// Skip header
const dataLines = lines.slice(1);

for (const line of dataLines) {
  let cols = parseCSVLine(line);

  // Fix for unquoted commas in Hebrew or Notes fields
  while (cols.length > 5) {
    // Check where the split likely happened
    // If the second to last column contains Hebrew, it's likely part of the Notes (split in Notes)
    // Otherwise, we assume the split is in the Hebrew field (index 1)
    
    const secondToLast = cols[cols.length - 2];
    
    if (hasHebrew(secondToLast)) {
      // Likely split in Notes
      // Merge last two columns
      const last = cols.pop();
      const secondLast = cols.pop();
      cols.push(secondLast + ',' + last);
    } else {
      // Likely split in Hebrew (index 1)
      // Merge index 1 and 2
      const part1 = cols[1];
      const part2 = cols[2];
      cols.splice(1, 2, part1 + ',' + part2);
    }
  }

  // ID, Hebrew, English, Italian, Notes
  // Note: CSV columns are 0-indexed
  const code = cols[0];
  const hebrew = cols[1];
  // const english = cols[2]; // Ignored
  const italian = cols[3];
  const notes = cols[4];
  
  let text_he = hebrew;
  let text_it = italian;
  let type = 'LANG';
  
  if (!text_it) {
    type = 'INFO';
    text_he = hebrew || notes; // Fallback to notes if hebrew is empty
  }
  
  // Escape single quotes for SQL
  const escape = (str) => str ? str.replace(/'/g, "''") : '';
  
  // (order_num, code, text_he, text_it, type)
  sqlValues.push(`(${orderNum}, '${escape(code)}', '${escape(text_he)}', '${escape(text_it)}', '${type}')`);
  orderNum++;
}

// Generate timestamp for migration filename
// Add a small delay or random part to ensure uniqueness if running multiple times quickly
const now = new Date();
const timestamp = now.toISOString().replace(/[-:T.]/g, '').slice(0, 14);
const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
const migrationName = `${timestamp}${random}_update_lesson_${lessonNum}_content.sql`;
const migrationPath = path.join('supabase/migrations', migrationName);

const sqlContent = `/*
  # Update Lesson ${lessonNum} Content
*/

DO $$
DECLARE
  l_id uuid;
BEGIN
  -- Find or create lesson
  SELECT id INTO l_id FROM lessons WHERE index = ${lessonNum};
  
  IF l_id IS NULL THEN
    INSERT INTO lessons (index, title, is_published) 
    VALUES (${lessonNum}, 'Lesson ${lessonNum}', true) 
    RETURNING id INTO l_id;
  END IF;

  -- Delete existing lines
  DELETE FROM lines WHERE lesson_id = l_id;

  -- Insert new lines
  INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type)
  SELECT l_id, v.order_num, v.code, v.text_he, v.text_it, v.type
  FROM (VALUES
    ${sqlValues.join(',\n    ')}
  ) AS v(order_num, code, text_he, text_it, type);

END $$;
`;

fs.writeFileSync(migrationPath, sqlContent);
console.log(`Created migration: ${migrationPath}`);
