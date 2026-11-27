import React, { useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import SiteHeader from './SiteHeader';
import SiteFooter from './SiteFooter';
import { NotifyProvider } from './NotifyModal';

/** Every public route renders inside this shell. */
const ScrollToTop = () => {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
  }, [pathname]);
  return null;
};

const SiteLayout = () => (
  <NotifyProvider>
    <div className="vx-site">
      <ScrollToTop />
      <a className="vx-skip-link" href="#vx-main">Skip to content</a>
      <SiteHeader />
      <main id="vx-main">
        <Outlet />
      </main>
      <SiteFooter />
    </div>
  </NotifyProvider>
);

export default SiteLayout;
