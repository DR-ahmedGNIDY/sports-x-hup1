# Phase Mobile M2 — the shell and navigation

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M2
**Goal:** make moving around the app feel like an app rather than a series of
page loads.
**Status:** complete. Analyze clean, 80/80 tests passing, built.

---

## What shipped

### The shell is stateful now

`ShellRoute` became `StatefulShellRoute.indexedStack`. Every authenticated
route belongs to exactly one of eleven branches (`lib/core/navigation/app_branches.dart`),
and each branch owns a `Navigator` and keeps its own state and scroll
position.

Switching tabs used to rebuild the destination screen from scratch — the feed
refetched, scroll jumped to the top, a half-filled form was gone. Now the tab
comes back exactly as you left it. This is the single change in the phase that
most separates "the app remembered where I was" from "the page reloaded".

Branch order is derived from `AppBranch.values`, because
`StatefulNavigationShell.currentIndex` is an integer into the router's branch
list and the shell turns that integer back into an `AppBranch`. If the two
ever disagree nothing crashes — the wrong tab just quietly looks selected — so
the invariant is pinned by tests rather than by a comment.

Routes inside a branch stay flat, which kept **every URL exactly as it was**:
`/player/edit` did not become `/player/preview/edit`. The trade is that there
is no navigator stack to pop, so a detail screen declares where its back
button goes via `AppRouteMeta.parentPath` instead of inferring it.

### A top bar that knows what screen you're on

The old mobile bar was the same on all sixteen screens: the logo plus
theme/language/logout buttons. It told you nothing about where you were and
offered no way back.

Now it names the screen, and carries a back button on any screen that has a
parent. The logo appears only on Home — the way a phone app puts its wordmark
on the first tab and a screen name on every other. Theme, language and logout
moved into the account sheet, where a phone app keeps them.

