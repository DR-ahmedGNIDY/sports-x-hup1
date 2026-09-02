# Stage 1 — build the Flutter web app. `stable` tracks whatever Flutter
# release cirruslabs currently publishes as stable — pinning an exact patch
# version (e.g. 3.44.1) risks the image simply not existing on ghcr.io yet.
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# flutter_dotenv needs an `.env` asset to exist at build time (see
# lib/core/config/env.dart) — its actual content doesn't matter here.
# The real values are written into the *served* copy of this file at
# container startup (docker-entrypoint.sh), so the API base URL can change
# without rebuilding the Flutter app.
RUN cp .env.example .env
# --no-web-resources-cdn: without it Flutter fetches CanvasKit — the rendering
# engine, several MB — from gstatic.com at runtime, even though the build
# already emits a local copy. That makes first paint depend on a third-party
# CDN being reachable, and makes offline impossible however good the service
# worker is, since the engine itself is never same-origin to cache.
RUN flutter build web --release --no-web-resources-cdn

# Stage 2 — serve the static build with nginx.
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Overridable at deploy time — see docs/DEPLOYMENT_SELF_HOSTED.md.
ENV API_BASE_URL=http://localhost:3000
ENV APP_ENV=production

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
