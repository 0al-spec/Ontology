# Next Task: ONT-007 - `ontologyc` Compiler Module Split

**Priority:** P1
**Phase:** Code Quality and Maintainability
**Effort:** 10h
**Dependencies:** ONT-006
**Status:** PRD Ready
**PRD:** `SPECS/INPROGRESS/ONT-007_ontologyc_Compiler_Module_Split.md`

## Description

Split the current monolithic Swift compiler implementation into a thin CLI executable and an importable `OntologyCompiler` target with focused compiler phase files.

## Next Step

Run the Flow lifecycle for ONT-007 starting from BRANCH/SELECT, then perform a behavior-preserving module split under the ONT-006 regression harness.

## TODO Summary

| ID | Task | Effort |
|---|---|---:|
| T-003 | Split `OntologyC` executable from compiler core | 5h |
| T-004 | Move compiler phases into focused files | 5h |

Total: **10h**.

## Upcoming Tasks

| Task ID | Title | Dependencies | Status |
|---|---|---|---|
| ONT-008 | OntologyRules Specification Extraction | ONT-007 | Not Started |
| ONT-009 | Ontology DecisionSpec Migration | ONT-008 | Not Started |
| ONT-010 | Specification-Driven Refactor Documentation and Audit | ONT-009 | Not Started |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---|---|---|---|
| ONT-006 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/` |
| ONT-005 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/` |
| ONT-004 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/` |
| ONT-003 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/` |
| ONT-002 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/` |
| ONT-001 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/` |
