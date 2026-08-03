# Sport X Hub — Official Project Roadmap (V1 MVP)

**Status:** APPROVED — this is the binding execution plan for the project.
**Rule:** No feature is implemented unless it is listed in this document under "Final MVP Scope." Any change to scope requires an explicit, separate request from the project owner and a new revision of this file.

**Revision note:** This document supersedes the earlier PostgreSQL/Prisma-based draft. The database layer has been changed to **MongoDB Atlas + Mongoose** per an explicit architecture decision. Business logic and MVP scope are unchanged.

---

## 1. Project Summary

Sport X Hub is a professional sports talent marketplace connecting **Players** and **Clubs**. Version 1 exists to validate one loop only:

> **A Player builds a credible profile → A Club finds that player through search → A Club contacts that player directly (WhatsApp / Email / Phone).**

Nothing is built that does not serve this loop.

## 2. Technology Stack (fixed, do not change)

| Layer | Technology |
|---|---|
| Frontend | Flutter Web, responsive (Desktop + Mobile), Clean Architecture |
| State Management | Riverpod |
| Routing | Go Router |
| Backend | NestJS |
| Database | **MongoDB Atlas** |
| ODM | **Mongoose** |
| Auth | JWT (access + refresh) |
| Media Storage | Cloudinary (binary assets never touch MongoDB — only `public_id` / `secure_url` / metadata are stored) |

> PostgreSQL, Prisma, and Prisma Migrations are **removed entirely** from this project. No Prisma dependency, config, or schema file should exist anywhere in the codebase.

## 3. Non-Negotiable Architecture Rules

### 3.1 Desktop and Mobile are separate presentation layers

Desktop UI is **never** a stretched or breakpoint-hidden version of Mobile UI, and vice versa. No `if (width > 900)` branching inside a single widget tree for layout decisions at the feature level.

Every feature folder is structured as:

```
features/
  <feature_name>/
    domain/            <-- entities, repository interfaces, use cases (shared)
    data/               <-- repository implementations, DTOs (shared)
    application/        <-- Riverpod providers/controllers (shared)
    presentation/
      desktop/          <-- Desktop-only widgets and screens
      mobile/           <-- Mobile-only widgets and screens
      shared/           <-- truly platform-agnostic atoms (rare: e.g. a text formatter)
```

Only `domain/`, `data/`, and `application/` are shared. Presentation is 100% forked. A single top-level responsive shell (built in Phase 0) decides — once, at the router/shell level — which presentation tree to mount. Individual features do not re-implement that decision.

### 3.2 Backend module structure (NestJS + Mongoose)

Every backend feature follows the same internal shape:

```
src/
  <feature>/
    <feature>.module.ts
    <feature>.controller.ts
    <feature>.service.ts
    schemas/
      <feature>.schema.ts       <-- @Schema() Mongoose class + indexes
    dto/
      create-<feature>.dto.ts
      update-<feature>.dto.ts
    repositories/
      <feature>.repository.ts    <-- wraps the Mongoose Model; only added when a service
                                      needs non-trivial queries worth isolating for testing
```

- Schemas are defined with `@nestjs/mongoose` decorators (`@Schema()`, `@Prop()`).
- Indexes are declared directly on the schema (`@Prop({ index: true })` or `schema.index({...})`), never added ad hoc later.
- Controllers stay thin (validation via DTOs + guards only); business logic lives in services.
- ObjectId references are used between collections (e.g. `PlayerProfile.userId: Types.ObjectId`) — no cross-collection joins are simulated in application code beyond a `.populate()` where genuinely needed.

### 3.3 Design Style

- Modern SaaS, professional, minimal, fast.
- Full Dark Mode + Light Mode support from Phase 0 onward (theming is not retrofitted later).
- **Desktop** experience takes inspiration from LinkedIn, Transfermarkt, Linear, Notion — dense information layout, sidebar navigation, data tables/grids, hover states.
- **Mobile** experience takes inspiration from native apps — bottom navigation, card-based lists, gesture-friendly touch targets. Not a shrunk desktop page.

