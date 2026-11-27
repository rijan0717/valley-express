/**
 * Writes a static HTML shell per public route after `vite build`.
 *
 * Why: the site is a single-page app, and its <title>, description and social
 * tags are set by React once the bundle runs. Google renders JavaScript, but
 * Facebook, WhatsApp, X, LinkedIn and Bing read the raw HTML — so without this
 * step every shared link shows the homepage card, whatever page was shared.
 *
 * Each route gets a copy of dist/index.html with its own head. The body is
 * still rendered by React on load; only the metadata is baked in. Routes are
 * read from src/site/content/seo.js, the same file the pages use, so the two
 * cannot drift apart.
 */
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const appRoot = join(here, '..');
const dist = join(appRoot, 'dist');

const seoModule = await import(
  pathToFileURL(join(appRoot, 'src/site/content/seo.js')).href
);
const { POSTS } = await import(
  pathToFileURL(join(appRoot, 'src/site/content/posts.js')).href
);
const { ROUTE_SEO, SITE_URL } = seoModule;

const escapeAttr = (value) =>
  String(value).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');

/** Replaces the value of a tag already present in the template. */
const setMeta = (html, matcher, replacement) => {
  if (!matcher.test(html)) {
    throw new Error(`prerender: could not find ${matcher} in dist/index.html`);
  }
  return html.replace(matcher, replacement);
};

const buildHead = (template, { path, title, description, type }) => {
  const url = `${SITE_URL}${path === '/' ? '/' : path}`;
  const fullTitle = path === '/' ? `Valley Express — ${title}` : `${title} | Valley Express`;
  let html = template;

  html = setMeta(html, /<title>[\s\S]*?<\/title>/, `<title>${escapeAttr(fullTitle)}</title>`);
  html = setMeta(
    html,
    /<meta name="description" content="[^"]*" \/>/,
    `<meta name="description" content="${escapeAttr(description)}" />`
  );
  html = setMeta(
    html,
    /<link rel="canonical" href="[^"]*" \/>/,
    `<link rel="canonical" href="${escapeAttr(url)}" />`
  );
  html = setMeta(
    html,
    /<meta property="og:title" content="[^"]*" \/>/,
    `<meta property="og:title" content="${escapeAttr(fullTitle)}" />`
  );
  html = setMeta(
    html,
    /<meta property="og:description" content="[^"]*" \/>/,
    `<meta property="og:description" content="${escapeAttr(description)}" />`
  );
  html = setMeta(
    html,
    /<meta property="og:url" content="[^"]*" \/>/,
    `<meta property="og:url" content="${escapeAttr(url)}" />`
  );
  html = setMeta(
    html,
    /<meta property="og:type" content="[^"]*" \/>/,
    `<meta property="og:type" content="${type}" />`
  );
  return html;
};

const template = await readFile(join(dist, 'index.html'), 'utf8');

const routes = [
  ...Object.entries(ROUTE_SEO).map(([path, seo]) => ({ path, ...seo, type: 'website' })),
  ...POSTS.map((post) => ({
    path: `/blog/${post.slug}`,
    title: post.title,
    description: post.excerpt,
    type: 'article',
  })),
];

let written = 0;
for (const route of routes) {
  const html = buildHead(template, route);
  // "/" is dist/index.html itself; everything else gets its own directory so a
  // static host serves /about as /about/index.html.
  const target = route.path === '/' ? join(dist, 'index.html') : join(dist, route.path, 'index.html');
  await mkdir(dirname(target), { recursive: true });
  await writeFile(target, html, 'utf8');
  written += 1;
}

console.log(`prerender: wrote ${written} static route shells`);
