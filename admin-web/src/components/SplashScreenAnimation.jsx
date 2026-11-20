import React, { useState, useEffect } from 'react';

const SplashScreenAnimation = ({ onFinish, showAlways = false }) => {
  const [visible, setVisible] = useState(() => {
    if (showAlways) return true;
    const seen = localStorage.getItem('valley_seen_splash');
    return !seen;
  });

  const handleClose = () => {
    localStorage.setItem('valley_seen_splash', 'true');
    setVisible(false);
    if (onFinish) onFinish();
  };

  if (!visible) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 99999,
        background: '#FFFFFF',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        fontFamily: "'Poppins', sans-serif",
      }}
    >
      <style>{`
        .v-draw {
          stroke-dasharray: 1;
          stroke-dashoffset: 1;
          animation: draw-anim 5s ease-in-out infinite;
        }
        .sq-pop {
          transform-origin: 140px 80px;
          animation: pop-anim 5s ease-out infinite;
        }
        .l1-anim, .l2-anim, .l3-anim {
          opacity: 0;
          animation: slide-anim 5s ease-out infinite;
        }
        .l2-anim { animation-delay: .06s; }
        .l3-anim { animation-delay: .12s; }
        .dot-hop {
          animation: hop-anim 1.2s ease-in-out infinite, dotin-anim 5s linear infinite;
        }
        @keyframes dotin-anim {
          0%, 8% { opacity: 0; }
          12%, 94% { opacity: 1; }
          100% { opacity: 0; }
        }
        .w1-up, .w2-up, .w3-up {
          opacity: 0;
          animation: up-anim 5s ease-out infinite;
        }
        .w2-up { animation-delay: .08s; }
        .w3-up { animation-delay: .16s; }
        .bike-ride {
          transform: translateX(345px);
          opacity: 0;
          animation: ride-anim 5s linear infinite;
        }
        .bob-anim {
          animation: bob-anim .45s ease-in-out infinite;
        }
        .spin-wheel {
          transform-box: fill-box;
          transform-origin: center;
          animation: spin-anim .5s linear infinite;
        }
        @keyframes pop-anim {
          0% { transform: scale(.6); opacity: 0; }
          8% { transform: scale(1.06); opacity: 1; }
          12%, 94% { transform: scale(1); opacity: 1; }
          100% { transform: scale(1); opacity: 0; }
        }
        @keyframes draw-anim {
          0%, 4% { stroke-dashoffset: 1; opacity: 1; }
          16%, 93% { stroke-dashoffset: 0; opacity: 1; }
          98% { stroke-dashoffset: 0; opacity: 0; }
          100% { stroke-dashoffset: 1; opacity: 0; }
        }
        @keyframes slide-anim {
          0%, 6% { transform: translateX(30px); opacity: 0; }
          12% { transform: translateX(0); opacity: 1; }
          24%, 100% { transform: translateX(-26px); opacity: 0; }
        }
        @keyframes hop-anim {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-7px); }
        }
        @keyframes up-anim {
          0%, 28% { opacity: 0; transform: translateY(18px); }
          40%, 93% { opacity: 1; transform: translateY(0); }
          98%, 100% { opacity: 0; transform: translateY(0); }
        }
        @keyframes ride-anim {
          0%, 18% { transform: translateX(345px) scale(.6); opacity: 0; }
          23%, 26% { transform: translateX(345px) scale(1); opacity: 1; animation-timing-function: ease-in; }
          46%, 100% { transform: translateX(950px) scale(1); opacity: 1; }
        }
        @keyframes bob-anim {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-2px); }
        }
        @keyframes spin-anim {
          to { transform: rotate(360deg); }
        }
      `}</style>

      {/* Main Animated Stage Container */}
      <div
        style={{
          position: 'relative',
          overflow: 'hidden',
          width: '880px',
          maxWidth: '95vw',
          height: '560px',
          maxHeight: '90vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '16px',
        }}
      >
        {/* Animated Logo Mark */}
        <svg viewBox="0 0 260 160" width="260" height="160" role="img" aria-label="Valley Express logo mark">
          <g stroke="#003893" strokeWidth="8" strokeLinecap="round">
            <line className="l1-anim" x1="10" y1="52" x2="50" y2="52"></line>
            <line className="l2-anim" x1="22" y1="80" x2="52" y2="80"></line>
            <line className="l3-anim" x1="10" y1="108" x2="50" y2="108"></line>
          </g>
          <rect className="sq-pop" x="70" y="10" width="140" height="140" rx="34" fill="#FF6B1A"></rect>
          <path
            className="v-draw"
            pathLength="1"
            d="M104 56 L140 120 L176 56"
            fill="none"
            stroke="#FFFFFF"
            strokeWidth="14"
            strokeLinecap="round"
            strokeLinejoin="round"
          ></path>
          <g className="dot-hop">
            <path d="M140 68 C135 61 131 56 131 49 A9 9 0 0 1 149 49 C149 56 145 61 140 68 Z" fill="#003893"></path>
            <circle cx="140" cy="49" r="3.5" fill="#FFFFFF"></circle>
          </g>
        </svg>

        {/* Wordmarks */}
        <div className="w1-up" style={{ fontSize: '78px', fontWeight: 700, color: '#003893', lineHeight: 1, letterSpacing: '-1px' }}>
          Valley
        </div>
        <div className="w2-up" style={{ fontSize: '24px', fontWeight: 700, color: '#FF6B1A', lineHeight: 1, letterSpacing: '8px', paddingLeft: '8px' }}>
          EXPRESS
        </div>
        <div className="w3-up" style={{ fontSize: '15px', fontWeight: 400, color: '#1F2A44', marginTop: '8px' }}>
          Fast to order. Fast to your door.
        </div>

        {/* Animated Scooter Rider */}
        <svg
          className="bike-ride"
          viewBox="-30 0 150 100"
          width="190"
          height="127"
          style={{ position: 'absolute', left: 0, bottom: '130px' }}
          role="img"
          aria-label="Delivery rider on a scooter"
        >
          <g stroke="#003893" strokeWidth="4" strokeLinecap="round" opacity="0.85">
            <line x1="-30" y1="36" x2="-8" y2="36"></line>
            <line x1="-24" y1="54" x2="-4" y2="54"></line>
            <line x1="-30" y1="72" x2="-8" y2="72"></line>
          </g>
          <g className="bob-anim">
            <g fill="none" stroke="#1F2A44" strokeWidth="4">
              <circle cx="38" cy="76" r="13"></circle>
              <circle cx="108" cy="76" r="13"></circle>
            </g>
            <g className="spin-wheel" stroke="#7A869E" strokeWidth="2" strokeLinecap="round">
              <line x1="28" y1="76" x2="48" y2="76"></line>
              <line x1="38" y1="66" x2="38" y2="86"></line>
            </g>
            <g className="spin-wheel" stroke="#7A869E" strokeWidth="2" strokeLinecap="round">
              <line x1="98" y1="76" x2="118" y2="76"></line>
              <line x1="108" y1="66" x2="108" y2="86"></line>
            </g>
            <line x1="104" y1="40" x2="108" y2="76" stroke="#1F2A44" strokeWidth="4" strokeLinecap="round"></line>
            <rect x="28" y="52" width="40" height="20" rx="9" fill="#FF6B1A" stroke="#1F2A44" strokeWidth="2"></rect>
            <rect x="62" y="66" width="40" height="8" rx="4" fill="#C2410C"></rect>
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
            <circle cx="70" cy="8" r="8" fill="#F2C9A0"></circle>
            <path d="M61 8 A9 9 0 0 1 79 8 Z" fill="#FF6B1A"></path>
          </g>
        </svg>
      </div>

      {/* Skip / Continue Button */}
      <button
        onClick={handleClose}
        style={{
          position: 'absolute',
          bottom: '36px',
          padding: '12px 28px',
          borderRadius: '4px',
          background: '#003893',
          color: '#FFFFFF',
          border: '1px solid #003893',
          fontSize: '14px',
          fontWeight: 500,
          cursor: 'pointer',
          fontFamily: "'Poppins', sans-serif",
        }}
      >
        Enter Valley Express Dashboard
      </button>
    </div>
  );
};

export default SplashScreenAnimation;
