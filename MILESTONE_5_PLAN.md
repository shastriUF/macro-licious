# Milestone 5 Plan — Deploy + Operate

Last updated: 2026-02-16

## 1) Milestone Objective
Operationalize the product with stable deployment, release discipline, and basic production observability/backup hygiene.

---

## 2) Scope

## In Scope
1. Production backend deployment and environment configuration
2. DB backup/restore baseline
3. Health checks and basic service monitoring
4. CI gating policy before release
5. Repeatable TestFlight release cadence and checklist

## Out of Scope
- Advanced analytics/coaching
- Multi-region scaling

---

## 3) Deliverables

## Infrastructure
- Production backend instance
- Stable domain/base URL strategy
- Managed DB backup policy documented

## Operational docs
- Release checklist (backend + iOS)
- Incident first-response checklist
- Env/secrets rotation checklist

---

## 4) Testing & Quality Gates
- CI must pass lint/typecheck/tests before release
- Post-deploy health checks for auth/profile/ingredients/logging/recipes endpoints
- Manual device sanity run on latest TestFlight build

---

## 5) Implementation Sequence

## Phase A — Deploy baseline
1. Finalize host and deployment config
2. Configure prod env and secrets
3. Verify DB migrations in production path

## Phase B — Operability
1. Add health probes and alerting hooks
2. Document backup/restore and rotation procedures
3. Add release checklist docs

## Phase C — Stabilization
1. Run load/smoke sanity checks
2. Run release dry-run
3. Ship milestone TestFlight build + production verification

---

## 6) Definition of Done
- [ ] Production deploy is stable and reproducible
- [ ] Backup/restore procedure documented and verified
- [ ] CI and release gate policy enforced
- [ ] Health checks validated after deploy
- [ ] Milestone release checklist completed
