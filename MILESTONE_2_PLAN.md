# Milestone 2 Plan — Logging Core

Last updated: 2026-02-16

## 1) Milestone Objective
Deliver the first complete daily logging workflow so calories/macros can be tracked end-to-end from app input to persisted meal logs.

By end of Milestone 2:
- user can create/edit/delete meal log entries in diary sections,
- daily totals and target progress are computed and visible,
- data is persisted in backend database and reloaded correctly,
- core logging flows are covered by API and iOS tests.

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
- `POST /meal-logs`
- `GET /meal-logs?date=YYYY-MM-DD`
- `PATCH /meal-logs/{id}`
- `DELETE /meal-logs/{id}` (hard delete for now; archive optional)
- Stable response payload containing immutable nutrition snapshot per item

## 3.2 Data model
- `meal_logs` (user/date/meal_type/notes/timestamps)
- `meal_log_items` (meal_log_id + ingredient reference + quantity snapshot + nutrition snapshot)

## 3.3 iOS
- Diary screen grouped by meal type
- Add/edit/delete item interactions
- Totals and macro target progress UI

---

## 4) Testing & Quality Gates

## Backend
- Unit tests for daily total aggregation and numeric rounding rules
- Integration tests for add/edit/delete meal log APIs
- Auth/ownership checks for meal log access

## iOS
- Unit tests for diary view model state transitions
- UI tests for add/edit/delete meal log entry

Milestone exit criteria:
- backend tests + lint + typecheck green
- iOS tests green
- real-device smoke run of diary workflow

---

## 5) Implementation Sequence

## Phase A — Domain + schema
1. Add migration for meal log tables
2. Add backend domain models + store layer
3. Add API contracts + validation schemas

## Phase B — iOS diary
1. Add diary models and API client methods
2. Add diary UI sections and add/edit/delete controls
3. Wire daily totals + target progress

## Phase C — Hardening
1. Add tests (backend + iOS)
2. Run TestFlight smoke pass
3. Fix regressions and finalize milestone

---

## 6) Definition of Done
- [ ] Meal log CRUD works end-to-end
- [ ] Daily totals match backend-calculated values
- [ ] Macro target progress is visible and correct
- [ ] Tests cover critical logging and calculation paths
- [ ] Milestone TestFlight build validated on device
