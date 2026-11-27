import React from 'react';
import { useNotify } from './NotifyModal';

/**
 * Store badges. The app is not published yet, so these open the notify sheet
 * and say so on their face rather than linking to a listing that is not there.
 */
const AppleGlyph = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" fill="currentColor">
    <path d="M16.3 12.8c0-2.2 1.8-3.3 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.3.8-.7 0-1.7-.8-2.8-.8-1.4 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.6 2.2 2.7 2.2 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.1 0 1.9-1 2.6-2 .8-1.2 1.2-2.3 1.2-2.4-.1 0-2.3-.9-2.3-3.5zM14.4 6.2c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.6.6-1.1 1.7-.9 2.6 1 .1 2-.5 2.5-1.2z" />
  </svg>
);

const PlayGlyph = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
    <path d="M4 2.6v18.8c0 .5.5.8.9.6l10.4-6.1-3-3L4 2.6z" fill="currentColor" />
    <path d="M17.6 10.4 15 8.9l-2.8 2.8L15 14.5l2.6-1.5c.8-.5.8-1.6 0-2.1z" fill="currentColor" opacity="0.75" />
    <path d="M4.9 2c-.3-.2-.6-.1-.8.1l8.1 8.1L15 8.9 4.9 2z" fill="currentColor" opacity="0.55" />
  </svg>
);

const StoreBadges = ({ theme = 'light', block = false }) => {
  const { openNotify } = useNotify();

  return (
    <div className={`vx-badges${block ? ' is-block' : ''}`}>
      <button
        type="button"
        className={`vx-badge vx-badge-${theme}`}
        onClick={() => openNotify('android')}
      >
        <PlayGlyph />
        <span>
          <small>Coming soon on</small>
          <strong>Google Play</strong>
        </span>
      </button>
      <button
        type="button"
        className={`vx-badge vx-badge-${theme}`}
        onClick={() => openNotify('ios')}
      >
        <AppleGlyph />
        <span>
          <small>Coming soon on</small>
          <strong>App Store</strong>
        </span>
      </button>
    </div>
  );
};

export default StoreBadges;
