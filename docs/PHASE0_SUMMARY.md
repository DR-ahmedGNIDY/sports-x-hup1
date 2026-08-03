# Phase 0 Summary — Technical Reference

**Status:** Phase 0 (Project Foundation) approved, cleaned up, and committed. This document is the technical reference for the codebase as it exists after that cleanup — read it before writing any Phase 1 code. It complements, but does not replace, [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) (which governs *scope and phases*); this file governs *how the code already here is organized and why*.

---

## 1. Folder Structure

```
sport x hub/
  logo.png                      Original brand asset (source of truth, provenance copy)
  README.md                     Setup instructions for both apps
  .gitignore                    Repo-wide ignore rules (Flutter/Nest/Mongo/env/OS)
  docs/
    PROJECT_ROADMAP.md            Binding phase-by-phase execution plan
    PHASE0_SUMMARY.md             This file

  frontend/                     Flutter Web app (Desktop + Mobile, Android-buildable)
    .env.example                 Documented env vars (no secrets — just API base URL)
    pubspec.yaml
    lib/
      main.dart                    App entrypoint: loads Env, wires theme + router
      core/                        Cross-cutting code shared by every feature
        config/
          env.dart                   Typed .env access (Env.apiBaseUrl, Env.appEnv)
        network/
          api_client.dart            Thin HTTP wrapper over Env.apiBaseUrl
        providers/
          health_check_provider.dart Diagnostic-only: proves Flutter <-> NestJS connectivity
        router/
          app_router.dart            go_router route table
        theme/
          app_colors.dart            Brand palette (derived from logo.png)
          app_text_styles.dart       Shared type scale
          app_theme.dart             Light/Dark ThemeData (Material 3)
          theme_mode_provider.dart   Dark/Light toggle state + themeModeToggleIcon()
        utils/
          breakpoints.dart           The ONE place screen width is inspected
        widgets/
          app_logo.dart              Renders assets/images/logo.png — the only place that does
          backend_status_indicator.dart  Shared diagnostic atom (dot + label)
          responsive_layout.dart     Mounts exactly one of {desktop, mobile} per screen
      features/
        splash/
          presentation/
            desktop/splash_page_desktop.dart
            mobile/splash_page_mobile.dart
            splash_page.dart         Picks desktop/mobile via ResponsiveLayout
        home/
          presentation/
            desktop/home_page_desktop.dart   Sidebar + topbar shell
            mobile/home_page_mobile.dart      Bottom-nav shell
            home_page.dart            Picks desktop/mobile via ResponsiveLayout
    assets/images/logo.png         The single bundled copy the running app reads
    web/                          Generated favicon/icons/manifest (see §7)
    android/                      Generated adaptive icons (see §7)
    test/widget_test.dart          Smoke test

  backend/                       NestJS API
    .env.example                   Documented env vars, empty placeholders
    package.json
    tsconfig.json / tsconfig.build.json
    nest-cli.json
    .eslintrc.js / .prettierrc
    src/
      main.ts                      Bootstrap, global ValidationPipe, fail-fast on boot error
      app.module.ts                Root module: ConfigModule + MongooseModule + feature modules
      config/
        env.validation.ts          Joi schema — validates/defaults process.env
      health/
        health.module.ts
        health.controller.ts       GET /health
        health.service.ts          Reads live Mongo connection readyState
        health.service.spec.ts     Unit test
```

### Why this shape won't need refactoring later

Every future feature (Auth, Players, Clubs, ...) drops into `features/<name>/` following the **same four-folder pattern** already established structurally by the roadmap and used here at the presentation layer:

```
features/<name>/
  domain/          entities, repository interfaces, use cases      (shared)
  data/            repository implementations, DTOs/mappers        (shared)
  application/     Riverpod providers/controllers                  (shared)
  presentation/
    desktop/        Desktop-only widgets and screens
    mobile/          Mobile-only widgets and screens
```

`splash` and `home` currently only have `presentation/` because Phase 0 has no domain logic — there is nothing to put in `domain/data/application` yet, and creating empty placeholder folders for hypothetical future code was deliberately avoided. When Phase 1 adds a feature with real state (Auth), it introduces `domain/data/application` for the first time, and every feature after it follows the same shape from day one. No existing folder gets renamed or moved to make that happen.

