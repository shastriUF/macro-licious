# Calorie & Macro Tracker — Product + Implementation Plan

_Last updated: 2026-02-16_

## 1) Product Goal
Build a lightweight, low-friction calorie and macro tracker focused on home cooking and ingredient-level precision, without ad-heavy UX.

Core outcomes:
- Track calories + macros accurately per meal/day.
- Enter ingredients by **weight or volume** quickly.
- Add custom ingredients easily (especially raw produce and changing store items).
- Support **barcode scanning** where available.
- Compute per-portion nutrition from **post-cook wet weight** for shared dishes and leftovers.
- Save and reuse recipes for meal planning.

---

## 2) User Constraints & Preferences
- Primary device: iPhone.
- Open to app type: native iOS, React Native/Expo, or web app.
- Dislikes ad-heavy commercial apps.
- Budget tolerance for hosting: target <= $5/month.
- Prefers practical usability over framework purity.

---

## 3) Scope (MVP vs Later)

## MVP (required)
1. Daily logging of meals and foods.
2. Macro tracking (calories, protein, carbs, fat; optional fiber/sugar).
3. Ingredient entries in grams/oz/ml/tsp/tbsp/cup with conversion handling.
4. Custom ingredient creation/editing.
5. Barcode lookup + fallback manual entry.
6. Recipe builder from ingredients.
7. Wet-weight final dish workflow:
   - Enter raw ingredients + quantities.
   - Enter final cooked weight.
   - Log consumed grams of final dish.
   - Auto-calculate calories/macros consumed.
8. Saved recipe library and quick logging from saved recipes.

## Post-MVP (nice to have)
- Multi-user household sharing.
- Meal planner/calendar.
- Grocery list generation from recipes.
- Nutrition targets with adaptive coaching.
- Apple Health write/read integration.
- Import/export (CSV/JSON).

---

## 4) Architecture Decision (recommended path)

## Options considered

### Option A — Native iOS (SwiftUI) + small backend
Pros:
- Best iPhone UX/performance.
- Strong access to camera/barcode APIs.
- Fewer cross-platform compromises.

Cons:
- Steeper learning curve.
- Separate web/admin UIs if needed later.

### Option B — React Native (not Expo-managed) + backend
Pros:
- Cross-platform potential.
- Better native access than Expo-managed workflow.

Cons:
- More moving pieces than pure native.
- Native module maintenance overhead.

### Option C — PWA (web app) + backend
Pros:
- Fastest initial build.
- Lowest complexity to deploy.

Cons:
- Barcode/camera and offline behavior can feel less native.
- Weaker long-term mobile UX vs native app.

## Recommendation
Start with **Option A (SwiftUI iOS + lightweight backend)** for best fit with your preferences and feature needs (barcode + smooth phone-native workflow).

Backend should remain thin and portable so you can still add web clients later.

---

## 5) Suggested Tech Stack (for coding phase)

## Mobile (iOS)
- SwiftUI
- SwiftData or Core Data for local cache/offline queue
- AVFoundation/VisionKit for barcode scanning

## Backend/API
- Node.js + TypeScript (Fastify)
- PostgreSQL (managed, Supabase Free tier initially)
- Auth: Supabase email magic links for MVP (Sign in with Apple later)
- Image/barcode support via API + third-party food DB lookup

## Hosting (budget aware)
- Backend: Fly.io / Railway / Render starter tier
- DB: Supabase Postgres or Neon free/low tier
- Object storage (optional): Cloudflare R2 / S3-compatible low-cost tier

Estimated early monthly cost: **$0–$5** if usage is low and free tiers are sufficient.

---

## 6) Functional Workflows

## A) Ingredient logging workflow
1. Search existing ingredient.
2. If found: choose unit + quantity.
3. If not found: create ingredient manually or scan barcode.
4. System converts quantity to canonical grams (or ml when density-based).
5. Nutrition totals update in real-time.

## B) Custom ingredient creation
Required fields:
- Name
- Brand/source (optional)
- Barcode (optional)
- Nutrition per 100g (or per package with weight)
- Density (optional, for volume-to-weight conversion)

Behavior:
- If barcode exists and matches existing item, prompt merge/replace.
- Keep version history for ingredients that change by brand/lot.

## C) Recipe + wet-weight workflow
1. Add ingredient list and raw quantities.
2. Compute total recipe macros from raw inputs.
3. Enter final cooked (wet) weight.
4. System derives nutrition per 1g cooked dish:
   - calories_per_g = total_calories / cooked_weight_g
   - protein_per_g, carbs_per_g, fat_per_g similarly
5. Log portion by consumed grams.
6. Support leftover tracking by subtracting consumed grams from remaining cooked grams.

