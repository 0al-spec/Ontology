# Current Task: ONT-030 TypeScript SDK Smoke Gate

**Status:** ONT-030 selected and in progress

## Description

Add a local and CI quality gate that compiles the generated examcalc TypeScript SDK with
`tsc --noEmit` and exercises the generated Zod schemas through a minimal smoke fixture.
This protects the generated SDK before richer class-field emitters are added.

## Task Metadata

| Field | Value |
|-------|-------|
| Task ID | ONT-030 |
| Title | TypeScript SDK Smoke Gate |
| Phase | SpecGraph Value Loop Closure |
| Priority | P0 |
| Dependencies | ONT-017, ONT-028 |
| Parallelizable | no |

## Value Loop Context

The current Ontology repository has strong compiler, governance, registry-client, and
authoring-protocol foundations, but the live product loop is still not fully closed:

```text
intent
-> induction artifacts
-> DomainOntologyPackage
-> ontologyc validation/compile
-> generated SDK/IR
-> SpecGraph semantic refs
-> lockfile/gaps
-> governance decision
-> publish/pull
```

ONT-030 addresses the `generated SDK/IR` segment by making generated TypeScript artifacts
compiler-checked rather than only regression-hash checked.

## Current State

- Generated TypeScript artifacts are regression-locked but not compiled with `tsc`.
- `SPECS/ontology/typescript-smoke/` exists, but it is not wired into local or CI quality gates.
- SpecGraph proposal 0060 exists in the sibling SpecGraph repository, but there is no
  executable consumer slice yet.
- Prompt-contract intermediate artifacts are documented, but most are not machine-validated.
- Registry HTTP commands exist; a filesystem/git registry transport does not yet exist.

## Recommended Sequence

| Task ID | Title | Phase | Priority | Why Next |
|---------|-------|-------|----------|----------|
| ONT-031 | SpecGraph Ontology Integration Process PRD | SpecGraph Value Loop Closure | P0 | Prevent Ontology work from drifting away from the SpecGraph consumer contract |
| ONT-032 | Class Field Semantics And Rich SDK Generation | SpecGraph Value Loop Closure | P0 | Make generated SDK materially useful after TS smoke exists |
| ONT-033 | File And Git Registry Transport | SpecGraph Value Loop Closure | P1 | Dogfood publish/pull/compat-check without waiting for an HTTP registry service |
| ONT-034 | Induction Artifact Schemas And Draft Validation | SpecGraph Value Loop Closure | P1 | Make staged agent outputs deterministic and CI-checkable |
| ONT-035 | SpecGraph Proposal 0060 Minimal Consumer Slice | SpecGraph Value Loop Closure | P1 | Close the first consumer-side lock/ref/gap path |

## Sequencing Notes

- Run ONT-030 before ONT-032 so TypeScript emitter changes have a compiler-backed safety net.
- Keep ONT-031 small and process-focused; it should define the bridge contract before richer
  Ontology features grow around assumptions.
- Treat ONT-035 as cross-repo coordination: Ontology tracks the dependency, but the executable
  consumer slice belongs in the sibling SpecGraph repository.
- Keep any model-selection benchmark work P3 until the core value loop has at least one
  end-to-end consumer path.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
