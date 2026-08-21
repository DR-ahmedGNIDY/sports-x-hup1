# Phase Club Feed 2 — Social Interaction & Discovery

## Scope

Small, backend-honest improvements to the feed's social-interaction surfaces, per the agreed Phase
2 scope. No backend changes, no invented capabilities — post edit/delete and comment-count
analytics were explicitly left out since neither exists in the backend.

## What changed

**Comments presentation** (both `video_comments_sheet.dart` and `feed_comments_sheet.dart`)
- Extracted a shared `CommentTile` widget (`videos/presentation/shared/comment_tile.dart`) — an
  avatar (initial), the commenter's name, a small role badge (Player/Club/Admin, from the
  already-returned `authorRole` field that was previously unused in the UI), and a timestamp (from
  the already-returned `createdAt`, also previously unused), then the comment text and a delete
  action for the commenter's own comment. Both sheets' state management (load/send/delete/paging)
  is untouched — only the per-row presentation moved into the shared widget, since it has no
  repository dependency and both sheets render the same `VideoComment` shape.
- Empty state now uses `EmptyStateIllustration(variant: noData)` instead of bare text, matching
  the empty-state pattern used elsewhere in the app.

**Video mute/unmute** (`video_player_screen.dart`) — a mute toggle button (bottom-end of the
player, so it sits correctly in both RTL and LTR) using the existing `VideoPlayerController`'s
`setVolume`. No new dependency; state persists correctly across the existing Retry flow.

**Share** (`feed_item_card.dart`) — a Share icon in the post's action row. There's no public
per-post page to link to (no `/posts/:id` or `/videos/:id` route exists), so — following the
exact precedent already set by `ShareProfileButton` ("no backend endpoint exists for sharing, so
this is the smallest honest implementation") — it copies the caption + the direct media URL to the
clipboard via `Clipboard.setData`, with a snackbar confirmation. No new package dependency was
added: a `share_plus` native-share-sheet version was drafted and then reverted in favor of this
existing in-app convention, once the precedent was found.

**Discovery integration** — reviewed `PlayerSearchResultCard` (used by both Search Players and
Saved Players): it already shows the live saved/unsaved bookmark state per search result and lets
a Club toggle it inline. This was already fully implemented — no changes were needed, and none
were made.

## Explicitly not built (no backend support)

- Post edit/delete, a post "more" menu — no backend endpoint exists for either.
- Native share sheet (`share_plus`) — reverted in favor of the existing Clipboard-copy convention
  already established by `ShareProfileButton`, to avoid introducing a second, inconsistent "share"
  pattern and an unnecessary new dependency.

## Verification

- `flutter analyze` (whole project): no issues.
- `flutter test` (whole project): 9/9 passed, no regressions.
- One review pass: confirmed the mute toggle keeps its icon consistent with the actual controller
  volume across the Retry flow; confirmed no duplicate localization keys; confirmed the `share_plus`
  dependency was fully reverted (`pubspec.yaml`/`pubspec.lock` unchanged) after switching to the
  Clipboard approach.
- Live browser/visual verification was not performed (same environment limitation as Phase 1 — no
  quick web-build preview target here).

## Follow-ups (not in this phase)

- If/when the backend adds post edit/delete, a post "more" menu becomes straightforward to add
  using the same pattern as the existing comment delete confirmation dialog.
