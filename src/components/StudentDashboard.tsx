import { useState, useEffect } from 'react';
import { LogOut, Lock, CheckCircle, BookOpen, MapPin, PlayCircle, Sparkles, BrainCircuit } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import type { Lesson, Progress } from '../lib/database.types';
import LessonScreen from './LessonScreen';

export default function StudentDashboard() {
  const { user, logout } = useAuth();
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [progress, setProgress] = useState<Progress[]>([]);
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingCity, setEditingCity] = useState(false);
  const [userCity, setUserCity] = useState('');

  // Listen for lesson updates
  useEffect(() => {
    const channel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'lessons',
        },
        () => {
          loadData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  useEffect(() => {
    if (user) {
      setUserCity(user.city || '');
    }
  }, [user]);

  // Restore selected lesson from localStorage on mount
  useEffect(() => {
    if (user && !selectedLesson && lessons.length > 0) {
      const savedLessonId = localStorage.getItem(`selectedLesson_${user.id}`);
      if (savedLessonId) {
        const lesson = lessons.find(l => l.id === savedLessonId);
        if (lesson) {
          setSelectedLesson(lesson);
        }
      }
    }
  }, [user, lessons]);

  useEffect(() => {
    if (user && !selectedLesson && lessons.length === 0) {
      loadData();
    }
  }, [user]); // Only load once when user is set

  const loadData = async () => {
    if (!user) {
      setError('לא מחובר - אנא התחבר מחדש');
      setLoading(false);
      return;
    }

    try {
      setError(null);
      console.log('Loading dashboard data...');

      const [lessonsRes, progressRes] = await Promise.all([
        supabase
          .from('lessons')
          .select('*')
          .eq('is_published', true)
          .order('index'),
        supabase
          .from('progress')
          .select('*')
          .eq('user_id', user.id),
      ]);

      console.log('Dashboard data loaded:', {
        lessons: lessonsRes.data?.length || 0,
        progress: progressRes.data?.length || 0
      });

      if (lessonsRes.error) {
        console.error('Lessons error:', lessonsRes.error);
        throw new Error('שגיאה בטעינת השיעורים: ' + lessonsRes.error.message);
      }

      if (progressRes.error) {
        console.error('Progress error:', progressRes.error);
        throw new Error('שגיאה בטעינת ההתקדמות: ' + progressRes.error.message);
      }

      if (lessonsRes.data) {
        setLessons(lessonsRes.data);
        
        if (lessonsRes.data.length === 0) {
          setError('אין שיעורים זמינים כרגע. אנא פנה למנהל.');
        }
      } else {
        setError('לא התקבלו שיעורים מהשרת');
      }
      
      if (progressRes.data) {
        setProgress(progressRes.data);
      }
    } catch (err: any) {
      console.error('Load data error:', err);
      setError(err.message || 'שגיאה בטעינת הנתונים');
    } finally {
      setLoading(false);
    }
  };

  const getLessonStatus = (lesson: Lesson): 'locked' | 'available' | 'completed' => {
    const lessonProgress = progress.find((p) => p.lesson_id === lesson.id);
    if (lessonProgress?.is_completed) return 'completed';

    if (lesson.index === 0 || (lessons.length > 0 && lessons[0].id === lesson.id)) return 'available';

    const previousLesson = lessons.find((l) => l.index === lesson.index - 1);
    if (previousLesson) {
      const previousProgress = progress.find((p) => p.lesson_id === previousLesson.id);
      if (previousProgress?.is_completed) return 'available';
    }

    return 'locked';
  };

  const completedCount = progress.filter((p) => p.is_completed).length;
  const totalLessons = lessons.length;

  // Save selected lesson to localStorage
  useEffect(() => {
    if (user && selectedLesson) {
      localStorage.setItem(`selectedLesson_${user.id}`, selectedLesson.id);
    }
  }, [user, selectedLesson]);

  if (selectedLesson) {
    return (
      <LessonScreen
        lesson={selectedLesson}
        onBack={async () => {
          setSelectedLesson(null);
          if (user) {
            localStorage.removeItem(`selectedLesson_${user.id}`);
          }
          loadData();
        }}
      />
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center" dir="rtl">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
          <div className="text-lg font-medium text-slate-600">טוען נתונים...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4" dir="rtl">
        <div className="bg-white rounded-3xl shadow-xl p-8 max-w-md w-full text-center border border-slate-100">
          <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
            <span className="text-3xl">⚠️</span>
          </div>
          <h2 className="text-2xl font-bold text-slate-900 mb-2">שגיאה בטעינת הנתונים</h2>
          <p className="text-slate-500 mb-8">{error}</p>
          <div className="space-y-3">
            <button
              onClick={() => {
                setError(null);
                setLoading(true);
                loadData();
              }}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3.5 px-6 rounded-xl transition-all shadow-lg shadow-blue-600/20"
            >
              נסה שוב
            </button>
            <button
              onClick={() => {
                if (confirm('האם אתה בטוח שברצונך לצאת?')) {
                  logout();
                }
              }}
              className="w-full text-slate-500 hover:text-slate-700 font-medium py-2"
            >
              חזרה להתחברות
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8F9F7] font-sans text-[#3A4031] relative overflow-x-hidden" dir="rtl">
      {/* Background Elements */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute top-0 right-0 w-64 h-64 bg-[#DAD7CD]/30 rounded-full blur-[80px] -z-10" />
        <div className="absolute bottom-40 left-0 w-72 h-72 bg-[#E9C46A]/20 rounded-full blur-[100px] -z-10" />
      </div>

      <header className="sticky top-0 z-50 bg-[#F8F9F7]/80 backdrop-blur-xl border-b border-[#DAD7CD]/20 shadow-sm safe-top">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <img src="/logo.png" alt="Logo" className="w-16 h-16 object-contain" />
            <div>
              <h1 className="text-lg font-bold text-[#3A4031] tracking-tight">ספרדית למתחילים</h1>
              <p className="text-xs font-medium text-gray-400">{lessons.length} שיעורים • רמת מתחילים</p>
            </div>
          </div>
          <div className="flex items-center gap-3 sm:gap-6">
            <div className="flex items-center gap-3 pl-2 border-l border-[#DAD7CD]/30">
              <div className="text-right hidden sm:block">
                <div className="text-sm font-bold text-[#3A4031]">{user?.username}</div>
                <div className="flex items-center justify-end gap-1 text-xs text-gray-400">
                  {editingCity ? (
                    <input
                      type="text"
                      value={userCity}
                      onChange={(e) => setUserCity(e.target.value)}
                      onBlur={async () => {
                        if (user) {
                          await (supabase.from('users') as any)
                            .update({ city: userCity })
                            .eq('id', user.id);
                        }
                        setEditingCity(false);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.currentTarget.blur();
                        } else if (e.key === 'Escape') {
                          setUserCity(user?.city || '');
                          setEditingCity(false);
                        }
                      }}
                      autoFocus
                      className="text-xs px-2 py-1 border border-[#DAD7CD] rounded-md w-24 focus:outline-none focus:ring-2 focus:ring-[#A3B18A]/20 bg-white"
                      placeholder="עיר"
                    />
                  ) : (
                    <>
                      <MapPin className="w-3 h-3" />
                      <span
                        onClick={() => setEditingCity(true)}
                        className="cursor-pointer hover:text-[#A3B18A] transition-colors border-b border-transparent hover:border-[#DAD7CD]"
                      >
                        {user?.city || 'הוסף עיר'}
                      </span>
                    </>
                  )}
                </div>
              </div>
              <div className="w-10 h-10 rounded-full bg-[#F2E9E4] flex items-center justify-center text-[#3A4031] font-bold shadow-sm border border-[#DAD7CD]/50">
                {user?.username?.[0]?.toUpperCase()}
              </div>
            </div>
            <button
              onClick={() => {
                if (confirm('האם אתה בטוח שברצונך לצאת מהאפליקציה?')) {
                  logout();
                }
              }}
              className="p-2.5 hover:bg-[#F2E9E4] text-[#DAD7CD] hover:text-[#3A4031] rounded-xl transition-all duration-200 hover:shadow-md"
              title="יציאה"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 relative z-10 safe-bottom">
        <div className="mb-12 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div>
            <h2 className="text-3xl sm:text-4xl font-light text-[#3A4031] mb-2 tracking-tight">
              {(() => {
                const hour = new Date().getHours();
                const minutes = new Date().getMinutes();
                const totalMinutes = hour * 60 + minutes;
                // 05:00 (300) - 11:30 (690) → בוקר טוב
                // 11:31 (691) - 16:00 (960) → צהריים טובים
                // 16:01 (961) - 04:59 (299) → ערב טוב
                if (totalMinutes >= 300 && totalMinutes <= 690) {
                  return 'בוקר טוב';
                } else if (totalMinutes >= 691 && totalMinutes <= 960) {
                  return 'צהריים טובים';
                } else {
                  return 'ערב טוב';
                }
              })()}, <span className="font-semibold">{user?.username}</span>
            </h2>
            <p className="text-[#A3B18A] text-lg font-medium">
              מוכן להמשיך במסע הספרדי שלך?
            </p>
          </div>
          
          {/* Quick Stats */}
          <div className="flex gap-4">
            <div className="bg-white px-5 py-3 rounded-2xl border border-[#DAD7CD]/40 shadow-sm">
              <div className="text-xs text-[#A3B18A] font-bold uppercase tracking-wider mb-1">הושלמו</div>
              <div className="text-2xl font-black text-[#3A4031] flex items-baseline gap-1">
                {completedCount}
                <span className="text-sm font-medium text-[#DAD7CD]">/ {totalLessons}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-8">
          {/* Main Content - Lessons Grid */}
          <div className="lg:col-span-12 space-y-8">
            {completedCount === 0 && (
              <div className="mx-6 p-6 rounded-[2.5rem] bg-white border border-[#DAD7CD]/40 shadow-[0_15px_40px_-15px_rgba(163,177,138,0.2)] relative overflow-hidden">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2.5 bg-[#F8F9F7] rounded-2xl text-[#A3B18A]">
                    <BrainCircuit size={20} />
                  </div>
                  <span className="text-xs font-bold text-[#A3B18A] tracking-wide">המדריך החכם שלך</span>
                </div>
                <h3 className="text-3xl font-light text-[#3A4031] mb-2">התחל את המסע שלך</h3>
                <p className="text-lg text-[#3A4031] leading-relaxed mb-6">
                  "היום זה יום מעולה לתרגל <span className="text-[#A3B18A] font-bold">ספרדית</span>. בוא נתחיל מהבסיס!"
                </p>
                <button 
                  onClick={() => {
                    const firstLesson = lessons[0];
                    if (firstLesson) setSelectedLesson(firstLesson);
                  }}
                  className="w-full py-4 bg-[#A3B18A] text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-[#A3B18A]/20 hover:bg-[#8d9b75] transition-all"
                >
                  <Sparkles size={18} />
                  התחל שיעור ראשון
                </button>
              </div>
            )}
            
            <div>
              <div className="flex items-center justify-between mb-6 px-2">
                <h3 className="text-xl font-medium text-[#3A4031] flex items-center gap-2">
                  <BookOpen className="w-5 h-5 text-[#A3B18A]" />
                  השיעורים שלי
                </h3>
              </div>


              <div className="flex flex-wrap justify-center gap-1.5 sm:gap-5 px-1 sm:px-4">
                {lessons.map((lesson) => {
                  const status = getLessonStatus(lesson);
                  const isLocked = status === 'locked';
                  const isCompleted = status === 'completed';

                  return (
                    <button
                      key={lesson.id}
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();

                        if (isLocked) {
                          return;
                        }

                        // Open lesson immediately
                        setSelectedLesson(lesson);

                        // Update current lesson in background
                        if (user) {
                          (supabase.from('users') as any)
                            .update({ current_lesson_id: lesson.id })
                            .eq('id', user.id)
                            .then(({ error }: any) => {
                              if (error) console.error('Error updating current lesson:', error);
                            });
                        }
                      }}
                      disabled={isLocked}
                      className={`
                        relative p-2 sm:p-5 rounded-xl sm:rounded-[2rem] text-right transition-all duration-300 group overflow-hidden w-[29%] sm:w-[320px] lg:w-[360px] cursor-pointer
                        ${isLocked
                          ? 'bg-white border-2 border-[#DAD7CD] text-[#DAD7CD] cursor-not-allowed opacity-80'
                          : isCompleted
                          ? 'bg-white border border-[#A3B18A] shadow-sm hover:shadow-md'
                          : 'bg-white border border-[#DAD7CD]/30 shadow-sm hover:shadow-md hover:-translate-y-1'
                        }
                      `}
                    >

                      <div className="flex flex-col items-center text-center sm:flex-row sm:text-right sm:items-start gap-1 sm:gap-4 mb-1 sm:mb-4 w-full">
                        <div className={`
                          w-8 h-8 sm:w-14 sm:h-14 rounded-lg sm:rounded-2xl flex items-center justify-center transition-all duration-300 shrink-0
                          ${isLocked 
                            ? 'bg-white border-2 border-[#DAD7CD] text-[#DAD7CD]' 
                            : isCompleted 
                            ? 'bg-[#A3B18A] text-white shadow-lg shadow-[#A3B18A]/30' 
                            : 'bg-white border-4 border-[#A3B18A] text-[#A3B18A]'
                          }
                        `}>
                          {isLocked ? (
                            <Lock className="w-3.5 h-3.5 sm:w-6 sm:h-6" />
                          ) : isCompleted ? (
                            <CheckCircle className="w-3.5 h-3.5 sm:w-6 sm:h-6" />
                          ) : (
                            <PlayCircle className="w-3.5 h-3.5 sm:w-6 sm:h-6 sm:ml-0.5" />
                          )}
                        </div>
                        
                        <div className="flex-1 min-w-0 w-full">
                           <span className="text-[7px] sm:text-[10px] font-black text-[#A3B18A] uppercase tracking-widest block mb-0.5 sm:mb-1">
                            שיעור {String(lesson.index).padStart(2, '0')}
                          </span>
                          <h3
                            className={`text-xs sm:text-lg font-bold mb-0.5 sm:mb-1 line-clamp-2 sm:line-clamp-1 transition-colors leading-tight ${
                              isLocked ? 'text-[#DAD7CD]' : 'text-[#3A4031]'
                            }`}
                          >
                            {lesson.title}
                          </h3>
                          {lesson.description && (
                            <p className={`hidden sm:block text-sm line-clamp-2 leading-relaxed ${isLocked ? 'text-[#DAD7CD]' : 'text-gray-400'}`}>
                              {lesson.description}
                            </p>
                          )}
                        </div>
                      </div>
                      
                       {/* Progress Bar for valid states */}
                        {!isLocked && (
                          <div className="mt-1 sm:mt-2 h-1 sm:h-1.5 w-full bg-[#F8F9F7] rounded-full overflow-hidden">
                            <div 
                              className={`h-full rounded-full transition-all duration-500 touch-progress-indicator ${isCompleted ? 'bg-[#A3B18A] w-full' : 'bg-[#E9C46A] w-0 group-hover:w-full'}`} 
                            />
                          </div>
                        )}
                    </button>
                  );
                })}
              </div>

              {lessons.length === 0 && (
                <div className="text-center py-20 bg-white/50 backdrop-blur-sm rounded-[2rem] border border-dashed border-[#DAD7CD]">
                  <div className="bg-[#F8F9F7] w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                    <BookOpen className="w-10 h-10 text-[#DAD7CD]" />
                  </div>
                  <h3 className="text-lg font-bold text-[#3A4031] mb-2">אין שיעורים זמינים</h3>
                  <p className="text-gray-400">נראה שעדיין לא פורסמו שיעורים בקורס זה.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}