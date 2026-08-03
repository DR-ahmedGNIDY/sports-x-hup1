# Sport X Hub

A professional sports talent marketplace connecting Players and Clubs.

This is **Version 1 (MVP)**. Scope, architecture rules, and the phase-by-phase execution plan are documented in [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) — that file is the source of truth for what gets built and in what order. Read it before making any scope decisions.

## Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web, responsive (Desktop + Mobile), Clean Architecture |
| State Management | Riverpod |
| Routing | Go Router |
| Backend | NestJS |
| Database | MongoDB Atlas |
| ODM | Mongoose |
| Auth | JWT (access + refresh) |
| Media Storage | Cloudinary |

## Repository Layout

```
sport x hub/
  frontend/          Flutter Web app (Desktop + Mobile, buildable for Android)
  backend/            NestJS API
  docs/
    PROJECT_ROADMAP.md   Official phase-by-phase execution plan (binding)
  logo.png            Official brand asset — do not redesign
```

## Frontend (`frontend/`)

Clean Architecture, with Desktop and Mobile as **fully separate presentation
trees** sharing only domain/data/application code:

```
lib/
  core/              theme, router, config, network, shared widgets/utils
  features/
    <feature>/
      domain/          entities, repository interfaces, use cases (shared)
      data/             repository implementations, DTOs (shared)
      application/      Riverpod providers/controllers (shared)
      presentation/
        desktop/         Desktop-only widgets and screens
        mobile/           Mobile-only widgets and screens
```

### Setup

```bash
cd frontend
cp .env.example .env
flutter pub get
flutter run -d chrome
```

`.env` holds only the backend API base URL — no secrets live in the frontend.

## Backend (`backend/`)

Standard NestJS module shape used by every feature:

```
src/
  <feature>/
    <feature>.module.ts
    <feature>.controller.ts
    <feature>.service.ts
    schemas/            Mongoose @Schema() classes + indexes
    dto/
    repositories/        only when a service needs non-trivial queries
```

### Setup

```bash
cd backend
cp .env.example .env
# fill in MONGODB_URI (Atlas or local), JWT secrets, Cloudinary keys
npm install
npm run start:dev
```

Until real credentials are provided, `MONGODB_URI` falls back to a local
`mongodb://127.0.0.1:27017/sportxhub` default. Like any NestJS + Mongoose
API, the server needs a reachable database to finish booting: with none
available it retries 3 times (~15s total) and then exits with a clear
`MONGODB_URI` error instead of hanging — `npm run build`, `npm run lint`,
and `npm test` all work with no database at all. Once `MONGODB_URI` points
at a reachable Atlas cluster (or a local `mongod`), `npm run start:dev`
boots normally and `GET /health` returns `database: "connected"`.

## Environment Variables

Neither `.env` file is committed — see `frontend/.env.example` and
`backend/.env.example` for the full list of variables each app expects.
Never hardcode credentials in source.

## Development Workflow

Every phase in the roadmap follows exactly one review cycle:

```
Start Phase → Implement everything → One review pass → Fix issues → Commit → Next phase
```

Commits are one-per-completed-phase, formatted as `Phase X: <Phase Name>`.
