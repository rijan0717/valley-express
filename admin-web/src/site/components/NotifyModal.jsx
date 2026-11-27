import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { joinNotifyList } from '../api';
import { BrandMark } from './Brand';

const NotifyContext = createContext({ openNotify: () => {} });

export const useNotify = () => useContext(NotifyContext);

/**
 * The app is not on the stores yet, so every "Download" control opens this
 * sheet instead of linking somewhere that does not exist. What the visitor
 * leaves here is stored as a lead, not swallowed by a fake success message.
 */
export const NotifyProvider = ({ children }) => {
  const [platform, setPlatform] = useState(null);
  const openNotify = (next = 'either') => setPlatform(next);
  const close = () => setPlatform(null);

  const value = useMemo(() => ({ openNotify }), []);

  return (
    <NotifyContext.Provider value={value}>
      {children}
      <AnimatePresence>
        {platform && <NotifySheet platform={platform} onClose={close} />}
      </AnimatePresence>
    </NotifyContext.Provider>
  );
};

const NotifySheet = ({ platform, onClose }) => {
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [status, setStatus] = useState({ state: 'idle', message: '' });

  // Escape closes, and the page behind should not scroll while this is open.
  useEffect(() => {
    const onKey = (event) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = previousOverflow;
    };
  }, [onClose]);

  const submit = async (event) => {
    event.preventDefault();
    if (status.state === 'sending') return;
    setStatus({ state: 'sending', message: '' });
    const result = await joinNotifyList({ email, phone, platform });
    setStatus({ state: result.ok ? 'done' : 'error', message: result.message });
  };

  return (
    <motion.div
      className="vx-modal-backdrop"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
      role="presentation"
    >
      <motion.div
        className="vx-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="vx-notify-title"
        initial={{ opacity: 0, y: 24, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 16, scale: 0.98 }}
        transition={{ duration: 0.25, ease: [0.22, 0.61, 0.36, 1] }}
        onClick={(event) => event.stopPropagation()}
      >
        <button type="button" className="vx-modal-close" onClick={onClose} aria-label="Close">
          ×
        </button>

        <BrandMark size={34} />
        <h2 id="vx-notify-title" className="vx-modal-title">
          {status.state === 'done' ? 'You are on the list' : 'The app is almost here'}
        </h2>

        {status.state === 'done' ? (
          <>
            <p className="vx-modal-body">{status.message}</p>
            <button type="button" className="vx-btn vx-btn-primary vx-btn-block" onClick={onClose}>
              Back to the site
            </button>
          </>
        ) : (
          <>
            <p className="vx-modal-body">
              Valley Express for{' '}
              {platform === 'ios' ? 'iPhone' : platform === 'android' ? 'Android' : 'Android and iPhone'}{' '}
              is in final testing. Leave an email or a mobile number and we will tell you the day it lands
              on the store.
            </p>

            <form onSubmit={submit} className="vx-form" noValidate>
              <label className="vx-label" htmlFor="notify-email">
                Email address
              </label>
              <input
                id="notify-email"
                className="vx-input"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                autoComplete="email"
              />

              <label className="vx-label" htmlFor="notify-phone">
                Or mobile number
              </label>
              <input
                id="notify-phone"
                className="vx-input"
                type="tel"
                placeholder="98XXXXXXXX"
                value={phone}
                onChange={(event) => setPhone(event.target.value)}
                autoComplete="tel"
              />

              {status.state === 'error' && (
                <p className="vx-form-error" role="alert">
                  {status.message}
                </p>
              )}

              <button
                type="submit"
                className="vx-btn vx-btn-primary vx-btn-block"
                disabled={status.state === 'sending'}
              >
                {status.state === 'sending' ? 'Adding you…' : 'Notify me at launch'}
              </button>
              <p className="vx-form-note">
                One message when the app goes live. No marketing blasts, and you can ask us to remove you
                at any time.
              </p>
            </form>
          </>
        )}
      </motion.div>
    </motion.div>
  );
};

export default NotifyProvider;
