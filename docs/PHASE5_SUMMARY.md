# Phase 5 Summary — Public Marketing Site & Launch Polish

**Status:** Phase 5 implemented — read alongside [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (scope/phases), [`PHASE0_SUMMARY.md`](PHASE0_SUMMARY.md) (baseline architecture), and [`RELEASE_AUDIT.md`](RELEASE_AUDIT.md) (the pre-Phase-5 remediation pass this phase builds on top of).

---

## 1. Features Implemented

- **Home, About, Pricing, Contact** — public marketing pages (Desktop + Mobile), reachable with or without a session.
- **Public Players listing** (`/players`) and **Public Clubs listing** (`/clubs`) — reuse Phase 2/3 data, no auth required.
- **Public club profile** (`/clubs/:id`) — the public counterpart to the existing public player profile, using the `GET /clubs/:id` endpoint that already existed on the backend since Phase 3 but had no frontend consumer until now (`PHASE3_SUMMARY.md` §5 explicitly flagged this as deferred until "something actually calls it").
- **Contact form** — `POST /contact`, a new backend module, wired to the Contact page's form.
- **SEO basics** — meta description/keywords/robots/canonical, Open Graph and Twitter Card tags, and an updated `<title>` in `web/index.html`; `web/robots.txt` and `web/sitemap.xml` added.
- **Routing overhaul for the public funnel** — root `/` now sends an unauthenticated cold visitor to `/home` (marketing) instead of straight to `/login`; the marketing pages and the two public listings never bounce a visitor regardless of auth state, matching how `/players/:id` already behaved since Phase 2.

## 2. APIs

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/contact` | public | Rate-limited (5/min/IP, same pattern as auth endpoints); persists to `contactmessages` |
| GET | `/clubs` | public | New — paginated (page size 20), optional `?country=` filter; returns `{ items, page, pageSize, total }` |

`GET /clubs/:id` (Phase 3) is unchanged; this phase adds its first frontend consumer.

## 3. Database Changes

- **New collection `contactmessages`** — `{ name, email, message, createdAt }`, exactly as specified in the roadmap. No indexes beyond the implicit `_id` — this is a low-volume, write-only-from-the-app, admin-read-never-in-V1 collection; nothing in the roadmap's Phase 5 scope reads it back.

## 4. Flutter Screens

All new screens follow the established Desktop/Mobile fork:

- **Home** (`features/marketing`) — hero + value-prop feature cards, CTA to Register/Browse Players.
- **About**, **Pricing** (`features/marketing`) — static content pages; Pricing shows two free-during-launch plan cards (Player, Club), consistent with the roadmap's "informational only, no billing integration."
- **Contact** (`features/marketing`) — name/email/message form with loading/error/success states, backed by a new `ContactController`.
- **Public Players listing** (`features/search`) — new Desktop/Mobile pages that reuse the existing `PlayerSearchController`, `PlayerSearchFiltersForm`, `PlayerSearchResultCard`, and `SearchPagination` from the authenticated Club-facing Search tool (`/search`); only the outer chrome differs (marketing nav instead of a dashboard back button), since both routes already hit the same public `GET /players` endpoint.
- **Public Clubs listing** (`features/club`) — new Desktop/Mobile pages, a new `PublicClubsController`, `PublicClubCard`, and `ClubListPagination`, mirroring the Players listing's pattern.
- **Public Club Profile** (`features/club`) — reuses the existing `ClubProfileView` read-only renderer (previously only used for the owner's own "My Club" preview), the same pattern `PlayerProfileView` already followed for player profiles since Phase 2.

## 5. Architecture Decisions

- **Marketing chrome (nav bar / drawer) is factored into two plain functions** (`marketingDesktopNavActions`, `marketingMobileDrawer` in `features/marketing/presentation/shared/marketing_chrome.dart`), not a shared widget with its own layout decisions — each of the eight Desktop/Mobile marketing and public-listing screens calls the one matching its platform and places it into its own `AppBar`/`Drawer` independently. This is the same "platform-agnostic atom" carve-out `AppLogo`/`BackendStatusIndicator` already established in `core/widgets` since Phase 0 — the function contains no breakpoint check and makes no layout decision of its own.
- **The Public Players listing is a new presentation entry point onto the existing Search feature, not a new search implementation.** `PlayerSearchController`, the filters form, the result card, and pagination are all reused byte-for-byte; only the Scaffold/AppBar differ from `/search`. This avoids a second, parallel search implementation for what is functionally the same public endpoint.
- **`PlayerSearchResultCard` now checks `isClub` before rendering its bookmark button** (previously unconditional, since the card was only ever reachable by an authenticated Club through `/search`). Making the card reachable by anonymous/Player visitors through the new `/players` route surfaced this gap; the fix mirrors the same `isClub` check `SavePlayerButton` already used on the public player profile page.
- **Root `/` is treated purely as the technical splash/session-restore route, not a page in its own right.** Once `SessionController.restore()` resolves, `/` immediately redirects to `/dashboard` (authenticated) or `/home` (not) — `/home` is the actual landing page a cold, unauthenticated visitor sees, matching a standard marketing-site-first funnel. This is a deliberate change from Phase 1–4's behavior (where a logged-out cold visitor landed on `/login`); protected app routes (`/dashboard`, `/player/edit`, etc.) still redirect an unauthenticated visitor to `/login`, unchanged.

## 6. Security Decisions

- **`POST /contact` is rate-limited at the same strictness as the auth endpoints** (5 requests/minute/IP) — it's an unauthenticated, spam-prone public form, the same threat shape as `/auth/register`.
- **No new attack surface on existing authenticated endpoints.** `GET /clubs` (the new public listing endpoint) is deliberately unguarded (no `JwtAuthGuard`) since club profiles have no private fields to gate — same reasoning `clubs.mapper.ts` already documented for `GET /clubs/:id` since Phase 3.

## 7. Known Limitations

- **SEO meta tags are site-wide, not per-route.** Flutter Web is a client-rendered SPA with no server-side rendering, so `web/index.html`'s `<title>`/Open Graph/description tags are fixed for every route — a shared search engine crawl sees the same title/description for `/home`, `/players`, `/about`, etc. This is the ceiling of "SEO basics" achievable without introducing SSR, which is out of scope for this phase.
- **`web/robots.txt`, `web/sitemap.xml`, and the canonical/OG tags in `index.html` use a placeholder domain** (`sportxhub.com`) — must be updated to the real production domain at deploy time; each file is commented to say so.
- **The roadmap's "full Desktop + Mobile responsive QA pass" and "empty-state and error-state polish across all screens built in Phases 1–4" were not performed as an exhaustive pass in this phase.** The Release Readiness Audit (`RELEASE_AUDIT.md`) already covered loading/error/empty-state coverage in detail and found it largely compliant, with a small number of specific Low/Medium gaps (e.g. generic non-actionable error text on several screens) that remain open exactly as that audit reported them. This phase's own new screens (Home/About/Pricing/Contact/public listings) do have loading, error, and empty states built in from the start.
- **No automated test coverage was added** for the new backend `ContactModule` or the new frontend marketing/public-listing code — consistent with the project's established precedent (see `PHASE3_SUMMARY.md` §7), not a new regression.
- **End-to-end verification of the full funnel (Home → browse real listings → Register) against live data was not performed** — this development environment has no reachable MongoDB instance. Verification performed instead: `npm run build`/`lint`/`test` (backend) and `flutter analyze` (frontend) all clean; a built `flutter build web` bundle was served and every new route (`/home`, `/about`, `/pricing`, `/contact`, `/players`, `/clubs`, `/clubs/:id`, plus a cold-reload check on `/players/:id` and `/dashboard`) was confirmed to load without console errors and redirect correctly (public routes stay put, protected routes still bounce to `/login`). Confirming the funnel against real seeded data is a follow-up item before launch.

## 8. Future Extension Points

- `PublicClubsController`/`ClubListPagination` follow the exact pagination-envelope shape (`{ items, page, pageSize, total }`) introduced by the Release Audit's admin-pagination fix and already used by Player search — any future paginated public listing should follow the same shape.
- If a future phase adds SSR or pre-rendering, the per-page `<title>`/meta content already exists in each page's `Scaffold` (as visible text) and just needs to be lifted into `<head>` tags per route.
