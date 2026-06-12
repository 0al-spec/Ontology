# Next Task: ONT-036 `ontologyc` Adapter Report Artifact

**Status:** SELECTED / INPROGRESS.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-036 |
| Name | `ontologyc` Adapter Report Artifact |
| Priority | P0 |
| Dependencies | ONT-035 |
| Branch | `codex/ont-036-ontologyc-adapter-report` |
| PRD | `SPECS/INPROGRESS/ONT-036_ontologyc_Adapter_Report_Artifact.md` |
| Source proposal | SpecGraph `docs/proposals/0060_external_ontology_import_plane.md` |
| Consumer contract | SpecGraph `docs/ontologyc_adapter_report_contract.md` |

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
- SpecGraph has merged the first proposal 0060 consumer slice and the follow-up
  adapter/report contract slice.
- ONT-035 validation recorded both SpecGraph checks and Ontology checks.

## Selected Scope

ONT-036 turns the proposal candidate into an Ontology-owned compiler artifact:

```text
SpecGraph binding + normalized IR
-> ontologyc validate-specgraph
-> concept-refs.yaml / ontology.lock.yaml / ontology-gaps.yaml
-> ontologyc-adapter-report.yaml
```

The report is evidence for SpecGraph and future SpecSpace review surfaces. It is
not canonical SpecGraph state, not an accepted import lock, and not permission
for `ontologyc` to mutate `specs/nodes/*.yaml`.

## Non-Goals

- No prompt-agent invocation boundary.
- No SpecSpace UI or mutation action.
- No Platform/Docker packaging.
- No canonical SpecGraph import lock writeback.
- No change to `DomainOntologyPackage` source schema.

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
