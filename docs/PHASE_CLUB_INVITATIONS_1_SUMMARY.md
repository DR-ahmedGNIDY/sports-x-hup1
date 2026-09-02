# Phase 1 — IDs, Data Model, Backend Foundation

Backend only. No frontend file was touched in this phase; Phases 2 and 3 have
not been started.

## What changed

1. **Public codes.** Clubs and players now each carry a shareable identifier —
   `CLB-000001` / `PLY-000001` — allocated from a shared atomic counter,
   assigned once and never rewritten. Neither existed before this phase; the
   audit in the plan document confirms there was no player code or club code
   anywhere in the codebase to reuse.
2. **Invitations.** A `club_player_invitations` collection with the full
   `PENDING → ACCEPTED / REJECTED / CANCELLED / EXPIRED` state machine in both
   directions (`CLUB_TO_PLAYER`, `PLAYER_TO_CLUB`).
3. **Memberships.** A `club_memberships` collection — the official
   relationship, created only by accepting an invitation. `ClubManagedPlayer`
   was deliberately not extended into this role (see the plan, §1); the new
   code only ever *reads* it, as a business-rule guard.
4. **REST surface.** Nine `/invitations` routes plus two `by-code` lookups,
   following the project's existing controller/service/mapper/DTO layout,
   guards, page-based pagination and throttle conventions.
5. **Backfill.** `npm run migrate:public-codes` assigns codes to profiles that
   predate the feature; it is idempotent and cannot renumber anyone.

Nothing was rebuilt. Auth, guards, validation, pagination, throttling, player
search and club listing are all the existing implementations, used as-is.

## Files changed

**New**

| File | Purpose |
| --- | --- |
| `backend/src/public-codes/schemas/counter.schema.ts` | Sequence documents. |
| `backend/src/public-codes/public-codes.service.ts` | Atomic allocation + code normalization/validation. |
| `backend/src/public-codes/public-codes.service.spec.ts` | 12 tests. |
| `backend/src/public-codes/public-codes.module.ts` | Shared by clubs + players. |
| `backend/src/invitations/schemas/club-player-invitation.schema.ts` | Invitation model + 7 indexes. |
| `backend/src/invitations/schemas/club-membership.schema.ts` | Membership model + 3 indexes. |
| `backend/src/invitations/dto/create-invitation.dto.ts` | Both send DTOs. |
| `backend/src/invitations/dto/list-invitations.dto.ts` | Inbox/outbox filter + page. |
| `backend/src/invitations/invitations.service.ts` | Business rules, state transitions, concurrency. |
| `backend/src/invitations/memberships.service.ts` | Membership lifecycle. |
| `backend/src/invitations/invitations.mapper.ts` | Response views + effective status. |
| `backend/src/invitations/invitations.controller.ts` | The REST surface. |
| `backend/src/invitations/invitations.module.ts` | Wiring. |
| `backend/src/invitations/invitations.service.spec.ts` | 30 tests. |
| `backend/src/invitations/memberships.service.spec.ts` | 7 tests. |
| `backend/src/invitations/invitations.mapper.spec.ts` | 9 tests. |
| `backend/src/clubs/clubs.service.spec.ts` | 6 tests (new file — clubs had no spec). |
| `backend/src/common/throttle.config.ts` | The two shared per-route limits. |
| `backend/src/database/migrate-public-codes.ts` | Backfill script. |
| `docs/CLUB_PLAYER_INVITATIONS_PLAN.md` | Architecture + audit + rationale. |

**Modified**

