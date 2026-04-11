import { useState, useEffect, useMemo } from 'react';
import { createPortal } from 'react-dom';
import { Volume2, Languages, Edit3, ArrowLeft, Mic, MicOff, AlertCircle, X, RotateCcw } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import type { Line } from '../lib/database.types';
import { speakText, isSpeechRecognitionSupported, createSpeechRecognition, startRecording, stopRecording, unlockAudio } from '../lib/speech';
import { calculateSimilarity } from '../lib/similarity';

interface Props {
  line: Line;
  onNext: () => void;
}

export default function LineDisplay({ line, onNext }: Props) {
  const { user } = useAuth();
  const [showTranslation, setShowTranslation] = useState(false);
  const [showNote, setShowNote] = useState(false);
  const [showSpeech, setShowSpeech] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [similarity, setSimilarity] = useState<number | null>(null);
  const [speechError, setSpeechError] = useState('');
  const [recognition, setRecognition] = useState<any>(null);
  const [existingNote, setExistingNote] = useState('');
  const [shareWithAdmin, setShareWithAdmin] = useState(false);

  // Calculate plain text length of text_it for dynamic font sizing
  const plainTextItLength = useMemo(() => {
    return (line.text_it || '').replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim().length;
  }, [line.text_it]);

  const getTextItFontClass = () => {
    if (showTranslation) {
      if (plainTextItLength > 60) return "text-base sm:text-lg md:text-xl";
      if (plainTextItLength > 40) return "text-lg sm:text-xl md:text-2xl";
      return "text-xl sm:text-2xl md:text-3xl";
    }
    if (line.text_en) {
      if (plainTextItLength > 60) return "text-lg sm:text-xl md:text-2xl";
      if (plainTextItLength > 40) return "text-xl sm:text-2xl md:text-3xl";
      return "text-2xl sm:text-3xl md:text-4xl";
    }
    if (plainTextItLength > 60) return "text-xl sm:text-2xl md:text-3xl";
    if (plainTextItLength > 40) return "text-2xl sm:text-3xl md:text-4xl";
    return "text-3xl sm:text-4xl md:text-5xl";
  };

  // Unlock audio on first user interaction (for mobile)
  useEffect(() => {
    const handleFirstInteraction = () => {
      unlockAudio();
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
    document.addEventListener('touchstart', handleFirstInteraction);
    document.addEventListener('click', handleFirstInteraction);
    return () => {
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
  }, []);

  useEffect(() => {
    let isMounted = true;

    // Reset state when line changes
    setShowTranslation(false);
    setShowNote(false);
    setShowSpeech(false);
    setNoteContent('');
    setIsRecording(false);
    setTranscript('');
    setSimilarity(null);
    setSpeechError('');
    setExistingNote('');
    setShareWithAdmin(false);

    const fetchNote = async () => {
      if (!user) return;
      const { data } = await supabase
        .from('notes')
        .select('*')
        .eq('user_id', user.id)
        .eq('line_id', line.id)
        .maybeSingle();
      
      if (isMounted) {
        if (data) {
          setExistingNote(data.content);
          setNoteContent(data.content);
          setShareWithAdmin(data.share_with_admin || false);
        }
      }
    };

    fetchNote();

    let newRecognition: any = null;
    if (isSpeechRecognitionSupported()) {
      newRecognition = createSpeechRecognition('pt-BR');
      setRecognition(newRecognition);
    }

    return () => {
      isMounted = false;
      if (newRecognition) {
        try {
          newRecognition.abort();
        } catch (e) {
          // ignore errors during cleanup
        }
      }
    };
  }, [line.id, user]);

  const handleSaveNote = async () => {
    if (!user || !noteContent.trim()) return;

    if (existingNote) {
      await supabase
        .from('notes')
        .update({
          content: noteContent,
          share_with_admin: shareWithAdmin,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', user.id)
        .eq('line_id', line.id);
    } else {
      await supabase
        .from('notes')
        .insert({
          user_id: user.id,
          line_id: line.id,
          content: noteContent,
          share_with_admin: shareWithAdmin,
        });
    }

    setShowNote(false);
    setExistingNote(noteContent);
  };

  const handleStartRecording = () => {
    if (!recognition) {
      setSpeechError('זיהוי קולי לא נתמך בדפדפן זה');
      return;
    }

    setIsRecording(true);
    setSpeechError('');
    setTranscript('');
    setSimilarity(null);

    startRecording(
      recognition,
      (result) => {
        setIsRecording(false);
        setTranscript(result.transcript);
        const score = calculateSimilarity(line.text_it, result.transcript);
        setSimilarity(score);
        saveAttempt(result.transcript, score);
      },
      (error) => {
        setIsRecording(false);
        setSpeechError(error);
      }
    );
  };

  const handleStopRecording = () => {
    if (recognition) {
      stopRecording(recognition);
      // Note: setIsRecording(false) will be called by the result callback
      // But set it here as a fallback in case no transcript was captured
      setTimeout(() => {
        setIsRecording(false);
      }, 100);
    }
  };

  const saveAttempt = async (transcriptText: string, score: number) => {
    if (!user) return;
    await supabase.from('speech_attempts').insert({
      user_id: user.id,
      line_id: line.id,
      transcript: transcriptText,
      similarity_score: score,
    });
  };
  const noteModalWithOverlay = createPortal(
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fadeIn">
      <div className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl p-6 md:p-8 relative transform transition-all" dir="rtl">
        <button 
            onClick={() => setShowNote(false)}
            className="absolute top-4 left-4 p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
        >
            <X className="w-6 h-6" />
        </button>

        <h3 className="text-2xl font-bold text-[#3A4031] mb-6 text-center">הערה אישית</h3>
        
        <textarea
          value={noteContent}
          onChange={(e) => setNoteContent(e.target.value)}
          className="w-full px-5 py-4 bg-[#F8F9F7] border border-[#DAD7CD] rounded-2xl focus:ring-2 focus:ring-[#A3B18A]/20 focus:border-[#A3B18A] outline-none transition-all resize-none min-h-[160px] text-lg leading-relaxed"
          placeholder="כתוב כאן את ההערות שלך..."
          dir="auto"
        />

        <div className="mt-6 flex items-center gap-3 p-4 bg-[#F8F9F7] rounded-xl border border-[#DAD7CD]/50 hover:border-[#A3B18A]/50 transition-colors">
          <input
            type="checkbox"
            id="shareWithAdminModal"
            checked={shareWithAdmin}
            onChange={(e) => setShareWithAdmin(e.target.checked)}
            className="w-5 h-5 text-[#A3B18A] border-gray-300 rounded focus:ring-[#A3B18A]"
          />
          <label htmlFor="shareWithAdminModal" className="text-base text-[#3A4031] cursor-pointer select-none font-medium flex-1">
            שתף הערה זו עם המנהל (לקבלת משוב)
          </label>
        </div>

        <div className="flex gap-4 mt-8">
          <button
            onClick={handleSaveNote}
            className="flex-1 py-4 bg-[#A3B18A] hover:bg-[#8D9B75] text-white rounded-xl font-bold text-lg transition-colors shadow-lg shadow-[#A3B18A]/20 transform active:scale-[0.98]"
          >
            שמור
          </button>
          <button
            onClick={() => setShowNote(false)}
            className="flex-1 py-4 bg-white border-2 border-[#E9E9E9] hover:bg-[#F8F9F7] text-[#7A7A7A] rounded-xl font-bold text-lg transition-colors"
          >
            ביטול
          </button>
        </div>
      </div>
    </div>,
    document.body
  );

  const speechModalWithOverlay = createPortal(
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fadeIn">
      <div className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl p-6 md:p-8 relative transform transition-all text-center" dir="rtl">
        <button 
            onClick={() => {
              setShowSpeech(false);
              handleStopRecording();
            }}
            className="absolute top-4 left-4 p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors md:hidden z-20"
        >
            <X className="w-6 h-6" />
        </button>

        <h3 className="text-2xl font-bold text-[#3A4031] mb-2">בדיקת הגייה</h3>
        <p className="text-[#A3B18A] mb-8 text-lg">נסה לקרוא את המשפט בקול</p>

        {/* Target Text Display */}
        <div className="mb-8 p-4 bg-gray-50 rounded-2xl border border-gray-100">
           <div 
             className="text-2xl md:text-3xl font-medium text-[#3A4031]" 
             dir="ltr"
             lang="es"
             dangerouslySetInnerHTML={{ __html: line.text_it }}
           />
        </div>

        {!isSpeechRecognitionSupported() && (
          <div className="bg-[#F2E9E4] border border-[#E9C46A] text-[#3A4031] p-4 rounded-xl mb-6 flex items-start gap-3 text-right">
            <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5 text-[#E9C46A]" />
            <div className="text-sm">
              זיהוי קולי לא נתמך בדפדפן זה. נסה להשתמש ב-Chrome.
            </div>
          </div>
        )}

        {line.recording_hint && (
          <div className="text-[#A3B18A] mb-8 bg-[#F8F9F7] p-4 rounded-2xl border border-[#DAD7CD] text-lg font-medium">
            💡 {line.recording_hint}
          </div>
        )}

        <div className="flex items-center justify-center gap-6 mb-8 relative w-full px-4">
          
          {/* Back Button (Left side of Mic) */}
          <div className="flex justify-start w-16 order-3">
             <button
                onClick={() => {
                  setShowSpeech(false);
                  handleStopRecording();
                }}
                className="w-12 h-12 sm:w-14 sm:h-14 flex items-center justify-center bg-gray-100 hover:bg-gray-200 text-gray-600 rounded-full transition-all shadow-sm hover:shadow-md"
                title="חזרה"
              >
                <ArrowLeft className="w-5 h-5 sm:w-6 sm:h-6" />
              </button>
          </div>

          {/* Microphone (Center) */}
          <div className="flex-shrink-0 relative z-10 order-2">
            {!isRecording ? (
              <button
                onClick={handleStartRecording}
                disabled={!isSpeechRecognitionSupported()}
                className="group relative flex items-center justify-center w-20 h-20 sm:w-24 sm:h-24 bg-[#A3B18A] hover:bg-[#8d9b75] text-white rounded-full shadow-xl shadow-[#A3B18A]/30 transition-all transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              >
                <Mic className="w-8 h-8 sm:w-10 sm:h-10" />
                <span className="absolute inset-0 rounded-full border-2 border-white/30 animate-ping"></span>
              </button>
            ) : (
              <button
                onClick={handleStopRecording}
                className="relative flex items-center justify-center w-20 h-20 sm:w-24 sm:h-24 bg-[#EB5757] hover:bg-[#D44E4E] text-white rounded-full shadow-xl transition-all"
              >
                <MicOff className="w-8 h-8 sm:w-10 sm:h-10" />
                <span className="absolute inset-0 rounded-full border-4 border-[#EB5757]/30 animate-ping"></span>
              </button>
            )}
          </div>

          {/* Try Again (Right side of Mic) */}
          <div className="flex justify-end w-16 order-1 h-14">
            {transcript && (
              <button
                onClick={() => {
                  setTranscript('');
                  setSimilarity(null);
                  setSpeechError('');
                  handleStartRecording();
                }}
                className="w-12 h-12 sm:w-14 sm:h-14 flex items-center justify-center bg-white border-2 border-[#E9E9E9] hover:border-[#A3B18A] text-[#7A7A7A] hover:text-[#A3B18A] rounded-full transition-all shadow-sm hover:shadow-md animate-fadeIn"
                title="נסה שוב"
              >
                 <RotateCcw className="w-5 h-5 sm:w-6 sm:h-6" />
              </button>
            )}
          </div>
        </div>

        {isRecording && (
          <div className="text-[#EB5757] font-bold animate-pulse mb-6">
            מקליט... דבר עכשיו
          </div>
        )}

        {speechError && (
          <div className="bg-[#F2E9E4] border border-[#E9C46A] text-[#3A4031] p-4 rounded-xl mb-6 text-center text-sm">
            {speechError}
          </div>
        )}

        {transcript && (
          <div className="space-y-6 animate-fadeIn">
            <div className="bg-[#F8F9F7] p-6 rounded-2xl border border-[#DAD7CD] shadow-inner">
              <div className="text-xs font-bold text-[#A3B18A] uppercase tracking-wider mb-2">מה שמענו</div>
              <div className="text-2xl font-medium text-[#3A4031]" dir="ltr">
                "{transcript}"
              </div>
            </div>

            {similarity !== null && (
              <div className={`p-6 rounded-2xl border-2 ${
                similarity >= 0.7 
                  ? 'bg-[#F0FDF4] border-[#A3B18A]' 
                  : similarity >= 0.4 
                    ? 'bg-[#FFFBEB] border-[#E9C46A]' 
                    : 'bg-[#FEF2F2] border-[#EF4444]'
              }`}>
                <div className="text-center">
                  <div className={`text-3xl font-bold mb-2 ${
                    similarity >= 0.7 
                      ? 'text-[#A3B18A]' 
                      : similarity >= 0.4 
                        ? 'text-[#E9C46A]' 
                        : 'text-[#EF4444]'
                  }`}>
                    {similarity >= 0.7 
                      ? 'מצוין! 👏' 
                      : similarity >= 0.4 
                        ? 'כמעט... 🤔' 
                        : 'לא בכיוון 😕'}
                  </div>
                  <div className="text-lg font-medium text-[#3A4031]">
                    {similarity >= 0.7 
                      ? 'ההגייה שלך מדויקת מאוד' 
                      : similarity >= 0.4 
                        ? 'היית קרוב, נסה שוב!' 
                        : 'נסה להקשיב שוב להגייה המקורית'}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>,
    document.body
  );

  if (line.type === 'INFO' || line.type === 'LINK') {
    return (
      <div className="flex flex-col h-full">
        <div className="bg-gray-200/50 backdrop-blur-sm rounded-3xl shadow-xl shadow-slate-200/50 border border-white/50 h-[70%] flex flex-col overflow-hidden">
          <div className="overflow-y-auto h-full p-6 sm:p-10 thin-scrollbar flex flex-col">
            <div className="prose prose-lg max-w-none flex-1 w-full" dir="auto" data-bidi-auto>
              <div 
                className="text-slate-800 leading-relaxed font-medium info-content"
                dangerouslySetInnerHTML={{ __html: line.text_he || '' }}
              />
            </div>

            {showNote && noteModalWithOverlay}
          </div>
        </div>

        <div className="mt-4 space-y-4 overflow-y-auto flex-1 no-scrollbar pb-20">
          <div className="flex justify-center">
            <button
              onClick={() => setShowNote(!showNote)}
              className={`flex flex-col items-center justify-center gap-1 p-2 rounded-xl transition-all duration-200 border ${
                showNote 
                  ? 'bg-orange-50 border-orange-200 text-orange-700 shadow-inner' 
                  : 'bg-white border-slate-200 text-slate-600 hover:border-orange-300 hover:text-orange-600 hover:shadow-md'
              }`}
            >
              <Edit3 className="w-5 h-5" />
              <span className="text-xs font-medium">הערה</span>
            </button>
          </div>

          {existingNote && !showNote && (
            <div 
              onClick={() => setShowNote(true)}
              className="p-4 bg-yellow-50 border border-yellow-100 rounded-xl flex items-start gap-3 cursor-pointer hover:bg-yellow-100 transition-all"
            >
              <Edit3 className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
              <div>
                <div className="text-xs font-bold text-yellow-700 uppercase tracking-wider mb-1">הערה שמורה (לחץ לעריכה)</div>
                <div className="text-sm text-slate-700">{existingNote}</div>
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <div className="bg-white/60 backdrop-blur-md rounded-[3rem] p-6 sm:p-10 border border-white shadow-sm h-[55%] flex flex-col overflow-hidden relative">
        <div className="h-full flex flex-col pt-8 overflow-hidden">
          <div className="text-center flex-1 flex flex-col justify-center items-center w-full px-4 overflow-hidden">
            <div
              className={`${getTextItFontClass()} font-bold text-[#3A4031] leading-tight tracking-tight mb-4 transition-all duration-300 w-full max-h-full overflow-y-auto thin-scrollbar`}
              dir="ltr"
              lang="es"
              style={{ textAlign: 'center' }}
              dangerouslySetInnerHTML={{ __html: line.text_it }}
            />
            
            {line.text_en && (
               <div className="mt-2 text-center animate-fadeIn transition-all duration-300 inline-block px-4 py-2 rounded-xl bg-gray-200/50 backdrop-blur-sm" dir="ltr">
                  <div className="text-xl text-[#3A4031] font-medium">{line.text_en}</div>
               </div>
            )}

            {showTranslation && (
              <div className="mt-4 p-4 bg-[#F8F9F7] border border-[#DAD7CD] rounded-2xl animate-fadeIn w-full max-h-[40%] overflow-y-auto thin-scrollbar shadow-sm">
                <div className="text-center" dir="rtl" lang="he">
                  <div 
                    className={`${(line.text_he?.length || 0) > 80 ? 'text-base' : (line.text_he?.length || 0) > 40 ? 'text-lg' : 'text-xl'} text-[#3A4031] font-medium`}
                    dangerouslySetInnerHTML={{ __html: line.text_he || '' }}
                  />
                </div>
              </div>
            )}

            {showNote && noteModalWithOverlay}
            {showSpeech && speechModalWithOverlay}
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col overflow-hidden mt-4">
        <div className="flex-1 overflow-y-auto no-scrollbar space-y-6 px-1">

          {existingNote && !showNote && (
            <div 
              onClick={() => setShowNote(true)}
              className="p-4 bg-[#F2E9E4] border border-[#E9C46A] rounded-xl flex items-start gap-3 cursor-pointer hover:bg-[#E9C46A]/20 transition-all"
            >
              <Edit3 className="w-5 h-5 text-[#E9C46A] mt-0.5 flex-shrink-0" />
              <div>
                <div className="text-xs font-bold text-[#E9C46A] uppercase tracking-wider mb-1">הערה שמורה (לחץ לעריכה)</div>
                <div className="text-sm text-[#3A4031]">{existingNote}</div>
              </div>
            </div>
          )}
        </div>

        <div className="mt-auto pt-4 pb-6">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="flex flex-col items-center gap-1">
              <button
                onClick={() => speakText(line.text_it, 'pt-BR')}
                className="w-20 h-20 bg-blue-50 rounded-[2rem] flex items-center justify-center text-blue-500 shadow-inner hover:scale-105 transition-transform active:scale-95"
                title="השמע בפורטוגזית"
              >
                <Volume2 className="w-8 h-8" />
              </button>
              <span className="text-xs font-bold text-blue-500">פורטוגזית</span>
            </div>
            {line.text_en && (
              <div className="flex flex-col items-center gap-1">
                <button
                  onClick={() => speakText(line.text_en, 'en-US')}
                  className="w-14 h-14 bg-white border border-green-500 rounded-2xl flex items-center justify-center text-green-500 hover:bg-green-50 transition-all shadow-sm"
                  title="השמע באנגלית"
                >
                  <Volume2 className="w-5 h-5" />
                </button>
                <span className="text-xs font-bold text-green-500">אנגלית</span>
              </div>
            )}
          </div>

          <div className="grid grid-cols-3 gap-3">
            <button
              onClick={() => {
                setShowTranslation(!showTranslation);
                setShowSpeech(false);
                setShowNote(false);
              }}
              className={`flex flex-col items-center justify-center gap-1 p-3 rounded-2xl transition-all duration-200 border ${
                showTranslation 
                  ? 'bg-[#A3B18A] border-[#A3B18A] text-white shadow-lg shadow-[#A3B18A]/20' 
                  : 'bg-white border-[#DAD7CD] text-gray-400 hover:border-[#A3B18A] hover:text-[#A3B18A] hover:shadow-md'
              }`}
            >
              <Languages className="w-5 h-5" />
              <span className="text-xs font-bold mt-1">תרגום</span>
            </button>

            <button
              onClick={() => {
                const newShowSpeech = !showSpeech;
                setShowSpeech(newShowSpeech);
                setShowTranslation(false);
                setShowNote(false);
                
                if (newShowSpeech) {
                  // Auto start recording when opening practice mode
                  handleStartRecording();
                } else {
                  handleStopRecording();
                }
              }}
              className={`flex flex-col items-center justify-center gap-1 p-3 rounded-2xl transition-all duration-200 border ${
                showSpeech 
                  ? 'bg-[#E9C46A] border-[#E9C46A] text-white shadow-lg shadow-[#E9C46A]/20' 
                  : 'bg-white border-[#DAD7CD] text-gray-400 hover:border-[#E9C46A] hover:text-[#E9C46A] hover:shadow-md'
              }`}
            >
              <Mic className="w-5 h-5" />
              <span className="text-xs font-bold mt-1">תרגול</span>
            </button>

            <button
              onClick={() => {
                setShowNote(!showNote);
                setShowTranslation(false);
                setShowSpeech(false);
              }}
              className={`flex flex-col items-center justify-center gap-1 p-3 rounded-2xl transition-all duration-200 border ${
                showNote 
                  ? 'bg-[#3A4031] border-[#3A4031] text-white shadow-lg shadow-[#3A4031]/20' 
                  : 'bg-white border-[#DAD7CD] text-gray-400 hover:border-[#3A4031] hover:text-[#3A4031] hover:shadow-md'
              }`}
            >
              <Edit3 className="w-5 h-5" />
              <span className="text-xs font-bold mt-1">הערה</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