### 3.4 Branding

The existing `logo.png` (already present in the project root) is used as-is — **no redesign**. Applied to:
- Splash screen
- Login screen
- Register screen
- Desktop sidebar
- Desktop/Mobile header
- Browser favicon

## 4. Development Workflow (mandatory process for every phase)

Each phase follows exactly this sequence, with **one and only one** review checkpoint:

```
Start Phase
   ↓
Implement everything in the phase (backend + Flutter, both layouts)
   ↓
ONE review pass (correctness, architecture adherence, acceptance criteria)
   ↓
Fix issues found in that review
   ↓
Commit
   ↓
Start next phase
```

No mid-phase reviews. No re-reviewing the same code twice. A phase is not "done" until its Acceptance Criteria are met and the single review + fix pass is complete.

### 4.1 Git workflow

- One commit per completed phase, and only one.
- Never commit incomplete or unreviewed work.
- Commit message format: `Phase X: <Phase Name>` (e.g. `Phase 0: Project Foundation`, `Phase 1: Authentication`, `Phase 2: Player Profile`).
- No extra commits inside a phase unless explicitly requested by the project owner.
- `.gitignore` covers Flutter build artifacts, NestJS `node_modules`/`dist`, environment files (`.env*`), and editor/OS files — secrets and generated output are never committed.

---

## 5. Scope Discipline

Every feature below survived this test: **"Can the platform launch professionally without this feature?"** If the honest answer was yes, it was moved to Post Launch. The result is intentionally small.

**Explicitly excluded from V1 (see Section 8 for full Post-Launch list):** in-app chat, WebSockets, notifications system, AI features, payments, advanced analytics, digital contracts/e-signatures, Scout role, Agent role, Academy role, Trials.

---

## 6. Phases

### PHASE 0 — Foundation & Architecture Skeleton

**Goal:** Prove the full stack boots end-to-end and prove the Desktop/Mobile forked-presentation pattern works, before any real feature is written.

**Features:**
- Flutter project scaffold with Clean Architecture folder structure
- NestJS project scaffold + Mongoose connected to a MongoDB Atlas cluster
- Responsive root shell that mounts either the Desktop or Mobile presentation tree
- Theming system: Light + Dark mode, using brand colors derived from `logo.png`
- Logo integrated into Splash screen and favicon
- Cloudinary credentials wired (unused until Phase 2)
- Environment config for dev/staging/prod (`.env` files, never committed)

**Flutter Screens:**
- Splash Screen (with logo)
- Empty Home shell — Desktop layout (sidebar + topbar placeholder)
- Empty Home shell — Mobile layout (bottom nav placeholder)

**Backend Modules:**
- `Health` module

**Collections / Schemas:**
- None yet (connection to Atlas verified via health check only)

**APIs:**
- `GET /health` (also verifies live MongoDB connection state)

**Acceptance Criteria:**
- App runs on Flutter Web and is confirmed buildable for Android without project rework.
- Resizing the browser window across the Desktop/Mobile breakpoint swaps to a genuinely different widget tree, not a reflowed one.
- Dark/Light mode toggle works.
- Backend responds to `/health` from the Flutter app and confirms an active MongoDB Atlas connection.
- No Prisma package, config, or schema file exists anywhere in the repository.

**Estimated Difficulty:** Low–Medium

---

### PHASE 1 — Authentication & User Core

**Goal:** A real user can register as a Player or a Club, log in, and land on a role-specific dashboard.

**Features:**
- Register (role choice limited to **Player** or **Club** only)
- Login / Logout
- JWT access + refresh token flow
- Forgot / reset password
- Role-based route guarding via Go Router redirects
- Basic account settings (change email, change password)

**Flutter Screens:**
- Login (Desktop + Mobile)
- Register with role picker (Desktop + Mobile)
- Forgot Password
- Reset Password
- Empty Player Dashboard (Desktop + Mobile)
- Empty Club Dashboard (Desktop + Mobile)
- Account Settings

