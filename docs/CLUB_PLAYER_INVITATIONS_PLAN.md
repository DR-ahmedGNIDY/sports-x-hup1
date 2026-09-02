# Club ↔ Player Invitations & Recruitment System — Plan

Status: Phases 1 (backend foundation) and 2 (Club experience) implemented.
Phase 3 not started.

## 1. What already exists (audit before design)

The audit below is the reason almost nothing in this feature is rebuilt from
scratch — every entry on the right is an existing thing this system reuses.

| Concern | Existing implementation | Decision |
| --- | --- | --- |
| Accounts | `users` — `User { email?, phone?, passwordHash, role: PLAYER/CLUB/ADMIN, status }` | Reused as-is. No new account model. |
| Player profile | `playerprofiles` — `PlayerProfile { userId (unique), …, visibility: PUBLIC/PRIVATE }` | Reused. One new field: `publicCode`. |
| Club profile | `clubprofiles` — `ClubProfile { userId (unique), name, country, city, logo, … }` | Reused. One new field: `publicCode`. |
| Club-created players | `club_managed_players` — `ClubManagedPlayer { userId (globally unique), clubId, dialCode }` | **Not** the membership model. It is an *account-ownership* record: "this club created this login". Left untouched, but read as a guard (see §5). |
| Favourites | `savedplayers` — `SavedPlayer { clubUserId, playerId }` | Unrelated bookmark. Untouched. |
| Player search | `GET /players` (paginated, `visibility: PUBLIC` only) | Reused; a code lookup is added alongside it. |
| Club listing | `GET /clubs` (paginated, public) | Reused; a code lookup is added alongside it. |
| Auth | Passport JWT → `JwtAuthGuard`, `RolesGuard` + `@Roles()`, `@CurrentUser()` | Reused verbatim. |
| Rate limiting | Global `ThrottlerGuard` (100/min) with per-route `@Throttle()` overrides | Reused; stricter overrides on the new write/lookup routes. |
| Validation | Global `ValidationPipe({ whitelist: true, transform: true })` + class-validator DTOs | Reused (this is also the mass-assignment defence). |
| Pagination | Page-based `{ items, page, pageSize, total }`, page size 20 | Reused verbatim. |
| Notifications | **None exists** anywhere in backend or frontend | Nothing built. In-app invitation state only, per the brief. |
| Public IDs | **None exists.** No player code, no club code — only the Mongo `ObjectId`. | New — see §2. |

### Why `ClubManagedPlayer` is not extended into a membership model

It answers a different question. `ClubManagedPlayer.userId` is globally
unique, meaning "an account may be *created by* at most one club, ever" — an
irreversible provenance fact. A membership is a *revocable affiliation* a
player can leave and re-form with another club. Overloading one document with
both would make "remove from club" ambiguous (does the login die?) and would
break the existing club-players endpoints, every one of which reads this row
as an authorization check. So membership gets its own collection, and
`ClubManagedPlayer` is only *read* by the new code, never written.

## 2. Public IDs

Two new fields, one shared allocator.

- `ClubProfile.publicCode` — `CLB-000001`
- `PlayerProfile.publicCode` — `PLY-000001`

Properties: unique (`unique: true, sparse: true`), assigned once and never
rewritten, safe to print on a public profile, and it does not expose the Mongo
`ObjectId`. Lookup is a single-field indexed equality query, never a scan.

