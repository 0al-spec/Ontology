# Next Task: ONT-008 - OntologyRules Specification Extraction

**Priority:** P1
**Phase:** Code Quality and Maintainability
**Effort:** 9h
**Dependencies:** ONT-007
**Status:** Not Started
**PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## Description

Move current validation predicates into named `SpecificationCore` specifications for package shape, metadata, references, security, relations, policies, and state machines.

## Next Step

Run the Flow lifecycle for ONT-008 starting from BRANCH/SELECT, then extract validation predicates without changing compiler behavior.

## TODO Summary

| ID | Task | Effort |
|---|---|---:|
| T-006 | Extract metadata, package shape, and reference specs | 4h |
| T-007 | Extract security, relation, policy, and state machine specs | 5h |

Total: **9h**.

## Upcoming Tasks

| Task ID | Title | Dependencies | Status |
|---|---|---|---|
| ONT-009 | Ontology DecisionSpec Migration | ONT-008 | Not Started |
| ONT-010 | Specification-Driven Refactor Documentation and Audit | ONT-009 | Not Started |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---|---|---|---|
| ONT-007 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-007_ontologyc_Compiler_Module_Split/` |
| ONT-006 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/` |
| ONT-005 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/` |
| ONT-004 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/` |
| ONT-003 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/` |
| ONT-002 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/` |
| ONT-001 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/` |
