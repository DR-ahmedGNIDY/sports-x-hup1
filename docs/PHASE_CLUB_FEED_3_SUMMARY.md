# Phase Club Feed 3 — Final Polish & Performance

## Scope

Small, targeted polish items across the feed/comments surfaces touched in Phases 1–2: real RTL
bugs, missing accessibility labels, and a check of the app's Riverpod/caching setup. No new
features, no backend changes, nothing visually redesigned.

## What changed

**RTL bug fixes** — `Alignment.centerLeft` hardcodes the *screen* left edge regardless of reading
direction, so in Arabic (RTL) these three titles/buttons were sitting on the wrong side of the
screen instead of at the natural reading-direction start:
- The comments sheet title ("التعليقات") in both `feed_comments_sheet.dart` and
  `video_comments_sheet.dart`.
- The Save button in `club_info_section.dart` (Club Edit Profile).

All three changed to `AlignmentDirectional.centerStart`, which follows `Directionality` correctly
in both languages.

**Accessibility** — icon-only tap targets in the Home feed's post card had no `Tooltip`/label for
screen readers, unlike the Share button added in Phase 2:
- `FeedLikeButton` — new `Tooltip` ("Like"/"Unlike", switching with state).
- The comment-count tap target in `FeedItemCard` — new `Tooltip` ("Comments").

New localized strings (`app_ar.arb`/`app_en.arb`, regenerated): `feedLikeTooltip`,
`feedUnlikeTooltip`, `feedCommentsTooltip`.

**Performance/Riverpod review (no changes made)** — checked for the two things Phase 3 was scoped
to look at:
- `clubDashboardSummaryProvider` is a plain (non-`autoDispose`) `FutureProvider` — already cached
  across navigations, not refetched on every visit to Home; only invalidated explicitly after a
  roster mutation (add/edit/remove player). No change needed.
- Club Home's `ref.watch` calls are each read once per screen and the resulting data passed down
  via constructor params (not re-watched per sub-widget) — already avoids the redundant-rebuild
  pattern `.select` would otherwise fix. No meaningful `.select` opportunity found without
  restructuring working code for a marginal gain, so none was made.
- `Image.network`/`NetworkImage` (club logos, avatars, feed media) already participate in
  Flutter's built-in `ImageCache` by URL — no separate caching package was needed or added.

## Explicitly not built

- No new caching package, no skeleton redesign, no animation additions — none were needed once the
  above was checked; adding them anyway would have been polish for its own sake, not a real fix.

## Verification

- `flutter analyze` (whole project): no issues.
- `flutter test` (whole project): 9/9 passed, no regressions.
- One review pass: confirmed the `Tooltip` wrapping in `FeedLikeButton` didn't break the existing
  `ScaleTransition`/`AnimatedSwitcher` micro-animation (bracket/nesting check), confirmed the RTL
  fixes are `AlignmentDirectional` (not another hardcoded side).

## Follow-ups (not in this phase)

- The same `Alignment.centerLeft`-style RTL check was intentionally scoped to files already
  touched this project (Club Home, its comments sheets, and the adjacent Club Edit Profile page) —
  a full-codebase RTL audit is out of scope for a Club Home phase.