Allocation is a `counters` collection (`{ _id: 'CLB' | 'PLY', seq }`) driven by
one atomic `findOneAndUpdate($inc, { upsert: true, new: true })`, so two
concurrent signups can never receive the same number. Assignment is lazy
(`ensurePublicCode` on the profile's own `getOrCreate` path) plus a one-time
backfill script for rows created before this feature — no fabricated data, and
no second identifier where one would do.

**Trade-off, accepted deliberately:** sequential codes are enumerable. This
discloses nothing that is not already public — `GET /players` and `GET /clubs`
are unauthenticated, paginated listings of exactly these profiles — so the code
adds convenience, not exposure. It is still mitigated: both `by-code` lookups
require a JWT and carry a tighter throttle than the global default, and the
player lookup obeys the same `PUBLIC`-only rule as the rest of player search.

## 3. Data model

### `club_player_invitations`

| Field | Type | Notes |
| --- | --- | --- |
| `type` | `CLUB_TO_PLAYER` / `PLAYER_TO_CLUB` | Direction. |
| `status` | `PENDING` / `ACCEPTED` / `REJECTED` / `CANCELLED` / `EXPIRED` | See §4. |
| `clubUserId` | ObjectId → `User` | Canonical pair, direction-independent. |
| `playerUserId` | ObjectId → `User` | Canonical pair, direction-independent. |
| `senderUserId` | ObjectId → `User` | Derived from `type` on the server. |
| `recipientUserId` | ObjectId → `User` | Derived from `type` on the server. |
| `message` | string ≤ 500, optional | The only free-text field a client may set. |
| `expiresAt` | Date | Default now + 30 days. |
| `respondedAt` | Date, optional | Set on accept/reject. |
| `createdAt` / `updatedAt` | Date | Mongoose timestamps. |

Both the canonical pair *and* the sender/recipient pair are stored. The pair
makes "is there already something between this club and this player?" one
indexed lookup regardless of direction; sender/recipient makes the inbox and
outbox queries a straight index prefix. Sender and recipient are always
computed from `type` server-side — never accepted from the request body.

Indexes:

- `{ recipientUserId, status, createdAt: -1 }` — inbox.
- `{ senderUserId, status, createdAt: -1 }` — outbox.
- `{ clubUserId, playerUserId, createdAt: -1 }` — relationship history (a bare pair would duplicate the partial unique index below; this still covers the pair as a prefix).
- `{ type, status }` — analytics/moderation.
- `{ createdAt: -1 }` — time-ordered sweeps.
- `{ status, expiresAt }` — the expiry sweep.
- **`{ clubUserId, playerUserId }` unique, partial on `status: PENDING`** — the
  duplicate-pending rule, enforced by the database rather than by a
  read-then-write in application code. Direction-independent on purpose: one
  live conversation per club/player pair at a time.

### `club_memberships`

| Field | Type | Notes |
| --- | --- | --- |
| `clubUserId` | ObjectId → `User` | |
| `playerUserId` | ObjectId → `User` | |
| `status` | `ACTIVE` / `ENDED` | |
| `invitationId` | ObjectId → invitation | Provenance of the relationship. |
| `joinedAt` / `endedAt?` | Date | |

Indexes:

- **`{ playerUserId }` unique, partial on `status: ACTIVE`** — the product rule
  "a player belongs to at most one club at a time", enforced by the database.
  This is also the race-condition defence (§6).
- `{ clubUserId, status, joinedAt: -1 }` — a club's roster page.
- `{ playerUserId, status }` — a player's club history.

## 4. State machine

```
                     ┌─────────► ACCEPTED   recipient accepts → membership created
                     │
PENDING ─────────────┼─────────► REJECTED   recipient rejects
   │                 │
   │                 └─────────► CANCELLED  sender withdraws, or superseded by
   │                                        the player joining a club
   └───────────────────────────► EXPIRED    expiresAt passed
```

Every other transition is impossible. `ACCEPTED`, `REJECTED`, `CANCELLED` and
`EXPIRED` are terminal. `WITHDRAWN` was considered and rejected: "the sender
took it back" is exactly `CANCELLED`, and a second name for one state would
only create a second thing to check everywhere.

Expiry is evaluated, not swept: a `PENDING` row past `expiresAt` reads as
`EXPIRED` in every view, and every accept/reject query carries
`expiresAt: { $gt: now }`, so an expired invitation cannot be acted on even if
a sweep has never run. A `markExpired` maintenance method exists for making the
stored status match, but nothing depends on it having run.

## 5. Business rules

Sending is refused when:

1. The sender's role does not match the direction (`CLUB` may only send
   `CLUB_TO_PLAYER`, `PLAYER` only `PLAYER_TO_CLUB`) — role guard *and* a
   service-level check.
2. Sender and recipient are the same user.
3. The target does not exist, or (for a player) is not `PUBLIC`.
4. A `PENDING` invitation already exists between the pair, in either direction.
5. The player already has an `ACTIVE` membership — with this club, or with any
   other club (one club at a time).
6. The player is a `ClubManagedPlayer` of some club — that account already
   belongs to a club by construction, and letting it be recruited away would
   put the two models in conflict.

Responding is refused when:

7. The caller is not the `recipientUserId` (accept/reject) or not the
   `senderUserId` (cancel).
8. The invitation is not `PENDING`, or has expired.
9. The id is not a valid ObjectId, or belongs to an invitation the caller is
   neither party to — both answer `404`, never "exists but not yours".

## 6. Concurrency

MongoDB Atlas would support transactions, but local development runs a
standalone `mongod` where they are unavailable — so correctness here rests on
**atomic single-document operations plus unique indexes**, which behave
identically on both:

- Sending races → the partial unique index on the pending pair. The loser's
  duplicate-key error becomes a `409`.
- Two clubs' invitations accepted at the same instant → the partial unique
  index on `{ playerUserId }` where `ACTIVE`. Exactly one membership is
  created; the loser's insert fails and its invitation is rolled back to
  `PENDING`.
- Double-accept of one invitation → the accept is a single guarded
  `findOneAndUpdate({ _id, recipientUserId, status: PENDING, expiresAt: $gt })`.
  The second caller matches nothing.
- On a successful accept, every other `PENDING` invitation naming that player
  is moved to `CANCELLED` in one `updateMany`, so a player never keeps
  invitations that could no longer be accepted.

## 7. API surface

| Method | Route | Auth | Notes |
| --- | --- | --- | --- |
| `POST` | `/invitations/club-to-player` | CLUB | body `{ playerCode? \| playerId?, message? }` |
| `POST` | `/invitations/player-to-club` | PLAYER | body `{ clubCode? \| clubId?, message? }` |
| `GET` | `/invitations/received` | PLAYER, CLUB | `?status=&page=` |
| `GET` | `/invitations/sent` | PLAYER, CLUB | `?status=&page=` |
| `GET` | `/invitations/summary` | PLAYER, CLUB | pending counts, for badges |
| `GET` | `/invitations/:id` | party only | |
| `POST` | `/invitations/:id/accept` | recipient only | |
| `POST` | `/invitations/:id/reject` | recipient only | |
| `POST` | `/invitations/:id/cancel` | sender only | |
| `GET` | `/clubs/by-code/:code` | any authenticated | registered before `/clubs/:id` |
| `GET` | `/players/by-code/:code` | any authenticated | registered before `/players/:id` |

## 8. Phasing

- **Phase 1** — public codes, both schemas, invitation and membership
  services, the REST surface above, unit tests, backfill script.
- **Phase 2** — Club UI: invite from a player profile, search by player code,
  Club Invitations screen (Received/Sent), club code + copy on the profile.
- **Phase 3** — Player UI: request to join from a club profile, search by club
  code, Player Invitations screen, and the membership display on both public
  profiles.

Membership *read* endpoints (a club's roster, a player's current club) are
deliberately deferred to the phase whose UI consumes them, so nothing ships
without a caller.
