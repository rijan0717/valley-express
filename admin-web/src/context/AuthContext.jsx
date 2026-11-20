import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../api/client';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('valley_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem('valley_token') || null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // If we have token, verify profile with /api/auth/me
    if (token) {
      api.get('/auth/me')
        .then((res) => {
          if (res.data.success && res.data.user) {
            setUser(res.data.user);
            localStorage.setItem('valley_user', JSON.stringify(res.data.user));
          }
        })
        .catch(() => {
          // Keep existing local user in dev or clear on invalid
        });
    }
  }, [token]);

  const login = async (email, password) => {
    setLoading(true);
    try {
      const res = await api.post('/auth/admin-login', {
        email: email.trim(),
        password,
      });
      if (res.data.success) {
        setToken(res.data.token);
        setUser(res.data.user);
        localStorage.setItem('valley_token', res.data.token);
        localStorage.setItem('valley_user', JSON.stringify(res.data.user));
        return { success: true };
      }
      return { success: false, message: res.data.message };
    } catch (err) {
      return {
        success: false,
        message: err.response?.data?.message || 'Login failed. Please verify credentials.',
      };
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('valley_token');
    localStorage.removeItem('valley_user');
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!user,
        login,
        logout,
        loading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
