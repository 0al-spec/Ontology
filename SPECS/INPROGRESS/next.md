# Next Task: No Queued Workplan Task

**Status:** ONT-035 archived with PASS. `SPECS/Workplan.md` currently has no remaining
`Not Started`, `INPROGRESS`, or `PRD Ready` tasks.

## Recently Completed Value Loop

ONT-035 closed the first cross-repo consumer evidence loop for SpecGraph proposal 0060:

```text
Ontology-generated examcalc normalized IR
-> SpecGraph read-only import fixture
-> known refs resolve
-> missing ref emits ontology gap
-> Ontology docs link back to consumer evidence
```

SpecGraph evidence PR:

- <https://github.com/0al-spec/SpecGraph/pull/522>

## Current State

- Ontology still owns `DomainOntologyPackage`, compiler behavior, normalized IR, registry
  materialization, governance decisions, and trusted publish gates.
- SpecGraph now has an open PR for the first proposal 0060 consumer slice:
  `tools/ontology_import_policy.json`, `tools/ontology_imports.py`, checked-in examcalc
  normalized-IR fixture, focused tests, and proposal runtime markers.
- ONT-035 validation recorded both SpecGraph checks and Ontology checks.

## Recommended New Task Candidate

No Workplan task has been created yet. The strongest next candidate is:

| Candidate | Why |
|-----------|-----|
| `ontologyc validate-specgraph` adapter/report contract for SpecGraph | PR #522 proves fixture-driven consumption; the next stronger slice would invoke the real Ontology compiler contract from SpecGraph without allowing canonical graph mutation. |

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-035 | SpecGraph Proposal 0060 minimal consumer slice | `SPECS/ARCHIVE/ONT-035_SpecGraph_Proposal_0060_Minimal_Consumer_Slice/` |
| ONT-034 | Induction artifact schemas and draft validation | `SPECS/ARCHIVE/ONT-034_Induction_Artifact_Schemas_And_Draft_Validation/` |
| ONT-033 | File and git registry transport | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | Class field semantics and rich SDK generation | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | SpecGraph Ontology integration process PRD | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | TypeScript SDK smoke gate | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-035 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-035_SpecGraph_Proposal_0060_Minimal_Consumer_Slice/` |
| ONT-034 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-034_Induction_Artifact_Schemas_And_Draft_Validation/` |
| ONT-033 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
