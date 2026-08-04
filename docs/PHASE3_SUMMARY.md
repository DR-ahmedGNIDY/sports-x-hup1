# Phase 3 Summary — Clubs, Player Search & Saved Players

**Status:** Phase 3 (Club Profile, Player Search, Save Player & Simple Contact) implemented, reviewed, and committed. This document is the technical reference for what Phase 3 added — read alongside [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (scope/phases) and [`PHASE0_SUMMARY.md`](PHASE0_SUMMARY.md) (baseline architecture, still accurate).

---

## 1. Features Implemented

- **Club Profile** — name, country, city, logo (Cloudinary), description, founded year, level. Own profile (auto-created on first access, same pattern as Player) + public read view.
- **Player Search** — Club-facing search over public player profiles with 7 filters (Country, Age, Position, Height, Weight, Preferred Foot, Sport) and pagination.
- **Save Player** — a Club can bookmark a player from search results or the player's public profile; a dedicated Saved Players list shows everything saved.
- **Simple Contact** — a logged-in Club sees WhatsApp / Email / Phone actions on a player's public profile. No in-app messaging, no conversation history — matches the roadmap's explicit "Simple Contact" scope.
- **Role-based authorization** — a reusable `@Roles()` / `RolesGuard` pair now gates every role-specific endpoint, including retrofitting Players' own `/players/me*` endpoints (a latent gap from Phase 2, where a Club could otherwise create a spurious player profile of its own).

## 2. APIs

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/clubs/me` | CLUB | Auto-creates an empty profile on first call |
| PATCH | `/clubs/me` | CLUB | Partial update |
| POST | `/clubs/me/logo` | CLUB | Multipart upload → Cloudinary; replaces and deletes the previous logo asset |
| GET | `/clubs/:id` | public | No private fields on a club profile — safe to expose unauthenticated |
| GET | `/players?country=&minAge=&maxAge=&position=&minHeight=&maxHeight=&weight=&preferredFoot=&sport=&page=` | public | PUBLIC-visibility players only; page size fixed at 20 |
| GET | `/players/:id/contact` | CLUB | 404s if the player isn't PUBLIC — private contact stays private even from Clubs |
| POST | `/saved-players/:playerId` | CLUB | 404s if the player isn't public; 409 if already saved (DB-level unique index, not just app logic) |
| DELETE | `/saved-players/:playerId` | CLUB | 404 if nothing was saved |
| GET | `/saved-players/me` | CLUB | Returns the lean search-result shape, silently drops any saved player that has since gone private |

`GET /players/:id` (Phase 2) is unchanged and still never returns `contact` — Simple Contact is the only path to it, and only for an authenticated Club.

## 3. Database Changes

- **New collection `clubprofiles`** — `{ userId (unique), name, country (indexed), city (indexed), logo: { publicId, secureUrl }, description, foundedYear, level }`.
- **New collection `savedplayers`** — `{ clubUserId, playerId, createdAt }`.
  - Compound **unique** index `{ clubUserId: 1, playerId: 1 }` — the actual duplicate-save guard (app-level catch on the resulting Mongo error just turns it into a 409).
  - Standalone index on `playerId` only (reverse lookups, e.g. "how many clubs saved this player"). No standalone index on `clubUserId` — it's already the compound index's leading field, so the Saved Players list query (`find({ clubUserId })`) uses it as a prefix for free; a second index there would just be duplicate write overhead.
- **`playerprofiles.dateOfBirth` is now indexed.** Age (minAge/maxAge) is one of the 7 search filters and wasn't covered by the Phase 2 compound index `{ sport, position, country }` — without this, an age-only search would force a full collection scan at the "hundreds of thousands of players" scale the roadmap targets.

## 4. Flutter Screens

All screens follow the established Desktop/Mobile fork — two independent widget trees per screen, sharing only `domain/data/application`.

- **Edit Club Profile** (Desktop: two-card layout / Mobile: stacked sections)
- **My Club** (read-only preview of the owner's own club)
- **Search Players** (Desktop: filter sidebar + result grid / Mobile: filter bottom sheet + card list), with pagination controls
- **Saved Players** (Desktop: grid / Mobile: list) — reuses the same result card as Search
- **Public Player Profile** (Phase 2) gained two additions, both gated on `sessionControllerProvider`'s role and rendering nothing for a Player or signed-out visitor: a Simple Contact section and a save/bookmark toggle in the app bar

## 5. Architecture Decisions

- **`PlayerSearchResult` lives in the Player feature**, not Search or Saved Players. It's fundamentally player data (a lean projection), and both Search and Saved Players consume it — putting it in either of those two would have made the other import across a feature boundary for no reason.
- **`runAuthorized` extracted to `core/network`.** Phase 2 had one repository (`PlayerRepositoryImpl`) doing token-attach + one-shot refresh-and-retry on 401. Phase 3 needed the identical logic in two more repositories (`ClubRepositoryImpl`, `SavedPlayersRepositoryImpl`), so it was pulled out to `core/network/authorized_request.dart` rather than copied a second and third time.
- **`SavedPlayersController` doubles as both the Saved Players list's data source and the save/unsave state every result card checks.** One fetch on load, then local list edits (`AsyncData([player, ...current])` / filtered removal) on every save/unsave — avoids a full refetch per toggle. `toggleSavedPlayer()` (in `saved_players/presentation/shared/`) centralizes the try/catch + SnackBar error handling so it isn't duplicated between the search-result card and the public-profile save button.
- **Search's lean response shape (`toSearchResultView` on the backend, `PlayerSearchResult` on the frontend)** intentionally excludes achievements/social links/full media — a results grid of potentially hundreds of players doesn't need each row's full profile payload.
- **`publicClubProfileProvider` was deliberately not built.** Nothing in Phase 3's screens needs "view another club's profile" (My Club is the owner's own read-only view, not a public-facing route) — `GET /clubs/:id` exists on the backend for Phase 5's public listings to consume later, but the matching frontend capability isn't added until something actually calls it.

## 6. Security Decisions

- **Role gating is enforced on every role-specific endpoint**, verified directly (not just by code inspection): a Player token gets 403 on Club endpoints, a Club token gets 403 on Player endpoints, and an unauthenticated request gets 401 on anything requiring a session.
- **Ownership is implicit and unspoofable.** Every "me" endpoint (Club or Player) derives its target document from the JWT's `sub`, never from a client-supplied id — there is no code path where one user's request can act on another user's data.
- **Simple Contact has two independent gates, not one.** `@Roles(UserRole.CLUB)` blocks non-Clubs at the guard level; `findPublicByIdOrThrow` inside the handler additionally 404s if the target player isn't PUBLIC — so a Club cannot pull a private player's contact info even though it can authenticate as a Club.
- **Saving a player probes nothing.** `SavedPlayersService.save()` calls the same visibility-gated lookup before creating the save record, so attempting to save a private or nonexistent player id returns the same 404 either way — it can't be used to detect which player ids exist.

## 7. Known Limitations

- Search pagination uses a fixed page size (20); a page has no total-time-bound guarantee at very large data volumes beyond what the current index set provides — acceptable for the roadmap's 10k-document acceptance criterion, not benchmarked beyond it.
- `weight` in search is an exact match, not a range — this matches the roadmap's query-parameter spec (`weight=`, no `minWeight`/`maxWeight`) exactly; height *is* a range (`minHeight`/`maxHeight`) per the same spec. This asymmetry is intentional, not an oversight.
- The Saved Players list re-sorts by `createdAt` in memory after an index-backed fetch (no index covers the sort). Fine at the scale of one Club's saved list; would need revisiting only if a "sort saved players" feature at scale is ever added.
- No UI test coverage was added for the new frontend features in this phase (matches Phase 1/2 precedent — the Flutter side has no widget-test suite yet, only `flutter analyze` + manual/API verification).

## 8. Future Extension Points

- `GET /clubs/:id` is already implemented and ready for Phase 5's "Public Clubs listing" — only the frontend read path needs adding then.
- The Simple Contact pattern (role-gated sub-resource endpoint, separate from the public profile) is the template Phase 4's Admin views can follow if any Player/Club field ever needs to be admin-only-visible.
- `RolesGuard` is already generic over any `UserRole[]` — Phase 4's Admin endpoints reuse it directly with `@Roles(UserRole.ADMIN)`, no new guard needed.
