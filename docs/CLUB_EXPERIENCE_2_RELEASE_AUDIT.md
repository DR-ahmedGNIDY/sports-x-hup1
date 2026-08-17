# Club Experience 2.0 — Release Audit

**Audit type:** Independent verification pass. Code-inspection based, not a
re-read of prior phase summaries — every claim below was checked against
the actual source, the actual git history, and a fresh run of the actual
test suites. No source code, tests, or existing documentation were
modified during this audit.

**Scope audited:** the three Club Experience 2.0 commits (`b0a6c29`,
`99f6288`, `d08aaff`) and everything they touch — Club Dashboard, Club
Identity, Navigation, Player Management, Add Player, Player Discovery,
Saved Players, and their integration points with the pre-existing Player
Profile, Contact, and ownership systems.

---

## 1. Executive Summary

**Overall status: READY WITH MINOR ISSUES**

All three phases are implemented, committed, pushed, and internally
consistent with each other. Every backend endpoint touched by Club
Experience 2.0 sits behind `JwtAuthGuard` + `RolesGuard` + an explicit
`requireOwnership()`/scoping check — verified by reading the actual guard
and service code, not by trusting comments. No IDOR, no private-contact
leak, and no MVP-scope violation (AI, payments, contracts, chat, etc.) was
found anywhere in the audited code. All test suites pass: **58/58**
backend, **9/9** frontend, `flutter analyze` clean, backend build clean.

Nothing found rises to Critical or High. Two Medium findings are real but
non-blocking (a missing index for the new name-search feature, and zero
automated test coverage for the search endpoint itself — both performance/
safety-net gaps, not correctness or security defects). Four Low findings
are minor polish/hygiene notes. None of this blocks building Phase 4+ on
top of the current state.

---

## 2. Phase 1 Audit — Dashboard, Identity & Navigation

**Status: PASS**

- **Club Identity Header** (`ClubDashboardIdentityHeader`,
  `club_dashboard_widgets.dart`): renders logo, name, and a
  `location · founded year · level` line built strictly from
  `ClubProfile.city/country/foundedYear/level`. Falls back to
  `l10n.unnamedClub` when `name` is empty; every other field is
  conditionally included via `if (...)` — confirmed no invented/fallback
  data anywhere in this widget.
- **Dashboard statistics**: `GET /club-players/summary` computes
  `totalPlayers`, `completeProfiles`, `incompleteProfiles`,
  `averageCompletionPercent`, `topMissingFields` server-side from the
  club's own roster (`ownershipsForClub` → `findManyByUserIds`). The 4th
  tile, Saved Players, reads the already-loaded
  `savedPlayersControllerProvider` list length client-side — **confirmed
  this adds zero extra API calls** (no new endpoint, no new request; the
  provider is already fetched for other screens and Riverpod caches it).
