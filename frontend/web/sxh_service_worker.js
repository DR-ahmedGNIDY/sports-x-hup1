// The app's own service worker.
//
// Flutter used to generate one that precached the whole build; as of Flutter
// 3.44 the file it generates (`flutter_service_worker.js`) is a tombstone —
// it installs, unregisters itself, reloads its clients, and caches nothing.
// So despite a service worker being "registered" since M0, this app had no
// offline story and no warm second launch at all. This replaces it.
//
// Deliberately conservative, because a service worker is the one piece of a
// web app that can break it permanently for a returning visitor:
//
//   * Only same-origin GET requests are ever cached.
//   * API calls are never cached. They are authenticated and they change;
//     serving a stale one is worse than failing.
//   * Navigations are network-first with a cached-shell fallback, so a
//     deploy is picked up on the next load rather than after an eviction.
//   * Everything else is stale-while-revalidate: instant from cache, with a
//     fresh copy fetched in the background for next time.
//
// Registered by web/flutter_bootstrap.js, which appends the build version as
// a query parameter. That version is what names the cache, so every deploy
// gets a fresh one and the old ones are deleted on activate.

'use strict';

const VERSION = new URL(self.location).searchParams.get('v') || 'dev';
const CACHE = `sxh-shell-${VERSION}`;

/// The minimum needed to render something. Everything else arrives through
/// the runtime cache — precaching the whole build (canvaskit alone is
/// several MB) would make the first visit slower to pay for the second.
const SHELL = [
  '/',
  'index.html',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  // The boot screen's own logo. Without it the offline first paint is a
  // broken-image glyph, which is a worse answer than no logo at all.
  'icons/Icon-512.png',
];

/// Never cached, whatever else matches. The Flutter tombstone is excluded so
/// it can never be resurrected from cache.
const NEVER_CACHE = ['/flutter_service_worker.js'];

/// Fetched fresh when the network is there, served from cache when it isn't.
///
/// `assets/.env` is rewritten from container environment on every start (see
/// docker-entrypoint.sh), so a stale copy would pin the app to a previous
/// deploy's API URL — but excluding it outright is worse: `main()` awaits it
/// before `runApp`, so an uncacheable .env means the app cannot start offline
/// at all, however much of it is cached. Network-first gives both.
const NETWORK_FIRST = ['/assets/.env'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Individually rather than `addAll`, which rejects the whole install if
      // any single request fails. A shell file that 404s should cost its own
      // entry, not the entire worker.
      await Promise.all(
        SHELL.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch(() => {}),
        ),
      );
      // Take over immediately. Waiting for every tab to close means a fix
      // ships whenever the user happens to quit the app, which is never.
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((name) => name.startsWith('sxh-shell-') && name !== CACHE)
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (NEVER_CACHE.includes(url.pathname)) return;

  // A navigation: the SPA shell. Network first so a new deploy is picked up
  // on the next load, falling back to the cached shell — which is what makes
  // the app open at all with no connection.
  const isNavigation = request.mode === 'navigate';
  if (isNavigation || NETWORK_FIRST.includes(url.pathname)) {
    // Navigations all resolve to the one shell document; anything else keyed
    // network-first is cached under its own request.
    const key = isNavigation ? 'index.html' : request;
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          const copy = response.clone();
          caches
            .open(CACHE)
            .then((cache) => cache.put(key, copy))
            .catch(() => {});
          return response;
        } catch (error) {
          const cached = await caches.match(key);
          if (cached) return cached;
          throw error;
        }
      })(),
    );
    return;
  }

  // Everything else: serve from cache immediately if it's there, and refresh
  // the entry in the background. The user gets the previous build's asset
  // once, at most, and never waits on the network for it.
  event.respondWith(
    (async () => {
      const cached = await caches.match(request);
      const network = fetch(request)
        .then((response) => {
          if (response && response.ok && response.type === 'basic') {
            // Cloned here, synchronously, and not inside the `then` below:
            // by the time an async callback runs, the page may already have
            // consumed the body, and `clone()` then throws. That one
            // misplaced call is the difference between a warm cache and a
            // cache that only ever holds what `install` precached.
            const copy = response.clone();
            caches
              .open(CACHE)
              .then((cache) => cache.put(request, copy))
              .catch(() => {});
          }
          return response;
        })
        .catch(() => cached);

      return cached || network;
    })(),
  );
});
