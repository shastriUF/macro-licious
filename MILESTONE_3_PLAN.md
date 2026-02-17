# Milestone 3 Plan — Recipes + Wet Weight

Last updated: 2026-02-16

## 1) Milestone Objective
Implement recipe and cook-session workflows so users can log cooked dishes by consumed grams with accurate leftover tracking.

---

## 2) Scope

## In Scope
1. Recipe CRUD
2. Recipe ingredient composition
3. Cook session creation with final cooked (wet) weight
4. Macros-per-gram computation from total recipe nutrition and final wet weight
5. Portion logging by consumed grams
6. Leftover tracking and guardrails against over-consumption

## Out of Scope
- Barcode scan UX (Milestone 4)
- Smart meal planning/coaching

---

## 3) Deliverables

## Backend/API
- `POST /recipes`, `GET /recipes`, `PATCH /recipes/{id}`, `DELETE /recipes/{id}`
- `POST /cook-sessions`
- `POST /cook-sessions/{id}/consumptions`
- `GET /cook-sessions/{id}` with remaining grams + consumed history

## iOS
- Recipe library list/create/edit
- Cook-session UI for final weight entry
- Portion logging UI in grams with remaining balance display

---

## 4) Testing & Quality Gates
- Golden tests for wet-weight macro-per-gram math
- Integration tests for leftover state transitions
- iOS tests for recipe and cook-session flows
- Edge-case checks: zero/invalid cooked weight, over-consumption attempts

---

## 5) Implementation Sequence

## Phase A — Recipe domain
1. Add recipe tables + migrations
2. Implement recipe API + persistence
3. Add recipe UI and list/detail flows

## Phase B — Cook sessions
1. Add cook-session tables + math engine
2. Add consumption endpoints and remaining-grams checks
3. Add iOS cook-session + portion logging screens

## Phase C — Validation and release
1. Add wet-weight golden tests + integration coverage
2. Device smoke pass with real recipe scenario
3. Ship TestFlight milestone build

---

## 6) Definition of Done
- [ ] Recipe CRUD complete
- [ ] Cook-session wet-weight flow complete
- [ ] Portion-by-gram logging and leftovers accurate
- [ ] Golden/integration tests green
- [ ] TestFlight scenario validated end-to-end
