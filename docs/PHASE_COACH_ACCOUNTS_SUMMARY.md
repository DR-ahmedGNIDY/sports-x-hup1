# Coach accounts — summary

## What exists now

- **Role `COACH`**, self-registration, public code `COA-000123`.
- **Coach CV** (`coachprofiles`): name, title, sport, years of experience,
  bio, education, specialties, preferred formations, languages, contact,
  visibility (PUBLIC by default so clubs can invite by code), profile photo,
  photo/video album (max 30), career history, licences, achievements, links.
  Current clubs are derived from live memberships.
- **Club ↔ coach invitations** (`club_coach_invitations`), both directions,
  same state machine and 30-day expiry as player invitations.
- **Staff memberships** (`club_coach_memberships`): a coach may be on several
  clubs at once; one active membership per club/coach pair.
- **Per-club permissions** on each membership:
  `VIEW_SQUAD` (always), `VIEW_PLAYER_CONTACTS`, `MANAGE_CALENDAR`,
  `MANAGE_LINEUP`, `INVITE_PLAYERS`, `CREATE_PLAYERS`, `MANAGE_CLUB_PLAYERS`,
  `EDIT_CLUB_PROFILE`, `REMOVE_MEMBERS`. "All permissions" grants every one.
  Never delegable: managing coaches/permissions, the club's own account,
  posting as the club.
- **Coach posts** in the Home feed (as themselves).

## How a coach acts for a club

The app sends `X-Club-Id: <club profile id>` for the coach's active club.
`ClubActorGuard` (backend `club-access/`) resolves the club and checks the
route's `@ClubPermission(...)` against the membership **on every request**,
so revoking a permission takes effect immediately. Any failure is the same
403. Club accounts are unaffected (they always act for themselves).

Roster rows hide player contact details from a coach without
`VIEW_PLAYER_CONTACTS`. A player created by a coach is owned by the club
(`ClubManagedPlayer.createdByCoachUserId` records who created it).

## Endpoints

| Area | Endpoints |
|---|---|
| CV | `GET/PATCH /coaches/me`, `PATCH /coaches/me/visibility`, `POST/DELETE /coaches/me/profile-photo`, `POST /coaches/me/media`, `DELETE /coaches/me/media/:id`, `POST/PATCH/DELETE /coaches/me/{certifications,experience,achievements,social-links}[/:id]` |
| Public | `GET /coaches`, `GET /coaches/:id`, `GET /coaches/by-code/:code`, `GET /memberships/clubs/:clubId/coaches` |
| Invitations | `POST /coach-invitations/club-to-coach` (club), `POST /coach-invitations/coach-to-club` (coach), `GET received/sent/summary/:id`, `POST :id/accept|reject|cancel` |
| Staff | `GET /club/coaches`, `PATCH /club/coaches/:id/permissions`, `DELETE /club/coaches/:id` (club only); `GET /coaches/me/clubs`, `DELETE /coaches/me/clubs/:id` (coach) |
| Club profile as staff | `GET/PATCH /club/profile`, `POST /club/profile/logo` |

## Known limits

- Coach videos live in the CV album only; they are not part of the
  Community/skills video system (which is player-specific).
- Older app builds do not know the `COACH` role; ship the new app before
  announcing coach sign-up.
- No end-to-end run against a database was done in development: the local
  `.env` points at the hosted Atlas database.
