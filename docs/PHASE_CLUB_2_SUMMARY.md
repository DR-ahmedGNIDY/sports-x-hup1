# Phase Club 2 Summary — Managed Player Management & Club Level

**Status:** Phase 2 of 3 implemented, following [`PHASE_CLUB_1_SUMMARY.md`](PHASE_CLUB_1_SUMMARY.md). Scope: let a Club view/edit/resend-credentials/remove a player it created, and replace `ClubProfile.level`'s free text with a controlled, backward-compatible set of values. Ownership enforcement stays exactly where it already lived (`ClubPlayersService.requireOwnership`) — nothing about that check was touched, only reused.

---

## 1. API Changes

| Method | Path | Change |
|---|---|---|
| `PATCH` | `/club-players/:playerId` | **Unchanged** — already existed since Phase Club 1's exploration; this phase adds its first frontend consumer. Ownership-checked via `requireOwnership`. |
| `DELETE` | `/club-players/:playerId` | **New.** Removes only the `ClubManagedPlayer` ownership record; the `User` account and `PlayerProfile` are untouched. Ownership-checked the same way as every other endpoint on this controller. Returns `204 No Content`. |
| `PATCH` | `/clubs/me` | **Unchanged route**, tightened validation: `level` now requires one of `ClubLevel`'s three values (`amateur` / `semi_professional` / `professional`) instead of accepting arbitrary text. Omitting `level` entirely still works exactly as before. |

No other endpoints changed. `GET /club-players/:playerId` and `POST /club-players/:playerId/photo` (both already existed) got their first frontend consumers too, via the new Edit Managed Player page.

## 2. Database Changes

**None.** `ClubManagedPlayer` schema is unchanged — `removeFromClub` just deletes the existing ownership document (`deleteOne({ _id: ownership._id })`), it doesn't add or rename any field. `ClubProfile.level` also keeps its existing `String` schema type on purpose — see §5 for why a schema-level enum was deliberately avoided.

## 3. Security Changes

- **`DELETE /club-players/:playerId` reuses the exact same `requireOwnership(clubId, userId)` check** every other club-players endpoint already used — a Club can only remove a player it created; a lookup miss throws `ForbiddenException`, matching `update`/`uploadPhoto`/`resendCredentials`.
- **No new attack surface**: the new endpoint sits under the controller's existing `@UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CLUB)`, unauthenticated or non-Club callers are rejected before the handler ever runs, same as the rest of the controller.
- **Backend test coverage added** (`club-players.service.spec.ts`): removing an owned player calls `deleteOne` with only the ownership id (never touches the `User`/`PlayerProfile` collections), and removing a player another club owns throws `ForbiddenException`. Combined with the pre-existing `updatePlayer` ownership test from Phase Club 1's exploration, both mutating endpoints this phase touches now have an explicit "wrong club" test.
- **Removal is a destructive-adjacent action gated by confirmation**: the roster card's "Remove from club" shows an `AlertDialog` ("Remove this player from your club?" / its Arabic equivalent) before calling the endpoint — no accidental single-tap removal.

## 4. UI Changes

