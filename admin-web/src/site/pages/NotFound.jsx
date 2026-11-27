import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import Seo from '../components/Seo';
import { ScooterRider } from '../../components/Logo';

/**
 * Public 404. Deliberately offers no route into the dashboard — a visitor who
 * mistypes a URL is sent back to the shop front, not shown that staff software
 * exists behind it.
 */
const NotFound = () => (
  <>
    <Seo
      title="Page Not Found"
      description="That page is not here. Head back to the Valley Express home page."
      path="/404"
      noIndex
    />
    <section className="vx-notfound">
      <div className="vx-container">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <motion.div
            animate={{ x: [-14, 14, -14] }}
            transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
          >
            <ScooterRider width={240} />
          </motion.div>
          <h1 className="vx-page-title">This address does not exist.</h1>
          <p className="vx-page-sub">
            Even our riders could not find it. Let us get you back to somewhere useful.
          </p>
          <div className="vx-hero-actions">
            <Link to="/" className="vx-btn vx-btn-primary vx-btn-lg">
              Back to home
            </Link>
            <Link to="/contact" className="vx-btn vx-btn-ghost vx-btn-lg">
              Contact us
            </Link>
          </div>
        </motion.div>
      </div>
    </section>
  </>
);

export default NotFound;
