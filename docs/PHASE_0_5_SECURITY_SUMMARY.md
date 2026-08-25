# Phase 0.5 — Security & Production Blockers

**Date:** 2026-08-25
**Scope:** Close the security/production-blocker findings from [docs/FULL_SYSTEM_AUDIT.md](FULL_SYSTEM_AUDIT.md) (Phase 0) before starting the full refactoring/audit program. No architecture redesign, no new features, no CI/CD build-out.

---

## 1. Scope

Eight required fixes from the Phase 0.5 instructions, all implemented:

1. Password reset — production-ready email delivery
2. CORS hardening
3. Password-reset token logging
4. Secure token storage (Flutter)
5. Security headers / Helmet
6. JWT algorithm pinning
7. Password maximum length
8. Upload content validation (magic bytes)

Plus two explicitly scoped non-changes:
- **Player contact exposure (F-05b)** — reviewed, documented as a product decision, **not changed**.
- **CI/CD (F-13)** — confirmed still absent, **not built out**, left `OPEN` for a later phase.

---

## 2. Findings Addressed

| Audit ID | Finding | Outcome |
|---|---|---|
| F-01 | No Helmet / security headers | RESOLVED |
| F-02 | CORS falls open in staging | RESOLVED |
| F-03 | Reset token logged outside production | RESOLVED |
| F-04 | No password max length | RESOLVED |
| F-05 | JWT algorithm not pinned | RESOLVED |
| F-05c | Password-reset email is a non-functional stub | RESOLVED |
| F-06 | Auth tokens in plaintext `SharedPreferences` | RESOLVED |
| F-14 | Upload MIME validation trusts client header only | RESOLVED |
| F-05b | Player contact exposed to any Club | **OPEN — product decision required** (unchanged, per scope) |
| F-07, F-08, F-09, F-10, F-11, F-12, F-13 | (frontend interceptor, `.env` asset, unescaped links, stale providers, `forbidNonWhitelisted`, Cloudinary required-in-prod, no CI) | **OPEN — out of Phase 0.5 scope**, unchanged |

---

## 3. Files Changed

### Backend

**New files:**
- `backend/src/auth/mail/email-provider.interface.ts` — `EmailProvider` delivery seam
- `backend/src/auth/mail/smtp-email.provider.ts` — Nodemailer/SMTP implementation
- `backend/src/auth/mail/console-email.provider.ts` — dev/test-only stand-in (Joi-blocked in prod/staging)
- `backend/src/auth/mail/mail.service.spec.ts`
- `backend/src/common/file-signature.ts` — magic-byte content validator
- `backend/src/common/file-signature.spec.ts`
- `backend/src/config/env.validation.spec.ts`

**Modified:**
- `backend/src/main.ts` — Helmet, CORS comment update
- `backend/src/config/env.validation.ts` — CORS_ORIGINS staging + wildcard rules, MAIL_PROVIDER/SMTP_*/FRONTEND_URL schema
- `backend/.env.example` — new env vars documented
- `backend/src/auth/auth.module.ts` — `EMAIL_PROVIDER` DI wiring
- `backend/src/auth/auth.service.ts` — `forgotPassword` passes a correlation id instead of relying on token-bearing logs
- `backend/src/auth/auth.service.spec.ts` — new `forgotPassword` tests
- `backend/src/auth/mail/mail.service.ts` — rewritten around `EmailProvider`
- `backend/src/auth/strategies/jwt.strategy.ts` / `.spec.ts` — `algorithms: ['HS256']` + regression test
- `backend/src/auth/dto/register.dto.ts`, `reset-password.dto.ts`, `backend/src/users/dto/update-user.dto.ts` — `@MaxLength(72)`
- `backend/src/players/players.service.ts` / `.spec.ts`, `videos/videos.service.ts` / `.spec.ts`, `posts/posts.service.ts`, `clubs/clubs.service.ts` — magic-byte validation wired in; test fixtures updated to genuine media signatures
- `backend/package.json`, `package-lock.json` — added `helmet`, `nodemailer`, `jsonwebtoken` (+ `@types/*`)

