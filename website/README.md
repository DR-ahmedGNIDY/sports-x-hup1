# Sport X Hub — Website

The public site on `sportxhup.com`: marketing pages (Arabic at `/`, English
under `/en/`) and, from phase 5 of the split plan, the storefront at `/store`.
Static HTML built with Astro; no Node process runs on the server.

This project is independent of `../frontend/` (the app). Nothing here imports
from or writes to that folder.

## Develop

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # -> dist/
```

Copy `.env.example` to `.env` to point at a different API.

## Where the content comes from

- Links and contact details (social, WhatsApp, phones, email, Google Play,
  web-app URL) come from `GET /site-settings`, edited in the app's admin
  dashboard under **Website**. They are read at build time and refreshed in
  the browser on every visit, so an admin change shows without a rebuild.
- `public/privacy.html` is the privacy policy registered with Google Play.
  Its URL, and the `#delete-account` anchor, must not change.

## The store

`/store` (and `/en/store`) is the storefront that used to live in the app.
Pages are static shells; `src/lib/store/client.ts` renders them in the
browser from the live store API (products, categories, banners, shipping
zones, coupon preview, guest orders, order tracking). The bag lives in
`localStorage` on the visitor's device. Payment is cash on delivery.

Category and product pages are pre-built for every slug that exists at build
time. A product added later needs either a rebuild or this nginx fallback,
which serves the generic shell that reads the slug from the URL:

```nginx
location ~ ^/(en/)?store/c/ { try_files $uri $uri/ /$1store/c/index.html; }
location ~ ^/(en/)?store/p/ { try_files $uri $uri/ /$1store/p/index.html; }
```
