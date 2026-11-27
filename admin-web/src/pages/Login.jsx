import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Navigate, useNavigate } from 'react-router-dom';
import { LogoFull } from '../components/Logo';
import ValleyLoader from '../components/ValleyLoader';

const Login = () => {
  const [email, setEmail] = useState(() => localStorage.getItem('valley_remember_email') || '');
  // The password is never read from, or written to, storage. Keeping it in
  // localStorage left the admin password in clear text on the machine, where
  // any script on the page (or anyone at the keyboard) could read it.
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(() => localStorage.getItem('valley_remember_me') === 'true');

  // Remove any password left behind by an older build of this page.
  React.useEffect(() => {
    localStorage.removeItem('valley_remember_password');
  }, []);
  const [error, setError] = useState('');
  const { login, loading, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  // Somebody already signed in has no business on the sign-in page.
  if (isAuthenticated) {
    return <Navigate to="/admin" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    // Validate before spending a round trip on the API
    if (!email.trim()) {
      setError('Enter the admin email address.');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setError('Enter a valid email address, for example admin@gmail.com.');
      return;
    }
    if (!password) {
      setError('Enter your password.');
      return;
    }

    const res = await login(email, password);
    if (res.success) {
      if (rememberMe) {
        // Remember the email to save typing — never the password.
        localStorage.setItem('valley_remember_me', 'true');
        localStorage.setItem('valley_remember_email', email.trim());
      } else {
        localStorage.removeItem('valley_remember_me');
        localStorage.removeItem('valley_remember_email');
      }
      navigate('/admin');
    } else {
      setError(res.message);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#FFFFFF',
        padding: '24px',
      }}
    >
      <div
        style={{
          background: '#FFFFFF',
          border: '1px solid #D1D5DB',
          borderRadius: '4px',
          maxWidth: '420px',
          width: '100%',
          padding: '36px 32px',
        }}
      >
        {/* Official Brand Logo */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '8px' }}>
            <LogoFull height={52} />
          </div>
          <p style={{ fontSize: '12px', fontWeight: 500, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.8px' }}>
            Operations Command Center
          </p>
        </div>

        {error && (
          <div
            style={{
              background: '#FFFFFF',
              border: '1px solid #FF6B1A',
              color: '#FF6B1A',
              padding: '10px 14px',
              borderRadius: '4px',
              fontSize: '13px',
              fontWeight: 500,
              marginBottom: '20px',
              textAlign: 'center',
            }}
          >
            {error}
          </div>
        )}

        {loading ? (
          <ValleyLoader text="Authenticating admin credentials..." size="sm" />
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Admin Email</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@gmail.com"
                autoComplete="email"
              />
            </div>

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label className="form-label">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                autoComplete="current-password"
              />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '22px' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '13px', color: '#1F2A44', fontWeight: 500, userSelect: 'none' }}>
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  style={{ width: '16px', height: '16px', accentColor: '#003893', cursor: 'pointer' }}
                />
                <span>Remember Me</span>
              </label>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn btn-primary"
              style={{ width: '100%' }}
            >
              Sign In to Operations
            </button>
          </form>
        )}

        <div
          style={{
            marginTop: '28px',
            paddingTop: '16px',
            borderTop: '1px solid #D1D5DB',
            textAlign: 'center',
            fontSize: '11px',
            color: '#1F2A44',
          }}
        >
          Valley Express v1.0 • Kathmandu Valley
        </div>
      </div>
    </div>
  );
};

export default Login;
