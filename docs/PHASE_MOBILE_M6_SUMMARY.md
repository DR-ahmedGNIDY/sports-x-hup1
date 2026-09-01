# Phase Mobile M6 — performance and perceived speed

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M6
**Goal:** make the app fast, having spent five phases making it feel like one.
**Status:** complete. Analyze clean, 108/108 tests. Every number below was
measured, not estimated.

---

## Measure first

Before changing anything, the built bundle:

| | |
|---|---|
| `main.dart.js` | 4,297 KB, uncompressed over the wire |
| `assets/images/logo.png` | **1,209 KB** |
| `assets/videos/panar1.mp4` | 1,510 KB |
| `assets/videos/panar22.mp4` | 1,232 KB |
| Tajawal (3 weights) | 179 KB, already bundled locally |

Two of those turned out to be defects rather than costs.

---

## The logo was 1.2 MB to draw a 28px mark

`assets/images/logo.png` was the 1024×1024 brand master, shipped as-is and
loaded on first paint because it sits in the app bar of every screen. The
tallest `AppLogo` anywhere in the app is 96 logical pixels; most are 24–28.

The master moved to `assets/brand/logo_master.png` — deliberately *not*
listed in `pubspec.yaml`, because it is a source file, not a shipped one. It
remains the input for the iOS launch images and the launcher icons, both of
which genuinely need the resolution. `tool/generate_logo_variants.py` writes
the three resolution-aware variants Flutter picks by device pixel ratio:

| | before | after |
|---|---|---|
| 1x | 1,209 KB | **11 KB** |
| 2x | 1,209 KB | **32 KB** |
| 3x | 1,209 KB | **60 KB** |

Confirmed from the browser's own resource timing on a 2x display: the app now
fetches `2.0x/logo.png` at 32 KB. **97% smaller**, on the asset every visitor
downloads first.

## Production served everything raw

`docker/nginx.conf.template` had no `gzip` and no `Cache-Control` at all.
nginx compresses nothing by default, so every visitor was downloading
`main.dart.js` uncompressed.

Measured on the actual build: **4,297 KB → 1,201 KB, a saving of 3,096 KB
(72%)** on the single largest thing a first-time visitor downloads. Larger
than the logo fix, and it was one missing directive.

The caching policy is deliberately revalidation rather than a long `max-age`.
`flutter build web` does not content-hash its output — `main.dart.js` is
always `main.dart.js` — so pinning it would serve a stale bundle to returning
visitors with no way to bust it. nginx sends an ETag for every static file, so
`no-cache` (which means "revalidate", not "don't store") returns a 304 for
anything unchanged: nearly all of the saving, none of the staleness. The
service worker is `no-store`, because a stale copy of the file that decides
when everything else updates pins the whole app to the deploy it shipped with.

## Every remote image is now cached and decoded to size

`appImageProvider` replaces all 19 `NetworkImage` / `Image.network` call
sites. Two things a bare `NetworkImage` does not do:

- **It doesn't cache.** Decoded frames live in Flutter's in-memory image cache
  and nowhere else, so an avatar re-downloads whenever it is evicted — which,
  with M2's shell keeping every tab mounted, happens often.
- **It doesn't decode to the size drawn.** These photos come from Cloudinary
  at their upload resolution. A 3000px portrait decoded for a 32px avatar
  costs roughly 36 MB of memory and the CPU to produce it, per avatar, to
  discard 99% of the pixels.

`AppImageSize` names the four shapes the app draws (`avatarSmall`,
`avatarLarge`, `thumbnail`, `fullWidth`) so "how big is an avatar" has one
answer. The helper applies the device pixel ratio itself, so a call site says
48 and means 48 logical pixels on every screen — a test pins that it becomes
144 on a 3x display.

Two sites deliberately pass no decode width: the zoomable photo viewer, where
a cap would put a ceiling on how far it can zoom, and the feed's intrinsic-size
probe, which exists to read the photo's real dimensions and would otherwise
report the resized ones.

## The hero video is off the critical path

The marketing home page — the app's public landing page, reached on mobile —
started loading a 1,510 KB background video in `initState`, in competition
with the page it decorates. It now starts after the first frame. Nothing
changes visually: the hero already opens on the dark background the video
fades in over.

---

## Already done, and recorded as such

**Fonts.** The plan called for Tajawal served locally with `font-display:
swap`. It has been a bundled Flutter asset since the font was introduced —
there is no web font request to optimise.

**Skeletons in every loading path.** M4 replaced the centred spinners with
`AppSkeletonList` on the migrated screens. This is the perceived-speed half of
the phase and it was already banked.

**The service worker.** Registered since M0, through the custom
`flutter_bootstrap.js`. Flutter now prints a deprecation notice for it on every
build ("Flutter's service worker is deprecated and will be removed in a future
Flutter release"), so the offline story will need revisiting in M7 rather than
being built on top of it.

---

## Verification, and one thing I could not verify

- `flutter analyze` — clean. `flutter test` — 108/108, five new covering the
  image provider: that it caches, that a decode width wraps it in a
  `ResizeImage` without losing the cache underneath, that the width is applied
  in logical pixels, that omitting it leaves the provider unwrapped, and that
  the named sizes stay ordered.
- Measured in the browser against the live session: `2.0x/logo.png` at 32 KB,
  and the console clean.
- The gzip saving was measured by compressing the actual built `main.dart.js`,
  not estimated.

**The nginx config was not executed.** The Docker daemon is not running on this
machine, so `nginx -t` could not be used to validate it. The directives are
stock `ngx_http_gzip_module` ones and the structure is unchanged from the file
that was already working, but it is a config change verified by reading rather
than by running, and it should get an `nginx -t` before it is deployed.

The plan's acceptance criteria (Lighthouse ≥ 85, FCP < 2.5s) are also not
claimed: the only server available here is the dev static server, which does no
compression, so any number measured through it says more about that script than
about production. They should be measured against a real deploy.

---

## Next

M7 — PWA and offline: the install prompt, an offline page, and deciding what
replaces the deprecated service worker.
