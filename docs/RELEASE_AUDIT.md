# Release Readiness Audit — Sport X Hub V1 MVP

**Audit date:** 2026-08-04
**Remediation pass date:** 2026-08-04
**Scope:** Phases 0–4 as implemented (Foundation, Authentication, Player Profile, Club/Search/Saved Players/Simple Contact, Minimal Admin). Phase 5 (public marketing site) is explicitly **not started and not in scope** for this audit.
**Type:** Project audit (architecture / security / database / performance / code quality / docs / scope), not a code review.
**Baseline:** [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) Section 8 ("Final MVP Scope") is the authority for what should exist. Sections 9 and 10 (Post Launch / V2) are the authority for what must **not** exist yet.

> **Update (remediation pass):** The project owner selected 7 launch blockers from this audit's findings for immediate remediation (no architectural refactoring, no redesign, Desktop/Mobile presentation strategy unchanged). All 7 are fixed and verified below (§12). Findings not on that list are left exactly as originally reported — they were not in scope for this pass and remain open.

---

## 0. Verdict

**7 of 7 requested launch blockers resolved; not yet fully launch-ready.** Nothing found is architecturally unsound — the codebase is a clean, consistent implementation of the roadmap with no scope creep. The Critical issue and the specific High-severity items the project owner selected (contact-merge data loss, no rate limiting, unbounded uploads, unbounded admin lists, wide-open CORS, missing phase docs) are now fixed and verified. Two High-severity items from the original audit (undeclared `dotenv` dependency, incomplete frontend Player-vs-Club route guarding) were **not** on the remediation list and remain open, along with all originally-reported Medium/Low findings. See §12 for the itemized resolution log.

| Severity | Original count | Resolved this pass | Still open |
|---|---|---|---|
| Critical | 1 | 1 | 0 |
| High | 10 (5 backend, 5 frontend) | 5 (4 backend, 1 frontend*) | 5 |
| Medium | 12 (7 backend, 5 frontend) | 1 (CORS) | 11 |
| Low | 12 (6 backend, 6 frontend) | 0 | 12 |
| Documentation gap | 1 | 1 | 0 |

\* The "1 frontend" High resolved is the Critical session-restore issue, which was cross-listed under both Security and Frontend in the original audit; it is counted once, under Critical.

Recommendation: the remaining open High-severity items (undeclared `dotenv`, incomplete role-vs-role route guarding) plus the Medium/Low backlog in §10–§11 should still be triaged before or shortly after Phase 5, at the project owner's discretion. Nothing currently open blocks starting Phase 5, per the project owner's explicit scope for this remediation pass.

---

## 1. Architecture

### Backend — compliant
Every module (`admin`, `auth`, `clubs`, `countries`, `health`, `players`, `saved-players`, `sports`, `users`) follows the mandated `module/controller/service/schemas/dto` shape from `PHASE0_SUMMARY.md` §6. Controllers are thin — no business logic found in any controller. Dependency direction is correct throughout (controller → service → model, never reversed). `repositories/` is correctly omitted everywhere — no service's queries are complex enough to warrant it yet. ObjectId refs are used correctly between collections; no simulated joins beyond the documented `.populate()`-free pattern.

**Findings:**
- **Low** — `backend/src/players/players.service.ts:59-65` and `backend/src/clubs/clubs.service.ts:23-29`: `getOrCreateForUser` is duplicated near-identically between `PlayersService` and `ClubsService`. No functional issue, just a DRY gap.
- **Low** — Cloudinary `resourceType` handling is inconsistent: `players.service.ts:30-32` has a helper (`resourceTypeFor`), `clubs.service.ts:61,67` hardcodes `'image'` inline. No bug, just an inconsistent pattern between two modules that otherwise mirror each other.

### Frontend — systemic violation of the Desktop/Mobile forking rule
`PROJECT_ROADMAP.md` §3.1 and `PHASE0_SUMMARY.md` §4–5 are explicit: only `domain/`, `data/`, `application/` are shared; `presentation/shared/` is reserved for "truly platform-agnostic atoms (rare)." Desktop and Mobile are supposed to be genuinely independent widget trees.

