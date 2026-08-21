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
