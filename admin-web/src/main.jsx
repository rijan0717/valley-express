import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './index.css';
import { AuthProvider } from './context/AuthContext';

// Only the auth context is global, because the sign-in state decides which of
// the two applications a visitor is allowed into. The socket, modal and chat
// providers belong to the dashboard alone and are mounted with it in App.jsx —
// a visitor reading the public site should not be holding a websocket open.
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>
);
