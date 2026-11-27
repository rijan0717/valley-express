/**
 * Image build step.
 *
 *  1. Renders the social card to PNG. Facebook, WhatsApp and X do not render
 *     SVG og:image, so the SVG alone meant no preview image at all.
 *  2. Writes a WebP beside every app screenshot. The PNGs stay as the <picture>
 *     fallback; only one of the pair is ever downloaded.
 *
 * Run with `npm run images` after changing any source asset.
 */
import { readdir, readFile, writeFile, stat } from 'node:fs/promises';
import { dirname, extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const appRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const pub = join(appRoot, 'public');

const kb = (bytes) => `${(bytes / 1024).toFixed(0)}kB`;

// 1. Social card
const ogSvg = await readFile(join(pub, 'og-image.svg'));
const ogPng = await sharp(ogSvg, { density: 192 })
  .resize(1200, 630, { fit: 'fill' })
  .png({ compressionLevel: 9 })
  .toBuffer();
await writeFile(join(pub, 'og-image.png'), ogPng);
console.log(`og-image.png  1200x630  ${kb(ogPng.length)}`);

// 2. App screenshots
const shots = join(pub, 'brand', 'app');
const files = (await readdir(shots)).filter((f) => extname(f) === '.png');

for (const file of files) {
  const source = join(shots, file);
  const target = source.replace(/\.png$/, '.webp');
  const out = await sharp(source).webp({ quality: 82, effort: 5 }).toBuffer();
  await writeFile(target, out);
  const before = (await stat(source)).size;
  console.log(`${file.padEnd(20)} ${kb(before)} -> ${kb(out.length)} webp`);
}
