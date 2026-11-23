import React, { useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import OrdersBoard from './pages/OrdersBoard';
import Products from './pages/Products';
import Offers from './pages/Offers';
import Riders from './pages/Riders';
import Users from './pages/Users';
import Coins from './pages/Coins';
import Chat from './pages/Chat';
import Issues from './pages/Issues';
import Settings from './pages/Settings';
import MobilePreview from './pages/MobilePreview';
import Login from './pages/Login';
import ProtectedRoute from './routes/ProtectedRoute';
import SplashScreenAnimation from './components/SplashScreenAnimation';
import { useAuth } from './context/AuthContext';
import { LayoutProvider, useLayout } from './context/LayoutContext';

function AppShell() {
  const { isAuthenticated } = useAuth();
  const { sidebarOpen, closeSidebar } = useLayout();
  const [showSplashOverlay, setShowSplashOverlay] = useState(false);

  return (
    <div className="app-container">
      {/* First-time Animated Splash Screen (From Main.dc.html) */}
      <SplashScreenAnimation
        showAlways={showSplashOverlay}
        onFinish={() => setShowSplashOverlay(false)}
      />

      {isAuthenticated && (
        <>
          <Sidebar isOpen={sidebarOpen} onNavigate={closeSidebar} />
          {/* Tapping away closes the drawer, as a drawer should. */}
          <div
            className={'sidebar-backdrop' + (sidebarOpen ? ' is-open' : '')}
            onClick={closeSidebar}
          />
        </>
      )}
      <main className="main-content">
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Dashboard onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/orders"
            element={
              <ProtectedRoute>
                <OrdersBoard onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/products"
            element={
              <ProtectedRoute>
                <Products onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/offers"
            element={
              <ProtectedRoute>
                <Offers onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/riders"
            element={
              <ProtectedRoute>
                <Riders onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/users"
            element={
              <ProtectedRoute>
                <Users onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coins"
            element={
              <ProtectedRoute>
                <Coins onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/chat"
            element={
              <ProtectedRoute>
                <Chat onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/issues"
            element={
              <ProtectedRoute>
                <Issues onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/settings"
            element={
              <ProtectedRoute>
                <Settings onReplaySplash={() => setShowSplashOverlay(true)} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/mobile-preview"
            element={<MobilePreview onReplaySplash={() => setShowSplashOverlay(true)} />}
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

// The provider has to sit outside the shell, since the shell is what reads
// the sidebar state it holds.
function App() {
  return (
    <LayoutProvider>
      <AppShell />
    </LayoutProvider>
  );
}

export default App;