**Rule of thumb for "where does this new file go?"**
- Touches only one feature's screens/state → inside that `features/<name>/`.
- Genuinely cross-cutting (used by 3+ unrelated features, or infrastructure like HTTP/env/theme/routing) → `core/`.
- A Riverpod provider that is feature-specific → `features/<name>/application/`.
- A Riverpod provider that is infrastructure (API client, theme mode, auth session) → `core/providers/` or co-located with the thing it wraps (e.g. `theme_mode_provider.dart` lives in `core/theme/`, not `core/providers/`, because it's theme infrastructure specifically). `core/providers/` is reserved for providers that don't belong to any single core subsystem, like the diagnostic health check.

---

## 2. Packages Used

Every dependency below is **actively imported by committed code**. Nothing is present "for later" — when Phase 2 needs Cloudinary image display, `cached_network_image` gets added back then, not before.

### Frontend (`frontend/pubspec.yaml`)

| Package | Why it's here |
|---|---|
| `flutter_riverpod` | State management (roadmap-mandated) |
| `go_router` | Routing (roadmap-mandated) |
| `flutter_dotenv` | Loads `.env` for `Env` (core/config) |
| `http` | Used by `ApiClient` (core/network) |
| `flutter_lints` (dev) | Powers `analysis_options.yaml`; `flutter analyze` is clean |
| `flutter_launcher_icons` (dev) | Generated the web favicon/icons and Android adaptive icons from `logo.png` (§7). Kept as a dev tool so icons can be regenerated with `dart run flutter_launcher_icons` if the logo ever changes — not needed at app runtime. |

Removed during cleanup as unused: `cached_network_image` (no network images rendered yet — Phase 2 will re-add it when Player media display is built), `cupertino_icons` (no `CupertinoIcons` referenced anywhere; all icons used so far are Material).

### Backend (`backend/package.json`)

| Package | Why it's here |
|---|---|
| `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express` | NestJS framework core |
| `@nestjs/config` + `joi` | Typed, validated environment config (`ConfigModule` + `env.validation.ts`) |
| `@nestjs/mongoose` + `mongoose` | Database layer (MongoDB Atlas + Mongoose, per the architecture decision) |
| `class-validator`, `class-transformer` | Required at runtime by the global `ValidationPipe` wired in `main.ts`. No DTOs use their decorators yet (Phase 1 will be first), but the pipe itself is active now and depends on these packages to function. |
| `reflect-metadata`, `rxjs` | Standard NestJS peer requirements |
| `typescript`, `@types/node`, `@types/express` (dev) | Compilation/typing |
| `eslint` + `@typescript-eslint/*` + `eslint-config-prettier` + `eslint-plugin-prettier` + `prettier` (dev) | Lint/format — `npm run lint` is clean |
| `jest`, `ts-jest`, `@types/jest` (dev) | Test runner — `health.service.spec.ts` passes |
| `ts-node-dev` (dev) | Watch-mode dev server (`npm run start:dev`) |

Removed during cleanup as unused: `tsconfig-paths` (was wired into the `start:dev` script via `-r tsconfig-paths/register`, but `tsconfig.json` defines no `paths` aliases — all imports are relative. If path aliases are introduced later, re-add it then and configure `paths` at the same time).

---

## 3. Architecture Decisions

- **MongoDB Atlas + Mongoose**, not PostgreSQL/Prisma. Every schema is a Mongoose `@Schema()` class with indexes declared inline. See `PROJECT_ROADMAP.md` §2–3.2 for the full rationale and the standard module shape (`module/controller/service/schemas/dto/repositories`).
- **Config validation fails fast, not silently.** `env.validation.ts` only *requires* what Phase 0 code actually consumes (`MONGODB_URI`, with a safe local-dev default). `JWT_SECRET`, `JWT_REFRESH_SECRET`, and the `CLOUDINARY_*` keys are declared and documented in `.env.example` per the project owner's instruction, but intentionally not validated as required yet — nothing in the codebase reads them. Phase 1/2 will tighten this schema when Auth/Cloudinary code starts consuming them, so a missing secret fails loudly at the point it's actually needed instead of blocking unrelated work today.
- **Database connectivity is required to fully boot the API — this is standard, not a bug.** Verified directly: without a reachable Mongo, `MongooseModule` retries 3 times (~15s total, `serverSelectionTimeoutMS: 3000`, `retryDelay: 2000`) and then `main.ts`'s `bootstrap().catch()` exits with a clear message, instead of hanging indefinitely. `npm run build`, `npm run lint`, and `npm test` all work with zero database dependency. Confirmed working end-to-end against a real local MongoDB container (`GET /health` → `{"status":"ok","database":"connected"}`).
- **Diagnostic health check across the stack.** `core/providers/health_check_provider.dart` + `BackendStatusIndicator` call the real `GET /health` endpoint and render a connectivity dot in both Home shells. This is infrastructure verification, not a business feature — it exists to prove the two apps actually talk to each other, per the roadmap's Phase 0 goal.

---

## 4. Shared Layers (Frontend)

Only three kinds of code are shared between Desktop and Mobile, and all of it lives outside `presentation/`:

1. **`domain/`** — entities, repository interfaces, use cases (none yet — introduced in Phase 1)
2. **`data/`** — repository implementations, DTOs (none yet — introduced in Phase 1)
3. **`application/`** — Riverpod providers/controllers, either feature-scoped (`features/<name>/application/`) or cross-cutting (`core/`)

Everything under `presentation/desktop/` and `presentation/mobile/` is platform-specific and **never imports the other platform's presentation code.** They both import the same `domain/data/application` and `core/` code, which is where all actual business logic and state lives.

**Concrete example already in the codebase:** `themeModeProvider` (state) and `themeModeToggleIcon()` (a tiny pure helper) live in `core/theme/theme_mode_provider.dart`. Both `HomePageDesktop`'s topbar and `HomePageMobile`'s app bar call the same provider and the same helper function to render their (differently laid out) dark-mode toggle button. Neither screen imports the other's file.

---

## 5. Desktop / Mobile Strategy

- The **only** place screen width is inspected is `AppBreakpoints.isDesktop()` (`core/utils/breakpoints.dart`, 900px threshold).
- The **only** widget that acts on that check is `ResponsiveLayout` (`core/widgets/responsive_layout.dart`) — it mounts exactly one of two independent `WidgetBuilder`s.
- Every screen-level entry point (`SplashPage`, `HomePage`) is a small wrapper that does nothing but call `ResponsiveLayout` with its `desktop`/`mobile` widget. The actual screens (`SplashPageDesktop`, `SplashPageMobile`, `HomePageDesktop`, `HomePageMobile`) are separate files with zero shared widget code between them.
- **Small platform-agnostic atoms used by both** (`AppLogo`, `BackendStatusIndicator`) live in `core/widgets/`, not inside either presentation tree — they contain no layout decisions of their own (no breakpoint checks, no `if` on platform), they're just reusable leaf components any screen can drop in. This is different from — and does not violate — "Desktop never reuses Mobile widgets": `AppLogo` isn't a Desktop widget or a Mobile widget, it never lived in either presentation folder to begin with.

---

## 6. Backend Architecture

Standard NestJS module shape, applied consistently (see `health/` as the reference example every future module should match):

```
src/<feature>/
  <feature>.module.ts       Wires controller + service (+ MongooseModule.forFeature once schemas exist)
  <feature>.controller.ts   Thin — routes + DTOs/guards only, no business logic
  <feature>.service.ts      Business logic
  <feature>.service.spec.ts Unit tests
  schemas/                  Mongoose @Schema() classes + indexes (added when the feature has data)
  dto/                      class-validator-decorated request/response shapes (added when needed)
  repositories/             Only added when a service's queries are complex enough to warrant isolating
```

`ConfigModule` (global) and `MongooseModule` (root connection) are wired once in `AppModule`; feature modules never configure their own database connection — they inject models via `MongooseModule.forFeature([...])` when they have schemas (starting Phase 1's `User` schema).

---

## 7. Logo Asset — Single Source of Truth

- **`/logo.png`** (repo root) is the original asset the project owner provided. It is not read by any running code — it exists as the canonical provenance copy.
- **`frontend/assets/images/logo.png`** is the one and only copy the running Flutter app reads, and it is read from exactly one place in code: `core/widgets/app_logo.dart`. Every screen that needs the logo renders `<AppLogo />` — no screen references the image path directly, and no second copy exists anywhere under `lib/`.
- **`frontend/web/favicon.png`, `frontend/web/icons/*.png`, `frontend/android/**/ic_launcher*.png`** are *generated derivatives*, not hand-made duplicates — produced by `dart run flutter_launcher_icons` (config lives in `pubspec.yaml` under `flutter_launcher_icons:`) reading the single source at `assets/images/logo.png`. **Never hand-edit these files.** If the logo changes, replace `assets/images/logo.png` and re-run `dart run flutter_launcher_icons`.

---

## 8. Environment Variables

Neither `.env` is committed (`.gitignore` covers `.env` / `.env.*` everywhere in the repo, `!.env.example` explicitly un-ignores the templates).

**`frontend/.env.example`**
```
API_BASE_URL=http://localhost:3000
APP_ENV=development
```
No secrets on the frontend — just where to find the backend.

**`backend/.env.example`**
```
NODE_ENV=development
PORT=3000
MONGODB_URI=            # falls back to mongodb://127.0.0.1:27017/sportxhub if empty
JWT_SECRET=              # required starting Phase 1
JWT_REFRESH_SECRET=      # required starting Phase 1
CLOUDINARY_CLOUD_NAME=   # required starting Phase 2
CLOUDINARY_API_KEY=      # required starting Phase 2
CLOUDINARY_API_SECRET=   # required starting Phase 2
```

---

## 9. Things a Future Developer Should Know

- **Run `npm run lint` / `dart run flutter_launcher_icons` etc. from inside `backend/` or `frontend/` respectively** — there is no root-level package manager or task runner tying the two apps together, by design (they're independently deployable).
- **CORS is currently wide open** (`app.enableCors()` with no options in `main.ts`). Fine for local development; must be scoped to the real frontend origin before any non-local deployment.
- **No auth exists yet.** `HomePage` is reachable with no session check — Phase 1 replaces the splash screen's timer-based navigation with a real session check and adds route guarding.
- **Jest config lives inline in `backend/package.json`** (not a separate `jest.config.js`) — this is intentional, matches the Nest starter convention, and keeps config discoverable in one file alongside scripts/dependencies.
- **Git workflow is strict:** one commit per completed phase (`Phase X: <Name>`), one review pass per phase, no mid-phase commits unless explicitly requested. This cleanup pass was an explicit exception requested between Phase 0 and Phase 1 and is committed separately from both.
