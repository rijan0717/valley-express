import React from 'react';
import { motion } from 'framer-motion';

/**
 * Scroll-triggered entrance used across the public pages.
 * `once` keeps a section from re-animating every time it scrolls past, and
 * framer-motion already drops the animation for prefers-reduced-motion users.
 */
const DIRECTIONS = {
  up: { y: 28, x: 0 },
  down: { y: -28, x: 0 },
  left: { x: 36, y: 0 },
  right: { x: -36, y: 0 },
  none: { x: 0, y: 0 },
};

export const Reveal = ({
  children,
  delay = 0,
  direction = 'up',
  className = '',
  as = 'div',
}) => {
  const offset = DIRECTIONS[direction] || DIRECTIONS.up;
  const MotionTag = motion[as] || motion.div;

  return (
    <MotionTag
      className={className}
      initial={{ opacity: 0, ...offset }}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true, amount: 0.25 }}
      transition={{ duration: 0.55, delay, ease: [0.22, 0.61, 0.36, 1] }}
    >
      {children}
    </MotionTag>
  );
};

/** Staggers direct children that are themselves motion elements. */
export const RevealGroup = ({ children, className = '', stagger = 0.08 }) => (
  <motion.div
    className={className}
    initial="hidden"
    whileInView="visible"
    viewport={{ once: true, amount: 0.2 }}
    variants={{
      hidden: {},
      visible: { transition: { staggerChildren: stagger } },
    }}
  >
    {children}
  </motion.div>
);

export const revealItem = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 0.61, 0.36, 1] } },
};

export default Reveal;
