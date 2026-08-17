# Club Experience 2.0 — Phase 1: Dashboard, Identity & Navigation

**Status:** Phase 1 of 3 implemented. Scope: turn the Club Dashboard into a real
operational dashboard with a genuine club identity, roster-wide profile
completeness, and a navigation order that puts the Club's daily work
(Manage Players → Discover Players) ahead of Community.

## 0. Important context: this is not greenfield

Before writing any code, the actual repository was inspected against the
brief, the current UI, and git history. That inspection found a prior
project — **"Phase Club 1/2/3"** (commits `abd185c`, `658c34e`, `b5bd450`,
`4c90a43`; see `docs/PHASE_CLUB_1_SUMMARY.md` through `_3_SUMMARY.md`) —
had already delivered a large share of what this brief asks for: dashboard
stat tiles, a "recently added players" list, 5 Quick Actions, a desktop
roster **table** vs. mobile roster **cards**, server-side pagination/search/
filtering, view/edit/remove/resend-WhatsApp with ownership enforcement, and
full ar/en localization of all of it.

Phase 1 of Club Experience 2.0 is therefore a **delta on top of that work**,
not a rewrite. Nothing from Phase Club 1–3 was reimplemented or replaced.

## 1. Club Identity Header

New `ClubDashboardIdentityHeader` widget
(`features/dashboard/presentation/shared/club_dashboard_widgets.dart`) —
logo, name, and a `location · founded year · level` line built only from
fields the club has actually filled in (`ClubProfile.city/country/
foundedYear/level`). No sport field exists on `ClubProfile`, so it is not
shown — nothing invented. Falls back to "Unnamed club" when the club hasn't
set a name yet. Rendered above the stats on both Desktop (64px logo) and
Mobile (52px logo, same widget, smaller size — not a separate copy).

## 2. Saved Players stat tile

`ClubDashboardSavedPlayersTile` reads the already-loaded
`savedPlayersControllerProvider` list length. No new backend endpoint —
`GET /saved-players/me` returns a club's full shortlist already, and a
shortlist is small by nature (not a paginated collection worth a count-only
endpoint). Dashboard now shows 4 stat tiles: Total, Complete, Incomplete,
Saved.

## 3. Roster-wide profile completeness

Backend: `GET /club-players/summary` gains two fields —

- `averageCompletionPercent` — the roster-wide average of each player's own
  completion percentage (the exact per-field checklist
  `GET /players/me/stats` already uses), `null` for an empty roster.
- `topMissingFields` — up to 3 field keys most frequently missing across the
  roster (ties broken by checklist order), `[]` when nothing is missing.

