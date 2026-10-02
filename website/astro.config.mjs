import { defineConfig } from 'astro/config';

// Static output: the site is plain HTML on nginx, no Node process on the
// server. Arabic is the default locale at `/`, English lives under `/en/`.
export default defineConfig({
  site: 'https://sportxhup.com',
  output: 'static',
  trailingSlash: 'ignore',
  build: { format: 'directory' },
});
