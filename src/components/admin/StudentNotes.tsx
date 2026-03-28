import { useState, useEffect } from 'react';
import { MessageSquare, User, BookOpen, Calendar } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Note {
  id: string;
  content: string;
  created_at: string;
  user_id: string;
  line_id: string;
  user: {
    username: string;
  };
  line: {
    id: string;
    order_num: number;
    lesson_id: string;
    lesson: {
      id: string;
      index: number;
      title: string;
    };
  };
}

export default function StudentNotes() {
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | number>('all');
  const [availableLessons, setAvailableLessons] = useState<number[]>([]);
  const [lineRanks, setLineRanks] = useState<Record<string, number>>({});

  useEffect(() => {
    loadNotes();
  }, []);

  const loadNotes = async () => {
    setLoading(true);

    const { data: notesData, error } = await supabase
      .from('notes')
      .select(`
        id,
        content,
        created_at,
        user_id,
        line_id,
        user:users!notes_user_id_fkey(username),
        line:lines!notes_line_id_fkey(
          id,
          order_num,
          lesson_id,
          lesson:lessons!lines_lesson_id_fkey(id, index, title)
        )
      `)
      .eq('share_with_admin', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading notes:', error);
    } else if (notesData) {
      setNotes(notesData as any);

      const lessons = [...new Set(notesData.map((n: any) => n.line?.lesson?.index).filter(Boolean))];
      setAvailableLessons(lessons.sort((a, b) => a - b));

      // Calculate real line numbers (ranks)
      const lessonIds = [...new Set(notesData.map((n: any) => n.line?.lesson_id).filter(Boolean))];
      
      if (lessonIds.length > 0) {
        const { data: linesData } = await supabase
          .from('lines')
          .select('id, lesson_id')
          .in('lesson_id', lessonIds)
          .order('order_num', { ascending: true });
          
        if (linesData) {
           const ranks: Record<string, number> = {};
           const linesByLesson: Record<string, string[]> = {};
           
           linesData.forEach((l: any) => {
             if (!linesByLesson[l.lesson_id]) linesByLesson[l.lesson_id] = [];
             linesByLesson[l.lesson_id].push(l.id);
           });

           Object.values(linesByLesson).forEach(lessonLines => {
             lessonLines.forEach((lineId, index) => {
               ranks[lineId] = index + 1;
             });
           });
           
           setLineRanks(ranks);
        }
      }
    }

    setLoading(false);
  };

  const filteredNotes = filter === 'all'
    ? notes
    : notes.filter(n => n.line?.lesson?.index === filter);

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('he-IL', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-gray-600">טוען הערות...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <MessageSquare className="w-6 h-6 text-blue-600" />
            <h2 className="text-2xl font-bold text-gray-900">הערות תלמידים</h2>
          </div>
          <div className="bg-blue-50 px-4 py-2 rounded-lg">
            <span className="text-sm text-blue-700 font-medium">
              {filteredNotes.length} הערות משותפות
            </span>
          </div>
        </div>

        <div className="flex gap-2 flex-wrap mb-6">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg transition-colors ${
              filter === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            כל השיעורים
          </button>
          {availableLessons.map(lessonNum => (
            <button
              key={lessonNum}
              onClick={() => setFilter(lessonNum)}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filter === lessonNum
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              שיעור {lessonNum}
            </button>
          ))}
        </div>

        {filteredNotes.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded-xl">
            <MessageSquare className="w-12 h-12 text-gray-400 mx-auto mb-3" />
            <p className="text-gray-600">אין הערות משותפות כרגע</p>
            <p className="text-sm text-gray-500 mt-1">
              תלמידים יכולים לשתף הערות דרך הסימון בכתיבת הערה
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredNotes.map(note => (
              <div
                key={note.id}
                className="bg-gray-50 rounded-xl p-5 border border-gray-200 hover:border-blue-300 transition-colors"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                      <User className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <div className="font-medium text-gray-900">{note.user?.username}</div>
                      <div className="flex items-center gap-2 text-sm text-gray-500">
                        <Calendar className="w-3 h-3" />
                        <span>{formatDate(note.created_at)}</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 text-sm bg-white px-3 py-1.5 rounded-lg border border-gray-200">
                    <BookOpen className="w-4 h-4 text-gray-600" />
                    <span className="text-gray-700">
                      שיעור {note.line?.lesson?.index} - שורה {lineRanks[note.line_id] || note.line?.order_num}
                    </span>
                  </div>
                </div>
                <div className="bg-white rounded-lg p-4 border border-gray-200">
                  <div className="text-gray-800 whitespace-pre-wrap" dir="auto">{note.content}</div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