### Frontend

- `frontend/lib/core/storage/session_storage.dart` — rewritten around `flutter_secure_storage`, async API, one-time migration
- `frontend/lib/main.dart` — wires `FlutterSecureStorage`, runs the migration at boot
- `frontend/lib/core/network/authorized_request.dart`, `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart` — updated to `await` the now-async token getters
- `frontend/pubspec.yaml` / `.lock` — added `flutter_secure_storage`, `mocktail` (dev)
- `frontend/test/core/storage/session_storage_test.dart` — new

### Documentation
- `docs/FULL_SYSTEM_AUDIT.md` — findings register updated with per-finding Status
- `docs/PHASE_0_5_SECURITY_SUMMARY.md` — this file

---

## 4. Security Reasoning Per Fix

### 4.1 Password reset — production-ready (F-05c)

**Before:** `MailService.sendPasswordResetEmail` was a stub. In production it logged a warning and sent nothing; in dev/staging it logged the raw token.

**After:** `MailService` now depends on an `EmailProvider` interface (`email-provider.interface.ts`), resolved by DI in `auth.module.ts` based on `MAIL_PROVIDER`:
- `smtp` → `SmtpEmailProvider` (Nodemailer, real SMTP delivery)
- `console` → `ConsoleEmailProvider` (dev/test-only stand-in)

`env.validation.ts` makes `MAIL_PROVIDER=smtp` **mandatory** whenever `NODE_ENV` is `production` or `staging` — the app fails to boot if a real deployment tries to use the console provider. Swapping SMTP for a different transactional API later means adding one more class implementing `EmailProvider`; nothing in `AuthService` or callers changes.

**Token lifecycle, confirmed unchanged and still correct:** opaque 48-byte random token, HMAC-SHA256 hashed at rest (`PasswordResetToken.tokenHash`), 1-hour TTL, single-use (deleted on successful reset along with every other pending reset token and every refresh token for that account — `AuthService.resetPassword`), never returned in any API response. `forgotPassword` still returns the same generic response regardless of whether the email exists (OWASP ASVS 2.10 — no account-enumeration signal).

**References:** OWASP ASVS 2.10 (password reset), CWE-640 (weak password recovery — closed by keeping the existing hashed/single-use/short-TTL token design and only fixing *delivery*).

### 4.2 CORS hardening (F-02)

**Before:** `CORS_ORIGINS` was required only in `production`; `staging` fell into the same permissive `origin: true` branch as local development.

**After:** `env.validation.ts`'s `CORS_ORIGINS` schema now requires a non-empty value whenever `NODE_ENV` is `production` **or** `staging`, and a custom Joi validator explicitly rejects a literal `*` in either environment (relevant because `credentials: true` is always on in `main.ts`, and browsers/the CORS spec forbid combining a wildcard origin with credentials safely). Development/test are unaffected — they can still leave it empty for local convenience.

**References:** CWE-346 (Origin Validation Error), OWASP ASVS 14.5 (deployment configuration — no dev-permissive settings in a real deployment).

### 4.3 Password-reset token logging (F-03)

**Before:** `ConsoleEmailProvider`'s predecessor logged the raw reset token in every non-production environment, including `staging` — a real, internet-reachable deployment.

**After:** Two structural changes close this, not just a deleted log line:
1. §4.1's Joi requirement means `MAIL_PROVIDER=console` (the only place a token is ever printed) **cannot run in production or staging at all** — it's not a matter of remembering to check `NODE_ENV` in one file anymore; the app won't boot with that combination.
2. `MailService.sendPasswordResetEmail` itself never logs the token or the reset URL — only a `correlationId`, which is the persisted `PasswordResetToken` document's own MongoDB `_id` (non-reversible to the token, not sensitive). `SmtpEmailProvider` likewise never logs the URL it sends. The only remaining place the raw token is printed is inside `ConsoleEmailProvider`, gated by (1) to dev/test only, and documented in that file as existing specifically so the forgot/reset-password flow stays testable locally without real SMTP infrastructure.

