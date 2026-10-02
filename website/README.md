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
