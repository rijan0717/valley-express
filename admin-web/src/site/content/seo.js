import { BRAND } from './site.js';
import { POSTS } from './posts.js';

/**
 * Single source of truth for page metadata.
 *
 * The React pages read it at runtime, and scripts/prerender-meta.mjs reads the
 * same file at build time to write a static HTML shell per route. Keeping one
 * copy is the point: social crawlers only ever see the static version, so a
 * second hand-maintained list would drift silently.
 */
export const SITE_URL = 'https://valleyexpress.com.np';

export const ROUTE_SEO = {
  '/': {
    title: 'Snacks, Drinks and Ice Delivered Across Kathmandu Valley',
    description: `${BRAND.shortPitch} Live rider tracking, Valley Coins on every order, and delivery across Kathmandu, Lalitpur and Bhaktapur.`,
  },
  '/about': {
    title: 'About Us — Quick Delivery Built for Kathmandu Valley',
    description:
      'Valley Express is an on-demand delivery service for snacks, soft drinks, ice, mixers and essentials across Kathmandu, Lalitpur and Bhaktapur, with its own storefront, rider fleet and support desk.',
  },
  '/blog': {
    title: 'Blog — Notes from the Valley Express Operations Desk',
    description:
      'How quick delivery actually works in Kathmandu Valley: routing, Valley Coins, keeping ice frozen, and building an app riders can use one-handed.',
  },
  '/contact': {
    title: 'Contact Us — Valley Express Support in Kathmandu',
    description:
      'Message the Valley Express team about an order, riding with us, stocking your product or a partnership. Our Kathmandu desk replies within one working day.',
  },
  '/privacy': {
    title: 'Privacy Policy',
    description:
      'What Valley Express collects when you order, why we hold it, how long we keep it, and how to ask for a copy or its deletion.',
  },
  '/terms': {
    title: 'Terms of Service',
    description:
      'The terms you agree to when ordering from Valley Express: orders, pricing, delivery, Valley Coins, age restrictions and liability.',
  },
  '/refunds': {
    title: 'Refund and Cancellation Policy',
    description:
      'When a Valley Express order can be cancelled, what happens to a missing or damaged item, and how refunds and Valley Coins are returned.',
  },
  '/ride-with-us': {
    title: 'Ride With Us — Rider Jobs in Kathmandu Valley',
    description:
      'Ride for Valley Express across Kathmandu, Lalitpur and Bhaktapur. What the work involves, what you need, and how to apply.',
  },
};

/** Every public URL, for the sitemap and the prerender step. */
export const routeList = () => [
  ...Object.keys(ROUTE_SEO),
  ...POSTS.map((post) => `/blog/${post.slug}`),
];

export const postSeo = (post) => ({
  title: post.title,
  description: post.excerpt,
});
