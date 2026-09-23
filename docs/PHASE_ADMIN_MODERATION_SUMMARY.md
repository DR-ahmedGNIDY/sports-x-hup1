# Admin Moderation & Verification — Summary

Four capabilities added to the admin dashboard, plus the community-facing
surfaces each one shows up on.

## 1. Timed suspension

An admin suspends an account for **1 month, 3 months, 1 year, or
permanently**. Players, clubs and coaches are all `User` records, so one
mechanism covers every kind of account.

- `User.suspendedUntil` — the end date, absent for a permanent suspension.
- `User.suspensionReason` — an internal note; never shown to the suspended
  user, and never returned by `toPublicUser`.
- `users/suspension.ts` — the closed set of terms and the calendar-month
  arithmetic behind the end date.

**A fixed-term suspension lifts itself.** There is no cron job:
`UsersService.liftExpiredSuspension` runs on login, on refresh and on every
authenticated request (`JwtStrategy.validate`), so the account comes back
the moment it is next used. Login rejection tells the user the date.

Endpoints: `POST /admin/users/:id/suspend`, `POST /admin/users/:id/reactivate`.
The pre-existing `PATCH /admin/users/:id/status` still works, and now
clears the suspension fields when it sets a user back to ACTIVE.

## 2. Club verification

`ClubProfile.isVerified` / `verifiedAt`, set through
`PATCH /admin/clubs/:id/verification`.

The flag is **public**, not admin-only: `toClubView` returns it and the
feed's author view carries it, so the check badge
(`core/widgets/verified_badge.dart`) renders next to the club's name on its
own profile, in the public clubs listing, and on its Home-feed posts — one
widget, one source of truth.

## 3. Overview cards

`GET /admin/stats` returns registered players, clubs, coaches, total
accounts, suspended accounts, moderators, verified clubs, and post counts,
in one round trip.

Rendered by `/admin/overview`, which is now the admin's first sidebar
branch and therefore the dashboard's landing screen.

Accounts and profiles are counted separately, and the cards say so: an
account exists from signup, its profile only once the user fills something
in, so `players` (accounts) is normally >= `playerProfiles`.

## 4. Community moderation

`User.isModerator` — orthogonal to `role`, so a player, club or coach can
moderate without being an admin (which would also unlock the whole
dashboard). Granted via `PATCH /admin/users/:id/moderator`. It is read live
by `JwtStrategy` rather than signed into the token, so granting or revoking
it takes effect on the very next request.

Two powers, deliberately separate:

| | who | reversible |
|---|---|---|
| **Hide** | moderators only | yes — the post stays, flagged |
| **Delete** | the author, or any moderator | no — the Cloudinary asset goes too |

Both reach either kind of Home-feed item, because the feed mixes them:
`DELETE /feed/:kind/:id` and `PATCH /feed/:kind/:id/visibility`, with
`:kind` being `PHOTO` or `VIDEO`. Hiding a photo post sets
`PhotoPost.isHidden`; hiding a video flips it back to `PRIVATE`, reusing
the visibility the Video schema already had rather than adding a second
overlapping flag.

The feed excludes hidden posts for everyone except moderators, who still
receive them flagged so they can review and restore them. Every feed item
is stamped with `canDelete` / `canModerate` by the server, and the card's
three-dot menu only offers what those allow — the client never re-derives
permissions.

**Note:** deleting a post did not exist at all before this change, not even
for its own author. It does now.

## Data migration

None needed. Every new field has a schema default, so existing documents
read as `isVerified: false`, `isModerator: false`, `isHidden: false` and no
suspension date.
