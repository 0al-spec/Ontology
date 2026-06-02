# Next Tasks: Repeatability Harness

**Status:** Updated after ONT-021 archive

## Description

ONT-021 is archived with PASS. The golden intent set now has minimum semantic expectation
files that future repeatability checks can consume.

## Recommended Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-022 | Golden Intent Repeatability Harness | 9 | P1 | `SPECS/Workplan.md` |

## Sequencing Notes

- ONT-021 is archived with PASS.
- Expectations must remain minimum semantic criteria, not byte-exact ontology truth.
- ONT-022 should consume these expectations in a repeatability harness.
- ONT-023 should define the governance protocol for approving candidate outputs.
- ONT-020 Hypercode IR Import Spike is already merged on `main`; its PRD still lives in
  `SPECS/INPROGRESS/` until a later planning cleanup/archive pass.
- ONT-019 is archived with PASS.
- The final YAML artifact remains `DomainOntologyPackage`; ONT-019 documents how an
  ontology-authoring agent gets there from product/domain intent.
- ONT-015 is complete: `ExamPolicyProfile` is the only `central: true` class in the
  canonical examcalc package, example mirror, compatibility fixture, and generated IR.
- ONT-013 is complete: the fresh audit found zero SwiftLint violations, force rules are
  already enforced as errors, and `strict: true` now makes warning regressions fail CI.
- The ONT-018 `pull` contract follows the PRD: `sourceDigest` is the digest of the original
  YAML source, not the downloaded IR body. Integrity for pulled IR is transport-level for now.
- ONT-011, ONT-012, and ONT-014 are complete in `SPECS/Workplan.md` but do not have
  dedicated archive folders; create those only if strict Flow artifact parity is required.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-021 | Golden intent semantic expectations | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |
| ONT-020 | Hypercode IR import bridge | `SPECS/INPROGRESS/ONT-020_Hypercode_IR_Import_Spike.md` |
| ONT-019 | Ontology induction protocol and prompt contracts | `SPECS/ARCHIVE/ONT-019_SpecGraph_Ontology_Induction_Protocol_And_Prompt_Contracts/` |
| ONT-015 | Governing-concept central marker follow-up | `SPECS/Workplan.md` |
| ONT-013 | Strict SwiftLint warning gate follow-up | `SPECS/Workplan.md` |
| ONT-014 | CLI help/argument parsing follow-up | `SPECS/Workplan.md` |
| ONT-012 | Competency-question regression test follow-up | `SPECS/Workplan.md` |
| ONT-011 | README and contributor guide follow-up | `SPECS/Workplan.md` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-021 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |
| ONT-019 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-019_SpecGraph_Ontology_Induction_Protocol_And_Prompt_Contracts/` |
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
