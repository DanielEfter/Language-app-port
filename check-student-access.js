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

console.log('=== בדיקת גישה לשיעורים ===\n');

// Get all students
const { data: students, error: studentsError } = await supabase
  .from('users')
  .select('*')
  .eq('role', 'STUDENT');

if (studentsError) {
  console.error('❌ שגיאה:', studentsError);
  process.exit(1);
}

console.log(`מצאתי ${students.length} תלמידים\n`);

// For each student, check their access
for (const student of students) {
  console.log(`\n🧑‍🎓 תלמיד: ${student.username}`);
  console.log(`   ID: ${student.id}`);
  
  // Get lessons with is_published = true
  const { data: lessons, error: lessonsError } = await supabase
    .from('lessons')
    .select('*')
    .eq('is_published', true)
    .order('index');
  
  if (lessonsError) {
    console.error('   ❌ שגיאה בטעינת שיעורים:', lessonsError);
    continue;
  }
  
  console.log(`   📚 שיעורים זמינים: ${lessons?.length || 0}`);
  
  // Get student's progress
  const { data: progress, error: progressError } = await supabase
    .from('progress')
    .select('*')
    .eq('user_id', student.id);
  
  if (progressError) {
    console.error('   ❌ שגיאה בטעינת התקדמות:', progressError);
    continue;
  }
  
  console.log(`   📊 רשומות התקדמות: ${progress?.length || 0}`);
  
  if (progress && progress.length > 0) {
    const completed = progress.filter(p => p.is_completed).length;
    console.log(`   ✅ שיעורים שהושלמו: ${completed}`);
    
    progress.forEach(p => {
      const lesson = lessons.find(l => l.id === p.lesson_id);
      const status = p.is_completed ? '✅' : '⏳';
      console.log(`      ${status} שיעור ${lesson?.index}: ${lesson?.title} (line ${p.last_line_order})`);
    });
  } else {
    console.log('   ⚠️  אין רשומות התקדמות');
  }
  
  // Simulate what the StudentDashboard does
  console.log('\n   🔍 סימולציה של לוגיקת הגישה:');
  
  if (!lessons || lessons.length === 0) {
    console.log('   ❌ אין שיעורים! זו הבעיה!');
    continue;
  }
  
  lessons.forEach(lesson => {
    let status = 'locked';
    
    if (lesson.index === 0) {
      status = 'available';
    } else {
      const lessonProgress = progress?.find(p => p.lesson_id === lesson.id);
      if (lessonProgress?.is_completed) {
        status = 'completed';
      } else {
        const previousLesson = lessons.find(l => l.index === lesson.index - 1);
        if (previousLesson) {
          const previousProgress = progress?.find(p => p.lesson_id === previousLesson.id);
          if (previousProgress?.is_completed) {
            status = 'available';
          }
        }
      }
    }
    
    const emoji = status === 'locked' ? '🔒' : status === 'completed' ? '✅' : '📖';
    console.log(`      ${emoji} שיעור ${lesson.index}: ${lesson.title} - ${status}`);
  });
}

console.log('\n=== סיכום ===');
console.log('אם אתה לא רואה שיעורים באפליקציה, הבעיה יכולה להיות:');
console.log('1. בעיית RLS - התלמיד לא מורשה לקרוא את הטבלאות');
console.log('2. בעיית אימות - המשתמש לא מחובר כראוי');
console.log('3. בעיית קוד - השאילתות לא עובדות');