**Backend Modules:**
- `Auth`
- `Users`

**Collections / Schemas:**
- **`users`** — `{ email (unique index), passwordHash, role: 'PLAYER' | 'CLUB' | 'ADMIN', status, createdAt, updatedAt }`
- **`refreshtokens`** — `{ userId (indexed, ref: User), tokenHash, expiresAt (TTL index), createdAt }`
- **`passwordresettokens`** — `{ userId (indexed, ref: User), tokenHash, expiresAt (TTL index), createdAt }`

**APIs:**
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `GET /users/me`
- `PATCH /users/me`

**Acceptance Criteria:**
- A Player and a Club can each independently register, log in, and reach their correct, protected dashboard.
- An expired/invalid access token is transparently refreshed or forces re-login.
- Password reset email flow works end-to-end in a test environment.
- `users.email` has a unique index and duplicate registration is rejected at the database level, not just application level.

**Estimated Difficulty:** Medium

> 🔒 Phase 0 and Phase 1 are hard blockers. Nothing else in the project can begin before Phase 1 is complete.

---

### PHASE 2 — Player Profile (incl. Contact Details)

**Goal:** A Player can build a profile complete enough for a Club to make a real evaluation and contact decision — this is the core data asset of the marketplace.

**Features:**
- Personal information (name, date of birth, nationality, country, city)
- Sports information (sport, position, preferred foot, height, weight, current status/club)
- Photo upload (profile photo + gallery) via Cloudinary
- Video upload/link (Cloudinary) — no analysis, just storage/playback
- Achievements (simple list: title, year, description)
- Social links (Instagram, YouTube, X, etc.)
- **Contact details: phone number, email, WhatsApp number**
- Visibility setting: **Public or Private only** (binary — no tiered visibility in V1)
- Public player profile page (read-only, shareable URL, respects visibility)

**Flutter Screens:**
- Edit Profile — Desktop (multi-column sectioned form) and Mobile (step/accordion form)
- My Profile Preview
- Public Player Profile page (Desktop + Mobile)

**Backend Modules:**
- `Players` (profile CRUD + media/achievement/social-link sub-resources)

**Collections / Schemas:**
- **`playerprofiles`** — one document per player:
  ```
  {
    userId: ObjectId (unique index, ref: User),
    firstName, lastName, dateOfBirth,
    nationality, country (indexed), city,
    sport (indexed), position (indexed),
    preferredFoot (indexed), height (indexed), weight (indexed),
    bio,
    contact: { phone, email, whatsapp },
    visibility: 'PUBLIC' | 'PRIVATE' (indexed),
    media: [ { type: 'PHOTO' | 'VIDEO', publicId, secureUrl, isProfilePhoto } ],   // embedded — bounded, small array per player
    achievements: [ { title, year, description } ],                              // embedded — small array
    socialLinks: [ { platform, url } ],                                          // embedded — small array
    createdAt, updatedAt
  }
  ```
  Media, achievements, and social links are embedded as subdocuments rather than separate collections: each array is small and bounded per player, always read/written together with the profile, and embedding avoids extra round trips at read time — the pattern that would justify a separate collection (unbounded growth, independent access patterns) doesn't apply here.
  Cloudinary is the source of truth for binary media; MongoDB stores only `publicId` / `secureUrl` / lightweight metadata.
- **`sports`** — lookup collection: `{ name (unique index) }`, seeded via script.
- **`countries`** — lookup collection: `{ name, code (unique index) }`, seeded via script.

**Indexes (for scale — hundreds of thousands of players):**
- Compound index `{ sport: 1, position: 1, country: 1 }` for the most common search combination.
- Individual indexes on `visibility`, `preferredFoot`, `height`, `weight` to support additional filter combinations efficiently.

**APIs:**
- `GET/PATCH /players/me`
- `POST /players/me/media`, `DELETE /players/me/media/:id`
- `GET/POST/PATCH/DELETE /players/me/achievements`
- `GET/POST/PATCH/DELETE /players/me/social-links`
- `PATCH /players/me/visibility`
- `GET /players/:id` (public, respects visibility)

