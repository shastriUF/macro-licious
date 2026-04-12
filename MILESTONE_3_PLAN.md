# Milestone 3 Plan — Recipes + Wet Weight

Last updated: 2026-04-12

## 1) Milestone Objective
Implement recipe and cook-session workflows so users can log cooked dishes by consumed grams with accurate leftover tracking.

---

## 2) Scope

## In Scope
1. Recipe CRUD (name, ingredient list with quantities, notes)
2. Recipe ingredient composition with nutrition rollup from ingredient library
3. Cook session creation with final cooked (wet) weight
4. Macros-per-gram computation from total recipe nutrition ÷ final wet weight
5. Portion logging by consumed grams from a cook session
6. Leftover tracking and guardrails against over-consumption
7. Quick-log a meal from a saved recipe (creates cook session + logs portion in one flow)

## Out of Scope
- Barcode scan UX (Milestone 4)
- Smart meal planning/coaching
- Recipe versioning (changing ingredients after cook sessions exist)
- Sharing recipes between users

---

## 3) Deliverables

## 3.1 Database
- `recipes` table (id, user_id, name, notes, archived, timestamps)
- `recipe_ingredients` table (id, recipe_id, ingredient_id, ingredient_name, quantity_value, quantity_unit, timestamps)
- `cook_sessions` table (id, user_id, recipe_id, cooked_weight_grams, notes, timestamps)
- `cook_session_consumptions` table (id, cook_session_id, meal_log_item_id, consumed_grams, timestamps)
- Appropriate RLS enablement and FK constraints
- Check constraints on quantity_unit matching existing ingredient units

## 3.2 Backend/API
- `POST /recipes` — create recipe with ingredient list
- `GET /recipes` — list user's recipes (with ingredient details + nutrition rollup)
- `GET /recipes/{id}` — single recipe with full details
- `PATCH /recipes/{id}` — update recipe name/notes/ingredients
- `DELETE /recipes/{id}` — archive or hard-delete
- `POST /cook-sessions` — create session from recipe with cooked weight
- `GET /cook-sessions/{id}` — session details with remaining grams + consumption history
- `POST /cook-sessions/{id}/consumptions` — log consumed grams (creates meal log item)
- `GET /cook-sessions?active=true` — list sessions with remaining portions
- Nutrition rollup logic: sum recipe ingredients → compute per-gram values → multiply by consumed grams

## 3.3 iOS
- Recipe library tab or section (list, create, edit, archive)
- Recipe detail view showing ingredient list with total nutrition
- Cook session creation flow (select recipe → enter cooked weight → confirm)
- Active cook sessions list with remaining grams indicator
- Portion logging from cook session (enter consumed grams → auto-compute nutrition → add to meal log)
- Quick-cook flow: select recipe → enter weight → log portion in one pass

## 3.4 Shared logic
- Wet-weight math engine: `nutrition_per_gram = total_raw_nutrition / cooked_weight_grams`
- Reuse existing `UnitConversion` for ingredient quantity → grams conversion
- Keep backend and iOS implementations in sync

---

## 4) Testing & Quality Gates

## Backend
- Golden tests for wet-weight macro-per-gram math (multiple recipes, edge cases)
- Integration tests for recipe CRUD API
- Integration tests for cook session lifecycle (create → consume → check remaining)
- Edge-case tests: zero cooked weight, over-consumption attempts, empty recipe

## iOS
- Unit tests for wet-weight computation
- Unit tests for recipe nutrition rollup
- View-model tests for cook session state transitions

## Release
- All backend + iOS tests green
- Render deployment updated and health-checked
- Real-device smoke test: create recipe → cook → log portion → verify totals
- TestFlight build uploaded and validated

---

## 5) Implementation Sequence

## Phase A — Recipe domain + API
1. Add recipe + recipe_ingredients DB migration
2. Add backend domain models, store, and recipe CRUD routes
3. Add recipe integration tests
4. Add iOS recipe models, API client methods, and recipe list/create/edit UI

## Phase B — Cook sessions + wet-weight math
1. Add cook_sessions + cook_session_consumptions DB migration
2. Add wet-weight math engine (backend + iOS shared logic)
3. Add cook session API endpoints (create, consume, get with remaining)
4. Add cook session integration tests + golden math tests
5. Add iOS cook session UI (create, view active sessions, log portion)

## Phase C — Integration + release
1. Wire portion logging to meal log creation (cook session consumption → meal log item)
2. Add quick-cook flow (recipe → cook → log in one pass)
3. Run full test suite (backend + iOS)
4. Deploy to Render, push TestFlight build
5. Real-device smoke test with a real recipe scenario

---

## 6) Definition of Done
- [ ] Recipe CRUD complete (backend + iOS)
- [ ] Cook-session wet-weight flow complete (backend + iOS)
- [ ] Portion-by-gram logging from cook sessions accurate
- [ ] Leftover tracking with over-consumption guardrails
- [ ] Backend + iOS tests green
- [ ] Render deployment updated
- [ ] TestFlight build validated end-to-end on device