| File | Change |
| --- | --- |
| `backend/src/clubs/schemas/club-profile.schema.ts` | `publicCode` field (unique, sparse). |
| `backend/src/players/schemas/player-profile.schema.ts` | `publicCode` field (unique, sparse). |
| `backend/src/clubs/clubs.service.ts` | `ensurePublicCode`, `findByPublicCodeOrThrow`, `findByUserId`, `findManyByUserIds`; `PublicCodesService` injected. |
| `backend/src/players/players.service.ts` | `ensurePublicCode`, `findPublicByCodeOrThrow`, `findByUserId`; `PublicCodesService` injected. |
| `backend/src/clubs/clubs.controller.ts` | `GET /clubs/by-code/:code`. |
| `backend/src/players/players.controller.ts` | `GET /players/by-code/:code`. |
| `backend/src/clubs/clubs.mapper.ts` | `publicCode` in the club view. |
| `backend/src/players/players.mapper.ts` | `publicCode` in the public and search views. |
| `backend/src/clubs/clubs.module.ts`, `players.module.ts` | Import `PublicCodesModule`. |
| `backend/src/app.module.ts` | Register `InvitationsModule`. |
| `backend/src/players/players.service.spec.ts` | New constructor arg + 5 public-code tests. |
| `backend/package.json` | `migrate:public-codes` script. |

## API changes

All additive. No existing route changed shape beyond one new optional field.

| Method | Route | Auth | Throttle |
| --- | --- | --- | --- |
| `POST` | `/invitations/club-to-player` | CLUB | 10/min |
| `POST` | `/invitations/player-to-club` | PLAYER | 10/min |
| `GET` | `/invitations/received?status=&page=` | CLUB, PLAYER | default |
| `GET` | `/invitations/sent?status=&page=` | CLUB, PLAYER | default |
| `GET` | `/invitations/summary` | CLUB, PLAYER | default |
| `GET` | `/invitations/:id` | party only | default |
| `POST` | `/invitations/:id/accept` | recipient only | default |
| `POST` | `/invitations/:id/reject` | recipient only | default |
| `POST` | `/invitations/:id/cancel` | sender only | default |
| `GET` | `/clubs/by-code/:code` | authenticated | 20/min |
| `GET` | `/players/by-code/:code` | authenticated | 20/min |

Existing responses: `GET /clubs`, `/clubs/me`, `/clubs/:id` and every player
view now carry `publicCode` (a string, or absent until backfilled). Additive
only — no field was renamed or removed, and the Flutter client ignores unknown
keys, which is why `flutter analyze` and `flutter test` still pass untouched.

Invitation responses carry `canAccept` / `canReject` / `canCancel` for
rendering. These are a convenience for the client; every endpoint re-derives
the same rules server-side and never trusts them.

## Database changes

Two new collections, one supporting collection, two new fields.

- `club_player_invitations` — 7 indexes, including a **partial unique index on
  `{ clubUserId, playerUserId }` where `status: PENDING`** (one live
  invitation per pair, in either direction).
- `club_memberships` — 3 indexes, including a **partial unique index on
  `{ playerUserId }` where `status: ACTIVE`** (a player belongs to at most one
  club at a time).
- `counters` — one document per sequence.
- `clubprofiles.publicCode`, `playerprofiles.publicCode` — unique, sparse.

Both business rules are enforced by the database, not only by application
code, so a race cannot produce a state a single request would have refused.

**Deployment note:** indexes are created by Mongoose's `autoIndex` on startup,
as with every other collection in this project. Run
`npm run migrate:public-codes` after deploying so existing profiles are
searchable immediately rather than only after their owner next signs in.

## Security considerations

Reviewed against the OWASP items named in the brief.

**A01 Broken Access Control / IDOR.** Every invitation query pins one side to
the caller *inside the query* rather than checking ownership after fetching:
the inbox filters on `recipientUserId`, the outbox on `senderUserId`, single
lookups on `$or: [sender, recipient]`, and each state transition on the one
party entitled to make it. A caller who is not party to an invitation matches
nothing and receives the same `404` as one who invented the id — "not yours"
and "doesn't exist" are indistinguishable. `403` is used only where the caller
*is* a party and therefore may already read the record (e.g. a sender trying
to accept their own invitation), so it discloses nothing new. The failure
diagnosis that produces those errors is itself scoped to the caller's own
invitations, so it cannot be used as a probe.

**A03 Injection.** Every user-supplied value reaching a query is either
enum-validated (`status`), integer-validated (`page`), `@IsMongoId` +
`Types.ObjectId.isValid` (ids), or regex-normalized against
`^(CLB|PLY)-\d{6,}$` before use (codes). Operator-shaped input such as
`{"$ne": null}` cannot survive any of those paths; it is covered by a test.
Malformed input answers `404` without a database round-trip.