## D) Daily diary workflow
- Breakfast/lunch/dinner/snacks sections.
- Add ingredient/recipe quickly.
- Show per-meal + daily totals against user macro targets.

---

## 7) Data Model (high-level)

Entities:
- User
- Ingredient
- IngredientVersion (for changed nutrition profiles)
- Barcode
- Recipe
- RecipeIngredient
- CookSession (recipe instance with final wet weight)
- MealLog
- MealLogItem
- MacroTarget

Key concepts:
- Canonical quantity storage in grams for solids, milliliters for liquids when needed.
- Store conversion factors per ingredient for volume units when density is known.
- Immutable nutrition snapshot in MealLogItem so historical logs remain accurate.

---

## 8) Unit Conversion Strategy
- Internal canonical units:
  - mass: g
  - volume: ml
- UI accepts: g, oz, lb, ml, tsp, tbsp, cup.
- Convert volume->mass only when density is available.
- If density is missing:
  - either store as volume-only and warn reduced precision,
  - or prompt user to provide weight.

Conversion references (fixed):
- 1 oz = 28.3495 g
- 1 lb = 453.592 g
- 1 tsp = 4.92892 ml
- 1 tbsp = 14.7868 ml
- 1 cup = 236.588 ml

---

## 9) Barcode Data Strategy
Primary sources to evaluate during coding phase:
- Open Food Facts (free/open, variable completeness)
- Commercial APIs (paid, usually better coverage)

Plan:
1. Try barcode lookup in external DB.
2. If no result, allow manual ingredient creation and store barcode mapping locally.
3. Cache lookups to reduce latency and external dependency.

---

## 10) Non-Functional Requirements
- Fast logging flow (<5 taps for common actions).
- Offline-first for meal entry; sync when online.
- Data privacy: user-owned data, no ads, no data resale.
- Observability: minimal error logging and crash reporting.
- Reliability: deterministic nutrition calculations with rounding rules.

---

## 11) Milestone Plan

## Milestone 0 — Product Definition (current)
- Finalize scope and architecture.
- Confirm exact MVP fields and units.
- Define test strategy (unit, integration, UI smoke) and CI pass criteria.

## Milestone 1 — Foundation
- Project scaffolding (iOS app + backend).
- Auth + user profile + macro target settings.
- Core ingredient CRUD.
- Testing: add unit tests for models/conversions baseline + API contract tests for ingredient CRUD.
- Release strategy: ship first internal TestFlight build by end of milestone (even with limited features) to validate signing, distribution, and backend connectivity.

Status: ✅ Mostly complete (core foundation delivered; release hardening remains iterative)

## Milestone 2 — Logging Core
- Meal diary screens.
- Unit conversion + macro calculations.
- Daily totals and target progress.
- Testing: add calculation regression tests and iOS UI tests for add/edit/delete meal log flows.
- Release strategy: push milestone-complete TestFlight build and run end-to-end diary smoke test on device.

Status: 🟡 Not started (plan created in `MILESTONE_2_PLAN.md`)

## Milestone 3 — Recipes + Wet Weight
- Recipe creation/editing.
- Cook session + final wet-weight entry.
- Portion-by-grams logging + leftovers.
- Testing: add wet-weight math golden tests and integration tests for leftover state transitions.
- Release strategy: push TestFlight build focused on recipe + leftovers real-device workflow validation.

Status: 🟡 Not started (plan created in `MILESTONE_3_PLAN.md`)

## Milestone 4 — Barcode + Quality
- Barcode scanner UX.
- External barcode lookup + fallback.
- Validation, edge-case handling, and speed improvements.
- Testing: add barcode mock/fixture tests, offline fallback tests, and end-to-end diary logging smoke tests.
- Release strategy: push TestFlight build for camera/barcode reliability checks in real-world usage.

Status: 🟡 Not started (plan created in `MILESTONE_4_PLAN.md`)

## Milestone 5 — Deploy + Operate
- Deploy backend + DB on low-cost host.
- Backups, monitoring, and basic analytics.
- Maintain continuous TestFlight cadence (early and often): release after each milestone and for major feature branches.
- Testing: require CI green on all suites before TestFlight release and run post-deploy health checks.

Status: 🟡 Not started (plan created in `MILESTONE_5_PLAN.md`)

---

## 12) Acceptance Criteria (MVP)
1. User can create/edit custom ingredients with nutrition values.
2. User can log foods by grams or common kitchen volume units.
3. User can scan barcode and either auto-fill or manually fill item details.
4. User can create a recipe and enter final cooked weight.
5. User can log consumed grams from cooked recipe and get accurate macros.
6. User can save and reuse recipes from a library.
7. User can view daily calorie + macro totals versus targets.

