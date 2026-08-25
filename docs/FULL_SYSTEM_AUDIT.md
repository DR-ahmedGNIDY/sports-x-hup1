# Sport X Hub — Full System Audit (Phase 0)

**Date:** 2026-08-25
**Scope:** Full repository — `backend/` (NestJS 11 + MongoDB/Mongoose), `frontend/` (Flutter/Riverpod/go_router), infrastructure and dependencies.
**Type:** Read-only inventory and audit. **No source code was modified in this phase.**
**Standards used as checklist:** OWASP Top 10:2025, OWASP ASVS 5.0.0, OWASP API Security Top 10:2023, MITRE CWE Top 25:2025, NIST SP 800-218 SSDF 1.1.

**Prior context:** This project already has an established audit/phase-doc history (`docs/PROJECT_ROADMAP.md`, `docs/RELEASE_AUDIT.md`, `docs/PHASE0_SUMMARY.md`–`PHASE5_SUMMARY.md`, `docs/CLUB_EXPERIENCE_2_*`, `docs/PHASE_CLUB_*`). This document is a new, independent full-system pass and does not assume those prior audits' findings were resolved — it re-examines the code directly.

> **Disclaimer:** This audit reflects the scope actually examined, the standards used, and the tests/tools that were run. It is not a certification of "100% secure" or "no vulnerabilities exist" — no audit can make that claim. Remaining risk, accepted risk, and unavailable tooling are called out explicitly where relevant.

---

## 1. Architecture Overview

### Backend — NestJS 11 / MongoDB (Mongoose 8) / TypeScript 5.6

15 feature modules under `backend/src/`: `admin`, `auth`, `cloudinary`, `club-players`, `clubs`, `common`, `config`, `contact`, `countries`, `database`, `health`, `players`, `posts`, `saved-players`, `sports`, `users`, `videos`.

Layering is thin but consistent: **Controller → Service → Mongoose Model**, with per-module `.mapper.ts` files handling entity→DTO shaping. There is no repository-abstraction layer, no domain layer, and no CQRS — this is a pragmatic, appropriately-sized architecture for the project's scale, not an anti-pattern to "fix."

Auth: JWT access tokens (15 min TTL) + opaque, HMAC-hashed, rotate-on-use refresh tokens (7 day TTL) stored in MongoDB (`RefreshToken` schema, TTL-indexed for auto-expiry). Role-based access via `@Roles()` + `RolesGuard`, applied per-controller/per-route. Ownership enforcement is done at the service layer, either implicitly (via `user.sub` scoping) or explicitly (`ClubManagedPlayer` ownership-join-table checks in `club-players`).

File uploads go through Multer (memory storage, no disk writes) directly into Cloudinary; no local filesystem storage of user-uploaded media exists.

### Frontend — Flutter Web/Android, Riverpod 2.6, go_router 17

`lib/core/` holds shared infrastructure (network client, session storage, router, theme, locale). `lib/features/*` follow a domain/data/application/presentation 4-layer convention, applied consistently across 12 of 15 feature folders (`community`, `dashboard`, `settings` are intentionally thinner composition layers).

State management is 100% Riverpod (`Notifier`/`AsyncNotifier`), no other state library present. Desktop vs. mobile is handled via **separate widget trees** (`presentation/desktop/` vs `presentation/mobile/`), gated by a single `ResponsiveLayout` breakpoint decision point — a deliberate, consistently-applied architectural rule, not ad-hoc `LayoutBuilder` usage.

Auth token storage uses `SharedPreferences` (not `flutter_secure_storage`) — a documented, deliberate MVP tradeoff (see §9, Finding F-06).

### Infrastructure

No CI/CD pipeline exists (no `.github/workflows`). Frontend ships via a multi-stage Docker build (Flutter build → nginx:alpine), with runtime config (`API_BASE_URL`, `APP_ENV` — both non-secret) injected at container start via `docker-entrypoint.sh` + `envsubst`. Backend has no Dockerfile in the inventory (deploy mechanism not confirmed in this pass — worth clarifying with the user whether Railway/Render/other PaaS auto-detects it).

---

## 2. Security Overview

