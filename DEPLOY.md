# طريقة النشر — Deployment

**This is the procedure to follow whenever the user says "انشر التعديلات" /
"publish the changes".** It is written from what actually works on this
server, including the things that went wrong the first time.

The live deployment is **not** the Docker Compose path in
`docs/DEPLOYMENT_SELF_HOSTED.md`. That guide describes a machine of its own;
this one describes the machine the app is actually on.

## The server

A **shared production host** — `sportxhup.com` is one of twelve sites on it.
The others belong to other businesses. nginx is shared, so a broken config
takes all of them down, not just this app.

| | |
| --- | --- |
| Host | `claude@76.13.63.162` (key: `~/.ssh/claude-agent`) |
| API | pm2 process `sportxhup-api`, port **3007** (3000–3006 are taken) |
| Web root | `/var/www/sportxhup`, owned by `www-data` |
| Staging dir | `~/sportxhup-web` — writable without sudo |
| Backend source | `~/sportxhup` |
| Database | MongoDB Atlas (not on this server) |
| TLS | certbot, auto-renewing |

**`sudo` needs a password nobody has here.** Anything touching
`/var/www`, `/etc/nginx` or systemd is a command *for the user to run*.
Everything else can be done over SSH directly.

## Frontend

The Flutter build happens **locally**, not on the server — the server has no
Flutter, and putting one there would be a large install for a machine that
does not otherwise need it.

```bash
cd frontend
cp .env .env.devbackup
printf 'API_BASE_URL=https://api.sportxhup.com\nAPP_ENV=production\n' > .env
flutter build web --release --no-web-resources-cdn
cp .env.devbackup .env && rm -f .env.devbackup
```

**Restore `.env` in the same breath as writing it.** It is a declared pubspec
asset, so it must exist for any build *or test*; it is git-ignored, so a
clobbered copy cannot be recovered from the repo; and leaving production
values in it makes `test/core/env_test.dart` fail. All three were learned the
hard way.

Then ship it to the staging directory:

```bash
cd build && tar czf /tmp/sxh-web.tgz -C web .
scp -i ~/.ssh/claude-agent /tmp/sxh-web.tgz claude@76.13.63.162:/tmp/sxh-web.tgz
ssh -i ~/.ssh/claude-agent claude@76.13.63.162 'set -e
rm -rf ~/sportxhup-web/*
tar xzf /tmp/sxh-web.tgz -C ~/sportxhup-web
rm -f /tmp/sxh-web.tgz
find ~/sportxhup-web -type d -exec chmod 755 {} +
find ~/sportxhup-web -type f -exec chmod 644 {} +'
```

**Set the modes here, in the staging directory.** A `sudo cp` of this tree
once produced mode `055` — no read bit for the owner — and since nginx runs
*as* the owner it answered `403` to every visitor. Fixing the modes before
the copy leaves nothing for the copy to get wrong.

### Then hand the user this one command

```bash
sudo rsync -a --delete ~/sportxhup-web/ /var/www/sportxhup/ && sudo chown -R www-data:www-data /var/www/sportxhup && sudo find /var/www/sportxhup -type d -exec chmod 755 {} + && sudo find /var/www/sportxhup -type f -exec chmod 644 {} +
```

`--delete` so files dropped from a build do not linger. The `chmod` after the
`chown` is belt and braces against the `055` case above.

## Backend

Nothing is built locally; the server compiles it.

```bash
ssh -i ~/.ssh/claude-agent claude@76.13.63.162 'set -e
cd ~/sportxhup && git pull --ff-only
cd backend && npm ci && npm run build
pm2 restart sportxhup-api --update-env
pm2 save'
```

`--update-env` because a `.env` change is otherwise not picked up, and
`pm2 save` because the resurrect list is what brings the process back after a
reboot — skip it and the next restart runs the previous config.

**`git pull` on the server sometimes fails with `could not read Username for
'https://github.com'` even though the repo is public.** It is transient;
retry. It has never needed credentials.

## Verifying — hash, not hope

The one check that settles it. `curl` bypasses the service worker, so this
compares what nginx actually serves against what was just built:

```bash
cd frontend/build/web
LOCAL=$(sha256sum main.dart.js | cut -d' ' -f1)
SERVED=$(curl -s https://sportxhup.com/main.dart.js | sha256sum | cut -d' ' -f1)
[ "$LOCAL" = "$SERVED" ] && echo MATCH || echo MISMATCH
```

For the backend, hit a route that only exists in the new code, or:

```bash
curl -s https://api.sportxhup.com/health
```

**Do not verify the frontend by looking at it in a browser first.** A browser
holding a previous service worker will show the old build while `curl` shows
the new one, and mistaking that for a failed deploy has cost real time here.
Check the hash, *then* look.

## What a viewer sees, and when

The service worker is network-first for `flutter_bootstrap.js`, so a deploy
now reaches a returning visitor. A device that still holds a worker from
**before** that fix needs **two loads** — the first is served by the old
worker, which fetches the new one in the background. After that, one load.

To see a change immediately: clear site data for `sportxhup.com`. A private
window is *not* enough — the worker is registered against the origin.

## Things that are easy to get wrong

1. **Never reload nginx without `sudo nginx -t` passing first.** Eleven other
   sites share it.
2. **Do not commit `frontend/.env`.** It is git-ignored; keep it that way.
3. **VAPID keys are generated once.** Rotating them invalidates every push
   subscription and every user has to re-enable notifications.
4. **Deleting `frontend/build` between builds is unnecessary** — Flutter
   overwrites — but `rsync --delete` on the server *is* necessary.
5. **`docker-compose.yml` and `docs/DEPLOYMENT_SELF_HOSTED.md` do not
   describe this deployment.** They are the standalone-machine path, kept for
   the day the app gets a host of its own.

## After a first deploy on a fresh database

```bash
cd ~/sportxhup/backend
npm run migrate:public-codes   # assigns CLB-/PLY- codes; idempotent
npm run seed:admin             # creates the admin account
```
