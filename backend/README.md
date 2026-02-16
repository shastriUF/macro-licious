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

## Validation commands
- `npm run typecheck`
- `npm run lint`
- `npm test`

## Current endpoints
- `GET /`
- `GET /health`
- `POST /auth/magic-link/request`
- `POST /auth/magic-link/verify`
- `GET /me`
- `PATCH /me/macro-targets`
- `POST /ingredients`
- `GET /ingredients`
- `GET /ingredients/:ingredientId`
- `PATCH /ingredients/:ingredientId`
- `DELETE /ingredients/:ingredientId` (soft archive)
