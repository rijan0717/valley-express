import React from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { motion, useScroll, useSpring } from 'framer-motion';
import Seo, { SITE_URL } from '../components/Seo';
import Reveal from '../components/Reveal';
import StoreBadges from '../components/StoreBadges';
import { POSTS, getPost } from '../content/posts';
import { formatDate } from './Blog';

/** A thin orange bar that tracks how far down the article the reader is. */
const ReadingProgress = () => {
  const { scrollYProgress } = useScroll();
  const width = useSpring(scrollYProgress, { stiffness: 120, damping: 24, restDelta: 0.001 });
  return <motion.div className="vx-progress" style={{ scaleX: width }} aria-hidden="true" />;
};

const BlogPost = () => {
  const { slug } = useParams();
  const post = getPost(slug);

  if (!post) return <Navigate to="/blog" replace />;

  const others = POSTS.filter((item) => item.slug !== post.slug).slice(0, 2);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    description: post.excerpt,
    datePublished: post.date,
    dateModified: post.date,
    url: `${SITE_URL}/blog/${post.slug}`,
    publisher: {
      '@type': 'Organization',
      name: 'Valley Express',
      logo: { '@type': 'ImageObject', url: `${SITE_URL}/full-logo.svg` },
    },
    mainEntityOfPage: { '@type': 'WebPage', '@id': `${SITE_URL}/blog/${post.slug}` },
  };

  return (
    <>
      <Seo
        title={post.title}
        description={post.excerpt}
        path={`/blog/${post.slug}`}
        type="article"
        jsonLd={jsonLd}
      />
      <ReadingProgress />

      <article>
        <section className="vx-page-hero vx-page-hero-article">
          <div className="vx-container vx-prose">
            <Reveal>
              <Link to="/blog" className="vx-back-link">
                ← All posts
              </Link>
              <span className="vx-post-tag vx-post-tag-light">{post.tag}</span>
              <h1 className="vx-page-title">{post.title}</h1>
              <p className="vx-page-sub">{post.excerpt}</p>
              <p className="vx-article-meta">
                {formatDate(post.date)} · {post.readingMinutes} min read
              </p>
            </Reveal>
          </div>
        </section>

        <section className="vx-section">
          <div className="vx-container vx-prose">
            {post.body.map((paragraph, index) => (
              <Reveal key={paragraph.slice(0, 32)} delay={index * 0.05}>
                <p className={index === 0 ? 'vx-lead' : 'vx-body'}>{paragraph}</p>
              </Reveal>
            ))}

            {/* Placeholder notice — see src/site/content/posts.js */}
            <Reveal>
              <p className="vx-disclaimer vx-disclaimer-left">
                Sample post, written to demonstrate the blog layout.
              </p>
            </Reveal>

            <Reveal delay={0.1}>
              <div className="vx-article-cta">
                <h2 className="vx-h3">Get the app when it lands</h2>
                <StoreBadges theme="light" />
              </div>
            </Reveal>
          </div>
        </section>

        {others.length > 0 && (
          <section className="vx-section vx-section-grey">
            <div className="vx-container">
              <Reveal className="vx-section-head">
                <span className="vx-kicker">Keep reading</span>
                <h2 className="vx-h2">More from the desk</h2>
              </Reveal>
              <div className="vx-post-grid">
                {others.map((item, index) => (
                  <Reveal key={item.slug} delay={index * 0.08}>
                    <article className="vx-post-card">
                      <Link to={`/blog/${item.slug}`}>
                        <span className="vx-post-tag">{item.tag}</span>
                        <h3>{item.title}</h3>
                        <p>{item.excerpt}</p>
                        <span className="vx-post-meta">{item.readingMinutes} min read</span>
                      </Link>
                    </article>
                  </Reveal>
                ))}
              </div>
            </div>
          </section>
        )}
      </article>
    </>
  );
};

export default BlogPost;
