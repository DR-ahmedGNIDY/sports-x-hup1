// Same kill switch as sxh_service_worker.js, for the older worker path.
// Kill switch for the Flutter app's service worker.
//
// Until the split, sportxhup.com served the Flutter web app, which registered
// a service worker at this exact path. A returning visitor's browser keeps
// that worker and would keep showing the cached app instead of this website.
// Browsers re-check a registered worker's script on navigation, so serving
// this file at the same URL replaces the old worker with one that deletes
// every cache, unregisters itself and reloads open tabs onto the real site.
// The app itself now lives on app.sportxhup.com, a different origin.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
      await self.registration.unregister();
      const clients = await self.clients.matchAll({ type: 'window' });
      for (const client of clients) client.navigate(client.url);
    })(),
  );
});