**References:** CWE-532 (Insertion of Sensitive Information into Log File), OWASP A09:2025 (Logging and Alerting Failures).

### 4.4 Secure token storage — Flutter (F-06)

**Before:** `SessionStorage` persisted the JWT access/refresh token pair in `SharedPreferences` — an unencrypted XML file on Android, readable with root/backup access.

**After:** `SessionStorage` now wraps `flutter_secure_storage` (Keystore-backed `EncryptedSharedPreferences` on Android, Keychain on iOS/macOS, DPAPI on Windows). Since secure-storage reads are inherently async (platform-channel calls), `accessToken`/`refreshToken` changed from synchronous getters to `Future<String?>` getters — the two call sites that read them directly (`authorized_request.dart`, `auth_repository_impl.dart`) were updated to `await` them; every other repository already went through `runAuthorized()`, so nothing else needed to change.

**Migration, not a breaking upgrade:** `SessionStorage.migrateFromSharedPreferences()` runs once at app boot (`main.dart`) — it copies any token pair still sitting in the old `SharedPreferences` keys into secure storage, then deletes the plaintext copy. An existing install upgrades in place on its next launch rather than being force-logged-out. It's a no-op (single `getString` read, no writes) once the plaintext keys are gone.

**Scope discipline:** `LocaleStorage` (theme/language preference) was deliberately left on `SharedPreferences` — it's not an authentication secret, and moving it would have been an unrequested behavior change.

**References:** CWE-312 (Cleartext Storage of Sensitive Information), OWASP ASVS 8.1 (client-side data protection).

### 4.5 Security headers / Helmet (F-01)

**Before:** No `helmet` dependency, no explicit security headers at all — Express defaults only.

**After:** `helmet()` applied globally in `main.ts`. Two deliberate deviations from Helmet's defaults, both documented inline:
- `contentSecurityPolicy: false` — this is a JSON API, not an HTML-serving app (Flutter Web is served separately by nginx per `frontend/Dockerfile`); Helmet's default CSP exists to restrict inline scripts/styles on *rendered pages*, which don't exist here, so leaving it on would add no protection while risking unexpected header behavior for API clients.
- `hsts` only set when `NODE_ENV === 'production'` — forcing `Strict-Transport-Security` in development would make `http://localhost` awkward/unusable in browsers that cache the header, and the API isn't served over HTTPS locally anyway.

Kept at Helmet's default: `X-Content-Type-Options: nosniff`, `X-Frame-Options`/frame-ancestors protections, `Referrer-Policy`, hidden `X-Powered-By`, and more.

**References:** CWE-693 (Protection Mechanism Failure), OWASP ASVS 14.4 (HTTP security headers).

### 4.6 JWT algorithm pinning (F-05)

**Before:** `JwtStrategy`'s `passport-jwt` options didn't set `algorithms`, relying on `jsonwebtoken`'s default behavior to reject `alg: none` and mismatched key types.

**After:** `algorithms: ['HS256']` added explicitly to `JwtStrategy`'s constructor options — the only algorithm this app's symmetric secret is ever used to sign with. A regression test (`jwt.strategy.spec.ts`) signs one token with HS256 and one with HS384 using the same secret, reads the strategy's own `_verifOpts.algorithms` (what `passport-jwt` actually hands to `jsonwebtoken.verify`), and asserts the HS384 token is rejected — verifying the wiring, not just the intent.

No change to how access tokens are *signed* (`AuthService.issueTokens` / `JwtModule.registerAsync` in `auth.module.ts`) — only what the verifier accepts.

