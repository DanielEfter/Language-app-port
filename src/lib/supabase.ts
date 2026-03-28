import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://imjgijjwydjzprqzxune.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltamdpamp3eWRqenBycXp4dW5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNjIxNzcsImV4cCI6MjA4NjkzODE3N30.X18D_qKEPz6zjOCK_ynsTJI1sTiV5IBA7pFsENBDu7g';

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);
