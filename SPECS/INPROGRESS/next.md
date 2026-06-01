# Next Task: ONT-009 - Ontology DecisionSpec Migration

**Priority:** P1
**Phase:** Code Quality and Maintainability
**Effort:** 9h
**Dependencies:** ONT-008
**Status:** Not Started
**PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## Description

Move classification logic into typed `SpecificationCore` decision specs for relation range shape, concept ref resolution, SpecGraph resolved/gap classification, compatibility changes, and CLI command classification where useful.

## Next Step

Run the Flow lifecycle for ONT-009 starting from BRANCH/SELECT, then migrate classification branches into typed decision specs without changing compiler behavior.

## TODO Summary

| ID | Task | Effort |
|---|---|---:|
| T-008 | Introduce decision specs for relation range and concept resolution branches | 4h |
| T-009 | Migrate SpecGraph gap and compatibility change classification | 5h |

Total: **9h**.

## Upcoming Tasks

| Task ID | Title | Dependencies | Status |
|---|---|---|---|
| ONT-010 | Specification-Driven Refactor Documentation and Audit | ONT-009 | Not Started |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---|---|---|---|
| ONT-008 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-008_OntologyRules_Specification_Extraction/` |
| ONT-007 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-007_ontologyc_Compiler_Module_Split/` |
| ONT-006 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/` |
| ONT-005 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/` |
| ONT-004 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/` |
| ONT-003 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/` |
| ONT-002 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/` |
| ONT-001 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/` |