**References:** CWE-347 (Improper Verification of Cryptographic Signature — "algorithm confusion"), OWASP ASVS 3.5/6.2.

### 4.7 Password maximum length (F-04)

**Before:** `register.dto.ts`, `reset-password.dto.ts`, and `update-user.dto.ts`'s password fields had `@MinLength(8)` but no upper bound — an oversized payload still costs full bcrypt CPU on every hash/compare.

**After:** `@MaxLength(72)` added to all three — 72 bytes is bcrypt's own truncation point (`bcryptjs` silently ignores anything past it), so this rejects oversized input *before* it reaches `bcrypt.hash`/`bcrypt.compare`, without changing what any legitimate password can be. `PASSWORD_MAX_LENGTH` is exported once from `register.dto.ts` and imported by the other two DTOs to keep the value in one place.

**Deliberately left unbounded:** `login.dto.ts`'s `password` field. Adding a cap there risked locking out any account whose password was hashed (with bcrypt's own truncation) before this change, from a value longer than 72 characters — since bcrypt already truncates at comparison time, capping input length at login buys no additional protection and only risks breaking existing accounts. The 5 req/min throttle on `/auth/login` (pre-existing, `auth.controller.ts`) already bounds the DoS surface there.

**References:** CWE-400 (Uncontrolled Resource Consumption), OWASP Password Storage Cheat Sheet (bcrypt's 72-byte limit).

### 4.8 Upload content validation — magic bytes (F-14)

**Before:** File-type validation relied entirely on the client-supplied `Content-Type` (Multer `fileFilter` in `upload.config.ts`, plus a service-layer mimetype re-check in `players.service.ts`/`videos.service.ts`/`posts.service.ts`) — a value the client fully controls and can spoof. `clubs.service.ts`'s logo upload had no service-layer re-check at all.

**After:** `common/file-signature.ts` adds `assertFileContentMatchesMimeType(file, kind)`, checking the file's actual magic bytes against its declared media family:
- Images: JPEG (`FF D8 FF`), PNG (`89 50 4E 47 0D 0A 1A 0A`), GIF (`GIF87a`/`GIF89a`), WebP (`RIFF`…`WEBP`)
- Videos: WebM (EBML header `1A 45 DF A3`), MP4/QuickTime (ISO-BMFF box type at offset 4 — `ftyp`/`moov`/`mdat`/etc.)

Checked by *media family* rather than exact codec subtype deliberately — MP4 and QuickTime share the same ISO-BMFF container structure, so distinguishing them by signature alone would be unreliable and risk rejecting genuine files; the goal is catching content that isn't the declared family at all (an executable or script renamed to `photo.jpg`), which magic-byte category checking does reliably.

Wired in at every upload entry point: `players.service.ts` (`validateMediaFile`, covers both direct player uploads and the club-managed player photo path via `setProfilePhoto`), `videos.service.ts` (`uploadVideo`), `posts.service.ts` (`createPost`), and `clubs.service.ts` (`uploadLogo` — this one previously had no service-layer check whatsoever, so both a mimetype allowlist check and the signature check were added together).

**References:** CWE-434 (Unrestricted Upload of File with Dangerous Type), OWASP File Upload Cheat Sheet (content-based validation, not extension/header-only).

---

## 5. Environment Variables — New/Changed

All documented in `backend/.env.example`.

| Variable | Required when | Purpose |
|---|---|---|
| `MAIL_PROVIDER` | Always has a value (`console` default) | `smtp` for real delivery, `console` for dev/test only. **Must be `smtp` in production/staging** — app fails to boot otherwise. |
| `SMTP_HOST` | `MAIL_PROVIDER=smtp` | SMTP server hostname |
| `SMTP_PORT` | Always has a value (`587` default) | SMTP port |
| `SMTP_SECURE` | Always has a value (`false` default) | `true` for implicit TLS (port 465), `false` for STARTTLS (587) |
| `SMTP_USER` | `MAIL_PROVIDER=smtp` | SMTP auth username |
| `SMTP_PASSWORD` | `MAIL_PROVIDER=smtp` | SMTP auth password — **treat as a secret**, never commit |
| `SMTP_FROM` | `MAIL_PROVIDER=smtp` | "From" header, e.g. `Sport X Hub <no-reply@sportxhub.com>` |
| `FRONTEND_URL` | `MAIL_PROVIDER=smtp` | Base URL used to build the password-reset link embedded in the email |
| `CORS_ORIGINS` | Always required in `production`/`staging` (was `production`-only before) | Comma-separated allowed origins; wildcard (`*`) now rejected in both |

No secret's actual value is stored anywhere in this repository — `backend/.env` remains untracked (confirmed via `git ls-files` and full `git log --all` history check, same as Phase 0).

---

## 6. Tests Added

**Backend (Jest) — 15 new tests across 4 new spec files + additions to 4 existing ones:**
- `common/file-signature.spec.ts` (9 tests) — genuine JPEG/PNG/GIF/WebP/MP4/WebM accepted; plain text, an ELF executable, a wrong-signature image, and a too-short buffer all rejected under a spoofed MIME type.
- `config/env.validation.spec.ts` (10 tests) — CORS_ORIGINS required/wildcard-rejected in production and staging, allowed empty in development; MAIL_PROVIDER defaults to console, rejected in production, SMTP_*/FRONTEND_URL required when `smtp`.
- `auth/mail/mail.service.spec.ts` (3 tests) — reset URL built correctly and delegated to the provider; **raw token/URL never appear in any log output** (regression test intercepting `process.stdout.write`); a provider failure is swallowed rather than thrown (preserves the no-enumeration-signal behavior).
- `auth/auth.service.spec.ts` (+2 tests) — `forgotPassword` is a no-op for an unregistered email; for a registered one, the token is hashed before storage and only the token document's own `_id` (never the raw token) reaches `MailService` as the correlation id.
- `auth/strategies/jwt.strategy.spec.ts` (+1 test) — an HS384-signed token (same secret) is rejected once the strategy's pinned `algorithms: ['HS256']` is applied.
- `players/players.service.spec.ts` (+1 test) — an oversized (>5MB) photo upload is rejected before reaching Cloudinary.
- Existing `players.service.spec.ts` / `videos.service.spec.ts` fixtures updated from placeholder buffers to genuine PNG/MP4 signatures so the new magic-byte check doesn't false-positive on mock data.

**Frontend (Flutter) — new file `test/core/storage/session_storage_test.dart` (5 tests):** save/read/clear delegate correctly to a mocked `FlutterSecureStorage`; the SharedPreferences→secure-storage migration moves and removes legacy tokens; migration is a no-op when there's nothing to migrate.

---

## 7. Verification Results

### Backend
```
npm run build   → PASS (tsc, no errors)
npm run lint    → 1 pre-existing, unrelated warning (unused `VideoCommentDocument` import
                   in videos.service.ts, predates this phase — left untouched per scope)
npm test        → PASS — 13 suites, 94 tests, 0 failures
```

### Frontend
```
flutter analyze → PASS, no issues
flutter test    → PASS — 51 tests, 0 failures (46 pre-existing + 5 new)
```

### Manual/regression coverage against the Phase 0.5 verification checklist

| # | Item | Covered by |
|---|---|---|
| 1 | Register | `auth.service.spec.ts` (existing, unmodified) |
| 2 | Login | `auth.service.spec.ts` — wrong password, unknown identifier, suspended account, success |
| 3 | Refresh token | `auth.service.spec.ts` (existing) — rotate-on-use, hashed storage |
| 4 | Logout | Unchanged; not independently re-verified beyond existing coverage (no logic touched) |
| 5 | Session restore | `session_storage_test.dart` (migration path) + existing frontend flow, unchanged logic otherwise |
| 6 | Forgot password | `auth.service.spec.ts` (new tests) + `mail.service.spec.ts` |
| 7 | Reset password | `auth.service.spec.ts` (existing, unmodified logic) |
| 8 | Suspended user | `jwt.strategy.spec.ts`, `auth.service.spec.ts` (existing, unmodified logic) |
| 9 | File upload | `file-signature.spec.ts`, `players.service.spec.ts` |
| 10 | CORS | `env.validation.spec.ts` |
| 11 | JWT rejection | `jwt.strategy.spec.ts` (new algorithm-pinning test) |
| 12 | Oversized upload | `players.service.spec.ts` (new test) |
| 13 | Invalid MIME/magic bytes | `file-signature.spec.ts` |

Items 4 and 7 have pre-existing test coverage whose logic wasn't touched in this phase (only `forgotPassword`'s correlation-id plumbing changed; `resetPassword`/`logout` bodies are untouched) — no new test was added for them since nothing about their behavior changed.