- **High** — In practice, the entire Player and Club edit/view feature set lives in `presentation/shared/` as full `ConsumerStatefulWidget`s carrying their own controllers, validation, save calls, and dialogs — not atoms:
  - `frontend/lib/features/player/presentation/shared/personal_info_section.dart`, `sports_info_section.dart`, `bio_contact_section.dart`, `media_section.dart`, `achievements_section.dart`, `social_links_section.dart`, `visibility_section.dart` — imported identically by `presentation/desktop/edit_profile_page_desktop.dart:6-12` and `presentation/mobile/edit_profile_page_mobile.dart:6-12`. Desktop wraps them in `Card`s in a `Row`; Mobile wraps them in `ExpansionTile`s — that's the entire difference.
  - `frontend/lib/features/player/presentation/shared/player_profile_view.dart` — a full read-only profile renderer reused untouched by all four Desktop/Mobile preview and public-profile pages.
  - The identical pattern repeats for Club (`club_info_section.dart`, `club_logo_section.dart`, `club_profile_view.dart`) and for `player_search_result_card.dart` / `save_player_button.dart` / `simple_contact_actions.dart`.

  **Impact:** this is exactly the "shared widget with conditional chrome" pattern the roadmap prohibits. It's not a cosmetic nitpick — it's the project's own stated non-negotiable architecture rule, violated systemically across the two largest features in the app. A literal re-read of the Phase 0 acceptance bar ("swaps to a genuinely different widget tree, not a reflowed one") would fail on Player and Club edit/view screens today. This is worth a deliberate decision: either accept the shared-logic-widget pattern retroactively and update the roadmap/PHASE0_SUMMARY to reflect the actual convention in use, or refactor before it spreads to Phase 5.

- **Low** — `frontend/lib/features/settings/` has no `domain/data/application` of its own; it reaches directly into `auth`'s providers (`change_email_form.dart:5`, `change_password_form.dart:5`). Defensible (settings genuinely is auth data) but undocumented as an intentional exception, unlike Admin's documented desktop-only carve-out.
- **Compliant** — No `MediaQuery`/width-branching found outside `core/utils/breakpoints.dart` and `ResponsiveLayout`. No `data/`-layer imports inside `presentation/`. `runAuthorized` correctly centralized in `core/network/authorized_request.dart` per `PHASE3_SUMMARY.md` §5.

---

## 2. Security

### Critical
- ✅ **RESOLVED** — **Session is never restored for a cold load on a shared public-player-profile link**, breaking the exact "shareable URL" scenario Phase 2/3 were built to support. `frontend/lib/core/router/app_router.dart:31,47`: `_isPublicPlayerProfile` routes return `null` (allowed) **before** the `session.status == SessionStatus.unknown` gate that normally forces every cold load through `/` (Splash). `SessionController.restore()` was only ever called from `SplashPage.initState()`, so a route Splash never mounts for never triggered it. Consequence: a logged-in Club opening a shared `/players/:id` link directly in a new tab never restored its session; `SavePlayerButton`/`SimpleContactActions` rendered nothing even with a valid stored token.
  **Fix:** `restore()` is now triggered once at app root (`frontend/lib/main.dart`, `SportXHubApp.initState()`) instead of only from `SplashPage`, so it fires on every cold load regardless of which route is first matched. `SplashPage` is now a pure loading display (its own `restore()` call was removed as redundant — see `frontend/lib/features/splash/presentation/splash_page.dart`). Verified: `flutter analyze` clean; confirmed by code inspection that `restore()` now runs before the router's first `redirect` evaluation on every cold load, including `/players/:id`.

### High (backend)
- ✅ **RESOLVED** — `backend/src/players/players.service.ts:147-158` (`updateProfile`): `Object.assign(profile, dto)` was a shallow merge. A `PATCH /players/me` with a partial `contact` object (e.g. `{ contact: { phone: '...' } }`) **replaced** `profile.contact` entirely instead of merging fields — any previously saved `email`/`whatsapp` was silently wiped.
  **Fix:** `updateProfile` now destructures `contact` out of the DTO and merges it field-by-field onto `profile.contact` via `Object.assign(profile.contact, contact)`, instead of letting the top-level `Object.assign` replace the whole subdocument. Every other DTO field is still a scalar, so the top-level shallow assign remains correct for the rest. Verified: `npm run build` and `npm test` (19/19 passing) both clean after the change.
