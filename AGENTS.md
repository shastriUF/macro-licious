# Project Guidelines

## Architecture

- **Backend**: TypeScript + Fastify, in `backend/`. Supabase for Postgres and Auth.
- **iOS**: Native SwiftUI app in `ios/macrolicious/`. No third-party dependencies.
- **Database**: Supabase Postgres with versioned migrations in `supabase/migrations/`.
- **Planning**: Milestone-driven. See `APP_IMPLEMENTATION_PLAN.md` and `MILESTONE_*.md` for current status and scope.

## Build and Test

### Backend
```sh
cd backend && npm install
npm test          # vitest — all tests must pass before committing
npm run dev       # local dev server
```

### iOS
```sh
# Unit tests
xcodebuild test -project ios/macrolicious/macrolicious.xcodeproj \
  -scheme macrolicious \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:macroliciousTests

# UI tests
xcodebuild test -project ios/macrolicious/macrolicious.xcodeproj \
  -scheme macrolicious \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:macroliciousUITests
```

### Supabase
```sh
supabase db push   # apply pending migrations to remote
```

## Conventions

- **Commits**: Use conventional commit format with scope — `feat(ios):`, `fix(backend):`, `docs:`, `chore:`.
- **Backend API shape**: Fastify routes return camelCase JSON. Zod for request validation. Domain models in `backend/src/domain/models.ts`.
- **iOS JSON decoding**: Standard `JSONDecoder()` — no snake_case conversion. Swift model property names must match API JSON keys exactly.
- **Unit conversion**: Shared logic in `backend/src/domain/unit-conversion.ts` and `ios/.../UnitConversion.swift`. Keep these in sync when adding units.
- **Plan docs**: Keep `APP_IMPLEMENTATION_PLAN.md` and relevant `MILESTONE_*.md` updated when features are added or milestones close.
- **Tests before commits**: All backend and iOS unit tests must pass. Run both test suites before committing.
- **SwiftUI sheets**: When a sheet needs data from the presenting view, initialise `@State` in the sheet's own `init` from parameters — don't rely on external `@State` set before presentation (race-prone).

## Debugging

When investigating bugs, diagnose root causes rather than applying surface-level patches. Trace the data flow end-to-end (backend response → iOS decoding → view state → rendering) before proposing a fix.
