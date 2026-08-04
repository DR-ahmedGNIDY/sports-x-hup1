# Phase 4 Summary — Minimal Admin

**Status:** Phase 4 (Minimal Admin) implemented, reviewed, and committed. This document is the technical reference for what Phase 4 added — read alongside [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (scope/phases), [`PHASE0_SUMMARY.md`](PHASE0_SUMMARY.md) (baseline architecture), [`PHASE1_SUMMARY.md`](PHASE1_SUMMARY.md) (auth/roles), and [`PHASE3_SUMMARY.md`](PHASE3_SUMMARY.md) (the `RolesGuard` this phase reuses unchanged). Backfilled post-Phase-4 as part of the Release Readiness Audit; describes the codebase as implemented, not a plan — including the pagination fix that same audit applied to this module (see §7).

---

## 1. Features Implemented

- **View all Users**, suspend/activate a user, delete a user.
- **View all Players and Clubs** (read-only list) with the ability to remove a profile, including its Cloudinary assets (photos/videos or logo).
- Explicitly out of scope, per the roadmap: CRUD UI for Sports/Countries (seeded via script, Phase 2), a reports/flagging system, and a settings panel — none of these exist anywhere in the codebase.

## 2. APIs

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/admin/users` | ADMIN | Paginated (`?page=`), fixed page size 20; returns `{ items, page, pageSize, total }` |
| PATCH | `/admin/users/:id/status` | ADMIN | Sets `ACTIVE`/`SUSPENDED` — takes effect on the user's very next request (see §5) |
| DELETE | `/admin/users/:id` | ADMIN | Permanently deletes the user document |
| GET | `/admin/players` | ADMIN | Paginated, same shape as `/admin/users`; every profile regardless of visibility |
| DELETE | `/admin/players/:id` | ADMIN | Deletes the profile and every Cloudinary media asset it referenced |
| GET | `/admin/clubs` | ADMIN | Paginated, same shape |
| DELETE | `/admin/clubs/:id` | ADMIN | Deletes the profile and its Cloudinary logo asset, if any |

## 3. Database Changes

None — Admin reuses the `users`, `playerprofiles`, and `clubprofiles` collections from Phases 1–3 as-is. No new collection or schema was introduced.

## 4. Flutter Screens

- **Admin Users** (Desktop only) — table of all users with suspend/activate and delete actions.
- **Admin Players & Clubs** (Desktop only) — tabbed table view, one tab per profile type, with a remove action on each row.

Both screens are a deliberate, roadmap-sanctioned exception to the Desktop/Mobile fork every other feature follows: the roadmap explicitly states admin tooling does not need a mobile layout for V1, so neither screen goes through `ResponsiveLayout` — there is no `presentation/mobile/` for either.

## 5. Architecture Decisions

- **`AdminController` is deliberately thin — every handler calls straight into `UsersService`/`PlayersService`/`ClubsService` and reuses their existing mappers** (`toPublicUser`, `toOwnerView`, `toClubView`), per the roadmap's explicit design: "thin — reuses `Users`, `Players`, `Clubs` modules behind an admin guard." No admin-specific business logic or duplicate query logic was introduced; `findAllForAdmin()` on each service is the only admin-specific addition, and it exists on the feature's own service, not inside `AdminModule`.
- **`RolesGuard` needed no changes.** It was already generic over any `UserRole[]` when Phase 3 introduced it for `PLAYER`/`CLUB` gating; Phase 4 applies it to `/admin/*` with `@Roles(UserRole.ADMIN)` with zero modification to the guard itself.
- **Suspension takes effect immediately, not just after token expiry.** `JwtStrategy.validate()` (added in this phase) re-checks the live user record's `status` on every authenticated request, not only the token's signature/expiry — satisfying the Phase 4 acceptance criterion that a suspended user "immediately loses access," at the cost of one extra DB read per request (a documented, accepted tradeoff — see the Release Readiness Audit's Performance section).

## 6. Security Decisions

- **`ADMIN` cannot be created through the public API.** `RegisterDto` only accepts `PLAYER`/`CLUB` (Phase 1); the only way an `ADMIN` account is ever created is the operational script `npm run seed:admin` (`database/seed-admin.ts`), which upserts one account from `ADMIN_EMAIL`/`ADMIN_PASSWORD` environment variables and is never invoked by the running server.
- **Every `/admin/*` route is gated by both `JwtAuthGuard` and `RolesGuard` with `@Roles(UserRole.ADMIN)`**, applied once at the controller level (`@UseGuards(...)` + `@Roles(...)` on `AdminController` itself) rather than per-method — there is no route on this controller reachable without both checks passing.
- **Deleting a player or club profile also deletes its Cloudinary assets** (`deleteProfileAndMedia`, `deleteProfileAndLogo`) before removing the database document, so a moderation action doesn't leave orphaned media behind in the Cloudinary account.

## 7. Known Limitations

- **As originally shipped in Phase 4, all three admin list endpoints were fully unbounded** (no pagination, no limit) — flagged as a High-severity finding in the Release Readiness Audit (unbounded collection load at launch scale) and fixed as part of that audit's required remediation: all three now paginate (`?page=`, fixed page size 20) and the corresponding Flutter screens gained a "Load more" control plus an explicit empty state. This document describes the *current*, fixed state.
- Admin routes have no viewport guard — reachable (and visually broken, since `DataTable` isn't responsive) at mobile widths despite being "Desktop only" by design. Not fixed as of this writing; noted in the Release Readiness Audit as a Medium finding.
- No UI test coverage was added for Phase 4's screens — matches the project's established pattern (see `PHASE3_SUMMARY.md` §7).

## 8. Future Extension Points

- The Simple Contact pattern from Phase 3 (role-gated sub-resource endpoint, separate from the main view) remains the template if any Player/Club field ever needs to be admin-only-visible.
- The pagination envelope introduced by the audit fix (`{ items, page, pageSize, total }`) matches the shape `GET /players` (search) already used since Phase 3 — any future paginated admin or listing endpoint should follow the same shape for consistency.
