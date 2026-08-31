# Phase Mobile M0 — Web-on-phone foundations

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M0
**Goal:** make the app *render* like an app on a phone before touching a single widget.
**Status:** complete, built and verified in-browser.

---

## What shipped

### 1. The viewport meta tag (`web/index.html`)

The single highest-impact line in this phase. `index.html` had no
`<meta name="viewport">` at all, so every phone laid the page out at a ~980px
desktop width and then scaled it down — the actual mechanism behind the app
reading as a shrunken web page.

```
width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover
```

`viewport-fit=cover` lets the app paint edge to edge behind the notch and home
indicator, which is what makes item 3 below necessary.

### 2. Boot screen (`web/index.html` + `web/flutter_bootstrap.js`)

The browser previously painted nothing until `main.dart.js` had been fetched,
parsed and started. `index.html` now carries an inline, dependency-free boot
screen — brand background, logo, indeterminate progress bar — painted on the
first frame the browser produces.

`web/flutter_bootstrap.js` is now a customized copy of Flutter's default
bootstrap (same loader, same service-worker registration) that additionally
dismisses the boot screen once the app has rendered. It is deliberately
mirrored on the iOS launch images (item 4) so the handoff between them is
invisible.

Two failure modes are handled explicitly:

- **Hidden tab.** `requestAnimationFrame` never fires in a backgrounded tab, so
  a rAF-only dismissal stranded the boot screen on top of a fully rendered app
  until the user focused it — the everyday "open link in a new tab" case. A
  `setTimeout` fallback that does not depend on the compositor now covers it
  (measured: dismissed at 5.7s in a hidden tab, immediately after first paint
  in a visible one).
- **No `transitionend`.** Reduced-motion settings and hidden tabs can swallow
  the fade's end event; a timer removes the element regardless.

### 3. Real safe-area insets on web

Flutter Web never populates `MediaQuery.padding` from `env(safe-area-inset-*)`,
so `viewport-fit=cover` on its own would have painted the bottom navigation
underneath the iPhone home indicator. Closed end to end:

- `web/index.html` installs a hidden probe element whose padding is set from the
  four `env(safe-area-inset-*)` values, exposed as `window.sxhSafeAreaInsets()`.
- `lib/core/utils/safe_area_insets.dart` — `applyWebSafeArea`, wired into
  `MaterialApp.router`'s `builder` in `lib/main.dart`, injects those values into
  the inherited `MediaQueryData`. `SafeArea` and `MediaQuery.paddingOf` now
  behave on web exactly as they do on iOS/Android.
- Conditional import (`_web` / `_stub`) keeps it a no-op off the web, where the
  embedder already reports correct values and must not be overwritten.

A bug worth recording: the first cut returned early when the insets were zero,
*before* calling `MediaQuery.of(context)`. That skipped registering the build as
a dependency of the inherited MediaQuery, so a surface starting with no insets
never rebuilt when metrics changed — rotating into an orientation that does have
insets would never re-read the probe. The read is now unconditional.

### 4. iOS launch images (`web/splash/`, `tool/generate_ios_splash.py`)

iOS is the one platform that ignores the manifest's `background_color` when an
installed PWA launches; without an `apple-touch-startup-image` matching the
device's exact pixel size it shows a blank white screen. 17 portrait launch
images (every iPhone and iPad still receiving updates) are generated from
`assets/images/logo.png` by a committed, re-runnable script and declared in
`index.html`.

Kept to ~1.1 MB total by cropping the source logo's baked-in transparent
padding and quantizing to 128 colors — a flat background plus a two-tone mark
needs nowhere near 24-bit color.

### 5. iOS status bar

`apple-mobile-web-app-status-bar-style` moved from `black` to
`black-translucent`, so the app's own background runs under the status bar
instead of stranding a solid black strip above it. `apple-mobile-web-app-capable`
added alongside the modern `mobile-web-app-capable`.

### 6. `manifest.json`

Added `id`, `scope`, `lang: ar` / `dir: rtl` (Arabic is the product default —
see `LocaleController`), `categories`, and three app shortcuts (Search Players,
My Profile, Community) for the long-press launcher menu.

### 7. App-like touch behavior (`web/index.html`)

`-webkit-touch-callout: none`, `-webkit-tap-highlight-color: transparent`,
`user-select: none`, `touch-action: manipulation`, and
`overscroll-behavior: none` — no long-press callout, no blue tap flash, no
double-tap-zoom delay, no page-level rubber band behind the app. Editable
elements opt back into text selection so the caret and copy/paste keep working.

---

## Deliberate deviations from the plan

**A single dark `theme-color`, not a light/dark pair.** The plan called for a
`prefers-color-scheme`-driven pair. `ThemeModeController` starts every session
in dark mode and does not persist the user's toggle, so a light `theme-color`
would have painted white browser chrome around an app that is still dark. Worth
revisiting when the theme choice becomes persisted.

**No `screenshots` in the manifest.** The richer install UI needs real captures
of the finished mobile UI; taking them now would only have to be redone after
M2–M4 redesign every screen. Deferred to the end of M4.

---

## Verification

- `flutter analyze` on the changed files — no issues.
- `flutter build web --release` — succeeds; template tokens in the custom
  bootstrap (`{{flutter_js}}`, `{{flutter_build_config}}`,
  `{{flutter_service_worker_version}}`) substitute correctly, and all 17 launch
  images plus the probe reach `build/web`.
- `flutter test` — 50/50 passing, no regressions.
- In-browser at 375×812 and 390×844: the app lays out at true device width (no
  desktop-width downscale), the boot screen paints immediately and hands off
  cleanly, and the console is clean.
- Safe area verified end to end by serving the build with the probe patched to
  return `59,0,34,0`: the app bar shifts down by exactly the injected top inset,
  and returns flush to the top when the probe reports zero.

---

## Next

M1 — the second token layer (`AppRadius`, `AppElevation`, `AppBlur`,
`AppTouch`) and the mobile type scale, which M2's shell rebuild depends on.
