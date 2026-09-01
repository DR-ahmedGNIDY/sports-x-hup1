# Phase Mobile M5 — motion and touch

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M5
**Goal:** make the app answer a finger the way a native one does.
**Status:** complete, and smaller than planned — three of the six planned items
turned out to be already satisfied or actively wrong to build. Analyze clean,
103/103 tests.

---

## What shipped

### `AppHaptics` — four intensities, each meaning one thing

`selection` for moving between peers (tabs, segmented controls), `light` for a
small state change the user caused (like, save, toggle), `success` for
something completing, `error` for something refused. Calling `HapticFeedback`
directly at each site is how an app ends up buzzing at three different
strengths for the same class of event.

Wired to three real sites: the tab bar (`selection` — the most frequent gesture
in the app, and anything stronger turns routine navigation into a series of
thuds), the video like button and the save-player button (`light`, fired on the
tap rather than on the server's reply, because the feedback is acknowledging
the press and a buzz that arrives after a round trip reads as a second,
unrelated event).

Every call is a no-op on web and swallows a `PlatformException` on a device
with no haptic engine. Losing the buzz must never lose the tap that asked for
it, and a test pins that all four complete rather than throw with no platform
channel answering.

### `AppScrollBehavior` — the list finally springs

Flutter Web defaults to desktop clamping physics on every platform: a list
stops dead at its end. On a phone that is the most legible remaining difference
between a web page and an app — every native list overscrolls and springs back,
and its absence is felt before it is noticed.

Applied at the app root so it reaches every scroll view, including the ones
inside sheets. Three details that are easy to get wrong and are pinned by test:

- The bouncing physics wrap `AlwaysScrollableScrollPhysics`, or a list shorter
  than its viewport won't overscroll and pull-to-refresh becomes unreachable on
  a half-empty screen.
- Android's overscroll glow is removed. It answers the same question the bounce
  now answers; both at once is a list that springs *and* flashes.
- Mouse and trackpad are added to `dragDevices`, which Flutter Web otherwise
  refuses — without it a desktop browser can only scroll these with the wheel.

Desktop keeps clamping, decided through `AppBreakpoints` so a window dragged
across the breakpoint changes physics and layout together.

### Reduced motion, applied consistently

The tab bar's press scale and icon cross-fade — both added in M2 — never
checked `disableAnimations`, while the page transitions did from the start. A
setting that silences one and not the other is worse than either answer applied
consistently. Both now collapse to `Duration.zero`, pinned by a test scoped to
one tab slot (a blanket assertion would fail on Flutter's own animations
instead of the two this app added).

---

## A latent crash, surfaced by turning the setting on

`SkeletonBox` built its `AnimationController` as a `late final` field. The first
thing to touch it was `build` — but under reduced motion `build` returns before
reaching it, so the *first* access became `dispose`. Creating a ticker there
means creating it against an already-deactivated element:

```
Looking up a deactivated widget's ancestor is unsafe.
```

A skeleton is on screen during almost every load, and M4 put them on far more
screens, so with the setting on this was every screen. Now built in
`initState`.

It says something that the bug only appeared once a test turned the
accessibility setting on — the reduced-motion path had never been exercised.

---

## Three planned items deliberately not built

**Pressed states on cards.** The plan called for every tappable card to shrink
on press. Every tappable card in this app is already a `Card` (a `Material`)
wrapping an `InkWell` or `ListTile`, which is Flutter's own answer and gives
real feedback. A scale wrapper on top would mean a ripple *and* a shrink for
one tap. A written-and-then-deleted `AppPressable` is the whole story here: the
gap the plan assumed had already been closed correctly.

**Hero transition from a player card to their profile.** Blocked by M2's own
design, not by effort. `StatefulShellRoute.indexedStack` keeps every branch
mounted, so the same player can be on screen in Search and in Saved Players at
the same time — two Heroes sharing one tag, which is an assertion failure
rather than a degraded animation. Tagging per source list doesn't work either,
because the destination cannot know which list it was opened from. Worth
revisiting if branch mounting ever changes.

**Staggered list entrances.** `FadeSlideIn` already staggers the Player
Profile's sections, and it is the right tool there because that page's sections
are a fixed, known set. Every list M4 migrated is a lazy sliver, where items
build as they scroll into view — so a stagger would animate rows *during*
scrolling, which reads as jank rather than as polish. Doing it properly means
animating only the first screenful and tracking which indices have already
appeared; that is a component, not a flag, and it did not earn its place ahead
of the rest of this phase.

`AppMotion.emphasized` was also skipped: no transition in the app needs a curve
the existing `enter`/`exit` pair doesn't already provide, and a constant nobody
reads is the thing this project has been refusing to ship since M1.

---

## Verification

- `flutter analyze` — clean.
- `flutter test` — 103/103. Seven new: the phone/desktop physics split, the
  `AlwaysScrollableScrollPhysics` parent, the drag devices, the suppressed
  glow, all four haptic intensities completing without a platform channel, and
  the tab bar going still under reduced motion.
- Rebuilt and checked in the browser against the live session: the Player
  Profile renders and the console is clean.

---

## Next

M6 — performance and perceived speed: `cached_network_image` in place of every
raw `NetworkImage`, decode sizes, precaching the logo and avatar, the service
worker, and a local Tajawal with `font-display: swap`.
