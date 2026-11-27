import React from 'react';
import { motion } from 'framer-motion';
import Seo, { organizationJsonLd } from '../components/Seo';
import Reveal, { RevealGroup, revealItem } from '../components/Reveal';
import StoreBadges from '../components/StoreBadges';
import FeatureIcon from '../components/FeatureIcon';
import { ScooterRider } from '../../components/Logo';
import { BRAND, CATEGORIES } from '../content/site';

const PRINCIPLES = [
  {
    icon: 'pin',
    title: 'Local before clever',
    body:
      'Routing, delivery zones and rider shifts are tuned to how the Valley actually moves. A map pin and a quick message beat a street address every time.',
  },
  {
    icon: 'chat',
    title: 'Answerable end to end',
    body:
      'We hold the stock, employ the riders and staff the support desk. When an order goes wrong, one team owns it from the shelf to the gate.',
  },
  {
    icon: 'coin',
    title: 'Plain numbers',
    body:
      'One coin per Rs 10. Delivery from Rs 100. Free over Rs 1,500. If a figure cannot be explained in a sentence, it does not belong in the app.',
  },
  {
    icon: 'snow',
    title: 'Honest promises',
    body:
      'We would rather tell you the real window than start a countdown that resets. Cold things ship cold or they do not ship.',
  },
];

const About = () => (
  <>
    <Seo
      title="About Us — Quick Delivery Built for Kathmandu Valley"
      description="Valley Express is an on-demand delivery service for snacks, soft drinks, ice, mixers and essentials across Kathmandu, Lalitpur and Bhaktapur, with its own storefront, rider fleet and support desk."
      path="/about"
      jsonLd={organizationJsonLd}
    />

    <section className="vx-page-hero">
      <div className="vx-container">
        <Reveal>
          <span className="vx-eyebrow">About us</span>
          <h1 className="vx-page-title">
            A delivery service that behaves like it lives here.
          </h1>
          <p className="vx-page-sub">
            {BRAND.shortPitch} Built in Kathmandu, for the way the Valley actually orders.
          </p>
        </Reveal>
      </div>
    </section>

    <section className="vx-section">
      <div className="vx-container vx-split">
        <Reveal direction="right" className="vx-split-copy">
          <span className="vx-kicker">The problem we started with</span>
          <h2 className="vx-h2">Small errands are the ones nobody solves</h2>
          <p className="vx-lead">
            Ice for guests who are already at the door. The one mixer missing from the table. Milk, eggs
            and bread before the morning. None of it is worth crossing town for, and all of it is urgent.
          </p>
          <p className="vx-body">
            Valley Express exists for exactly those baskets. The catalogue is deliberately narrow —
            {' '}
            {CATEGORIES.map((category) => category.name.toLowerCase()).join(', ')} — because a short list
            that is always in stock is worth more than a long list that is mostly out of it.
          </p>
          <p className="vx-body">
            Our operations desk watches every live order on one board. If a rider is held up, somebody sees
            it and tells you, rather than waiting for you to ring and ask.
          </p>
        </Reveal>

        <Reveal direction="left" delay={0.1} className="vx-split-visual">
          <div className="vx-scooter-card">
            <motion.div
              animate={{ x: [0, 12, 0] }}
              transition={{ duration: 4.5, repeat: Infinity, ease: 'easeInOut' }}
            >
              <ScooterRider width={230} />
            </motion.div>
            <div className="vx-scooter-meta">
              <span className="vx-scooter-label">Coverage</span>
              <strong>{BRAND.cities.join(' · ')}</strong>
            </div>
          </div>
        </Reveal>
      </div>
    </section>

    <section className="vx-section vx-section-grey">
      <div className="vx-container">
        <Reveal className="vx-section-head">
          <span className="vx-kicker">How we work</span>
          <h2 className="vx-h2">Four things we will not trade away</h2>
        </Reveal>
        <RevealGroup className="vx-feature-grid">
          {PRINCIPLES.map((principle) => (
            <motion.article key={principle.title} className="vx-feature" variants={revealItem}>
              <span className="vx-feature-icon">
                <FeatureIcon name={principle.icon} />
              </span>
              <h3>{principle.title}</h3>
              <p>{principle.body}</p>
            </motion.article>
          ))}
        </RevealGroup>
      </div>
    </section>

    <section className="vx-section">
      <div className="vx-container vx-prose">
        <Reveal>
          <h2 className="vx-h2">On alcohol</h2>
          <p className="vx-body">
            We are asked this often enough that it deserves a straight answer. Valley Express does not
            deliver alcohol. An alcohol category exists in our system, built and ready, and it stays
            switched off until a liquor licence is issued to the store. Until that day we carry mixers,
            soft drinks and ice — and nothing stronger.
          </p>
          <h2 className="vx-h2">Where we are going</h2>
          <p className="vx-body">
            The apps for Android and iPhone are in final testing, the rider fleet is growing across the
            three cities, and the catalogue widens as we learn what people actually run out of. If there is
            something you think we should carry, the contact form reaches a person, not a queue.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <StoreBadges theme="light" />
        </Reveal>
      </div>
    </section>
  </>
);

export default About;