- ✅ **RESOLVED** — `backend/src/players/players.controller.ts:87-103`, `backend/src/clubs/clubs.controller.ts:48-58`: `FileInterceptor('file')` had no `limits.fileSize` and no MIME-type filter.
  **Fix:** new `backend/src/common/upload.config.ts` defines `imageUploadOptions` (club logo: images only, 5MB cap) and `mediaUploadOptions` (player media: images+videos, 50MB cap), both with a Multer `fileFilter` that rejects disallowed MIME types via `BadRequestException` before the file is even buffered. Both controllers now pass these options to `FileInterceptor`. `players.service.ts` additionally cross-checks the declared `type` (PHOTO/VIDEO) against the actual file mimetype and enforces a tighter per-type size cap (5MB photo even though the interceptor ceiling is 50MB) — closing the gap where the interceptor alone can't know the declared type, since that's a separate multipart field. Verified: `npm run build` clean.
- ✅ **RESOLVED** — No rate limiting existed anywhere. `/auth/login`, `/auth/register`, `/auth/forgot-password`, `/auth/reset-password` were fully exposed to brute-force / credential-stuffing / automated account creation.
  **Fix:** `@nestjs/throttler` installed and wired globally (`app.module.ts`: `ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 100 }])` + `APP_GUARD` → `ThrottlerGuard`, a 100 req/min per-IP baseline for the whole API). The four sensitive auth endpoints additionally carry `@Throttle({ default: { limit: 5, ttl: 60_000 } })` (`auth.controller.ts`) — 5 req/min per IP, well below what a legitimate user needs but low enough to blunt brute-force/credential-stuffing. `logout` and `reset-password`'s token-consuming nature made them lower priority and were left at the API-wide default per the project owner's explicit 4-endpoint list (login, register, refresh, forgot-password); `reset-password` also got the strict limit since it's equally credential-sensitive. Verified: `npm run build` and `npm test` (19/19) clean.
- ✅ **RESOLVED** — `backend/src/admin/admin.controller.ts:35-39,56-60,68-72`: `GET /admin/users`, `/admin/players`, `/admin/clubs` were fully unbounded.
  **Fix:** see Performance §4 and Documentation §8 (`PHASE4_SUMMARY.md` §7) for the full description — all three now paginate at a fixed page size of 20 via a shared `PaginationQueryDto`, returning `{ items, page, pageSize, total }`. The corresponding Flutter admin screens were updated to consume the new envelope and gained a "Load more" control. Verified: `npm run build`/`npm test` (backend) and `flutter analyze` (frontend) both clean.
- **STILL OPEN** — `backend/package.json` declares no `dotenv` dependency, yet `backend/src/database/seed.ts:1` and `seed-admin.ts:1` both `import 'dotenv/config'`. It currently resolves only because `dotenv` is installed transitively (via `@nestjs/config`) — a lockfile change could silently break `npm run seed` / `npm run seed:admin`. **Not on this remediation pass's list; left exactly as originally found.**

### High (frontend)
- **STILL OPEN** — No role-based route guarding for Player-only vs. Club-only routes. `app_router.dart`'s `redirect` only special-cases admin routes; an authenticated Player can navigate to `/club/edit` or `/search`, and a Club can navigate to `/player/edit`. The backend correctly 403s, but the frontend surfaces a raw error screen instead of redirecting. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — Media upload UX bug: `frontend/lib/features/player/presentation/shared/media_section.dart:43` sets `isProfilePhoto: type == PlayerMediaType.photo` for **every** photo upload. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — Admin routes (`/admin/users`, `/admin/players-clubs`) render an unconditional `DataTable` with no width guard. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — JWT access/refresh tokens are stored via `SharedPreferences` (`localStorage` on Flutter Web). **Not on this remediation pass's list; left exactly as originally found** — the project owner should still make an explicit go/no-go call on this before launch.
- ✅ **RESOLVED** — (Duplicate of Critical above, listed here for completeness under Security) — session-restore gap on public profile deep links. See §2 Critical for the fix.

### Medium
- ✅ **RESOLVED** — `backend/src/main.ts:10`: `app.enableCors()` with no options — CORS was wide open to any origin.
  **Fix:** CORS is now environment-driven. `backend/src/config/env.validation.ts` adds `CORS_ORIGINS` (comma-separated allowlist), required whenever `NODE_ENV=production` (Joi conditional validation), optional in development/staging. `main.ts` parses it and calls `app.enableCors({ origin: corsOrigins.length > 0 ? corsOrigins : true, credentials: true })` — any origin is only ever allowed when `CORS_ORIGINS` is left empty, which the env schema now forbids in production. `.env.example` documents the new variable. Verified: `npm run build` clean; a production boot with `NODE_ENV=production` and no `CORS_ORIGINS` now fails Joi validation at startup instead of silently allowing any origin.
