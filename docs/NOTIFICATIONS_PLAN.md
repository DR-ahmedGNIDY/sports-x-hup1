# Notifications — Plan

Status: **Phases 1 and 2 implemented.** Phase 3 (expiry reminders) not
started. §12 is the deployment step push needs before it can send anything.

**Scope decision (taken after the first draft):** no email. The channels are
in-app, and the phone's own notification tray via Web Push on the installed
PWA. §7 is rewritten around that; §11 records what "phone notifications"
actually costs and where it does not work.

The club/player invitations feature (see `CLUB_PLAYER_INVITATIONS_PLAN.md`)
ships with no way to tell anyone anything happened. A club sends an
invitation; it sits for 30 days and expires; the player may never learn it
existed. Closing that is what this plan is for.

## 1. What already exists (audit before design)

| Concern | Existing implementation | Consequence for this design |
| --- | --- | --- |
| Notifications | **None**, anywhere | Everything here is new. |
| Transactional email | `MailService` + `EmailProvider` seam, three bound implementations (`smtp`, `brevo`, `console`) chosen by `MAIL_PROVIDER` | Reused — but the interface has exactly one method, `sendPasswordResetEmail`. It must be generalized before it can carry anything else. |
| Email delivery in production | **Broken.** `SmtpEmailProvider` times out on Railway, which blocks outbound mail ports (25/465/587/2525) | `BrevoApiEmailProvider` (HTTPS on 443) exists **uncommitted** in the working tree and fixes it. Email notifications are blocked until it lands. |
| User contact | `User { email?, phone? }` — **both optional**; a club-created player may have only a phone | Email cannot reach every player. This is the single most important constraint in this plan; see §3. |
| Scheduler | **None.** No `@nestjs/schedule`, no cron, no queue | Anything periodic (digests, expiry reminders) needs new infrastructure. Phase 1 deliberately needs none. |
| Realtime transport | **None.** No WebSocket, no SSE | The client polls. Stated as a limitation rather than hidden. |
| WhatsApp | `whatsapp_send_button.dart` builds a `wa.me` link a human then taps | This is *manual sharing*, not a delivery channel. Automating it needs the WhatsApp Business API — out of scope. |
| Invitation events | `InvitationsService` transitions: send, accept, reject, cancel | These are the emission points. |
| Localization | Full ar/en via `.arb`; Arabic is the default | Notifications must **not** store rendered text — see §4. |
| Auth / IDOR rule | Every invitation query pins one side to the caller *inside the query* | Reused verbatim for notification rows. |

## 2. What is worth notifying about

Only events where someone is waiting on someone else. Everything else is
noise, and noise is how a badge becomes something people learn to ignore.

| Event | Who is told | Why it earns a notification |
| --- | --- | --- |
| Club invites player | the player | They cannot act on what they don't know about. |
| Player asks to join club | the club | Same, in the other direction. |
| Invitation accepted | the sender | The outcome they were waiting for. |
| Invitation rejected | the sender | Closes the loop; frees them to look elsewhere. |
| Invitation about to expire | the recipient | Only one, at T-3 days, and only if still `PENDING`. Needs a scheduler → Phase 3. |

**Deliberately not notified:**

- **Cancelled by the sender.** The recipient loses nothing and can do
  nothing about it. Telling them turns a withdrawn thought into an event.
- **Expired.** Nobody acted; saying so days later helps no one.
- **A membership being created.** It is the same moment as "accepted",
  already covered — two notifications for one event is how a system starts
  feeling like spam.

## 3. The constraint that decides the architecture

**`User.email` is optional.** A club-created player account may carry only a
phone number. Those accounts are exactly the ones a club interacts with
most.

So an email-first design would silently fail for a large and predictable
slice of users — and fail *invisibly*, which is worse than not sending.

**Therefore in-app is the backbone, not a nice-to-have.** Every account can
receive an in-app notification because every account can open the app.
Email is an *additional* channel layered on top for users who have an
address, never the system of record.

## 4. Data model

### `notifications`

| Field | Type | Notes |
| --- | --- | --- |
| `userId` | ObjectId → `User` | The recipient. Every query pins this. |
| `type` | enum | `INVITATION_RECEIVED`, `INVITATION_ACCEPTED`, `INVITATION_REJECTED`, `INVITATION_EXPIRING` |
| `params` | object | Structured payload — names, ids, codes. **Not rendered text.** |
| `entityType` / `entityId` | string / ObjectId | What to open when tapped (an invitation). |
| `readAt` | Date, optional | Absent = unread. |
| `createdAt` | Date | Mongoose timestamps. |

Indexes:

- `{ userId, createdAt: -1 }` — the list.
- `{ userId, readAt }` — the unread count behind the badge.
- `{ userId, entityType, entityId, type }` **unique** — the dedupe rule
  (§6).