No manual end-to-end run against a live server/app was performed in this phase (no `.env` credentials were provisioned for real SMTP); all verification is at the unit/integration-test level described above, which is what the touched code paths' existing test infrastructure supports.

---

## 8. OWASP/CWE References Used

Only the ones actually tied to a fix in this phase (per the instruction not to cite for form's sake):

- **CWE-434** (Unrestricted Upload of File with Dangerous Type) — §4.8
- **CWE-532** (Insertion of Sensitive Information into Log File) — §4.3
- **CWE-346** (Origin Validation Error) — §4.2
- **CWE-400** (Uncontrolled Resource Consumption) — §4.7
- **CWE-347** (Improper Verification of Cryptographic Signature) — §4.6
- **CWE-312** (Cleartext Storage of Sensitive Information) — §4.4
- **CWE-693** (Protection Mechanism Failure) — §4.5
- **CWE-640** (Weak Password Recovery Mechanism) — §4.1
- **OWASP ASVS 2.10** (password reset), **3.5/6.2** (algorithm confusion), **8.1** (client data protection), **14.4** (HTTP headers), **14.5** (deployment config) — mapped 1:1 to fixes above
- **OWASP A09:2025** (Logging and Alerting Failures) — §4.3

---

## 9. Remaining Open Findings

Unchanged from Phase 0, not addressed in this phase (see `docs/FULL_SYSTEM_AUDIT.md` §15 for full detail):

- **F-05b** (player contact exposure) — product decision required, see §10 below.
- **F-07** — frontend auth interceptor is opt-in per call site, not centralized.
- **F-08** — `.env` bundled as a plain Flutter asset.
- **F-09** — unescaped `mailto:`/`tel:` links from user-generated contact data.
- **F-10** — role-specific Riverpod providers not invalidated on logout.
- **F-11** — `ValidationPipe` missing `forbidNonWhitelisted: true`.
- **F-12** — `CLOUDINARY_*` not `.required()` in production.
- **F-13** — no CI/CD pipeline. Explicitly out of scope for this phase per instructions; still open.

---

## 10. Product Decisions Still Required

**F-05b — `GET /players/:id/contact` (players.controller.ts).** Any authenticated CLUB account can view any PUBLIC player's private phone/email/WhatsApp by ID, with no prior relationship (no "saved" requirement) and no dedicated rate limit or audit log on this specific endpoint beyond the app-wide default. This was **not changed** in Phase 0.5, per explicit instruction to leave it alone and only document it here.

This may be intentional product behavior ("any club can browse and contact any public player, that's the point of the platform"), or it may need tightening (e.g. require the club to have saved/be managing the player first, or add a per-club rate limit on this specific endpoint to blunt bulk contact-scraping). **This needs a product-owner decision before any code changes are made to it** — recommend making that call before or during Phase 4 (API Contract Audit), where the full endpoint matrix will be produced and this can be resolved alongside every other endpoint's documented intent.
