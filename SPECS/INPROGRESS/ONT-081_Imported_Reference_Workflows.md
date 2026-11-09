# ONT-081 — Imported references in compatibility and publication workflows

## Problem

An ontology containing a source-bound imported `Ref` can pass `check` and
`compile` but cannot be compared, checked against registry IR, or published.
Those workflows validate without the supplied dependency snapshots.

## Contract

- Accept repeatable local imports, bound by exact declared package identity and
  version, without network discovery or replacing a missing source by name.
- `diff` accepts separately scoped old and new imports; changed dependency
  versions must not contaminate the opposite snapshot.
- `publish`, `compat-check`, and decision validation use the same explicit
  imports as package checking, including trusted publication's decision gate.
- Normalize from those validated sources and compare imported target identity;
  changed target identity is classified conservatively rather than silently
  considered equivalent. Source digests are provenance, not semantic changes.
- No report or registry mutation occurs if a source is absent, malformed, a
  wrong version, or does not contain the declared target.

## Validation

Exercise local and CLI paths with two versions of a dependency, unchanged and
changed imported targets, missing and mismatched sources, local registry
round-trips, and trusted governance. Preserve existing no-import behavior.