- **Club Players roster card** (`ClubManagedPlayerCard`) — tapping the card (or its new overflow menu's "View profile") opens the player's existing public profile page (`/players/:id`); the menu adds **Edit**, keeps **Resend credentials**, and adds **Remove from club** (styled in the error color, with the confirmation dialog above). Previously the card only had a single "Resend credentials" button.
- **New "Edit Player" page** (`/club/players/:userId/edit`, Desktop + Mobile) — photo upload + the identity/sports/position/bio/contact form, for a specific managed player. **Not a new editing implementation**: it reuses the Player feature's own `ProfilePhotoSection` and `ProfileDetailsForm` widgets (see §5), including the existing football/basketball visual position pickers, unmodified in behavior for the Player's own Edit Profile page.
- **Club level** (`ClubInfoSection`, part of Edit Club Profile) — the free-text field is now a dropdown of the three controlled values. A club whose stored `level` is old free text sees that text as a helper line under the dropdown ("Current value: …") until they pick a new value — see §6.
- **Read-only club level display** (`ClubProfileView`, used by both My Club Profile and the public club profile) — a controlled value renders its localized label; a legacy free-text value renders exactly as stored, unchanged.

## 5. Architecture Decisions

- **`ProfileDetailsForm` and `ProfilePhotoSection` were parameterized instead of duplicated.** Both previously read/wrote exclusively through `playerProfileControllerProvider` (the signed-in Player's own profile). Each now accepts optional overrides (`initialProfile`/`onSave`/`onSaved`/`saveLabel` on the form; `photoUrl`/`onUpload` on the photo section) that, when omitted, fall through to the exact original behavior via Dart's `??` short-circuit — the Player's own Edit Profile page (`EditProfilePageDesktop`/`Mobile`) passes none of them and is unchanged. The Club's Edit Managed Player page passes all of them, bound to `ClubPlayersController.updatePlayer`/`uploadPhoto` instead. This was the deciding design call this phase made: it avoids a second, parallel "edit a player's fields" implementation (and the validation/position-picker duplication that would come with it), at the cost of these two widgets now having a slightly wider public API.
- **Achievements, media, social links, and visibility were deliberately left out of the Club's Edit Player page.** Phase 2's brief asks for "the ability for a Club to edit a player it created," which this reads as the same core identity/sports/contact fields the Add Player form already collects — not the player's own personal touches (their achievements, gallery, social links, public/private toggle). Those stay exclusively the player's own to manage; the Club's page is a trimmed-down counterpart of the full Edit Profile page, not a copy of it.
- **A dedicated `clubManagedPlayerProvider` (`FutureProvider.family<ClubManagedPlayer, String>`) backs the View/Edit page**, separate from `clubPlayersControllerProvider`'s whole-roster list. Opening a specific player's edit page doesn't depend on the roster list already being loaded, and `ClubPlayersController.updatePlayer`/`uploadPhoto`/`removePlayer` all invalidate the matching family entry after a mutation, so a concurrently-open edit page never shows stale data.
- **The roster card's single "Resend credentials" button became an overflow menu** (View / Edit / Resend / Remove) instead of four buttons crammed into one row — the WhatsApp resend logic itself was extracted into a standalone `resendCredentialsAndOpenWhatsApp()` function so both the menu item and the pre-existing `ResendCredentialsWhatsAppButton` widget (kept, unused for now, still exported) call the identical flow rather than duplicating it.
- **`ClubLevel` is a frontend enum mirroring the backend's**, following the exact same `enum { wireValue }` + a separate `clubLevelLabel()` translator function pattern the Player feature already established for `PreferredFoot` (`player_enums.dart` + `player_enum_labels.dart`) — reused convention, not a new one.

## 6. Migration / Backward Compatibility

- **`ClubProfile.level` stays a plain `String` in the Mongoose schema — deliberately not converted to a schema-level enum.** A schema-level enum validator runs on every `.save()`, including one that only changes an unrelated field (e.g. the club's name); any club with a legacy free-text `level` already saved would have that unrelated save start failing. Instead, the controlled values are enforced only where new data comes in — `UpdateClubProfileDto.level` now requires `@IsEnum(ClubLevel)` — so old documents are never touched or rejected until the club itself picks a new value.
- **No data migration script was written or needed.** Existing free-text values are read back exactly as stored (`clubLevelDisplayValue()` passes through anything that isn't a recognized `ClubLevel` wire value unchanged) and are never silently overwritten: the Edit Club Profile form only sends `level` in the save request when the club has actually picked one of the three options from the dropdown (`_level?.wireValue`, omitted when null) — editing the club's name or city, for instance, never re-sends (and thus never risks invalidating) an old free-text level.
- **The dropdown surfaces the legacy value instead of hiding it** — a helper line under the field ("Current value: {value}") so the club can see what's on file today, without forcing them to pick a replacement before they can save anything else.

## 7. Verification

- `flutter analyze` — **no issues**.
- `flutter test` — **all 9 tests pass** (unchanged from Phase Club 1).
- Backend `npm run build` — **clean**.
- Backend `npm run lint` — **one pre-existing error**, unrelated to this phase: `src/videos/videos.service.ts:25` (`VideoCommentDocument` unused). Confirmed via `git diff` that this file was not touched in Phase Club 1 or 2 — not a regression introduced here.
- Backend `npm test` — **all 52 tests pass** (10 suites), including the 2 new `removeFromClub` tests added this phase.
- Manual/code-level verification (no live backend was available in this environment, same limitation as Phase Club 1):
  - Traced `DELETE /club-players/:playerId` end to end: controller → `requireOwnership` → `deleteOne({ _id: ownership._id })` — confirmed it can only ever match the calling club's own ownership row (`clubManagedPlayerModel.findOne({ clubId, userId })` inside `requireOwnership`), never another club's.
  - Confirmed `ProfileDetailsForm`/`ProfilePhotoSection`'s new optional parameters are only reached via the new Club Edit Player pages — every call site in the Player feature (`EditProfilePageDesktop`/`Mobile`) is unchanged and passes none of them, so `playerProfileControllerProvider` is read exactly as before for the Player's own Edit Profile.
  - Confirmed the Club level save path omits `level` from the request body whenever the dropdown hasn't been touched (`_level == null`), so editing any other Club Info field can't accidentally clear or reject a legacy value.
  - Re-read `/club/players/:userId/edit`'s registration in `app_router.dart` — it falls under the existing `_isClubRoute` prefix check (`startsWith('/club/players')`), so it's already role-gated to `UserRole.club` with no router changes needed beyond adding the route itself.

## 8. Known Limitations

- **No live end-to-end run**, same limitation as Phase Club 1 — no reachable backend/MongoDB with seeded data in this environment. Recommend a manual QA pass (edit a managed player's every field including photo and position picker, remove a player, edit Club level from both a fresh club and one with legacy free-text data) before shipping.
- **`ResendCredentialsWhatsAppButton` (the standalone button widget) is no longer referenced anywhere** — the roster card now drives the same flow through its overflow menu instead. The widget was kept rather than deleted (it still works, still calls the shared `resendCredentialsAndOpenWhatsApp()`), in case a future screen wants a dedicated button instead of a menu item; if that never materializes, it's a candidate for removal in a later cleanup pass.
- **The Club's Edit Player page has no optimistic "unsaved changes" guard** (navigating away mid-edit loses typed input) — this matches the Player's own Edit Profile page's existing behavior exactly (not a new gap introduced here), not something Phase 2 was asked to fix.
- **`ClubLevel`'s three values (Amateur / Semi-Professional / Professional) were chosen as a reasonable MVP default**, not sourced from an existing product spec — if the actual target market uses different terminology (e.g. league divisions), the enum is a single small file (`club-level.enum.ts` + `club_level.dart`) to revise later without touching the storage layer, per §6.
