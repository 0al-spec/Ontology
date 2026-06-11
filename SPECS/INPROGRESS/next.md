# Current Task: ONT-033 File And Git Registry Transport

**Status:** ONT-033 selected and in progress.

## Description

Add a filesystem/git-backed registry transport for `publish`, `pull`, and `compat-check`
so the registry loop can be dogfooded without an HTTP registry service.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-033 |
| Title | File And Git Registry Transport |
| Phase | SpecGraph Value Loop Closure |
| Priority | P1 |
| Dependencies | ONT-018, ONT-026, ONT-031 |
| Parallelizable | yes |

## Value Loop Context

ONT-032 made generated SDK artifacts materially useful by adding first-class class fields
to ontology packages and generated TypeScript/Zod outputs. The next missing loop closure
is dogfooding registry flows without waiting for a reference HTTP service.

```text
ontologyc publish
-> local/git registry directory
-> ontologyc pull
-> ontologyc compat-check
-> governance-gated trusted promotion
```

## Current State

- `publish`, `pull`, and `compat-check` exist for the registry protocol path.
- Trusted publication already has a governance decision gate.
- The project still lacks a local registry transport that can be used as a reviewable
  git-backed artifact store.
- ONT-032 is archived and the generated SDK now includes field-bearing class shapes.

## Recommended Sequence

| Task ID | Title | Phase | Priority | Why Next |
|---------|-------|-------|----------|----------|
| ONT-033 | File And Git Registry Transport | SpecGraph Value Loop Closure | P1 | Dogfood publish/pull/compat-check without waiting for an HTTP registry service |
| ONT-034 | Induction Artifact Schemas And Draft Validation | SpecGraph Value Loop Closure | P1 | Make staged agent outputs deterministic and CI-checkable |
| ONT-035 | SpecGraph Proposal 0060 Minimal Consumer Slice | SpecGraph Value Loop Closure | P1 | Close the first consumer-side lock/ref/gap path |

## Sequencing Notes

- Keep ONT-033 scoped to filesystem/git transport; do not build an HTTP registry server yet.
- Preserve the existing governance gate for trusted publication.
- The local registry layout should be deterministic and reviewable in git.
- Use ONT-032 field-bearing examcalc output as a practical package for dogfooding.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-032 | Class field semantics and rich SDK generation | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | SpecGraph Ontology integration process PRD | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | TypeScript SDK smoke gate | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-032 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-032_Class_Field_Semantics_And_Rich_SDK_Generation/` |
| ONT-031 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
