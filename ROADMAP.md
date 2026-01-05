# Roadmap

This roadmap is intentionally minimal.

scenic-kernel is being developed by enforcing contracts first and discovering
capabilities through use, not by committing to a fixed feature list.

## Phase 0 — Kernel Contract
- establish a deterministic stepping model
- define the append-only event log
- enforce purity and explicit time
- write tests that lock in invariants

## Phase 1 — Minimal Structure
- introduce the smallest possible scene and system abstractions
- ensure all state changes are represented as events
- keep projections read-only and derived

## Phase 2 — Integration Pressure
- use the kernel from at least one external application
- identify missing or awkward contracts
- refine APIs only when forced by real usage

## Phase 3 — Stabilization
- document invariants that have survived use
- resist adding features without clear contracts
- keep the kernel small, boring, and predictable

Near-term details are intentionally left unspecified.  
The roadmap exists to constrain ambition, not to promise scope.
