import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { ArrowRight, Plus, Trash2, Save, ArrowUp, ArrowDown, Edit } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { Lesson, Line } from '../../lib/database.types';
import LineForm from './LineForm';

interface Props {
  lesson: Lesson;
  onBack: () => void;
}

export default function LineEditor({ lesson, onBack }: Props) {
  const [lines, setLines] = useState<Line[]>([]);
  const [editingLine, setEditingLine] = useState<Partial<Line> | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    loadLines();

    // Subscribe to real-time changes
    const channel = supabase
      .channel(`admin-lines-${lesson.id}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'lines',
          filter: `lesson_id=eq.${lesson.id}`,
        },
        () => {
          // If we are currently editing/saving, we might want to be careful not to overwrite user input
          // But for the main list view, we definitely want the latest data
          if (!isSaving) { 
             loadLines(); 
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [lesson.id]);

  // Lock body scroll when modal opens
  useEffect(() => {
    if (editingLine) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    
    // Cleanup on unmount
    return () => {
      document.body.style.overflow = '';
    };
  }, [editingLine]);

  const loadLines = async () => {
    const { data, error } = await supabase.from('lines').select('*').eq('lesson_id', lesson.id).order('order_num');
    if (error) {
      console.error('Error loading lines:', error);
      return;
    }
    if (data) setLines(data);
  };

  const handleSaveLine = async () => {
    if (!editingLine || isSaving) return;

    setIsSaving(true);

    try {
      if (editingLine.id) {
        // Update existing line - auto-generate code if missing
        let codeToUse = editingLine.code;
        if (!codeToUse) {
          // Generate code based on lesson index and order_num
          codeToUse = `${lesson.index}-${String(editingLine.order_num || 0).padStart(5, '0')}`;
        }
        
        const updateData: any = {
          code: codeToUse,
          type: editingLine.type || 'INFO',
          text_he: editingLine.text_he || '',
          text_en: editingLine.text_en || '',
          text_it: editingLine.text_it || '',
          stress_rule: editingLine.stress_rule || null,
          recording_hint: editingLine.recording_hint || null,
        };
        
        // Optimistic update: update state immediately
        const updatedLines = lines.map(l => 
          l.id === editingLine.id ? { ...l, ...updateData } : l
        );
        setLines(updatedLines);
        setEditingLine(null);
        setIsSaving(false);

        // Update DB in background
        const { error } = await supabase.from('lines').update(updateData).eq('id', editingLine.id);
        if (error) {
          console.error('Error updating line:', error);
          alert('שגיאה בעדכון השורה: ' + error.message);
          // Reload on error
          await loadLines();
        }
      } else {
        // Create new line
        const insertPosition = (editingLine as any).insertAfter;
        let newOrderNum: number;
        let suggestedCode = editingLine.code;

        if (insertPosition === 'end' || lines.length === 0) {
          newOrderNum = lines.length > 0 ? Math.max(...lines.map(l => l.order_num)) + 1 : 1;
          
          if (!suggestedCode && lines.length > 0) {
            const lastLine = lines[lines.length - 1];
            const match = lastLine.code.match(/^(\d+)-(\d+)$/);
            if (match) {
              const lessonNum = match[1];
              const lineNum = parseInt(match[2]) + 1;
              suggestedCode = `${lessonNum}-${String(lineNum).padStart(5, '0')}`;
            }
          }
        } else {
          const afterIndex = lines.findIndex(l => l.id === insertPosition);

          if (afterIndex === -1) {
            console.error('Could not find line with ID:', insertPosition);
            alert('שגיאה: לא נמצאה השורה הקודמת');
            setIsSaving(false);
            return;
          }

          newOrderNum = lines[afterIndex].order_num + 1;

          if (!suggestedCode) {
            const prevLine = lines[afterIndex];
            const nextLine = lines[afterIndex + 1];
            
            if (prevLine && nextLine) {
              const prevMatch = prevLine.code.match(/^(\d+)-(\d+)$/);
              const nextMatch = nextLine.code.match(/^(\d+)-(\d+)$/);
              
              if (prevMatch && nextMatch) {
                const lessonNum = prevMatch[1];
                const prevNum = parseInt(prevMatch[2]);
                const nextNum = parseInt(nextMatch[2]);
                
                const newNum = Math.floor((prevNum + nextNum) / 2);
                if (newNum > prevNum && newNum < nextNum) {
                  suggestedCode = `${lessonNum}-${String(newNum).padStart(5, '0')}`;
                } else {
                  suggestedCode = `${lessonNum}-${String(prevNum).padStart(5, '0')}a`;
                }
              }
            } else if (prevLine) {
              const match = prevLine.code.match(/^(\d+)-(\d+)$/);
              if (match) {
                const lessonNum = match[1];
                const lineNum = parseInt(match[2]) + 1;
                suggestedCode = `${lessonNum}-${String(lineNum).padStart(5, '0')}`;
              }
            }
          }

          // Batch update order_num for lines after insertion point
          const linesToUpdate = lines.slice(afterIndex + 1);
          if (linesToUpdate.length > 0) {
            // Update all in parallel instead of sequential await
            await Promise.all(
              linesToUpdate.map(line => 
                supabase.from('lines').update({ order_num: line.order_num + 1 }).eq('id', line.id)
              )
            );
          }
        }

        // Auto-generate code if not provided
        if (!suggestedCode) {
          // Fallback: use lesson index and order_num
          suggestedCode = `${lesson.index}-${String(newOrderNum).padStart(5, '0')}`;
        }

        const newLineData = {
          lesson_id: lesson.id,
          order_num: newOrderNum,
          code: suggestedCode,
          type: editingLine.type || 'INFO',
          text_he: editingLine.text_he || '',
          text_en: editingLine.text_en || '',
          text_it: editingLine.text_it || '',
          stress_rule: editingLine.stress_rule || null,
          recording_hint: editingLine.recording_hint || null,
        };

        const { data: insertedLine, error } = await supabase.from('lines').insert(newLineData).select().single();

        if (error) {
          console.error('Error inserting line:', error);
          alert('שגיאה בשמירת השורה: ' + error.message);
          setIsSaving(false);
          return;
        }

        // Optimistic update: add new line to state immediately
        if (insertedLine) {
          const afterIndex = insertPosition === 'end' ? lines.length : lines.findIndex(l => l.id === insertPosition);
          const updatedLines = [...lines];
          
          if (afterIndex === lines.length || afterIndex === -1) {
            updatedLines.push(insertedLine);
          } else {
            // Update order_num in local state for lines after insertion
            for (let i = afterIndex + 1; i < updatedLines.length; i++) {
              updatedLines[i] = { ...updatedLines[i], order_num: updatedLines[i].order_num + 1 };
            }
            updatedLines.splice(afterIndex + 1, 0, insertedLine);
          }
          
          setLines(updatedLines);
        }

        setEditingLine(null);
        setIsSaving(false);
      }
    } catch (err) {
      console.error('Unexpected error:', err);
      setIsSaving(false);
      // Reload on unexpected error
      await loadLines();
    }
  };

  const deleteLine = async (id: string) => {
    if (!confirm('למחוק שורה זו?')) return;
    await supabase.from('lines').delete().eq('id', id);
    loadLines();
  };

  const moveLineUp = async (index: number) => {
    if (index === 0) return;
    const line1 = lines[index];
    const line2 = lines[index - 1];

    // Optimistic update: swap in local state immediately
    const updatedLines = [...lines];
    updatedLines[index] = { ...line2, order_num: line1.order_num };
    updatedLines[index - 1] = { ...line1, order_num: line2.order_num };
    setLines(updatedLines);

    // Update DB in background
    await Promise.all([
      supabase.from('lines').update({ order_num: line2.order_num }).eq('id', line1.id),
      supabase.from('lines').update({ order_num: line1.order_num }).eq('id', line2.id)
    ]);
  };

  const moveLineDown = async (index: number) => {
    if (index === lines.length - 1) return;
    const line1 = lines[index];
    const line2 = lines[index + 1];

    // Optimistic update: swap in local state immediately
    const updatedLines = [...lines];
    updatedLines[index] = { ...line2, order_num: line1.order_num };
    updatedLines[index + 1] = { ...line1, order_num: line2.order_num };
    setLines(updatedLines);

    // Update DB in background
    await Promise.all([
      supabase.from('lines').update({ order_num: line2.order_num }).eq('id', line1.id),
      supabase.from('lines').update({ order_num: line1.order_num }).eq('id', line2.id)
    ]);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <button onClick={onBack} className="flex items-center gap-2 text-gray-600 hover:text-gray-900">
          <ArrowRight className="w-5 h-5" />
          <span>חזרה לשיעורים</span>
        </button>
        <h2 className="text-lg font-semibold">שיעור {lesson.index}: {lesson.title}</h2>
        <button
          onClick={() => setEditingLine({ code: '', type: 'INFO', text_he: '', text_en: '', text_it: '', stress_rule: '', recording_hint: '', insertAfter: 'end' } as any)}
          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          title="הוסף שורה בסוף"
        >
          <Plus className="w-5 h-5" />
          <span>הוסף שורה בסוף</span>
        </button>
      </div>

      {/* Modal for editing/creating lines */}
      {editingLine && createPortal(
        <>
          {/* Overlay backdrop */}
          <div 
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              backgroundColor: 'rgba(0, 0, 0, 0.5)',
              zIndex: 99998,
              display: 'block'
            }}
            onClick={() => setEditingLine(null)}
          />
          
          {/* Modal content */}
          <div 
            style={{
              position: 'fixed',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              zIndex: 99999,
              width: '90%',
              maxWidth: '56rem',
              maxHeight: '90vh',
              backgroundColor: 'white',
              borderRadius: '0.75rem',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
              display: 'flex',
              flexDirection: 'column'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className={`p-6 border-b ${editingLine.id ? 'bg-blue-50' : 'bg-green-50'}`} style={{ flexShrink: 0 }}>
              <h3 className={`text-xl font-bold ${editingLine.id ? 'text-blue-900' : 'text-green-900'}`}>
                {editingLine.id 
                  ? `עריכת שורה ${lines.findIndex(l => l.id === editingLine.id) + 1}` 
                  : (editingLine as any).insertAfter === 'end'
                    ? 'שורה חדשה בסוף השיעור'
                    : `שורה חדשה אחרי שורה ${lines.findIndex(l => l.id === (editingLine as any).insertAfter) + 1}`
                }
              </h3>
            </div>
            <div className="p-6 overflow-y-auto" style={{ flex: 1 }}>
              <LineForm
                line={editingLine}
                onChange={setEditingLine}
                title=""
                titleColor=""
              />
            </div>
            <div className="p-6 bg-gray-50 border-t flex gap-3 justify-end" style={{ flexShrink: 0 }}>
              <button
                onClick={() => setEditingLine(null)}
                disabled={isSaving}
                className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                ביטול
              </button>
              <button
                onClick={handleSaveLine}
                disabled={isSaving}
                className={`flex items-center gap-2 px-6 py-2 text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed ${
                  editingLine.id ? 'bg-blue-600 hover:bg-blue-700' : 'bg-green-600 hover:bg-green-700'
                }`}
              >
                <Save className="w-5 h-5" />
                <span>{isSaving ? (editingLine.id ? 'מעדכן...' : 'שומר...') : (editingLine.id ? 'עדכן' : 'שמור')}</span>
              </button>
            </div>
          </div>
        </>,
        document.body
      )}

      <div className="space-y-3">
        {lines.map((line, index) => (
          <div key={line.id}>
            <div className="bg-white border rounded-xl p-4 flex items-start justify-between hover:border-gray-300 transition-colors">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <span className="text-xs font-mono bg-blue-600 text-white px-2 py-1 rounded">שורה {index + 1}</span>
                  <span className="text-xs font-semibold text-blue-600">{line.type}</span>
                </div>
                {line.text_it && (
                  <div
                    className="text-sm text-gray-900 mb-1"
                    dir="ltr"
                    style={{ textAlign: 'left' }}
                    dangerouslySetInnerHTML={{ __html: line.text_it }}
                  />
                )}
                {line.text_en && (
                  <div 
                    className="text-sm text-gray-700 mb-1" 
                    dir="ltr" 
                    style={{ textAlign: 'left' }} 
                    dangerouslySetInnerHTML={{ __html: line.text_en }} 
                  />
                )}
                {line.text_he && (
                  <div 
                    className="text-sm text-gray-900" 
                    dir="rtl"
                    dangerouslySetInnerHTML={{ __html: line.text_he }}
                  />
                )}
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setEditingLine({ code: '', type: 'INFO', text_he: '', text_en: '', text_it: '', stress_rule: '', recording_hint: '', insertAfter: line.id } as any)}
                  className="p-2 hover:bg-green-100 text-green-600 rounded-lg transition-colors"
                  title="הוסף שורה אחרי"
                >
                  <Plus className="w-4 h-4" />
                </button>
                <button
                  onClick={() => moveLineUp(index)}
                  disabled={index === 0}
                  className="p-2 hover:bg-gray-100 text-gray-600 rounded-lg disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  title="הזז למעלה"
                >
                  <ArrowUp className="w-4 h-4" />
                </button>
                <button
                  onClick={() => moveLineDown(index)}
                  disabled={index === lines.length - 1}
                  className="p-2 hover:bg-gray-100 text-gray-600 rounded-lg disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  title="הזז למטה"
                >
                  <ArrowDown className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setEditingLine(line)}
                  className="p-2 hover:bg-blue-100 text-blue-600 rounded-lg transition-colors"
                  title="ערוך"
                >
                  <Edit className="w-4 h-4" />
                </button>
                <button
                  onClick={() => deleteLine(line.id)}
                  className="p-2 hover:bg-red-100 text-red-600 rounded-lg transition-colors"
                  title="מחק"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
