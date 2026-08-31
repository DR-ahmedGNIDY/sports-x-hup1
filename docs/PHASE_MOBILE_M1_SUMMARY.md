# Phase Mobile M1 — the second token layer

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M1
**Goal:** give M2–M4 a design system to build on, and stop the drift that had
already produced ten different corner radii.
**Status:** complete. Analyze clean, 57/57 tests passing, built and rendered.

---

## What shipped

### `AppRadius` — and the sweep that made it true

`lib/core/theme/app_radius.dart`. Seven steps: 4 / 8 / 12 / 16 / 20 / 28 /
pill.

Before this, `lib/` held **63 literal `circular(N)` call sites across 40
files**, using ten distinct values: 4, 6, 8, 10, 12, 14, 16, 20, 24 and 999.
Most of that spread was drift, not design — nothing meaningful distinguishes a
10px corner from a 12px one. Every site now references a token.

Odd values were rounded **up** to the next step (6→8, 10→12, 14→16, 24→28), 17
sites in total, each a ≤4px change. Rounding up rather than to-nearest was
deliberate: softer, larger corners are the direction this whole effort is
moving in, and it makes the rule mechanical instead of case-by-case. The one
site worth naming is the club composer's input (24→28), which was already a
capsule at half its own height and stays one.

Three theme-level radii moved with it: cards 12→16, filled buttons 10→12,
inputs 10→12.

The rule is enforced, not just documented — `design_tokens_test.dart` scans
`lib/` and fails on any literal `circular(N)` outside the token file itself.

### `AppElevation`

`lib/core/theme/app_elevation.dart`. Four levels — `flat` / `raised` /
`floating` / `overlay` — each pairing a Material elevation with the shadow
color that makes it legible at a given brightness.

This formalizes a rule `AppTheme`'s card theme was already following by hand:
light mode separates surfaces with a soft grey shadow, dark mode with a faint
lighter-surface glow, because a black drop shadow on a near-black background
reads as nothing at all. The two always travel together, which is exactly what
kept going wrong when they were picked independently at each call site. The
`raised` values are numerically identical to what the card theme had, so
nothing moved visually.

### `AppTouch` and the compact button minimum

`lib/core/theme/app_touch.dart` — `minTarget` 48 (Material, and the app's
default), `iosMinTarget` 44 (recorded for the rare dense row that genuinely
cannot afford 48).

Applied where it actually bites: Material sizes `TextButton` and
`OutlinedButton` at 40 tall, below the minimum, which reads as a mis-tap rather
than as a small button once a fingertip is doing the aiming. `AppTheme.compact`
raises both to 48. Filled buttons already clear it through their own padding.

### The compact type scale

`AppTextStyles` gains a compact set — body **14→16**, title 17→20, headline
22→24, display 32→34, caption 12→13 — defined with `copyWith` on the base
styles so family, weight and letter-spacing can never drift apart between the
two scales, only size.

`AppTheme.compact(base)` swaps that scale in, and `main.dart` applies it below
`AppBreakpoints.desktop` — the same single decision point every screen already
uses to fork its presentation, so the type scale can never disagree with the
layout it is typesetting. The theme is applied in `MaterialApp`'s `builder`
rather than baked into `AppTheme.light`/`dark` because that is the first place
with a `MediaQuery` to measure; above `MaterialApp` there isn't one.

Body text at 14 was the second-clearest tell (after the missing viewport tag)
that this was a web page rather than an app: every native phone UI sets body
text at 16–17.

---

## Deliberate deviations from the plan

**No `AppBlur` yet.** The plan lists it under M1, but nothing consumes a blur
value until M2 rebuilds the translucent app/tab bars. Shipping it now would be
committing dead constants and guessing at the sigma before there is anything to
look at. It lands in M2, with its consumer.

**The base (desktop) theme was left alone.** An earlier cut of this phase set
`materialTapTargetSize: padded` and an icon-button minimum globally. That
changes desktop control metrics — outside this phase's scope, and not verifiable
in the mobile preview. Both moved into `AppTheme.compact`, so the desktop app is
byte-for-byte unaffected except for the three shared radii above.

**`AppTextStyles.eyebrow` and `statNumber` have no compact variant.** Unlike the
rest of the scale they are read directly by widgets rather than through
`TextTheme`, so a theme-level swap cannot reach them. Routing them through the
theme means touching their call sites, which is M3/M4 work on those components.

---

## Verification

- `flutter analyze` — clean across the whole project after the 40-file sweep.
- `flutter test` — 57/57. Six of those are new (`test/core/theme/design_tokens_test.dart`):
  the radius scale is strictly ascending, no literal radius survives in `lib/`,
  elevation shadows strengthen with height and are tinted correctly per
  brightness, `compact` enlarges text without touching color or shape, every
  compact style is larger than its base at the same weight and family, and the
  compact button minimum is 48 while the base theme keeps Material's default.
- The existing phone-width matrix in `feed_responsive_matrix_test.dart` now
  pumps under `AppTheme.compact` instead of the desktop theme — it was
  previously asserting "no overflow at 320–430px" against type the phone never
  actually gets. The feed card passes at all four widths with the larger scale,
  in Arabic RTL.
- `flutter build web --release` succeeds; rendered at 375×812 with a clean
  console and visibly larger, more readable type.

---

## Next

M2 — the shell rebuild: per-screen app bars with collapsing large titles,
translucent blurred bars (bringing `AppBlur` with them), a real tab bar with
filled/outlined states, tab scroll-position retention via
`StatefulShellRoute.indexedStack`, page transitions, and edge-swipe back.
