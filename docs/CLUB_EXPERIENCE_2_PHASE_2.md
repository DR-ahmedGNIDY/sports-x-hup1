# Club Experience 2.0 — Phase 2: Professional Player Management & Add Player

**Status:** Phase 2 of 3 implemented. Scope: turn Add Player into a guided,
step-based experience and surface real per-player profile completeness in
the roster — the two gaps left after inspecting what the prior "Phase Club
1/2/3" project (see `docs/PHASE_CLUB_1..3_SUMMARY.md`) had already built.

## 0. Inspection first

Before writing anything, the current roster/player-management code was
re-inspected against this phase's brief:

Already done by Phase Club 2/3 (untouched here):
- Desktop roster **table** (Player/Sport/Position/Status/Phone/Actions,
  hover, dense rows) vs. Mobile roster **cards** — genuinely different,
  not a shrunk clone.
- View / Edit / Resend WhatsApp / Remove from club, all from the roster
  (overflow menu on both platforms).
- `DELETE /club-players/:playerId` — removes only the `ClubManagedPlayer`
  ownership row, never the player's `User`/`PlayerProfile`. Confirmed by
  reading `removeFromClub` — unchanged.
- Ownership enforcement (`requireOwnership()`), `JwtAuthGuard`/`RolesGuard`
  on every `club-players` endpoint — unchanged, not touched.
- `ClubLevel` enum (amateur/semi_professional/professional), legacy-value
  tolerant — unchanged.
- Server-side pagination + search (name/phone) + Sport/Position filters —
  unchanged.
- Loading/empty/search-empty/error/pagination states — unchanged, already
  localized.

Real gaps found and addressed this phase:
1. **Add Player was one long scrolling form**, not the brief's guided
   4-step flow.
2. **No per-player completeness signal in the roster** — only the
   Dashboard's roster-wide aggregate (Phase 1) existed; nothing at the
   individual-player level the brief's §3 asks for.

## 1. Add Player — 4-step wizard

`AddClubPlayerForm` (`club_players/presentation/shared/add_club_player_form.dart`)
is now a 4-step flow instead of one long form:

1. **Basic Information** — first/last name, date of birth, country, city,
   nationality.
2. **Sports Information** — sport, position, preferred foot, height,
   weight, bio.