**`params`, never rendered strings.** The app is bilingual and Arabic is
the default. If a notification is stored as `"نادي الأهلي دعاك للانضمام"`
and the user switches to English, their whole history stays Arabic — and a
copy-edit to the wording never reaches anything already sent. Storing
`{ clubName: "الأهلي" }` against a `type` lets the client render from the
same `.arb` files as everything else, in whatever language is current.

### `User.notificationPreferences` (Phase 2)

`{ emailOnInvitation: bool, emailOnResponse: bool }`, defaulting to `true`.
Needed *before* email ships, not after — a channel with no off switch is a
channel people mark as spam.

## 5. API surface

| Method | Route | Auth | Notes |
| --- | --- | --- | --- |
| `GET` | `/notifications?page=&unreadOnly=` | any | Page-based, same envelope as every other list. |
| `GET` | `/notifications/summary` | any | `{ unread: n }` — the badge. Cheap, called often. |
| `POST` | `/notifications/:id/read` | owner only | |
| `POST` | `/notifications/read-all` | any | One write, not N. |
| `PATCH` | `/users/me/notification-preferences` | any | Phase 2. |

Every route scopes to `userId` from the JWT *inside the query*, so a caller
who is not the owner matches nothing and gets the same `404` as one who
invented the id — the rule already established for invitations.

## 6. Emission, and why it is not an event bus

`NotificationsService.emit(...)` is called from `InvitationsService`
**after** each state transition has committed, inside a `try/catch` that
only logs.

- **Not before**, and not in the same operation: a failed notification write
  must never roll back an accepted invitation. The relationship is the fact;
  the notification is an announcement of it.
- **Not through an event bus.** This codebase has no event emitter, and
  adding `@nestjs/event-emitter` for a single producer and a single consumer
  buys indirection, not decoupling. A direct call is honest about what
  actually happens. If a second producer ever appears, that is the moment to
  reconsider.

**Dedupe.** The partial unique index on `{ userId, entityType, entityId, type }`
means one notification per invitation per type, enforced by the database. A
club that sends, withdraws, and re-sends does not produce three unread rows.
The duplicate-key error is swallowed — a duplicate is a success, not a
failure.

## 7. Delivery channels, phased

### Phase 1 — In-app (no external dependency)

Everything above, plus:

- **Badge on the account slot** in the shell. `GET /notifications/summary`,
  polled on app start and on resume. This is the single highest-value piece
  in the whole plan: today the pending count exists (`/invitations/summary`)
  but only renders once you are *already looking at the screen that shows
  it*, which is the one moment you no longer need it.
- **A notifications screen** — a list, tap to open the invitation, mark
  read on open, "mark all read".

Ships value to 100% of accounts, needs no scheduler, no queue, no provider,
no new dependency, and no working email.

**Polling, honestly.** With no WebSocket, "realtime" means "within a poll
interval". Poll the summary on app start and on foreground resume — not on
a timer while the app sits open, which spends a request per user per
interval to change a number almost nobody is watching.

### Phase 2 — Web Push (the phone's notification tray)

This is what "the player sees it in their phone notifications" actually
means: the operating system shows a banner **while the app is closed**. That
is not in-app delivery — it is push, and it is a genuinely bigger piece of
work than Phase 1. It is worth it, because a badge nobody opens the app to
see solves nothing.

**What already exists and is reused**

- A real service worker (`web/sxh_service_worker.js`) — well-formed, owns
  its cache lifecycle. It has **no `push` or `notificationclick` handler**;
  those are added.
- A complete PWA manifest (`display: standalone`, icons, ar/rtl). The app is
  already installable — which is the precondition for push on a phone.

**What is new**

1. **`push` and `notificationclick` handlers** in the existing service
   worker. `notificationclick` deep-links to the invitation.
2. **VAPID keypair**, public key shipped to the client, private key an env
   var on the backend.
3. **`push_subscriptions` collection** — `{ userId, endpoint (unique), keys,
   userAgent, createdAt, lastFailedAt }`. One user has several: a phone, a
   laptop.
4. **A permission prompt at a moment that earns it.** Never on first load —
   a cold prompt is refused by most people, and a refusal in a browser is
   effectively permanent. Ask *after* the player opens their first
   invitation, where the value is self-evident.
5. **Send on emit**, alongside the in-app row: `web-push` on the backend, to
   every subscription the recipient has.
6. **Prune dead subscriptions.** Endpoints die silently; a `404`/`410` from
   the push service means delete the row. Without this the table grows
   forever and every send wastes requests.

**Where this does not work — state this to users, not just here**

| Platform | Works? |
| --- | --- |
| Android — Chrome, installed to home screen | **Yes** |
| Android — Chrome, browser tab only | Yes |
| iPhone — **installed to Home Screen** (iOS 16.4+) | **Yes** |
| iPhone — Safari tab, not installed | **No.** iOS grants push only to installed PWAs |
| Desktop Chrome / Edge / Firefox | Yes |

The iPhone row is the one that will generate support questions. An iOS user
who never taps "Add to Home Screen" gets **no phone notifications at all**,
and nothing in the browser tells them why. The app already has an install
prompt (`core/utils/app_install.dart`) — Phase 2 should route iOS users to
it explicitly rather than letting them silently receive nothing.

