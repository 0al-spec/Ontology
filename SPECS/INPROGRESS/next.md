# Next Tasks: Planning State

**Status:** Updated after ONT-013 strict lint gate

## Description

The active implementation backlog is now small. ONT-013 has been completed by auditing the
current SwiftLint state and enabling strict lint mode. The next task should start from the
remaining Phase 5 semantic-governance backlog.

## Recommended Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-015 | Ontology Governing-Concept Review | 5 | P3 | `SPECS/Workplan.md` |

## Sequencing Notes

- ONT-013 is complete: the fresh audit found zero SwiftLint violations, force rules are
  already enforced as errors, and `strict: true` now makes warning regressions fail CI.
- ONT-015 remains the only active Workplan item.
- The ONT-018 `pull` contract follows the PRD: `sourceDigest` is the digest of the original
  YAML source, not the downloaded IR body. Integrity for pulled IR is transport-level for now.
- ONT-011, ONT-012, and ONT-014 are complete in `SPECS/Workplan.md` but do not have
  dedicated archive folders; create those only if strict Flow artifact parity is required.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-013 | Strict SwiftLint warning gate follow-up | `SPECS/Workplan.md` |
| ONT-014 | CLI help/argument parsing follow-up | `SPECS/Workplan.md` |
| ONT-012 | Competency-question regression test follow-up | `SPECS/Workplan.md` |
| ONT-011 | README and contributor guide follow-up | `SPECS/Workplan.md` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-018 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-018_CLI_Registry_Commands/` |
| ONT-017 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-017_Zod_JSON_Schema_Validators_For_ABox/` |
| ONT-016 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-016_Protocol_Interfaces_And_Compiler_Support/` |
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
