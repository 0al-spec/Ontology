# ONT-038: SpecGraph Core Ontology Package PRD

**Status:** PRD Ready
**Priority:** P0
**Phase:** SpecGraph Core Ontology Integration
**Reasoning Effort:** high
**Dependencies:** ONT-036, ONT-037
**Branch:** `codex/ont-038-specgraph-core-package`

## TL;DR

Materialize the small SpecGraph Core Ontology seed as a real
`DomainOntologyPackage` owned by the Ontology repository. The package should
compile through `ontologyc` and emit normalized IR and TypeScript SDK artifacts
that downstream SpecGraph and SpecSpace work can consume for resolved refs,
ontology gaps, compatibility diffs, and owner-decision review surfaces.

## Problem

SpecSpace now has a curated `SpecGraph Core Ontology v0` read model that removed
the old noisy extraction layer. That read model is useful for presentation, but
it is not a compiler-backed ontology authority boundary. SpecGraph and SpecSpace
need the same core vocabulary to come from Ontology compiler outputs rather than
hardcoded UI data.

## Goals

1. Add a `specgraph-core` ontology package with the initial core vocabulary:
   `SpecGraph`, `Intent`, `Spec`, `Node`, `Edge`, `Requirement`,
   `AcceptanceCriterion`, `Decision`, `Constraint`, `Invariant`, `Evidence`,
   `CodeSurface`, `Test`, and `Release`.
2. Model the core semantic relations used by the review graph:
   `contains`, `refines`, `defines`, `has`, `is_validated_by`,
   `connected_by`, `relates`, `constrains`, `applies_to`, `governs`,
   `implements`, `validates`, `packages`, and `supports`.
3. Compile the package with `ontologyc` to deterministic generated artifacts and
   `ontology.normalized.json`.
4. Keep `approvalStatus: draft`; this task does not approve ontology truth.
5. Add regression coverage proving the package checks and compiles.
6. Document that the package is the compiler-backed source for downstream
   SpecGraph semantic binding/gap/diff work.

## Non-Goals

- Mutating SpecGraph specs.
- Creating a canonical SpecGraph ontology lockfile.
- Publishing the package to a trusted registry.
- Accepting owner decisions automatically.
- Building SpecSpace UI in this repo.
- Replacing the `examcalc` golden package.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | SpecGraph Core package YAML | `SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml` | `ontologyc check` passes. |
| D2 | Generated compiler artifacts | `SPECS/ontology/packages/specgraph-core/generated/` | `ontologyc compile` emits normalized IR and TypeScript SDK files. |
| D3 | Package docs | `SPECS/ontology/packages/specgraph-core/README.md` | Explains scope, draft authority, and downstream use. |
| D4 | Regression tests | `Tests/OntologyCompilerTests/SpecGraphCorePackageTests.swift` | Verifies check, compile, core refs, and relation ids. |
| D5 | README/docs update | `README.md` | Mentions `specgraph-core` alongside `examcalc` as a compiler-backed package. |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-038_Validation_Report.md` | Records local checks and residual risks. |

## Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-001 | Package metadata MUST use id `org.0al.specgraph.core`, namespace `sgcore`, version `0.1.0`, and `approvalStatus: draft`. | YAML inspection and compiler test. |
| FR-002 | Core classes MUST include the 14 seed concepts listed in Goals. | Test reads normalized IR class ids. |
| FR-003 | Core relations MUST include the 16 seed relation statements from the curated graph. | Test reads normalized IR relation ids and domain/range pairs. |
| FR-004 | `ontologyc check` MUST pass for the package. | CLI check and test. |
| FR-005 | `ontologyc compile` MUST emit deterministic generated artifacts. | CLI compile and committed generated files. |
| FR-006 | The package MUST remain a draft source, not trusted authority. | Metadata assertion and docs. |

## Risks

| Risk | Mitigation |
|------|------------|
| The core package is mistaken for approved ontology truth. | Keep `approvalStatus: draft` and document governance boundary. |
| SpecGraph hardcodes the UI seed instead of consuming compiler IR. | Treat this package as the next downstream input for semantic bindings and gap/diff surfaces. |
| Relation verbs are too generic for long-term ontology design. | Accept generic seed relations for v0; future diffs can refine them under compatibility review. |

## Notes

This task intentionally creates a small compiler-backed substrate first. Later
SpecGraph and SpecSpace slices should consume its normalized IR, emit gaps for
unknown refs, show compatibility diffs for candidate deltas, and preserve owner
decisions as review evidence until a separate import action is approved.
