# Backend (Milestone 1 Foundation)

Node.js + TypeScript + Fastify service for MacroLicious.

## Quick start
1. Install dependencies:
   - `npm install`
2. Configure env:
   - `cp .env.example .env`
   - default local mode uses `AUTH_PROVIDER=dev`
3. Run in dev mode:
   - `npm run dev`

## Auth modes (staged)
- `AUTH_PROVIDER=dev`
  - local in-memory magic link tokens (fast local iteration)
- `AUTH_PROVIDER=supabase`
  - provider-backed magic links via Supabase Auth

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for full Supabase Auth + DB setup.

## Database migrations
- Migration files are versioned under `supabase/migrations` at the repo root.
- Apply using Supabase CLI: `supabase db push`.

## Validation commands
- `npm run typecheck`
- `npm run lint`
- `npm test`

## API versioning convention
- Current foundation API remains unprefixed for Milestone 1 (`/health`, `/auth/*`, `/ingredients/*`).
- First breaking API revision will introduce explicit `/v1` route prefixes while keeping old routes temporarily for migration.
- Additive (non-breaking) fields are allowed in existing response payloads.
- Breaking changes require:
   1. new `/vN` endpoint surface,
   2. migration notes in root `README.md`,
   3. test coverage for both old/new behavior during transition window.

## Current endpoints
- `GET /`
- `GET /health`
- `POST /auth/magic-link/request`
- `POST /auth/magic-link/verify`
- `POST /auth/sign-out`
- `GET /me`
- `PATCH /me/macro-targets`
- `POST /ingredients`
- `GET /ingredients`
- `GET /ingredients/:ingredientId`
- `PATCH /ingredients/:ingredientId`
- `DELETE /ingredients/:ingredientId` (soft archive)
- `POST /meal-logs`
- `GET /meal-logs?date=YYYY-MM-DD`
- `PATCH /meal-logs/:mealLogId`
- `DELETE /meal-logs/:mealLogId`
