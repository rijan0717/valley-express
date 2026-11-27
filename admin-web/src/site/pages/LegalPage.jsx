import React from 'react';
import { Link } from 'react-router-dom';
import Seo from '../components/Seo';
import Reveal from '../components/Reveal';
import { ROUTE_SEO } from '../content/seo';
import { LEGAL_UPDATED, PRIVACY, TERMS, REFUNDS, RIDE_WITH_US } from '../content/legal';
import { BRAND } from '../content/site';

/**
 * One component serves the four text pages: privacy, terms, refunds and the
 * rider advert. They share a layout, and the copy lives in content/legal.js.
 *
 * The draft banner is deliberate: this copy has not been through legal review
 * and still carries [BRACKETED PLACEHOLDERS]. Remove the banner when the real
 * text lands, not before.
 */
const DOCS = {
  privacy: { path: '/privacy', heading: 'Privacy Policy', doc: PRIVACY, draft: true },
  terms: { path: '/terms', heading: 'Terms of Service', doc: TERMS, draft: true },
  refunds: { path: '/refunds', heading: 'Refund and Cancellation Policy', doc: REFUNDS, draft: true },
  'ride-with-us': {
    path: '/ride-with-us',
    heading: 'Ride with us',
    doc: RIDE_WITH_US,
    draft: false,
  },
};

const LegalPage = ({ name }) => {
  const entry = DOCS[name];
  const seo = ROUTE_SEO[entry.path];
  const { doc } = entry;

  return (
    <>
      <Seo title={seo.title} description={seo.description} path={entry.path} />

      <section className="vx-page-hero">
        <div className="vx-container vx-prose">
          <Reveal>
            <span className="vx-eyebrow">{entry.draft ? 'Draft' : 'Join the fleet'}</span>
            <h1 className="vx-page-title">{entry.heading}</h1>
            <p className="vx-page-sub">{doc.intro}</p>
            {entry.draft && (
              <p className="vx-article-meta">Last reviewed: {LEGAL_UPDATED}</p>
            )}
          </Reveal>
        </div>
      </section>

      <section className="vx-section">
        <div className="vx-container vx-prose">
          {entry.draft && (
            <Reveal>
              <p className="vx-note vx-note-strong">
                This is a working draft. It has not been reviewed by a lawyer, and the bracketed
                items below are decisions still to be made. Do not rely on it as a statement of
                your rights until it is finalised.
              </p>
            </Reveal>
          )}

          {doc.sections.map((section, index) => (
            <Reveal key={section.heading} delay={Math.min(index * 0.04, 0.2)}>
              <h2 className="vx-h2 vx-h2-doc">{section.heading}</h2>
              {section.body?.map((paragraph) => (
                <p className="vx-body" key={paragraph.slice(0, 40)}>
                  {paragraph}
                </p>
              ))}
              {section.list && (
                <ul className="vx-doc-list">
                  {section.list.map((item) => (
                    <li key={item.slice(0, 40)}>{item}</li>
                  ))}
                </ul>
              )}
            </Reveal>
          ))}

          <Reveal>
            <div className="vx-article-cta">
              <h2 className="vx-h3">
                {name === 'ride-with-us' ? 'Ready to apply?' : 'Questions about this page?'}
              </h2>
              <p className="vx-body">
                {name === 'ride-with-us'
                  ? 'Tell us your area, your bike and your hours, and our Kathmandu desk will come back to you within one working day.'
                  : `Write to ${BRAND.email} or use the contact form and we will answer.`}
              </p>
              <Link to="/contact" className="vx-btn vx-btn-primary">
                {name === 'ride-with-us' ? 'Apply through the form' : 'Contact us'}
              </Link>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
};

export default LegalPage;
