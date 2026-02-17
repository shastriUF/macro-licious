# Milestone 4 Plan — Barcode + Quality

Last updated: 2026-02-16

## 1) Milestone Objective
Add reliable barcode-assisted ingredient entry and complete quality hardening for primary user workflows.

---

## 2) Scope

## In Scope
1. Camera-based barcode scan flow in iOS
2. Backend barcode lookup integration + timeout/retry rules
3. No-match fallback to manual ingredient creation
4. Local caching for repeat barcode scans
5. Performance and error-handling improvements across diary and recipes

## Out of Scope
- Household sharing and planner features

---

## 3) Deliverables

## Backend/API
- `GET /barcode/{code}` lookup endpoint
- Adapter for external food DB provider(s)
- Local barcode-to-ingredient cache model

## iOS
- Barcode scanner view (permissions + UX)
- Scan result handling (match / no match / error)
- Fast handoff into ingredient create/edit flow

---

## 4) Testing & Quality Gates
- Mocked provider tests for lookup success/failure/timeout
- Offline fallback tests
- iOS UI tests for scan path and fallback path
- End-to-end smoke test for scan -> log meal

---

## 5) Implementation Sequence

## Phase A — Provider integration
1. Select provider + adapter interface
2. Implement lookup endpoint and cache path
3. Add observability for provider errors/rate limits

## Phase B — iOS scanner
1. Add camera permission and scanner view
2. Connect scan result to backend lookup
3. Add fallback UX for unmatched barcodes

## Phase C — Quality pass
1. Add performance pass on frequent flows
2. Expand tests and run full smoke suite
3. Ship TestFlight milestone build

---

## 6) Definition of Done
- [ ] Barcode scan works reliably on device
- [ ] Lookup fallback flow works when data is missing
- [ ] Cache improves repeat scan speed
- [ ] Quality gates and smoke tests pass
- [ ] TestFlight validation complete
