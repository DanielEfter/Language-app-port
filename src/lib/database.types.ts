export type UserRole = 'ADMIN' | 'STUDENT';
export type LineType = 'INFO' | 'LINK' | 'LANG';

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          username: string;
          password_hash: string;
          role: UserRole;
          is_active: boolean;
          current_lesson_id: string | null;
          city: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          username: string;
          password_hash: string;
          role?: UserRole;
          is_active?: boolean;
          current_lesson_id?: string | null;
          city?: string;
          created_at?: string;
        };
        Update: {
          username?: string;
          password_hash?: string;
          role?: UserRole;
          is_active?: boolean;
          current_lesson_id?: string | null;
          city?: string;
        };
      };
      lessons: {
        Row: {
          id: string;
          index: number;
          title: string;
          description: string;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          index: number;
          title: string;
          description?: string;
          is_published?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          index?: number;
          title?: string;
          description?: string;
          is_published?: boolean;
          updated_at?: string;
        };
      };
      lines: {
        Row: {
          id: string;
          lesson_id: string;
          order_num: number;
          code: string;
          type: LineType;
          text_he: string;
          text_en: string;
          text_it: string;
          stress_rule: string;
          recording_hint: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          lesson_id: string;
          order_num: number;
          code: string;
          type: LineType;
          text_he?: string;
          text_en?: string;
          text_it?: string;
          stress_rule?: string;
          recording_hint?: string;
          created_at?: string;
        };
        Update: {
          order_num?: number;
          code?: string;
          type?: LineType;
          text_he?: string;
          text_en?: string;
          text_it?: string;
          stress_rule?: string;
          recording_hint?: string;
        };
      };
      notes: {
        Row: {
          id: string;
          user_id: string;
          line_id: string;
          content: string;
          share_with_admin: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          line_id: string;
          content: string;
          share_with_admin?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          content?: string;
          share_with_admin?: boolean;
          updated_at?: string;
        };
      };
      progress: {
        Row: {
          id: string;
          user_id: string;
          lesson_id: string;
          last_line_order: number;
          is_completed: boolean;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          lesson_id: string;
          last_line_order?: number;
          is_completed?: boolean;
          updated_at?: string;
        };
        Update: {
          last_line_order?: number;
          is_completed?: boolean;
          updated_at?: string;
        };
      };
      speech_attempts: {
        Row: {
          id: string;
          user_id: string;
          line_id: string;
          transcript: string;
          similarity_score: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          line_id: string;
          transcript: string;
          similarity_score?: number;
          created_at?: string;
        };
      };
    };
    Functions: {
      verify_user_login: {
        Args: {
          p_username: string;
          p_password: string;
        };
        Returns: {
          id: string;
          username: string;
          role: UserRole;
          is_active: boolean;
          current_lesson_id: string | null;
          city: string;
        }[];
      };
      create_user: {
        Args: {
          p_username: string;
          p_password: string;
          p_role?: string;
        };
        Returns: string;
      };
    };
  };
}

export type User = Database['public']['Tables']['users']['Row'];
export type Lesson = Database['public']['Tables']['lessons']['Row'];
export type Line = Database['public']['Tables']['lines']['Row'];
export type Note = Database['public']['Tables']['notes']['Row'];
export type Progress = Database['public']['Tables']['progress']['Row'];
export type SpeechAttempt = Database['public']['Tables']['speech_attempts']['Row'];
