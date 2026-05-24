# syntax=docker/dockerfile:1

FROM node:22-alpine AS build

WORKDIR /repo

ENV CI=true
ENV NODE_ENV=production

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY apps ./apps
COPY packages ./packages
COPY docs ./docs
COPY assets ./assets
COPY tsconfig.json ./

RUN pnpm install --frozen-lockfile

RUN pnpm build:app

# Nuxt/Nitro writes .output in the app workspace.
# This keeps the Dockerfile resilient if the exact app folder name changes.
RUN set -eux; \
  OUTPUT_SERVER="$(find . -path '*/.output/server/index.mjs' -print -quit)"; \
  test -n "$OUTPUT_SERVER"; \
  OUTPUT_DIR="$(dirname "$(dirname "$OUTPUT_SERVER")")"; \
  cp -R "$OUTPUT_DIR" /tmp/shelve-output

FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

COPY --from=build /tmp/shelve-output ./.output

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
