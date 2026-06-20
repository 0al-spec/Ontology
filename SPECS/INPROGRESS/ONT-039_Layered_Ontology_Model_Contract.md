# ONT-039: Layered Ontology Model Contract PRD

**Status:** PRD Ready
**Priority:** P0
**Phase:** Layered Ontology Stack
**Reasoning Effort:** high
**Dependencies:** ONT-038
**Branch:** `codex/ont-039-layered-ontology-model`

## TL;DR

Add a minimal first-class ontology layer contract to `DomainOntologyPackage`,
compiler validation, normalized IR, generated TypeScript artifacts, and
compatibility reporting. The first layer vocabulary is:

- `objective`
- `mechanics`
- `execution`
- `meta`
- `multi_agent`

This is a compiler contract slice. It does not make product ontologies canonical
inside this repository and does not add SpecGraph or SpecSpace runtime behavior.

## Problem

SpecGraph and SpecSpace can now consume compiler-backed ontology packages, but
the model is still flat: a concept ref does not say whether it is a goal,
deterministic domain mechanic, execution assumption, ontology-change concept, or
adaptive actor. That makes downstream agents and reviewers treat very different
claims as the same kind of semantic reference.

The next step is not a strict formal system. The next step is small metadata
that lets downstream systems preserve layer intent and later build layer-aware
gaps, diffs, backfill reports, write gates, and review surfaces.

## Goals

1. Add a constrained `OntologyLayer` vocabulary:
   `objective`, `mechanics`, `execution`, `meta`, `multi_agent`.
2. Allow optional `layer` metadata on primary ontology elements:
   `classes`, `protocols`, `relations`, `policies`, and `stateMachines`.
3. Reject unknown layer values deterministically during `ontologyc check`.
4. Preserve layer metadata in normalized IR.
5. Emit layer metadata through generated TypeScript artifacts.
6. Classify class/relation layer additions or changes in compatibility reports.
7. Add fixtures/tests showing all five layer values without turning example
   product ontology data into trusted global ontology truth.

## Non-Goals

- Requiring every existing package element to declare a layer.
- Adding SpecGraph `LayeredConceptRef`.
- Adding `ModelApplicabilityProfile`.
- Updating SpecSpace UI.
- Changing ontology package authority or governance rules.
- Moving product/workspace ontology data into this repository beyond examples
  and fixtures.
- Inferring layers from descriptions or other natural language.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Schema contract | `SPECS/ontology/domain-ontology-package.schema.yaml` | `layer` is accepted only from the constrained vocabulary. |
| D2 | Compiler validation | `Sources/OntologyCompiler/PackageValidation.swift`, `Sources/OntologyRules/` | Unknown layer values emit deterministic diagnostics. |
| D3 | Normalized IR | `Sources/OntologyCompiler/Normalization.swift`, docs | Layer metadata is preserved when present. |
| D4 | TypeScript projection | `Sources/OntologyCompiler/TypeScriptEmitter.swift` | Generated refs/definitions expose layer metadata. |
| D5 | Compatibility report | `Sources/OntologyCompiler/CompatibilityDiff.swift`, `Sources/OntologyRules/` | Class/relation layer additions and changes are visible in report output. |
| D6 | Layered fixture/tests | `Tests/OntologyCompilerTests/` and fixture docs or package | Tests cover all five layer values and unknown-layer rejection. |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-039_Validation_Report.md` | Records local checks and residual risks. |

## Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-001 | `layer` MUST be optional so existing packages remain valid. | Existing tests pass. |
| FR-002 | `layer` MUST accept only `objective`, `mechanics`, `execution`, `meta`, and `multi_agent`. | Invalid package test. |
| FR-003 | `layer` MAY be declared on `classes`, `protocols`, `relations`, `policies`, and `stateMachines`. | Schema and compiler tests. |
| FR-004 | Normalized IR MUST include `layer` exactly when source elements declare it. | IR test. |
| FR-005 | Generated TypeScript refs/definitions MUST expose layer metadata for downstream consumers. | Emitter regression test or generated baseline drift test. |
| FR-006 | Compatibility reports MUST list class/relation layer additions or changes separately from removals and field changes. | Compatibility test. |
| FR-007 | Layer metadata MUST NOT change approval status, registry publish authority, or governance behavior. | Code review and validation report. |

## Design Decisions

### Layer Location

`layer` is allowed on all primary top-level ontology elements in this slice:

- classes;
- protocols;
- relations;
- policies;
- state machines.

This keeps authoring consistent and avoids forcing future PRs to revisit schema
shape just to tag non-class ontology elements.

### Compatibility Scope

The existing compatibility report compares classes, relations, and class fields.
ONT-039 extends that existing scope with class/relation layer changes. It does
not introduce policy/protocol/state-machine compatibility diffing in the same
PR.

### Optional Metadata

Layer metadata is optional in ONT-039. Making it required would force noisy
migration of existing examples before downstream value is proven.

## Risks

| Risk | Mitigation |
|------|------------|
| Layer values become fake precision. | Keep layer optional and descriptive; do not infer it automatically. |
| Downstream consumers treat layer metadata as authority. | Preserve existing draft/governance boundaries and document non-goals. |
| Compatibility output becomes too strict too early. | Report class/relation layer changes explicitly without making them breaking in this slice. |
| Product ontologies leak into this repo. | Use minimal fixtures/examples only; keep product ontology storage project-owned. |

## Notes

SpecGraph can follow this with `LayeredConceptRef` and a minimal
`ModelApplicabilityProfile`. SpecSpace can follow with a layer lens in the
Ontology Workbench once SpecGraph publishes layer-aware derived artifacts.
