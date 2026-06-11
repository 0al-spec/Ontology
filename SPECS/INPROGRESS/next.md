# Next Task: ONT-035 SpecGraph Proposal 0060 Minimal Consumer Slice

**Status:** ONT-035 selected in branch
`feature/ONT-035-specgraph-proposal-0060-consumer-slice`.

## Description

Coordinate the first SpecGraph-side implementation slice for proposal 0060: one
requirement or binding imports an Ontology package through a lockfile, resolves known refs,
and reports a gap for one unresolved ref.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-035 |
| Title | SpecGraph Proposal 0060 Minimal Consumer Slice |
| Phase | SpecGraph Value Loop Closure |
| Priority | P1 |
| Dependencies | ONT-031, ONT-033 |
| Parallelizable | no |

## Value Loop Context

ONT-034 made staged induction outputs deterministic and CI-checkable. The next missing
piece is the consumer side: SpecGraph should import a compiled/published Ontology package
instead of duplicating domain concepts locally.

```text
Ontology package / local registry
-> SpecGraph ontology import or lock metadata
-> known ConceptRef resolves
-> missing ConceptRef creates explicit OntologyGap
```

## Current State

- ONT-031 defines the integration process and boundary.
- ONT-033 provides a deterministic local `file://` registry transport.
- ONT-034 validates staged induction artifacts before package validation.
- The first SpecGraph consumer slice is cross-repo work: SpecGraph should own the
  lock/ref/gap artifacts and any implementation tests, while Ontology owns the producer
  package, compiler, registry materialization, and docs link-back.
- SpecGraph proposal `0060_external_ontology_import_plane.md` already names the intended
  runtime surfaces: `tools/ontology_import_policy.json`,
  `runs/ontology_package_index.json`, `runs/ontology_import_gap_index.json`,
  `runs/ontology_governance_evidence_index.json`,
  `runs/ontology_binding_preview.json`, and `runs/ontology_prompt_invocation_index.json`.

## Recommended Sequence

| Task ID | Title | Phase | Priority | Why Next |
|---------|-------|-------|----------|----------|
| ONT-035 | SpecGraph Proposal 0060 Minimal Consumer Slice | SpecGraph Value Loop Closure | P1 | Close the first consumer-side lock/ref/gap path |

## Sequencing Notes

- Keep Ontology as the producer/compiler boundary; SpecGraph should consume IR, lock, or
  registry materialization rather than re-modeling package semantics.
- Use examcalc as the minimal known-ref fixture unless proposal 0060 requires a different
  package.
- Include one unresolved ref to prove explicit `OntologyGap` behavior.
- Link back to Ontology docs once the consumer slice exists.
- Do not reuse SpecGraph `specs/nodes/SG-SPEC-0060.yaml` for this proposal: that node is
  currently about proposal/split readiness verdict checkpoints, not the external ontology
  import plane.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-034 | Induction artifact schemas and draft validation | `SPECS/ARCHIVE/ONT-034_Induction_Artifact_Schemas_And_Draft_Validation/` |
| ONT-033 | File and git registry transport | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | Class field semantics and rich SDK generation | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | SpecGraph Ontology integration process PRD | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | TypeScript SDK smoke gate | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-034 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-034_Induction_Artifact_Schemas_And_Draft_Validation/` |
| ONT-033 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-033_File_And_Git_Registry_Transport/` |
| ONT-032 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
