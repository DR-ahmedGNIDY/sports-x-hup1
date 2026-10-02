# app.sportxhup.com — the Flutter web app (the same code as the Google Play
# build). Live file: /etc/nginx/sites-available/app.sportxhup.com.
#
# Install with port 80 only (as below), reload, then run
#   sudo certbot --nginx -d app.sportxhup.com
# which adds the `listen 443 ssl` lines and the HTTP->HTTPS redirect itself.
#
# Everything inside `location` is copied from what served the app on
# sportxhup.com before the split.
server {
    server_name app.sportxhup.com;

    root /var/www/sportxhup-app;
    index index.html;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/javascript
               application/json application/manifest+json application/wasm
               image/svg+xml;

    # The public website on sportxhup.com is what search engines should
    # index; the app is a signed-in tool.
    add_header X-Robots-Tag "noindex" always;

    # flutter build web does not content-hash its output, so a long max-age
    # would pin returning visitors to a stale bundle with no way to bust it.
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache";
        add_header X-Robots-Tag "noindex" always;
    }

    # Rewritten on every deploy.
    location = /assets/.env {
        add_header Cache-Control "no-store";
    }

    # The service worker decides when everything else updates, so it must
    # never come from cache.
    location = /sxh_service_worker.js {
        add_header Cache-Control "no-store";
    }

    listen 80;
}
