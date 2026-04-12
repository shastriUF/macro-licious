# Milestone 5 Plan — Deploy + Operate

Last updated: 2026-04-12

## 1) Milestone Objective
Operationalize the product with stable deployment, release discipline, and basic production observability/backup hygiene.

---

## 2) Scope

## Already Delivered (pulled forward)
- ✅ Render Free deployment live at `macrolicious-api.onrender.com` (deployed in M2)
- ✅ Supabase Postgres with versioned migrations via `supabase db push`
- ✅ TestFlight distribution established (archive + upload from Xcode)
- ✅ Backend build/start scripts working in production (`npm run build && npm start`)
- ✅ Environment variables configured on Render (SUPABASE_URL, keys, AUTH_PROVIDER)

## Remaining In Scope
1. CI gating policy: require lint + typecheck + tests green before merge/release
2. DB backup/restore documentation and verification
3. Health check automation (periodic ping or uptime monitor)
4. Release checklist document (backend deploy + iOS TestFlight)
5. Env/secrets rotation checklist
6. Incident first-response checklist
7. Consider upgrading from Render Free (cold starts) if usage warrants

## Out of Scope
- Advanced analytics/coaching
- Multi-region scaling

---

## 3) Deliverables

## Infrastructure
- [x] Production backend instance on Render
- [x] Stable base URL (`https://macrolicious-api.onrender.com`)
- [ ] Managed DB backup policy documented
- [ ] Uptime monitor or health check cron

## Operational docs
- [ ] Release checklist (backend + iOS)
- [ ] Incident first-response checklist
- [ ] Env/secrets rotation checklist

---

## 4) Testing & Quality Gates
- CI must pass lint/typecheck/tests before release
- Post-deploy health check for `/health` endpoint
- Manual device sanity run on latest TestFlight build

---

## 5) Implementation Sequence

## Phase A — CI + release process
1. Add GitHub Actions CI workflow (lint + typecheck + test)
2. Document release checklist for backend + iOS
3. Add pre-push or PR gate requiring CI green

## Phase B — Operability
1. Document DB backup/restore procedure
2. Add uptime monitoring (e.g. UptimeRobot free tier or similar)
3. Document secrets rotation procedure

## Phase C — Stabilization
1. Run full smoke suite against Render deployment
2. Evaluate Render tier (free vs starter) based on cold-start impact
3. Ship milestone TestFlight build + production verification

---

## 6) Definition of Done
- [x] Production deploy is stable and reproducible
- [ ] CI gate enforced on PRs/pushes
- [ ] Backup/restore procedure documented and verified
- [ ] Release checklist completed and committed
- [ ] Health checks validated after deploy
- [ ] Milestone release checklist completed
