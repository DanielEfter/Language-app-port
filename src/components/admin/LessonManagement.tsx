import { useState, useEffect } from 'react';
import { Plus, Edit, Eye, Trash2, Edit3 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { Lesson } from '../../lib/database.types';
import LineEditor from './LineEditor';

export default function LessonManagement() {
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [editingLesson, setEditingLesson] = useState<Lesson | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [editingLessonDetails, setEditingLessonDetails] = useState<Lesson | null>(null);
  const [newTitle, setNewTitle] = useState('');
  const [newIndex, setNewIndex] = useState(1);
  const [newDescription, setNewDescription] = useState('');

  useEffect(() => {
    loadLessons();

    // Subscribe to real-time changes
    const channel = supabase
      .channel('admin-lessons')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'lessons',
        },
        () => {
          loadLessons();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const loadLessons = async () => {
    const { data } = await supabase.from('lessons').select('*').order('index');
    if (data) setLessons(data);
  };

  const handleCreate = async () => {
    if (!newTitle.trim()) return;
    await supabase.from('lessons').insert({
      index: newIndex,
      title: newTitle,
      description: newDescription,
      is_published: false,
    });
    setShowCreate(false);
    setNewTitle('');
    setNewDescription('');
    loadLessons();
  };

  const togglePublish = async (id: string, current: boolean) => {
    await supabase.from('lessons').update({ is_published: !current }).eq('id', id);
    loadLessons();
  };

  const deleteLesson = async (id: string) => {
    if (!confirm('האם למחוק שיעור זה?')) return;
    await supabase.from('lessons').delete().eq('id', id);
    loadLessons();
  };

  const handleUpdateLesson = async () => {
    if (!editingLessonDetails) return;
    await supabase
      .from('lessons')
      .update({
        index: editingLessonDetails.index,
        title: editingLessonDetails.title,
        description: editingLessonDetails.description,
      })
      .eq('id', editingLessonDetails.id);
    setEditingLessonDetails(null);
    loadLessons();
  };

  if (editingLesson) {
    return <LineEditor lesson={editingLesson} onBack={() => { setEditingLesson(null); loadLessons(); }} />;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900">ניהול שיעורים</h2>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg"
        >
          <Plus className="w-5 h-5" />
          <span>שיעור חדש</span>
        </button>
      </div>

      {showCreate && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
          <h3 className="font-semibold text-blue-900 mb-4">יצירת שיעור חדש</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">מספר שיעור (0-8)</label>
              <input
                type="number"
                min="0"
                max="8"
                value={newIndex}
                onChange={(e) => setNewIndex(Number(e.target.value))}
                className="w-full px-4 py-2 border rounded-lg"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">כותרת</label>
              <input
                type="text"
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                className="w-full px-4 py-2 border rounded-lg"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">תיאור</label>
              <textarea
                value={newDescription}
                onChange={(e) => setNewDescription(e.target.value)}
                className="w-full px-4 py-2 border rounded-lg"
                rows={2}
              />
            </div>
            <div className="flex gap-3">
              <button onClick={handleCreate} className="px-6 py-2 bg-blue-600 text-white rounded-lg">
                צור
              </button>
              <button onClick={() => setShowCreate(false)} className="px-6 py-2 border rounded-lg">
                ביטול
              </button>
            </div>
          </div>
        </div>
      )}

      {editingLessonDetails && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-6">
          <h3 className="font-semibold text-green-900 mb-4">עריכת פרטי השיעור</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">מספר שיעור</label>
              <input
                type="number"
                min="0"
                value={editingLessonDetails.index}
                onChange={(e) => setEditingLessonDetails({ ...editingLessonDetails, index: Number(e.target.value) })}
                className="w-full px-4 py-2 border rounded-lg"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">כותרת</label>
              <input
                type="text"
                value={editingLessonDetails.title}
                onChange={(e) => setEditingLessonDetails({ ...editingLessonDetails, title: e.target.value })}
                className="w-full px-4 py-2 border rounded-lg"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">תיאור</label>
              <textarea
                value={editingLessonDetails.description || ''}
                onChange={(e) => setEditingLessonDetails({ ...editingLessonDetails, description: e.target.value })}
                className="w-full px-4 py-2 border rounded-lg"
                rows={2}
              />
            </div>
            <div className="flex gap-3">
              <button onClick={handleUpdateLesson} className="px-6 py-2 bg-green-600 text-white rounded-lg">
                שמור שינויים
              </button>
              <button onClick={() => setEditingLessonDetails(null)} className="px-6 py-2 border rounded-lg">
                ביטול
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="grid gap-4">
        {lessons.map((lesson) => (
          <div key={lesson.id} className="bg-white border rounded-xl p-6">
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <span className="text-2xl font-bold text-blue-600">{lesson.index}</span>
                  <h3 className="text-lg font-semibold">{lesson.title}</h3>
                  <span className={`text-xs px-3 py-1 rounded-full ${lesson.is_published ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                    {lesson.is_published ? 'מפורסם' : 'טיוטה'}
                  </span>
                </div>
                {lesson.description && (
                  <p className="text-sm text-gray-600">{lesson.description}</p>
                )}
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setEditingLessonDetails(lesson)}
                  className="p-2 hover:bg-green-100 text-green-600 rounded-lg"
                  title="ערוך פרטי שיעור"
                >
                  <Edit3 className="w-5 h-5" />
                </button>
                <button
                  onClick={() => setEditingLesson(lesson)}
                  className="p-2 hover:bg-blue-100 text-blue-600 rounded-lg"
                  title="ערוך שורות"
                >
                  <Edit className="w-5 h-5" />
                </button>
                <button
                  onClick={() => togglePublish(lesson.id, lesson.is_published)}
                  className="p-2 hover:bg-purple-100 text-purple-600 rounded-lg"
                  title={lesson.is_published ? 'הסתר' : 'פרסם'}
                >
                  <Eye className="w-5 h-5" />
                </button>
                <button
                  onClick={() => deleteLesson(lesson.id)}
                  className="p-2 hover:bg-red-100 text-red-600 rounded-lg"
                  title="מחק"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
