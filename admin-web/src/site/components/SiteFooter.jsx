import React from 'react';
import { Link } from 'react-router-dom';
import { BrandLockup } from './Brand';
import { BRAND, CATEGORIES } from '../content/site';
import { useNotify } from './NotifyModal';

/**
 * Public footer. Like the header, it carries no route into the dashboard.
 */
const SiteFooter = () => {
  const { openNotify } = useNotify();
  const year = new Date().getFullYear();

  return (
    <footer className="vx-footer">
      <div className="vx-container vx-footer-grid">
        <div className="vx-footer-brand">
          <BrandLockup />
          <p className="vx-footer-tagline">{BRAND.tagline}</p>
          <p className="vx-footer-text">{BRAND.shortPitch}</p>
          <div className="vx-footer-social">
            <a href={BRAND.social.facebook} target="_blank" rel="noreferrer noopener">Facebook</a>
            <a href={BRAND.social.instagram} target="_blank" rel="noreferrer noopener">Instagram</a>
            <a href={BRAND.social.tiktok} target="_blank" rel="noreferrer noopener">TikTok</a>
          </div>
        </div>

        <div className="vx-footer-col">
          <h3>Valley Express</h3>
          <Link to="/">Home</Link>
          <Link to="/about">About us</Link>
          <Link to="/blog">Blog</Link>
          <Link to="/contact">Contact</Link>
          <Link to="/ride-with-us">Ride with us</Link>
        </div>

        <div className="vx-footer-col">
          <h3>What we deliver</h3>
          {CATEGORIES.map((category) => (
            <span key={category.name} className="vx-footer-static">{category.name}</span>
          ))}
        </div>

        <div className="vx-footer-col">
          <h3>Get in touch</h3>
          <a href={`mailto:${BRAND.email}`}>{BRAND.email}</a>
          <a href={`tel:${BRAND.phone.replace(/\s/g, '')}`}>{BRAND.phone}</a>
          <span className="vx-footer-static">{BRAND.address}</span>
          <span className="vx-footer-static">
            Daily {BRAND.hours.open}–{BRAND.hours.close}
          </span>
          <button type="button" className="vx-btn vx-btn-ghost-light" onClick={() => openNotify('either')}>
            Get the app
          </button>
        </div>
      </div>

      <div className="vx-container vx-footer-bottom">
        <span>© {year} {BRAND.name}. Delivering across {BRAND.cities.join(', ')}.</span>
        <span className="vx-footer-legal">
          <Link to="/privacy">Privacy</Link>
          <Link to="/terms">Terms</Link>
          <Link to="/refunds">Refunds</Link>
        </span>
        <span className="vx-footer-note">
          Valley Express does not deliver alcohol. Mixers and soft drinks only.
        </span>
      </div>
    </footer>
  );
};

export default SiteFooter;