**Overall assessment: notably strong security baseline for the areas most commonly broken in projects this size** — ownership/IDOR checks, refresh-token rotation, immediate suspension enforcement, regex-injection escaping, and mass-assignment protection via `ValidationPipe({whitelist:true})` are all correctly and consistently implemented. The real findings are narrower and lower-severity than the "assume broken" default (see §14 Production Blockers for the one item that actually blocks production readiness — the password-reset email being non-functional).

No secrets are committed to git (verified via `git ls-files` and full `git log --all` history check on both `.env` files). `npm audit` reports 0 vulnerabilities across 576 backend dependencies.

Full findings list is in §14/§15 tables below (also to be expanded into `docs/SECURITY_AUDIT.md` and `docs/API_SECURITY_MATRIX.md` in Phase 4/14, pending your approval to proceed).

---

## 3. Dependency Overview

**Backend** (`backend/package.json`): NestJS 11.x, Mongoose 8.9, `bcryptjs` 3.0.3, `@nestjs/throttler` 6.5, `class-validator`/`class-transformer`, `cloudinary` 2.10, `multer` 2.2, `passport-jwt` 4.0.1, Joi 17.13 (env validation only). `npm audit --json`: **0 vulnerabilities** (info/low/moderate/high/critical all 0) across 165 prod + 412 dev + 2 optional packages.

**Frontend** (`frontend/pubspec.yaml`): Flutter 3.44.1 / Dart 3.12.1 (project pins to `>=3.12.0 <4.0.0` to match the Docker build image, documented). `flutter_riverpod` 2.6.1 (latest 3.4.2 — major version behind), `go_router` 17.3.0 (latest 18.0.0, 17.5.0 available as non-breaking), `file_picker` 11.0.3 (latest 12.0.0), `video_player` 2.10.0/2.13.0 (minor behind). No `flutter_secure_storage` dependency present. No Dart/Flutter equivalent of `npm audit` was run (no such tool exists in the Flutter ecosystem) — staleness was checked via `flutter pub outdated`, not CVE scanning.

**Gap:** No automated dependency scanning (Dependabot, Snyk, etc.) is configured — there's no CI at all, so even `npm audit`/`flutter pub outdated` only run when a human remembers to run them manually.

---

## 4. Authentication Overview

Implemented in `backend/src/auth/` (`auth.service.ts`, `jwt.strategy.ts`, `mail/mail.service.ts`).

- **Login**: generic `"Invalid credentials."` error regardless of whether the email/username or password was wrong — no user-enumeration signal. Suspended (`status !== ACTIVE`) accounts are rejected at login.
- **Refresh**: opaque 96-hex-char token, stored only as an HMAC-SHA256 hash (keyed by `JWT_REFRESH_SECRET`), rotated (old token deleted) on every use. Suspension is re-checked on refresh too.
- **Suspension enforcement is immediate, not just at token-issuance time**: `JwtStrategy.validate()` re-fetches the live user from MongoDB on **every authenticated request** and rejects if `status !== ACTIVE` — meaning an admin suspending a user takes effect on that user's very next API call, not after a 15-minute token expiry window. This is a deliberate, well-executed design (explicitly commented in code as the intended behavior).
- **Password reset**: opaque 48-byte random token, HMAC-hashed at rest, 1-hour TTL, single-use, and successfully resetting a password invalidates **all** of that user's refresh tokens and other pending reset tokens (kills all sessions on password change — good practice).
- **JWT secrets**: `JWT_SECRET`/`JWT_REFRESH_SECRET` are `Joi.required().min(32)` — app fails to boot without them, no hardcoded fallback anywhere in the codebase (verified by full-tree search).
- **Password hashing**: bcrypt, 10 salt rounds, applied consistently across all account-creation/password-change code paths.
- **Critical functional gap**: `MailService.sendPasswordResetEmail` is a **stub**. No email provider (Nodemailer, SendGrid, etc.) is wired up. In production it logs a warning and sends nothing; in dev/staging it logs the raw reset token to console. **Users cannot self-service password resets in production today.** This is both a security finding (raw token logged outside production, including staging — CWE-532) and a production blocker (the feature silently does nothing).

