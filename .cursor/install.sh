#!/usr/bin/env bash
# Idempotent Cloud Agent install for Sprout Track (SQLite dev setup).
# Safe to run repeatedly: it only adds missing env vars, applies pending
# migrations, and seeds only when no family exists yet.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[1/6] Ensuring .env defaults (SQLite)..."
node scripts/ensure-env-defaults.js local .env

echo "[2/6] Installing dependencies..."
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

echo "[3/6] Generating Prisma clients (main + log)..."
npm run prisma:generate
npx prisma generate --config prisma/log.config.ts

echo "[4/6] Applying main database migrations..."
npx prisma migrate deploy

echo "[5/6] Syncing log database schema..."
# The log DB is a fresh, empty local SQLite file created during install, so
# --accept-data-loss cannot destroy real data. The consent variable satisfies
# Prisma 7's AI safety guard for this development-only, empty database.
PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION="Cloud Agent dev environment install: sync log schema into the fresh empty local api-logs.db development database." \
  npx prisma db push --config prisma/log.config.ts --accept-data-loss

echo "[6/6] Seeding default family, system caretaker (PIN 111222), and units..."
npm run prisma:seed

echo "Sprout Track dev environment install complete."