3. **Contact** — phone (dial code shown from step 1's country), email.
4. **Account** — a review card (name, phone) + "Create account", which
   still opens the existing credentials dialog (username/password + Send
   via WhatsApp) unchanged.

All field logic, controllers, and the final `_submit()` call are the exact
same code that existed before — only the presentation was restructured
into steps. `Next` validates only the current step's required fields
(a `GlobalKey<FormState>` per step that has any); `Back` never re-validates.

**Desktop vs. Mobile chrome, not a scaled clone:** the widget takes an
`isDesktop` flag from its caller (the already-desktop/mobile-specific page
files — the shared widget itself doesn't inspect `MediaQuery`, matching
`core/utils/breakpoints.dart`'s "only the page layer branches on
breakpoint" rule):
- **Desktop**: a horizontal row of numbered circles connected by lines,
  with the step title under the active one; Back/Next sit right-aligned
  in a row.
- **Mobile**: a compact "Step X of 4" label + a linear progress bar; the
  primary action is a full-width button with Back as a plain text button
  beneath it — the usual mobile stacked-button pattern.

Live-verified end-to-end in the browser: stepped through all 4 steps,
confirmed per-step validation (Next is blocked until required fields in
that step are filled), confirmed Back preserves every field already
entered, and confirmed the review step correctly shows the dial-code-
prefixed phone. Successfully created a player and got the existing
credentials dialog with a working WhatsApp button.

## 2. Per-player profile completeness in the roster

The brief's §3 wants "Status: Profile completeness/status if supported"
per row. Backend: `toOwnerView()` (`players.mapper.ts`) now includes
`completionPercent`, computed via the same `completionPercentFor()` helper
Phase 1 already extracted from the per-field `COMPLETION_CHECKS` checklist
— no schema change, no new concept, the exact same completeness definition
used everywhere else in the app. `toOwnerView` backs every club-players
response (create/list/get/update/photo-upload) plus the player's own `me`
endpoints and the admin player list, so every one of those callers now
carries this field for free.

Frontend: a new shared `ClubPlayerCompletenessChip` (small pill, colored —
success tint at 100%, primary tint otherwise) replaces the Desktop roster
table's **Status** column (previously the `currentStatus` free-text field,
which Phase 3's own audit already flagged as "the only status-shaped field
available at the time" — now there's a real one) and is added to the
Mobile roster card underneath the phone number. Renders nothing when
`completionPercent` is `null` (never fabricates a value).

Live-verified: created a player with only name/phone/country filled in,
confirmed the roster card showed "31% complete" — the same number the
backend's checklist computes.

## 3. Bug found and fixed: duplicate-null-email collision on Add Player

While live-testing the Add Player wizard with the email field left blank
(it's optional), the second such player in this session failed with a
raw `Internal server error`, traced to a backend `MongoServerError:
E11000 duplicate key ... email_1 dup key: { email: null }`. Root cause:
`UsersService.createClubManagedPlayer` passed `email: input.email` to
`userModel.create()` even when `input.email` was `undefined`; the field's
index is `unique + sparse`, which only skips documents where the path is
truly absent — not documents that end up with an explicit `null`.
Confirmed by retrying with a real email (succeeded immediately) and by
reading the schema's sparse-unique setup.

Fix (`users.service.ts`): the `email` key is now only included in the
document passed to `.create()` when a value is actually present, so the
path stays genuinely unset for players created without one — the sparse
index then does what it's meant to. Two new unit tests
(`users.service.spec.ts`) cover both cases (email omitted → key absent
from the inserted doc; email given → present). This directly affects the
Add Player feature this phase is about (email is explicitly optional per
the brief's own Step 3), so it was in scope to fix rather than merely
document.

## 4. Security

No guard, role, or ownership logic changed. The new `completionPercent`
field is derived entirely from data the caller of `toOwnerView` was
already authorized to see (the profile document itself) — no new query,
no new cross-boundary exposure. `DELETE /club-players/:playerId`,
`requireOwnership()`, and every existing test around Club A vs. Club B
isolation are untouched and still pass.

## 5. Localization

New keys (`ar`+`en`): `clubPlayerNextLabel`, `clubPlayerStepBasicInfoTitle`,
`clubPlayerStepSportsInfoTitle`, `clubPlayerStepContactTitle`,
`clubPlayerStepAccountTitle`, `clubPlayerStepIndicatorLabel`,
`clubPlayerReviewTitle`, `clubPlayerReviewSubtitle`,
`clubPlayersTableColumnCompleteness`, `clubPlayerProfileCompleteLabel`,
`clubPlayerProfilePercentCompleteLabel`. The existing `backLabel` is
reused for the wizard's Back button rather than adding a duplicate key.
`flutter gen-l10n` was run to regenerate the Dart delegates.

## 6. Verification

- `flutter analyze` — **no issues**.
- `flutter test` — **9/9 passing**.
- Backend `npm run build` — **clean**.
- Backend `npm run lint` — **one pre-existing error**, unrelated
  (`src/videos/videos.service.ts:25`), unchanged from Phase 1/Phase Club
  2-3.
- Backend `npm test` — **58/58 passing** (10 suites; 2 new tests in
  `users.service.spec.ts` for the email-omission fix).
- Live manual verification against a real (Atlas) MongoDB backend:
  stepped through the full 4-step Add Player wizard on Mobile, hit and
  diagnosed the null-email bug, fixed it, retried successfully, confirmed
  the credentials dialog + WhatsApp button, and confirmed the roster card
  shows the new completeness chip with a real, correctly-computed
  percentage.

## 7. Known limitations

- **Desktop visual verification of the wizard's step-indicator chrome**
  (the horizontal circles) was not captured as a screenshot — same
  environment limitation as Phase 1 (this session's browser preview
  harness doesn't propagate post-load viewport resizes to the Flutter
  canvas). The Desktop chrome was verified via code review and
  `flutter analyze`; it shares 100% of the field/validation/submit logic
  with the Mobile path that was visually confirmed.
- **The Desktop roster table's popup overflow menu** (View/Remove) could
  not be clicked open in this session's automation (a UI-automation
  flakiness in the harness, not a reproduced app error) — it is unchanged
  code from Phase Club 2, already covered by that phase's own review.