---

## 5. Authorization Overview

Every controller was checked individually (not assumed-safe from `JwtAuthGuard` presence alone), per the audit brief's instruction.

- **Broken Function Level Authorization (API5)**: `AdminController` correctly stacks `JwtAuthGuard` + `RolesGuard` + `@Roles(ADMIN)` at the class level. `RegisterDto` restricts self-registration to `PLAYER`/`CLUB` only (`@IsIn`) — ADMIN accounts can only be created via the offline `seed-admin.ts` script, never through any API surface.
- **IDOR / Broken Object Level Authorization (API1)**: No confirmed IDOR was found. Ownership is enforced consistently:
  - `club-players` module: every per-player method (`getOneForClub`, `updatePlayer`, `uploadPhoto`, `removeFromClub`, `resendCredentials`) calls `requireOwnership(clubId, userId)`, verified against the `ClubManagedPlayer` join table before any read or write.
  - `videos`/`posts`: ownership checked inline (`resource.userId.toString() !== userId`) before update/delete; comment deletion allows author-or-ADMIN.
  - `users`, `players` (`me/*`), `clubs` (`me/*`), `saved-players`: all self-scoped via `user.sub` from the JWT, never a client-supplied ID.
- **Mass assignment**: no update DTO exposes `role`, `status`/`isSuspended`, `ownerId`, or `clubId`. Global `ValidationPipe({ whitelist: true, transform: true })` strips any unknown/extra body fields before they reach a DTO, providing defense-in-depth even if a DTO were ever mis-scoped.
- **Notable design decision, not a bug, but worth stakeholder confirmation**: `GET /players/:id/contact` is gated only by `@Roles(CLUB)` — **any** authenticated club (not specifically one that has saved/manages that player) can view any public player's phone/email/WhatsApp by ID, with no additional relationship check, rate limit, or audit log specific to this disclosure path. This may be intentional product behavior ("clubs can browse and contact any public player"), but it enables bulk contact-scraping by any single registered club account and should be explicitly confirmed as intended, per OWASP API3:2023 (Excessive Data Exposure).
- **Frontend**: route guards in `go_router` correctly gate `/admin/*` and `/club/players/*` by role, but this is explicitly understood in the codebase (via code comments) as UX-only — the backend is the actual authorization boundary in every case checked.

---

## 6. API Attack Surface

Full endpoint-by-endpoint matrix (auth/role/ownership/validation/rate-limit/upload columns) will be produced as `docs/API_SECURITY_MATRIX.md` in Phase 4, pending approval. Summary here:

- **Rate limiting**: global `@nestjs/throttler` default of 100 req/min per client, tightened to 5 req/min on `register`, `login`, `refresh`, `forgot-password`, `reset-password`, and `contact` submission. `logout` has no throttle (low risk — caller must already possess a valid token to have any effect).
- **Public/unauthenticated endpoints**: `health`, `sports`, `countries` (reference data), `contact` (throttled), `auth/*` (throttled), `players` search/public-detail (filtered to `visibility: PUBLIC`), `clubs` public listing/detail, `videos` player/traits by ID (filtered to public visibility).
- **CORS**: origin allowlist (`CORS_ORIGINS`) is required and enforced in production; in development/staging with the var unset, it falls back to reflecting any origin with `credentials: true` — flagged as Finding F-02 below since **staging** is included in the permissive branch, not just development.
- **No Helmet / security headers** applied anywhere (Finding F-01).

---

## 7. Database Risks

MongoDB via Mongoose. Indexing is generally well-thought-out: unique compound indexes prevent duplicate likes (`VideoLike`, `PhotoLike`), TTL indexes auto-expire refresh/reset tokens, and `SavedPlayer`/`ClubManagedPlayer` have appropriate unique constraints enforcing one club-player relationship per pair. Full query-by-query index analysis is deferred to Phase 2 (Database Security + Performance) per the requested phase order.

