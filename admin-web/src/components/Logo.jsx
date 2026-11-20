import React from 'react';

/**
 * Valley Express Vector Brand Mark
 * Strict palette: #FF6B1A, #003893, #1F2A44, #FFFFFF, #D1D5DB
 */
export const LogoMark = ({ size = 40, className = '' }) => (
  <svg
    viewBox="0 0 260 160"
    width={size * 1.625}
    height={size}
    className={className}
    role="img"
    aria-label="Valley Express logo mark"
  >
    <g stroke="#003893" strokeWidth="8" strokeLinecap="round">
      <line x1="10" y1="52" x2="50" y2="52"></line>
      <line x1="22" y1="80" x2="52" y2="80"></line>
      <line x1="10" y1="108" x2="50" y2="108"></line>
    </g>
    <rect x="70" y="10" width="140" height="140" rx="34" fill="#FF6B1A"></rect>
    <path
      d="M104 56 L140 120 L176 56"
      fill="none"
      stroke="#FFFFFF"
      strokeWidth="14"
      strokeLinecap="round"
      strokeLinejoin="round"
    ></path>
    <g>
      <path
        d="M140 68 C135 61 131 56 131 49 A9 9 0 0 1 149 49 C149 56 145 61 140 68 Z"
        fill="#003893"
      ></path>
      <circle cx="140" cy="49" r="3.5" fill="#FFFFFF"></circle>
    </g>
  </svg>
);

export const LogoFull = ({ height = 48, className = '' }) => (
  <svg
    viewBox="0 0 500 160"
    height={height}
    width={height * 3.125}
    className={className}
    role="img"
    aria-label="Valley Express"
  >
    {/* Logo Mark */}
    <g transform="translate(0, 0)">
      <g stroke="#003893" strokeWidth="8" strokeLinecap="round">
        <line x1="10" y1="52" x2="50" y2="52"></line>
        <line x1="22" y1="80" x2="52" y2="80"></line>
        <line x1="10" y1="108" x2="50" y2="108"></line>
      </g>
      <rect x="70" y="10" width="140" height="140" rx="34" fill="#FF6B1A"></rect>
      <path
        d="M104 56 L140 120 L176 56"
        fill="none"
        stroke="#FFFFFF"
        strokeWidth="14"
        strokeLinecap="round"
        strokeLinejoin="round"
      ></path>
      <g>
        <path
          d="M140 68 C135 61 131 56 131 49 A9 9 0 0 1 149 49 C149 56 145 61 140 68 Z"
          fill="#003893"
        ></path>
        <circle cx="140" cy="49" r="3.5" fill="#FFFFFF"></circle>
      </g>
    </g>

    {/* Wordmark typography */}
    <text
      x="235"
      y="84"
      fontFamily="'Poppins', sans-serif"
      fontSize="68"
      fontWeight="700"
      fill="#003893"
      letterSpacing="-1.5"
    >
      Valley
    </text>
    <text
      x="238"
      y="114"
      fontFamily="'Poppins', sans-serif"
      fontSize="20"
      fontWeight="700"
      fill="#FF6B1A"
      letterSpacing="8"
    >
      EXPRESS
    </text>
    <text
      x="238"
      y="138"
      fontFamily="'Poppins', sans-serif"
      fontSize="12"
      fontWeight="400"
      fill="#1F2A44"
    >
      Fast to order. Fast to your door.
    </text>
  </svg>
);

export const ScooterRider = ({ width = 120, className = '' }) => (
  <svg
    viewBox="-30 0 160 100"
    width={width}
    height={width * 0.625}
    className={className}
    role="img"
    aria-label="Delivery Scooter"
  >
    <g stroke="#003893" strokeWidth="4" strokeLinecap="round">
      <line x1="-30" y1="36" x2="-8" y2="36"></line>
      <line x1="-24" y1="54" x2="-4" y2="54"></line>
      <line x1="-30" y1="72" x2="-8" y2="72"></line>
    </g>
    <g>
      <g fill="none" stroke="#1F2A44" strokeWidth="4">
        <circle cx="38" cy="76" r="13"></circle>
        <circle cx="108" cy="76" r="13"></circle>
      </g>
      <g stroke="#D1D5DB" strokeWidth="2" strokeLinecap="round">
        <line x1="28" y1="76" x2="48" y2="76"></line>
        <line x1="38" y1="66" x2="38" y2="86"></line>
        <line x1="98" y1="76" x2="118" y2="76"></line>
        <line x1="108" y1="66" x2="108" y2="86"></line>
      </g>
      <line x1="104" y1="40" x2="108" y2="76" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round"></line>
      <rect x="28" y="52" width="40" height="20" rx="9" fill="#FF6B1A" stroke="#1F2A44" strokeWidth="2"></rect>
      <rect x="62" y="66" width="40" height="8" rx="4" fill="#FF6B1A"></rect>
      <path d="M96 68 L102 38" stroke="#FF6B1A" strokeWidth="11" strokeLinecap="round" fill="none"></path>
      <rect x="34" y="46" width="30" height="8" rx="4" fill="#1F2A44"></rect>
      <line x1="102" y1="36" x2="106" y2="26" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round"></line>
      <line x1="100" y1="26" x2="114" y2="26" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round"></line>
      <circle cx="112" cy="38" r="5" fill="#FFFFFF" stroke="#1F2A44" strokeWidth="2"></circle>
      <rect x="4" y="20" width="30" height="30" rx="4" fill="#003893"></rect>
      <path d="M11 28 L19 42 L27 28" fill="none" stroke="#FFFFFF" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"></path>
      <g fill="none" strokeLinecap="round" strokeLinejoin="round">
        <path d="M54 44 L78 52 L84 68" stroke="#1F2A44" strokeWidth="8"></path>
        <path d="M54 44 L66 18" stroke="#003893" strokeWidth="13"></path>
        <path d="M66 20 L104 26" stroke="#003893" strokeWidth="6"></path>
      </g>
      <circle cx="70" cy="8" r="8" fill="#FFFFFF" stroke="#1F2A44" strokeWidth="2"></circle>
      <path d="M61 8 A9 9 0 0 1 79 8 Z" fill="#FF6B1A"></path>
    </g>
  </svg>
);

export default LogoMark;
