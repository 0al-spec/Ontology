# Next Tasks: ONT-016, ONT-017, ONT-018

**Status:** PRD Ready

## Description

Three new tasks open Phase 6 (Protocol Interfaces and Advanced Validation) and Phase 7
(Registry and Distribution). They extend the compiler and CLI surface without touching
existing behavior.

## Pending Tasks

| Task ID | Title | Phase | Priority | PRD |
|---------|-------|-------|----------|-----|
| ONT-016 | Protocol Interfaces and Compiler Support | 6 | P2 | `SPECS/INPROGRESS/ONT-016_Protocol_Interfaces_And_Compiler_Support.md` |
| ONT-017 | Zod/JSON Schema Validators for ABox Instances | 6 | P2 | `SPECS/INPROGRESS/ONT-017_Zod_JSON_Schema_Validators_For_ABox.md` |
| ONT-018 | CLI Registry Commands (publish, pull, compat-check) | 7 | P2 | `SPECS/INPROGRESS/ONT-018_CLI_Registry_Commands.md` |

## Sequencing Notes

- ONT-016 before ONT-017: the schema emitter conditionally injects protocol required-fields,
  so protocol normalization must land first.
- ONT-018 depends on ONT-014 (CLI argument hardening, Phase 5) for the flag-parsing
  convention; ONT-014 should be completed or developed in parallel on a separate branch.
- ONT-016 and ONT-018 are independent of each other and can be developed in parallel once
  their respective dependencies are satisfied.

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-010 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-010_Specification_Driven_Refactor_Documentation_And_Audit/` |
| ONT-009 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-009_Ontology_DecisionSpec_Migration/` |
| ONT-008 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-008_OntologyRules_Specification_Extraction/` |
| ONT-007 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-007_ontologyc_Compiler_Module_Split/` |
| ONT-006 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/` |
| ONT-005 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/` |
| ONT-004 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/` |
| ONT-003 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/` |
| ONT-002 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/` |
| ONT-001 | 2026-06-01 | PASS | `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/` |
