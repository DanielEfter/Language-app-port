import { useState } from 'react';
import { LogIn, UserPlus, Shield, Eye, EyeOff } from 'lucide-react';
import { login, register } from '../lib/auth';
import { useAuth } from '../contexts/AuthContext';

type Mode = 'login' | 'register' | 'admin';

export default function LoginScreen() {
  const [mode, setMode] = useState<Mode>('login');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { setUser } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!username.trim() || !password.trim()) {
      setError('נא למלא את כל השדות');
      return;
    }

    if (mode === 'register') {
      if (password.length < 8) {
        setError('הסיסמה חייבת להכיל לפחות 8 תווים');
        return;
      }
      if (password !== confirmPassword) {
        setError('הסיסמאות אינן תואמות');
        return;
      }
    }

    setLoading(true);

    try {
      if (mode === 'register') {
        const user = await register(username, password);
        if (user) {
          setUser(user);
        }
      } else {
        const user = await login(username, password);

        if (!user) {
          setError('שם משתמש או סיסמה שגויים');
        } else if (mode === 'admin' && user.role !== 'ADMIN') {
          setError('אין הרשאת מנהל למשתמש זה');
        } else {
          setUser(user);
        }
      }
    } catch (err: any) {
      setError(err.message || 'שגיאה בהתחברות');
    } finally {
      setLoading(false);
    }
  };

  const getTitle = () => {
    switch (mode) {
      case 'register':
        return 'יצירת חשבון חדש';
      case 'admin':
        return 'כניסה למנהל';
      default:
        return 'ברוך הבא';
    }
  };

  const getButtonText = () => {
    switch (mode) {
      case 'register':
        return 'יצירת חשבון';
      case 'admin':
        return 'כניסה לאדמין';
      default:
        return 'כניסה';
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center p-4 relative overflow-hidden safe-top safe-bottom" dir="rtl">
      {/* Background decoration */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-100/40 rounded-full blur-3xl mix-blend-multiply animate-blob"></div>
        <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-indigo-100/40 rounded-full blur-3xl mix-blend-multiply animate-blob animation-delay-2000"></div>
      </div>

      <div className="w-full max-w-md relative z-10">
        <div className="bg-white/80 backdrop-blur-xl rounded-3xl shadow-2xl shadow-blue-900/10 p-8 border border-white/50">
          <div className="text-center mb-10">
            {mode === 'admin' ? (
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl shadow-lg shadow-blue-500/30 mb-6 transform rotate-3 hover:rotate-6 transition-transform duration-300">
                <Shield className="w-10 h-10 text-white" />
              </div>
            ) : mode === 'register' ? (
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl shadow-lg shadow-blue-500/30 mb-6 transform rotate-3 hover:rotate-6 transition-transform duration-300">
                <UserPlus className="w-10 h-10 text-white" />
              </div>
            ) : (
              <img src="/logo.png" alt="Logo" className="w-32 h-32 object-contain mx-auto mb-6" />
            )}
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">{getTitle()}</h1>
            <p className="text-slate-500 mt-2">קורס ספרדית למתחילים</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-4">
              <div>
                <label htmlFor="username" className="block text-sm font-medium text-slate-700 mb-1.5">
                  שם משתמש
                </label>
                <input
                  id="username"
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all text-slate-900 placeholder-slate-400"
                  placeholder="שם משתמש"
                  disabled={loading}
                  dir="auto"
                />
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium text-slate-700 mb-1.5">
                  סיסמה
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all text-slate-900 placeholder-slate-400"
                    placeholder="סיסמה"
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {mode === 'register' && (
                <div>
                  <label htmlFor="confirmPassword" className="block text-sm font-medium text-slate-700 mb-1.5">
                    אימות סיסמה
                  </label>
                  <input
                    id="confirmPassword"
                    type={showPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all text-slate-900 placeholder-slate-400"
                    placeholder="אימות סיסמה"
                    disabled={loading}
                  />
                </div>
              )}
            </div>

            {error && (
              <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-xl text-sm flex items-center gap-2 animate-shake">
                <div className="w-1.5 h-1.5 bg-red-500 rounded-full"></div>
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold py-3.5 px-4 rounded-xl hover:shadow-lg hover:shadow-blue-600/30 focus:ring-4 focus:ring-blue-600/20 transition-all transform active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed mt-2"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  מתחבר...
                </span>
              ) : (
                getButtonText()
              )}
            </button>
          </form>

          <div className="mt-8 flex items-center justify-between pt-6 border-t border-slate-100">
            {mode === 'login' ? (
              <>
                <button
                  onClick={() => {
                    setMode('register');
                    setError('');
                  }}
                  className="text-sm text-slate-500 hover:text-blue-600 font-medium transition-colors"
                >
                  אין לך חשבון? הירשם
                </button>
                <button
                  onClick={() => {
                    setMode('admin');
                    setError('');
                  }}
                  className="text-sm text-slate-400 hover:text-slate-600 transition-colors"
                >
                  כניסה למנהל
                </button>
              </>
            ) : (
              <button
                onClick={() => {
                  setMode('login');
                  setError('');
                }}
                className="text-sm text-slate-500 hover:text-blue-600 font-medium transition-colors w-full text-center"
              >
                יש לך כבר חשבון? התחבר
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
