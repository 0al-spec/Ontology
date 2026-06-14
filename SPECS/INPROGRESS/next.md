# Next Task: ONT-037 — SpecGraph Owner Decision Report Export

**Priority:** P0
**Phase:** External Ontology Import Plane Follow-Ups
**Effort:** 4-6 hours
**Dependencies:** ONT-036
**Status:** Executed locally; Swift build blocked by `SpecificationCore` 1.0.0 on Apple Swift 6.3.2

## Description

Add an Ontology-owned owner-decision export for SpecGraph ontology delta
candidates. The report should carry accepted, rejected, and needs-clarification
decisions in the shape SpecGraph already consumes, while preserving the boundary
that decisions are evidence only and do not mutate Ontology packages, lockfiles,
semantic gates, or canonical SpecGraph specs.

## Next Step

Open the focused PR, inspect remote CI, and archive the task after validation
is green or the dependency/toolchain blocker is explicitly resolved.
