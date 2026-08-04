# Phase 1 Summary — Authentication & User Core

**Status:** Phase 1 (Authentication & User Core) implemented, reviewed, and committed. This document is the technical reference for what Phase 1 added — read alongside [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (scope/phases) and [`PHASE0_SUMMARY.md`](PHASE0_SUMMARY.md) (baseline architecture, still accurate). Backfilled post-Phase-4 as part of the Release Readiness Audit; describes the codebase as implemented, not a plan.

---

## 1. Features Implemented

- **Register** — role choice limited to `PLAYER` or `CLUB` only; `ADMIN` cannot self-register.
- **Login / Logout** — email + password, JWT access + refresh token pair issued on success.
- **JWT access + refresh flow** — 15-minute access tokens, 7-day opaque refresh tokens, refresh rotates the token on every use.
- **Forgot / reset password** — opaque, single-use, time-boxed reset token emailed to the account; resetting invalidates every existing session for that account.
- **Role-based route guarding** (frontend) — Go Router redirects unauthenticated users to `/login` and authenticated users away from the guest-only auth pages, with a separate admin-only gate added in Phase 4.
- **Basic account settings** — change email, change password (current password required to change password).

## 2. APIs

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/auth/register` | public | Role restricted to `PLAYER`/`CLUB` via DTO validation |
| POST | `/auth/login` | public | Rejects suspended accounts |
| POST | `/auth/refresh` | public (refresh token) | Rotates the refresh token on every use |
| POST | `/auth/logout` | public (refresh token) | Deletes the stored refresh token hash |
| POST | `/auth/forgot-password` | public | Always returns success, regardless of whether the email exists — avoids leaking which addresses are registered |
| POST | `/auth/reset-password` | public (reset token) | Invalidates all refresh tokens for the account on success |
| GET | `/users/me` | authenticated | Returns the public user shape (never `passwordHash`) |
| PATCH | `/users/me` | authenticated | Change email and/or password; password change requires `currentPassword` |

## 3. Database Changes

- **New collection `users`** — `{ email (unique, lowercased, trimmed), passwordHash, role: 'PLAYER' | 'CLUB' | 'ADMIN', status: 'ACTIVE' | 'SUSPENDED', createdAt, updatedAt }`. The unique index on `email` is enforced at the database level, not just application-level — a duplicate registration is rejected by Mongo, not merely caught in code.
- **New collection `refreshtokens`** — `{ userId (indexed, ref: User), tokenHash (unique), expiresAt }`, with a TTL index on `expiresAt` so MongoDB automatically deletes expired tokens.
- **New collection `passwordresettokens`** — same shape and TTL pattern as `refreshtokens`.

## 4. Flutter Screens

Following the established Desktop/Mobile fork from Phase 0 — every screen below has independent `presentation/desktop/` and `presentation/mobile/` widget trees, sharing only `domain/data/application`:

- **Login** (Desktop + Mobile)
- **Register** with role picker (Desktop + Mobile) — `RolePicker` is a shared atom (no layout decisions of its own), reused by both trees per the Phase 0 convention for platform-agnostic components.
- **Forgot Password** (Desktop + Mobile)
- **Reset Password** (Desktop + Mobile) — reads the reset token from the route's query parameter
- **Empty Player Dashboard** and **Empty Club Dashboard** (Desktop + Mobile) — role-specific landing screens, populated with real content in later phases
- **Account Settings** — change email / change password forms

## 5. Architecture Decisions

- **Opaque refresh/reset tokens, hashed with a keyed HMAC (not plain SHA-256).** `AuthService.hashToken()` uses `JWT_REFRESH_SECRET` as the HMAC key, so a stolen database row alone never yields a usable token without also knowing the secret — a plain hash would be reversible-by-lookup for common tokens or at least equivalent-secret-free, this isn't.
- **Refresh tokens rotate on every use.** `AuthService.refresh()` deletes the presented token and issues a new one, standard practice against replay of a leaked refresh token.
- **`SessionController` (frontend) owns "who is logged in right now"; it does not own screen-local form state.** Login/Register/Forgot/Reset pages keep their own field-level state; only the authenticated-or-not session identity is centralized, consumed via `sessionControllerProvider` by anything that needs to know the current user/role.
- **`GoRouterRefreshNotifier` bridges Riverpod to Go Router's `refreshListenable`**, so the router's `redirect` re-evaluates reactively whenever session state changes (e.g. right after login/logout), not just on the next manual navigation attempt.

## 6. Security Decisions

- **Passwords are hashed with bcrypt** (`bcryptjs`, 10 salt rounds) — never stored or logged in plaintext.
- **`toPublicUser` strips `passwordHash`** on every response that serializes a user, including the account-settings endpoints and (from Phase 4) the admin user list.
- **Forgot-password does not leak account existence** — the endpoint returns the same success response whether or not the email is registered.
- **A password reset invalidates every existing session**, not just the one that requested it — all refresh tokens for the account are deleted alongside the used reset token.
- **Suspended accounts are rejected at login and at refresh**, not only at initial authentication — `AuthService.login()` and `AuthService.refresh()` both check `user.status === ACTIVE`. (Phase 4 later adds a per-request suspension check in `JwtStrategy` itself, for immediate effect mid-session — see `PHASE4_SUMMARY.md`.)

## 7. Known Limitations

- No email verification on signup — deferred to Post-Launch (V1.1) per the roadmap; any email format is accepted as-is at registration.
- No password complexity policy beyond a minimum length — acceptable for MVP, flagged as a launch-hardening candidate in the Release Readiness Audit.
- No rate limiting existed on `/auth/*` as of Phase 1 — added afterward as part of the pre-Phase-5 Release Readiness Audit fixes (see `RELEASE_AUDIT.md`).
- No UI test coverage was added for Phase 1's screens — matches the project's established pattern (see `PHASE3_SUMMARY.md` §7); the Flutter side has no widget-test suite beyond the Phase 0 smoke test.

## 8. Future Extension Points

- `RolesGuard`/`@Roles()` (added in this phase for the `/users/me` role-neutral endpoints) is the same generic guard Phase 3 later applies to `PLAYER`/`CLUB`-specific endpoints and Phase 4 applies to `ADMIN`-only endpoints — no new guard mechanism was needed at any later phase.
- The account-settings pattern (`change email`/`change password`, both requiring re-authentication of the current password for a password change) is the template for any future account-security feature.
