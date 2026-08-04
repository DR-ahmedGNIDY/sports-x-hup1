# Phase 2 Summary — Player Profile (incl. Contact Details)

**Status:** Phase 2 (Player Profile) implemented, reviewed, and committed. This document is the technical reference for what Phase 2 added — read alongside [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (scope/phases), [`PHASE0_SUMMARY.md`](PHASE0_SUMMARY.md) (baseline architecture) and [`PHASE1_SUMMARY.md`](PHASE1_SUMMARY.md) (auth this phase builds on). Backfilled post-Phase-4 as part of the Release Readiness Audit; describes the codebase as implemented, not a plan.

---

## 1. Features Implemented

- **Personal information** — name, date of birth, nationality, country, city.
- **Sports information** — sport, position, preferred foot, height, weight, current status/club.
- **Photo upload (profile photo + gallery) and video upload**, both via Cloudinary — MongoDB stores only `publicId`/`secureUrl`, never binary data.
- **Achievements** — simple list of `{ title, year, description }`.
- **Social links** — `{ platform, url }` pairs (Instagram, YouTube, X, etc.).
- **Contact details** — phone, email, WhatsApp, stored on the profile but never exposed on the public read endpoint (see Security Decisions).
- **Visibility** — binary `PUBLIC`/`PRIVATE` toggle; Private immediately removes the profile from `GET /players/:id` and search.
- **Public player profile page** — read-only, shareable URL, respects visibility.

## 2. APIs

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/players/me` | PLAYER | Auto-creates an empty profile on first call (`getOrCreateForUser`) |
| PATCH | `/players/me` | PLAYER | Partial update of scalar fields + `contact` |
| POST | `/players/me/media` | PLAYER | Multipart upload → Cloudinary; `type: PHOTO\|VIDEO`, optional `isProfilePhoto` |
| DELETE | `/players/me/media/:id` | PLAYER | Deletes the Cloudinary asset by `publicId`, then removes the embedded subdocument |
| POST/PATCH/DELETE | `/players/me/achievements[/:id]` | PLAYER | CRUD on the embedded `achievements` array |
| POST/PATCH/DELETE | `/players/me/social-links[/:id]` | PLAYER | CRUD on the embedded `socialLinks` array |
| PATCH | `/players/me/visibility` | PLAYER | Sets `PUBLIC`/`PRIVATE` |
| GET | `/players/:id` | public | 404s unless the profile is `PUBLIC`; never returns `contact` |

`GET /players/:id/contact` (Simple Contact, CLUB-only) is a Phase 3 addition — see `PHASE3_SUMMARY.md`.

## 3. Database Changes

- **New collection `playerprofiles`** — one document per player, `userId` unique-indexed (`ref: User`). Media, achievements, and social links are embedded subdocuments (not separate collections): each array is small, bounded per player, and always read/written together with the profile — the pattern that would justify a separate collection (unbounded growth, independent access patterns) doesn't apply here.
- **New lookup collections `sports`** (`{ name (unique) }`) and **`countries`** (`{ name, code (unique) }`), both seeded via script (`npm run seed`), read-only from the API (`GET /sports`, `GET /countries`) — no CRUD endpoints, matching the roadmap's explicit Phase 4 callout that Sports/Countries CRUD is out of scope for V1.
- **Indexes for scale**: compound `{ sport: 1, position: 1, country: 1 }` for the most common search combination, plus individual indexes on `visibility`, `preferredFoot`, `height`, `weight`. (The `dateOfBirth` index and the age-range search filter were added in Phase 3, once age became one of the 7 search filters — see `PHASE3_SUMMARY.md`.)

## 4. Flutter Screens

- **Edit Profile** — Desktop (multi-column sectioned form) and Mobile (accordion form), both composed from the same set of section widgets (personal info, sports info, bio/contact, media, achievements, social links, visibility).
- **My Profile Preview** — the owner's own read-only view, including fields a public visitor wouldn't see (contact, visibility state).
- **Public Player Profile** (Desktop + Mobile) — the shareable, visibility-respecting read view; gains a Simple Contact section and save/bookmark toggle in Phase 3.

## 5. Architecture Decisions

- **Cloudinary is the single source of truth for binary media.** `CloudinaryService.uploadBuffer()` streams the multipart file buffer directly to Cloudinary and returns only `{ publicId, secureUrl }`; MongoDB never stores raw binary. Deleting a media item calls `CloudinaryService.deleteAsset(publicId, resourceType)` before removing the embedded subdocument, so orphaned Cloudinary assets aren't left behind.
- **`getOrCreateForUser` is the standard access pattern** for a player's own profile — every `/players/me*` endpoint resolves the target document from the JWT's `sub`, creating an empty profile on first touch rather than requiring an explicit "create profile" step. Clubs later reuse the identical pattern for their own profile (Phase 3).
- **Mapper functions (`players.mapper.ts`) are the single point that decides field exposure** — `toOwnerView` (full, including `contact`/`visibility`), `toPublicView` (everything except `contact`), and `toSearchResultView` (a lean ~9-field projection for result lists) all read from the same Mongoose document but never leak more than their name promises.

## 6. Security Decisions

- **`GET /players/:id` never returns `contact`**, even though the endpoint is otherwise public once a profile is `PUBLIC` — `toPublicView` deliberately omits it, closing off any path for an anonymous scraper to harvest phone/email/WhatsApp. The only path to `contact` is the CLUB-only Simple Contact endpoint added in Phase 3.
- **Visibility is checked at the query/service layer, not just hidden in the UI** — `findPublicByIdOrThrow` 404s for a non-`PUBLIC` profile regardless of caller, so a private profile is unreachable by guessing its id, not merely unlisted.
- **Ownership is implicit and unspoofable** — every `/players/me*` endpoint derives its target profile from the JWT's `sub`; there is no code path where a request can act on another player's profile by id.

## 7. Known Limitations

- File-size and MIME-type limits on media uploads did not exist as of Phase 2 — added afterward as part of the pre-Phase-5 Release Readiness Audit fixes (see `RELEASE_AUDIT.md`).
- `PATCH /players/me`'s handling of the nested `contact` object had a shallow-merge bug (a partial `contact` update could silently wipe previously saved fields) — introduced in this phase, found and fixed as part of the Release Readiness Audit (see `RELEASE_AUDIT.md`).
- No UI test coverage was added for Phase 2's screens — matches the project's established pattern (see `PHASE3_SUMMARY.md` §7).

## 8. Future Extension Points

- The `getOrCreateForUser` / mapper-function-per-view pattern established here is reused as-is by Clubs in Phase 3 (`ClubsService.getOrCreateForUser`, `clubs.mapper.ts`).
- `playerprofiles`' embedded-subdocument design (media/achievements/socialLinks) is the template for any future small, bounded, profile-owned array — no new collection is introduced for data that fits this shape.
