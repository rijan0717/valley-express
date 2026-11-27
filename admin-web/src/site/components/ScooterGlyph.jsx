import React from 'react';

/**
 * Compact delivery scooter used as the moving marker on every route line.
 *
 * The full ScooterRider in components/Logo.jsx carries far too much detail to
 * read at marker size, so this is the same vehicle reduced to what survives at
 * 20–40px: two wheels, the orange body, a rider, and the blue delivery box on
 * the back — the one shape that says "your order is on this bike".
 */
/**
 * The same vehicle as a bare <g>, for dropping inside an existing <svg> — the
 * route markers need it as a group so it can ride an offset-path. `scale` sizes
 * it; it is drawn centred on its own origin so it sits on the path, not beside
 * it.
 */
export const ScooterShape = ({ scale = 1 }) => (
  <g transform={`scale(${scale}) translate(-32 -20)`}>
    <rect x="6" y="9" width="17" height="14" rx="3" fill="#003893" />
    <path d="M10.5 13 L14.5 20 L18.5 13" fill="none" stroke="#fff" strokeWidth="2.2"
          strokeLinecap="round" strokeLinejoin="round" />
    <circle cx="38" cy="7" r="4.4" fill="#1F2A44" />
    <path d="M30 22 L34.5 13 L41 12 L47 16" fill="none" stroke="#1F2A44" strokeWidth="4.2"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M23 24 L34 24 L40 19" fill="none" stroke="#FF6B1A" strokeWidth="5"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M44 14 L49 14" stroke="#1F2A44" strokeWidth="2.6" strokeLinecap="round" />
    <path d="M47 16 L49 26" stroke="#FF6B1A" strokeWidth="3.4" strokeLinecap="round" />
    <circle cx="20" cy="29" r="6.4" fill="#fff" stroke="#1F2A44" strokeWidth="3" />
    <circle cx="49" cy="29" r="6.4" fill="#fff" stroke="#1F2A44" strokeWidth="3" />
  </g>
);

const ScooterGlyph = ({ width = 44, className = '' }) => (
  <svg
    viewBox="0 0 64 40"
    width={width}
    height={width * 0.625}
    className={className}
    overflow="visible"
    aria-hidden="true"
  >
    {/* delivery box */}
    <rect x="6" y="9" width="17" height="14" rx="3" fill="#003893" />
    <path d="M10.5 13 L14.5 20 L18.5 13" fill="none" stroke="#fff" strokeWidth="2.2"
          strokeLinecap="round" strokeLinejoin="round" />

    {/* rider */}
    <circle cx="38" cy="7" r="4.4" fill="#1F2A44" />
    <path d="M30 22 L34.5 13 L41 12 L47 16" fill="none" stroke="#1F2A44" strokeWidth="4.2"
          strokeLinecap="round" strokeLinejoin="round" />

    {/* body and handlebar */}
    <path d="M23 24 L34 24 L40 19" fill="none" stroke="#FF6B1A" strokeWidth="5"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M44 14 L49 14" stroke="#1F2A44" strokeWidth="2.6" strokeLinecap="round" />
    <path d="M47 16 L49 26" stroke="#FF6B1A" strokeWidth="3.4" strokeLinecap="round" />

    {/* wheels */}
    <circle cx="20" cy="29" r="6.4" fill="#fff" stroke="#1F2A44" strokeWidth="3" />
    <circle cx="49" cy="29" r="6.4" fill="#fff" stroke="#1F2A44" strokeWidth="3" />
  </svg>
);

export default ScooterGlyph;
