# Phase Mobile M7 — PWA and offline

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M7
**Goal:** make the installed app a real one — it opens, and it opens without a
connection.
**Status:** complete. Analyze clean, 111/111 tests, and **verified offline with
the server stopped**.

---

## The premise was wrong, which changed the phase

M0's summary said a service worker was registered, and it was. What it did not
say — because it was not true then — is what that worker *does*. As of Flutter
3.44 the file `flutter build web` generates is a tombstone:

```js
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    ...
  })());
});
```

It installs, unregisters itself, reloads its clients, and caches nothing. So
the app had no offline story and no warm second launch at all — there was
nothing here to build on top of, only something to replace.

## `web/sxh_service_worker.js`

Written deliberately conservatively, because a service worker is the one piece
of a web app that can break it permanently for a returning visitor:

- Only same-origin GETs are ever cached. API calls are authenticated and they
  change; serving a stale one is worse than failing.
- Navigations are **network-first** with the cached shell as fallback, so a
  deploy is picked up on the next load rather than after an eviction.
- Everything else is **stale-while-revalidate**: instant from cache, refreshed
  in the background.
- The cache is named from the build version, which `flutter_bootstrap.js`
  passes as a query parameter, so every deploy gets a fresh one and the old
  ones are deleted on activate.
- The shell precache is seven files, not the whole build. CanvasKit alone is
  several MB; precaching it would make the first visit slower to pay for the
  second.

## Three defects found by testing it, not by reading it

**CanvasKit came from `gstatic.com`.** The build emits a local `canvaskit/`
directory — 37 MB of it — and then the app ignored it and fetched the
rendering engine from Google's CDN at runtime. That makes first paint depend on
a third party being reachable, and it makes offline impossible however good the
service worker is, because the engine is never same-origin to cache. The
Dockerfile now builds with `--no-web-resources-cdn`.

**My own worker cached nothing at runtime.** It precached its seven shell files
and then never grew, because `response.clone()` sat inside an async callback:

```js
caches.open(CACHE).then((cache) => cache.put(request, response.clone()));
```

By the time that callback runs the page may already have consumed the body, and
`clone()` throws — inside the worker, where nothing surfaces it. Cloning
synchronously before returning the response is the whole fix, and it is the
difference between a warm cache and a cache frozen at install.

**The app refused to start without `.env`.** `main()` awaits `Env.load()`
before `runApp`, and on web that file is fetched over HTTP — it is rewritten
from container environment on every start, so it cannot be compiled in. I had
put it on the worker's never-cache list, correctly reasoning that a stale copy
would pin the app to a previous deploy's API URL. The result was an app that
booted offline as far as a blank screen and an uncaught exception.

Fixed from both ends, because either alone would have been a patch:

- The worker treats `.env` as network-first: fresh whenever the network is
  there, cached only as the offline fallback. Freshness and offline both.
- `Env.load()` no longer throws. A config file the app cannot fetch should cost
  it its configuration, not its ability to start — it now falls through to the
  defaults and lets the request that actually needed the URL fail later, where
  the app has error states to show. Three tests pin that: it completes when the
  file is missing, the defaults are genuinely readable afterwards (dotenv
  throws on every read until initialised once, so "it didn't throw" is not
  enough), and a real `.env` still wins.

## Installing

`beforeinstallprompt` is captured in `index.html`, before Dart is running,
because Chromium fires it once and early and only allows the prompt to be
replayed from a user gesture. Dart reaches it through the same conditional-
import pattern M0 used for safe-area insets.

The account sheet gains an install row, and what it does depends on what the
browser actually offers:

| | |
|---|---|
| Chromium | replays the captured prompt — one tap installs |
| Safari / iOS | opens the three Share-sheet steps, since iOS fires no event |
| Already installed, or anything else | no row at all |

That last case matters: a row that does nothing is worse than no row, and
offering to install an app that is already installed is the kind of detail that
makes software feel like it isn't paying attention.

---

## Verification

- `flutter analyze` clean, `flutter test` 111/111.
- **Offline, end to end**: loaded twice with the server up, then stopped the
  server and reloaded. The app boots and renders the full marketing home —
  logo, hero image, headline, buttons, feature cards — entirely from a
  19-entry cache including CanvasKit and all three font weights. Before this
  phase the same test produced a browser connection error.
- The service worker's registration, scope, active state and cache contents
  were each read back from the browser rather than assumed.

**Not verified end to end:** the Chromium install prompt itself. The hooks are
in place and answer correctly (`sxhCanInstall()` → false, `sxhIsInstalled()` →
false, the prompt function present), but this embedded browser never fires
`beforeinstallprompt` — it depends on engagement heuristics — so the row's
one-tap path has been verified structurally, not by an actual install.

---

## Next

M8 — quality: the device/theme/direction matrix, an RTL audit of directional
padding, accessibility (touch targets, contrast, semantics, 200% text), and
golden tests for the M3 components.