**Acceptance Criteria:**
- A Player completes a profile with at least one photo, one video, sports info, and contact details.
- Setting visibility to Private removes the profile from public view and search immediately.
- A public profile URL renders correctly on both Desktop and Mobile layouts.
- Cloudinary assets are deletable independently (via `publicId`) when a Player removes a photo/video, and MongoDB never stores raw binary data.

**Estimated Difficulty:** Medium–High (Cloudinary media handling is the primary risk/time driver in this phase)

---

### PHASE 3 — Club Profile, Player Search, Save Player & Simple Contact

**Goal:** The actual marketplace transaction. A Club can find real players and reach out — this phase alone delivers the product's core value proposition.

**Features:**
- Club profile (name, country, city, logo, description, founded year, level)
- Player search with filters: **Country, Age, Position, Height, Weight, Preferred Foot, Sport**
- Save Player (bookmark) / Saved Players list
- **Simple Contact**: on a player's profile, a logged-in Club sees Contact actions — WhatsApp (`wa.me` deep link), Email (`mailto:`), Phone (`tel:`). No in-app messaging, no conversation history stored, no WebSocket.

**Flutter Screens:**
- Edit Club Profile (Desktop + Mobile)
- My Club Profile (public view)
- Search Players — Desktop (filter sidebar + data grid) and Mobile (filter sheet + card list)
- Saved Players list (Desktop + Mobile)

**Backend Modules:**
- `Clubs`
- `Search` (query endpoints, can live inside the `Players` module)
- `SavedPlayers`

**Collections / Schemas:**
- **`clubprofiles`** — `{ userId (unique index, ref: User), name, country (indexed), city (indexed), logo: { publicId, secureUrl }, description, foundedYear, level, createdAt, updatedAt }`
- **`savedplayers`** — `{ clubUserId (indexed, ref: User), playerId (indexed, ref: PlayerProfile), createdAt }` with a **compound unique index** on `{ clubUserId: 1, playerId: 1 }` to prevent duplicate saves, plus a standalone index on `playerId` for reverse lookups (e.g. "how many clubs saved this player").

**APIs:**
- `GET/PATCH /clubs/me`, `GET /clubs/:id`
- `GET /players?country=&minAge=&maxAge=&position=&minHeight=&maxHeight=&weight=&preferredFoot=&sport=&page=`
- `POST /saved-players/:playerId`, `DELETE /saved-players/:playerId`, `GET /saved-players/me`

**Acceptance Criteria:**
- A Club filters players by at least 3 combined criteria and receives correct, paginated results within acceptable latency at seed-scale test data (10k+ synthetic player documents).
- A Club saves a player and the saved list persists across sessions; saving the same player twice is rejected by the unique index, not just app logic.
- A Club viewing a public player profile sees working WhatsApp/Email/Phone contact actions when the player has provided them.

**Estimated Difficulty:** Medium–High (query performance and correctness under combined filters is the highest-reputation-risk feature in the MVP)

> ✅ Parallelization: Once the `playerprofiles` schema (not the full Phase 2 UI) is frozen, Phase 3 can be developed in parallel with the remainder of Phase 2 by a second developer.

---

### PHASE 4 — Minimal Admin

**Goal:** Give the platform operator just enough control to launch responsibly.

**Features:**
- View all Users, suspend/activate/delete a user
- View all Players and Clubs (read-only list + ability to remove a profile)

*Explicitly out of scope for V1:* CRUD UI for Sports/Countries (seeded via script), Reports/flagging system, Settings panel.

**Flutter Screens:**
- Admin Users list (Desktop only — admin tooling does not require a mobile layout for V1)
- Admin Players/Clubs list

**Backend Modules:**
- `Admin` (thin — reuses `Users`, `Players`, `Clubs` modules behind an admin guard)

**Collections / Schemas:**
- None new (reuses `users`, `playerprofiles`, `clubprofiles`)

