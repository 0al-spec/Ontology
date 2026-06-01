# Next Task: ONT-006 - SpecificationCore Baseline and Regression Harness

**Priority:** P1
**Phase:** Code Quality and Maintainability
**Effort:** 11h
**Dependencies:** ONT-004, ONT-005
**Status:** PRD Ready
**PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## Description

Add the first behavior-preserving ONT-006 implementation slice: Swift regression tests for current `ontologyc` behavior plus the pinned `SpecificationCore` dependency and `OntologyRules` target scaffold.

## Next Step

Run the Flow lifecycle for ONT-006 starting from BRANCH/SELECT, then lock the current compiler behavior before production refactoring.

## TODO Summary

| ID | Task | Effort |
|---|---|---:|
| T-001 | Add baseline regression tests for CLI commands | 5h |
| T-002 | Add deterministic output hash helper in Swift tests | 3h |
| T-005 | Add `SpecificationCore` dependency and `OntologyRules` target | 3h |

Total: **11h**.

## Upcoming Tasks

| Task ID | Title | Dependencies | Status |
|---|---|---|---|
| ONT-007 | `ontologyc` Compiler Module Split | ONT-006 | Not Started |
| ONT-008 | OntologyRules Specification Extraction | ONT-007 | Not Started |
| ONT-009 | Ontology DecisionSpec Migration | ONT-008 | Not Started |
| ONT-010 | Specification-Driven Refactor Documentation and Audit | ONT-009 | Not Started |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---|---|---|---|
| ONT-005 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/` |
| ONT-004 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/` |
| ONT-003 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/` |
| ONT-002 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/` |
| ONT-001 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/` |
