import { useState } from 'react';
import { Shield, Users, BookOpen, BarChart3, LogOut, MessageSquare, Menu, X, ChevronLeft, ChevronDown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import UserManagement from './admin/UserManagement';
import LessonManagement from './admin/LessonManagement';
import ProgressTracking from './admin/ProgressTracking';
import StudentNotes from './admin/StudentNotes';

type Tab = 'users' | 'lessons' | 'progress' | 'notes';

export default function AdminDashboard() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>('progress');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);

  const tabs = [
    { id: 'progress' as Tab, label: 'אנליטיקה', icon: BarChart3, description: 'מעקב התקדמות תלמידים' },
    { id: 'notes' as Tab, label: 'הערות תלמידים', icon: MessageSquare, description: 'משובים והערות אישיות' },
    { id: 'lessons' as Tab, label: 'ניהול שיעורים', icon: BookOpen, description: 'עריכת תוכן ומבנה השיעורים' },
    { id: 'users' as Tab, label: 'ניהול משתמשים', icon: Users, description: 'הוספה וניהול תלמידים' },
  ];

  const activeTabInfo = tabs.find(t => t.id === activeTab);

  return (
    <div className="flex h-screen bg-[#f8fafc] overflow-hidden font-sans text-slate-900" dir="rtl">
      {/* Background Elements */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute top-[-10%] right-[-5%] w-[500px] h-[500px] rounded-full bg-blue-400/10 blur-[100px]" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[500px] h-[500px] rounded-full bg-indigo-400/10 blur-[100px]" />
      </div>

      {/* Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`
          fixed lg:static inset-y-0 right-0 z-50 w-72 bg-white/80 backdrop-blur-2xl border-l border-white/50 shadow-[0_0_40px_-10px_rgba(0,0,0,0.05)]
          transform transition-transform duration-300 ease-out
          ${isSidebarOpen ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'}
          flex flex-col
        `}
      >
        {/* Sidebar Header */}
        <div className="p-6 flex items-center gap-4 border-b border-slate-100/50">
          <div className="relative group">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl blur opacity-40 group-hover:opacity-60 transition-opacity" />
            <div className="relative p-3 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl shadow-lg text-white">
              <Shield className="w-6 h-6" />
            </div>
          </div>
          <div>
            <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700">
              לוח בקרה
            </h1>
            <p className="text-xs text-slate-500 font-medium tracking-wide">ADMIN PORTAL</p>
          </div>
          <button 
            onClick={() => setIsSidebarOpen(false)}
            className="lg:hidden mr-auto p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          <div className="text-xs font-semibold text-slate-400 px-4 py-2 uppercase tracking-wider">תפריט ראשי</div>
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => {
                  setActiveTab(tab.id);
                  setIsSidebarOpen(false);
                }}
                className={`
                  w-full flex items-center gap-3 px-4 py-3.5 rounded-2xl transition-all duration-200 group relative overflow-hidden
                  ${isActive 
                    ? 'bg-blue-50/80 text-blue-600 shadow-sm' 
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                  }
                `}
              >
                {isActive && (
                  <div className="absolute right-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-blue-500 rounded-l-full" />
                )}
                <Icon className={`w-5 h-5 transition-colors ${isActive ? 'text-blue-600' : 'text-slate-400 group-hover:text-slate-600'}`} />
                <span className="font-medium">{tab.label}</span>
                {isActive && <ChevronLeft className="w-4 h-4 mr-auto text-blue-400" />}
              </button>
            );
          })}
        </nav>

        {/* User Profile */}
        <div className="p-4 border-t border-slate-100/50 bg-white/50">
          <div className="bg-slate-50/80 rounded-2xl border border-white/50 shadow-sm overflow-hidden">
            <button 
              onClick={() => setIsProfileOpen(!isProfileOpen)}
              className="w-full flex items-center gap-3 p-4 hover:bg-slate-100/50 transition-colors text-right"
            >
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center text-slate-600 font-bold shadow-inner shrink-0">
                {user?.username?.[0]?.toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-bold text-slate-900 truncate">{user?.username}</div>
                <div className="text-xs text-blue-600 font-medium">מנהל מערכת</div>
              </div>
              <ChevronDown className={`w-5 h-5 text-slate-400 transition-transform duration-200 ${isProfileOpen ? 'rotate-180' : ''}`} />
            </button>
            
            {isProfileOpen && (
              <div className="p-2 pt-0 border-t border-slate-100/50">
                <button
                  onClick={() => {
                    if (confirm('האם אתה בטוח שברצונך לצאת מהאפליקציה?')) {
                      logout();
                    }
                  }}
                  className="w-full flex items-center justify-center gap-2 p-2.5 text-sm text-red-600 hover:bg-red-50 rounded-xl transition-colors font-medium mt-2"
                >
                  <LogOut className="w-4 h-4" />
                  <span>התנתק</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 relative z-10 h-screen overflow-hidden">
        {/* Top Bar */}
        <header className="h-20 px-8 flex items-center justify-between bg-white/50 backdrop-blur-sm border-b border-white/50 sticky top-0 z-30">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsSidebarOpen(true)}
              className="lg:hidden p-2 -mr-2 text-slate-500 hover:bg-slate-100 rounded-lg"
            >
              <Menu className="w-6 h-6" />
            </button>
            <div>
              <h2 className="text-2xl font-bold text-slate-900">{activeTabInfo?.label}</h2>
              <p className="text-sm text-slate-500 hidden sm:block">{activeTabInfo?.description}</p>
            </div>
          </div>
          
          {/* Quick Actions / Status (Placeholder) */}
          <div className="flex items-center gap-3">
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-full text-xs font-medium border border-emerald-100">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              מערכת פעילה
            </div>
          </div>
        </header>

        {/* Content Scroll Area */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-8 scroll-smooth">
          <div className="max-w-6xl mx-auto">
            <div className="bg-white/60 backdrop-blur-xl rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white/60 p-6 sm:p-8 min-h-[calc(100vh-10rem)] animate-in fade-in slide-in-from-bottom-4 duration-500">
              {activeTab === 'progress' && <ProgressTracking />}
              {activeTab === 'notes' && <StudentNotes />}
              {activeTab === 'lessons' && <LessonManagement />}
              {activeTab === 'users' && <UserManagement />}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
