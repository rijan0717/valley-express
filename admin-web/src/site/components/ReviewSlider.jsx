import React, { useCallback, useEffect, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { REVIEWS } from '../content/reviews';

/**
 * Reviews as a single large pull quote rather than a row of boxed cards: one
 * voice at a time, the way a printed page would set it. Auto-advances, pauses
 * on hover or focus, drags on touch, and answers the arrow keys.
 */
const ReviewSlider = () => {
  const [index, setIndex] = useState(0);
  const [direction, setDirection] = useState(1);
  const [paused, setPaused] = useState(false);

  const go = useCallback(
    (next) => {
      setDirection(next > index || (index === REVIEWS.length - 1 && next === 0) ? 1 : -1);
      setIndex((next + REVIEWS.length) % REVIEWS.length);
    },
    [index]
  );

  useEffect(() => {
    if (paused) return undefined;
    const timer = setTimeout(() => go(index + 1), 7000);
    return () => clearTimeout(timer);
  }, [index, paused, go]);

  const review = REVIEWS[index];

  return (
    <div
      className="vx-quotes"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocusCapture={() => setPaused(true)}
      onBlurCapture={() => setPaused(false)}
      onKeyDown={(event) => {
        if (event.key === 'ArrowRight') go(index + 1);
        if (event.key === 'ArrowLeft') go(index - 1);
      }}
      role="region"
      aria-roledescription="carousel"
      aria-label="What people say about Valley Express"
      tabIndex={0}
    >
      <span className="vx-quote-mark" aria-hidden="true">
        &ldquo;
      </span>

      <div className="vx-quote-stage">
        <AnimatePresence mode="wait" custom={direction}>
          <motion.figure
            key={index}
            className="vx-quote"
            initial={{ opacity: 0, y: direction * 18 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: direction * -18 }}
            transition={{ duration: 0.45, ease: [0.22, 0.61, 0.36, 1] }}
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={0.12}
            onDragEnd={(_, info) => {
              if (info.offset.x < -60) go(index + 1);
              if (info.offset.x > 60) go(index - 1);
            }}
          >
            <blockquote>{review.quote}</blockquote>
            <figcaption>
              <span className="vx-quote-rating" aria-label={`${review.rating} out of 5`}>
                {'★'.repeat(review.rating)}
                <em>{'★'.repeat(5 - review.rating)}</em>
              </span>
              <span className="vx-quote-place">{review.role}</span>
            </figcaption>
          </motion.figure>
        </AnimatePresence>
      </div>

      <div className="vx-quote-nav">
        <span className="vx-quote-count">
          {String(index + 1).padStart(2, '0')} / {String(REVIEWS.length).padStart(2, '0')}
        </span>
        <div className="vx-quote-ticks">
          {REVIEWS.map((item, dotIndex) => (
            <button
              key={item.quote}
              type="button"
              className={`vx-quote-tick${dotIndex === index ? ' is-active' : ''}`}
              onClick={() => go(dotIndex)}
              aria-label={`Review ${dotIndex + 1} of ${REVIEWS.length}`}
              aria-current={dotIndex === index}
            />
          ))}
        </div>
        <div className="vx-quote-arrows">
          <button type="button" onClick={() => go(index - 1)} aria-label="Previous review">
            ←
          </button>
          <button type="button" onClick={() => go(index + 1)} aria-label="Next review">
            →
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReviewSlider;
