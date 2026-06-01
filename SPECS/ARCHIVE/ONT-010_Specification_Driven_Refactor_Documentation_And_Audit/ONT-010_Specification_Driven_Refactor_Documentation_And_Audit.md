# PRD: ONT-010 - Specification-Driven Refactor Documentation and Audit

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Code Quality and Maintainability  
**Reasoning Effort:** medium  
**Dependencies:** ONT-009  
**Parent PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## TL;DR

Close the SpecificationCore-based `ontologyc` refactor with documentation and final audit evidence. This task must not change compiler logic.

## Objective

Make the final architecture understandable and auditable by documenting module boundaries, the `SpecificationCore` dependency decision, validation commands, output hashes, and no-Ruby status.

## Scope

### In Scope

- Update `SPECS/ontology/ontologyc.md` with:
  - current SwiftPM target boundaries;
  - `OntologyCompiler` phase ownership;
  - `OntologyRules` specification and decision ownership;
  - `SpecificationCore` dependency rationale;
  - behavior-preserving refactor policy.
- Add final ONT-010 validation report.
- Run final quality gates:
  - build;
  - explicit dependency import check;
  - full test suite through fresh scratch-path `swiftbuild`;
  - manual CLI regression;
  - generated output hash;
  - no-Ruby audit;
  - archive/workplan consistency check.
- Archive ONT-010 artifacts through Flow.

### Out of Scope

- Production compiler logic changes.
- New validation semantics.
- New generated artifact shape.
- New dependencies.
- Ruby tooling.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Compiler architecture docs | `SPECS/ontology/ontologyc.md` | Documents module boundaries and `SpecificationCore` dependency decision |
| D2 | Final validation report | `SPECS/INPROGRESS/ONT-010_Validation_Report.md` | Records final build, tests, CLI checks, hashes, no-Ruby audit, and residual risks |
| D3 | Workplan/archive consistency | `SPECS/Workplan.md`, `SPECS/ARCHIVE/INDEX.md`, `SPECS/INPROGRESS/next.md` | ONT-010 completes the current refactor slice cleanly |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Docs MUST describe final module boundaries. | `ontologyc.md` covers `OntologyC`, `OntologyCompiler`, and `OntologyRules`. | Review |
| FR-002 | Docs MUST describe the `SpecificationCore` dependency decision. | Rationale and accepted SwiftPM surface are documented. | Review |
| FR-003 | Final audit MUST prove behavior preservation. | Tests, CLI regression, and hash checks pass. | Validation report |
| FR-004 | Final audit MUST prove no Ruby growth. | Changed files audit has no Ruby matches. | no-Ruby audit |
| FR-005 | Task MUST not change compiler logic. | Production source files are not modified except docs/spec artifacts. | `git diff --name-only` |

## Implementation Roadmap

### Phase 1 - Documentation

- Update `SPECS/ontology/ontologyc.md` with the post-ONT-009 architecture.
- Keep documentation factual and tied to current source paths.

### Phase 2 - Final Audit

- Run final build/test/hash/no-Ruby gates.
- Record exact commands and results in `ONT-010_Validation_Report.md`.

### Phase 3 - Flow Closure

- Archive ONT-010 PRD and validation report.
- Mark Workplan acceptance criteria complete.
- Add local REVIEW and archive it.

## Success Metrics

- `SPECS/ontology/ontologyc.md` reflects the actual current Swift package structure.
- Full fresh scratch-path test suite passes.
- Combined generated output hash remains `1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19`.
- No production compiler logic changes are present in ONT-010.