**Not the native Android app.** The repo has an `android/` target, but the
product ships as web on Railway. Doing this over FCM instead would mean an
app-store release, a signing pipeline and a separate token lifecycle — for
the same banner on the same phone. Web Push reaches the same place with no
store involved. If a native release happens later, FCM is added beside this,
not instead of it.

### Phase 3 — Expiry reminders

Needs a scheduler: `@nestjs/schedule` plus a daily sweep over `PENDING`
invitations near `expiresAt`. This also finally gives
`InvitationsService.markExpired` a caller, which invitations Phase 1 left
deliberately unscheduled.

Small, and genuinely optional — do it only if invitations are observed
expiring unseen.

### Email — dropped

Not in scope, by decision. Worth recording why the option existed: the
`EmailProvider` seam is already built and a working `BrevoApiEmailProvider`
sits uncommitted in the working tree. If email is ever wanted, §2 of the
original draft applies — generalize the interface, add a per-user
preference, send only where an address exists. It stays dropped as long as
push covers the same need, which for a phone-first audience it does, and
better.

## 8. Security and privacy

- **Ownership is a query filter, not a post-fetch check** — the IDOR rule
  already used throughout invitations.
- **`params` carries no contact details.** Name, code and ids only — the
  same fields the invitation card already shows. A notification must never
  become a way to read a phone number that `GET /players/:id/contact`
  guards.
- **A private player's data does not leak into a club's email.** The payload
  is limited to what the club could already see in the invitation view.
- **Email addresses are never logged**, matching the existing rule in
  `MailService` about reset tokens.
- **Spam pressure.** A club is already throttled to 10 invitation sends per
  minute, and the dedupe index caps notifications per invitation. Worth
  re-checking once notifications make sending *visible* to the recipient.

## 9. Effort, roughly

| Phase | Backend | Frontend | Notes |
| --- | --- | --- | --- |
| 1 — In-app | schema, service, 4 routes, emission, tests | badge, screen, l10n, tests | No new dependency, nothing blocked. |
| 2 — Web Push | `web-push` dep, VAPID, subscriptions collection, send + prune | SW handlers, permission flow, iOS install routing | Reaches the phone tray. The larger half is the permission moment and the dead-subscription handling, not the sending. |
| 3 — Reminders | `@nestjs/schedule`, daily sweep | — | Small. Optional. |

## 10. Recommendation

**Build Phase 1 and Phase 2 together, ship them together.**

Phase 1 alone does not do what was asked. A badge is only seen by someone
who already opened the app, and the whole problem is that nobody knows to
open it. Phase 2 alone has no fallback for a viewer who declined the
permission prompt, and no history — a banner dismissed is gone.

They are two halves of one feature: the in-app list is the durable record,
push is what makes anyone look at it. Phase 1 is still built first, because
Phase 2 sends *from* the same emission point Phase 1 establishes — but
neither is worth releasing on its own.

Phase 3 stays optional.

## 11. Known limitations, before anything is built

1. **iPhone users who do not install the app get nothing.** No push, no
   banner, no explanation. Mitigated by routing them to the existing install
   prompt, not solved.
2. **A declined permission is close to permanent.** Browsers make
   re-prompting deliberately hard. This is why the prompt's timing matters
   more than any other decision in Phase 2.
3. **No delivery guarantee.** Push services drop messages; a phone that is
   off may never receive one. The in-app list is the system of record, and
   push is best-effort on top — never the other way round.
4. **No realtime in-app.** Without a WebSocket the badge updates on app
   start and resume. Push covers the closed-app case, so the gap is narrow.
5. **A process death between the transition and the send loses the push.**
   The in-app row is already committed, so nothing durable is lost.

## 12. Deploying push

**Push stays silently off until VAPID keys exist.** `PushService` disables
itself when they are absent and every method becomes a no-op — deliberate,
so a dev machine, a test run, and a deploy that skipped this section all
keep working, just without banners. The in-app notification is the durable
record either way.

Generate a keypair once:

```bash
npx web-push generate-vapid-keys
```

Set three variables on the **backend** service:

| Variable | Value |
| --- | --- |
| `VAPID_PUBLIC_KEY` | the public key from above |
| `VAPID_PRIVATE_KEY` | the private key — a secret, never committed |
| `VAPID_SUBJECT` | `mailto:` address or a site URL; falls back to `FRONTEND_URL` |

They are read through `ConfigService` rather than added to the Joi schema in
`env.validation.ts`, precisely so that a deploy without them still boots.

**Rotating the keys invalidates every existing subscription.** Browsers bind
a subscription to the public key it was created with; after a rotation every
row in `push_subscriptions` is dead and will be pruned on its next failed
send, and every user has to re-enable. Generate once and keep them.

**Push requires HTTPS**, which Railway already provides. It will not work
over plain HTTP beyond `localhost`.
