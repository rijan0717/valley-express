import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import Seo, { SITE_URL } from '../components/Seo';
import Reveal from '../components/Reveal';
import { POSTS } from '../content/posts';

const formatDate = (iso) =>
  new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'long', year: 'numeric' });

const Blog = () => {
  const tags = useMemo(() => ['All', ...new Set(POSTS.map((post) => post.tag))], []);
  const [tag, setTag] = useState('All');

  const visible = tag === 'All' ? POSTS : POSTS.filter((post) => post.tag === tag);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Blog',
    name: 'Valley Express Blog',
    url: `${SITE_URL}/blog`,
    blogPost: POSTS.map((post) => ({
      '@type': 'BlogPosting',
      headline: post.title,
      datePublished: post.date,
      url: `${SITE_URL}/blog/${post.slug}`,
      description: post.excerpt,
    })),
  };

  return (
    <>
      <Seo
        title="Blog — Notes from the Valley Express Operations Desk"
        description="How quick delivery actually works in Kathmandu Valley: routing, Valley Coins, keeping ice frozen, and building an app riders can use one-handed."
        path="/blog"
        jsonLd={jsonLd}
      />

      <section className="vx-page-hero">
        <div className="vx-container">
          <Reveal>
            <span className="vx-eyebrow">Blog</span>
            <h1 className="vx-page-title">Notes from the operations desk.</h1>
            <p className="vx-page-sub">
              How the service is built, what we got wrong on the way, and the small decisions behind a bag
              of ice arriving still frozen.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="vx-section">
        <div className="vx-container">
          <Reveal className="vx-tag-row">
            {tags.map((item) => (
              <button
                key={item}
                type="button"
                className={`vx-tag${tag === item ? ' is-active' : ''}`}
                onClick={() => setTag(item)}
              >
                {item}
              </button>
            ))}
          </Reveal>

          <motion.div layout className="vx-post-grid vx-post-grid-wide">
            <AnimatePresence mode="popLayout">
              {visible.map((post) => (
                <motion.article
                  key={post.slug}
                  layout
                  className="vx-post-card"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -12 }}
                  transition={{ duration: 0.35, ease: [0.22, 0.61, 0.36, 1] }}
                  whileHover={{ y: -6 }}
                >
                  <Link to={`/blog/${post.slug}`}>
                    <span className="vx-post-tag">{post.tag}</span>
                    <h2>{post.title}</h2>
                    <p>{post.excerpt}</p>
                    <span className="vx-post-meta">
                      {formatDate(post.date)} · {post.readingMinutes} min read
                    </span>
                  </Link>
                </motion.article>
              ))}
            </AnimatePresence>
          </motion.div>

          {/* Placeholder notice — see src/site/content/posts.js */}
          <p className="vx-disclaimer">
            Sample posts shown while the editorial calendar is being set up.
          </p>
        </div>
      </section>
    </>
  );
};

export { formatDate };
export default Blog;
