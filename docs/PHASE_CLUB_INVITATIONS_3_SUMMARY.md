# Phase 3 — Player Experience & Memberships

Backend *and* frontend. Phase 1 deferred the membership read endpoints "to
the phase whose UI consumes them"; this is that phase, so they were built
here alongside the screens that call them.

## What changed

### Backend

1. **Two membership read routes**, on a new `MembershipsController` inside
   the invitations module, addressed by *profile* id because that is what a
   public profile page has in hand:
   - `GET /memberships/clubs/:clubId/players?page=` — a club's current
     players.
   - `GET /memberships/players/:playerId/club` — the club a player belongs
     to, or `null`.
   Both unauthenticated, matching the pages they render on (`GET /players/:id`
   and `GET /clubs/:id` are already public). No writes: a membership is
   created only by accepting an invitation, and nothing in the product yet
   says who may end one.
2. **`PlayersService.findManyPublicByUserIds`** — paginated, `PUBLIC`-only,
   counted on the same filter.
3. **`MembershipsService.listActiveForClubUnpaginated`** — every current
   member, so the caller can page over *profiles* rather than memberships.

### Frontend

4. **Player Invitations screen** at `/player/invitations` — Received (clubs
   that invited you) and Sent (clubs you asked to join), same screen as the
   Club's.
5. **Request to join** from any public club profile, player-only, with an
   optional message.
6. **Join by club code** — type `CLB-000123`, see which club it is, ask to
   join.
7. **The player's own `PLY-` code** on their profile, with one-tap copy —
   the thing Phase 2's invite-by-code needed and could not get.
8. **Membership display on both public profiles**: the club a player belongs
   to (logo, code, join date, tappable) on the player profile; a club's
   visible roster on the club profile.

## Files changed

**New — backend**

| File | Purpose |
| --- | --- |
| `src/invitations/memberships.controller.ts` | The two public read routes. |
| `src/invitations/memberships.mapper.ts` | Membership views, reusing the invitation summaries verbatim. |
| `src/invitations/dto/list-members.dto.ts` | The roster's whole query surface: a page number. |
| `src/invitations/memberships.controller.spec.ts` | 8 tests. |

**New — frontend**

| File | Purpose |
| --- | --- |
| `features/invitations/domain/entities/membership.dart` | `PlayerClubMembership`, `ClubMember`, `ClubMembersPage`. |
| `features/invitations/domain/repositories/memberships_repository.dart` | The port. |
| `features/invitations/domain/public_code.dart` | Code normalization, shared by both lookups. |
| `features/invitations/data/{models,datasources,repositories}/membership*.dart` | Decode + fetch. |
| `features/invitations/application/memberships_providers.dart` | `playerClubProvider`, `clubMembersProvider`. |
| `features/invitations/presentation/player_invitations_page.dart` | `/player/invitations`. |
| `features/invitations/presentation/{mobile,desktop}/invitations_page_*.dart` | One screen, configured per role. |
| `features/invitations/presentation/shared/invitations_screen_config.dart` | What actually differs between the two roles. |
| `features/invitations/presentation/shared/send_invitation_dialog.dart` | Both send flows (replaces `invite_player_dialog.dart`). |
| `features/invitations/presentation/shared/code_lookup_sheet.dart` | The shared code-lookup sheet. |
| `features/invitations/presentation/shared/join_by_code_sheet.dart` | Its club-shaped half. |
| `features/invitations/presentation/shared/request_to_join_button.dart` | Player-only action on a club profile. |
| `features/invitations/presentation/shared/club_members_section.dart` | A club's visible roster. |
| `features/club/application/club_by_code_provider.dart` | `GET /clubs/by-code/:code`. |
| `test/features/invitations/membership_model_test.dart` | 6 tests. |
| `test/features/invitations/player_side_test.dart` | 8 tests. |

**Modified**

| File | Change |
| --- | --- |
| `src/invitations/invitations.mapper.ts` | `clubSummary` / `playerSummary` exported for reuse. |
| `src/players/players.service.ts` | `findManyPublicByUserIds`. |
| `src/invitations/memberships.service.ts` | `listActiveForClubUnpaginated`. |
| `src/invitations/invitations.module.ts` | Registers the new controller. |
| `src/{players/players,invitations/memberships}.service.spec.ts` | 2 new tests; `find()` mock chain extended. |
| `features/club/{domain,data}/**` | `getByCode`. |
| `features/player/presentation/shared/player_club_card.dart` | Membership-first Current Club card. |
| `features/player/presentation/shared/owner_account_section.dart` | The owner's own player code. |
| `features/club/presentation/{mobile,desktop}/public_club_profile_page_*.dart` | Join action + roster. |
| `core/navigation/app_branches.dart` | `playerInvitations` branch + account-sheet entry. |
| `core/router/app_router.dart` | The route, and a Player-only guard for it. |
| `lib/l10n/app_{en,ar}.arb` | 14 new keys, both locales. |
| `test/features/player/player_profile_redesign_test.dart` | Wrapped in a `ProviderScope` (the club card now reads a membership). |

## Design decisions worth stating

**A private player is absent from a club's roster *and* from its total.**
The roster pages over player profiles rather than over memberships, and
counts the same `PUBLIC`-filtered set. Reporting "5 of 8" would disclose the
existence of the three it may not show. Belonging to a club is not a way
around a player's visibility setting — the same rule the by-code lookups
already enforce. Pinned by test on both sides.

**"No club" is a 200, not a 404.** A player with no membership is the
ordinary case on a profile page. Answering 404 would force every caller to
treat a normal state as a failure.

