# Milestone 2 Plan — Logging Core

Last updated: 2026-03-29

## 1) Milestone Objective
Deliver the first complete daily logging workflow so calories/macros can be tracked end-to-end from app input to persisted meal logs.

By end of Milestone 2:
- user can create/edit/delete meal log entries in diary sections,
- daily totals and target progress are computed and visible,
- data is persisted in backend database and reloaded correctly,
- core logging flows are covered by API and iOS tests.

Current status snapshot:
- ✅ Backend meal-log API, domain store, and integration tests implemented.
- ✅ `meal_logs` + `meal_log_items` migration created and pushed to staging Supabase.
- ✅ iOS diary flow implemented (ingredient-library + manual snapshot logging, add/edit/delete, daily totals).
- ✅ iOS tabbed IA implemented (Sign In / Meals / Ingredients).
- ✅ iOS diary UX/stability pass completed (segmented entry modes, computed validation feedback, safer loading behavior).
- 🟡 Remaining: macro target progress visualization + dedicated meal diary UI tests + planned Phase D UI refinement + device smoke pass.

---

## 2) Scope

## In Scope
1. Meal logging data model + API
2. iOS diary screens (breakfast/lunch/dinner/snacks)
3. Ingredient-based quick log flow
4. Daily macro/calorie totals and progress against targets
5. Edit/delete meal log item behavior
6. Test coverage for calculations and core logging flows

## Out of Scope
- Recipe/cook-session wet-weight logic (Milestone 3)
- Barcode scanning and external lookup (Milestone 4)
- JSON import/export (later milestone)

---

## 3) Deliverables

## 3.1 Backend/API
- [x] `POST /meal-logs`
- [x] `GET /meal-logs?date=YYYY-MM-DD`
- [x] `PATCH /meal-logs/{id}`
- [x] `DELETE /meal-logs/{id}` (hard delete for now; archive optional)
- [x] Stable response payload containing immutable nutrition snapshot per item

## 3.2 Data model
- [x] `meal_logs` (user/date/meal_type/notes/timestamps)
- [x] `meal_log_items` (meal_log_id + ingredient reference + quantity snapshot + nutrition snapshot)

## 3.3 iOS
- [x] Diary screen with meal-type selector and date-based log listing
- [x] Add/edit/delete item interactions
- [x] Tab-based top-level navigation for auth, meals, and ingredients
- [ ] Totals and macro target progress UI (totals complete, target progress pending)

## 3.4 iOS UX Iteration (Phase D)
- [ ] Add daily macro progress card (calories/carbs/protein/fat vs targets)
- [ ] Present diary as meal timeline sections with section subtotals
- [ ] Expand quick-add strip (recent/favorites/repeat shortcuts)
- [ ] Add richer empty states and undo affordance for delete/archive
- [ ] Add ingredient list search/sort controls for faster lookup

---

## 4) Testing & Quality Gates

## Backend
- [x] Unit tests for daily total aggregation and numeric rounding rules
- [x] Integration tests for add/edit/delete meal log APIs
- [x] Auth/ownership checks for meal log access

## iOS
- [x] Unit tests for diary view model state transitions (quick preset load/apply/persist paths)
- [ ] UI tests for add/edit/delete meal log entry

Milestone exit criteria:
- ✅ backend tests + lint + typecheck green
- ✅ iOS tests green
- ⏳ real-device smoke run of diary workflow

---

## 5) Implementation Sequence

## Phase A — Domain + schema
1. Add migration for meal log tables
2. Add backend domain models + store layer
3. Add API contracts + validation schemas

Status: ✅ Completed

## Phase B — iOS diary
1. Add diary models and API client methods
2. Add diary UI sections and add/edit/delete controls
3. Wire daily totals + target progress

Status: ✅ Completed for core logging; target-progress UI remains.

## Phase C — Hardening
1. Add tests (backend + iOS)
2. Run TestFlight smoke pass
3. Fix regressions and finalize milestone

Status: 🟡 In progress (backend + iOS tests green; more diary UI tests + TestFlight smoke pending)

## Phase D — UI Iteration
1. Ship macro progress card in Meals tab
2. Ship sectioned meal timeline + subtotals
3. Ship upgraded quick-add shortcuts and empty states
4. Add undo UX for destructive diary actions
5. Expand meal-flow UI test coverage

Status: ⏳ Planned (next active iteration)

---

## 6) Definition of Done
- [x] Meal log CRUD works end-to-end
- [x] Daily totals match backend-calculated values
- [ ] Macro target progress is visible and correct
- [ ] Tests cover critical logging and calculation paths
- [ ] Milestone TestFlight build validated on device
