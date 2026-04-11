import { Capacitor } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import { TextToSpeech } from '@capacitor-community/text-to-speech';

export interface SpeechRecognitionResult {
  transcript: string;
  confidence: number;
}

export function isSpeechRecognitionSupported(): boolean {
  if (Capacitor.isNativePlatform()) {
    return true;
  }
  return 'webkitSpeechRecognition' in window || 'SpeechRecognition' in window;
}

export function createSpeechRecognition(language: string = 'pt-BR'): any {
  if (Capacitor.isNativePlatform()) {
    return {
      native: true,
      lang: language,
      cleanup: null,
      lastTranscript: '',
      onFinalResult: null
    };
  }

  if (!isSpeechRecognitionSupported()) {
    return null;
  }

  const SpeechRecognitionAPI = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
  const recognition = new SpeechRecognitionAPI();

  recognition.lang = language;
  recognition.continuous = true;  // Keep listening
  recognition.interimResults = true;  // Get interim results
  recognition.maxAlternatives = 1;

  return recognition;
}

// Estimate speaking duration based on text length (in milliseconds)
// Average speaking rate: ~150 words/min = 2.5 words/sec
// Average word length in Portuguese: ~5 chars
// So roughly 12.5 chars/sec, we add buffer for slower speakers
function estimateSpeakingDuration(text: string): number {
  const plainText = text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
  const charCount = plainText.length;
  // Base: 8 chars per second (slower estimate), minimum 3 seconds, max 30 seconds
  const estimatedSeconds = Math.max(3, Math.min(30, charCount / 8));
  return estimatedSeconds * 1000;
}

export async function startRecording(
  recognition: any,
  onResult: (result: SpeechRecognitionResult) => void,
  onError: (error: string) => void,
  textToMatch?: string
): Promise<void> {
  if (!recognition) {
    onError('זיהוי קולי לא נתמך');
    return;
  }

  if (recognition.native) {
    try {
      // Check permissions
      try {
        const { speechRecognition } = await SpeechRecognition.checkPermissions();
        if (speechRecognition !== 'granted') {
             const status = await SpeechRecognition.requestPermissions();
             if (status.speechRecognition !== 'granted') {
                 onError('נא לאשר גישה למיקרופון בהגדרות המכשיר');
                 return;
             }
        }
      } catch (e) {
          console.warn('Permission check skipped', e);
      }

      // Cleanup previous listener if any
      if (recognition.cleanup) recognition.cleanup();
      
      // Reset transcript storage
      recognition.lastTranscript = '';
      recognition.onFinalResult = onResult;

      // We use 'partialResults' to get updates as the user speaks
      // Store transcript but don't call onResult yet - wait for manual stop
      const listener = await SpeechRecognition.addListener('partialResults', (data: any) => {
        // Android returns { matches: ["text"] }
        // iOS returns { value: ["text"] }
        const transcript = (data.matches && data.matches[0]) || (data.value && data.value[0]);
        
        if (transcript) {
          recognition.lastTranscript = transcript;
          console.log('📝 Partial transcript:', transcript);
        }
      });

      recognition.cleanup = () => {
        listener.remove();
      };

      await SpeechRecognition.start({
        language: recognition.lang,
        maxResults: 5,
        prompt: "דבר עכשיו...", // Android only popup
        partialResults: true,
        popup: false 
      });

    } catch (error: any) {
      console.error('Native speech error:', error);
      onError(error.message || 'שגיאה בזיהוי קולי');
    }
    return;
  }

  // Web Implementation - continuous mode for longer sentences
  let finalTranscript = '';
  
  recognition.onresult = (event: any) => {
    let interimTranscript = '';
    
    for (let i = event.resultIndex; i < event.results.length; i++) {
      const transcript = event.results[i][0].transcript;
      if (event.results[i].isFinal) {
        finalTranscript += transcript;
      } else {
        interimTranscript += transcript;
      }
    }
    
    // Store the transcript for when recording stops
    recognition.lastTranscript = finalTranscript || interimTranscript;
    recognition.onFinalResult = onResult;
    console.log('📝 Web transcript:', recognition.lastTranscript);
  };

  recognition.onerror = (event: any) => {
    let errorMessage = 'שגיאה בזיהוי קולי';
    switch (event.error) {
      case 'no-speech':
        errorMessage = 'לא זוהה דיבור';
        break;
      case 'audio-capture':
        errorMessage = 'לא נמצא מיקרופון';
        break;
      case 'not-allowed':
        errorMessage = 'נא לאשר גישה למיקרופון';
        break;
      default:
        errorMessage = `שגיאה: ${event.error}`;
    }
    onError(errorMessage);
  };

  // Initialize for web
  recognition.lastTranscript = '';
  recognition.onFinalResult = onResult;

  try {
    recognition.start();
  } catch (error) {
    onError('לא ניתן להתחיל הקלטה');
  }
}

