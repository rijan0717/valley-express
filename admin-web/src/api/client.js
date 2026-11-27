import axios from 'axios';

const TOKEN_KEY = 'valley_token';
const REFRESH_KEY = 'valley_refresh_token';
const USER_KEY = 'valley_user';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach the short-lived access token to every outgoing request.
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

const clearSession = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
};

const redirectToLogin = () => {
  if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
    window.location.href = '/login';
  }
};

// A single in-flight refresh shared by every request that hits a 401 at once,
// so a burst of expired-token responses triggers one refresh, not many.
let refreshPromise = null;

const refreshAccessToken = async () => {
  const refreshToken = localStorage.getItem(REFRESH_KEY);
  if (!refreshToken) return null;
  // Bare axios (not `api`) so this call does not recurse through this
  // interceptor.
  const res = await axios.post(
    `${api.defaults.baseURL}/auth/refresh`,
    { refreshToken },
    { headers: { 'Content-Type': 'application/json' } }
  );
  if (res.data?.success && res.data.token) {
    localStorage.setItem(TOKEN_KEY, res.data.token);
    if (res.data.refreshToken) localStorage.setItem(REFRESH_KEY, res.data.refreshToken);
    if (res.data.user) localStorage.setItem(USER_KEY, JSON.stringify(res.data.user));
    return res.data.token;
  }
  return null;
};

// On a 401, try once to silently renew the access token with the refresh
// token and replay the original request. Only if that fails do we clear the
// session and bounce to the login page.
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config;
    const status = error.response?.status;
    const isRefreshCall = original?.url?.includes('/auth/refresh');

    if (status === 401 && original && !original._retried && !isRefreshCall) {
      original._retried = true;
      try {
        refreshPromise = refreshPromise || refreshAccessToken();
        const newToken = await refreshPromise;
        refreshPromise = null;
        if (newToken) {
          original.headers = original.headers || {};
          original.headers.Authorization = `Bearer ${newToken}`;
          return api(original);
        }
      } catch {
        refreshPromise = null;
      }
      clearSession();
      redirectToLogin();
    }
    return Promise.reject(error);
  }
);

export default api;
