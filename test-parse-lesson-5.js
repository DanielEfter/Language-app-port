import fs from 'fs';

function parseCSV(content) {
  const lines = content.split('\n').slice(1); // Skip header
  const parsedLines = [];
  
  for (let i = 0; i < Math.min(10, lines.length); i++) {
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
    
    const [code, hebrewWord, englishText, col4, col5] = cleanParts;
    
    if (!code || !code.trim()) continue;
    
    let type = 'INFO';
    let text_he = '';
    let text_en = '';
    let text_it = '';
    
    if (col5 && col5.trim()) {
      const hebrewChars = (col5.match(/[\u0590-\u05FF]/g) || []).length;
      const latinChars = (col5.match(/[A-Za-z]/g) || []).length;
      
      if (hebrewChars > latinChars) {
        type = 'INFO';
        text_he = col5.trim();
      } else {
        type = 'LANG';
        text_he = hebrewWord ? hebrewWord.trim() : '';
        text_en = englishText ? englishText.trim() : '';
        text_it = col5.trim();
      }
    } else if (col4 && col4.trim()) {
      type = 'LANG';
      text_he = hebrewWord ? hebrewWord.trim() : '';
      text_en = englishText ? englishText.trim() : '';
      text_it = col4.trim();
    } else if (hebrewWord && hebrewWord.trim()) {
      type = 'INFO';
      text_he = hebrewWord.trim();
    }
    
    console.log(`\n${code} (${type}):`);
    console.log(`  HE: ${text_he || '(empty)'}`);
    console.log(`  EN: ${text_en || '(empty)'}`);
    console.log(`  IT: ${text_it || '(empty)'}`);
  }
}

const csvContent = fs.readFileSync('Lessons-original-files/מפגש 5.csv', 'utf8');
parseCSV(csvContent);
