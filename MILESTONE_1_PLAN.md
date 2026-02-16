# Milestone 1 Plan — Foundation

Last updated: 2026-02-15

## 1) Milestone Objective
Set up the production-ready foundation for the app so Milestone 2 can focus on logging features without rework.

By end of Milestone 1, we should have:
- iOS app scaffold (SwiftUI) with basic navigation shell
- backend scaffold with auth + profile primitives
- ingredient CRUD API + minimal iOS client integration
- baseline tests running in CI
- first internal TestFlight build proving end-to-end deployment path

---

## 2) Scope

## In Scope
1. Project scaffolding
   - iOS app project structure
   - backend project structure
   - shared environment/config conventions
2. Authentication + user profile
   - email magic-link flow
   - user profile with macro targets (mandatory: calories, carbs, protein)
3. Core ingredient CRUD
   - create, read/list, update, archive/delete behavior
4. Testing baseline
   - backend unit/integration tests for ingredient APIs
   - iOS unit tests for conversion/model layer baseline
   - minimal UI smoke test (app launch + auth screen render)
5. Delivery baseline
   - CI running tests on PRs/main
   - internal TestFlight release for deployment validation

## Out of Scope
- Meal diary logging UX
- Recipe and wet-weight workflows
- Barcode scanner and external barcode provider integration
- JSON export/import implementation
- Spouse sharing features

---

## 3) Architecture Decisions for Milestone 1

## Confirmed
- Client: SwiftUI iOS app
- Auth for MVP: email magic link (Sign in with Apple deferred)
- Data model priority entities this milestone: User, MacroTarget, Ingredient
- App name: MacroLicious
- Backend: Node.js + TypeScript + Fastify
- Database/Auth: Supabase Postgres (Free tier) + Supabase Auth magic links

## Why this backend choice
- Strong compile-time type safety in TypeScript (preferred for long-term maintainability and LLM-assisted coding).
- Fastify keeps runtime lightweight while still supporting strong schema validation.
- Supabase Free keeps initial costs near zero while enabling auth + managed Postgres.

---

## 4) Deliverables

## 4.1 Repo/Structure Deliverables
- iOS app folder with environment-aware config strategy
- backend folder with API app entrypoint and dependency setup
- root-level developer docs for running locally
- TypeScript strict mode enabled for backend (`strict: true`) with linting/typecheck in CI

## 4.2 API Deliverables (v1 foundation)
- `POST /auth/magic-link/request`
- `POST /auth/magic-link/verify`
- `GET /me`
- `PATCH /me/macro-targets`
- `POST /ingredients`
- `GET /ingredients`
- `GET /ingredients/{id}`
- `PATCH /ingredients/{id}`
- `DELETE /ingredients/{id}` (soft delete/archive preferred)

## 4.3 Data/Domain Deliverables
- User profile model
- Macro target model (calories, carbs, protein)
- Ingredient model with base nutrition fields
- Audit timestamps (`created_at`, `updated_at`)

## 4.4 CI & Release Deliverables
- PR validation pipeline executes tests and fails on test regressions
- Build/sign pipeline capable of creating internal TestFlight build
- One internal TestFlight release completed and installable

---

## 5) Test Strategy (Milestone 1)

## Backend tests
- Unit tests
  - request validation and schema guards
  - macro target field constraints
- Integration tests
  - ingredient CRUD happy paths
  - auth token/session checks for protected endpoints
  - soft-delete behavior
- Static checks
   - `tsc --noEmit` typecheck
   - lint checks on backend source

## iOS tests
- Unit tests
  - model parsing/encoding
  - conversion helper baseline (g/oz/lb, ml/tsp/tbsp/cup)
- UI smoke test
  - app launch
  - render auth entry view

## CI gates
- No PR merge without passing tests
- Main branch remains releasable after each merge

---

## 6) Implementation Sequence

## Phase A — Foundation setup
1. Initialize iOS and backend project skeletons
2. Configure env files/secrets strategy
3. Set up CI workflow
4. Enable strict TypeScript and baseline lint/typecheck rules

## Phase B — Auth and profile
1. Implement magic-link request/verify backend
2. Implement iOS auth screens and session persistence
3. Add profile + macro target read/update

## Phase C — Ingredient CRUD
1. Add ingredient data schema + persistence
2. Implement CRUD endpoints
3. Connect minimal iOS ingredient list/create/edit screens

## Phase D — Hardening + release
1. Fill baseline unit/integration/UI smoke tests
2. Run full CI on main
3. Ship first internal TestFlight build and verify backend connectivity from device

---

## 7) Definition of Done (Milestone 1)
- [ ] iOS app and backend scaffolded with clear local run instructions
- [ ] Email magic-link auth works end-to-end in dev/staging
- [ ] User macro targets (calories, carbs, protein) can be edited and persisted
- [ ] Ingredient CRUD works end-to-end from app to backend
- [ ] Baseline tests exist and pass in CI
- [ ] Internal TestFlight build is distributed and installs successfully
- [ ] Core regression checklist executed after TestFlight build

---

## 8) Risks & Mitigations (Milestone 1)
- Auth provider friction -> start with simplest magic-link provider + mocked local mode for dev
- iOS signing/TestFlight delays -> configure Apple signing in Phase A, not at end
- API churn -> lock endpoint contracts before UI wiring
- TypeScript setup overhead -> keep framework surface minimal (Fastify + focused libs) and avoid over-abstraction in Milestone 1
- Time overrun -> defer any non-foundation UX polish to Milestone 2

---

## 9) Coding Mode Readiness Checklist

Switch to coding mode when all items below are true:
- [x] Backend runtime choice confirmed (Node.js + TypeScript + Fastify)
- [x] Apple Developer account access + bundle ID availability confirmed
- [ ] Initial deployment target selected for backend (can be temporary staging)
- [ ] This Milestone 1 plan accepted as implementation baseline

When these are checked, coding can start immediately.
