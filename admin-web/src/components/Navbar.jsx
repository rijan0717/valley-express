import React, { useEffect, useState } from 'react';
import { useSocket } from '../context/SocketContext';
import api from '../api/client';

const Navbar = ({ title, onReplaySplash }) => {
  const { isConnected } = useSocket();
  const [settings, setSettings] = useState(null);

  useEffect(() => {
    api.get('/admin/settings')
      .then((res) => {
        if (res.data.success) {
          setSettings(res.data.settings);
        }
      })
      .catch((err) => console.log('Settings error:', err.message));
  }, []);

  return (
    <header className="top-navbar">
      <div className="navbar-left">
        <h2 className="navbar-title">{title || 'Control Center'}</h2>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
        {onReplaySplash && (
          <button
            onClick={onReplaySplash}
            className="btn btn-secondary btn-sm"
            title="Replay the official animated logo sequence"
          >
            Play Intro Animation
          </button>
        )}

        {settings && (
          <div
            className={`badge ${settings.alcoholEnabled ? 'badge-accent' : 'badge-neutral'}`}
            style={{ fontSize: '11px', padding: '6px 10px' }}
          >
            {settings.alcoholEnabled ? 'Alcohol Sales Enabled' : 'Alcohol Disabled (Licence Pending)'}
          </div>
        )}

        <div
          className={`badge ${isConnected ? 'badge-brand' : 'badge-neutral'}`}
          style={{ fontSize: '11px', padding: '6px 10px' }}
        >
          {isConnected ? 'Socket Connected' : 'Sync Disconnected'}
        </div>

        <div style={{ fontSize: '12px', color: '#1F2A44', fontWeight: 500 }}>
          Kathmandu Valley
        </div>
      </div>
    </header>
  );
};

export default Navbar;
