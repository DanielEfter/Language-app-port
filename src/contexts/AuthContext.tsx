import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import type { User } from '../lib/database.types';
import { getUserFromStorage, saveUserToStorage, clearUserFromStorage } from '../lib/auth';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  setUser: (user: User | null) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUserState] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const stored = getUserFromStorage();
    setUserState(stored);
    setLoading(false);
  }, []); // Only run once on mount

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        const currentUser = getUserFromStorage();
        if (currentUser && (!user || user.id !== currentUser.id)) {
          setUserState(currentUser);
        }
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleVisibilityChange);
    };
  }, [user]);

  const setUser = (user: User | null) => {
    setUserState(user);
    if (user) {
      saveUserToStorage(user);
    } else {
      clearUserFromStorage();
    }
  };

  const logout = () => {
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, setUser, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
