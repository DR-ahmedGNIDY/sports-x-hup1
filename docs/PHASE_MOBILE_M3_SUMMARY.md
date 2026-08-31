# Phase Mobile M3 — the component library

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M3
**Goal:** build the components M4 will rebuild every screen on — and adopt each
one somewhere real, so none of it ships as a guess.
**Status:** core complete. Analyze clean, 91/91 tests, verified in a browser.

---

## The rule this phase followed

Every component here has a consumer **in this commit**. That is the same
standard M1 and M2 held (`AppBlur` was cut from M2 for having none), and it is
what stopped the library being twelve widgets designed against an imagined
screen. It also means the phase covers fewer components than the plan listed —
see *What was deferred*.

---

## What shipped

### `AppBlur` + `BlurredSurface`

Deferred out of M2, landing here with its consumers. Sigma and surface opacity
travel together, because a blur behind an opaque fill blurs nothing and costs a
render layer for it. Falls back to an opaque surface under the platform's
reduced-transparency setting — an accessibility flag Flutter surfaces and
nothing in this app was honouring.

### `AppScaffoldMobile` — the collapsing, blurred bar M2 couldn't build

The other M2 deferral. A large title has to shrink in step with the page's own
scroll offset, which means the bar must be a sliver **inside** the page; and a
blurred bar only means anything if content passes underneath it. Both need the
page's cooperation, so both live in a page-level scaffold.

A screen opts in by using it *and* setting `AppRouteMeta.ownsChrome`, at which
point the shell renders no bar of its own and lets content run under a now
translucent tab bar. Title, back button and back destination all come from the
same `routeMetaFor` the shell reads, so a screen never names itself twice.

A detail screen gets a small title beside its back button; a branch root gets
the large one. Not cosmetic: a large title wants the leading edge to itself,
and a screen you can go back from has a button sitting exactly there.

### `InsetGroupedList` + `AppListRow`

Rows drawn as one inset card — rounded outside only, hairline dividers between
rows inset to clear the icon column. The card says "these belong together"; the
inset seams say "and these are the divisions inside it". A stack of bare
`ListTile`s under full-width rules says neither.

The group is a `Material`, not a `DecoratedBox`, specifically so rows can paint
their ink splash — the defect this app already has on the Player Profile, now
[filed separately](#).

Two rules the rows enforce:

- **A chevron only where the row navigates.** A toggle or Log out that wears
  one promises a screen it never opens. `showChevron` overrides; destructive
  rows never get one.
- **Label and value both flex.** The first cut had an `Expanded` label beside
  an unconstrained value, which overflowed the moment the value was something
  real — like the account's own email address. Caught by the test suite before
  it reached a screen.

### `AppSheet`

Seven call sites each opened `showModalBottomSheet` with their own arguments,
and they disagreed: some had a drag handle, some didn't; some were
scroll-controlled, some clipped themselves; corner radius was `lg` in five
places and square in two; and **none** reserved space for the home indicator,
which is why more than one sheet's last button sat under the gesture bar. Two
of them hand-rolled a keyboard inset the others simply lacked.

All seven now go through `AppSheet.show`. The only thing a caller still picks
is `backgroundColor`, because the feed and video sheets sit on the Player
Profile's darker surface — a deliberate feature palette rather than drift.
The comments sheets shed their own drag handles, keyboard padding and fixed
heights, all now the sheet's job.

### The primary button was never themed

Found while looking at the gallery: the theme styled `elevatedButtonTheme` and
nothing else, but the app's actual primary button is `FilledButton` — **31
files use it, against a handful using `ElevatedButton`**. Every one of those
fell through to Material 3's seeded `onPrimary`: dark navy text on brand blue,
at a contrast ratio nobody chose, on every form's submit button in the app.

Both now share one `_primaryButtonStyle`. A test pins them equal.

### Settings, rebuilt

The showcase consumer, and the worst screen in the app. What was there: an
untitled `Column` of two permanently expanded forms under a hardcoded English
`'Signed in as …'` — in an app whose default language is Arabic. **Every**
string it displayed was English, including both shared forms', which had l10n
keys sitting unused in the `.arb` files the whole time (`emailSectionTitle`,
`newEmailLabel`, `saveEmailLabel`, `emailUpdatedMessage`,
`currentPasswordLabel`, `passwordUpdatedMessage`, and the auth validation
messages).

It is now grouped rows in inset cards, the account's details at the top, each
change opening in a sheet instead of sprawling down the page, and the
destructive action alone at the bottom. Two new keys were added for the group
headers; everything else was already translated and simply unused.

### `/dev/gallery` — a preview surface

These components live on screens behind a login, against a database this
environment has no credentials for. They were being reviewed as code and as
widget tests, and never as pixels, which is how the button contrast problem
above survived until now.

The gallery renders the components and their states, and `/dev/settings`
renders the real Settings screen outside the shell. Both are compiled in only
under `--dart-define=SXH_GALLERY=true`, so neither can ship by accident. It
stays useful past this phase: it is where M4 compares a component's states side
by side without hunting for a screen that happens to show all of them.

---

## What was deferred, and why

`AppButton`, `AppActionSheet`, `AppSegmentedControl`, `AppSearchField`,
`AppToast`, `AppAvatar`, `AppPullToRefresh` and the skeleton/empty-state
expansions are **not** in this commit.

Each would have been a wrapper with no caller until M4 redesigns the screen
that needs it, and several would have been a wrapper around something the app
already does correctly. `AppToast` in particular was on the list to fix a
collision with the new tab bar — but `Scaffold` already lifts a `SnackBar`
above `bottomNavigationBar`, so there is no collision to fix and a
top-anchored toast is a style change that belongs with the screens raising it.

They land in the M4 wave that consumes them, on the same rule this phase
followed.

---

## Verification

- `flutter analyze` — clean.
- `flutter test` — 91/91. Eleven are new: the long-value overflow that already
  bit once, chevron-only-where-it-navigates across four row shapes, the
  destructive label color, that rows sit under a `Material` and can splash, n
  rows producing n−1 dividers, an empty group rendering nothing, `AppSheet`
  opening and returning its popped value, a screen that owns its chrome still
  declaring a title, and the two primary-button widgets resolving to the same
  style in both brightnesses.
- Rendered at 375×812 and 390×900 with a clean console: the rebuilt Settings
  screen (large title, grouped rows, correct chevron rules, Arabic throughout),
  and the gallery — where the blurred bar is visibly blurring the content
  scrolling under it, long values ellipsize instead of overflowing, and the
  filled button now reads white-on-blue.

**Two limits worth stating.** Tapping is unavailable in this harness's browser
pane, so sheet presentation and the title's collapse-on-scroll are covered by
widget tests rather than by a screenshot. And the shell around Settings still
needs a session to see; `/dev/settings` renders the page without it.

## Something found along the way

The web build uses Flutter's **hash URL strategy** — routes live after `#`, so
`/players/:id` only resolves as `/#/players/:id`. `app_router.dart` documents
those as "shareable URLs" and the sitemap advertises the path form. Worth
deciding on in M6/M7, when the service worker and PWA work touches the same
area.

---

## Next

M4 — the screen migration: Home and the Club dashboard, search and listings,
the profiles, then the forms, each flipping `ownsChrome` as it moves to
`AppScaffoldMobile`, and each bringing the component it needs with it.
