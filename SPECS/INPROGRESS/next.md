# Current Task: ONT-034 Induction Artifact Schemas And Draft Validation

**Status:** PRD Ready in `feature/ONT-034-induction-artifact-schemas`.

## Description

Add machine-readable schemas and validation for the core intermediate ontology-induction
artifacts produced before final `DomainOntologyPackage` YAML assembly.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-034 |
| Title | Induction Artifact Schemas And Draft Validation |
| Phase | SpecGraph Value Loop Closure |
| Priority | P1 |
| Dependencies | ONT-019, ONT-021, ONT-022, ONT-031 |
| PRD | `SPECS/INPROGRESS/ONT-034_Induction_Artifact_Schemas_And_Draft_Validation.md` |
| Parallelizable | yes |

## Value Loop Context

ONT-033 closed the local registry dogfood path: `publish`, `pull`, and `compat-check` can
now run against a deterministic `file://` registry directory. The next missing value-loop
piece is making pre-package induction artifacts deterministic and CI-checkable before they
become final `DomainOntologyPackage` YAML.

```text
prompt-contract outputs
-> draft artifact schemas
-> ontologyc validate-draft
-> deterministic report
-> final YAML assembly remains compiler/governance gated
```

## Current State

- ONT-019 documents the induction protocol and prompt contracts.
- ONT-021 and ONT-022 provide golden intent expectations and repeatability validation.
- The intermediate prompt-contract outputs are still Markdown-described artifacts, not
  machine-validated schema instances.
- ONT-033 now gives later publication flows a local registry for dogfooding.

## Selected Task

| Task ID | Title | Phase | Priority | Why Next |
|---------|-------|-------|----------|----------|
| ONT-034 | Induction Artifact Schemas And Draft Validation | SpecGraph Value Loop Closure | P1 | Make staged agent outputs deterministic and CI-checkable |
| ONT-035 | SpecGraph Proposal 0060 Minimal Consumer Slice | SpecGraph Value Loop Closure | P1 | Close the first consumer-side lock/ref/gap path |

ONT-034 is selected before ONT-035 because SpecGraph integration needs stable, reviewable
candidate artifacts before the consumer-side lock/ref/gap slice can rely on induction
outputs.

## Sequencing Notes

- Keep ONT-034 focused on artifact schemas and validation reports, not on approving ontology truth.
- `validate-draft` should validate staged outputs before YAML assembly, while final trust still
  comes from package compiler validation and governance decisions.
- Use the existing prompt-contract names from ONT-019 instead of inventing a new induction workflow.
- Preserve the SpecGraph/Ontology boundary from ONT-031.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-033 | File and git registry transport | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | Class field semantics and rich SDK generation | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | SpecGraph Ontology integration process PRD | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | TypeScript SDK smoke gate | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-033 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