---

## 13) Risks & Mitigations
- Barcode DB incompleteness -> fallback manual flow and local barcode map.
- Volume conversion inaccuracies -> density-aware conversion + user warnings.
- Sync complexity -> start single-device + cloud backup, then expand.
- Scope creep -> keep strict MVP boundary until milestone 5.

---

## 14) Finalized Product Decisions

### Confirmed decision
1. Launch as **single-user**.
2. Include a roadmap feature for **sharing meals/recipes with spouse's app instance** (without full household multi-user collaboration in MVP).
3. Input policy by food type:
  - Use **weight-first** entry for foods typically measured by weight (e.g., meat, vegetables).
  - Use **volume-first** entry for liquids (e.g., oil, milk) and common pantry grains/powders (e.g., sugar, rice, wheat/flour).
4. Mandatory nutrition fields: **calories, carbs, protein**.
5. Login approach: start with **email magic link** for MVP (easiest deployment), then add **Sign in with Apple** after core workflows are stable.
6. Backup/export requirement at MVP: **full JSON export/import**.
7. Backend stack for implementation: **Node.js + TypeScript (Fastify)** with **Supabase Postgres/Auth (Free tier)** for Milestone 1.

---

## 15) Definition of Done for Planning Phase
- [x] Goals documented.
- [x] MVP and non-MVP scope separated.
- [x] Architecture recommendation documented.
- [x] Data model and core workflows defined.
- [x] Milestones and acceptance criteria drafted.
- [x] Resolve remaining open items in section 14.

---

## 16) MVP v1 Execution Checklist (Coding Mode)

### Foundation & Tooling
- [x] Create iOS app project skeleton (SwiftUI) and backend service skeleton.
- [x] Set up CI pipeline (build + tests + lint checks).
- [x] Configure dev/staging/prod environment variables and secrets handling.
- [ ] Establish API schema and versioning conventions.

### Auth & User Profile
- [x] Implement email magic-link authentication.
- [x] Add user profile and macro target settings (calories, carbs, protein).
- [ ] Add sign-out/session expiration handling.

### Ingredient System
- [x] Implement ingredient create/read/update/archive.
- [ ] Support input units: g, oz, lb, ml, tsp, tbsp, cup.
- [ ] Implement conversion engine with canonical storage and density-aware volume conversion.
- [ ] Add manual custom ingredient creation flow optimized for raw produce.

### Meal Logging
- [ ] Build daily diary screens (breakfast/lunch/dinner/snacks).
- [ ] Add quick-log from ingredient and recipe.
- [ ] Show per-meal and daily totals versus macro targets.
- [ ] Store immutable nutrition snapshot on each logged item.

### Recipes & Wet Weight
- [ ] Build recipe create/edit/save flow.
- [ ] Implement cook session with final wet weight input.
- [ ] Compute macros-per-gram from final cooked weight.
- [ ] Log consumed grams and track leftovers accurately.

### Barcode
- [ ] Add barcode scanning (camera permission + scanner UX).
- [ ] Integrate external barcode lookup with timeout/retry behavior.
- [ ] Implement no-match fallback to manual ingredient creation.
- [ ] Cache barcode results locally for repeat scans.

### Export & Data Portability
- [ ] Implement full JSON export for user data.
- [ ] Implement full JSON import with schema validation.
- [ ] Add conflict handling for duplicate ingredients/recipes on import.

### Quality Gates
- [ ] Unit tests for conversion and macro calculations.
- [ ] Integration tests for ingredient, recipe, and cook session APIs.
- [ ] UI tests for primary logging flows.
- [ ] End-to-end smoke test script for real-device milestone validation.

### Release & Operations
- [x] Produce first internal TestFlight build in Milestone 1.
- [ ] Release updated TestFlight build after each milestone and major feature branch.
- [ ] Require CI green before every TestFlight submission.
- [ ] Run post-deploy health checks for backend and DB after each release.

---

## 17) Current Progress Snapshot (2026-02-16)

### Delivered
- Backend: auth/profile + ingredient CRUD APIs, tests, lint/typecheck, CI, Supabase staged persistence, smoke test.
- iOS: auth/profile + ingredient CRUD screens, session handling, callback URL wiring for deep-link flow, shared Xcode scheme for CLI/CI.
- Infra/docs: Supabase setup guide, migration workflow, RLS enablement migration, secret-handling guidance.

### Next Critical Path
1. Milestone 2 logging domain + diary UI/API.
2. Milestone 3 recipe/cook-session/wet-weight math.
3. Milestone 4 barcode integration + fallback + quality pass.
4. Milestone 5 deploy/operate hardening and release cadence.
