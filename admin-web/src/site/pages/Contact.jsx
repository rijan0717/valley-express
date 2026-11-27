import React, { useState } from 'react';
import { motion } from 'framer-motion';
import Seo from '../components/Seo';
import Reveal from '../components/Reveal';
import { sendContactMessage } from '../api';
import { BRAND } from '../content/site';

const SUBJECTS = [
  'An order I placed',
  'Becoming a rider',
  'Stocking our product',
  'Press and partnerships',
  'Something else',
];

const Contact = () => {
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    subject: SUBJECTS[0],
    message: '',
  });
  const [status, setStatus] = useState({ state: 'idle', message: '' });

  const update = (field) => (event) =>
    setForm((current) => ({ ...current, [field]: event.target.value }));

  const submit = async (event) => {
    event.preventDefault();
    if (status.state === 'sending') return;
    setStatus({ state: 'sending', message: '' });
    const result = await sendContactMessage(form);
    if (result.ok) {
      setStatus({ state: 'done', message: result.message });
      setForm({ name: '', email: '', phone: '', subject: SUBJECTS[0], message: '' });
    } else {
      setStatus({ state: 'error', message: result.message });
    }
  };

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'ContactPage',
    name: `Contact ${BRAND.name}`,
    mainEntity: {
      '@type': 'Organization',
      name: BRAND.name,
      email: BRAND.email,
      telephone: BRAND.phone,
      address: {
        '@type': 'PostalAddress',
        addressLocality: 'Kathmandu',
        addressRegion: 'Bagmati',
        addressCountry: 'NP',
      },
    },
  };

  return (
    <>
      <Seo
        title="Contact Us — Valley Express Support in Kathmandu"
        description="Message the Valley Express team about an order, riding with us, stocking your product or a partnership. Our Kathmandu desk replies within one working day."
        path="/contact"
        jsonLd={jsonLd}
      />

      <section className="vx-page-hero">
        <div className="vx-container">
          <Reveal>
            <span className="vx-eyebrow">Contact</span>
            <h1 className="vx-page-title">Talk to the people who pack the bags.</h1>
            <p className="vx-page-sub">
              Orders, rider applications, supplier questions or something we have not thought of — this form
              reaches the Valley Express desk in Kathmandu.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="vx-section">
        <div className="vx-container vx-contact-grid">
          <Reveal direction="right" className="vx-contact-form-wrap">
            {status.state === 'done' ? (
              <motion.div
                className="vx-contact-done"
                initial={{ opacity: 0, scale: 0.97 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.35 }}
              >
                <h2 className="vx-h3">Message sent</h2>
                <p className="vx-body">{status.message}</p>
                <button
                  type="button"
                  className="vx-btn vx-btn-ghost"
                  onClick={() => setStatus({ state: 'idle', message: '' })}
                >
                  Send another message
                </button>
              </motion.div>
            ) : (
              <form className="vx-form vx-contact-form" onSubmit={submit} noValidate>
                <div className="vx-field-row">
                  <div className="vx-field">
                    <label className="vx-label" htmlFor="contact-name">
                      Your name
                    </label>
                    <input
                      id="contact-name"
                      className="vx-input"
                      value={form.name}
                      onChange={update('name')}
                      autoComplete="name"
                      required
                    />
                  </div>
                  <div className="vx-field">
                    <label className="vx-label" htmlFor="contact-phone">
                      Mobile number
                    </label>
                    <input
                      id="contact-phone"
                      className="vx-input"
                      type="tel"
                      placeholder="98XXXXXXXX"
                      value={form.phone}
                      onChange={update('phone')}
                      autoComplete="tel"
                    />
                  </div>
                </div>

                <div className="vx-field">
                  <label className="vx-label" htmlFor="contact-email">
                    Email address
                  </label>
                  <input
                    id="contact-email"
                    className="vx-input"
                    type="email"
                    placeholder="you@example.com"
                    value={form.email}
                    onChange={update('email')}
                    autoComplete="email"
                  />
                </div>

                <div className="vx-field">
                  <label className="vx-label" htmlFor="contact-subject">
                    What is this about?
                  </label>
                  <select
                    id="contact-subject"
                    className="vx-input"
                    value={form.subject}
                    onChange={update('subject')}
                  >
                    {SUBJECTS.map((subject) => (
                      <option key={subject} value={subject}>
                        {subject}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="vx-field">
                  <label className="vx-label" htmlFor="contact-message">
                    Your message
                  </label>
                  <textarea
                    id="contact-message"
                    className="vx-input vx-textarea"
                    rows={6}
                    value={form.message}
                    onChange={update('message')}
                    required
                  />
                </div>

                {status.state === 'error' && (
                  <p className="vx-form-error" role="alert">
                    {status.message}
                  </p>
                )}

                <button
                  type="submit"
                  className="vx-btn vx-btn-primary vx-btn-lg"
                  disabled={status.state === 'sending'}
                >
                  {status.state === 'sending' ? 'Sending…' : 'Send message'}
                </button>
                <p className="vx-form-note">
                  We use what you send here only to reply to you. Leave either an email address or a mobile
                  number so we can reach you.
                </p>
              </form>
            )}
          </Reveal>

          <Reveal direction="left" delay={0.1} className="vx-contact-side">
            <div className="vx-contact-card">
              <h2 className="vx-h3">Direct lines</h2>
              <dl className="vx-contact-list">
                <div>
                  <dt>Email</dt>
                  <dd>
                    <a href={`mailto:${BRAND.email}`}>{BRAND.email}</a>
                  </dd>
                </div>
                <div>
                  <dt>Phone</dt>
                  <dd>
                    <a href={`tel:${BRAND.phone.replace(/\s/g, '')}`}>{BRAND.phone}</a>
                  </dd>
                </div>
                <div>
                  <dt>Where we are</dt>
                  <dd>{BRAND.address}</dd>
                </div>
                <div>
                  <dt>Order hours</dt>
                  <dd>
                    Every day, {BRAND.hours.open} – {BRAND.hours.close}
                  </dd>
                </div>
              </dl>
            </div>

            <div className="vx-contact-card vx-contact-card-accent">
              <h2 className="vx-h3">Have a live order?</h2>
              <p className="vx-body">
                The fastest route is the chat inside the app — it reaches the support desk and your rider
                while the order is still moving. This form is better for everything else.
              </p>
            </div>

            <div className="vx-contact-card">
              <h2 className="vx-h3">Ride with us</h2>
              <p className="vx-body">
                We take on riders across {BRAND.cities.join(', ')}. Tell us which area you know best and
                whether you ride your own bike or scooter.
              </p>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
};

export default Contact;
