import fs from 'fs';

const csvContent = fs.readFileSync('Lessons-original-files/מפגש 5.csv', 'utf8');
const lines = csvContent.split('\n');

// Check first 10 lines
for (let i = 0; i < 10 && i < lines.length; i++) {
  console.log(`Line ${i}: ${lines[i]}`);
  
  // Parse this line
  const line = lines[i].trim();
  if (!line) continue;
  
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
  
  const cleanParts = parts.map(p => p.replace(/^"(.*)"$/, '$1').replace(/""/g, '"'));
  console.log(`  Parsed (${cleanParts.length} parts):`, cleanParts);
  console.log('');
}
