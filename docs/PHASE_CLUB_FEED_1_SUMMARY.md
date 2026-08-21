# Phase Club Feed 1 — Professional Social Feed

## Scope

Redesigned the Club's Home screen into a 3-column (desktop) / single-column (mobile) social-feed
layout, matching the reference image's design language while reusing every existing capability
(feed pagination, like/comment, post upload, club profile data, roster stats). No backend
rewrites — the two backend changes made this session (comments pagination shape) were bug fixes
requested separately, not part of this redesign.

## What changed

**Desktop** (`dashboard_page_desktop.dart`, Club branch)
- 2-column content area inside the existing app shell (which already provides the persistent left
  sidebar): a ~680px center feed column + a 320px right "at a glance" column.
- Center column: compact club identity header → `ClubComposerCard` → `ClubFeedTabs`
  (All/Photos/Videos) → the feed (`HomeFeedBody`, `role: club`).
- Right column: roster stats (2×2), profile-completeness card, recently added players — the same
  real data the old single-column dashboard showed, just laid out for a narrow column.

**Mobile** (`dashboard_page_mobile.dart`, Club branch)
- Own composition (not a scaled desktop layout): identity header → composer → tabs → feed, then
  stats/completeness/recent players below in the same scroll, as before.

**New shared widgets**
- `ClubComposerCard` — a tappable composer pill that opens the existing `CreatePostSheet`. Only a
  Photo action is offered: a Club can only ever publish a Photo post (`PostsService.createPost`);
  Video upload is a Player-only endpoint, and there is no text-only post type on the backend, so
  neither is faked here.
- `ClubFeedTabs` — All/Photos/Videos, a **client-side filter** over whatever page is already
  loaded. The feed endpoint has no `kind` query param, so switching tabs never fires a new
  request; a "Most Engaged" tab and a "Posts" (text) tab were **not** added since neither is
  backend-supported.
- `FeedItemCardSkeleton` — a card-shaped loading placeholder (author row, media rectangle, action
  row) so the feed's initial load matches the final layout instead of a bare spinner.

**`HomeFeedBody`** gained two additive, backward-compatible params:
- `kindFilter` — renders a filtered view of the already-loaded page (used by the tabs above).
  When the underlying page has items but the current filter matches none of them, a distinct
  "nothing of this type yet" message shows instead of the generic empty state.
- `onCreatePost` — shows a "Create your first post" CTA under the empty state when the feed is
  genuinely empty (Club role only); omitted elsewhere, so Player Home is unaffected.

**Mobile bottom navigation** (Club role only, `app_shell.dart`) — reordered to Home → Club
Profile → Club Players → Search → **More**, per explicit direction. "More" is a sentinel
destination (`#more`, never registered as a `GoRoute`) that opens a bottom sheet with Saved
Players, Community, Settings, and Logout instead of navigating directly. The active tab still
highlights "More" when the current route is one of those three, instead of falling back to Home.
Player/Admin bottom navs are unchanged.

## Explicitly not built (no backend support)

- Text-only posts, Video posting for Clubs, post edit/delete, "Most Engaged" sort, a `kind` query
  filter on the feed endpoint, Share, notifications, global search, a club verification badge —
  none of these exist in the backend today, so none were faked in the UI. Share was left out
  entirely for this phase rather than added as a client-only no-op.

## Verification

- `flutter analyze` (whole project): **no issues**.
- `flutter test` (whole project): **9/9 passed**, no regressions.
- Manual review pass: unused-variable cleanup in `dashboard_page_desktop.dart`, confirmed no new
  hardcoded strings (`homeFeedComposerPlaceholder`, `homeFeedCreateFirstPostCta`,
  `homeFeedTabAll/Photos/Videos`, `homeFeedFilteredEmptyState`, `moreNavLabel` added to both
  `app_ar.arb`/`app_en.arb` and regenerated), confirmed RTL relies on Flutter's own
  `Directionality` (no hardcoded left/right), confirmed Player Home (`HomeFeedPageDesktop`/
  `HomeFeedPageMobile`) is untouched.
