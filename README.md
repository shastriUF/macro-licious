# Macro-licious

A planning-first repository for an iPhone-focused calorie and macro tracking app designed for home cooking workflows.

## Why this project exists
Most mainstream calorie trackers are ad-heavy and optimized for packaged foods. This app is being designed to prioritize:
- precise ingredient entry for fresh cooking,
- recipe and leftovers tracking using cooked wet weight,
- clean UX without ad noise,
- practical deployment and testing cadence with early TestFlight releases.

## Current status
This repo currently contains product and implementation planning artifacts only.

Primary plan document:
- [APP_IMPLEMENTATION_PLAN.md](APP_IMPLEMENTATION_PLAN.md)

## Planned MVP capabilities
- Daily calorie + macro tracking
- Ingredient entry via weight and volume units
- Custom ingredient management for raw produce and changing brands
- Barcode lookup with manual fallback
- Recipe saving and reuse
- Wet-weight based cooked dish portioning and leftover tracking
- Full JSON backup/export and import

## Architecture direction
The project currently targets:
- iOS app: SwiftUI
- Lightweight backend + managed Postgres
- Early and frequent TestFlight builds throughout milestones

See details in [APP_IMPLEMENTATION_PLAN.md](APP_IMPLEMENTATION_PLAN.md).

## Repository structure
- [APP_IMPLEMENTATION_PLAN.md](APP_IMPLEMENTATION_PLAN.md): product scope, architecture, milestones, testing strategy, execution checklist
- [README.md](README.md): visitor overview and onboarding

## Development approach
- Planning first, then coding milestones
- Testing included in every milestone
- TestFlight used early and often for end-to-end validation

## Contributing
Contributions are welcome once initial scaffolding begins. For now, feedback on product scope and milestone sequencing is especially useful.

## Privacy and data handling (intent)
This project is intended to be privacy-respecting:
- no ads,
- no data resale,
- user-controlled backup/export.

Formal privacy and security documents will be added as implementation starts.

## License
No license has been selected yet.
If this repository is made open source, a license should be added before accepting external contributions.
