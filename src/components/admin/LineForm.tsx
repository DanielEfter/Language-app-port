import { useState, useRef } from 'react';
import { Palette, Bold, Underline, Type } from 'lucide-react';
import type { Line, LineType } from '../../lib/database.types';

interface Props {
  line: Partial<Line>;
  onChange: (line: Partial<Line>) => void;
  title: string;
  titleColor: string;
}

export default function LineForm({ line, onChange, title, titleColor }: Props) {
  const [showColorEditor, setShowColorEditor] = useState(false);
  const [selectedText, setSelectedText] = useState<{ start: number; end: number } | null>(null);
  const editableRef = useRef<HTMLDivElement>(null);
  const hebrewEditableRef = useRef<HTMLDivElement>(null);

  const handleItalianInput = () => {
    // תמיד LTR
    if (editableRef.current) {
      editableRef.current.dir = 'ltr';
      editableRef.current.style.direction = 'ltr';
      editableRef.current.style.textAlign = 'left';
      editableRef.current.style.unicodeBidi = 'bidi-override';
      editableRef.current.style.writingMode = 'horizontal-tb';
    }
    // לא לעדכן state כאן — רק ב-onBlur
  };

  const applyColor = (color: string) => {
    if (!selectedText) return;

    const text = line.text_it || '';
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = text;
    const plainText = tempDiv.textContent || '';

    const existingSpans: Array<{ start: number; end: number; color: string }> = [];
    const spanRegex = /<span style="color:([^"]+)">([^<]+)<\/span>/g;
    let match;
    let offset = 0;

    while ((match = spanRegex.exec(text)) !== null) {
      const spanColor = match[1];
      const spanText = match[2];
      const startInPlain = plainText.indexOf(spanText, offset);

      if (startInPlain !== -1) {
        existingSpans.push({
          start: startInPlain,
          end: startInPlain + spanText.length,
          color: spanColor
        });
        offset = startInPlain + spanText.length;
      }
    }

    existingSpans.push({
      start: selectedText.start,
      end: selectedText.end,
      color: color
    });

    existingSpans.sort((a, b) => a.start - b.start);

    const mergedSpans: Array<{ start: number; end: number; color: string }> = [];
    for (const span of existingSpans) {
      const last = mergedSpans[mergedSpans.length - 1];
      if (last && last.end >= span.start && last.color === span.color) {
        last.end = Math.max(last.end, span.end);
      } else {
        mergedSpans.push({ ...span });
      }
    }

    let result = '';
    let pos = 0;

    for (const span of mergedSpans) {
      if (span.start > pos) {
        result += plainText.slice(pos, span.start);
      }
      result += `<span style="color:${span.color}">${plainText.slice(span.start, span.end)}</span>`;
      pos = span.end;
    }

    if (pos < plainText.length) {
      result += plainText.slice(pos);
    }

    onChange({ ...line, text_it: result });
    setSelectedText(null);
    setShowColorEditor(false);
  };

  const removeColorFromSelection = () => {
    if (!selectedText) return;

    const text = line.text_it || '';
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = text;
    const plainText = tempDiv.textContent || '';

    const existingSpans: Array<{ start: number; end: number; color: string }> = [];
    const spanRegex = /<span style="color:([^"]+)">([^<]+)<\/span>/g;
    let match;
    let offset = 0;

    while ((match = spanRegex.exec(text)) !== null) {
      const spanColor = match[1];
      const spanText = match[2];
      const startInPlain = plainText.indexOf(spanText, offset);

      if (startInPlain !== -1) {
        const spanStart = startInPlain;
        const spanEnd = startInPlain + spanText.length;

        if (spanEnd <= selectedText.start || spanStart >= selectedText.end) {
          existingSpans.push({
            start: spanStart,
            end: spanEnd,
            color: spanColor
          });
        } else {
          if (spanStart < selectedText.start) {
            existingSpans.push({
              start: spanStart,
              end: selectedText.start,
              color: spanColor
            });
          }
          if (spanEnd > selectedText.end) {
            existingSpans.push({
              start: selectedText.end,
              end: spanEnd,
              color: spanColor
            });
          }
        }
        offset = startInPlain + spanText.length;
      }
    }

    existingSpans.sort((a, b) => a.start - b.start);

    let result = '';
    let pos = 0;

    for (const span of existingSpans) {
      if (span.start > pos) {
        result += plainText.slice(pos, span.start);
      }
      result += `<span style="color:${span.color}">${plainText.slice(span.start, span.end)}</span>`;
      pos = span.end;
    }

    if (pos < plainText.length) {
      result += plainText.slice(pos);
    }

    onChange({ ...line, text_it: result });
    setSelectedText(null);
    setShowColorEditor(false);
  };

  const removeColors = () => {
    const text = line.text_it || '';
    const cleanText = text.replace(/<span[^>]*>(.*?)<\/span>/g, '$1');
    onChange({ ...line, text_it: cleanText });
  };

  const handleTextSelection = () => {
    const selection = window.getSelection();
    if (!selection || selection.toString().length === 0) {
      setSelectedText(null);
      return;
    }

    const selectedTextContent = selection.toString();
    const editableDiv = document.querySelector('.editable-text');
    if (!editableDiv) return;

    const plainText = editableDiv.textContent || '';
    const range = selection.getRangeAt(0);
    const preSelectionRange = range.cloneRange();
    preSelectionRange.selectNodeContents(editableDiv);
    preSelectionRange.setEnd(range.startContainer, range.startOffset);
    const start = preSelectionRange.toString().length;
    const end = start + selectedTextContent.length;

    setSelectedText({ start, end });
  };

  const openColorEditor = () => {
    if (selectedText) {
      setShowColorEditor(true);
    }
  };

  return (
    <div className="space-y-4">
      <h3 className={`font-semibold mb-4 ${titleColor}`}>{title}</h3>

      <div>
        <label className="block text-sm font-medium mb-1">סוג</label>
        <select
          value={line.type || 'INFO'}
          onChange={(e) => onChange({ ...line, type: e.target.value as LineType })}
          className="w-full px-4 py-2 border rounded-lg"
        >
          <option value="INFO">INFO - הסבר</option>
          <option value="LINK">LINK - קישור</option>
          <option value="LANG">LANG - שורת שפה</option>
        </select>
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">טקסט בפורטוגזית</label>
        <div className="border rounded-lg p-4 bg-white relative" dir="ltr" style={{ direction: 'ltr' }}>
          <div
            ref={editableRef}
            className="editable-text min-h-[60px] text-lg outline-none"
            contentEditable
            suppressContentEditableWarning
            onInput={handleItalianInput}
            onBlur={(e) => onChange({ ...line, text_it: e.currentTarget.innerHTML })}
            onMouseUp={handleTextSelection}
            // לא נשתמש ב-dangerouslySetInnerHTML בזמן הקלדה, רק כאשר יש ערך התחלתי
            {...(line.text_it ? { dangerouslySetInnerHTML: { __html: line.text_it } } : {})}
            dir="ltr"
            lang="es"
            style={{ textAlign: 'left', direction: 'ltr', unicodeBidi: 'bidi-override', writingMode: 'horizontal-tb' }}
            data-placeholder="הקלד טקסט בפורטוגזית..."
          />
          {showColorEditor && selectedText && (
            <div className="absolute top-0 right-0 mt-2 mr-2 bg-white border border-gray-300 rounded-lg shadow-lg p-3 z-10">
              <div className="flex gap-2 items-center mb-2">
                <span className="text-xs text-gray-600 font-medium">צבע:</span>
                <button onClick={() => applyColor('#ef4444')} className="w-8 h-8 rounded-full bg-red-500 hover:ring-2 ring-gray-400" title="אדום" />
                <button onClick={() => applyColor('#3b82f6')} className="w-8 h-8 rounded-full bg-blue-500 hover:ring-2 ring-gray-400" title="כחול" />
                <button onClick={() => applyColor('#10b981')} className="w-8 h-8 rounded-full bg-green-500 hover:ring-2 ring-gray-400" title="ירוק" />
                <button onClick={() => applyColor('#f59e0b')} className="w-8 h-8 rounded-full bg-amber-500 hover:ring-2 ring-gray-400" title="כתום" />
                <button onClick={() => applyColor('#8b5cf6')} className="w-8 h-8 rounded-full bg-violet-500 hover:ring-2 ring-gray-400" title="סגול" />
                <button onClick={() => applyColor('#ec4899')} className="w-8 h-8 rounded-full bg-pink-500 hover:ring-2 ring-gray-400" title="ורוד" />
              </div>
              <div className="flex gap-2 border-t pt-2">
                <button
                  onClick={removeColorFromSelection}
                  className="flex-1 text-xs px-3 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded"
                  title="הסר הדגשה מהטקסט המסומן"
                >
                  הסר הדגשה
                </button>
                <button
                  onClick={() => setShowColorEditor(false)}
                  className="text-xs px-3 py-1.5 text-gray-500 hover:text-gray-700"
                >
                  ביטול
                </button>
              </div>
            </div>
          )}
        </div>
        <div className="flex gap-2 mt-2">
          <button
            type="button"
            onClick={openColorEditor}
            disabled={!selectedText}
            className="flex items-center gap-1 px-3 py-1.5 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            <Palette className="w-4 h-4" />
            <span>צבע טקסט מסומן</span>
          </button>
          <button
            type="button"
            onClick={removeColors}
            className="flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition-colors"
          >
            <Palette className="w-4 h-4" />
            <span>נקה צבעים</span>
          </button>
          <span className="text-xs text-gray-500 flex items-center">סמן טקסט ולחץ על "צבע טקסט מסומן"</span>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">טקסט באנגלית</label>
        <textarea
          value={line.text_en || ''}
          onChange={(e) => onChange({ ...line, text_en: e.target.value })}
          className="w-full px-4 py-2 border rounded-lg"
          rows={3}
          dir="ltr"
          lang="en"
          style={{ textAlign: 'left', direction: 'ltr', unicodeBidi: 'isolate' }}
        />
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">תרגום לעברית</label>
        <div className="border rounded-lg bg-white" dir="rtl">
          {/* Formatting toolbar */}
          <div className="flex gap-2 p-2 border-b bg-gray-50">
            <button
              type="button"
              onClick={() => {
                document.execCommand('bold', false);
                hebrewEditableRef.current?.focus();
              }}
              className="p-2 hover:bg-gray-200 rounded transition-colors"
              title="מודגש"
            >
              <Bold className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={() => {
                document.execCommand('underline', false);
                hebrewEditableRef.current?.focus();
              }}
              className="p-2 hover:bg-gray-200 rounded transition-colors"
              title="קו תחתון"
            >
              <Underline className="w-4 h-4" />
            </button>
            <div className="border-r mx-2"></div>
            <button
              type="button"
              onClick={() => {
                document.execCommand('fontSize', false, '5');
                hebrewEditableRef.current?.focus();
              }}
              className="p-2 hover:bg-gray-200 rounded transition-colors text-sm font-bold"
              title="גדול"
            >
              <Type className="w-5 h-5" />
            </button>
            <button
              type="button"
              onClick={() => {
                document.execCommand('fontSize', false, '3');
                hebrewEditableRef.current?.focus();
              }}
              className="p-2 hover:bg-gray-200 rounded transition-colors text-xs"
              title="רגיל"
            >
              <Type className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={() => {
                document.execCommand('fontSize', false, '1');
                hebrewEditableRef.current?.focus();
              }}
              className="p-2 hover:bg-gray-200 rounded transition-colors text-xs"
              title="קטן"
            >
              <Type className="w-3 h-3" />
            </button>
          </div>
          {/* Editable div */}
          <div
            ref={hebrewEditableRef}
            className="min-h-[80px] p-4 outline-none"
            contentEditable
            suppressContentEditableWarning
            onBlur={(e) => onChange({ ...line, text_he: e.currentTarget.innerHTML })}
            {...(line.text_he ? { dangerouslySetInnerHTML: { __html: line.text_he } } : {})}
            dir="rtl"
            lang="he"
            style={{ textAlign: 'right', direction: 'rtl' }}
            data-placeholder="הקלד טקסט בעברית..."
          />
        </div>
      </div>
    </div>
  );
}