- Live browser/visual verification was **not** performed this pass (the only preview target wired
  up is a static web build, which this environment doesn't build/serve quickly) — recommend a
  manual pass in the running app before sign-off.

## Follow-ups (not in this phase)

- Share action (native share sheet over caption/media — client-only, no backend change needed).
- Improved comments sheet presentation, video fullscreen/mute controls, post more-menu — all
  candidates for Phase 2, pending approval.

## Refinement pass (still Phase 1 — visual/layout only, no new features)

After a visual review of the first pass, the Club Home composition was reworked. No backend
changes; no commit made for this pass (pending explicit approval).

**Problem addressed:** the layout read as "a feed with some cards next to it" rather than a real
Club Management Dashboard — a narrow, sparse right sidebar with big vertical gaps between short
stat tiles, a feed boxed into an arbitrary fixed height that left large empty areas whenever a
club had few posts, and roster stats/identity that felt bolted on rather than integrated.

**Desktop** (`dashboard_page_desktop.dart`) — restructured top to bottom into an actual dashboard:
- Full-width identity header (`_ClubHomeHeader`, larger 72px logo, a divider closing the block)
  with two real actions: **View Public Profile** (`context.push('/clubs/:id')`, matching the
  existing Player pattern for "peek at your own public page") and **Edit Profile** (existing
  `/club/edit` route).
- Full-width roster-metrics row (`_ClubHomeStatsRow`) — the same 4 real stats as before (Total,
  Complete, Incomplete, Saved), now spanning the whole dashboard width instead of stacked 2×2 in a
  320px column, each with a "X% of roster" subtitle computed from the existing counts (no new
  metric).
- A "roster health" row (`_ClubHomeHealthRow`) pairing the existing completeness card with Quick
  Actions (`clubDashboardQuickActions` + `ClubQuickActionCard`, already built for the Club Profile
  page — reused, not duplicated logic) side by side. When a club has no roster yet (no
  completeness data), Quick Actions takes the full row instead of leaving half of it blank.
- Only the bottom section — feed (composer, tabs, posts) beside Recent Players — scrolls/flexes:
  it sits in an `Expanded` `Row`, so the feed gets exactly the real remaining viewport height
  instead of a guessed constant, and widens to use the actual column width
  (`HomeFeedBody(maxWidth: double.infinity)`) instead of being capped at 640px.

**Mobile** (`dashboard_page_mobile.dart`) — reordered to match the requested hierarchy: identity
header (with the same two actions, as icon buttons) → roster metrics (2-per-row) → Quick Actions →
composer → feed tabs → feed → completeness/Recent Players as trailing detail. Own composition,
not the desktop layout scaled down.

**Shared widget change** — `ClubDashboardStatTile` gained an optional `subtitle` line (used for
the "% of roster" text); fully backward-compatible, existing callers unaffected.

**New localized strings** (`app_ar.arb`/`app_en.arb`, regenerated): `clubDashboardPercentOfRosterLabel`,
`clubHomeViewPublicProfileLabel`.

**Verification:** `flutter analyze` (whole project) — no issues. `flutter test` — 9/9 passed. One
review pass performed (confirmed bounded-height propagation through the new `Expanded` chain,
switched the public-profile action from `context.go` to `context.push` to match the existing
Player "view public profile" navigation convention). No commit was made — awaiting approval.

## Regression fix — feed had disappeared from Desktop

The refinement pass above introduced a real regression: on Desktop, the feed could render at
near-zero height and effectively vanish. Root cause and fix, no backend changes, still Phase 1.

**Root cause:** the page had become a *non-scrolling* `Column` where only the final row (feed +
Recent Players) was wrapped in `Expanded`, with everything above it (identity, stats, the
health/quick-actions row) sized to its own intrinsic height. Two compounding bugs made that fixed
portion much taller than intended, starving the `Expanded` feed row of space (down to ~0px on
common viewport heights):
1. `_ClubHomeHealthRow` wrapped the completeness card and the Quick Actions grid in
   `IntrinsicHeight`, forcing both panels to match the taller one's height.
2. The Quick Actions `GridView`'s `childAspectRatio` (2.8, later checked against 2.6) was tuned for
   a much narrower column than the ~half-dashboard-width column it actually renders in — at that
   width it produced ~130–145px-tall cells for ~80px-tall content, both inflating the row's own
   height *and* leaving visible empty space inside every Quick Action card (exactly what showed up
   in the screenshot).

**Fix:**
- The whole page is one `SingleChildScrollView` again (as in the original Phase 1), so the fixed
  chrome above the feed can never starve it.
- The feed+Recent-Players row now gets an explicit height computed from the real viewport height
  via `LayoutBuilder` (`maxHeight * 0.8`, clamped to `[600, 980]`) — captured *before* the scroll
  view, so it reflects the actual window rather than "whatever's left". Generous on tall screens,
  a guaranteed usable minimum on short ones.
- `IntrinsicHeight` removed from `_ClubHomeHealthRow` — each panel now sizes to its own content.
- Quick Actions `childAspectRatio` changed to `4.3`, tuned for its actual (wide) column width so
  each card fits its icon/title/description without excess padding.
- Recent Players changed from a fixed `SizedBox(width: 340)` to `Expanded` (flex 1, vs. the feed
  column's flex 2 — a ~68/32 split), per the "responsive constraints, not hardcoded pixel widths"
  requirement.
- Confirmed exactly one `HomeFeedBody` instance exists on the page (no duplicate feed introduced).

**Verification:** `flutter analyze` (whole project) — no issues. `flutter test` — 9/9 passed.
Mobile was checked and was never affected (its feed already sat in a fixed-height box inside a
normal scrolling column, not competing with an `Expanded` sibling). No commit was made — awaiting
visual approval.
