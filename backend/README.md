# Backend (Milestone 1 Foundation)

Node.js + TypeScript + Fastify service for MacroLicious.

## Quick start
1. Install dependencies:
   - `npm install`
2. Configure env:
   - `cp .env.example .env`
3. Run in dev mode:
   - `npm run dev`

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

Milestone 1 next step is ingredient CRUD endpoints.
