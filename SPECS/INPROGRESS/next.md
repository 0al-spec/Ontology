# Next Tasks: Governance Enforcement

**Status:** ONT-024 selected

## Description

ONT-023 defined ontology governance as a normative protocol. The next three tasks turn
that protocol into an enforceable release path in stacked PRs:

1. define the governance decision artifact schema;
2. validate decision artifacts with `ontologyc`;
3. require valid approval evidence during trusted registry publication.

## Current Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-024 | Governance Decision YAML Schema | Phase 9 | P1 | `SPECS/Workplan.md` |

## Upcoming Stack

| Order | Task ID | Title | Depends On |
|-------|---------|-------|------------|
| 1 | ONT-024 | Governance Decision YAML Schema | ONT-023 |
| 2 | ONT-025 | Governance Decision CLI Validation | ONT-024 |
| 3 | ONT-026 | Registry Publish Governance Gate | ONT-025 |

## Sequencing Notes

- ONT-024 must not add compiler enforcement. It defines the artifact contract, examples,
  and documentation links that later compiler work will consume.
- ONT-025 should implement deterministic validation for the same schema and should not
  change registry publication behavior yet.
- ONT-026 should integrate the validator into publish flow after ONT-025 is merged.
- The policy boundary to decide in ONT-026: governance may be mandatory for trusted/stable
  publication while draft/candidate publication remains possible only if explicitly documented.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-023 | Ontology governance protocol | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | Golden intent repeatability harness | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |
| ONT-021 | Golden intent semantic expectations | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |
| ONT-020 | Hypercode IR import bridge | `SPECS/INPROGRESS/ONT-020_Hypercode_IR_Import_Spike.md` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-023 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |
| ONT-021 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |
| ONT-019 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-019_SpecGraph_Ontology_Induction_Protocol_And_Prompt_Contracts/` |
