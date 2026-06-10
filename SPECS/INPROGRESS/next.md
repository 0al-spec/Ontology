# Current Task: ONT-032 Class Field Semantics And Rich SDK Generation

**Status:** ONT-031 archived with PASS; ONT-032 is the next recommended task.

## Description

Add first-class class field semantics to `DomainOntologyPackage` and project them into
normalized IR, generated TypeScript interfaces, generated Zod schemas, JSON Schema, and
compatibility reports.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-032 |
| Title | Class Field Semantics And Rich SDK Generation |
| Phase | SpecGraph Value Loop Closure |
| Priority | P0 |
| Dependencies | ONT-030, ONT-031 |
| Parallelizable | no |

## Value Loop Context

ONT-030 added a TypeScript smoke gate for generated SDK artifacts. ONT-031 defined the
SpecGraph/Ontology bridge process and kept ontology semantics owned by Ontology. ONT-032
should now make generated SDK artifacts materially useful by adding first-class class
fields instead of only semantic references and protocol-required relation surfaces.

```text
DomainOntologyPackage fields
-> ontologyc validation
-> normalized IR
-> TypeScript interfaces
-> Zod schemas
-> JSON Schema helper
-> compatibility diff
-> TypeScript smoke gate
```

## Current State

- Generated TypeScript artifacts are regression-locked and compiled by `tools/typescript-smoke.sh`.
- The smoke package lives at `SPECS/ontology` and the fixture lives under
  `SPECS/ontology/typescript-smoke/`.
- ONT-031 now defines the SpecGraph bridge process and future consumer smoke criteria.
- The current generated SDK still carries mostly concept identity and protocol-required
  relation surfaces, not first-class class data fields.
- `DomainOntologyPackage` schema does not yet define a constrained `fields` section for classes.

## Recommended Sequence

| Task ID | Title | Phase | Priority | Why Next |
|---------|-------|-------|----------|----------|
| ONT-032 | Class Field Semantics And Rich SDK Generation | SpecGraph Value Loop Closure | P0 | Make generated SDK materially useful after TS smoke exists |
| ONT-033 | File And Git Registry Transport | SpecGraph Value Loop Closure | P1 | Dogfood publish/pull/compat-check without waiting for an HTTP registry service |
| ONT-034 | Induction Artifact Schemas And Draft Validation | SpecGraph Value Loop Closure | P1 | Make staged agent outputs deterministic and CI-checkable |
| ONT-035 | SpecGraph Proposal 0060 Minimal Consumer Slice | SpecGraph Value Loop Closure | P1 | Close the first consumer-side lock/ref/gap path |

## Sequencing Notes

- Keep ONT-032 focused on class fields only; relation behavior, ABox validation, and
  registry transport belong to separate tasks.
- The TypeScript smoke fixture should be expanded to cover at least one field-bearing class.
- Compatibility rules must be explicit before emitter changes are treated as stable.
- Preserve ONT-031's boundary: richer SDK types are Ontology outputs, not SpecGraph-owned
  ontology semantics.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-031 | SpecGraph Ontology integration process PRD | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | TypeScript SDK smoke gate | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-031 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/` |
| ONT-030 | 2026-06-11 | PASS | `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/` |
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
