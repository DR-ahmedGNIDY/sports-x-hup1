#!/bin/sh
set -e

export PORT="${PORT:-80}"

# Scoped substitution — only ${PORT} is replaced, so nginx's own $uri/$host
# variables in the template are left untouched.
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# Rewrite the served .env asset from the container's real env vars. Flutter
# declared `.env` as a pubspec asset, so it ends up at this path in the web
# build output — flutter_dotenv fetches it over HTTP when the app boots.
cat > /usr/share/nginx/html/assets/.env <<EOF
API_BASE_URL=${API_BASE_URL:-http://localhost:3000}
APP_ENV=${APP_ENV:-production}
EOF

exec "$@"
