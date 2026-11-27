import React, { useId } from 'react';
import { motion } from 'framer-motion';

/**
 * A minted Valley Coin: milled edge, raised rim, the logo V struck into the
 * face and a light sweep across it. Drawn rather than illustrated so it stays
 * crisp from 28px in the hero stat row up to 120px in the coins band.
 *
 * `spin` gives it a slow edge-on rotation, the way a coin catches the light
 * when it turns.
 */
const ValleyCoin = ({ size = 56, spin = false, className = '' }) => {
  // Gradients are id-referenced, so two coins on a page must not share ids.
  const id = useId().replace(/:/g, '');
  const ridges = Array.from({ length: 36 });

  // When spinning, the caller's className has to land on the outer wrapper —
  // positioning the inner svg instead leaves the wrapper in flow and the coin
  // ends up somewhere else entirely.
  const faceClass = spin ? 'vx-coin-face' : className;

  const face = (
    <svg viewBox="0 0 100 100" width={size} height={size} className={faceClass} aria-hidden="true">
      <defs>
        <linearGradient id={`${id}-rim`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#ffc98f" />
          <stop offset="38%" stopColor="#ff8a3d" />
          <stop offset="72%" stopColor="#e8590c" />
          <stop offset="100%" stopColor="#c2470a" />
        </linearGradient>
        <linearGradient id={`${id}-face`} x1="0.1" y1="0" x2="0.9" y2="1">
          <stop offset="0%" stopColor="#ffb673" />
          <stop offset="45%" stopColor="#ff7a2f" />
          <stop offset="100%" stopColor="#e8590c" />
        </linearGradient>
        <linearGradient id={`${id}-shine`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#fff" stopOpacity="0.62" />
          <stop offset="46%" stopColor="#fff" stopOpacity="0.06" />
          <stop offset="100%" stopColor="#fff" stopOpacity="0" />
        </linearGradient>
      </defs>

      {/* milled edge */}
      <circle cx="50" cy="50" r="48" fill={`url(#${id}-rim)`} />
      <g stroke="#c2470a" strokeOpacity="0.55" strokeWidth="2">
        {ridges.map((_, i) => {
          const angle = (i * 360) / ridges.length;
          return (
            <line
              key={angle}
              x1="50"
              y1="2.5"
              x2="50"
              y2="7.5"
              transform={`rotate(${angle} 50 50)`}
              strokeLinecap="round"
            />
          );
        })}
      </g>

      {/* raised rim and struck face */}
      <circle cx="50" cy="50" r="42" fill={`url(#${id}-face)`} />
      <circle cx="50" cy="50" r="42" fill="none" stroke="#fff" strokeOpacity="0.4" strokeWidth="1.4" />
      <circle cx="50" cy="50" r="34" fill="none" stroke="#c2470a" strokeOpacity="0.35" strokeWidth="1.2" />

      {/* the mark, struck into the metal */}
      <path
        d="M34 38 L50 67 L66 38"
        fill="none"
        stroke="#c2470a"
        strokeOpacity="0.45"
        strokeWidth="8.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        transform="translate(0 1.6)"
      />
      <path
        d="M34 38 L50 67 L66 38"
        fill="none"
        stroke="#fff"
        strokeWidth="8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      {/* light sweep */}
      <path d="M8 36 A48 48 0 0 1 64 4 L30 78 A48 48 0 0 1 8 36 Z" fill={`url(#${id}-shine)`} />
    </svg>
  );

  if (!spin) return face;

  return (
    <motion.span
      className={`vx-coin-spin ${className}`.trim()}
      animate={{ rotateY: [0, 360] }}
      transition={{ duration: 9, repeat: Infinity, ease: 'linear' }}
    >
      {face}
    </motion.span>
  );
};

export default ValleyCoin;
