import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { LogoFull } from '../components/Logo';
import ValleyLoader from '../components/ValleyLoader';

const Login = () => {
  const [email, setEmail] = useState('admin@gmail.com');
  const [password, setPassword] = useState('Password@123');
  const [error, setError] = useState('');
  const { login, loading } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    const res = await login(email, password);
    if (res.success) {
      navigate('/');
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

            <div className="form-group" style={{ marginBottom: '24px' }}>
              <label className="form-label">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password@123"
                autoComplete="current-password"
              />
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
