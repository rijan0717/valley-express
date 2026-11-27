import React, { useEffect, useRef, useState } from 'react';
import { animate, useInView } from 'framer-motion';

/**
 * A number that counts up the first time it is scrolled into view.
 *
 * Reduced-motion users get the final value immediately — a figure ticking up
 * is decoration, and nobody should have to wait for it.
 */
const CountUp = ({ to, from = 0, duration = 1.1, prefix = '', suffix = '', decimals = 0 }) => {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, amount: 0.6 });
  const [value, setValue] = useState(from);

  useEffect(() => {
    if (!inView) return undefined;

    const reduced =
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (reduced) {
      setValue(to);
      return undefined;
    }

    const controls = animate(from, to, {
      duration,
      ease: [0.22, 0.61, 0.36, 1],
      onUpdate: (latest) => setValue(latest),
    });
    return () => controls.stop();
  }, [inView, from, to, duration]);

  const shown = decimals
    ? value.toFixed(decimals)
    : Math.round(value).toLocaleString('en-NP');

  return (
    <span ref={ref} className="vx-countup">
      {prefix}
      {shown}
      {suffix}
    </span>
  );
};

export default CountUp;
