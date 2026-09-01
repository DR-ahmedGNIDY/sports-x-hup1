# Phase Mobile M4 — the screen migration

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M4
**Goal:** move every in-shell mobile screen onto `AppScaffoldMobile`, so the
collapsing blurred bar M3 built is what the app actually wears.
**Status:** complete. Analyze clean, 93/93 tests, verified against a live
session in a browser.

---

## What moved

Thirteen routes now set `AppRouteMeta.ownsChrome` and draw their own bar:

| Wave | Screens |
|---|---|
| 1 — daily | Home (Player feed + Club dashboard), Club Players, Search, Saved Players |
| 2 — profiles | Player Profile, Skills, Traits, Club Profile |
| 3 — forms | Edit Profile, Edit Club Profile, Add Player, Edit Player |

Each migration is the same three moves: the body becomes slivers so it scrolls
under the bar as one surface, the screen's action moves from a labelled button
in the content into the bar that now exists to hold it, and the centred
spinner becomes a skeleton the shape of what is coming.

`AppScaffoldMobile` grew two things it needed to host them:

- **The logo on Home.** Its title is deliberately `null`; a wordmark is what a
  phone app puts on its first tab, and there is nothing to collapse, so Home
  gets a plain pinned bar while every other screen gets the large title.
- **A `background` override.** The Player Profile family runs on its own darker
  `ProfileColors` palette, and a bar tinted with the app-wide surface over that
  background reads as a seam rather than as the same sheet.

## Two components, six consumers

Same rule as M3 — nothing ships without a caller.

- **`AppEmptyState`** (Saved Players, Club Players, Search). The illustration
  already existed; what didn't was agreement on what goes around it. One screen
  centred a bare sentence, another added a button, a third showed only text.
  The difference between "empty" and "broken" lives entirely in that framing.
  It also carries a rule: a *filtered*-empty list gets no action, because "add
  a player" is not an answer to "your filter matched nothing".
- **`AppSkeletonList`** (Saved Players, Club Players, Search, and the profile
  and form screens). A spinner in the middle of an empty screen says "wait" and
  nothing else. Placeholders shaped like the rows that are coming say what is
  coming and how much, and the screen doesn't jump when the data lands.

---

## Three real defects found and fixed

**Dropdowns overflowed on a phone.** `DropdownButtonFormField` sizes itself to
its widest label unless told otherwise, and M1's compact type scale — body text
at 16 instead of 14 — pushed a club-level label 41px past the field on Club
Edit. That is clipped content, not a cosmetic gap. `isExpanded: true` is now set
on all sixteen dropdown fields across seven files, not just the one that
happened to be caught.

**Tap ripples were invisible on the Player Profile.** `ProfileSectionCard`
wrapped its content in a decorated `Container` with no `Material` between, so
every `ListTile` and `InkWell` inside Achievements, Social Links and Visibility
painted its splash behind an opaque background. Flutter says so out loud in
debug; in release the sections simply felt dead. A transparent `Material` fixes
it. This was [filed as its own task during M2](PHASE_MOBILE_M2_SUMMARY.md) and
is closed here, because it sits on a screen this phase migrates.

**A test of mine was asserting the wrong rule.** M3's "a screen that owns its
chrome declares a title" predates Home owning its chrome, and Home's title is
`null` by design. Corrected to state the real rule and pin the exception.

---

## Found, not fixed: a NaN layout exception on every screen

A release build logs, twice per load, on **every** authenticated route:

```
Unsupported operation: Result of truncating division is NaN: NaN ~/ 182.11765423943015
```

Not from this phase: it reproduces identically on `/community`, which M4 did
not touch. The divisor is a `SliverGrid` main-axis stride, and solving it
backwards against `mainAxisSpacing: 14` and `childAspectRatio: 0.78` identifies
the Community tab's video grid. The NaN is the scroll offset handed to it.

The likely cause is M2: `StatefulShellRoute.indexedStack` keeps every branch
mounted, and an `IndexedStack` lays out all of its children — so the Community
grid now lays out while offscreen, with degenerate constraints. Under the old
`ShellRoute` only the visible page was ever mounted, so this never fired.

Nothing renders wrong today, but an uncaught layout exception on every screen
is not a state to ship and it will mask real ones. Filed as its own task with
the diagnosis above rather than expanded into this phase.

---

## Wave 4 turned out to be already done

The plan's fourth wave — the marketing pages and the auth screens — was scoped
as "typography and spacing alignment only". M1 did that globally when it routed
the type scale through `ThemeData` and re-typed the app below the breakpoint;
M3's `filledButtonTheme` fix reached their submit buttons at the same time.

What is left is raw `EdgeInsets.all(16)` / `all(24)` literals whose values are
already `AppSpacing.lg` and `AppSpacing.xl` — replacing them changes nothing on
screen. These screens also sit outside the shell and have their own chrome, so
`AppScaffoldMobile` does not apply to them. Rather than manufacture churn, this
wave is recorded as complete-by-M1.

---

## Verification

- `flutter analyze` — clean.
- `flutter test` — 93/93. The shell suite now asserts the chrome contract
  across **ten** migrated routes: each draws exactly one `SliverAppBar` and no
  second shell `AppBar`, while `/community` still gets the shell's fixed bar.
  Both halves matter — `ownsChrome` flipped without migrating leaves a screen
  with no bar, and migrating without flipping it leaves two, and both are
  silent.
- **Verified against a live session**, backend running locally against the
  project's own database: the Player Profile renders with real data, its large
  title collapses to a small pinned one on scroll with content visibly passing
  under the blurred bar, Home shows the wordmark with compose in the bar, and
  the tab bar's filled/outlined selected state and avatar slot behave.

---

## Next

M5 — motion and touch: haptics, bouncing scroll physics, pressed states on
cards, staggered list entrances, and Hero transitions between a player card and
their profile.