**A04 Insecure Design — mass assignment.** The DTOs accept only a counterpart
reference and an optional ≤500-character message. `type`, `status`,
`senderUserId`, `recipientUserId`, `clubUserId`, `playerUserId`, `expiresAt`
and `respondedAt` are all derived server-side; the global
`ValidationPipe({ whitelist: true })` strips anything else before the
controller sees it.

**A04 — race conditions.** MongoDB Atlas supports transactions but local
development runs standalone `mongod`, so this rests on atomic single-document
operations plus unique indexes, which behave identically on both:
- Simultaneous sends → partial unique index on the pending pair → the loser
  gets `409`.
- Two clubs' invitations accepted at the same instant → partial unique index
  on the active membership. Exactly one wins; the loser's invitation is rolled
  back to `PENDING` (guarded on the status this request itself wrote, so it
  can never resurrect an invitation somebody else has resolved) and answers
  `409`.
- Double-accept → the accept is one guarded `findOneAndUpdate` on
  `{ _id, recipientUserId, status: PENDING, expiresAt: $gt now }`. The second
  attempt matches nothing.
- Accepting a membership cancels the player's other pending invitations in one
  `updateMany`, so no invitation survives that could no longer be honoured.

**A05 Security Misconfiguration.** No new configuration, no new environment
variable, no new dependency. Helmet, CORS and the global throttler are
unchanged.

**A07 Authentication Failures.** Every new route requires a valid JWT. The two
`by-code` lookups are authenticated even though the equivalent `:id` routes
are public — a deliberate tightening, since sequential codes make bulk lookups
cheap.

**A09 Logging/Monitoring.** *Gap, unchanged from the rest of the project:*
there is no audit trail beyond Nest's default error logging. Invitation state
transitions are self-documenting in the data (`respondedAt`, and each
membership records the `invitationId` that produced it), but there is no
security event log. Noted as a limitation rather than silently addressed —
building one is a platform-wide concern, not this feature's.

**Enumeration.** Sequential codes are enumerable by design (the requested
format). They expose nothing new: `GET /players` and `GET /clubs` are already
unauthenticated paginated listings of exactly these profiles. Mitigated by
requiring a JWT and a 20/min limit on both lookups, and the player lookup
still honours `visibility: PUBLIC` — a code is not a way around a private
profile, which is covered by a test.

**Information disclosure.** Invitation views carry name, photo, sport,
position, code and club identity — never contact details, which stay behind
the existing club-only `GET /players/:id/contact`. A test asserts the phone
and email never appear in a serialized invitation view. One deliberate
disclosure: a player with a `PRIVATE` profile who sends a join request reveals
their own summary to that club. That is the player's own act of applying, and
it is limited to the same non-contact summary.

**Rate limiting.** Sends 10/min per account, code lookups 20/min; everything
else inherits the global 100/min.

### Defect found and fixed during this review

The duplicate-pending unique index does not know about expiry, so a lapsed
invitation whose stored status was still `PENDING` would have permanently
barred that club and player from ever trying again — the sweep is
maintenance-only and nothing guarantees it has run. Sending now expires any
lapsed invitation for that specific pair first (one indexed update, not a
sweep). Covered by a test.

## Tests

All commands were run; output below is real.

```
backend:  npm run build   → clean
backend:  npx jest        → 18 suites, 166 tests passed (was 13 suites / 94)
frontend: flutter analyze → No issues found!
frontend: flutter test    → All tests passed (132)
```

72 new tests. Coverage of the brief's checklist:

