# Deploying to Railway

Two services from one repository: `backend` (NestJS API) and `frontend`
(Flutter Web behind nginx). Each is built from its own directory and gets its
own public URL.

`backend/railway.json` and `frontend/railway.json` pin how each is built, so
the deploy does not depend on Railway guessing correctly. Everything else —
creating the services and setting their variables — happens in the Railway
dashboard, because it involves credentials.

---

## The ordering problem, first

The two services need each other's URLs, and neither URL exists until the
service does. Trying to set everything in one pass is where this goes wrong,
so do it in this order:

1. Create both services and let the first build run. It is fine for the
   backend's first deploy to fail its healthcheck — it has no variables yet.
2. Copy each service's generated domain from **Settings → Networking**.
3. Set the variables below, using those domains.
4. Redeploy both.

---

## Service 1 — `backend`

**Root directory:** `backend`
**Builder:** Nixpacks (from `railway.json`)
**Healthcheck:** `/health` — returns `{"status":"ok","database":"connected"}`

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `PORT` | *leave unset* — Railway injects it |
| `MONGODB_URI` | your Atlas connection string |
| `JWT_SECRET` | **generate a new one**, see below |
| `JWT_REFRESH_SECRET` | **generate a new one**, different from the above |
| `CORS_ORIGINS` | the frontend's Railway URL, e.g. `https://sportxhub-frontend.up.railway.app` |
| `FRONTEND_URL` | the same URL — used in password-reset emails |
| `CLOUDINARY_CLOUD_NAME` / `_API_KEY` / `_API_SECRET` | from your Cloudinary dashboard |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | the seeded admin account |
| `MAIL_PROVIDER` | **`brevo`** — see below |
| `BREVO_API_KEY` | from your Brevo account |

### Use `brevo`, not `smtp`

**Railway's trial plan blocks outbound ports 25, 465, 587 and 2525.** With
`MAIL_PROVIDER=smtp` every send dies on a TCP connection timeout before it ever
authenticates — and it fails *quietly*, in a background send, so the first
symptom is a user who never receives a password-reset email.

The codebase already anticipates this: `BrevoApiEmailProvider` sends the
identical message over ordinary HTTPS on 443, which no host blocks. Set
`MAIL_PROVIDER=brevo` and `BREVO_API_KEY`, and leave the `SMTP_*` variables
unset.

`MAIL_PROVIDER=console` is rejected outright in production — it never sends a
real email.

### What the service refuses to start without

Enforced by `src/config/env.validation.ts`:

- **`JWT_SECRET` and `JWT_REFRESH_SECRET` must be at least 32 characters.**
  Generate them fresh rather than reusing whatever is in your local `.env` — a
  secret that has lived on a developer machine is not a production secret:
  ```bash
  openssl rand -hex 64
  ```
- **`CORS_ORIGINS` is required in production and cannot be `*`.** The API sends
  credentials, and CORS forbids combining credentials with a wildcard origin.
  List the exact frontend origin.

## Service 2 — `frontend`

**Root directory:** `frontend`
**Builder:** Dockerfile (from `railway.json`)

| Variable | Value |
|---|---|
| `PORT` | *leave unset* — Railway injects it, and `docker-entrypoint.sh` substitutes it into the nginx config |
| `API_BASE_URL` | the backend's Railway URL, e.g. `https://sportxhub-backend.up.railway.app` |
| `APP_ENV` | `production` |

`API_BASE_URL` is **not** compiled into the bundle. `docker-entrypoint.sh`
writes it into the served `assets/.env` on every container start, so pointing
the frontend at a different API is a variable change and a restart, not a
rebuild.

---

## After the first successful deploy

- **`nginx -t` has already been run** against `docker/nginx.conf.template`, and
  the built site was served through it and measured: gzip brings `main.dart.js`
  from 4,406,720 to 1,231,075 bytes, `assets/.env` and the service worker are
  `no-store`, unknown deep links fall back to the shell, and a request with a
  matching `If-None-Match` returns 304.
- **Update the canonical URL.** `web/index.html` and `web/sitemap.xml` still
  carry the `https://sportxhub.com/` placeholder from before there was a real
  domain.
- **Measure Lighthouse against the deploy, not locally.** The plan's targets
  (Performance ≥ 85, FCP < 2.5s) were deliberately not claimed in M6, because
  the only server available in development does no compression and any number
  from it describes that script rather than production.
- **Check the install prompt on a real Android Chrome.** M7's one-tap install
  path is structurally correct but was never fired: the embedded browser used
  during development never emits `beforeinstallprompt`.

## A note on the database

The backend connects to whatever `MONGODB_URI` points at. If that is the same
Atlas cluster used in development, the deployed app shares its data — including
its users. Point production at its own database unless you intend otherwise.