- **Regex search safety**: `PlayersService.search()` builds `$regex` filters from user input but escapes regex metacharacters first (`escapeRegex()`) — prevents both regex-injection and ReDoS via crafted patterns. No raw `req.query`/`req.body` was found spliced directly into any Mongo filter/aggregate anywhere in the codebase.
- **No NoSQL injection found** — no use of `$where`, no unsanitized operator injection surface identified.
- **Destructive script note**: `database/seed.ts` deletes sports/skill-categories not present in its hardcoded list on every run (`deleteMany({name:{$nin:SPORTS}})`) — intentional, but a reminder this script must never run unexpectedly against production data without review.
- **Cloudinary config not `.required()` in production Joi schema** — a misconfigured production deploy would boot successfully and only fail at first upload attempt rather than failing fast at startup (minor operational risk).

---

## 8. File Upload Risks (CWE-434)

- MIME allowlisting + size limits (5MB image / 50MB video) enforced via Multer `fileFilter`+`limits` in `common/upload.config.ts`, with a service-layer second check cross-validating declared media type vs. actual mimetype (players/videos modules) — good defense-in-depth.
- Filenames/public IDs are **Cloudinary-generated**, never derived from user input — no path traversal or filename-injection surface exists; the upload `folder` parameter is always server-constructed (e.g. `sportxhub/players/${userId}`), never user-supplied.
- **Known, self-documented weak point**: MIME validation is based on the client-supplied `Content-Type` header (`file.mimetype`), not magic-byte/content-sniffing. No `file-type`-style library is used anywhere. A malicious client can lie about mimetype; Cloudinary itself provides a secondary backstop by generally rejecting/transcoding genuinely malformed media, but this isn't verified as a hard guarantee.
- No decompression-bomb-specific handling was found, but this is largely mitigated by Cloudinary handling all actual media processing off the origin server.
- Frontend: video uploads have an explicit client-side size guard mirroring the backend limit; **image uploads (profile photo, club logo) do not** — inconsistent hardening (low severity — backend still enforces its own limit; this is a UX/bandwidth gap, not a security bypass).

---

## 9. Frontend Security

- **F-06 [Medium]**: Access + refresh tokens stored in `SharedPreferences`, not `flutter_secure_storage`. Documented in-code as a deliberate tradeoff because Web's secure-storage implementation degrades to `localStorage` anyway — that reasoning holds for the Web target but not for the Android build the app also ships, where `SharedPreferences` is an unencrypted XML file vs. Keystore-backed encryption available via `flutter_secure_storage`.
- **F-07 [Low-Medium]**: No centralized HTTP auth interceptor. The `runAuthorized()` wrapper (handles 401 → refresh → retry) is opt-in per repository call site rather than enforced by a single `http.Client` layer — nothing structurally prevents a future repository from bypassing the refresh flow.
- **F-08 [Low]**: `.env` is bundled as a plain Flutter asset (ships inside the compiled web/app bundle, extractable from the built artifact). Currently only holds non-secret config (`API_BASE_URL`, `APP_ENV`), but is a footgun if a real secret is ever added there instead of via `--dart-define`.
- **F-09 [Low]**: `mailto:`/`tel:`/`wa.me` links built from user-generated contact-info fields (`simple_contact_actions.dart`) are not URI-escaped, unlike a parallel, properly-escaped WhatsApp implementation elsewhere in the same codebase (`whatsapp_send_button.dart`). Minor mailto-injection-style risk (a crafted email value could append `&subject=...` query params); no arbitrary-scheme or open-redirect risk, since all destination hosts/schemes are hardcoded.
- **F-10 [Low]**: No provider invalidation on logout — `SessionController.logout()` only resets its own state; `playerProfileControllerProvider`, `clubProfileControllerProvider`, `homeFeedControllerProvider`, etc. are not invalidated, risking a brief flash of the previous user's cached profile/feed data on a logout→login cycle within the same app instance (most visible in `AppShell._UserIdentity`).
- Router-level guards correctly treat backend authorization as the source of truth (explicit in-code comments confirm this mental model is applied deliberately, not just assumed).

---

## 10. Performance Issues

Deferred to Phase 11 per the requested ordering; noted in passing during Phase 0:

