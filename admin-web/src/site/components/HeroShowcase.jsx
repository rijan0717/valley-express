import React from 'react';

/**
 * Hero visual: three columns of phones running the Valley Express app, each
 * column scrolling vertically at its own pace — the middle one travelling the
 * opposite way to the outer two.
 *
 * The scroll is a CSS marquee rather than a JS animation: each track holds its
 * phones twice over and translates by exactly -50%, so the loop is seamless
 * and the whole thing runs on the compositor. No timers, nothing to throttle
 * on a cheap Android, and it stops dead under prefers-reduced-motion.
 *
 * Captures live in public/brand/app at 344x746.
 */

const SCREENS = {
  welcome: { src: '/brand/app/app-welcome.png', alt: 'The Valley Express app welcome screen' },
  signin: { src: '/brand/app/app-signin.png', alt: 'Signing in to Valley Express' },
  chat: { src: '/brand/app/app-chat.png', alt: 'Messages and chats with dispatch, riders and support' },
  address: { src: '/brand/app/app-address.png', alt: 'Choosing a delivery pin and landmark on the map' },
};

const COLUMNS = [
  { key: 'a', width: 158, duration: 34, direction: 'up', screens: ['welcome', 'chat', 'address'] },
  { key: 'b', width: 196, duration: 28, direction: 'down', screens: ['address', 'signin', 'welcome'] },
  { key: 'c', width: 172, duration: 38, direction: 'up', screens: ['chat', 'address', 'signin'] },
];

const Phone = ({ screen, width, hidden }) => (
  <div className="vx-ph" style={{ '--ph-w': `${width}px` }}>
    {/* iPhone furniture: side rails, Dynamic Island and home indicator. */}
    <span className="vx-ph-btn vx-ph-btn-action" />
    <span className="vx-ph-btn vx-ph-btn-up" />
    <span className="vx-ph-btn vx-ph-btn-down" />
    <span className="vx-ph-btn vx-ph-btn-power" />

    <div className="vx-ph-screen">
      {/* WebP with the PNG as fallback — only one of the pair is ever
          fetched. Dimensions are stated so the frame reserves its space and
          nothing shifts as the images arrive, and the first copy loads eagerly
          because it sits in the hero. */}
      <picture>
        <source srcSet={screen.src.replace(/\.png$/, '.webp')} type="image/webp" />
        <img
          src={screen.src}
          /* The duplicated half of each track is decorative — announcing every
             screen twice would only clutter a screen reader. */
          alt={hidden ? '' : screen.alt}
          aria-hidden={hidden || undefined}
          draggable="false"
          className="vx-ph-shot"
          width="344"
          height="746"
          loading={hidden ? 'lazy' : 'eager'}
          decoding="async"
        />
      </picture>
      <span className="vx-ph-island" />
      <span className="vx-ph-glare" />
      <span className="vx-ph-home" />
    </div>
  </div>
);

const Column = ({ column }) => {
  const screens = column.screens.map((name) => SCREENS[name]);

  return (
    <div className={`vx-ph-col vx-ph-col-${column.key}`}>
      <div
        className={`vx-ph-track vx-ph-track-${column.direction}`}
        style={{ '--marquee-duration': `${column.duration}s` }}
      >
        {[0, 1].map((copy) =>
          screens.map((screen, index) => (
            <Phone
              key={`${copy}-${column.key}-${index}`}
              screen={screen}
              width={column.width}
              hidden={copy === 1}
            />
          ))
        )}
      </div>
    </div>
  );
};

const HeroShowcase = () => (
  <div className="vx-cluster">
    {COLUMNS.map((column) => (
      <Column key={column.key} column={column} />
    ))}
  </div>
);

export default HeroShowcase;
