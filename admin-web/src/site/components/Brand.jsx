import React from 'react';

/**
 * Official brand assets, served from /public/brand.
 *
 * These are the supplied artwork files rather than components redrawn from
 * them, so the site always shows the same mark as the rest of the brand. The
 * design values they carry (wordmark #003893, "EXPRESS" #E8590C at 14px
 * tracking, secondary text #3D4A6B, 34px corner radius) are mirrored in the
 * tokens at the top of site.css.
 */

export const BrandMark = ({ size = 34, className = '' }) => (
  <img
    src="/brand/valley-express-mark.svg"
    width={size}
    height={size}
    alt=""
    className={className}
    draggable="false"
  />
);

export const BrandLogo = ({ height = 44, className = '' }) => (
  <img
    src="/brand/valley-express-logo-static.svg"
    height={height}
    alt="Valley Express"
    className={className}
    style={{ height, width: 'auto' }}
    draggable="false"
  />
);

/**
 * Header lockup: the supplied mark beside the wordmark set to the values in
 * the design mockup (Poppins 700 #003893 at -2px tracking, "EXPRESS" in 500
 * #E8590C at wide tracking). The static artwork is a 880×560 artboard with the
 * wordmark stacked and a rider beneath it, so it is used whole on the About
 * page and rebuilt at lockup proportions here.
 */
export const BrandLockup = ({ className = '' }) => (
  <span className={`vx-lockup ${className}`.trim()}>
    <BrandMark size={34} />
    <span className="vx-lockup-type">
      <strong>Valley</strong>
      <small>EXPRESS</small>
    </span>
  </span>
);

/** The supplied loader: the mark breathing while the V traces itself. */
export const BrandLoader = ({ size = 64, label = 'Loading…' }) => (
  <div className="vx-loader" role="status" aria-live="polite">
    <img src="/brand/valley-express-loader.svg" width={size} height={size} alt="" draggable="false" />
    {label && <span>{label}</span>}
  </div>
);

export default BrandMark;
