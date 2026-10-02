# Website split — server setup and cutover (phases 7–8)

After the split there are two web roots on the server:

| Name | What | Web root | Staging dir (no sudo) |
| --- | --- | --- | --- |
| `sportxhup.com` | Website + store (`website/`, Astro) | `/var/www/sportxhup-site` | `~/sportxhup-site` |
| `app.sportxhup.com` | The app's web build (`frontend/`) | `/var/www/sportxhup-app` | `~/sportxhup-app-web` |
| `api.sportxhup.com` | API (unchanged) | — | — |

`/var/www/sportxhup` (the old app root) is left untouched until the cutover
has settled, as the rollback.

nginx files: `deploy/nginx/live/`. Commands marked **(user)** need `sudo`,
which only the user can run. Run `sudo nginx -t` before every reload — eleven
other sites share this nginx.

## Phase 7 — make app.sportxhup.com exist (nothing visible changes yet)

1. **(user, DNS panel)** Add an `A` record: `app` → `76.13.63.162`.
   Check: `nslookup app.sportxhup.com` returns that address.

2. **Backend.** Deploy the branch (site settings API, hash-route reset link)
   as in `DEPLOY.md`, then edit `~/sportxhup/backend/.env` on the server:

   ```
   CORS_ORIGINS=https://sportxhup.com,https://www.sportxhup.com,https://app.sportxhup.com
   FRONTEND_URL=https://app.sportxhup.com
   ```

   and `pm2 restart sportxhup-api --update-env && pm2 save`.
   `FRONTEND_URL` is where password-reset emails point.

3. **App web build** — exactly the `DEPLOY.md` frontend build (production
   `.env`, then restore it), staged into `~/sportxhup-app-web` instead of
   `~/sportxhup-web`.

4. **(user)** Web root, vhost, certificate:

   ```bash
   sudo mkdir -p /var/www/sportxhup-app
   sudo rsync -a --delete ~/sportxhup-app-web/ /var/www/sportxhup-app/ && sudo chown -R www-data:www-data /var/www/sportxhup-app
   sudo cp ~/sportxhup/deploy/nginx/live/app.sportxhup.com /etc/nginx/sites-available/app.sportxhup.com
   sudo ln -s /etc/nginx/sites-available/app.sportxhup.com /etc/nginx/sites-enabled/app.sportxhup.com
   sudo nginx -t && sudo systemctl reload nginx
   sudo certbot --nginx -d app.sportxhup.com
   ```

   Check: `https://app.sportxhup.com` opens on the sign-in screen.

## Phase 8 — switch sportxhup.com to the website

1. Build the website (`cd website && npm ci && npm run build`) and stage
   `website/dist/` into `~/sportxhup-site` (same tar/scp/chmod steps as the
   app in `DEPLOY.md`).

2. **(user)**

   ```bash
   sudo mkdir -p /var/www/sportxhup-site
   sudo rsync -a --delete ~/sportxhup-site/ /var/www/sportxhup-site/ && sudo chown -R www-data:www-data /var/www/sportxhup-site
   sudo cp /etc/nginx/sites-available/sportxhup.com ~/sportxhup.com.nginx.bak
   sudo cp ~/sportxhup/deploy/nginx/live/sportxhup.com /etc/nginx/sites-available/sportxhup.com
   sudo nginx -t && sudo systemctl reload nginx
   ```

3. Check:
   - `curl -sI https://sportxhup.com/` → 200, the website.
   - `curl -sI https://sportxhup.com/login` → 301 to `https://app.sportxhup.com/#/login`.
   - `curl -sI https://sportxhup.com/privacy.html` → 200 (Google Play links here).
   - `https://sportxhup.com/store` lists the departments.
   - Place one test order on the website store with a test product, and
     see it under Admin → Store → Orders.

**Rollback:** `sudo cp ~/sportxhup.com.nginx.bak /etc/nginx/sites-available/sportxhup.com && sudo nginx -t && sudo systemctl reload nginx`
— the old app root `/var/www/sportxhup` is still there.

## What visitors notice

- Returning visitors still have the old app's service worker for
  sportxhup.com. The website serves a replacement at the same path that
  clears it and reloads once, so they land on the website.
- Old links like `sportxhup.com/players/abc` and `sportxhup.com/#/players/abc`
  are sent to the same screen on `app.sportxhup.com`.
- Web push subscriptions belong to an origin: users who allowed
  notifications on `sportxhup.com` need to allow them again on
  `app.sportxhup.com`.
- Anyone signed in on the web build is signed in per origin too, so they
  sign in once more on `app.sportxhup.com`.