- `PlayersService.search()` uses an unindexed `$regex` scan (self-documented tradeoff in code) — fine at current scale, worth revisiting if the player table grows large.
- Frontend: no obvious rebuild-storm patterns were found in the files inspected (`ref.watch` usage looked appropriate), but a systematic pass across all ~15 feature folders' `AsyncNotifier.build()` methods was not completed in Phase 0 and should be a Phase 11 action item.
- `AppShell._UserIdentity` watches both the session provider and the active profile provider, causing the top bar to rebuild on every profile-controller emission — appropriate for freshness, flagged only because it interacts with the stale-state gap above (F-10).

---

## 11. Code Quality Issues

- Frontend: `_digitsOnly` phone-sanitizing helper duplicated verbatim in two files instead of shared via `core/utils` (trivial).
- Frontend/backend config duplication with no tooling enforcement: `_extensionMimeTypes` map and `_kMaxVideoBytes` constant in the Flutter API client/upload sheet must be manually kept in sync with backend `upload.config.ts` constants — both are explicitly commented as needing to match, but nothing enforces it, so they can silently drift.
- `community` feature folder lacks a `data/` layer while having `domain/`+`application/` — inconsistent with the otherwise-consistent 4-layer convention used elsewhere; worth a direct check on whether it's intentionally reusing `home_feed`'s data layer or missing one.
- Global `ValidationPipe` does not set `forbidNonWhitelisted: true` — unknown fields are silently stripped rather than rejected with a 400. Low severity (no vulnerability results, since `whitelist: true` still strips them), but reduces visibility into client bugs/probing attempts.

---

## 12. Bugs

Full bug inventory with repro steps is deferred to Phase 10 per the requested ordering. Confirmed candidates surfaced during Phase 0 architecture review (none independently reproduced yet — flagged for Phase 10 verification):

1. **[Medium, unverified]** Stale cached profile/feed data may render briefly for a new session after a logout→login cycle on the same app instance, because role-specific Riverpod providers aren't invalidated on logout (see F-10). Needs a live repro to confirm severity/visibility duration.
2. **[Low]** `VideoPlayerScreen._retry()` reassigns `_controller` to a new instance inside `setState`, then disposes the old (captured) reference afterward — currently correct but fragile; a future refactor could easily introduce a use-after-dispose or double-dispose bug. Flagged as a robustness risk, not a confirmed active bug.
3. **[Low]** Password-reset email being a stub (see §4) manifests as a **functional bug** from the end-user's perspective ("I clicked forgot password and got nothing"), independent of its security angle.

---

## 13. Technical Debt

- No CI/CD pipeline at all — no automated test/lint/build gate on any PR or push. This is the single largest process gap found in Phase 0 and affects every other finding's regression risk going forward.
- No dependency-vulnerability scanning automation (Dependabot/Snyk/`npm audit` in CI).
- No global exception filter or response-shaping interceptor on the backend — relies entirely on NestJS defaults, which is currently safe (no leakage confirmed) but offers no central point to enforce a consistent error envelope if requirements change.
- Several frontend packages are a major version behind (`flutter_riverpod` 2.6.1→3.4.2, `go_router` 17.3.0→18.0.0, `file_picker` 11.0.3→12.0.0) — not urgent (no known CVEs), but breaking-change upgrades will only get harder to schedule the longer they're deferred.

---

## 14. Production Blockers

Ranked by whether they would actually block a production launch, not just severity in the abstract:

| # | Blocker | Why it blocks launch |
|---|---|---|
| PB-1 | **Password-reset email is non-functional in production** (`mail.service.ts` stub) | Users who forget their password have no self-service recovery path at all. This is a hard product blocker, not just a security nice-to-have. Requires wiring a real transactional email provider (SendGrid/SES/Postmark/etc.) before launch. |
| PB-2 | **No Helmet / security headers** | Quick, low-risk fix; should be closed before any public production traffic given it's a one-line addition with no functional risk. |
| PB-3 | **No CI/CD pipeline** | Not a security vulnerability per se, but means every deploy is unverified by any automated gate — elevated regression risk for a "make many changes without breaking features" project like this one. Recommend at minimum a lint+test+build gate before Phase 12+ refactoring begins, so regressions are caught automatically rather than manually. |
| PB-4 | **CORS permissive fallback includes `staging`** | If a staging environment is ever deployed with `CORS_ORIGINS` unset, it silently allows credentialed cross-origin requests from any origin. Should be confirmed operationally (does staging always set this var?) or the Joi validation tightened to require it in staging too. |

