import { supabase } from './supabase';
import type { User } from './database.types';

async function simpleHash(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function hashPassword(password: string): Promise<string> {
  return simpleHash(password + 'salt_italian_2024');
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  const computedHash = await hashPassword(password);
  return computedHash === hash;
}

export async function login(username: string, password: string): Promise<User | null> {
  const { data, error } = await supabase.rpc('verify_user_login', {
    p_username: username,
    p_password: password,
  });

  if (error || !data || data.length === 0) {
    return null;
  }

  return data[0] as User;
}

export async function register(username: string, password: string): Promise<User | null> {
  const { data: existing } = await supabase
    .from('users')
    .select('id')
    .eq('username', username)
    .maybeSingle();

  if (existing) {
    throw new Error('שם משתמש כבר תפוס');
  }

  const { data: userId, error } = await supabase.rpc('create_user', {
    p_username: username,
    p_password: password,
    p_role: 'STUDENT',
  });

  if (error) {
    throw new Error('שגיאה ביצירת חשבון');
  }

  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  return user;
}

export function saveUserToStorage(user: User): void {
  localStorage.setItem('currentUser', JSON.stringify(user));
}

export function getUserFromStorage(): User | null {
  const stored = localStorage.getItem('currentUser');
  if (!stored) return null;
  try {
    return JSON.parse(stored);
  } catch {
    return null;
  }
}

export function clearUserFromStorage(): void {
  localStorage.removeItem('currentUser');
}