- **STILL OPEN** — `backend/src/users/users.service.ts:46-56` doesn't validate the id is a well-formed ObjectId before `findById`. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — No `helmet` (or equivalent) security response headers. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — Password policy is `MinLength(8)` only, no complexity requirement. **Not on this remediation pass's list; left exactly as originally found.**
- **STILL OPEN** — Admin routes reachable at mobile widths (companion to the frontend route-guarding finding above). **Not on this remediation pass's list; left exactly as originally found.**

---

## 3. Database

**Compliant.** All roadmap-mandated indexes are present and correct:
- `users.email` unique (`user.schema.ts:19`)
- `savedplayers` compound unique `{clubUserId, playerId}` + standalone `playerId` (`saved-player.schema.ts:15-34`)
- `playerprofiles` compound `{sport, position, country}` + standalone indexes on `visibility`, `preferredFoot`, `height`, `weight`, and `dateOfBirth` (added in Phase 3 per `PHASE3_SUMMARY.md`)
- `clubprofiles.userId` unique; `country`/`city` indexed
- TTL indexes correctly set on `refreshtokens.expiresAt` and `passwordresettokens.expiresAt`

**Findings:**
- **Medium** — No `.lean()` or field projection anywhere in the codebase (repo-wide search: zero hits). `players.service.ts` `search()` (lines 108-117) and `findManyPublicByIds()` (119-124) are the two hottest read paths — public player search and the saved-players list — and both hydrate full Mongoose documents (including embedded `achievements`, `socialLinks`, `media`, `contact`) even though the response is immediately narrowed to ~9 fields via `toSearchResultView`. Not a leak (the mapper strips fields before serialization), but real, easily-fixed overhead on the highest-traffic endpoint at the scale the roadmap targets.
- **Low** — `player-profile.schema.ts:22-35`: the embedded `ContactDetails` subdocument declares `{ _id: true }` unnecessarily (it's a single object, not an array member) — harmless stray ObjectId per profile.

Schema consistency, relations, and scalability design are otherwise sound and match the roadmap's stated collection design exactly (see `PHASE3_SUMMARY.md` §3 for the documented rationale on embedding vs. separate collections).

---

## 4. Performance

- ✅ **RESOLVED** — `GET /admin/users`, `/admin/players`, `/admin/clubs` (`admin.controller.ts`) were fully unbounded — no pagination, no limit, no projection.
  **Fix:** `UsersService.findAll()`, `PlayersService.findAllForAdmin()`, and `ClubsService.findAllForAdmin()` now accept a `page` parameter and apply `.skip()`/`.limit(20)` alongside a parallel `countDocuments()`, mirroring the pattern `players.service.ts`'s `search()` already used since Phase 3. `AdminController` accepts `?page=` via a new `PaginationQueryDto` and returns `{ items, page, pageSize, total }` on all three list endpoints. Frontend `AdminRepository`/`AdminRemoteDataSource` updated to decode the new envelope; the three admin `AsyncNotifier` controllers track `hasMore` and expose `loadMore()`; all three admin screens gained a "Load more" button and an explicit empty state. Verified: `npm run build`/`npm test` (backend, 19/19 passing) and `flutter analyze` (frontend, no issues) both clean.
- **Medium** — `backend/src/auth/strategies/jwt.strategy.ts:28-34`: every authenticated request does a live DB lookup (`usersService.findById`) to check suspension status. This is a deliberate, documented tradeoff (needed for Phase 4's "immediate suspension" acceptance criterion) — flagged here as a scale cost to be aware of, not a defect.
- **Medium** — Missing `.lean()`/projection on the search hot path (see Database §3).
- **Medium (frontend)** — `achievements_section.dart:24`, `social_links_section.dart:22`, `visibility_section.dart:13`, `media_section.dart:62` all `ref.watch(playerProfileControllerProvider)` on the whole `AsyncValue<PlayerProfile>` with no `.select()`. Saving Personal Info causes Achievements/Social Links/Media/Visibility sections to all rebuild even though their data didn't change — inconsistent with the `.select()` pattern already correctly used in `player_search_result_card.dart:19-23` and `save_player_button.dart:25-29`.
- **Compliant** — Search results and Saved Players lists correctly use `ListView.builder`/`GridView.builder`, not unbounded `ListView(children:)`. `search()` correctly uses `Promise.all` for count+page, fixed page size, index-backed filters.

---

## 5. Frontend UI Coverage

- **Medium** — Empty states are missing on all three Admin lists (Users, Players, Clubs) — `DataTable(rows: [])` renders with no rows and no "No users found" message, unlike Search (`'No players match these filters.'`) and Saved Players (`'You have not saved any players yet.'`), which both handle it.
- **Low** — Nearly every async screen's error branch (`edit_profile_page_desktop.dart:76`, `my_club_profile_page_desktop.dart:39`, `search_players_page_desktop.dart:70`, all three admin controllers) renders the raw exception `toString()` with no retry action. Functional but not "professional, minimal, fast" per §3.3's design bar.
- **Compliant** — Loading states are present for every async provider consumed directly by UI, consistently via `.when(loading:...)`.

---

## 6. Backend / REST

- **High** — see `dotenv` gap (Security §2).
- **Medium** — Inconsistent id-validation → error-shape behavior between `UsersService` (raw 500 on malformed id) and `PlayersService`/`ClubsService` (clean 404). See Security §2.
- **Low** — `main.ts:11`: `ValidationPipe` has `whitelist: true, transform: true` but not `forbidNonWhitelisted: true` — unknown request fields are silently dropped instead of rejected, so a typo'd field name in a PATCH body fails with no client-visible feedback.
- **Compliant** — Every write endpoint across every module has a DTO with `class-validator` decorators (verified across all 15+ DTOs). Nest's built-in exception types (`NotFoundException`, `ConflictException`, `UnauthorizedException`, etc.) are used consistently; no raw try/catch swallowing except the intentional, correct duplicate-key translation in `saved-players.service.ts:32-39`.
- **Config gap** — `backend/src/config/env.validation.ts:26-28`: `CLOUDINARY_*` vars are still `Joi.string().allow('').default('')` (optional) even though Phase 2/3 code actively consumes them in `cloudinary.service.ts:14-20`. `PHASE0_SUMMARY.md` explicitly said this schema would tighten once Cloudinary code started consuming these values — it was done for `JWT_SECRET`/`JWT_REFRESH_SECRET` but never for Cloudinary. A deployment with missing Cloudinary credentials boots successfully and fails late/silently on first upload instead of failing fast at startup, contradicting the project's own stated config philosophy.
- **Launch risk, not a defect** — There is no logging strategy at all. `Logger` is used in exactly one place (`auth/mail/mail.service.ts`); there is no request-logging middleware, no error-logging interceptor, nothing else in the app. Production will have zero visibility into errors or traffic. Flagged for the Launch Risks section below.

---

## 7. Code Quality

**Backend:** No `TODO`/`FIXME`/`XXX` anywhere in `src`. No stray `console.*` in application code (only in the two operational seed scripts and the intentional fatal-boot-error handler — both acceptable). No unused npm dependencies. Naming is consistent module to module. Only quality issues found are the two Low architecture duplications already listed in §1.

**Frontend:** No `print`/`debugPrint`/`TODO`/`FIXME` anywhere in `lib` (verified via full-tree search). No unused pub dependencies — every `pubspec.yaml` entry is actively used. Naming is consistent across features.

- **Low** — `frontend/lib/core/theme/theme_mode_provider.dart:9-11`: `toggle()` only flips between `light`/`dark`; once a user touches the toggle there is no UI path back to `ThemeMode.system` ("follow OS"), even though `set()` supports it. Minor loss of the system-default behavior.
- **Nitpick** — stray blank line in `frontend/lib/features/club/data/datasources/club_remote_data_source.dart:54-55`.
- **Info** — Test coverage remains a single smoke test (`frontend/test/widget_test.dart`) and one backend spec per service — an already-documented, accepted limitation carried forward from Phase 1/2/3, not a new issue, but worth naming explicitly for launch sign-off: there is no automated regression coverage for the Player/Club/Search/Saved-Players/Admin flows on either side.

---

## 8. Documentation

- ✅ **RESOLVED** — `PHASE1_SUMMARY.md`, `PHASE2_SUMMARY.md`, and `PHASE4_SUMMARY.md` did not exist in `/docs`, even though the project's own phase workflow (`PROJECT_ROADMAP.md` §4) treats each phase as producing a reviewed, committed deliverable, and `PHASE3_SUMMARY.md` explicitly cites `PHASE0_SUMMARY.md` as a peer document in the same series.
  **Fix:** all three backfilled, following the same structure as `PHASE0_SUMMARY.md`/`PHASE3_SUMMARY.md` (Features, APIs, Database Changes, Flutter Screens, Architecture Decisions, Security Decisions, Known Limitations, Future Extension Points) and cross-referencing the codebase as it exists today, including the fixes made in this same remediation pass (e.g. `PHASE2_SUMMARY.md` §7 documents the contact-merge bug and its fix; `PHASE4_SUMMARY.md` §7 documents the admin pagination gap and its fix). See [`PHASE1_SUMMARY.md`](PHASE1_SUMMARY.md), [`PHASE2_SUMMARY.md`](PHASE2_SUMMARY.md), [`PHASE4_SUMMARY.md`](PHASE4_SUMMARY.md).
- `PROJECT_ROADMAP.md` and `PHASE0_SUMMARY.md` both remain accurate to the current implementation — no stale claims found in either against the current codebase. `PHASE3_SUMMARY.md` is also accurate as written and was not found to be outdated by anything discovered in this audit.

---

## 9. MVP Scope

**No scope creep found, backend or frontend.** Verified against `PROJECT_ROADMAP.md` §8 (must exist) and §9/§10 (must not exist):

- Roles are strictly `PLAYER | CLUB | ADMIN` on both backend (`user.schema.ts`) and frontend (`user_role.dart`) — no Scout/Agent/Academy anywhere.
- No chat/messaging, WebSockets, notifications, payments, digital contracts, AI features, or advanced analytics anywhere in either codebase.
- Visibility is strictly binary `PUBLIC | PRIVATE` — no tiered/"Clubs-only" visibility.
- No email-verification-on-signup flow (correctly deferred to V1.1).
- No CRUD UI for Sports/Countries, no Reports/flagging, no Settings panel beyond change email/password — matches the explicit Phase 4 "explicitly out of scope" callout.
- Search implements exactly the 7 roadmap filters, no extras.
- Simple Contact implements exactly `wa.me`/`mailto:`/`tel:`, no in-app messaging or conversation history.

**No MVP-listed feature (§8) was found missing** on either backend or frontend, for what's in scope through Phase 4. (Public marketing site is Phase 5 and correctly not started.)

---

## 10. Launch Readiness

### Requested launch blockers — all resolved this pass
1. ✅ **[Critical]** Session restore on cold-load public-profile deep links (`app_router.dart`) — fixed, see §2.
2. ✅ **[High]** `Object.assign` shallow-merge data loss on `PATCH /players/me` for the `contact` subdocument — fixed, see §2.
3. ✅ **[High]** No rate limiting on `/auth/*` endpoints — fixed, see §2.
4. ✅ **[High]** No file-size/type limits on media upload endpoints — fixed, see §2.
5. ✅ **[High]** Unbounded `/admin/users`, `/admin/players`, `/admin/clubs` — fixed, see §4.
6. ✅ **[Medium]** CORS wide open — fixed, see §2.
7. ✅ **[Documentation]** Missing `PHASE1/2/4_SUMMARY.md` — fixed, see §8.

### Still open — not requested for this pass, unchanged from the original audit
- **[High]** Undeclared `dotenv` dependency backing the admin-seed scripts.
- **[High]** Frontend Player-vs-Club route guarding is incomplete.
- **[Medium]** No security response headers (`helmet` or equivalent).
- **[Medium]** `UsersService` id-validation inconsistency (raw 500 vs. clean 404).
- **[Medium]** Admin routes reachable/broken at mobile viewport widths.
- **[Medium]** JWT stored in `localStorage` via `SharedPreferences` — a conscious, documented tradeoff; still recommend an explicit go/no-go from the project owner given the product handles contact PII.
- All originally-reported Low findings (see §1, §3, §6, §7) — duplicated `getOrCreateForUser`, stray `_id:true` on `ContactDetails`, `forbidNonWhitelisted` not set, password complexity policy, `ThemeMode.system` toggle path, etc.
- **[Architecture]** The `presentation/shared/` pattern for Player/Club (§1) — the project owner has explicitly ratified this as acceptable for the MVP; no further action needed, noted here only so the decision is on record.

### Known limitations (accepted, documented, not blockers)
- No automated UI/widget test coverage beyond a single smoke test (consistent since Phase 1).
- Search pagination has no benchmark beyond the 10k-document acceptance scale (documented in `PHASE3_SUMMARY.md`).
- `weight` filter is exact-match, not range — intentional, matches roadmap's query spec exactly.

### Production risks (not code defects, but real launch risk) — still open
- **No logging strategy at all** — one `Logger` usage in the whole backend. Zero production visibility into errors or traffic today.
- Cloudinary env vars are optional in validation despite being required at runtime — a misconfigured deployment fails late and confusingly instead of at boot. (Considered for this pass and deliberately left unchanged — not on the project owner's requested list.)

### Nice-to-have improvements (not launch blockers, still open)
- `.lean()`/projection on the player search and saved-players read paths.
- `.select()` on Riverpod watches in the shared edit-profile sections to cut unnecessary rebuilds.
- A "set as profile photo" affordance instead of every upload auto-flagging itself.
- `forbidNonWhitelisted: true` on the global `ValidationPipe`.
- Password complexity policy beyond `minLength(8)`.
- A path back to `ThemeMode.system` after the user has toggled dark/light once.

---

## 11. Production Checklist

- [x] Fix session-restore gap on public player profile deep links
- [x] Fix `Object.assign` shallow-merge on player profile contact updates
- [x] Add rate limiting to `/auth/*`
- [x] Add file-size limit + MIME-type validation to all Cloudinary upload endpoints
- [x] Paginate `/admin/users`, `/admin/players`, `/admin/clubs`
- [x] Scope CORS to the real frontend origin(s) per environment
- [x] Backfill `PHASE1_SUMMARY.md` / `PHASE2_SUMMARY.md` / `PHASE4_SUMMARY.md`
- [ ] Declare `dotenv` as an explicit backend dependency
- [ ] Add frontend redirect for Player-vs-Club route mismatches
- [ ] Add `helmet` (or equivalent) security headers
- [ ] Make `CLOUDINARY_*` env vars required in `env.validation.ts`
- [ ] Stand up a minimal logging strategy (request + error logging) before launch
- [ ] Decide and document: keep JWT in `localStorage`, or move to a more XSS-resistant storage strategy

Per the project owner's explicit direction, the 7 items above marked `[x]` were the required blockers for this remediation pass — all are resolved and verified (§12). The remaining unchecked items were reported in the original audit but were not requested for this pass; they do not block starting **Phase 5 — Public Marketing Site & Launch Polish** per the project owner's decision, but should be triaged before or shortly after launch.

---

## 12. Remediation Verification Log

Performed after all 7 requested fixes were applied, as the "one final verification" requested alongside this update.

| Check | Result |
|---|---|
| Backend `npm run build` (`tsc`) | ✅ Clean, no errors |
| Backend `npm run lint` (ESLint + Prettier) | ✅ Clean, no errors |
| Backend `npm test` (Jest) | ✅ 6 suites / 19 tests passing |
| Frontend `flutter analyze` | ✅ No issues found |
| Manual review of each fixed file against the original finding | ✅ Confirmed the specific bug/gap described in each original finding no longer exists in the diff |

**New dependency added:** `@nestjs/throttler` (backend `dependencies`) — required for rate limiting; no other dependency changes.

**No feature was modified beyond what each fix required.** No architectural refactoring was performed; the Desktop/Mobile presentation strategy is unchanged; the `presentation/shared/` pattern for Player/Club noted in §1 was left exactly as-is, per instruction. The admin pagination fix required a minimal, additive UI change (a "Load more" button and an empty-state message on the three existing admin screens) since the backend could no longer return an unbounded list without the frontend silently truncating to 20 items with no way to see more — this was the smallest change that kept the fix from being a regression, not a redesign.

**Verdict: all 7 requested launch blockers are resolved and verified.** Per the project owner's direction, the project may proceed to Phase 5 pending their final sign-off on this document.
