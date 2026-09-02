# Stage 1 — compile TypeScript.
#
# Node 22 rather than 24: it is the current LTS, and `engines` already
# requires >= 20 because @nestjs/core@11 does. Pinned to a major so a
# rebuild months from now produces the same runtime, and to `-alpine`
# because nothing here needs glibc.
FROM node:22-alpine AS build
WORKDIR /app

# Dependencies are their own layer: package.json and the lockfile change far
# less often than src/, so a normal code change reuses the cached install.
COPY package.json package-lock.json ./
# `npm ci` here — and only here. It wipes node_modules before installing,
# which is exactly what you want in a clean build stage and exactly what
# broke on Railway, where a cache was mounted inside the directory it tries
# to delete (see the fix in backend/railway.json).
RUN npm ci

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

# Stage 2 — production dependencies only, resolved separately so the runtime
# image never carries TypeScript, ESLint, Jest or their trees.
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Stage 3 — the image that actually runs.
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# The node image ships a non-root `node` user. Running as root inside a
# container is a habit worth not having: a container escape starts from
# whatever the process already is.
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./

USER node

# Matches PORT's default in src/main.ts. The reverse proxy in front of this
# is what the public actually talks to; see docs/DEPLOYMENT_SELF_HOSTED.md.
ENV PORT=3000
EXPOSE 3000

# `dist/main` — the same entry point railway.json's startCommand uses, so
# the two deployment paths cannot drift.
CMD ["node", "dist/main"]
