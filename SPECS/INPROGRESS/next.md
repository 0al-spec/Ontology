# Next Tasks: Phase 5 Follow-Up

**Status:** Updated after ONT-014

## Description

PR #14 implemented most of the Phase 6/7 surface that was previously listed here as pending:
protocol interfaces, Zod schema output, and registry CLI commands. The ONT-017 follow-up
added the remaining JSON Schema helper and smoke fixture. The ONT-014 follow-up hardens
CLI help and argument parsing, so the next fresh implementation task should move to the
remaining Phase 5 backlog.

## Recommended Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-012 | Automated Competency-Question Resolution Test | 5 | P1 | `SPECS/Workplan.md` |

## Sequencing Notes

- ONT-012 is the highest-priority remaining Phase 5 item and closes the unimplemented
  competency-question validation coverage from the ontology PRD.
- ONT-011, ONT-013, and ONT-015 remain useful but lower-priority follow-ups.
- ONT-014 is implemented in code but still needs formal archive materialization if the Flow
  lifecycle is enforced strictly.
- ONT-016, ONT-017, and ONT-018 are implemented in code but still need formal archive materialization
  if the Flow lifecycle is enforced strictly.
- The ONT-018 `pull` contract follows the PRD: `sourceDigest` is the digest of the original
  YAML source, not the downloaded IR body. Integrity for pulled IR is transport-level for now.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-018 | PR #14 | `SPECS/INPROGRESS/ONT-018_CLI_Registry_Commands.md` |
| ONT-017 | PR #14 + JSON Schema follow-up | `SPECS/INPROGRESS/ONT-017_Zod_JSON_Schema_Validators_For_ABox.md` |
| ONT-016 | PR #14 | `SPECS/INPROGRESS/ONT-016_Protocol_Interfaces_And_Compiler_Support.md` |
| ONT-014 | CLI help/argument parsing follow-up | `SPECS/Workplan.md` |

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
