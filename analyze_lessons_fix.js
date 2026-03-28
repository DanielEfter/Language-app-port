import fs from 'fs';

try {
  const content = fs.readFileSync('complete_migration.sql', 'utf8');

  // Map to hold unique Lesson Num -> UUID mappings
  const lessonMap = new Map();

  // Regex to find INSERT INTO lines ... VALUES ('UUID', OrderNum, 'Code-XXXXX'...)
  // Assuming UUID is first value, OrderNum second, Code third.
  const regex = /\('([0-9a-f-]{36})',\s*\d+,\s*'(\d+)-[0-9]{5}'/g;

  let match;
  while ((match = regex.exec(content)) !== null) {
      const uuid = match[1];
      const lessonNum = parseInt(match[2]);
      if (!lessonMap.has(lessonNum)) {
          lessonMap.set(lessonNum, uuid);
      }
  }

  // Check schema for column name (index vs lesson_number)
  let colName = 'lesson_number';
  // Simple check for "index integer" in Create Table lessons
  if (content.match(/CREATE TABLE.*?lessons.*?index\s+integer/is)) {
      colName = 'index';
  }

  console.log(`Found ${lessonMap.size} lessons. Using column: ${colName}`);

  let sql = `-- Seed Lessons Data (Required for FKs)\n`;
  const sorted = Array.from(lessonMap.entries()).sort((a,b) => a[0] - b[0]);
  
  for (const [num, uuid] of sorted) {
      // Use correct columns: id, index, title, is_published
      // (No description, no is_active)
      sql += `INSERT INTO public.lessons (id, ${colName}, title, is_published) VALUES ('${uuid}', ${num}, 'Lesson ${num}', true) ON CONFLICT (id) DO NOTHING;\n`;
  }

  fs.writeFileSync('seed_lessons.sql', sql);
  console.log('Successfully generated seed_lessons.sql');

} catch(err) {
  console.error(err);
}
