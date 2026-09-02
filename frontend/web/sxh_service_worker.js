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
/// This worker itself, so a fix to it can never be served from a copy of
/// the thing being fixed. `/sxh_service_worker.js` is the one the app
/// registers; Flutter's generated file is listed too because a browser that
/// still holds an old registration may ask for it.
const NEVER_CACHE = ['/sxh_service_worker.js', '/flutter_service_worker.js'];

/// Fetched fresh when the network is there, served from cache when it isn't.
///
/// `assets/.env` is rewritten from container environment on every start (see
/// docker-entrypoint.sh), so a stale copy would pin the app to a previous
/// deploy's API URL — but excluding it outright is worse: `main()` awaits it
/// before `runApp`, so an uncacheable .env means the app cannot start offline
/// at all, however much of it is cached. Network-first gives both.
///
/// `flutter_bootstrap.js` is here for a sharper reason: it carries the build
/// version this worker is registered with. Served stale-while-revalidate, a
/// deploy could not announce itself — the old worker handed back the old
/// bootstrap, which re-registered the same old worker, and the app stayed on
/// a previous build until someone cleared site data by hand. The one file
/// able to break that loop cannot itself be inside it.
///
/// `main.dart.js` is deliberately *not* here, though it is the build itself.
/// Once the bootstrap arrives fresh, its new version names a new cache, and
/// `activate` deletes the old one — so the very next request for the bundle
/// misses and goes to the network anyway. Listing it would buy nothing and
/// cost a conditional request on every load, forever, for the largest file
/// the app has.
const NETWORK_FIRST = ['/assets/.env', '/flutter_bootstrap.js'];

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

// ---------------------------------------------------------------- web push
//
// The two handlers that turn this from a caching worker into something the
// operating system will show a banner for. They run when the app is closed —
// that is the whole point, and it is why the notification text has to be
// built here rather than by the Flutter app, which is not running.
//
// The payload is the same structured shape the in-app notification stores
// (`type` + actor), never a rendered sentence: see the backend's
// notification schema for why. The consequence is that this file owns one
// small copy of the wording, in both languages, because a service worker
// cannot reach the app's .arb files. It is the only duplicated copy in the
// system, and it is deliberate — the alternative is a server that renders
// text and freezes the reader's language at send time.

const PUSH_STRINGS = {
  ar: {
    title: 'Sport X Hub',
    INVITATION_RECEIVED_CLUB: (name) => `${name} دعاك للانضمام إلى النادي.`,
    INVITATION_RECEIVED_PLAYER: (name) => `${name} طلب الانضمام إلى ناديك.`,
    INVITATION_ACCEPTED: (name) => `${name} قَبِل دعوتك.`,
    INVITATION_REJECTED: (name) => `${name} رفض دعوتك.`,
    fallbackClub: 'نادٍ',
    fallbackPlayer: 'لاعب',
    generic: 'لديك إشعار جديد.',
  },
  en: {
    title: 'Sport X Hub',
    INVITATION_RECEIVED_CLUB: (name) => `${name} invited you to join their club.`,
    INVITATION_RECEIVED_PLAYER: (name) => `${name} asked to join your club.`,
    INVITATION_ACCEPTED: (name) => `${name} accepted your invitation.`,
    INVITATION_REJECTED: (name) => `${name} declined your invitation.`,
    fallbackClub: 'A club',
    fallbackPlayer: 'A player',
    generic: 'You have a new notification.',
  },
};

// Arabic is the app's default, so it is the fallback here too.
function pushStrings() {
  const language = (self.navigator && self.navigator.language) || 'ar';
  return language.startsWith('en') ? PUSH_STRINGS.en : PUSH_STRINGS.ar;
}

function pushBody(data) {
  const s = pushStrings();
  const isClub = data.actorRole === 'CLUB';
  const name =
    (data.actorName && data.actorName.trim()) ||
    (isClub ? s.fallbackClub : s.fallbackPlayer);

  switch (data.type) {
    case 'INVITATION_RECEIVED':
      return isClub
        ? s.INVITATION_RECEIVED_CLUB(name)
        : s.INVITATION_RECEIVED_PLAYER(name);
    case 'INVITATION_ACCEPTED':
      return s.INVITATION_ACCEPTED(name);
    case 'INVITATION_REJECTED':
      return s.INVITATION_REJECTED(name);
    default:
      // A type this build predates. Still worth a banner — the app will
      // render it properly once opened.
      return s.generic;
  }
}

self.addEventListener('push', (event) => {
  // A push with no readable payload still shows something. Silently
  // dropping it would be worse: on some platforms a push that shows no
  // notification costs the site its permission.
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (_) {
    data = {};
  }

  const s = pushStrings();
  event.waitUntil(
    self.registration.showNotification(s.title, {
      body: pushBody(data),
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      // Collapses repeats for one notification rather than stacking them.
      tag: data.notificationId || 'sxh-notification',
      data: { notificationId: data.notificationId || null },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  // Focus a tab that is already open rather than adding another — someone
  // who has the app open in a tab wants that tab, not a second copy.
  event.waitUntil(
    (async () => {
      const target = new URL('/#/notifications', self.location.origin).href;
      const clientList = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const client of clientList) {
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          await client.focus();
          if ('navigate' in client) await client.navigate(target);
          return;
        }
      }
      if (self.clients.openWindow) await self.clients.openWindow(target);
    })(),
  );
});