Both reuse the **existing** `COMPLETION_CHECKS` checklist in
`players.mapper.ts` — no schema change, no new "completeness" concept
invented. `isProfileComplete`'s original logic (`.every()`, short-circuiting)
is untouched; two new helpers were extracted for reuse:
`missingFieldsFor(profile)` and `completionPercentFor(profile)`.
`toStatsView` (the Player's own stats endpoint) was refactored to call
these same helpers instead of duplicating the same `Object.entries(...)
.filter(...)` logic inline — behavior-preserving, confirmed by the existing
`players.mapper.spec.ts` suite still passing unchanged.

Frontend: `ClubDashboardCompletenessCard` — a progress bar + percentage,
and "Most commonly missing: <labels>" using the field labels the Player
Dashboard's own completion checklist already localizes
(`missingFieldLabel` in `player_enum_labels.dart`, reused as-is — one
switch statement stays the single source of truth for these labels across
both Player and Club dashboards).

## 4. Quick Actions — hierarchy + descriptions

`ClubQuickAction` gained `description` and `emphasis`
(`primary`/`secondary`/`tertiary`). Add Player is `primary` (tinted card,
no elevation); My Players/Find Players are `secondary` (default elevated
card); Saved Players/Edit Club Profile are `tertiary` (outlined, flat).
Desktop renders these as a vertical column of icon+title+description cards
next to Recent Players; Mobile keeps the existing `ListTile` list but adds
the description as a `subtitle`.

## 5. Navigation — Players before Community

Per the brief ("Do NOT prioritize Community over Players for the Club"),
the Club's sidebar/bottom-nav order changed:

- **Desktop sidebar** (`app_shell.dart`): the flat, role-filtered
  `_navItems` list is now split into a default list (Player/Admin,
  **unchanged order**) and a dedicated `_clubNavItems` list: Dashboard →
  My Players → **Add Player** (new sidebar entry) → Find Players → Saved
  Players → Community → Club Profile → Edit Club Profile → Settings.
  Selected via `_navItemsFor(role)`; Player/Admin sidebars are byte-for-byte
  the same order as before this phase.
- **Mobile bottom nav**: Club destinations are now Home → My Players →
  Find Players → Saved Players → Community → Settings (6 tabs, same
  precedent as the Player role's existing 5-tab bar) — Community/Settings
  moved to the tail instead of sitting ahead of the Club's actual daily
  tools.

## 6. Desktop layout width

The Desktop dashboard no longer sits in a narrow 880px centered column. It
now uses up to 1400px, with stats as a 4-up row and a two-column split below
(Recent Players / Quick Actions) — closer to the brief's suggested desktop
layout while staying inside the app's existing container/spacing
conventions.

## 7. Loading states

Both platforms replace the bare `CircularProgressIndicator` with a
skeleton layout (`SkeletonBox`, an existing shared widget — no new
dependency) shaped like the real content: 4 stat-tile placeholders + a
two-column body placeholder on Desktop, stacked 2-up tile placeholders + a
card placeholder on Mobile.

## 8. What was deliberately left alone

- Roster table/cards, pagination, search, filters, edit/remove/resend —
  untouched (Phase Club 2–3 already built these correctly).
- `ClubLevel` enum, ownership checks, guards — untouched.
- Public Club Profile page — untouched (brief: "do not fully redesign the
  Public Club Profile in Phase 1").
- Empty/error state copy for the roster and saved-players screens — already
  localized and correct from earlier phases; not touched.

## 9. Security

No endpoint's guards, roles, or ownership checks changed.
`GET /club-players/summary` still sits under
`@UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CLUB)`, and the new
`averageCompletionPercent`/`topMissingFields` fields are computed from the
same already-scoped `profiles` array the endpoint already had (sourced from
`ownershipsForClub(clubId)` → `findManyByUserIds`) — no new query, no new
cross-club data exposure.

## 10. Localization

New keys (`ar`+`en`): `clubDashboardFoundedLabel`,
`clubDashboardCompletenessTitle`, `clubDashboardCompletenessMissingLabel`,
`clubDashboardAddPlayerDescription`, `clubDashboardMyPlayersDescription`,
`clubDashboardFindPlayersDescription`, `clubDashboardSavedPlayersDescription`,
`clubDashboardEditProfileDescription`. The Saved Players stat tile reuses
the existing `dashboardSavedPlayers` key rather than adding a near-duplicate.
`flutter gen-l10n` was run to regenerate the Dart localization delegates.

## 11. Verification

- `flutter analyze` — **no issues**.
- `flutter test` — **9/9 passing**.
- Backend `npm run build` — **clean**.
- Backend `npm run lint` — **one pre-existing error**, unrelated
  (`src/videos/videos.service.ts:25`, `VideoCommentDocument` unused) —
  same one already noted in Phase Club 2/3's summaries, untouched by this
  phase's diff.
- Backend `npm test` — **56/56 passing** (10 suites), including 2 updated
  assertions in `club-players.service.spec.ts` for the new
  `averageCompletionPercent`/`topMissingFields` fields (zeroed for an empty
  roster; correctly averaged/ranked for a mixed roster).
- Live manual check: registered a fresh Club account against a real
  (Atlas) MongoDB instance through the actual UI, confirmed the Club
  Dashboard renders correctly end-to-end on Mobile — identity header
  correctly falls back to "Unnamed club" with no fabricated fields, Quick
  Action cards show icon/title/description, empty-roster state is correct,
  and the reordered bottom nav (Home → My Players → Find Players → Saved
  → Community → Settings) matches spec. Confirmed via network trace that
  `GET /club-players/summary` returns the new fields without error.

## 12. Known limitations

- **No live end-to-end run of the Desktop layout** — the browser preview
  harness available in this environment renders the Flutter (CanvasKit)
  web build at a viewport size fixed at initial page load; programmatic
  window resizes after load do not propagate to the Flutter canvas, so the
  Desktop-breakpoint layout could not be visually screenshotted at full
  size in this session (same class of limitation Phase Club 1–3 already
  documented for live verification generally). The Desktop code path was
  verified via `flutter analyze`/`flutter test`, code review, and the fact
  that it shares every data widget (`ClubDashboardIdentityHeader`,
  `ClubDashboardCompletenessCard`, `ClubDashboardSavedPlayersTile`,
  `ClubDashboardStatTile`) with the Mobile layout that *was* visually
  confirmed. Recommend a manual Desktop-viewport QA pass before shipping.
- **Roster-wide completeness is an aggregate, not per-player** — the brief's
  example ("82%, Missing: Profile photo, Achievements") reads per-player;
  Phase 1 is dashboard-level, so it was implemented as a roster-wide
  average with the most commonly missing fields. Per-player completeness in
  the roster table itself is Phase 2 territory ("Status: Profile
  completeness/status if supported") and was left there.