**A membership outranks the typed club name, and never merges with it.**
`PlayerProfile.currentClub` is free text the player typed; a membership is a
fact both parties agreed to. The card shows the membership when there is
one, and falls back otherwise. Showing both would imply they had been
reconciled.

**Two roles, one screen.** The Club's inbox and the Player's differ in three
strings and which code sheet the action opens, so that is all
`InvitationsScreenConfig` carries. An invitation is one object seen from two
ends, and the card already renders itself from the viewer's side. Two
screens would have meant every later change to either being a change to
both, with nothing enforcing that it was.

**The membership reads never block a page.** A club roster or a current-club
card that fails to load renders nothing (or falls back), because both are
supplementary sections on someone else's profile where an error box is worse
than absence.

### Defect found and fixed during this phase

`AsyncValue.value` **rethrows** when the provider is in an error state, so
the "degrade quietly" behaviour described above was not what the first draft
actually did — a failed side request would have thrown during `build` and
taken the profile page with it. An existing test caught it. Four sites now
use `valueOrNull`: the Current Club card, the club roster section, the
inbox badge counts, and the list controller's in-place patch (where `value`
would have turned a *successful* accept into a thrown error). Two
**pre-existing** sites with the same pattern were found in
`visibility_section.dart` and `profile_details_form.dart`; they are outside
this phase and were left alone rather than changed silently — flagged as
separate work.

## Security considerations

**Roster visibility** — covered above; the filter and the count are the same
set, asserted by `memberships.controller.spec.ts` and
`players.service.spec.ts`.

**No contact details anywhere new.** The membership mapper reuses the
invitation summaries verbatim, so a field can never be safe to show in an
invitation and leak in a roster. A test asserts a phone and email never
appear in a serialized roster row.

**Player-only routing.** `/player/invitations` is guarded the way
`/club/*` already is. The guard is deliberately narrow: the Player profile
and skills screens stay reachable by any role, as they always have been.

**Enumeration.** The club lookup reports "no club found with that code" for
anything it cannot resolve, and fires on submit rather than per keystroke —
same treatment as the player lookup in Phase 2.

## Tests

All commands were run; output below is real.

```
backend:  npm run build   → clean
backend:  npx jest        → 19 suites, 176 tests passed (was 18 / 166)
frontend: flutter analyze → No issues found!
frontend: flutter test    → All tests passed (174)  (was 160)
```

24 new tests. What they pin:

| Case | Where |
| --- | --- |
| Roster pages over profiles, so the total honours the PUBLIC filter | `memberships.controller.spec.ts` |
| Each member carries the date they joined | `memberships.controller.spec.ts` |
| A roster row never carries contact details | `memberships.controller.spec.ts` |
| An empty roster costs no profile query | `memberships.controller.spec.ts` |
| Unknown club 404s rather than answering empty | `memberships.controller.spec.ts` |
| A player's club resolves through the membership | `memberships.controller.spec.ts` |
| "No club" is `null`, not an error | `memberships.controller.spec.ts` |
| A private player's membership is not readable | `memberships.controller.spec.ts` |
| The visibility filter is on the count too | `players.service.spec.ts` |
| Every current member is listed, newest first | `memberships.service.spec.ts` |
| Membership + roster wire shapes decode | `membership_model_test.dart` |
| A deleted club reads as no club | `membership_model_test.dart` |
| Only a Player sees "request to join" | `player_side_test.dart` |
| A membership wins over the typed club name | `player_side_test.dart` |
| Fallback to typed club, then to "No Club" | `player_side_test.dart` |
| The two roles' screens differ only as configured | `player_side_test.dart` |

## Known limitations

1. **Still not exercised against a live backend.** Same limit as Phase 2:
   no e2e harness and no seeded club/player pair, so the full round trip —
   a player asks to join, a club accepts, both profiles then show the
   membership — has not been watched happen. Verified by the analyzer, the
   TypeScript build, and unit/widget tests against fakes.
2. **A membership cannot be ended.** `MembershipsService.end` exists and is
   tested, but no route and no UI expose it: who may end a membership, and
   what the other party is told, is a product decision nothing has asked
   yet. Building it before there is a caller would mean inventing the rule.
3. **The roster is the club's *visible* roster.** By design (see above), but
   worth stating plainly: a club with private members will look smaller on
   its public page than it is.
4. **No badges in the shell.** Both roles' Invitations sit in the account
   sheet with no unread indicator; the pending counts show only once the
   screen is open. Adding one is a shell change.
5. **`ClubManagedPlayer` accounts still cannot be recruited**, unchanged
   from Phase 1 — and they do not appear in a club's membership roster
   either, since they never accepted an invitation. A club created that way
   therefore has two separate player lists: Club Players (accounts it
   created) and its membership roster. Unifying them is a deliberate
   backfill, not a UI change.
6. **The club's own roster screen is unchanged.** `/club/players` still
   lists club-*created* accounts only. Members who joined by invitation
   appear on the club's public profile, not in that tool.

## Git status

Phases 1 and 2 were committed on `feat/club-player-invitations-phase1`
(`ed9c4ab`, `1c7dd04`).

Also present in the working tree but **not part of this phase** — already
modified/untracked before it started: `backend/.env.example`,
`backend/src/auth/auth.module.ts`, `backend/src/config/env.validation.ts`,
`backend/src/auth/mail/brevo-api-email.provider.ts`, `docs/SECURITY_AUDIT.md`.

## Stop point

All three phases of the plan are implemented. What remains is the live
end-to-end verification named in limitation 1, and the deliberately deferred
items in 2, 5 and 6.
