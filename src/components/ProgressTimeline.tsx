import { CheckCircle, Circle, Lock } from 'lucide-react';
import type { Lesson, Progress } from '../lib/database.types';

interface Props {
  lessons: Lesson[];
  progress: Progress[];
}

export default function ProgressTimeline({ lessons, progress }: Props) {
  const getLessonStatus = (lesson: Lesson, index: number): 'locked' | 'available' | 'completed' => {
    if (index === 0) return progress.find(p => p.lesson_id === lesson.id)?.is_completed ? 'completed' : 'available';

    const lessonProgress = progress.find(p => p.lesson_id === lesson.id);
    if (lessonProgress?.is_completed) return 'completed';

    const previousLesson = lessons[index - 1];
    if (previousLesson) {
      const previousProgress = progress.find(p => p.lesson_id === previousLesson.id);
      if (previousProgress?.is_completed) return 'available';
    }

    return 'locked';
  };

  const completedCount = progress.filter(p => p.is_completed).length;
  const totalLessons = lessons.length;

  return (
    <div className="bg-white rounded-[2rem] shadow-sm p-8 border border-[#DAD7CD]/30">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-xl font-medium text-[#3A4031]">מסלול הלמידה שלך</h2>
          <p className="text-sm text-[#A3B18A] mt-1">התקדמות בקורס</p>
        </div>
        <div className="flex items-center gap-2 bg-[#F8F9F7] px-4 py-2 rounded-full border border-[#DAD7CD]/30 shadow-sm">
          <div className="w-2 h-2 rounded-full bg-[#A3B18A] animate-pulse"></div>
          <span className="text-sm font-bold text-[#3A4031]">
            {completedCount} / {totalLessons} שיעורים
          </span>
        </div>
      </div>

      <div className="relative pr-2">
        <div className="absolute right-[19px] top-0 bottom-0 w-0.5 bg-dashed bg-[#DAD7CD]/40" />

        <div className="space-y-8">
          {lessons.map((lesson, index) => {
            const status = getLessonStatus(lesson, index);
            const isLocked = status === 'locked';
            const isCompleted = status === 'completed';
            const isAvailable = status === 'available';

            return (
              <div key={lesson.id} className="relative flex items-start gap-6 group">
                <div className={`
                  relative z-10 flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center
                  ${isCompleted ? 'bg-[#A3B18A] text-white shadow-lg shadow-[#A3B18A]/30' : isAvailable ? 'bg-white border-4 border-[#A3B18A] text-[#A3B18A] scale-110' : 'bg-white border-2 border-[#DAD7CD] text-[#DAD7CD]'}
                  transition-all duration-300
                `}>
                  {isLocked ? (
                    <Lock className="w-4 h-4" />
                  ) : isCompleted ? (
                    <CheckCircle className="w-5 h-5" />
                  ) : (
                    <Circle className="w-5 h-5" />
                  )}
                </div>

                <div className={`
                  flex-1 p-4 rounded-2xl transition-all duration-300
                  ${isAvailable ? 'bg-white shadow-md border border-[#A3B18A]/30 transform translate-x-[-4px]' : 'hover:bg-white/50'}
                  ${isLocked ? 'opacity-60 grayscale' : ''}
                `}>
                  <div className="flex items-center gap-3 mb-2">
                    <span className={`
                      text-xs font-bold uppercase tracking-wider
                      ${isCompleted ? 'text-[#3A4031]' : isAvailable ? 'text-[#A3B18A]' : 'text-[#DAD7CD]'}
                    `}>
                      שיעור {String(lesson.index).padStart(2, '0')}
                    </span>
                    {isCompleted && (
                      <span className="text-[10px] bg-[#A3B18A]/10 text-[#A3B18A] px-2 py-0.5 rounded-full font-bold">
                        הושלם
                      </span>
                    )}
                    {isAvailable && !isCompleted && (
                      <span className="text-[10px] bg-[#F2E9E4] text-[#3A4031] px-2 py-0.5 rounded-full font-bold animate-pulse">
                        זמין כעת
                      </span>
                    )}
                  </div>
                  <h3 className={`
                    font-bold text-lg mb-1
                    ${isLocked ? 'text-[#DAD7CD]' : 'text-[#3A4031]'}
                  `}>
                    {lesson.title}
                  </h3>
                  {lesson.description && (
                    <p className={`
                      text-sm leading-relaxed
                      ${isLocked ? 'text-slate-400' : 'text-slate-600'}
                    `}>
                      {lesson.description}
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
