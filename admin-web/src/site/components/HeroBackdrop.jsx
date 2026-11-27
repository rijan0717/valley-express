import React from 'react';
import { motion } from 'framer-motion';

/**
 * Hero backdrop.
 *
 * Rather than generic floating particles, this draws the thing the product
 * actually does: a delivery route crossing the Valley, with the store at one
 * end and a drop pin at the other. The route draws itself once on load and a
 * rider runs it on a slow loop.
 */
const ROUTE = 'M-40 352 C 180 320, 250 210, 470 212 S 820 236, 980 150 S 1270 96, 1500 120';

const HeroBackdrop = () => (
  <div className="vx-hero-backdrop" aria-hidden="true">
    <div className="vx-hero-wash" />

    <svg className="vx-hero-route" viewBox="0 0 1440 460" preserveAspectRatio="xMidYMid slice">
      {/* Contour lines: the Valley rim, abstracted. */}
      <g stroke="rgba(255,255,255,0.055)" fill="none" strokeWidth="1">
        <path d="M-40 404 C 240 360, 420 392, 700 344 S 1180 300, 1500 336" />
        <path d="M-40 432 C 240 392, 460 424, 740 376 S 1200 332, 1500 368" />
        <path d="M-40 460 C 240 424, 500 456, 780 408 S 1220 364, 1500 400" />
      </g>

      <motion.path
        d={ROUTE}
        fill="none"
        stroke="rgba(255,107,26,0.55)"
        strokeWidth="1.5"
        strokeDasharray="5 9"
        strokeLinecap="round"
        initial={{ pathLength: 0, opacity: 0 }}
        animate={{ pathLength: 1, opacity: 1 }}
        transition={{ duration: 2.2, ease: 'easeInOut', delay: 0.3 }}
      />

      <motion.g
        animate={{ offsetDistance: ['0%', '100%'] }}
        transition={{ duration: 14, repeat: Infinity, ease: 'linear', delay: 1.6 }}
        style={{ offsetPath: `path("${ROUTE}")` }}
      >
        {/* The supplied artwork, referenced as a file so its own wheel-spin
            animation and C2PA manifest travel with it. The wheels sit ~74%
            down its viewBox, so the offsets put them on the route line. */}
        <image
          href="/brand/valley-scooter.svg"
          width="92"
          height="64"
          x="-46"
          y="-47"
        />
      </motion.g>
    </svg>

    <div className="vx-grain" />
  </div>
);

export default HeroBackdrop;
