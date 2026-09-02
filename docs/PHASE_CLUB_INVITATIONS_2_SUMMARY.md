# Phase 2 — Club Experience

Frontend only. No backend file was touched: Phase 1 shipped the whole REST
surface this phase consumes, and nothing was found missing while building
against it.

## What changed

1. **An Invitations screen for Clubs.** Received and Sent in one screen,
   with a server-side status filter, page-based pagination, and per-row
   Accept / Decline / Withdraw.
2. **Invite from a player's profile.** A Club viewing any public player
   profile gets an "Invite to club" action, with an optional message.
3. **Invite by player code.** A sheet that resolves `PLY-000123` to a real
   player, shows who it is, and invites them.
4. **The club's own code on its profile**, with one-tap copy — the thing a
   player quotes to ask to join, which Phase 3 will consume.
5. **Navigation.** A new `clubInvitations` branch, reachable from the
   account sheet and from a new Dashboard quick action, guarded to
   `CLUB` accounts by the same rule that guards Club Players.

Nothing was rebuilt. The clean-architecture layering, `runAuthorized`,
`ApiClient`, the page-based list conventions, `AppScaffoldMobile`,
`ResponsiveLayout`, `AppEmptyState`, `ErrorState`, the spacing/radius tokens
and the l10n workflow are all the existing implementations, used as-is.

## Files changed

**New**

| File | Purpose |
| --- | --- |
| `lib/features/invitations/domain/entities/invitation.dart` | Invitation, its three enums, and the two counterpart summaries. |
| `lib/features/invitations/domain/entities/invitations_page.dart` | The standard page envelope. |
| `lib/features/invitations/domain/entities/invitations_summary.dart` | The two pending counts. |
| `lib/features/invitations/domain/repositories/invitations_repository.dart` | The port. |
| `lib/features/invitations/data/models/invitation_model.dart` | Wire decoding. |
| `lib/features/invitations/data/datasources/invitations_remote_data_source.dart` | The nine `/invitations` routes. |
| `lib/features/invitations/data/repositories/invitations_repository_impl.dart` | Auth + decode. |
| `lib/features/invitations/application/invitations_controller.dart` | The two inboxes, the summary, and the send actions. |
| `lib/features/invitations/presentation/club_invitations_page.dart` (+ `mobile/`, `desktop/`) | The screen. |
| `lib/features/invitations/presentation/shared/invitation_card.dart` | One invitation, from the viewer's side. |
| `lib/features/invitations/presentation/shared/invitation_actions.dart` | Accept / Decline / Withdraw. |
| `lib/features/invitations/presentation/shared/invitation_status_chip.dart` | Status badge. |
| `lib/features/invitations/presentation/shared/invitation_labels.dart` | Status → translated label. |
| `lib/features/invitations/presentation/shared/invitations_filter_bar.dart` | Received/Sent + status filter. |
| `lib/features/invitations/presentation/shared/invitations_pagination.dart` | The project's standard pager. |
| `lib/features/invitations/presentation/shared/invite_player_dialog.dart` | Compose + send. |
| `lib/features/invitations/presentation/shared/invite_player_button.dart` | The action on a player profile. |
| `lib/features/invitations/presentation/shared/invite_by_code_sheet.dart` | Code → player → invite. |
| `lib/features/invitations/presentation/shared/public_code_chip.dart` | A code with one-tap copy. |
| `lib/features/player/application/player_by_code_provider.dart` | `GET /players/by-code/:code`. |
| `test/features/invitations/invitation_model_test.dart` | 12 tests. |
| `test/features/invitations/invitations_controller_test.dart` | 7 tests. |
| `test/features/invitations/invitation_card_test.dart` | 10 tests. |

**Modified**

| File | Change |
| --- | --- |
| `lib/features/player/domain/entities/player_profile.dart`, `data/models/player_profile_model.dart` | `publicCode`. |
| `lib/features/club/domain/entities/club_profile.dart`, `data/models/club_profile_model.dart` | `publicCode`. |
| `lib/features/player/{domain/repositories,data/repositories,data/datasources}` | `getPublicProfileByCode`. |
| `lib/features/club/presentation/shared/club_profile_view.dart` | The club code chip. |
| `lib/features/player/presentation/{mobile,desktop}/public_player_profile_page_*.dart` | The invite action. |
| `lib/features/dashboard/presentation/shared/club_dashboard_widgets.dart` | Invitations quick action. |
| `lib/core/navigation/app_branches.dart` | `clubInvitations` branch, its route metadata, and the Club's account-sheet entry. |
| `lib/core/router/app_router.dart` | The route, and `/club/invitations` added to the Club-only guard. |
| `lib/l10n/app_en.arb`, `app_ar.arb` | 38 new keys, both locales. |

## Design decisions worth stating

**Actions come from the server, never from the status.** Every button is
rendered from `canAccept` / `canReject` / `canCancel` as the backend
computed them, rather than from `status == PENDING && direction == …`
worked out again on the client. There is one implementation of those rules
and it is the one that will actually be enforced; a stale flag costs a
refused request and a message, never an unauthorised action. This is
pinned by test.

**Expiry is not computed here.** The backend reports a lapsed `PENDING` row
as `EXPIRED` in every view whether or not its sweep has run, so a client
that derived expiry itself could only ever disagree with the server about
it. `InvitationStatus.expired` is decoded, never inferred.

