# sportxhup.com — the public website (Astro, static) and its storefront.
# Live file: /etc/nginx/sites-available/sportxhup.com (symlinked into
# sites-enabled). The "managed by Certbot" lines are the ones certbot wrote
# for this name; they are kept as they are on the server.
#
# The Flutter app moved to app.sportxhup.com. Every path the app used to own
# here is redirected there, so old links, bookmarks and the password-reset
# emails already sent keep working. The app uses hash routing, so the path is
# carried after "/#".
server {
    server_name sportxhup.com www.sportxhup.com;

    root /var/www/sportxhup-site;
    index index.html;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/javascript
               application/json image/svg+xml;

    # Astro writes every page as <path>/index.html; anything else is a 404,
    # not the app's SPA fallback.
    location / {
        try_files $uri $uri/ =404;
        add_header Cache-Control "no-cache";
    }

    # Astro's bundled CSS/JS are content-hashed, so they can be cached hard.
    location /_astro/ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Category and product pages are pre-built for the slugs that existed at
    # build time; a newer one is served by the generic shell, which reads
    # the slug from the URL.
    location ~ ^/(en/)?store/c/ { try_files $uri $uri/ /$1store/c/index.html; }
    location ~ ^/(en/)?store/p/ { try_files $uri $uri/ /$1store/p/index.html; }

    # Replaces the Flutter service worker returning visitors still have
    # registered for this origin — see website/public/sxh_service_worker.js.
    location = /sxh_service_worker.js     { add_header Cache-Control "no-store"; }
    location = /flutter_service_worker.js { add_header Cache-Control "no-store"; }

    # Marketing pages the app used to serve here.
    location = /home    { return 301 /; }
    location = /about   { return 301 /; }
    location = /pricing { return 301 /; }

    # Everything the app owned: sign-in, profiles, the signed-in screens.
    location ~ ^/(login|register|forgot-password|reset-password|dashboard|player|players|club|clubs|coach|coaches|search|saved-players|settings|notifications|community|calendar|invitations|admin)(/|$) {
        return 301 "https://app.sportxhup.com/#$request_uri";
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/sportxhup.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/sportxhup.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.sportxhup.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    if ($host = sportxhup.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name sportxhup.com www.sportxhup.com;

    listen 80;
    return 404; # managed by Certbot
}
