import React from 'react';

/** Line icons for the feature grid, drawn on the same 24px grid as the dashboard set. */
const PATHS = {
  map: (
    <>
      <path d="M9 3 3 5.4v15.1l6-2.4 6 2.4 6-2.4V2.9l-6 2.5L9 3z" />
      <path d="M9 3v15.1M15 5.4v15.1" />
    </>
  ),
  coin: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M14.5 9.5a2.5 2.5 0 0 0-5 0c0 2.5 5 1.5 5 4a2.5 2.5 0 0 1-5 0M12 7v10" />
    </>
  ),
  chat: <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />,
  snow: (
    <>
      <path d="M12 2v20M4.2 6.5l15.6 11M19.8 6.5 4.2 17.5" />
      <path d="M12 6.4 9.6 4M12 6.4 14.4 4M12 17.6 9.6 20M12 17.6l2.4 2.4" />
    </>
  ),
  wallet: (
    <>
      <path d="M3 7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v1" />
      <path d="M3 7v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2H5a2 2 0 0 1-2-2z" />
      <circle cx="16.5" cy="13.5" r="1.2" />
    </>
  ),
  pin: (
    <>
      <path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z" />
      <circle cx="12" cy="10" r="2.6" />
    </>
  ),
};

const FeatureIcon = ({ name, size = 26 }) => (
  <svg
    viewBox="0 0 24 24"
    width={size}
    height={size}
    fill="none"
    stroke="currentColor"
    strokeWidth="1.8"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    {PATHS[name] || PATHS.pin}
  </svg>
);

export default FeatureIcon;