export async function stopRecording(recognition: any): Promise<void> {
  if (recognition) {
    if (recognition.native) {
      try {
        await SpeechRecognition.stop();
        if (recognition.cleanup) {
           await recognition.cleanup();
           recognition.cleanup = null;
        }
        
        // Call the final result callback with accumulated transcript
        if (recognition.onFinalResult && recognition.lastTranscript) {
          recognition.onFinalResult({
            transcript: recognition.lastTranscript,
            confidence: 0.9
          });
        }
        
        // Reset
        recognition.lastTranscript = '';
        recognition.onFinalResult = null;
        
      } catch (error) {
        console.error('Error stopping native recognition:', error);
      }
    } else {
      try {
        recognition.stop();
        
        // Call the final result callback with accumulated transcript
        if (recognition.onFinalResult && recognition.lastTranscript) {
          recognition.onFinalResult({
            transcript: recognition.lastTranscript,
            confidence: 0.9
          });
        }
        
        // Reset
        recognition.lastTranscript = '';
        recognition.onFinalResult = null;
        
      } catch (error) {
        console.error('Error stopping recognition:', error);
      }
    }
  }
}

// Web Audio API context for better iOS compatibility
let audioContext: AudioContext | null = null;
let audioUnlocked = false;

function getAudioContext(): AudioContext {
  if (!audioContext) {
    audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
  }
  return audioContext;
}

// Call this on first user interaction (touch/click) to unlock audio on iOS/mobile
// Only runs ONCE to avoid accumulating audio buffer sources
export function unlockAudio(): void {
  if (audioUnlocked) return;
  audioUnlocked = true;
  
  const ctx = getAudioContext();
  if (ctx.state === 'suspended') {
    ctx.resume().then(() => {
      console.log('🔓 AudioContext resumed for mobile');
    });
  }
  
  // Create a silent buffer to fully unlock (only once)
  const buffer = ctx.createBuffer(1, 1, 22050);
  const source = ctx.createBufferSource();
  source.buffer = buffer;
  source.connect(ctx.destination);
  source.start(0);
  source.onended = () => source.disconnect();
  console.log('🔓 Audio unlocked for mobile');
}

// Track current audio to stop/clean previous one before playing new
let currentAudio: HTMLAudioElement | null = null;


const GOOGLE_API_KEY = 'AIzaSyCnhDQbfnpgqyid2nMPaDsW53_rtZt6pWk';

export async function speakText(text: string, language: string = 'pt-BR'): Promise<void> {

  // 1. For Portuguese - ALWAYS try Google Cloud TTS first (even on mobile)
  //    This ensures consistent high-quality pronunciation on all platforms
  if (language === 'pt-BR') {
    try {
      // Clean HTML tags if present
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = text;
      const plainText = tempDiv.textContent || tempDiv.innerText || text;

      const response = await fetch(`https://texttospeech.googleapis.com/v1/text:synthesize?key=${GOOGLE_API_KEY}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          input: { text: plainText },
          voice: { 
            languageCode: 'pt-BR',
            name: 'pt-BR-Neural2-A', // Premium Neural voice
            ssmlGender: 'FEMALE'
          },
          audioConfig: { 
            audioEncoding: 'MP3',
            pitch: 0,
            speakingRate: 1.0
          },
        }),
      });

      if (!response.ok) {
        throw new Error('Google Cloud TTS failed');
      }

      const data = await response.json();
      if (data.audioContent) {
        console.log('🔊 Using Google Cloud Neural Voice (API)');
        // Clean up previous audio to prevent memory leaks
        if (currentAudio) {
          currentAudio.pause();
          currentAudio.removeAttribute('src');
          currentAudio.load();
          currentAudio = null;
        }
        const audio = new Audio(`data:audio/mp3;base64,${data.audioContent}`);
        currentAudio = audio;
        audio.onended = () => {
          audio.removeAttribute('src');
          audio.load();
          if (currentAudio === audio) currentAudio = null;
        };
        audio.onerror = () => {
          audio.removeAttribute('src');
          audio.load();
          if (currentAudio === audio) currentAudio = null;
        };
        await audio.play();
        return;
      }
    } catch (error) {
      console.warn('Google TTS error for Portuguese, falling back to native/browser:', error);
      // Continue to fallbacks below
    }
  }

  // 2. Try Native TTS (Capacitor) for mobile - fallback or non-Portuguese
  if (Capacitor.isNativePlatform()) {
    try {
      // Clean HTML tags if present
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = text;
      const plainText = tempDiv.textContent || tempDiv.innerText || text;
      
      await TextToSpeech.speak({
        text: plainText,
        lang: language,
        rate: 1.0,
        pitch: 1.0,
        volume: 1.0,
        category: 'ambient',
      });
      return; 
    } catch (error) {
      console.warn('Native TTS failed, falling back to browser speech synthesis:', error);
      // Continue to browser fallback below
    }
  }

  // 3. Fallback to Browser Speech Synthesis
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel(); // Cancel previous

    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = text;
    const plainText = tempDiv.textContent || tempDiv.innerText || text;

    const utterance = new SpeechSynthesisUtterance(plainText);
    utterance.lang = language;
    utterance.rate = 0.9;

    if (language === 'en-US') {
      utterance.rate = 0.8;
      const voices = window.speechSynthesis.getVoices();
      const preferredVoice = voices.find(voice => 
        (voice.name.includes('Google US English') || 
         voice.name.includes('Samantha') || 
         voice.name.includes('Microsoft Zira')) && 
        voice.lang.startsWith('en')
      );
      if (preferredVoice) {
        utterance.voice = preferredVoice;
      }
    }

    window.speechSynthesis.speak(utterance);
  }
}
