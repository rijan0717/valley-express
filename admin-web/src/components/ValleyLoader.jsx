import React from 'react';

/**
 * Reusable Valley Express Animated Loader Component
 * Strict 5-color palette: #FFFFFF, #1F2A44, #FF6B1A, #003893, #D1D5DB
 * Supports 3 branded animation variants:
 * 1. "badge" (default) - Orange badge with white V and bouncing blue location pin
 * 2. "scooter" - Fast delivery scooter rider with bobbing suspension, rotating spokes, and speed streams
 * 3. "orbit" - Double orbit velocity rings with center badge and hopping pin
 * Respects prefers-reduced-motion
 */
export const ValleyLoader = ({
  text = 'Loading...',
  size = 'default',
  variant = 'badge',
}) => {
  const dimension = size === 'sm' ? 44 : size === 'lg' ? 96 : 64;

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: size === 'sm' ? '8px' : '20px',
        gap: '12px',
      }}
      role="status"
      aria-live="polite"
    >
      <style>{`
        @keyframes valleyPinBounce {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-8px); }
        }
        @keyframes valleySquarePulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.02); }
        }
        @keyframes valleySpinLinear {
          100% { transform: rotate(360deg); }
        }
        @keyframes valleyScooterBob {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-3px); }
        }
        @keyframes valleySpeedLines {
          0% { opacity: 0.3; transform: translateX(0); }
          50% { opacity: 1; transform: translateX(-4px); }
          100% { opacity: 0.3; transform: translateX(0); }
        }
        .v-pin-bounce {
          animation: valleyPinBounce 1.2s ease-in-out infinite;
          transform-origin: center bottom;
        }
        .v-square-pulse {
          animation: valleySquarePulse 1.2s ease-in-out infinite;
          transform-origin: center;
        }
        .v-scooter-bob {
          animation: valleyScooterBob 0.45s ease-in-out infinite;
        }
        .v-spoke-spin-1 {
          transform-box: fill-box;
          transform-origin: center;
          animation: valleySpinLinear 0.4s linear infinite;
        }
        .v-spoke-spin-2 {
          transform-box: fill-box;
          transform-origin: center;
          animation: valleySpinLinear 0.4s linear infinite;
        }
        .v-speed-streams {
          animation: valleySpeedLines 0.6s ease-in-out infinite;
        }
        .v-orbit-ring {
          transform-origin: 80px 80px;
          animation: valleySpinLinear 1.4s cubic-bezier(0.5, 0, 0.5, 1) infinite;
        }
        @media (prefers-reduced-motion: reduce) {
          .v-pin-bounce, .v-square-pulse, .v-scooter-bob,
          .v-spoke-spin-1, .v-spoke-spin-2, .v-speed-streams, .v-orbit-ring {
            animation: none !important;
          }
        }
      `}</style>

      {/* Variant: SCOOTER LOADER */}
      {variant === 'scooter' && (
        <svg
          viewBox="-30 0 160 100"
          width={dimension * 1.5}
          height={dimension * 0.9375}
          style={{ display: 'block' }}
          aria-label="Valley Express Delivery Scooter Loader"
        >
          {/* Speed Air Streams */}
          <g className="v-speed-streams" stroke="#003893" strokeWidth="4" strokeLinecap="round" opacity="0.85">
            <line x1="-30" y1="36" x2="-8" y2="36" />
            <line x1="-24" y1="54" x2="-4" y2="54" />
            <line x1="-30" y1="72" x2="-8" y2="72" />
          </g>

          {/* Bobbing Scooter and Rider */}
          <g className="v-scooter-bob">
            {/* Wheel Rims */}
            <g fill="none" stroke="#1F2A44" strokeWidth="4">
              <circle cx="38" cy="76" r="13" />
              <circle cx="108" cy="76" r="13" />
            </g>

            {/* Spinning Spokes */}
            <g className="v-spoke-spin-1" stroke="#D1D5DB" strokeWidth="2" strokeLinecap="round">
              <line x1="28" y1="76" x2="48" y2="76" />
              <line x1="38" y1="66" x2="38" y2="86" />
            </g>
            <g className="v-spoke-spin-2" stroke="#D1D5DB" strokeWidth="2" strokeLinecap="round">
              <line x1="98" y1="76" x2="118" y2="76" />
              <line x1="108" y1="66" x2="108" y2="86" />
            </g>

            {/* Fork & Chassis */}
            <line x1="104" y1="40" x2="108" y2="76" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round" />
            <rect x="28" y="52" width="40" height="20" rx="9" fill="#FF6B1A" stroke="#1F2A44" strokeWidth="2" />
            <rect x="62" y="66" width="40" height="8" rx="4" fill="#FF6B1A" />
            <path d="M96 68 L102 38" stroke="#FF6B1A" strokeWidth="11" strokeLinecap="round" fill="none" />
            <rect x="34" y="46" width="30" height="8" rx="4" fill="#1F2A44" />
            <line x1="102" y1="36" x2="106" y2="26" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round" />
            <line x1="100" y1="26" x2="114" y2="26" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round" />
            <circle cx="112" cy="38" r="5" fill="#FFFFFF" stroke="#1F2A44" strokeWidth="2" />

            {/* Delivery Box with V Logo */}
            <rect x="4" y="20" width="30" height="30" rx="4" fill="#003893" />
            <path d="M11 28 L19 42 L27 28" fill="none" stroke="#FFFFFF" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />

            {/* Rider Silhouette */}
            <g fill="none" strokeLinecap="round" strokeLinejoin="round">
              <path d="M54 44 L78 52 L84 68" stroke="#1F2A44" strokeWidth="8" />
              <path d="M54 44 L66 18" stroke="#003893" strokeWidth="13" />
              <path d="M66 20 L104 26" stroke="#003893" strokeWidth="6" />
            </g>
            <circle cx="70" cy="8" r="8" fill="#FFFFFF" stroke="#1F2A44" strokeWidth="2" />
            <path d="M61 8 A9 9 0 0 1 79 8 Z" fill="#FF6B1A" />
          </g>
        </svg>
      )}

      {/* Variant: ORBIT RINGS LOADER */}
      {variant === 'orbit' && (
        <svg
          viewBox="0 0 160 160"
          width={dimension}
          height={dimension}
          style={{ display: 'block' }}
          aria-label="Valley Express Orbit Loader"
        >
          {/* Static Track Ring */}
          <circle cx="80" cy="80" r="70" fill="none" stroke="#D1D5DB" strokeWidth="4" opacity="0.4" />
          {/* Rotating Orange Ring */}
          <circle
            cx="80"
            cy="80"
            r="70"
            fill="none"
            stroke="#FF6B1A"
            strokeWidth="5"
            strokeLinecap="round"
            strokeDasharray="110 330"
            className="v-orbit-ring"
          />
          {/* Rotating Blue Ring (Counter-clockwise) */}
          <circle
            cx="80"
            cy="80"
            r="70"
            fill="none"
            stroke="#003893"
            strokeWidth="5"
            strokeLinecap="round"
            strokeDasharray="60 380"
            strokeDashoffset="-200"
            className="v-orbit-ring"
            style={{ animationDirection: 'reverse', animationDuration: '2s' }}
          />

          {/* Center Badge */}
          <g className="v-square-pulse">
            <rect x="35" y="35" width="90" height="90" rx="24" fill="#FF6B1A" />
            <path
              d="M56 64 L80 106 L104 64"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="10"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <g className="v-pin-bounce">
              <path
                d="M80 72 C76 66 73 62 73 57 A7 7 0 0 1 87 57 C87 62 84 66 80 72 Z"
                fill="#003893"
              />
              <circle cx="80" cy="57" r="2.5" fill="#FFFFFF" />
            </g>
          </g>
        </svg>
      )}

      {/* Variant: BADGE LOADER (Default) */}
      {variant === 'badge' && (
        <svg
          viewBox="0 0 160 160"
          width={dimension}
          height={dimension}
          style={{ display: 'block' }}
          aria-label="Valley Express Badge Loader"
        >
          {/* Orange rounded square */}
          <rect
            className="v-square-pulse"
            x="10"
            y="10"
            width="140"
            height="140"
            rx="32"
            fill="#FF6B1A"
          />

          {/* White V stroke */}
          <path
            d="M44 56 L80 120 L116 56"
            fill="none"
            stroke="#FFFFFF"
            strokeWidth="14"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Bouncing Blue Pin inside the V */}
          <g className="v-pin-bounce">
            <path
              d="M80 68 C75 61 71 56 71 49 A9 9 0 0 1 89 49 C89 56 85 61 80 68 Z"
              fill="#003893"
            />
            <circle cx="80" cy="49" r="3.5" fill="#FFFFFF" />
          </g>
        </svg>
      )}

      {text && (
        <span
          style={{
            fontFamily: "'Poppins', sans-serif",
            fontSize: size === 'sm' ? '12px' : '13px',
            fontWeight: 500,
            color: '#1F2A44',
            letterSpacing: '0.3px',
          }}
        >
          {text}
        </span>
      )}
    </div>
  );
};

export default ValleyLoader;