| Required case | Where |
| --- | --- |
| Club sends invitation to player | `invitations.service.spec.ts` |
| Player sends invitation to club | `invitations.service.spec.ts` |
| Duplicate invitation blocked | duplicate-key → `409` |
| Invitation accepted (membership created) | accept + membership assertions |
| Invitation rejected | reject scoped to recipient, no membership |
| Invitation cancelled | cancel scoped to sender |
| Wrong recipient cannot accept | sender accepting → `403` |
| Wrong recipient cannot reject | sender rejecting → `403` |
| Unrelated user cannot access invitation | `404`, and the diagnosis is scoped |
| Already-member cannot receive invitation | active-membership → `409` (own club and other club) |
| Invalid ID blocked | malformed id → `404` with no database call |
| Role restrictions | `roles.guard.spec.ts` (existing) + `@Roles` per route |
| Rate limiting | declared per route; the throttler itself is framework-tested |
| Race conditions | membership conflict → rollback + `409`; double-accept guarded |

Rate limiting and authentication are enforced by guards applied
declaratively, exercised by the framework's own tests and by the existing
`roles.guard.spec.ts`; this project has no HTTP-level e2e harness, so those
are asserted at the decorator/guard level rather than over the wire. That is
the honest limit of what was verified.

## Known limitations

1. **No membership read endpoints yet.** The schema, indexes and service
   methods exist (`listActiveForClub`, `countActiveForClub`,
   `findActiveForPlayer`, `end`), but no route exposes them — deliberately
   deferred to the phase whose UI consumes them, so nothing ships without a
   caller. "Club Profile → Players" and "Player Profile → Current Club" are
   Phase 2/3 work.
2. **No frontend.** Phase 1 is backend only; no l10n keys were added because
   no user-facing string was introduced.
3. **Crash window on accept.** Without transactions, a process death between
   claiming the invitation and inserting the membership leaves an `ACCEPTED`
   invitation with no membership. The ordering is deliberate: it fails safe
   (no relationship without a recorded acceptance) rather than the reverse.
4. **Expiry sweep is not scheduled.** `markExpired` exists but nothing calls
   it — no scheduler exists in this project and adding one is out of scope.
   Nothing depends on it: reads compute the effective status, transitions
   filter on `expiresAt`, and sending clears a lapsed slot for its own pair.
5. **`ClubManagedPlayer` accounts cannot be recruited.** A club-created
   account already belongs to the club that created it, so it is excluded from
   invitations rather than being given two conflicting notions of "belongs
   to". If the product wants those rosters unified, the right move is a
   deliberate backfill of memberships from ownership rows — not a change to
   the guard.
6. **Pre-existing lint failure, untouched.** `npm run lint` fails on
   `src/videos/videos.service.ts:26` (`'VideoCommentDocument' is defined but
   never used`). `git diff` confirms that file is unmodified by this phase —
   it is a pre-existing error on `main`. Linting scoped to this phase's files
   passes cleanly. Left alone rather than fixed silently, since it is outside
   this work; say the word and it is a one-line fix.

## Git status

**No commit was made.** Nothing was staged, committed or pushed.

```
 M backend/package.json
 M backend/src/app.module.ts
 M backend/src/clubs/clubs.controller.ts
 M backend/src/clubs/clubs.mapper.ts
 M backend/src/clubs/clubs.module.ts
 M backend/src/clubs/clubs.service.ts
 M backend/src/clubs/schemas/club-profile.schema.ts
 M backend/src/players/players.controller.ts
 M backend/src/players/players.mapper.ts
 M backend/src/players/players.module.ts
 M backend/src/players/players.service.spec.ts
 M backend/src/players/players.service.ts
 M backend/src/players/schemas/player-profile.schema.ts
?? backend/src/clubs/clubs.service.spec.ts
?? backend/src/common/throttle.config.ts
?? backend/src/database/migrate-public-codes.ts
?? backend/src/invitations/
?? backend/src/public-codes/
?? docs/CLUB_PLAYER_INVITATIONS_PLAN.md
?? docs/PHASE_CLUB_INVITATIONS_1_SUMMARY.md
```

Also present in the working tree but **not part of this phase** — they were
already modified/untracked before it started: `backend/.env.example`,
`backend/src/auth/auth.module.ts`, `backend/src/config/env.validation.ts`,
`backend/src/auth/mail/brevo-api-email.provider.ts`, `docs/SECURITY_AUDIT.md`.

## Stop point

Phase 1 is complete and verified. Phase 2 (Club experience) has not been
started, per the brief.