Screens that were rendering their own heading no longer do, since that would
have been two titles on one screen. Where such a heading sat beside an action
button (Search's filters, Club Players' add, the two edit screens' preview),
the action stayed but became a labelled button: with no adjacent title to lend
it context, a lone glyph reads as decoration.

### A tab bar with feedback

Hand-built rather than a `NavigationBar`, because the account slot isn't a
destination — it opens a sheet.

- The selected tab's icon switches from outlined to **filled**. That weight
  change is what reads as "you are here", before the color does.
- Each slot scales to 0.9 while held. A flat icon has no other way to
  acknowledge a finger, and its absence is a large part of why a web app feels
  unresponsive to touch.
- Re-tapping the active tab returns it to its root **and** scrolls it to the
  top — every phone app treats that as "take me back to the start of this
  section", and doing nothing is one of those small absences that makes an app
  feel inert.
- The last slot is the user's own avatar rather than a "…" glyph, and it reads
  as selected whenever the active screen is one of the ones behind it.

### Page transitions

go_router's web default is no transition at all — a screen is simply replaced,
which is exactly how a web page behaves and exactly how an app does not.
`app_page_transitions.dart` adds two, borrowed from the grammar every phone
platform shares: a slide for hierarchical moves (the outgoing screen parallaxes
a quarter of the way, so the two don't read as one flat sheet), and a
cross-fade for lateral ones. Both mirror themselves in RTL, and both collapse
to an instant swap under reduced motion.

### Edge-swipe back

Swiping in from the leading edge goes back, on any screen that has somewhere to
go. The detector is a 24px strip rather than the whole screen: a full-width
horizontal drag listener would fight every carousel and swipeable row on the
page for the same gesture. In RTL both the strip's side and the expected
direction flip, read off the same `Directionality` as the app bar's arrow.

### The account sheet

The old More sheet was a bare `ListTile` list, Club-only. It's now a real
account sheet for every role: a drag handle, who you're signed in as at the
top, the screens that didn't earn a permanent tab, the app-wide toggles that
used to occupy the top bar on every single screen, and a logout separated and
colored as the destructive action it is.

---

## Two bugs found on the way

**`FadeSlideIn` read `MediaQuery` in `initState`.** That registers an inherited
dependency before the element is ready for one, tripping a framework assertion
in debug — the Player Profile screen would have thrown for anyone running a
debug build at phone width. Pre-existing, unrelated to this phase, fixed here
because the new shell test surfaced it: the read moved to
`didChangeDependencies` behind a one-shot guard.

**Admin lost a sidebar entry.** Folding both admin screens into one branch
would have dropped `/admin/players-clubs` from the desktop sidebar (it stayed
reachable from the users page, but that is not what it had before). They are
peers, not a screen and its detail, so they are now two branches.

A third, left alone: mounting the Player Profile trips *"ListTile background
color or ink splashes may be invisible"* — tap ripples on some profile rows are
painted behind an opaque background. Pre-existing, out of scope here, and
flagged as its own task; the shell test routes its Player case through Settings
rather than asserting on that page's internals.

---

## Deliberate deviations from the plan

**No translucent/blurred bars, and no collapsing large title.** Both were
listed for M2, and both turn out to belong to M3.

A large title has to *collapse with the page's scroll view*, which means the
app bar must be a sliver inside each page — a shell-level bar cannot do it.
Blur has the same dependency from the other side: it only means anything if
content passes under the bar (`extendBodyBehindAppBar`), and turning that on
without page cooperation slides content under the bar on the ~30 screens that
lay themselves out with plain padding. Both land in M3 with
`AppScaffoldMobile`, which is where the page-level sliver plumbing belongs —
and `AppBlur` lands with them rather than as a constant nothing reads.

**Tab sets changed shape.** Every role now gets up to four tabs plus a uniform
account slot, instead of Player having five tabs and no sheet while Club had
four and a More button. Five slots is the practical ceiling before labels start
truncating at 320px.

**The Player's desktop sidebar lost its separate "Edit Profile" row.** It is one
branch with the profile it edits, and the profile page has an Edit button —
the same treatment mobile already gave it.

---

## Verification

- `flutter analyze` — clean.
- `flutter test` — 80/80. Twenty-three are new:
  - `test/core/navigation/app_branches_test.dart` (11) pins the invariants the
    shell depends on silently: unique root paths, every root has metadata,
    selected and unselected icons actually differ, only Home is untitled, every
    detail route declares a reachable parent, no branch root has a back button,
    no role exceeds four tabs, every role can reach Home and Settings, nothing
    is both a tab and a sheet entry, and admin tooling never leaks into a
    Player's navigation.
  - `test/core/widgets/mobile_shell_test.dart` (12) drives the **real router**
    with only the session and profile providers stubbed, because the behaviour
    this phase buys lives in the seam between `StatefulShellRoute` and
    `AppShell` — testing the widgets in isolation would test neither the seam
    nor the branch indices. It covers the app bar naming the screen, the logo
    on Home, a back button that lands on the declared parent, no back button on
    a branch root, tab switching and the filled-icon selected state, **a tab
    keeping its state across a visit to another tab**, re-tap returning a tab to
    its root, the account sheet's contents and navigation, edge-swipe back
    working where there is a parent and doing nothing where there isn't, and a
    Player getting Player tabs rather than Club ones.
- `flutter build web --release` succeeds; the marketing site (outside the
  shell) renders unchanged at 375×812 with a clean console.

**A limit worth stating plainly:** the authenticated shell was not verified in
a real browser. Reaching it needs a live session against the project's Atlas
database and credentials I don't have, so the widget tests above — which drive
the actual router — are the evidence for this phase, not a screenshot.

---

## Next

M3 — the mobile component library: `AppScaffoldMobile` (bringing the collapsing
large title and blurred bars deferred from here), inset grouped lists, a
unified sheet and action sheet, `AppButton`, a search field, toasts that don't
collide with the tab bar, and cached avatars.