None of the other findings in this document are, on their own, production blockers — they are real but lower-severity/lower-likelihood issues appropriate for the P1–P3 refactoring/hardening phases.

---

## 15. Full Findings Register (Security-relevant)

> Statuses last updated: Phase 0.5 (2026-08-25). See [docs/PHASE_0_5_SECURITY_SUMMARY.md](PHASE_0_5_SECURITY_SUMMARY.md) for the fix details, verification, and remaining-risk notes behind each RESOLVED row.

| ID | Severity | Area | Finding | Reference | Location | Status |
|---|---|---|---|---|---|---|
| F-01 | Low | Backend | No Helmet / security headers (CSP, X-Frame-Options, HSTS, X-Content-Type-Options) | CWE-693, ASVS 14.4 | `backend/src/main.ts` | **RESOLVED** (Phase 0.5) — `helmet()` applied in `main.ts`; HSTS only in production. |
| F-02 | Medium | Backend | CORS falls open (`origin: true`, `credentials: true`) when `CORS_ORIGINS` unset, and staging is included in the permissive branch | CWE-346, ASVS 14.5 | `backend/src/main.ts`, `backend/src/config/env.validation.ts` | **RESOLVED** (Phase 0.5) — `CORS_ORIGINS` now required and wildcard-rejected for both `production` and `staging`; only dev/test can fall back to reflecting the origin. |
| F-03 | Medium | Backend | Password-reset token logged to console outside production (including staging) | CWE-532, OWASP A09:2025 | `backend/src/auth/mail/mail.service.ts` | **RESOLVED** (Phase 0.5) — raw token/URL removed from all business-logic logging; the dev-only console provider (which can never run in production/staging by Joi validation) is the sole remaining place a token is printed, for local testability. |
| F-04 | Low | Backend | No `@MaxLength` on password/newPassword fields — bcrypt-cost DoS surface on oversized input (partially mitigated by 5 req/min throttle on login/register) | CWE-400 | `register.dto.ts`, `login.dto.ts`, `reset-password.dto.ts`, `update-user.dto.ts` | **RESOLVED** (Phase 0.5) — `@MaxLength(72)` added to register/reset-password/update-user password fields (bcrypt's own truncation point); `login.dto.ts` intentionally left unbounded to avoid locking out any pre-existing account. |
| F-05 | Info | Backend | JWT strategy doesn't explicitly pin `algorithms: ['HS256']` — functionally safe today, standard hardening | CWE-347, ASVS 3.5/6.2 | `backend/src/auth/strategies/jwt.strategy.ts` | **RESOLVED** (Phase 0.5) — `algorithms: ['HS256']` added; regression test confirms an HS384-signed token is rejected. |
| F-05b | Medium (design confirmation needed) | Backend | `GET /players/:id/contact` exposes any public player's private contact info to any authenticated CLUB, no relationship check, no dedicated rate limit | OWASP API3:2023 | `backend/src/players/players.controller.ts` | **OPEN — product decision required.** Not changed in Phase 0.5 per explicit scope instruction; see §10 of PHASE_0_5_SECURITY_SUMMARY.md. |
| F-05c | High (functional + security) | Backend | Password-reset email is a stub — no real email provider wired up; production password recovery is non-functional | — | `backend/src/auth/mail/mail.service.ts` | **RESOLVED** (Phase 0.5) — SMTP delivery via Nodemailer behind an `EmailProvider` abstraction; `MAIL_PROVIDER=smtp` is mandatory in production/staging (Joi-enforced). |
| F-06 | Medium | Frontend | Access/refresh tokens stored in `SharedPreferences`, not `flutter_secure_storage` — plaintext-equivalent at rest on Android | CWE-312, ASVS 8.1 | `frontend/lib/core/storage/session_storage.dart` | **RESOLVED** (Phase 0.5) — tokens moved to `flutter_secure_storage`; one-time migration for existing installs, all call sites updated to the now-async API. |
| F-07 | Low-Medium | Frontend | No centralized HTTP auth interceptor; 401-retry/refresh flow is opt-in per call site | — | `frontend/lib/core/network/authorized_request.dart` | OPEN — out of Phase 0.5 scope (architectural change, not a listed Phase 0.5 fix). |
| F-08 | Low | Frontend | `.env` bundled as a plain asset, extractable from build artifact (currently non-secret contents) | CWE-200 | `frontend/pubspec.yaml` | OPEN — out of Phase 0.5 scope. |
| F-09 | Low | Frontend | `mailto:`/`tel:`/`wa.me` links built from unescaped user-generated contact data | CWE-79 (adjacent) | `frontend/lib/features/player/presentation/shared/simple_contact_actions.dart` | OPEN — out of Phase 0.5 scope. |
| F-10 | Low | Frontend | Role-specific providers not invalidated on logout — stale data flash risk | — | `frontend/lib/features/auth/application/session_controller.dart` | OPEN — out of Phase 0.5 scope. |
| F-11 | Info | Backend | `ValidationPipe` missing `forbidNonWhitelisted: true` | — | `backend/src/main.ts` | OPEN — not in the Phase 0.5 required-fixes list; revisit in Phase 1/13. |
| F-12 | Info | Backend | `CLOUDINARY_*` env vars not `.required()` in production — fails at first upload, not at boot | — | `backend/src/config/env.validation.ts` | OPEN — out of Phase 0.5 scope. |
| F-13 | Info | Infra | No CI/CD pipeline exists | NIST SSDF PW.4 | (repo-wide) | OPEN — explicitly deferred to a later phase per Phase 0.5 instructions (no CI/CD build-out in this phase). |
| F-14 | Info | Backend | File-upload MIME validation trusts client `Content-Type`, no magic-byte sniffing | CWE-434 (partial) | `backend/src/common/upload.config.ts` | **RESOLVED** (Phase 0.5) — magic-byte signature check added (`common/file-signature.ts`), applied at every upload entry point (players, videos, posts, club logo). |

**Not applicable / checked and clear**: SQL injection (no SQL DB), NoSQL operator injection, hardcoded secrets in source, secrets committed to git history, algorithm-confusion JWT attack, IDOR on all checked endpoints, mass assignment, ReDoS via search input.

---

## Executive Summary

**What this is:** A read-only Phase 0 inventory and audit of Sport X Hub's full stack — backend (NestJS/MongoDB), frontend (Flutter/Riverpod), and infrastructure. No code was changed.

**Bottom line:** This codebase is in noticeably better shape than a typical "unaudited MVP." Core security fundamentals — ownership checks, refresh-token rotation, immediate suspension enforcement, mass-assignment protection, regex-injection escaping — are correctly and consistently implemented across nearly every module checked. The real findings are narrower than expected: one genuine production blocker (non-functional password-reset email), a handful of Medium-severity hardening gaps (missing Helmet headers, staging CORS permissiveness, Android token storage), and a long tail of Low/Info items that are good hygiene rather than active risk.

### Critical
- None found. (No confirmed IDOR, no injection, no exposed secrets, no auth bypass.)

### High
- **PB-1 / F-05c** — Password-reset email is a stub; production users have no working self-service password recovery. Both a functional bug and a security finding (raw token logged in non-prod environments in the interim, F-03).

### Medium
- **F-02** — CORS permissive fallback applies to staging, not just development.
- **F-03** — Password-reset token logged to console outside production.
- **F-05b** — Any authenticated club can view any public player's private contact info with no relationship check (needs product confirmation — may be by design).
- **F-06** — Auth tokens stored unencrypted-at-rest on Android (`SharedPreferences` vs. secure storage).

### Low
- F-01 (no Helmet), F-04 (no password max-length), F-07 (opt-in auth interceptor), F-08 (`.env` bundled as asset), F-09 (unescaped mailto/tel links), F-10 (stale provider data on logout), F-14 (MIME trust without content-sniffing).

### Info / Good Practice Confirmed
- F-05, F-11, F-12, F-13 — minor hardening/process gaps, no direct exploit path.
- Confirmed clean: no hardcoded secrets, no committed `.env`, no NoSQL injection, no IDOR across 9 modules individually checked, `npm audit` 0 vulnerabilities.

### Architecture Findings
- Backend: pragmatic Controller→Service→Model layering, no over-engineering; consistent guard/ownership patterns.
- Frontend: consistent domain/data/application/presentation layering in 12/15 features; deliberate desktop/mobile widget-tree separation; centralized route-guard logic (UX-only, correctly understood as such in-code).
- Minor inconsistencies: `community` feature missing a `data/` layer; provider invalidation not wired to logout.

### Bug Findings
- Stale cached data flash risk after logout→login (unverified live repro, Phase 10 item).
- Fragile-but-currently-correct video controller lifecycle management (`VideoPlayerScreen._retry()`).
- Password-reset "bug" (see High above).

### Performance Findings
- Unindexed regex search in `PlayersService.search()` (self-documented, acceptable at current scale).
- No confirmed rebuild storms; systematic provider-watch audit deferred to Phase 11.

### Dependency Findings
- Backend: 0 known vulnerabilities (`npm audit`).
- Frontend: several packages a major version behind (non-security staleness); no CVE scan tooling exists for Dart/Flutter, so this is coverage via `flutter pub outdated` only.

### Refactoring Recommendations (high level — full plan in Phase 12/`docs/REFACTORING_PLAN.md` pending approval)
- P0: Wire a real email provider for password reset (PB-1); add Helmet; tighten CORS staging behavior; move auth tokens to `flutter_secure_storage` on Android.
- P1: Confirm/restrict `GET /players/:id/contact` access model; centralize the frontend auth-interceptor pattern; add `forbidNonWhitelisted: true`.
- P2: Stand up minimal CI (lint+test+build gate); consolidate duplicated frontend constants/helpers; add provider invalidation on logout.
- P3: Package version upgrades (Riverpod 3, go_router 18, file_picker 12) with breaking-change review.

### Production Blockers
See §14 table above — PB-1 (password reset), PB-2 (Helmet), PB-3 (no CI), PB-4 (CORS/staging).

### Recommended Phase Order
Given the findings above, the phase order originally proposed in your brief remains appropriate, with one adjustment: recommend pulling **PB-1 (password reset)** and **F-01 (Helmet)** into an accelerated "Phase 0.5" fix — both are small, isolated, low-regression-risk changes that unblock production readiness immediately, rather than waiting for the full Phase 1–3 security/architecture audit to complete. Suggested order:

1. *(Optional, your call)* Phase 0.5 — quick wins: Helmet + password-reset email provider (isolated, testable independently).
2. Phase 1 — Security Audit (deepen findings above into full `docs/SECURITY_AUDIT.md` with CWE/OWASP mapping per finding).
3. Phase 2 — Database Security + Performance.
4. Phase 3 — Backend Architecture Refactor (likely light, given the current architecture is already reasonably clean).
5. Phase 4 — API Contract Audit (`docs/API_SECURITY_MATRIX.md`).
6. Phase 5 — Frontend Refactor (likely light — mainly the `community` layer question and provider-invalidation fix).
7. Phase 6 — Frontend Security (tokens, interceptor centralization).
8. Phase 7 — Dependency/Supply Chain Audit (frontend package upgrades).
9. Phase 8 — Static Analysis (run ESLint, `flutter analyze`, `tsc`, `flutter test` — not yet run in Phase 0).
10. Phase 9 — Security Testing (regression suite for all findings above).
11. Phase 10 — Bug Audit (verify the stale-state and video-controller items with live repros).
12. Phase 11 — Performance Audit.
13. Phase 12 — Refactoring (P0 first).
14. Phase 13 — Security Hardening (implement confirmed fixes).
15. Phase 14 — Documentation (`docs/SECURITY_BASELINE.md`, `docs/BUG_AUDIT.md`, etc.).
16. Phase 15 — Final Verification.
17. Phase 16 — Final Security Gate (independent adversarial re-review).

---

**Status: Phase 0 complete. No code changed. Awaiting your review and approval before proceeding to Phase 1.**
