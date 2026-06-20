# Next Task

## ONT-039 — Layered Ontology Model Contract

Status: Not Started
Branch: `codex/ont-039-layered-ontology-model`
Priority: P0
Dependencies: ONT-038

## Goal

Add a minimal first-class ontology layer contract to `DomainOntologyPackage`,
normalized IR, and generated TypeScript output. The first layer vocabulary is:

- `objective` — goals, stakeholders, utility functions, and tradeoffs;
- `mechanics` — deterministic domain entities, relations, rules, invariants,
  and policies;
- `execution` — real-world constraints such as latency, offline operation,
  uncertainty, human error, operational drift, or agent hallucination risk;
- `meta` — ontology versioning, gaps, deltas, compatibility, and invalidation
  triggers;
- `multi_agent` — adaptive actors such as users, competitors, adversaries, and
  other AI agents.

The slice should stay compiler-focused. It should not move product ontology
data into this repository beyond examples/fixtures, and it should not add
SpecGraph or SpecSpace behavior directly.

## Recently Archived

- ONT-037 — SpecGraph Owner Decision Report Export archived on 2026-06-14.

## Recently Completed

- ONT-038 — SpecGraph Core Ontology Package merged in PR #57 on 2026-06-20.
  Archive materialization is still a follow-up workflow task.

## Suggested Next Steps

- Create `SPECS/INPROGRESS/ONT-039_Layered_Ontology_Model_Contract.md`.
- Decide whether `layer` belongs on concepts only for the first slice or also
  on relations, invariants, policies, and generated IR entries.
- Extend the YAML schema and compiler validation for the constrained
  `OntologyLayer` vocabulary.
- Preserve layer metadata in normalized IR and TypeScript output.
- Add compatibility diff coverage for layer additions/changes.
- Add fixtures that show objective, mechanics, execution, meta, and multi-agent
  layer examples without making product ontology data canonical here.
