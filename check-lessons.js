import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing environment variables!');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('=== בדיקת שיעורים ===\n');
console.log('URL:', supabaseUrl);

// Check lessons
const { data: lessons, error: lessonsError } = await supabase
  .from('lessons')
  .select('id, index, title, is_published')
  .order('index');

if (lessonsError) {
  console.error('❌ שגיאה בטעינת שיעורים:', lessonsError.message);
  console.error('פרטים:', lessonsError);
} else {
  console.log('\n📚 שיעורים במערכת:');
  console.log('סה"כ שיעורים:', lessons.length);
  console.log('\nפירוט:');
  lessons.forEach(lesson => {
    const status = lesson.is_published ? '✅ פורסם' : '❌ לא פורסם';
    console.log(`${lesson.index}. ${lesson.title} - ${status}`);
  });
  
  const publishedCount = lessons.filter(l => l.is_published).length;
  console.log(`\nפורסמו: ${publishedCount}/${lessons.length}`);
  
  if (publishedCount === 0) {
    console.log('\n⚠️  אין שיעורים מפורסמים! זו הבעיה!');
  }
}

// Check users
const { data: users, error: usersError } = await supabase
  .from('users')
  .select('id, username, role')
  .eq('role', 'STUDENT');

if (usersError) {
  console.error('\n❌ שגיאה בטעינת משתמשים:', usersError.message);
} else {
  console.log('\n👥 תלמידים במערכת:', users.length);
  users.forEach(user => {
    console.log(`  - ${user.username}`);
  });
}
