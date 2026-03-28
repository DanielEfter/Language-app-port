import { useState, useEffect } from 'react';
import { UserPlus, Edit, Trash2, Lock, Unlock, RefreshCw } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { User } from '../../lib/database.types';

export default function UserManagement() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [newUsername, setNewUsername] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newRole, setNewRole] = useState<'STUDENT' | 'ADMIN'>('STUDENT');
  const [error, setError] = useState('');

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    const { data } = await supabase.from('users').select('*').order('created_at', { ascending: false });
    if (data) setUsers(data);
    setLoading(false);
  };

  const handleCreateUser = async () => {
    setError('');
    if (!newUsername.trim() || !newPassword.trim()) {
      setError('נא למלא את כל השדות');
      return;
    }
    if (newPassword.length < 8) {
      setError('הסיסמה חייבת להכיל לפחות 8 תווים');
      return;
    }

    const { error: dbError } = await supabase.rpc('create_user', {
      p_username: newUsername,
      p_password: newPassword,
      p_role: newRole,
    });

    if (dbError) {
      setError(dbError.message.includes('duplicate') ? 'שם משתמש כבר קיים' : 'שגיאה ביצירת משתמש');
      return;
    }

    setShowCreate(false);
    setNewUsername('');
    setNewPassword('');
    setNewRole('STUDENT');
    loadUsers();
  };

  const toggleUserStatus = async (userId: string, currentStatus: boolean) => {
    await supabase.rpc('toggle_user_status', { p_user_id: userId });
    loadUsers();
  };

  const deleteUser = async (userId: string) => {
    if (!confirm('האם למחוק משתמש זה? לא ניתן לשחזר.')) return;
    await supabase.rpc('delete_user_by_id', { p_user_id: userId });
    loadUsers();
  };

  const changeRole = async (userId: string, newRole: 'STUDENT' | 'ADMIN') => {
    await supabase.rpc('update_user_role', { p_user_id: userId, p_new_role: newRole });
    loadUsers();
  };

  const resetPassword = async (userId: string) => {
    const newPass = prompt('הזן סיסמה חדשה (לפחות 8 תווים):');
    if (!newPass || newPass.length < 8) {
      alert('סיסמה לא תקינה');
      return;
    }
    await supabase.rpc('update_user_password', { p_user_id: userId, p_new_password: newPass });
    alert('הסיסמה אופסה בהצלחה');
  };

  const updateUserCity = async (userId: string, city: string) => {
    await supabase.from('users').update({ city }).eq('id', userId);
    loadUsers();
    setEditingUser(null);
  };

  if (loading) {
    return <div className="text-center py-8">טוען...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">ניהול משתמשים</h2>
          <p className="text-sm text-gray-600 mt-1">סך הכל {users.length} משתמשים במערכת</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
        >
          <UserPlus className="w-5 h-5" />
          <span>משתמש חדש</span>
        </button>
      </div>

      {showCreate && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
          <h3 className="font-semibold text-blue-900 mb-4">יצירת משתמש חדש</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">שם משתמש</label>
              <input
                type="text"
                value={newUsername}
                onChange={(e) => setNewUsername(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="שם משתמש ייחודי"
                dir="auto"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">סיסמה</label>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="לפחות 8 תווים"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">תפקיד</label>
              <select
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as 'STUDENT' | 'ADMIN')}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="STUDENT">תלמיד</option>
                <option value="ADMIN">מנהל</option>
              </select>
            </div>
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-2 rounded-lg text-sm">
                {error}
              </div>
            )}
            <div className="flex gap-3">
              <button
                onClick={handleCreateUser}
                className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
              >
                צור משתמש
              </button>
              <button
                onClick={() => {
                  setShowCreate(false);
                  setError('');
                }}
                className="px-6 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-lg transition-colors"
              >
                ביטול
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">שם משתמש</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">עיר</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">תפקיד</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">סטטוס</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">תאריך יצירה</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-700 uppercase">פעולות</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="font-medium text-gray-900">{user.username}</div>
                </td>
                <td className="px-6 py-4">
                  {editingUser?.id === user.id ? (
                    <div className="flex gap-2">
                      <input
                        type="text"
                        defaultValue={user.city}
                        onBlur={(e) => updateUserCity(user.id, e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            updateUserCity(user.id, e.currentTarget.value);
                          } else if (e.key === 'Escape') {
                            setEditingUser(null);
                          }
                        }}
                        autoFocus
                        className="text-sm px-2 py-1 border border-blue-300 rounded focus:ring-2 focus:ring-blue-500 w-32"
                        dir="auto"
                      />
                    </div>
                  ) : (
                    <div
                      onClick={() => setEditingUser(user)}
                      className="text-sm text-gray-700 cursor-pointer hover:text-blue-600 hover:underline"
                      dir="auto"
                    >
                      {user.city || 'הוסף עיר'}
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  <select
                    value={user.role}
                    onChange={(e) => changeRole(user.id, e.target.value as 'STUDENT' | 'ADMIN')}
                    className="text-sm px-3 py-1 border border-gray-300 rounded-lg"
                  >
                    <option value="STUDENT">תלמיד</option>
                    <option value="ADMIN">מנהל</option>
                  </select>
                </td>
                <td className="px-6 py-4">
                  <span
                    className={`inline-flex px-3 py-1 text-xs font-medium rounded-full ${
                      user.is_active
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {user.is_active ? 'פעיל' : 'חסום'}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-600">
                  {new Date(user.created_at).toLocaleDateString('he-IL')}
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => resetPassword(user.id)}
                      className="p-2 hover:bg-blue-100 text-blue-600 rounded-lg transition-colors"
                      title="אפס סיסמה"
                    >
                      <RefreshCw className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => toggleUserStatus(user.id, user.is_active)}
                      className="p-2 hover:bg-gray-100 text-gray-600 rounded-lg transition-colors"
                      title={user.is_active ? 'חסום' : 'בטל חסימה'}
                    >
                      {user.is_active ? <Lock className="w-4 h-4" /> : <Unlock className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => deleteUser(user.id)}
                      className="p-2 hover:bg-red-100 text-red-600 rounded-lg transition-colors"
                      title="מחק"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
