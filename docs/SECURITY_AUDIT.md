# Security Audit — Phase 1

**Date:** 2026-08-25
**Scope:** `backend/src` (NestJS/MongoDB) and, where relevant, `frontend/lib` (Flutter). Read-only — **no code was changed in this phase.**
**Standards:** OWASP ASVS 5.0.0, OWASP Top 10:2025, OWASP API Security Top 10:2023, MITRE CWE Top 25:2025, NIST SP 800-218 SSDF 1.1.
**Method:** Four parallel deep-dive passes (Authentication+Authorization; Input Validation+Injection; File Upload+Rate Limiting; CORS/HTTP+Secrets+Error Handling+Logging), each an adversarial re-read of the actual source — not a repeat of Phase 0's inventory. Findings already fixed in [Phase 0.5](PHASE_0_5_SECURITY_SUMMARY.md) were excluded unless found to be incomplete.

**Headline result:** No Critical or High-severity *exploitable* vulnerability was found (no confirmed IDOR, injection, or auth bypass — consistent with Phase 0). One **High-severity gap** was found that isn't an exploit path in itself but materially weakens the app's ability to detect and respond to one: **there is no security audit trail anywhere in the backend.** Everything else is Medium/Low defense-in-depth.

---

## Findings Register

Columns match the project's standard format. **Status is OPEN for every row** — Phase 1 is audit-only per the project's phase plan; fixes are Phase 13 (or an accelerated sub-phase, at your discretion, same as Phase 0.5 was for Phase 0's findings).

| ID | Severity | OWASP Ref | CWE Ref | Location | Description | Status |
|---|---|---|---|---|---|---|
| S-01 | **High** | ASVS 7.1.1/7.1.3/7.1.4, A09:2025 | CWE-778 | Entire backend — no `Logger` calls outside `auth/mail/*`, no request-logging middleware | No audit trail for login (success/failure), registration, password reset, token refresh/logout, admin suspend/delete, or any upload | OPEN |
| S-02 | Medium | ASVS 2.2.1 | CWE-208 | `auth/auth.service.ts:71-73` (`login()`) | `bcrypt.compare` is skipped entirely when the user doesn't exist, creating a timing gap that lets an attacker distinguish "no such account" from "wrong password" | OPEN |
| S-03 | Medium | API2:2023, ASVS 3.3.1 | CWE-613 | `auth/auth.service.ts:83-101` (`refresh()`) | No refresh-token reuse detection / token-family concept — a stolen-then-replayed token fails silently with no account-wide session revocation or alert | OPEN |
| S-04 | Medium | API4:2023 | CWE-770, CWE-400 | 6 upload routes (players media/profile-photo, club logo, club-managed-player photo, video upload, post image) | Only the global 100/min throttle applies; only `players.media` has any total-count cap (30) — videos/posts have none at all | OPEN |
| S-05 | Medium | ASVS 8.x (privacy) | — | `cloudinary/cloudinary.service.ts:22-40` (`uploadBuffer`) | EXIF (including GPS) metadata is not explicitly stripped on any upload path — a geotagged photo's location may be embedded in a public media URL | OPEN |
| S-06 | Medium (High for `homeFeed`) | API4:2023 | CWE-400, CWE-770 | `posts/dto/feed.dto.ts`, `videos/dto/community-feed.dto.ts`, `players/dto/search-players.dto.ts`, `club-players/dto/list-club-players.dto.ts`, `clubs/dto/list-clubs.dto.ts`, `admin/dto/pagination-query.dto.ts` — all `page` fields | `page` has `@Min(1)` but no `@Max` anywhere; `posts.service.ts` `homeFeed()`'s cost scales **linearly** with `page` by explicit design (re-fetches `page * 12` rows every call), not just via `.skip()` depth | OPEN |
| S-07 | Medium | API4:2023 | CWE-770 | `posts.controller.ts` `GET /feed`, `videos.controller.ts` `GET /videos/community` | Multi-collection aggregate reads (4+ queries, in-memory merge/sort) throttled identically to a single-document read | OPEN |
| S-08 | Medium | API4:2023, CWE-799 | CWE-770 | `videos.controller.ts` like/comment routes, `posts.controller.ts` like/comment routes (6 routes total) | No `@Throttle` beyond the global 100/min default on frequent-interaction endpoints (like-toggle, comment creation) | OPEN |
| S-09 | Medium | ASVS 8.1/14.4 | CWE-524 | `players.controller.ts:218-224` (`GET /players/:id/contact`), `users.controller.ts:16-20` (`GET /users/me`) | No `Cache-Control: no-store` on responses containing private contact info/PII — cacheable by browser or intermediary proxy | OPEN |
| S-10 | Low | ASVS 2.5.4 | CWE-640 | `auth/auth.service.ts:109-128` (`forgotPassword()`) | Requesting a second reset doesn't invalidate a still-unexpired earlier token — two tokens can be simultaneously valid | OPEN |
| S-11 | Low-Medium | ASVS 2.10 | CWE-287 | `auth/auth.service.ts:60-67` (`register()`) | No email-ownership verification — an attacker can squat someone else's email, though the real owner can reclaim it via `forgot-password` | OPEN |
| S-12 | Low | ASVS 2.2.1 | CWE-203 | `auth/auth.service.ts:77-79, 97-99` | The distinct `"This account has been suspended."` message (vs. generic invalid-credentials) confirms an account's existence+status once credentials are known | OPEN |
| S-13 | Low | CWE-1333 | CWE-400 | `players/dto/search-players.dto.ts`, `club-players/dto/list-club-players.dto.ts` — `search` field | No `@MaxLength` on the free-text search string feeding an already-unindexed `$regex` scan (metacharacters are escaped, so not ReDoS-proper, but length is unbounded) | OPEN |
| S-14 | Low | CWE-20 | — | `posts.controller.ts:74`, `videos.controller.ts:130` — comment-list `page` params | Two endpoints take `@Query('page') page?: string` raw instead of a validated DTO field; `parseInt('-99999999')` or `NaN` reaches `.skip()` unvalidated, producing a 500 instead of a clean 400 | OPEN |
| S-15 | Low | CWE-20/400 | — | ~12 DTO fields across `players`, `club-players`, `clubs`, `videos`, `posts`, `sports`, `auth` modules (full list in Appendix A) | Various free-text/filter fields have no `@MaxLength`, including two `Update*Dto`/`Create*Dto` inconsistencies (`UpdateAchievementDto.title`, `UpdateSocialLinkDto.platform` — capped on Create, not on Update) | OPEN |
| S-16 | Low | CWE-400 | — | `auth/dto/login.dto.ts` (`password`), `users/dto/update-user.dto.ts` (`currentPassword`) | Missed by the Phase 0.5 `@MaxLength(72)` pass — these two password-*comparison* fields (fed to `bcrypt.compare`) have no upper bound, unlike every password-*hashing* field | OPEN |
| S-17 | Low | ASVS 7.4 | CWE-532 | NestJS default `BaseExceptionFilter` (framework behavior, confirmed via source read) | Uncaught Mongo/Mongoose errors (e.g. `E11000` duplicate-key on a registration race) are **not** leaked to the client (confirmed generic 500 body), but the full raw error — including the offending email — is logged server-side with no redaction | OPEN |
| S-18 | Low/Info | ASVS 14.4 | CWE-693 | `main.ts:20-28` (Helmet config) | Helmet 8.x does not set `Permissions-Policy` by default (contrary to the original audit brief's assumption, verified by reading the installed package) — low impact for a pure JSON API | OPEN |
| S-19 | Info | CWE-203 | — | `users/users.service.ts:45-50` (register conflict) | Standard, expected registration-conflict behavior; enumerates registered emails at 5 req/min, same tradeoff nearly every product accepts | Accepted risk (no action proposed) |
| S-20 | Info/Low | — | — | `admin/admin.controller.ts:43-56` | An admin can suspend/delete another admin, including the last remaining one, with no lockout protection | OPEN (design decision) |
| S-21 | Info | — | — | `@nestjs/throttler` default tracker (confirmed via source read: keys by IP) | `/auth/register`'s 5/min throttle is per-IP; trivially bypassed by IP rotation; no CAPTCHA/email-verification gate exists | Accepted risk / product decision |

**D. Injection (NoSQL, command, template, path traversal, SSRF): all checked, all clear.** No findings — see Appendix B for the specific evidence per category (this was a genuine re-verification, not a rubber stamp: regex search is escaped, all `@Param()` values are plain strings incapable of carrying operator objects, no `child_process`/`eval`/template engine exists anywhere, Cloudinary paths are 100% server-constructed, and no endpoint fetches a client-supplied URL).

---

## Detail on the two most consequential findings

### S-01 — No security audit trail (High)

This is the one finding in this phase worth elevating above "defense-in-depth nice-to-have." The gap isn't that an attack is easier — it's that **if one happens, there's no way to know**. Concretely, today:

- A brute-forced or credential-stuffed login (bounded only by 5/min per IP) produces no log line, successful or failed.
- An admin — compromised, malicious, or simply mistaken — can suspend or permanently delete any account (including cascading deletion of a player's media/videos) with zero record of who did it or when.
- Password-reset requests, token refreshes, and logouts leave no trace beyond MongoDB's own TTL-expired token rows.

**Impact:** post-incident forensics ("who deleted this account?"), abuse detection (repeated failed logins, mass account creation), and basic accountability (GDPR Art. 30/32, SOC2 CC7.2 if ever relevant) are all currently impossible to reconstruct after the fact.

**Suggested fix (describe only, not implemented this phase):** a small `AuditLogService` — either a dedicated Mongo collection or structured JSON to stdout for downstream aggregation — invoked from `AuthService.login`/`register`/`resetPassword`, `UsersService.updateStatus`/`deleteById`, `AdminController`'s destructive endpoints, and the 6 upload entry points. Log **structured fields** (actor id, action, target, timestamp, outcome), never string-interpolated — this closes CWE-117 log-injection by construction, which matters here because `LoginDto.identifier` (unlike `email`) has no `@IsEmail()` format restriction and would otherwise be the one unrestricted user string flowing into a future log line.

### S-06 — Unbounded `page` depth, `homeFeed` specifically (Medium, High for that one endpoint)

`posts.service.ts`'s `homeFeed()` has a comment acknowledging its own design: it re-fetches `page * 12` rows from *both* the video and photo collections on every call, an explicitly-accepted tradeoff "at this app's scale." The problem is nothing enforces that scale assumption — `GET /feed?sport=football&page=999999` forces two `.limit(999999*12)` queries per request, repeatable at the standard 100/min throttle. This is the single cheapest-to-mount resource-amplification vector found in this phase. Every other paginated endpoint's cost is bounded by actual collection size (`.skip()` can't exceed it); `homeFeed` is not.

---

## What was checked and confirmed secure (do not re-flag)

- **IDOR/BOLA:** every controller re-walked; ownership is enforced via `user.sub` scoping or explicit join-table checks (`ClubManagedPlayer`) on every mutating/reading endpoint that takes a resource id. Embedded sub-document mutation (achievements/social-links) is scoped to the caller's own profile first, so a foreign sub-document `_id` can never be found. Confirmed no cross-tenant leak between clubs.
- **Mass assignment / Broken Object Property Level Authorization:** no non-admin DTO exposes `role`/`status`/`ownerId`/`clubId`/`verified`/`isAdmin`.
- **NoSQL injection:** confirmed clear — typed DTOs reject object payloads before they reach any query; regex search is properly escaped.
- **Command injection, template injection, path traversal, SSRF:** confirmed clear, see Appendix B.
- **CORS origin matching:** confirmed via reading the installed `cors` package source — exact string equality only, no subdomain/prefix bypass possible.
- **Secrets:** no hardcoded credentials anywhere (full grep sweep); `.env` files confirmed still git-untracked; SMTP password confirmed not reachable from any HTTP response.
- **JWT algorithm pinning, CORS staging requirement, Helmet CSP/HSTS scoping, upload magic-byte checks (all 6 endpoints, including club logo):** all re-verified intact from Phase 0.5, no regressions.
- **Client-facing error leakage:** confirmed via reading NestJS's actual `BaseExceptionFilter` source — raw Mongo/Mongoose errors cannot reach the client (they lack the `.statusCode` property the filter's leak-check requires), contradicting the original brief's assumption. The *logging* side of this (S-17) is still open, but client exposure is not a risk.
- **Log injection (CWE-117):** not currently exploitable — the only user-controlled value reaching any `Logger` call today is `ConsoleEmailProvider`'s recipient email, which is `@IsEmail()`-validated (rejects CRLF) and can only run in dev/test by construction.

---

## Appendix A — S-15 full field list

`contact-details.dto.ts` (phone, whatsapp) · `achievement.dto.ts` (Create/Update description, Update title) · `social-link.dto.ts` (Update platform) · `create-club-player.dto.ts` (sport) · `update-player-profile.dto.ts` (sport) · `search-players.dto.ts` (search, country, position, sport) · `list-club-players.dto.ts` (search, sport, position) · `list-clubs.dto.ts` (country) · `list-videos.dto.ts` / `community-feed.dto.ts` / `upload-video.dto.ts` (category) · `feed.dto.ts` / `list-skill-categories.dto.ts` (sport) · `refresh-token.dto.ts` (refreshToken).

## Appendix B — Injection: evidence of "checked and clear"

| Category | Evidence |
|---|---|
| NoSQL/operator injection | Global `ValidationPipe({whitelist:true, transform:true})` + typed decorators (`@IsString`, `@IsEmail`, `@IsMongoId`) reject any object-shaped payload before it reaches a query. Free-text search is regex-escaped (`escapeRegex()`, `players.service.ts:85`). All `@Param()` values are Express path segments — structurally incapable of carrying a `{"$ne":null}` object. |
| Command/OS injection | Zero matches for `child_process`, `exec(`, `spawn(`, `eval(`, `new Function(` anywhere in `backend/src`, including seed/migration scripts. |
| Template injection | Password-reset email HTML interpolates only `resetUrl`, built from `FRONTEND_URL` (server config) + a server-generated random token — never user input. No templating engine used anywhere else. |
| Path traversal | `CloudinaryService.uploadBuffer`'s `folder` param is always a hardcoded literal per call site; `deleteAsset`'s `publicId` always comes from a previously-stored, server-generated Cloudinary result — never client input. |
| SSRF | Zero matches for `fetch(`, `axios`, `http.get`, `https.get`, `got(` — no endpoint fetches any client-supplied URL; all media ingestion is multipart file upload only. |

---

## Recommended next step

Same pattern as Phase 0 → 0.5: this document is the audit; nothing has been fixed. Given the findings, a reasonable next move (your call) would be a **Phase 1.5** closing the Medium items with the best cost/impact ratio — S-01 (audit logging), S-06 (cap `page`, fix `homeFeed`'s cost model), S-04/S-07/S-08 (endpoint-specific throttles), S-09 (`Cache-Control: no-store`) — before proceeding to Phase 2 (Database Security + Performance), mirroring how Phase 0.5 handled Phase 0's findings. Everything else here is small, low-risk, and could ride along with that pass or wait for Phase 13.

**Status: Phase 1 complete. No code changed. Awaiting your review before any fixes are implemented.**
