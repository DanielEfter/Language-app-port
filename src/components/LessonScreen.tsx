import { useState, useEffect, useRef } from 'react';
import confetti from 'canvas-confetti';
import { ArrowRight, CheckCircle, Menu, RotateCcw, X } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import type { Lesson, Line, Progress } from '../lib/database.types';
import LineDisplay from './LineDisplay';

interface Props {
  lesson: Lesson;
  onBack: () => void;
}

export default function LessonScreen({ lesson, onBack }: Props) {
  const { user, logout } = useAuth();
  const [lines, setLines] = useState<Line[]>([]);
  const [currentLineIndex, setCurrentLineIndex] = useState(0);
  const [progress, setProgress] = useState<Progress | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCompletion, setShowCompletion] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const mainRef = useRef<HTMLDivElement>(null);

  // Restore current line index from localStorage on mount
  useEffect(() => {
    if (user) {
      const savedIndex = localStorage.getItem(`currentLine_${user.id}_${lesson.id}`);
      if (savedIndex !== null) {
        const index = parseInt(savedIndex);
        if (!isNaN(index) && index >= 0) {
          setCurrentLineIndex(index);
        }
      }
    }
  }, [user, lesson.id]);

  useEffect(() => {
    loadLessonData();

    // Subscribe to real-time changes
    const channel = supabase
      .channel(`lesson-${lesson.id}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'lines',
          filter: `lesson_id=eq.${lesson.id}`,
        },
        (payload) => {
          console.log('Real-time update received:', payload);
          loadLessonData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [lesson.id, user]); // Only reload when lesson changes

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return;
      }

      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        e.preventDefault();
        if (e.key === 'ArrowRight') {
          handlePrevious();
        } else {
          handleNext();
        }
      } else if (e.key === 'n' || e.key === 'N') {
        e.preventDefault();
        handleNext();
      } else if (e.key === 'p' || e.key === 'P') {
        e.preventDefault();
        handlePrevious();
      }
    };

    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [currentLineIndex]);

  const loadLessonData = async () => {
    if (!user) {
      setError('אין משתמש מחובר');
      setLoading(false);
      return;
    }

    try {
      setError(null);
      console.log('Loading lesson data for lesson:', lesson.id);
      
      // Load lines first without timeout
      const linesRes = await supabase
        .from('lines')
        .select('*')
        .eq('lesson_id', lesson.id)
        .order('order_num');

      console.log('Lines loaded:', linesRes.data?.length || 0, 'lines');

      if (linesRes.error) {
        console.error('Lines error:', linesRes.error);
        throw new Error('שגיאה בטעינת תוכן השיעור: ' + linesRes.error.message);
      }

      if (!linesRes.data || linesRes.data.length === 0) {
        console.warn('No lines found for lesson');
        setLines([]);
        setLoading(false);
        return;
      }

      setLines(linesRes.data);

      // Load progress in background (non-blocking)
      supabase
        .from('progress')
        .select('*')
        .eq('user_id', user.id)
        .eq('lesson_id', lesson.id)
        .maybeSingle()
        .then(({ data, error }) => {
          if (error) {
            console.error('Progress error:', error);
            return;
          }
          if (data) {
            setProgress(data);
            // Only set line index from progress if we don't have a saved position
            const savedIndex = localStorage.getItem(`currentLine_${user.id}_${lesson.id}`);
            if (savedIndex === null && linesRes.data) {
              const lastIndex = linesRes.data.findIndex(
                (l: any) => l.order_num === data.last_line_order
              );
              if (lastIndex >= 0) {
                const nextIndex = Math.min(lastIndex + 1, linesRes.data.length - 1);
                setCurrentLineIndex(nextIndex);
              }
            }
          }
        });

    } catch (err: any) {
      console.error('Error loading lesson:', err);
      setError(err.message || 'שגיאה בטעינת השיעור');
    } finally {
      setLoading(false);
    }
  };

  // Save current line index to localStorage whenever it changes
  useEffect(() => {
    if (user && lines.length > 0) {
      localStorage.setItem(`currentLine_${user.id}_${lesson.id}`, currentLineIndex.toString());
    }
    // Scroll main container to top when line changes
    if (mainRef.current) {
      mainRef.current.scrollTo(0, 0);
    }
  }, [user, lesson.id, currentLineIndex, lines.length]);

  const handleNext = async () => {
    if (!user) return;

    const nextIndex = currentLineIndex + 1;

    if (nextIndex >= lines.length) {
      await completeLesson();
      return;
    }

    setCurrentLineIndex(nextIndex);

    const currentLine = lines[currentLineIndex];
    if (currentLine) {
      if (progress) {
        await supabase
          .from('progress')
          .update({
            last_line_order: currentLine.order_num,
            updated_at: new Date().toISOString(),
          })
          .eq('id', progress.id);
      } else {
        const { data } = await supabase
          .from('progress')
          .insert({
            user_id: user.id,
            lesson_id: lesson.id,
            last_line_order: currentLine.order_num,
            is_completed: false,
          })
          .select()
          .single();
        if (data) setProgress(data);
      }
    }
  };

  const handlePrevious = () => {
    if (currentLineIndex > 0) {
      setCurrentLineIndex(currentLineIndex - 1);
    }
  };

  const completeLesson = async () => {
    if (!user) return;

    if (progress) {
      await supabase
        .from('progress')
        .update({
          is_completed: true,
          updated_at: new Date().toISOString(),
        })
        .eq('id', progress.id);
    } else {
      await supabase
        .from('progress')
        .insert({
          user_id: user.id,
          lesson_id: lesson.id,
          last_line_order: lines[lines.length - 1]?.order_num || 0,
          is_completed: true,
        });
    }

    await supabase
      .from('users')
      .update({ current_lesson_id: null })
      .eq('id', user.id);

    // Clear saved position when completing lesson
    localStorage.removeItem(`currentLine_${user.id}_${lesson.id}`);

    setShowCompletion(true);
    
    // Trigger fireworks
    const duration = 3 * 1000;
    const animationEnd = Date.now() + duration;
    const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };

    const randomInRange = (min: number, max: number) => {
      return Math.random() * (max - min) + min;
    };

    const interval: any = setInterval(function() {
      const timeLeft = animationEnd - Date.now();

      if (timeLeft <= 0) {
        return clearInterval(interval);
      }

      const particleCount = 50 * (timeLeft / duration);
      
      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 }
      });
      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 }
      });
    }, 250);
  };

  const currentLine = lines[currentLineIndex];

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center" dir="rtl">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#A3B18A] border-t-transparent rounded-full animate-spin" />
          <div className="text-xl text-[#3A4031]">טוען שיעור...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center p-4" dir="rtl">
        <div className="bg-white rounded-[2rem] shadow-sm border border-[#DAD7CD]/30 p-8 max-w-md text-center">
          <div className="w-16 h-16 bg-[#F2E9E4] rounded-full flex items-center justify-center mx-auto mb-6">
            <span className="text-3xl">⚠️</span>
          </div>
          <h2 className="text-xl font-bold text-[#3A4031] mb-4">שגיאה בטעינת השיעור</h2>
          <p className="text-gray-400 mb-6">{error}</p>
          <button
            onClick={() => {
              setError(null);
              setLoading(true);
              loadLessonData();
            }}
            className="px-6 py-3 bg-[#A3B18A] text-white rounded-xl hover:bg-[#8d9b75] transition-colors shadow-lg shadow-[#A3B18A]/20"
          >
            נסה שוב
          </button>
          <button
            onClick={onBack}
            className="block w-full mt-4 text-[#A3B18A] hover:text-[#3A4031] font-medium"
          >
            חזרה לרשימת השיעורים
          </button>
        </div>
      </div>
    );
  }

  if (lines.length === 0) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center p-4" dir="rtl">
        <div className="bg-white rounded-[2rem] shadow-sm border border-[#DAD7CD]/30 p-8 max-w-md text-center">
          <h2 className="text-xl font-bold text-[#3A4031] mb-4">השיעור ריק</h2>
          <p className="text-gray-400 mb-6">אין עדיין תוכן בשיעור זה</p>
          <button
            onClick={onBack}
            className="px-6 py-3 bg-[#A3B18A] text-white rounded-xl hover:bg-[#8d9b75] transition-colors shadow-lg shadow-[#A3B18A]/20"
          >
            חזור לרשימת השיעורים
          </button>
        </div>
      </div>
    );
  }

  if (!currentLine) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center" dir="rtl">
        <div className="text-xl text-[#3A4031]">טוען...</div>
      </div>
    );
  }

  if (showCompletion) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center p-4" dir="rtl">
        <div className="bg-white rounded-[2rem] shadow-sm border border-[#DAD7CD]/30 p-8 max-w-md text-center">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-[#A3B18A]/10 rounded-full mb-6">
            <CheckCircle className="w-12 h-12 text-[#A3B18A]" />
          </div>
          <h2 className="text-2xl font-bold text-[#3A4031] mb-4">כל הכבוד!</h2>
          <p className="text-[#3A4031] mb-2 font-medium text-lg">סיימת את שיעור {lesson.index}</p>
          <p className="text-sm text-gray-400 mb-8">
            {lines.length} שורות הושלמו בהצלחה
          </p>
          <div className="space-y-3">
            <button
              onClick={onBack}
              className="w-full bg-[#3A4031] hover:bg-[#2d3226] text-white font-medium py-3 px-4 rounded-xl transition-colors shadow-lg shadow-[#3A4031]/10"
            >
              חזרה לתפריט הראשי
            </button>
            <button
              onClick={() => {
                setShowCompletion(false);
                setCurrentLineIndex(lines.length - 1);
              }}
              className="w-full flex items-center justify-center gap-2 bg-white border-2 border-[#DAD7CD] text-[#A3B18A] hover:bg-[#F8F9F7] hover:border-[#A3B18A] font-medium py-3 px-4 rounded-xl transition-colors"
            >
              <ArrowRight className="w-4 h-4" />
              <span>חזור לשורה האחרונה</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!currentLine) {
    return (
      <div className="min-h-screen bg-[#F8F9F7] flex items-center justify-center" dir="rtl">
        <div className="text-center">
          <p className="text-gray-600 mb-4">אין שורות בשיעור זה</p>
          <button
            onClick={onBack}
            className="text-[#A3B18A] hover:text-[#3A4031] font-medium"
          >
            חזרה
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-[#F8F9F7] flex flex-col" dir="rtl">
      <header className="bg-[#F8F9F7]/80 backdrop-blur-md border-b border-[#DAD7CD]/20 z-40 flex-shrink-0 safe-top">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between gap-3 relative">
          
          {/* Info - Right Side */}
          <div className="flex flex-col sm:flex-row sm:items-center sm:gap-4 text-right">
             <h1 className="text-sm sm:text-base font-bold text-[#3A4031] leading-tight">
               {lesson.title}
             </h1>
             <div className="text-xs text-[#A3B18A] flex items-center gap-2">
               <span>שיעור {lesson.index}</span>
               <span className="hidden sm:inline">•</span>
               <span>שורה {currentLineIndex + 1} מתוך {lines.length}</span>
             </div>
          </div>

          {/* Hamburger - Leftmost */}
          <div className="relative">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="p-2 hover:bg-[#F2E9E4] rounded-full transition-colors text-[#3A4031]"
            >
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>

            {isMenuOpen && (
              <div className="absolute left-0 top-full mt-2 w-64 bg-white rounded-xl shadow-xl border border-[#DAD7CD]/30 py-3 z-50">
                <button
                  onClick={onBack}
                  className="w-full text-right px-6 py-3 text-lg text-[#3A4031] hover:bg-[#F8F9F7] hover:text-[#A3B18A] transition-colors"
                >
                  חזרה לרשימת השיעורים
                </button>
                <button
                  onClick={() => logout()}
                  className="w-full text-right px-6 py-3 text-lg text-[#E9C46A] hover:bg-[#F8F9F7] transition-colors"
                >
                  התנתק
                </button>
              </div>
            )}
          </div>

        </div>
        
        {/* Progress Bar */}
        <div className="h-1 bg-[#F8F9F7] w-full">
          <div 
            className="h-full bg-[#A3B18A] transition-all duration-300 ease-out"
            style={{ width: `${((currentLineIndex + 1) / lines.length) * 100}%` }}
          />
        </div>
      </header>

      <main 
        ref={mainRef}
        className="flex-1 flex flex-col items-center justify-start p-4 sm:p-6 md:p-8 relative overflow-hidden"
      >
        {/* Background decoration */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-[#DAD7CD]/30 rounded-full blur-[80px] -z-10" />
        <div className="absolute bottom-40 left-0 w-72 h-72 bg-[#E9C46A]/20 rounded-full blur-[100px] -z-10" />
        </div>

        <div className="w-full max-w-4xl relative z-10 h-full">
          <LineDisplay
            line={currentLine}
            onNext={handleNext}
          />
        </div>
      </main>

      <footer className="bg-[#F8F9F7] border-t border-[#DAD7CD]/20 px-4 py-4 sm:px-6 lg:px-8 z-40 flex-shrink-0 safe-bottom">
        <div className="max-w-4xl mx-auto flex items-center justify-between gap-4">
          <button
            onClick={handlePrevious}
            disabled={currentLineIndex === 0}
            className="flex items-center gap-2 px-8 py-3 bg-white border-2 border-[#DAD7CD] text-[#A3B18A] hover:bg-[#F8F9F7] hover:border-[#A3B18A] rounded-2xl disabled:opacity-40 disabled:cursor-not-allowed transition-all font-medium shadow-sm"
          >
            <ArrowRight className="w-4 h-4" />
            <span>הקודם</span>
          </button>

          <div className="text-sm font-medium text-gray-400 hidden sm:block text-center mx-auto">
            לחץ <kbd className="font-sans bg-white px-1.5 py-0.5 rounded border border-[#DAD7CD] text-[#A3B18A] mx-1">Enter</kbd> או <kbd className="font-sans bg-white px-1.5 py-0.5 rounded border border-[#DAD7CD] text-[#A3B18A] mx-1">←</kbd> להמשך
          </div>

          <button
            onClick={handleNext}
            className="flex items-center gap-2 px-8 py-3 bg-[#3A4031] text-white hover:bg-[#2d3226] rounded-2xl shadow-lg shadow-[#3A4031]/10 hover:shadow-[#3A4031]/20 transition-all transform active:scale-95 font-medium"
          >
            <span>{currentLineIndex >= lines.length - 1 ? 'סיים שיעור' : 'הבא'}</span>
            <ArrowRight className="w-4 h-4 rotate-180" />
          </button>
        </div>
      </footer>
    </div>
  );
}
