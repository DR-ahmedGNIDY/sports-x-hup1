# Deploying Sport X Hub to your own server

Two names, one machine:

| Name | Serves | Container |
| --- | --- | --- |
| `sportxhup.com` | the Flutter web app | `web`, nginx on `127.0.0.1:8080` |
| `api.sportxhup.com` | the NestJS API | `api`, node on `127.0.0.1:3000` |

The host's own nginx terminates TLS for both and proxies inward. **Neither
container is reachable from the internet directly** — they bind to
`127.0.0.1`, which also stops Docker's iptables rules from quietly punching
through `ufw`.

This is the self-hosted path. `DEPLOYMENT_RAILWAY.md` describes the managed
one; the two share the same images and the same variables.

## 0. Before you start

- A server with a public IPv4 address, Docker Engine and the Compose plugin.
- Both DNS records pointing at it — **before** requesting certificates, or
  the ACME challenge has nowhere to land:

  | Type | Name | Value |
  | --- | --- | --- |
  | A | `sportxhup.com` | your server's IP |
  | A | `www` | your server's IP |
  | A | `api` | your server's IP |

- Ports 80 and 443 open. Nothing else needs to be.

## 1. Configure

```bash
git clone <your remote> sportxhup && cd sportxhup
cp .env.example .env
```

Fill in `.env`. Every value is documented in the file itself; these are the
ones that must not be skipped:

```bash
openssl rand -hex 24   # MONGO_ROOT_PASSWORD
openssl rand -hex 64   # JWT_SECRET
openssl rand -hex 64   # JWT_REFRESH_SECRET   (a different value)
```

Then set `MONGODB_URI` to match the Mongo username and password you just
chose, and fill in the Cloudinary and SMTP credentials.

`CORS_ORIGINS` already lists both `sportxhup.com` and `www.sportxhup.com`.
**Leave the `www` entry in** even if you plan to redirect it — a browser
sends the origin it was loaded from, and dropping it breaks the app for
anyone who typed the `www` form before the redirect settles.

## 2. Start the stack

```bash
docker compose up -d --build
```

The first build compiles the Flutter web app, which takes several minutes
and a couple of GB of RAM. On a 1 GB server it will be killed part-way — if
that happens, either add swap or build the `web` image somewhere else and
push it to a registry.

Check both are answering locally before involving nginx:

```bash
curl -s localhost:3000/health     # {"status":"ok","database":"connected"}
curl -sI localhost:8080 | head -1 # HTTP/1.1 200 OK
```

If `/health` reports the database as anything but `connected`, the problem
is `MONGODB_URI` — its credentials must match `MONGO_ROOT_USERNAME` /
`MONGO_ROOT_PASSWORD` exactly, and it must end with `?authSource=admin`.

## 3. nginx and TLS

Install the host config:

```bash
sudo cp deploy/nginx/sportxhup.conf /etc/nginx/sites-available/sportxhup.conf
sudo ln -s /etc/nginx/sites-available/sportxhup.conf /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/certbot
```

The file already contains the `listen 443 ssl` blocks and points at
certificate paths that do not exist yet, so **nginx will not start until
certbot has issued them**. Comment out the two 443 blocks, reload, get the
certificates, then uncomment:

```bash
sudo nginx -t && sudo systemctl reload nginx

sudo certbot certonly --webroot -w /var/www/certbot \
  -d sportxhup.com -d www.sportxhup.com
sudo certbot certonly --webroot -w /var/www/certbot \
  -d api.sportxhup.com

sudo nginx -t && sudo systemctl reload nginx
```

Two certificates rather than one covering all three names: the API and the
app are separate deployments that may one day move apart, and a single
certificate makes that a migration instead of a DNS change.

Renewal is a systemd timer certbot installs itself. Confirm it:

```bash
sudo certbot renew --dry-run
```

**HTTPS is not optional here.** Service workers and Web Push both require a
secure context, so over plain HTTP the app does not merely lose its padlock
— offline caching and phone notifications do not run at all.

## 4. First-run setup

Assign public codes to any profiles that predate them. Idempotent, and it
cannot renumber anyone who already has a code:

```bash
docker compose exec api npm run migrate:public-codes
```

Create the admin account:

```bash
docker compose exec api npm run seed:admin
```

## 5. Enabling phone notifications

Optional, and the app works without it — in-app notifications are the
durable record, push is what makes anyone look at them.

```bash
npx web-push generate-vapid-keys
```

Put the pair in `.env` as `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY`, set
`VAPID_SUBJECT` to a `mailto:` address you read, then
`docker compose up -d api`.

**Generate once and keep them.** Browsers bind each subscription to the
public key it was created with, so rotating the pair kills every existing
subscription and every user has to re-enable notifications.

Details, including why iPhone users must install the app to the Home Screen
first, are in `NOTIFICATIONS_PLAN.md`.

## 6. Deploying a change

```bash
git pull
docker compose up -d --build
```

Compose rebuilds only what changed. A backend-only change does not rebuild
the Flutter app, which is the slow half.

The web container's `API_BASE_URL` is written into the served `.env` asset
at container start, not at build time — so pointing the app at a different
API host is a restart, not a rebuild.

## 7. Backups

The database lives in the `mongo-data` named volume. It survives
`docker compose down`; it does **not** survive `docker compose down -v`.
That flag is the one to be careful with.

```bash
docker compose exec -T mongo mongodump \
  --username "$MONGO_ROOT_USERNAME" --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin --archive --gzip > backup-$(date +%F).gz
```

Nothing schedules this. Until something does, you have a database with no
backups — worth a cron entry on day one rather than after the first
incident.

## 8. Known limitations

1. **No CI.** Deploying is `git pull && docker compose up -d --build` on the
   server, and nothing runs the test suites first. Running
   `npm test` and `flutter test` before pushing is currently a habit, not a
   gate.
2. **Single machine.** Database, API and web share one host: no redundancy,
   and a reboot is downtime.
3. **Mongo runs unreplicated**, so MongoDB transactions remain unavailable —
   the same constraint the invitations feature was designed around, and the
   reason its correctness rests on atomic operations plus unique indexes
   rather than transactions.
4. **No log rotation configured.** Docker's default json-file driver grows
   without limit; set `max-size` in `/etc/docker/daemon.json` before the
   disk finds out.
5. **`www` is served, not redirected.** The nginx config answers both names
   with the same app rather than redirecting `www` to the apex. Either is
   defensible; if you prefer a canonical host, add the redirect and keep the
   `www` origin in `CORS_ORIGINS` regardless.
