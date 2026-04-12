# UI/UX Improvement Plan — macrolicious iOS App

Created: 2026-04-12
Status: In progress (P0–P2)

---

## Current Problems (Audit)

### 1. Visual Density / "Giant Table" Feel
- The entire app uses `Form` with flat `Section` layouts — every screen looks like a settings page
- The Meals tab crams the date picker, refresh button, quick add, two segmented pickers, notes field, ingredient picker, quantity/unit fields, computed nutrition, validation message, add button, daily totals, macro progress bars, AND the meal log list all into a single `Section("Diary")`
- The Ingredients tab similarly dumps the create-ingredient form (9+ fields) and the full ingredient list into one `Section("Ingredients")`
- No visual hierarchy — inputs, buttons, display data, and lists all have equal visual weight

### 2. "Plus" Icon Not Visible on Active Button
- `Label("Add Meal Log Entry", systemImage: "plus.circle.fill")` with `.buttonStyle(.borderedProminent)` — the SF Symbol inherits the white foreground on blue background but `plus.circle.fill` is a filled circle with a plus cutout, making the plus nearly invisible against the tinted background

### 3. Other Visual Issues
- Status section repeated on every tab (sign-in, meals, ingredients) — clutters the bottom
- No empty state illustrations or guidance — just plain "No meal logs for selected date" text
- Macro progress section has no visual separation from the meal log list
- Quick presets use `.thinMaterial` which can look washed out
- Ingredient nutrition shown as dense abbreviated text ("P 12 • C 45 • F 8 • kcal 200") — hard to scan

---

## Phase 1: P0 — Quick Wins

### A. Fix "plus" icon visibility
- [ ] Change the add button icon to `"plus"` (plain) so it renders clearly on the prominent button background

### B. Break the Meals tab into multiple Sections
- [ ] **Section "New Entry"** — composer (meal type, entry mode, ingredient/manual fields, quantity, add button)
- [ ] **Section "Today's Summary"** — daily totals + macro progress bars
- [ ] **Section "Meal Log"** — just the list of logged meals
- [ ] Quick presets stay above the composer in the "New Entry" section

### C. Break the Ingredients tab into multiple Sections
- [ ] **Section "Add Ingredient"** — creation form moves into a `.sheet` triggered by a toolbar "+" button
- [ ] **Section "Your Ingredients"** — the ingredient list only

### D. Remove redundant Status sections
- [ ] Show status/loading only on Sign In tab; Meals and Ingredients use inline indicators or toolbar spinners

---

## Phase 2: P1 — Visual Hierarchy & Polish

### E. Card-style meal log entries
- [ ] Replace flat `VStack` rows with card-like `RoundedRectangle` backgrounds
- [ ] Group items within each meal log visually (indented with a leading accent bar or grouped padding)
- [ ] Show meal type as a colored badge/chip instead of plain headline text

### F. Macro progress redesign
- [ ] Replace linear `ProgressView` bars with `Gauge` ring style or compact colored bar chart
- [ ] Show "remaining" framing instead of "over by X" for positive UX

### G. Better nutrition formatting
- [ ] Replace "P 12 • C 45 • F 8 • kcal 200" with colored rounded-rect pill labels
- [ ] Apply consistently across ingredient list, meal log items, and computed previews

### H. Ingredient creation → sheet
- [ ] Move 9-field ingredient creation form into a `.sheet` with a toolbar "+" button
- [ ] Ingredients tab body becomes just the list (pairs with P0-C)

---

## Phase 3: P2 — Interaction Improvements

### I. Collapsible/expandable composer on Meals tab
- [ ] Move the new-entry composer into a sheet or half-sheet triggered by a FAB / toolbar button
- [ ] Meal log list becomes the primary content of the Meals tab

### J. Better empty states
- [ ] SF Symbol + description text for empty meal logs ("No meals logged today — tap + to add one")
- [ ] SF Symbol + description for empty ingredients ("Tap + to add your first ingredient")

### K. Search and sort for ingredients *(deferred to M4)*
- [ ] Search bar at top of ingredient list
- [ ] Sort by name, recently used, macro value

### L. Meal log timeline grouping *(deferred to M4)*
- [ ] Group meal logs by meal type with section headers and subtotals
- [ ] "Breakfast — 450 kcal", "Lunch — 620 kcal", etc.

---

## Deferred: P3 — Sign In Tab Cleanup

### M. Simplify sign-in layout
- [ ] Move backend URL config behind a settings/gear icon
- [ ] Once signed in, show profile + macro targets instead of auth form
- [ ] Or: remove Sign In tab entirely → full-screen auth flow → 2-tab layout (Meals / Ingredients) with profile in toolbar menu

---

## Implementation Order

| # | Item | Phase | Status |
|---|------|-------|--------|
| 1 | Fix plus icon | P0-A | Not started |
| 2 | Split Meals tab into sections | P0-B | Not started |
| 3 | Ingredients tab — creation form to sheet | P0-C / P1-H | Not started |
| 4 | Consolidate status display | P0-D | Not started |
| 5 | Card-style meal log entries | P1-E | Not started |
| 6 | Nutrition pill formatting | P1-G | Not started |
| 7 | Macro progress visual upgrade | P1-F | Not started |
| 8 | Composer → sheet on Meals tab | P2-I | Not started |
| 9 | Better empty states | P2-J | Not started |
| 10 | Sign-in tab restructure | P3-M | Deferred |
| 11 | Ingredient search/sort | P2-K | Deferred (M4) |
| 12 | Meal log timeline grouping | P2-L | Deferred (M4) |

---

## Notes
- All changes are iOS-only; no backend changes needed
- UI tests will need updates as accessibility identifiers and view hierarchy change
- Should preserve existing functionality — purely visual/UX changes