**Filtering is a request, not a `where` clause.** The lists are paginated,
so filtering already-loaded rows would silently mean "matching rows on this
page". Applying a status filter resets to page 1 for the same reason.

**A transition patches its own list and invalidates the other.** Writing
the server's answer back into the row keeps the page and filter the viewer
is on — invalidating would dispose the notifier and reset both. The
opposite inbox *is* invalidated, because accepting a request creates a
membership and cancels every other pending invitation naming that player.
That costs one extra paginated request per transition even when the other
tab was never opened; the alternative is a staleness flag the screen checks
on tab switch, which is more moving parts than the cost justifies. Noted
rather than hidden.

**Invitations is an account-sheet entry, not a fifth tab.** Four tabs beside
the account slot is the documented ceiling before labels truncate at 320px,
and it is pinned by an existing test. Discoverability comes from the
Dashboard quick action instead.

**The invite button does not pre-check eligibility.** It shows for every
player a Club can see. Working out beforehand whether an invitation is
already pending, whether the player is in a club, or whether the account
was created by a club would cost three requests per profile view to
pre-empt a message the send itself produces — and a client-side "you can't"
that the server disagreed with would be worse than either.

**Invite-by-code confirms before sending.** A code is six digits with no
redundancy. The lookup step exists so a typo is caught by a human reading a
name, not by a stranger receiving an invitation. The send then quotes the
resolved **id**, not the typed code — the backend resolves a code first when
given both, which would have made the id decorative.

## Security considerations

**Nothing new is trusted.** The client renders from server-supplied
permission flags and re-sends only ids/codes and a message; every rule is
re-derived server-side on each request (Phase 1, §A01/§A04).

**Enumeration.** The code lookup reports "no public player found with that
code" for both an unknown code and a private profile, so it cannot be used
to test whether a given code exists — which matches what the backend
already does by returning the same 404 for both. Lookups fire on submit,
never per keystroke, so a typed code costs one request against the
backend's 20/min budget rather than one per character.

**No contact details.** Invitation views carry name, photo, sport, position,
country and code. Phone and email stay behind the existing club-only
`GET /players/:id/contact`, which this phase does not touch.

## Tests

All commands were run; output below is real.

```
frontend: flutter analyze → No issues found!
frontend: flutter test    → All tests passed (160)   (was 132)
```

29 new tests:

| Case | Where |
| --- | --- |
| Full invitation payload decodes, both sides | `invitation_model_test.dart` |
| Permission flags are carried, not derived | `invitation_model_test.dart` |
| Deleted counterpart / missing flags / bad date degrade safely | `invitation_model_test.dart` |
| Every status the backend can send decodes | `invitation_model_test.dart` |
| Page envelope, `hasNextPage`, empty page | `invitation_model_test.dart` |
| Each inbox reads its own endpoint | `invitations_controller_test.dart` |
| Status filter is server-side and resets to page 1 | `invitations_controller_test.dart` |
| Paging keeps the filter | `invitations_controller_test.dart` |
| A transition patches the row in place, keeping page/filter | `invitations_controller_test.dart` |
| A transition invalidates the opposite inbox | `invitations_controller_test.dart` |
| The card shows the counterpart, not the viewer | `invitation_card_test.dart` |
| Status is spelled out, not only coloured | `invitation_card_test.dart` |
| Only server-granted actions are offered (three states) | `invitation_card_test.dart` |
| Expiry shows while pending, not after | `invitation_card_test.dart` |
| Decline confirms first, and backing out is inert | `invitation_card_test.dart` |

## Known limitations

1. **Not exercised against a live backend.** Everything here is verified by
   the analyzer and by widget/unit tests against fakes. The project has no
   HTTP-level e2e harness and no seeded club/player pair to drive the real
   flow, so "a club invited a player and the player joined" has not been
   watched end to end. That is the honest limit of what was verified.
2. **No membership display yet.** A club's roster of *joined* players and a
   player's current club still have no read endpoint (Phase 1's deferred
   item) and no UI. Accepting an invitation creates the membership; nothing
   yet shows it. Phase 3 work.
3. **No badge on the bottom navigation.** `GET /invitations/summary` is
   fetched and shown as a count beside the Received/Sent segments, but the
   account-sheet entry carries no unread indicator — the shell has no badge
   affordance, and adding one is a shell change rather than a feature one.
4. **`PlayerSearchResult` has no `publicCode`.** The backend's search view
   carries it, but nothing in this phase renders a code on a search card, so
   the field was not added. Phase 3 can add it in one line if a player card
   should show it.
5. **The player's own code is not shown anywhere.** A player cannot yet read
   their own `PLY-` code to hand to a club — that is Phase 3's "player code
   on the player profile", so invite-by-code is currently only usable with a
   code obtained out of band.
6. **The opposite inbox is refetched on every transition**, even unopened.
   See the design note above; deliberate, and cheap.

## Git status

**No commit was made** for this phase. Phase 1 was committed separately on
`feat/club-player-invitations-phase1` (`ed9c4ab`).

Also present in the working tree but **not part of this phase** — already
modified/untracked before it started: `backend/.env.example`,
`backend/src/auth/auth.module.ts`, `backend/src/config/env.validation.ts`,
`backend/src/auth/mail/brevo-api-email.provider.ts`, `docs/SECURITY_AUDIT.md`.

## Stop point

Phase 2 is complete. Phase 3 (Player experience: request to join a club,
search by club code, the Player Invitations screen, and the membership
display on both profiles) has not been started.
