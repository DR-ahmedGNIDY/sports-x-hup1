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
  On a fresh Ubuntu/Debian box:

  ```bash
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"   # then log out and back in
  docker compose version            # confirms the plugin came with it
  ```

- **At least 2 GB of RAM to build the web image**, or a plan for §2.1. The
  Flutter compile is the demanding step; everything else is small.
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
and a couple of GB of RAM.

### 2.1 If the web build is killed

On a 1 GB server the Flutter compile is killed part-way — usually with no
message beyond the build stopping, because the kernel's OOM killer does not
explain itself. Two ways out.

**Add swap** (simplest; slow but it finishes):

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Or build the web image elsewhere** — on your own machine, or in CI — and
ship it:

```bash
# where you have RAM to spare
docker build -t sportxhup-web ./frontend
docker save sportxhup-web | gzip | ssh you@server 'gunzip | docker load'
```

Then on the server, start it without rebuilding:

```bash
docker compose up -d --no-build web
docker compose up -d --build api mongo
```

The API image is a plain Node build and compiles happily on any size box;
only the web one needs this.

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

## 8. Moving off Railway

The order matters, because the Railway deployment is production until the
day it isn't.

1. **Bring the VPS up fully** — steps 1 to 4 above — while Railway keeps
   serving. Test it by pointing a `hosts` entry at the new IP, or by hitting
   the server's address directly, *before* touching DNS.
2. **Switch DNS.** Lower the TTL a day beforehand if you can; expect a tail
   of traffic on the old host regardless.
3. **Watch both** for a day. Railway's copy is a working rollback for as
   long as its database is still current.
4. **Only then** delete `backend/railway.json`, `frontend/railway.json` and
   `DEPLOYMENT_RAILWAY.md`. Removing them earlier changes how Railway builds
   the still-live site: without `railway.json` it falls back to
   auto-detection, which now finds `backend/Dockerfile` and takes a
   different path than the one currently running.

**The database does not move itself.** Railway's Mongo and the `mongo-data`
volume here are separate stores. Dump from the old one and restore into the
new one during the switch, or start on the VPS with an empty database and
accept the loss — but decide which, deliberately, rather than discovering it
afterwards.

```bash
mongodump --uri "<railway MONGODB_URI>" --archive --gzip > move.gz
docker compose exec -T mongo mongorestore \
  --username "$MONGO_ROOT_USERNAME" --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin --archive --gzip < move.gz
```

**Email may simply start working.** `SmtpEmailProvider` times out on Railway
because it blocks outbound mail ports (25/465/587/2525). A normal VPS leaves
587 open — many block 25 only — so try `MAIL_PROVIDER=smtp` first and keep
`brevo` as the fallback rather than assuming you still need it.

## 9. Known limitations

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
