import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import Seo, { organizationJsonLd, SITE_URL } from '../components/Seo';
import HeroShowcase from '../components/HeroShowcase';
import HeroBackdrop from '../components/HeroBackdrop';
import StoreBadges from '../components/StoreBadges';
import ReviewSlider from '../components/ReviewSlider';
import FeatureIcon from '../components/FeatureIcon';
import ValleyCoin from '../components/ValleyCoin';
import Reveal, { RevealGroup, revealItem } from '../components/Reveal';
import { useNotify } from '../components/NotifyModal';
import CountUp from '../components/CountUp';
import { BRAND, CATEGORIES, FEATURES, STEPS, FAQS } from '../content/site';
import { POSTS } from '../content/posts';

const formatPostDate = (iso) =>
  new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });

const Home = () => {
  const { openNotify } = useNotify();

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      organizationJsonLd,
      {
        '@type': 'WebSite',
        name: BRAND.name,
        url: SITE_URL,
        potentialAction: {
          '@type': 'SearchAction',
          target: `${SITE_URL}/blog?q={search_term_string}`,
          'query-input': 'required name=search_term_string',
        },
      },
      {
        '@type': 'FAQPage',
        mainEntity: FAQS.map((faq) => ({
          '@type': 'Question',
          name: faq.q,
          acceptedAnswer: { '@type': 'Answer', text: faq.a },
        })),
      },
    ],
  };

  return (
    <>
      <Seo
        title="Snacks, Drinks and Ice Delivered Across Kathmandu Valley"
        description={`${BRAND.shortPitch} Live rider tracking, Valley Coins on every order, and delivery across Kathmandu, Lalitpur and Bhaktapur.`}
        path="/"
        jsonLd={jsonLd}
      />

      {/* Hero */}
      <section className="vx-hero">
        <HeroBackdrop />
        <div className="vx-container vx-hero-inner">
          <motion.div
            className="vx-hero-copy"
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.22, 0.61, 0.36, 1] }}
          >
            <span className="vx-status">
              <i />
              Open today until {BRAND.hours.close}
            </span>

            <h1 className="vx-hero-title">
              Snacks, drinks and ice.
              <span className="vx-hero-accent">At your gate, not on a list.</span>
            </h1>

            <p className="vx-hero-sub">
              Quick delivery built for the Valley — ordered in a few taps, tracked on a live map, and
              earning Valley Coins on everything you spend.
            </p>

            <div className="vx-hero-actions">
              <button
                type="button"
                className="vx-btn vx-btn-primary vx-btn-lg"
                onClick={() => openNotify('either')}
              >
                Download the app
              </button>
              <Link to="/about" className="vx-link-arrow">
                What we are building
              </Link>
            </div>

            <dl className="vx-hero-facts">
              <div>
                <dt>Cities</dt>
                <dd>{BRAND.cities.join(' · ')}</dd>
              </div>
              <div>
                <dt>Open</dt>
                <dd>
                  {BRAND.hours.open}–{BRAND.hours.close}, daily
                </dd>
              </div>
              <div className="vx-fact-coin">
                <dt>Valley Coins</dt>
                <dd>
                  <ValleyCoin size={30} />
                  1 per Rs {BRAND.coinsPerRupees}
                </dd>
              </div>
            </dl>
          </motion.div>

          <motion.div
            className="vx-hero-visual"
            initial={{ opacity: 0, y: 36 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.15, ease: [0.22, 0.61, 0.36, 1] }}
          >
            <HeroShowcase />
          </motion.div>
        </div>

        {/* Categories run along the foot of the hero rather than sitting in
            their own boxed-out section. */}
        <div className="vx-ticker" role="list" aria-label="What we deliver">
          <div className="vx-ticker-track">
            {[0, 1].map((copy) => (
              <div className="vx-ticker-group" key={copy} aria-hidden={copy === 1}>
                {CATEGORIES.map((category) => (
                  <span className="vx-ticker-item" role="listitem" key={`${copy}-${category.name}`}>
                    <i />
                    {category.name}
                    <small>{category.note}</small>
                  </span>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* What the project is for */}
      <section className="vx-section">
        <div className="vx-container vx-split">
          <Reveal direction="right" className="vx-split-copy">
            <span className="vx-kicker">What it is for</span>
            <h2 className="vx-h2">
              The corner shop — if the corner shop could find your gate at ten at night.
            </h2>
            <p className="vx-lead">
              Most things you run out of are small, cheap and urgently needed. Ice before guests arrive. A
              mixer nobody remembered. Milk for the morning. Not worth crossing town for, and exactly what
              we built for.
            </p>
            <p className="vx-body">
              Valley Express runs its own storefront, its own rider fleet and its own operations desk, so
              one team answers for the stock, the route and the knock at your door.
            </p>
            <p className="vx-note">
              We do not deliver alcohol. The category exists in our system and stays switched off until a
              liquor licence is issued.
            </p>
          </Reveal>

          <Reveal direction="left" delay={0.1} className="vx-split-visual">
            <figure className="vx-fleet">
              <div className="vx-fleet-stage">
                {/* The supplied animated artboard. It carries its own CSS
                    animation and its own prefers-reduced-motion block, so it is
                    referenced as a file and left to run itself — no wrapper
                    motion, which would only fight it. */}
                <img
                  src="/brand/valley-express-animated.svg"
                  alt="Valley Express: fast to order, fast to your door"
                  className="vx-fleet-scooter"
                  loading="lazy"
                />
              </div>
              <figcaption>
                <strong>Our own riders</strong>
                <span>Not a marketplace of strangers — one fleet, one standard.</span>
              </figcaption>
              <dl className="vx-fleet-stats">
                <div>
                  <dt>Cities</dt>
                  <dd>{BRAND.cities.length}</dd>
                </div>
                <div>
                  <dt>Cold chain</dt>
                  <dd>Insulated</dd>
                </div>
                <div>
                  <dt>Tracking</dt>
                  <dd>Live</dd>
                </div>
              </dl>
            </figure>
          </Reveal>
        </div>
      </section>

      {/* Features — an editorial list, not a grid of identical cards */}
      <section className="vx-section vx-section-paper">
        <div className="vx-container vx-sticky-split">
          <div className="vx-sticky-head">
            <Reveal>
              <span className="vx-kicker">Why people keep it</span>
              <h2 className="vx-h2">
                Built around the parts that usually go wrong.
              </h2>
              <p className="vx-body">
                Every one of these started as a complaint about somebody else's delivery.
              </p>
            </Reveal>
          </div>

          <RevealGroup className="vx-list">
            {FEATURES.map((feature, index) => (
              <motion.article className="vx-list-row" key={feature.title} variants={revealItem}>
                <span className="vx-list-index">{String(index + 1).padStart(2, '0')}</span>
                <span className="vx-list-icon">
                  <FeatureIcon name={feature.icon} size={22} />
                </span>
                <div>
                  <h3>{feature.title}</h3>
                  <p>{feature.body}</p>
                </div>
              </motion.article>
            ))}
          </RevealGroup>
        </div>
      </section>

      {/* How it works — a route, not three boxes */}
      <section className="vx-section">
        <div className="vx-container">
          <Reveal className="vx-section-head">
            <span className="vx-kicker">How it works</span>
            <h2 className="vx-h2">Three steps, then the doorbell</h2>
          </Reveal>

          <RevealGroup className="vx-route">
            {STEPS.map((step, index) => (
              <motion.article className="vx-route-stop" key={step.title} variants={revealItem}>
                <span className="vx-route-dot">{index + 1}</span>
                <h3>{step.title}</h3>
                <p>{step.body}</p>
              </motion.article>
            ))}
          </RevealGroup>
        </div>
      </section>

      {/* Valley Coins */}
      <section className="vx-coins">
        <div className="vx-container vx-coins-inner">
          <Reveal direction="right">
            <span className="vx-kicker vx-kicker-light">Valley Coins</span>
            <h2 className="vx-h2 vx-h2-light">
              Spend Rs {BRAND.coinsPerRupees}, earn a coin. Spend the coins, pay less.
            </h2>
            <p className="vx-body vx-body-light">
              No tiers, no expiry clock, no points arithmetic. Coins land when an order is delivered and
              come off your basket whenever you choose to use them. Baskets over Rs{' '}
              {BRAND.freeDeliveryThreshold.toLocaleString('en-NP')} are delivered free on top.
            </p>
            <button
              type="button"
              className="vx-btn vx-btn-light vx-btn-lg"
              onClick={() => openNotify('either')}
            >
              Start earning at launch
            </button>
          </Reveal>

          <Reveal direction="left" delay={0.1}>
            <div className="vx-receipt-wrap">
            <ValleyCoin size={104} spin className="vx-receipt-coin" />
            <div className="vx-receipt" role="presentation">
              <div className="vx-receipt-row">
                <span>Basket</span>
                <span>
                  <CountUp to={1640} prefix="Rs " />
                </span>
              </div>
              <div className="vx-receipt-row">
                <span>Delivery</span>
                <span className="vx-receipt-free">Free</span>
              </div>
              <div className="vx-receipt-row vx-receipt-coins">
                <span>Valley Coins earned</span>
                <span>
                  +<CountUp to={164} />
                </span>
              </div>
              <div className="vx-receipt-rule" />
              <div className="vx-receipt-row vx-receipt-total">
                <span>Paid</span>
                <span>
                  <CountUp to={1640} prefix="Rs " />
                </span>
              </div>
              <p className="vx-receipt-note">Illustration of a typical basket.</p>
            </div>
            </div>
          </Reveal>
        </div>
      </section>

      {/* Reviews */}
      <section className="vx-section vx-section-quotes">
        <div className="vx-container">
          <Reveal className="vx-section-head">
            <span className="vx-kicker">From the Valley</span>
            <h2 className="vx-h2">What people say</h2>
          </Reveal>
          <Reveal delay={0.08}>
            <ReviewSlider />
          </Reveal>
          {/* Placeholder notice — see src/site/content/reviews.js */}
          <p className="vx-disclaimer">
            Sample reviews shown while we collect verified customer feedback.
          </p>
        </div>
      </section>

      {/* Blog — an index, not a card wall */}
      <section className="vx-section vx-section-grey">
        <div className="vx-container">
          <Reveal className="vx-section-head vx-section-head-row">
            <div>
              <span className="vx-kicker">From the desk</span>
              <h2 className="vx-h2">Notes on running a delivery service here</h2>
            </div>
            <Link to="/blog" className="vx-link-arrow">
              All posts
            </Link>
          </Reveal>

          <RevealGroup className="vx-index">
            {POSTS.slice(0, 3).map((post) => (
              <motion.article className="vx-index-row" key={post.slug} variants={revealItem}>
                <Link to={`/blog/${post.slug}`}>
                  <time dateTime={post.date}>{formatPostDate(post.date)}</time>
                  <h3>{post.title}</h3>
                  <span className="vx-index-tag">{post.tag}</span>
                  <span className="vx-index-arrow" aria-hidden="true">
                    →
                  </span>
                </Link>
              </motion.article>
            ))}
          </RevealGroup>
        </div>
      </section>

      {/* FAQ */}
      <section className="vx-section">
        <div className="vx-container vx-faq-wrap">
          <Reveal className="vx-section-head">
            <span className="vx-kicker">Questions</span>
            <h2 className="vx-h2">Before you ask</h2>
          </Reveal>
          <RevealGroup className="vx-faq">
            {FAQS.map((faq) => (
              <motion.details className="vx-faq-item" key={faq.q} variants={revealItem}>
                <summary>{faq.q}</summary>
                <p>{faq.a}</p>
              </motion.details>
            ))}
          </RevealGroup>
        </div>
      </section>

      {/* Download */}
      <section className="vx-cta">
        <div className="vx-container vx-cta-inner">
          <Reveal>
            <h2 className="vx-h2">Be first through the door.</h2>
            <p className="vx-body">
              The Android and iPhone apps are in final testing. Leave an email or a mobile number and we
              will tell you the day they go live.
            </p>
            <StoreBadges theme="light" />
          </Reveal>
        </div>

        {/* A rider crossing the foot of the page, on the road that becomes the
            footer rule. Decorative, so it is hidden from assistive tech. */}
        <div className="vx-cta-road" aria-hidden="true">
          <img src="/brand/valley-scooter.svg" alt="" className="vx-cta-scooter" loading="lazy" />
        </div>
      </section>
    </>
  );
};

export default Home;
