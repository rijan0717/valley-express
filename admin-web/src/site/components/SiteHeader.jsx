import React, { useEffect, useState } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { BrandLockup, BrandMark } from './Brand';
import { useNotify } from './NotifyModal';

/**
 * Public header.
 *
 * Deliberately carries no sign-in or register control: the dashboard is staff
 * software and is reached by typing /login, never by following a link from a
 * customer-facing page.
 */
const LINKS = [
  { to: '/', label: 'Home', end: true },
  { to: '/about', label: 'About' },
  { to: '/blog', label: 'Blog' },
  { to: '/contact', label: 'Contact' },
];

const SiteHeader = () => {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { openNotify } = useNotify();
  const location = useLocation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  // A route change should never leave the drawer hanging open behind the page.
  useEffect(() => setMenuOpen(false), [location.pathname]);

  return (
    <header className={`vx-header${scrolled ? ' is-scrolled' : ''}`}>
      <div className="vx-container vx-header-inner">
        <Link to="/" className="vx-logo-link" aria-label="Valley Express home">
          <BrandLockup />
        </Link>

        <nav className="vx-nav" aria-label="Primary">
          {LINKS.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.end}
              className={({ isActive }) => `vx-nav-link${isActive ? ' is-active' : ''}`}
            >
              {link.label}
            </NavLink>
          ))}
        </nav>

        <div className="vx-header-actions">
          <button type="button" className="vx-btn vx-btn-primary" onClick={() => openNotify('either')}>
            Download the app
          </button>
          <button
            type="button"
            className="vx-burger"
            aria-label={menuOpen ? 'Close menu' : 'Open menu'}
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((open) => !open)}
          >
            <span className={menuOpen ? 'is-open' : ''} />
          </button>
        </div>
      </div>

      <AnimatePresence>
        {menuOpen && (
          <motion.nav
            className="vx-mobile-nav"
            aria-label="Primary mobile"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25, ease: 'easeOut' }}
          >
            <div className="vx-container vx-mobile-nav-inner">
              {LINKS.map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  end={link.end}
                  className={({ isActive }) => `vx-mobile-link${isActive ? ' is-active' : ''}`}
                >
                  {link.label}
                </NavLink>
              ))}
              <button
                type="button"
                className="vx-btn vx-btn-primary vx-btn-block"
                onClick={() => openNotify('either')}
              >
                Download the app
              </button>
            </div>
          </motion.nav>
        )}
      </AnimatePresence>
    </header>
  );
};

export default SiteHeader;
