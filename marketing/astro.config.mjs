// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import { SITE_URL } from './src/consts.ts';

// https://astro.build/config
export default defineConfig({
  // Public URL the site is served from. Used for canonical URLs, the
  // sitemap, and RSS. Update SITE_URL in src/consts.ts when the real
  // marketing domain is wired up.
  site: SITE_URL,
  integrations: [sitemap()],
  build: {
    // Emit /about/index.html instead of /about.html so Firebase Hosting
    // serves clean URLs without a rewrite config.
    format: 'directory',
  },
});