**APIs:**
- `GET /admin/users`, `PATCH /admin/users/:id/status`, `DELETE /admin/users/:id`
- `GET /admin/players`, `DELETE /admin/players/:id`
- `GET /admin/clubs`, `DELETE /admin/clubs/:id`

**Acceptance Criteria:**
- An admin account (seeded manually, not self-registrable) can suspend a user and that user immediately loses access.
- An admin can remove an inappropriate player or club profile, including its Cloudinary assets.

**Estimated Difficulty:** Low

> ✅ Parallelization: Fully independent of Phase 3's search work; can be built by a second developer in parallel once Phase 1 and Phase 2 schemas exist.

---

### PHASE 5 — Public Marketing Site & Launch Polish

**Goal:** The conversion funnel for a cold visitor, plus final cross-device hardening. This is the Launch Candidate gate.

**Features:**
- Home, About, Pricing (informational only — no billing integration), Contact form
- Public Players listing and Public Clubs listing (reuse Phase 2/3 data)
- SEO basics (meta tags, sitemap)
- Full Desktop + Mobile responsive QA pass
- Empty-state and error-state polish across all screens built in Phases 1–4

**Flutter Screens:**
- Home, About, Pricing, Contact (Desktop + Mobile)

**Backend Modules:**
- `Contact`

**Collections / Schemas:**
- **`contactmessages`** — `{ name, email, message, createdAt }`

**APIs:**
- `POST /contact`

**Acceptance Criteria:**
- A first-time visitor can land on Home, browse real Player and Club listings, understand Pricing, and complete Registration — the full funnel works without errors on both Desktop and Mobile.
- Dark/Light mode and logo branding are consistent across every public page.

**Estimated Difficulty:** Low

---

## 7. Development Order & Parallelization Summary

**Strict sequence (hard blockers):** Phase 0 → Phase 1 → (Phase 2 schema freeze) → Phase 3

**Parallel tracks once unblocked:**
- Phase 2 (Player) and Phase 3 (Club/Search/Contact) — after the `playerprofiles` schema is frozen
- Phase 4 (Admin) can run parallel to Phase 3 or Phase 2, once Phase 1 is complete
- Phase 5's static pages (Home/About/Pricing/Contact) can start as early as Phase 0; its data-driven listing pages wait on Phase 2/3

**Highest risk items:** Cloudinary media upload reliability (Phase 2), search filter correctness/performance at scale (Phase 3).

---

## 8. Final MVP Scope (V1 — what ships at launch)

✔ Authentication (Player + Club roles)
✔ Player Profiles (info, media, achievements, social links, contact details, public/private visibility)
✔ Club Profiles
✔ Player Search (7 filters)
✔ Save Players
✔ Simple Contact (WhatsApp / Email / Phone links — no in-app messaging)
✔ Minimal Admin (user/profile moderation)
✔ Public marketing site

## 9. Post Launch (V1.1)

- In-app messaging → real-time Chat (WebSocket)
- Notifications system (in-app + push)
- Scout role (profile, save/contact players)
- Agent role (profile, manage represented players)
- Academy role (profile, publish/associate players)
- Trials (publish, listing, interest tracking)
- Reports / content-flagging system
- Full Admin CRUD for Sports/Countries/Categories, Settings panel
- Certificates upload
- Granular profile visibility (e.g., "Clubs-only" tier)
- Email verification on signup
- Public listings for Academies, Scouts, Agents, Trials

## 10. Version 2 (Future, out of near-term planning)

- Payment gateway / subscriptions / boosted listings
- Digital contracts & electronic signatures
- AI-powered player recommendations
- Video performance analysis
- Advanced analytics & benchmarking
- Identity verification (verified badges)
- Native mobile-specific features beyond responsive web (offline mode, native push)
- Multi-agency/team accounts with sub-permissions

---

*This document is the single source of truth for Sport X Hub V1. Do not implement any feature not listed under Section 8. Do not modify this roadmap without an explicit request from the project owner.*
