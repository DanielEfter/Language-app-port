import { useState, useEffect } from 'react';
import { Users, BookOpen, Trophy, TrendingUp, Clock, Target, ChevronDown, ChevronUp } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { User, Lesson, Progress } from '../../lib/database.types';

interface StudentProgress {
  user: User;
  currentLesson: Lesson | null;
  completedLessons: number;
  totalProgress: number;
  lastActivity: string | null;
  speechAttempts: number;
  averageSimilarity: number;
}

export default function ProgressTracking() {
  const [stats, setStats] = useState<any>(null);
  const [studentsProgress, setStudentsProgress] = useState<StudentProgress[]>([]);
  const [expandedStudent, setExpandedStudent] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    setLoading(true);
    await Promise.all([loadStats(), loadStudentsProgress()]);
    setLoading(false);
  };

  const loadStats = async () => {
    const [usersRes, lessonsRes, progressRes, speechRes] = await Promise.all([
      supabase.from('users').select('id, role').eq('role', 'STUDENT'),
      supabase.from('lessons').select('id').eq('is_published', true),
      supabase.from('progress').select('*'),
      supabase.from('speech_attempts').select('similarity_score'),
    ]);

    const totalStudents = usersRes.data?.length || 0;
    const totalLessons = lessonsRes.data?.length || 0;
    const allProgress = progressRes.data || [];
    const completed = allProgress.filter(p => p.is_completed).length;
    const activeStudents = new Set(allProgress.map(p => p.user_id)).size;

    const speechAttempts = speechRes.data || [];
    const avgSimilarity = speechAttempts.length > 0
      ? speechAttempts.reduce((sum, a) => sum + (Number(a.similarity_score) || 0), 0) / speechAttempts.length
      : 0;

    const completionRate = totalStudents > 0 && totalLessons > 0
      ? (completed / (totalStudents * totalLessons)) * 100
      : 0;

    setStats({
      totalStudents,
      totalLessons,
      completedLessons: completed,
      activeStudents,
      completionRate: Math.round(completionRate),
      totalSpeechAttempts: speechAttempts.length,
      averageSimilarity: Math.round(avgSimilarity * 100),
    });
  };

  const loadStudentsProgress = async () => {
    const { data: students } = await supabase
      .from('users')
      .select('*')
      .eq('role', 'STUDENT')
      .order('username');

    if (!students) return;

    const progressData = await Promise.all(
      students.map(async (student) => {
        const [progressRes, lessonsRes, speechRes, currentLessonRes] = await Promise.all([
          supabase
            .from('progress')
            .select('*, lessons(*)')
            .eq('user_id', student.id),
          supabase
            .from('lessons')
            .select('id')
            .eq('is_published', true),
          supabase
            .from('speech_attempts')
            .select('similarity_score, created_at')
            .eq('user_id', student.id)
            .order('created_at', { ascending: false })
            .limit(1),
          student.current_lesson_id
            ? supabase
                .from('lessons')
                .select('*')
                .eq('id', student.current_lesson_id)
                .maybeSingle()
            : Promise.resolve({ data: null }),
        ]);

        const allProgress = progressRes.data || [];
        const completedCount = allProgress.filter(p => p.is_completed).length;
        const totalLessons = lessonsRes.data?.length || 0;
        const progressPercent = totalLessons > 0 ? (completedCount / totalLessons) * 100 : 0;

        const lastActivity = allProgress.length > 0
          ? allProgress.sort((a, b) =>
              new Date(b.updated_at || 0).getTime() - new Date(a.updated_at || 0).getTime()
            )[0].updated_at
          : null;

        const speechAttempts = await supabase
          .from('speech_attempts')
          .select('similarity_score')
          .eq('user_id', student.id);

        const avgSimilarity = speechAttempts.data && speechAttempts.data.length > 0
          ? speechAttempts.data.reduce((sum, a) => sum + (Number(a.similarity_score) || 0), 0) / speechAttempts.data.length
          : 0;

        return {
          user: student,
          currentLesson: currentLessonRes.data,
          completedLessons: completedCount,
          totalProgress: Math.round(progressPercent),
          lastActivity,
          speechAttempts: speechAttempts.data?.length || 0,
          averageSimilarity: Math.round(avgSimilarity * 100),
        };
      })
    );

    setStudentsProgress(progressData.sort((a, b) => b.totalProgress - a.totalProgress));
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'אף פעם';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'היום';
    if (diffDays === 1) return 'אתמול';
    if (diffDays < 7) return `לפני ${diffDays} ימים`;
    if (diffDays < 30) return `לפני ${Math.floor(diffDays / 7)} שבועות`;
    return date.toLocaleDateString('he-IL');
  };

  if (loading) {
    return <div className="text-center py-8">טוען נתונים...</div>;
  }

  if (!stats) {
    return <div className="text-center py-8">אין נתונים זמינים</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900">דשבורד אנליטיקה</h2>
        <button
          onClick={loadAllData}
          className="text-sm text-blue-600 hover:text-blue-700"
        >
          רענן נתונים
        </button>
      </div>

      {/* סטטיסטיקות כלליות */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200 rounded-xl p-5">
          <div className="flex items-center justify-between mb-3">
            <Users className="w-8 h-8 text-blue-600" />
            <div className="text-xs text-blue-600 font-medium">סך תלמידים</div>
          </div>
          <div className="text-3xl font-bold text-blue-900">{stats.totalStudents}</div>
          <div className="text-sm text-blue-700 mt-1">{stats.activeStudents} פעילים</div>
        </div>

        <div className="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-xl p-5">
          <div className="flex items-center justify-between mb-3">
            <BookOpen className="w-8 h-8 text-green-600" />
            <div className="text-xs text-green-600 font-medium">שיעורים מפורסמים</div>
          </div>
          <div className="text-3xl font-bold text-green-900">{stats.totalLessons}</div>
          <div className="text-sm text-green-700 mt-1">{stats.completedLessons} הושלמו</div>
        </div>

        <div className="bg-gradient-to-br from-purple-50 to-purple-100 border border-purple-200 rounded-xl p-5">
          <div className="flex items-center justify-between mb-3">
            <Target className="w-8 h-8 text-purple-600" />
            <div className="text-xs text-purple-600 font-medium">אחוז השלמה</div>
          </div>
          <div className="text-3xl font-bold text-purple-900">{stats.completionRate}%</div>
          <div className="text-sm text-purple-700 mt-1">ממוצע כללי</div>
        </div>

        <div className="bg-gradient-to-br from-orange-50 to-orange-100 border border-orange-200 rounded-xl p-5">
          <div className="flex items-center justify-between mb-3">
            <TrendingUp className="w-8 h-8 text-orange-600" />
            <div className="text-xs text-orange-600 font-medium">דיוק הגייה</div>
          </div>
          <div className="text-3xl font-bold text-orange-900">{stats.averageSimilarity}%</div>
          <div className="text-sm text-orange-700 mt-1">{stats.totalSpeechAttempts} ניסיונות</div>
        </div>
      </div>

      {/* טבלת התקדמות תלמידים */}
      <div className="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
          <h3 className="text-base font-semibold text-gray-900">התקדמות תלמידים</h3>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">תלמיד</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">שיעור נוכחי</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">שיעורים שהושלמו</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">אחוז התקדמות</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">ניסיונות הגייה</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">דיוק ממוצע</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">פעילות אחרונה</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {studentsProgress.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-8 text-center text-gray-500">
                    אין תלמידים במערכת
                  </td>
                </tr>
              ) : (
                studentsProgress.map((student) => (
                  <tr key={student.user.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-sm font-semibold text-blue-600">
                            {student.user.username.charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium text-gray-900">{student.user.username}</div>
                          <div className={`text-xs ${student.user.is_active ? 'text-green-600' : 'text-red-600'}`}>
                            {student.user.is_active ? 'פעיל' : 'לא פעיל'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {student.currentLesson ? student.currentLesson.title : 'אין שיעור פעיל'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">
                        {student.completedLessons} / {stats.totalLessons}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                          <div
                            className={`h-full transition-all ${
                              student.totalProgress >= 80 ? 'bg-green-500' :
                              student.totalProgress >= 50 ? 'bg-blue-500' :
                              student.totalProgress >= 20 ? 'bg-yellow-500' : 'bg-red-500'
                            }`}
                            style={{ width: `${student.totalProgress}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-700 w-12">
                          {student.totalProgress}%
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{student.speechAttempts}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className={`text-sm font-medium ${
                        student.averageSimilarity >= 80 ? 'text-green-600' :
                        student.averageSimilarity >= 60 ? 'text-yellow-600' : 'text-red-600'
                      }`}>
                        {student.speechAttempts > 0 ? `${student.averageSimilarity}%` : '-'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1 text-sm text-gray-600">
                        <Clock className="w-3 h-3" />
                        <span>{formatDate(student.lastActivity)}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => setExpandedStudent(
                          expandedStudent === student.user.id ? null : student.user.id
                        )}
                        className="text-gray-400 hover:text-gray-600"
                      >
                        {expandedStudent === student.user.id ? (
                          <ChevronUp className="w-5 h-5" />
                        ) : (
                          <ChevronDown className="w-5 h-5" />
                        )}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* סיכום מהיר */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white border border-gray-200 rounded-xl p-5">
          <div className="flex items-center gap-3 mb-2">
            <Trophy className="w-6 h-6 text-yellow-500" />
            <h4 className="font-semibold text-gray-900">תלמיד מצטיין</h4>
          </div>
          {studentsProgress[0] ? (
            <div>
              <div className="text-lg font-bold text-gray-900">{studentsProgress[0].user.username}</div>
              <div className="text-sm text-gray-600">{studentsProgress[0].totalProgress}% התקדמות</div>
            </div>
          ) : (
            <div className="text-sm text-gray-500">אין נתונים</div>
          )}
        </div>

        <div className="bg-white border border-gray-200 rounded-xl p-5">
          <div className="flex items-center gap-3 mb-2">
            <TrendingUp className="w-6 h-6 text-green-500" />
            <h4 className="font-semibold text-gray-900">ממוצע השלמה</h4>
          </div>
          <div className="text-2xl font-bold text-gray-900">{stats.completionRate}%</div>
          <div className="text-sm text-gray-600">מכלל התלמידים</div>
        </div>

        <div className="bg-white border border-gray-200 rounded-xl p-5">
          <div className="flex items-center gap-3 mb-2">
            <Target className="w-6 h-6 text-blue-500" />
            <h4 className="font-semibold text-gray-900">יעד שבועי</h4>
          </div>
          <div className="text-2xl font-bold text-gray-900">
            {Math.round((stats.completedLessons / 7))}
          </div>
          <div className="text-sm text-gray-600">שיעורים ממוצע לתלמיד</div>
        </div>
      </div>
    </div>
  );
}
