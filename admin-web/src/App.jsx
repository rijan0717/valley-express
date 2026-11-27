import React, { Suspense, lazy, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './routes/ProtectedRoute';
import ValleyLoader from './components/ValleyLoader';
import { useLayout } from './context/LayoutContext';
import { useAuth } from './context/AuthContext';

// The dashboard is loaded on demand. A visitor reading the public site should
// not download the operations screens, the chat client or the map pickers that
// come with them — it is the bulk of the bundle and none of it is theirs.
const Sidebar = lazy(() => import('./components/Sidebar'));
const SplashScreenAnimation = lazy(() => import('./components/SplashScreenAnimation'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const OrdersBoard = lazy(() => import('./pages/OrdersBoard'));
const Products = lazy(() => import('./pages/Products'));
const Offers = lazy(() => import('./pages/Offers'));
const Riders = lazy(() => import('./pages/Riders'));
const Users = lazy(() => import('./pages/Users'));
const Coins = lazy(() => import('./pages/Coins'));
const Chat = lazy(() => import('./pages/Chat'));
const Issues = lazy(() => import('./pages/Issues'));
const Settings = lazy(() => import('./pages/Settings'));
const Enquiries = lazy(() => import('./pages/Enquiries'));
const Login = lazy(() => import('./pages/Login'));
const AdminProviders = lazy(() => import('./routes/AdminProviders'));

// Public marketing site
import SiteLayout from './site/components/SiteLayout';
import Home from './site/pages/Home';
import About from './site/pages/About';
import Blog from './site/pages/Blog';
import BlogPost from './site/pages/BlogPost';
import Contact from './site/pages/Contact';
import NotFound from './site/pages/NotFound';
import LegalPage from './site/pages/LegalPage';
import './site/site.css';

/**
 * Two applications share one bundle:
 *
 *   /            the public website customers see and search engines index
 *   /admin/*     the operations dashboard, behind ProtectedRoute
 *   /login       the staff sign-in, reachable only by typing the address
 *
 * Nothing on the public side links to /login or /admin by design — the
 * dashboard is staff software and does not advertise itself to visitors.
 */

// Dashboard pages used to live at the root. Anything bookmarked back then is
// forwarded rather than dropped on the public 404.
const LEGACY_ADMIN_PATHS = [
  'orders',
  'products',
  'offers',
  'riders',
  'users',
  'coins',
  'chat',
  'issues',
  'settings',
  'enquiries',
];

/** Shown for the moment it takes the dashboard chunk to arrive. */
const AdminChunkLoader = () => (
  <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center' }}>
    <ValleyLoader text="Loading dashboard…" variant="scooter" size="lg" />
  </div>
);

function AdminShell() {
  const { isAuthenticated } = useAuth();
  const { sidebarOpen, closeSidebar } = useLayout();
  const [showSplashOverlay, setShowSplashOverlay] = useState(false);

  const replaySplash = () => setShowSplashOverlay(true);

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
          <Route
            index
            element={
              <ProtectedRoute>
                <Dashboard onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="orders"
            element={
              <ProtectedRoute>
                <OrdersBoard onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="products"
            element={
              <ProtectedRoute>
                <Products onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="offers"
            element={
              <ProtectedRoute>
                <Offers onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="riders"
            element={
              <ProtectedRoute>
                <Riders onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="users"
            element={
              <ProtectedRoute>
                <Users onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="coins"
            element={
              <ProtectedRoute>
                <Coins onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="chat"
            element={
              <ProtectedRoute>
                <Chat onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="issues"
            element={
              <ProtectedRoute>
                <Issues onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="enquiries"
            element={
              <ProtectedRoute>
                <Enquiries onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route
            path="settings"
            element={
              <ProtectedRoute>
                <Settings onReplaySplash={replaySplash} />
              </ProtectedRoute>
            }
          />
          <Route path="*" element={<Navigate to="/admin" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function App() {
  return (
    <Routes>
      {/* Public website */}
      <Route element={<SiteLayout />}>
        <Route index element={<Home />} />
        <Route path="about" element={<About />} />
        <Route path="blog" element={<Blog />} />
        <Route path="blog/:slug" element={<BlogPost />} />
        <Route path="contact" element={<Contact />} />
        <Route path="privacy" element={<LegalPage name="privacy" />} />
        <Route path="terms" element={<LegalPage name="terms" />} />
        <Route path="refunds" element={<LegalPage name="refunds" />} />
        <Route path="ride-with-us" element={<LegalPage name="ride-with-us" />} />
        <Route path="*" element={<NotFound />} />
      </Route>

      {/* Staff sign-in: typed, never linked */}
      <Route
        path="/login"
        element={
          <Suspense fallback={<AdminChunkLoader />}>
            <Login />
          </Suspense>
        }
      />

      {/* Operations dashboard */}
      <Route
        path="/admin/*"
        element={
          <Suspense fallback={<AdminChunkLoader />}>
            <AdminProviders>
              <AdminShell />
            </AdminProviders>
          </Suspense>
        }
      />

      {LEGACY_ADMIN_PATHS.map((path) => (
        <Route key={path} path={`/${path}`} element={<Navigate to={`/admin/${path}`} replace />} />
      ))}
    </Routes>
  );
}

export default App;