- **Roster profile health**: `averageCompletionPercent` and
  `topMissingFields` are computed via `completionPercentFor()` /
  `missingFieldsFor()` in `players.mapper.ts` — the **same** functions
  `GET /players/me/stats` (the Player's own completion card) calls.
  Verified there is exactly one `COMPLETION_CHECKS` table in the codebase;
  no duplicate/competing completeness logic exists anywhere in Club
  Experience 2.0.
- **Quick Actions**: Add Player (primary), My Players / Find Players
  (secondary), Saved Players / Edit Club Profile (tertiary) — 5 actions,
  5 distinct routes (`/club/players/new`, `/club/players`, `/search`,
  `/saved-players`, `/club/edit`), each with icon + title + description.
  No duplicates.
- **Navigation**: Desktop sidebar (`_clubNavItems` in `app_shell.dart`) —
  Dashboard → My Players → Add Player → Find Players → Saved Players →
  Community → Club Profile → Edit Club Profile → Settings. Mobile bottom
  nav — Home → My Players → Find Players → Saved Players → Community →
  Settings. **Confirmed Community sits after every core Club workflow
  item on both platforms** — matches the brief's explicit requirement.
  Player/Admin sidebars are a separate, untouched list (`_navItems`); no
  route appears twice across the two lists, no dead nav items found.

**Findings:** none blocking. See §7 for one dense-desktop-table note
(Phase 2, not Phase 1) and §6 for one performance note.

---

## 3. Phase 2 Audit — Player Management & Add Player

**Status: PASS**

- **Desktop roster table** (`ClubPlayersRosterTable`): Player / Sport /
  Position / Profile-completeness / Phone / Actions, hover state via
  `MouseRegion`, every text cell has `overflow: TextOverflow.ellipsis`.
  Columns are `Expanded(flex: …)` + one fixed 132px actions column — no
  fixed-width columns that could force a hard overflow.
- **Mobile roster cards** (`ClubManagedPlayerCard`): confirmed a
  genuinely different widget tree, not the desktop table reused/scaled —
  photo, name, sport·position, phone, completeness chip, overflow menu.
- **Search / pagination / filters**: `GET /club-players` takes
  `page`/`search`/`sport`/`position`, server-side, page size fixed at 20
  (`CLUB_ROSTER_PAGE_SIZE`, not client-controlled). Search matches
  `firstName`/`lastName`/`contact.phone` via a regex-escaped `$or`,
  always pre-scoped to `userId: { $in: <this club's ids> }`.
- **View / Edit / Remove / WhatsApp**: all four wired through
  `ClubPlayersController`/`ClubPlayersRosterTable`/`ClubManagedPlayerCard`,
  each action ultimately calling a service method that runs
  `requireOwnership()` first (see §5).
- **Add Player wizard**: confirmed 4 real steps in
  `add_club_player_form.dart` — Basic Information → Sports Information →
  Contact → Review/Create. `widget.isDesktop` (a required constructor
  param, not internal `MediaQuery`) selects between a horizontal
  numbered-circle header (Desktop) and a "Step X of N" + progress bar
  (Mobile) — confirmed both page files pass different literal values
  (`isDesktop: true` / `isDesktop: false`). Per-step `GlobalKey<FormState>`
  validation on Basic Info and Contact; Back never re-validates. Optional
  fields (DOB, nationality, email, sport/position/foot/height/weight/bio)
  correctly omit themselves from the request when empty
  (`createClubPlayerInputToJson`'s `?field` null-aware entries).
- **Credentials + WhatsApp**: unchanged flow — `AlertDialog` with
  username/password + `SendCredentialsWhatsAppButton`, confirmed still
  wired at the end of `_submit()`.
- **The `email: null` fix**: verified present in
  `users.service.ts::createClubManagedPlayer` — the `email` key is now
  spread in conditionally (`...(input.email ? { email: input.email } : {})`)
  instead of always being passed (even as `undefined`). Two tests exist
  and pass: `users.service.spec.ts` — *"omits the email key entirely when
  none is given, instead of inserting an explicit null"* and *"includes
  the email when one is given"*. The pre-existing duplicate-phone and
  duplicate-email checks (lines 81–96) are untouched, so **email
  uniqueness still works correctly** for players that do provide one.

**Findings:** none blocking. See §7 for the desktop-table density note.

---

## 4. Phase 3 Audit — Player Discovery

**Status: PASS**

- **Name search**: `SearchPlayersDto.search` → `PlayersService.search()`
  builds `{ $or: [{ firstName: regex }, { lastName: regex }] }` via the
  same `escapeRegex()` helper `findManyByUserIdsFiltered` already used —
  confirmed regex-escaped (a search string like `a.*` or `(` is treated
  literally, not as regex syntax). Deliberately excludes `phone` (private
  data) on this public endpoint, unlike the authenticated club-roster
  search.
- **Debounce**: confirmed 400ms in both `PlayerSearchBox`
  (`Duration(milliseconds: 400)`) and `ClubPlayersToolbar` — consistent
  pattern across the app, not a new one-off.
- **Server-side filtering / pagination**: all 8 filters (search, country,
  minAge/maxAge, position, minHeight/maxHeight, weight, preferredFoot,
  sport) are DTO fields validated with `class-validator`
  (`@IsInt`/`@Min(0)`/`@IsEnum` etc.) — an invalid value (e.g.
  non-numeric `minAge`) is rejected by NestJS's `ValidationPipe` before
  reaching the query, not silently ignored or crashing the service. Page
  size fixed at `SEARCH_PAGE_SIZE = 20`, server-side only.
- **Pagination boundaries**: both `SearchPagination` and
  `ClubPlayersPagination` compute `lastPage` the same way
  (`((total - 1) / pageSize).floor() + 1`) and correctly disable
  Prev at `page == 1` and Next when `!hasNextPage` — no off-by-one, no
  dead button state observed.
- **Result count**: `l10n.searchResultsCountLabel(page.total)` sourced
  from the same `page.total` the pagination widget reads — no extra
  request.
- **Player result cards** (`toSearchResultView` / `PlayerSearchResult`):
  confirmed the shape is `id, firstName, lastName, age, country, sport,
  position, preferredFoot, height, weight, profilePhotoUrl` — **no
  `contact` field anywhere in this type**, both in the backend mapper and
  the frontend entity. Actions are View (`context.push('/players/:id')`)
  and Save/Unsave (`toggleSavedPlayer`) — no third action, no duplicate.
- **Saved Players**: single system — `SavedPlayer` (Mongoose schema,
  `savedplayers` collection) is the only saved/shortlist concept in the
  codebase; "Saved Players" and "Shortlist" are UI wording choices over
  the same backend model, not two competing implementations. Duplicate-
  save is prevented at the **database level**
  (`SavedPlayerSchema.index({ clubUserId: 1, playerId: 1 }, { unique:
  true })`), and the service catches the resulting Mongo duplicate-key
  error and turns it into a friendly `ConflictException` rather than a
  raw 500. `SavedPlayersController` scopes every query to
  `user.sub` (the JWT's own subject) — a club can only list/unsave its
  own saved rows.
- **Contact privacy**: `GET /players/:id/contact` requires
  `JwtAuthGuard` + `RolesGuard` + `@Roles(UserRole.CLUB)`, and internally
  calls `findPublicByIdOrThrow` — which 404s if the profile isn't
  `PUBLIC` visibility, so even an authenticated Club cannot fetch contact
  info for a private profile by guessing an id. The public
  `GET /players/:id` uses `toPublicView` → `baseView()`, which **does
  not include `contact` at all** — confirmed by reading the mapper
  function body, not inferred from a comment. `toSearchResultView` (used
  by both search results and the Saved Players list) also excludes
  `contact`. No leak path found.

**Findings:** two Medium (§5/§6), see below.

---

## 5. Security

| Severity | Finding |
|---|---|
| Critical | None found. |
| High | None found. |
| Medium | None found. |
| Low | None found. |

Specifically verified, with the exact code checked:

- **Club A cannot view/edit/remove Club B's players, or resend their
  credentials** — every mutating method in `ClubPlayersService`
  (`getOneForClub`, `updatePlayer`, `uploadPhoto`, `removeFromClub`,
  `resendCredentials`) calls `requireOwnership(clubId, userId)` first,
  which does `clubManagedPlayerModel.findOne({ clubId, userId })` and
  throws `ForbiddenException` if nothing matches. `clubId` is always
  `user.sub` from the verified JWT (`@CurrentUser()`), **never** taken
  from the request body or a route param — a Club cannot claim to be a
  different club. Confirmed by test: *"blocks a club from managing a
  player it does not own"*, *"blocks removing a player another club
  owns"* (`club-players.service.spec.ts`).
- **Players cannot access Club management endpoints; unauthenticated
  users cannot either** — `ClubPlayersController` has a class-level
  `@UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CLUB)`; every
  route on it inherits this, none has a guard override.
- **Public visitors never receive private contact info** — verified
  `toPublicView`/`baseView()` excludes `contact`; `GET /players/:id/contact`
  requires an authenticated Club JWT.
- **No IDOR on the Saved Players list** — `SavedPlayersController`'s
  every route scopes by `user.sub`, not a client-supplied id.
- **No secrets, `.env`, or generated build artifacts in the three Club
  Experience commits** — confirmed via `git show --stat` on each of the
  three commit hashes (see §14).

---

## 6. Performance

- **No unnecessary roster reloads found.** `SavedPlayersController`
  (frontend) does one fetch on `build()`, then patches its in-memory list
  on every save/unsave — confirmed no refetch call anywhere in `save()`/
  `unsave()`. `ClubPlayersActions` (a plain, non-`AsyncNotifier` provider)
  is what Add Player and Edit Player call — confirmed
  `add_club_player_form.dart` uses `ref.read(clubPlayersActionsProvider)`,
  **not** `clubPlayersControllerProvider.notifier` (reading an
  `AsyncNotifier`'s `.notifier` always runs its `build()` first — this
  was a documented pre-Club-Experience-2.0 fix, and it was **not**
  regressed by the Phase 2 wizard rewrite).
- **No client-side filtering of large datasets** — every list (roster,
  search results, saved players via its own paginated-looking-but-
  intentionally-full list) is either server-paginated or, for Saved
  Players, a genuinely small collection by nature (a shortlist), matching
  the code's own stated design rationale.
- **Medium — `GET /club-players/summary` loads the full roster into
  memory.** `getSummaryForClub` deliberately isn't paginated (documented
  in its own comment: "it needs to look at every managed player once to
  count completeness"), and the **response** sent to the client is always
  small (3 numbers + up to 5 players). But the **query** itself pulls
  every one of the club's `PlayerProfile` documents server-side to
  compute the aggregate. At current expected scale (a club managing tens
  to low-hundreds of players) this is a non-issue; if a club's roster
  ever reaches the thousands, this endpoint's server-side memory/CPU cost
  will grow linearly with roster size even though the network response
  doesn't. Not a regression — this trade-off was made deliberately and
  documented — but worth flagging as a scale watch-item.
- **Medium — name search has no supporting index.** See §10.
- No unbounded API responses found — every list endpoint touched by Club
  Experience 2.0 has a fixed, server-side page size (20).
- No duplicate/repeated provider invalidation found in the audited
  controllers.

---

## 7. Architecture

- **No cross-imports between `presentation/desktop` and
  `presentation/mobile`** in any of `club_players`, `dashboard`, `search`,
  or `saved_players` — confirmed via `grep` for
  `import.*presentation/(desktop|mobile)` across all four feature
  directories in both directions: zero matches.
- **No `MediaQuery`/`AppBreakpoints` branching inside shared widgets** —
  the only occurrence found in the audited code is a doc-comment in
  `add_club_player_form.dart` explicitly stating the widget does *not*
  do this, and the actual code confirms it: `isDesktop` is a required
  constructor parameter supplied by the (already breakpoint-aware) caller.
- **Domain/data/application layers are genuinely shared**, platform-
  specific pages own their own layout — matches the intended pattern.
  `ClubDashboardIdentityHeader`, `ClubDashboardCompletenessCard`, and
  `ClubPlayerCompletenessChip` are small shared UI atoms reused by both
  platforms with a size/layout parameter (`logoSize`, etc.) — acceptable
  per the audit's own stated allowance for "small UI atoms."

**Findings:** none.

---

## 8. Desktop / Mobile

- Add Player: genuinely different step-indicator chrome (horizontal
  circles vs. "Step X of N" + progress bar) and button layout
  (right-aligned row vs. full-width stacked) — confirmed in code, not
  just in the phase docs' prose.
- Roster: real `DataTable`-style table vs. real cards — confirmed two
  separate widget files, no shared "one card list at two widths."
- **Low — Desktop roster table is visually dense at the exact 900px
  breakpoint floor.** With the sidebar (240px) and page padding
  subtracted, the table's 5 `Expanded` columns share roughly 500–600px
  at the minimum desktop width. Not a rendering bug — `Expanded` cannot
  overflow, and every cell has `TextOverflow.ellipsis` — but a club
  running the app in a narrow desktop/tablet-landscape window sitting
  right at the breakpoint will see noticeably truncated Sport/Position/
  Phone columns. Cosmetic, not a defect.

---

## 9. Localization / RTL

- Searched every file under `club_players`, `dashboard`, `search`, and
  `saved_players` for `Text('literal')`/`Text("literal")` with a Latin
  first character: **zero matches**. Same for hardcoded
  `tooltip:`/`labelText:`/`hintText:` string literals: **zero matches**.
  Every user-facing string in the audited code goes through
  `AppLocalizations`.
- Spot-verified the two documented fixes are actually in place (not just
  claimed): `SearchPagination` uses `l10n.pageOfPagesLabel(...)` (not a
  hardcoded `'Page $x of $y'`), and the Mobile Find Players filter
  tooltip uses `l10n.filtersTooltip` (not a hardcoded `'Filters'`).
- RTL: `Icons.chevron_left`/`chevron_right` used in both pagination
  widgets rely on Flutter's built-in `matchTextDirection` auto-mirroring
  (documented in a code comment at each call site) rather than manual
  direction checks — consistent, low-risk approach. The roster table's
  completeness chip uses `AlignmentDirectional.centerStart` (logical,
  RTL-safe) rather than a hardcoded `Alignment.centerLeft`.
- No mixed-language string concatenation found in the audited files.

**Findings:** none.

---

## 10. Backend / Database

- **Indexes reviewed against actual query patterns:**
  - `PlayerProfile`: `dateOfBirth`, `preferredFoot`, `height`, `weight`,
    `visibility` each single-field indexed; a compound
    `{ sport: 1, position: 1, country: 1 }` index for the common filter
    combination. **Medium — no index supports the new `search`
    (firstName/lastName regex) filter added in Phase 3**, nor the
    pre-existing `findManyByUserIdsFiltered` name/phone search used by
    the Club roster. A case-insensitive, unanchored `$regex` cannot use a
    standard B-tree index regardless — this would need a text index
    (`$text`) or a collation-aware prefix strategy to actually be
    indexed, and there isn't one. Every name search currently performs a
    full collection scan (bounded by `visibility: PUBLIC` or
    `userId: $in [...]` first, so it's not scanning the *entire*
    collection unfiltered, but within that filtered set there is no
    index assist for the name match itself). Not urgent at current data
    volume; worth planning for before the players collection grows large.
  - `ClubManagedPlayer`: **Low — redundant index.** `userId` has its own
    `unique: true` (a player can be managed by at most one club, ever —
    confirmed by the schema's own doc comment), *and* there's a second
    compound unique index on `{ clubId: 1, userId: 1 }`. Since `userId`
    alone is already globally unique, the compound index can never
    reject anything the single-field index wouldn't already reject —
    it's pure duplicate write overhead, not a correctness issue. This
    predates Club Experience 2.0 (from the earlier "Phase Club 2" work)
    and was not introduced or touched by these three phases.
  - `SavedPlayer`: correctly indexed — compound unique
    `{ clubUserId: 1, playerId: 1 }` (duplicate-save prevention) with
    `clubUserId` as the leading field (covers the list query), plus a
    standalone `playerId` index for reverse lookups. No issues.
- **Regex escaping**: verified both `players.service.ts::search()` and
  `players.service.ts::findManyByUserIdsFiltered()` route user input
  through the same `escapeRegex()` function before building a `$regex`
  filter. No unescaped user input reaches a MongoDB query anywhere in the
  audited code.
- **Null/optional field handling**: the `email: null` bug (§3) is fixed
  and tested. No other similarly-shaped optional-field-into-unique-index
  pattern was found in the audited schemas.
- **Validation**: `SearchPlayersDto`, `CreateClubPlayerDto`,
  `ListClubPlayersDto` all use `class-validator` decorators
  (`@IsOptional`, `@IsInt`, `@Min`, `@IsEnum`, `@Type(() => Number)`) —
  malformed query params are rejected by the global `ValidationPipe`
  before reaching a service method, not silently coerced or crashing.
- **Error handling**: ownership violations → `ForbiddenException` (403);
  missing resources → `NotFoundException` (404); duplicate saves →
  `ConflictException` (409). Consistent, semantically correct HTTP status
  usage throughout the audited controllers.

---

## 11. Tests

Exact results from this audit's own run (not copied from prior reports):

```
Backend — npm run build:        clean, no errors
Backend — npm run lint:         1 error, 1 file
  G:\sport x hub\backend\src\videos\videos.service.ts:25
  'VideoCommentDocument' is defined but never used
  (pre-existing — this file is untouched by any of the 3 Club
  Experience 2.0 commits; confirmed via `git show --stat` on all three)

Backend — npm test:             58/58 passing, 10 suites, 0 failed
  PASS src/health/health.service.spec.ts
  PASS src/auth/guards/roles.guard.spec.ts
  PASS src/videos/videos.service.spec.ts
  PASS src/players/players.service.spec.ts
  PASS src/auth/strategies/jwt.strategy.spec.ts
  PASS src/saved-players/saved-players.service.spec.ts
  PASS src/players/players.mapper.spec.ts
  PASS src/users/users.service.spec.ts
  PASS src/auth/auth.service.spec.ts
  PASS src/club-players/club-players.service.spec.ts

Frontend — flutter analyze:     No issues found

Frontend — flutter test:        9/9 passing, 0 failed
  (test/features/player/player_profile_redesign_test.dart, all 9 cases)
```

No test failed. Nothing to report per-test-failure (the report format
asks for test name / failure / likely cause / severity only if a test
fails — none did).

**Medium — test-coverage gap, not a failure**: `players.service.spec.ts`
exists and has 20+ passing tests, but **none of them exercise
`search()`** — not the new `search` (name) filter added in Phase 3, nor
any of the 7 filters (country/age/position/height/weight/foot/sport) that
predate it. This is a public, unauthenticated, filter-heavy endpoint with
zero automated regression coverage. It was manually, live-verified
working in Phase 3 (see `docs/CLUB_EXPERIENCE_2_PHASE_3.md` §8), but
manual verification isn't a substitute for a regression safety net.

---

## 12. MVP Scope

Searched every file under `club_players`, `dashboard`, `search`, and
`saved_players` (frontend) plus `club-players` (backend) for AI,
analytics, payments, contracts, trials, chat, notifications, multi-staff/
club-permissions, and agent/scout-account terminology, using
word-boundary-anchored patterns to avoid false positives from substrings
(e.g. "email"/"remain" containing "ai").

| Feature | Status |
|---|---|
| AI / AI recommendations | Not implemented — no matches. |
| Analytics | Not implemented — no matches. |
| Contracts | Not implemented — no matches. |
| Trials | Not implemented — no matches. |
| Payments | Not implemented — no matches. |
| Chat | Not implemented — the only `chat`-adjacent code is
`Icons.chat_outlined` used as the WhatsApp icon glyph and
`resendCredentialsAndOpenWhatsApp`, which is the pre-existing WhatsApp
deep-link flow, not an in-app chat feature. |
| Notifications | Not implemented — no matches. |
| Multiple Club staff / permissions | Not implemented — no matches. |
| Agent accounts | Not implemented — no matches. |
| Scout accounts | Not implemented — no matches. |

**Findings:** none. The implementation stays within the stated MVP
boundary.

---

## 13. Documentation

`docs/CLUB_EXPERIENCE_2_PHASE_1.md`, `_PHASE_2.md`, `_PHASE_3.md` all
exist. Spot-checked their claims against the actual code (not just
trusted at face value):

- Phase 1's identity-header, stat-tile, and navigation-reorder claims —
  **match the code.**
- Phase 2's 4-step wizard and `email: null` fix claims — **match the
  code**, including the exact fix mechanism described.
- Phase 3's search/localization/pagination-fix claims — **match the
  code.**
- **Discrepancy found**: Phase 3's `docs/CLUB_EXPERIENCE_2_PHASE_3.md` §9
  states *"no spec file previously existed for `players.service.ts`
  covering `search()`"*. This is imprecise — `players.service.spec.ts`
  **does** exist, with 20+ passing tests for other `PlayersService`
  methods; it simply has no test for `search()` specifically (confirmed
  in §11 above). The practical conclusion in that doc (no automated
  coverage for the search filters) is still correct — only the stated
  reason ("no spec file existed") is wrong. Per this audit's
  instructions, this is reported, not corrected.

No other discrepancies found between the phase docs and the actual
implementation.

---

## 14. Git Integrity

```
d08aaff (HEAD -> main, origin/main) Club Experience 2.0 — Phase 3
99f6288 Club Experience 2.0 — Phase 2
b0a6c29 Club Experience 2.0 — Phase 1
4c90a43 Fix Club Dashboard recent players and desktop roster table  <- prior work, untouched
```

- Local `main` matches `origin/main` exactly — all three commits are
  pushed, no follow-up commits exist on top of Phase 3.
- **Confirmed via `git show --stat` on all three commit hashes**: every
  file in every commit belongs to Club Experience 2.0 (frontend
  `club_players`/`dashboard`/`search`/`saved_players`/`player` feature
  files, `app_shell.dart`, backend `players`/`club-players`/`users`
  files, ARB/generated-l10n files, and one new `docs/` file per phase).
  **No unrelated WIP file entered any of the three commits.**
- **No secrets, `.env` files, or build artifacts** in any of the three
  commits.
- Commit boundaries are sensible: each commit is exactly one phase's
  diff plus that phase's own doc file, nothing bled across phase
  boundaries.
- **Unrelated uncommitted WIP still sitting in the working tree**
  (present before Club Experience 2.0 started, not created by it, not
  staged or touched by any of the three commits):
  - `backend/src/database/seed.ts` — skill-category list changes.
  - `backend/src/users/schemas/user.schema.ts`,
    `backend/src/videos/dto/upload-video.dto.ts`,
    `backend/src/videos/schemas/video.schema.ts`,
    `backend/src/videos/videos.controller.ts`,
    `backend/src/videos/videos.module.ts`,
    `backend/src/videos/videos.service.spec.ts` — mostly formatting-only
    diffs (multi-line `@Prop()` decorators, import wrapping), no logic
    change observed.
  - `frontend/lib/features/auth/application/session_controller.dart` —
    **contains active `print('DEBUG_RESTORE: …')` statements** inside
    `restore()`, the session-restoration path every authenticated user's
    app launch runs through. This is out of Club Experience 2.0's scope
    (not part of any of the three commits, not touched by this audit's
    remit), but it is live in the same working tree and worth a note:
    debug console output left in an auth code path is a minor hygiene
    issue independent of this release.
  - `backend/src/club-players/dto/list-club-players.dto.ts`,
    `backend/src/clubs/club-level.enum.ts`,
    `backend/src/clubs/dto/update-club-profile.dto.ts` — line-ending
    (CRLF/LF) noise only, confirmed via `git diff --stat` showing 0
    insertions/deletions for these three files.

None of the above was modified, staged, or committed during this audit,
per the audit's constraints.

---

## 15. Recommended Fixes

**P0 — blocking:** none.

**P1 — important:**
1. Add automated test coverage for `PlayersService.search()` — at
   minimum, the new name-search `$or` behavior and one or two of the
   pre-existing filters, since this is a public, unauthenticated,
   multi-parameter endpoint with zero regression coverage today.
2. Add an index strategy for name search (either a MongoDB text index on
   `firstName`/`lastName`, or accept the current full-scan behavior with
   a documented data-volume ceiling) before the players collection grows
   large enough for it to matter in production.

**P1 — hygiene (not code, but flagged since it's live in the same repo):**
3. Remove the `DEBUG_RESTORE` `print()` statements from
   `session_controller.dart` before that file's WIP work is committed —
   out of Club Experience 2.0's scope, but it's in the session-restore
   path every user hits on launch.

**P2 — nice to have:**
4. Drop the redundant compound `{ clubId, userId }` unique index on
   `ClubManagedPlayer` (the standalone `userId` unique index already
   enforces the same constraint) — minor write-overhead cleanup, no
   functional change. Pre-dates Club Experience 2.0.
5. Revisit `GET /club-players/summary`'s full-roster load if/when a
   club's managed-player count grows into the thousands — currently a
   deliberate, documented, and reasonable trade-off at expected MVP
   scale.
6. Correct Phase 3's documentation wording in §9 (the "no spec file
   existed" statement) to say "no coverage for `search()` existed" — a
   one-line accuracy fix, not a scope or behavior issue.
7. Consider a denser-safe layout tweak for the Desktop roster table at
   exactly the 900px breakpoint floor (e.g. hiding the Phone column below
   a slightly higher width) — cosmetic only.

No new features are recommended. Every item above fixes or clarifies
something already built; none of them expands scope.

---

## 16. Final Verdict

**READY WITH MINOR ISSUES**

The three Club Experience 2.0 phases are complete, secure, and internally
consistent. Ownership enforcement, contact-privacy boundaries, and MVP
scope discipline all held up under independent code inspection — nothing
found here contradicts what the three phase docs claimed. The two Medium
findings (missing search index, missing search test coverage) are real
gaps worth closing before the feature sees significant production
traffic, but neither one is a correctness bug, a security hole, or a
user-facing regression today. Safe to build Phase 4+ on top of the
current state; the P1 items above are worth scheduling alongside whatever
comes next, not before it.
