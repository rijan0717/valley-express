import { useEffect } from 'react';
import { BRAND } from '../content/site';

const SITE_URL = 'https://valleyexpress.com.np';

/**
 * Per-page document head for the public site.
 *
 * react-helmet is not in the dependency list, and one small effect does the
 * same job here: set the title, the description, the canonical URL, the social
 * cards and an optional JSON-LD block, then put back whatever was there when
 * the page unmounts (the admin dashboard keeps its own title that way).
 */
const upsertMeta = (selector, attrs) => {
  let el = document.head.querySelector(selector);
  let created = false;
  if (!el) {
    el = document.createElement(attrs.tag || 'meta');
    created = true;
  }
  const previous = {};
  Object.entries(attrs).forEach(([key, value]) => {
    if (key === 'tag') return;
    previous[key] = el.getAttribute(key);
    el.setAttribute(key, value);
  });
  if (created) document.head.appendChild(el);
  return () => {
    if (created) {
      el.remove();
      return;
    }
    Object.entries(previous).forEach(([key, value]) => {
      if (value === null) el.removeAttribute(key);
      else el.setAttribute(key, value);
    });
  };
};

const Seo = ({
  title,
  description,
  path = '/',
  image = '/og-image.png',
  type = 'website',
  jsonLd,
  noIndex = false,
}) => {
  const fullTitle = title ? `${title} | ${BRAND.name}` : `${BRAND.name} — ${BRAND.tagline}`;
  const url = `${SITE_URL}${path}`;

  useEffect(() => {
    const previousTitle = document.title;
    document.title = fullTitle;

    const cleanups = [
      upsertMeta('meta[name="description"]', { name: 'description', content: description }),
      upsertMeta('link[rel="canonical"]', { tag: 'link', rel: 'canonical', href: url }),
      upsertMeta('meta[property="og:title"]', { property: 'og:title', content: fullTitle }),
      upsertMeta('meta[property="og:description"]', { property: 'og:description', content: description }),
      upsertMeta('meta[property="og:url"]', { property: 'og:url', content: url }),
      upsertMeta('meta[property="og:type"]', { property: 'og:type', content: type }),
      upsertMeta('meta[property="og:image"]', { property: 'og:image', content: `${SITE_URL}${image}` }),
      upsertMeta('meta[property="og:site_name"]', { property: 'og:site_name', content: BRAND.name }),
      upsertMeta('meta[name="twitter:card"]', { name: 'twitter:card', content: 'summary_large_image' }),
      upsertMeta('meta[name="twitter:title"]', { name: 'twitter:title', content: fullTitle }),
      upsertMeta('meta[name="twitter:description"]', { name: 'twitter:description', content: description }),
      upsertMeta('meta[name="twitter:image"]', { name: 'twitter:image', content: `${SITE_URL}${image}` }),
      upsertMeta('meta[name="robots"]', {
        name: 'robots',
        content: noIndex ? 'noindex, nofollow' : 'index, follow',
      }),
    ];

    let script;
    if (jsonLd) {
      script = document.createElement('script');
      script.type = 'application/ld+json';
      script.textContent = JSON.stringify(jsonLd);
      document.head.appendChild(script);
    }

    return () => {
      document.title = previousTitle;
      cleanups.forEach((undo) => undo());
      if (script) script.remove();
    };
  }, [fullTitle, description, url, type, image, noIndex, jsonLd]);

  return null;
};

export const organizationJsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: BRAND.name,
  url: SITE_URL,
  logo: `${SITE_URL}/full-logo.svg`,
  description: BRAND.shortPitch,
  areaServed: BRAND.cities.map((city) => ({ '@type': 'City', name: city })),
  address: {
    '@type': 'PostalAddress',
    addressLocality: 'Kathmandu',
    addressRegion: 'Bagmati',
    addressCountry: 'NP',
  },
};

export { SITE_URL };
export default Seo;
