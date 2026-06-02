# Next Tasks: Governance Enforcement

**Status:** ONT-025 selected

## Description

ONT-024 has defined the `OntologyGovernanceDecision` artifact contract. ONT-025 now
turns that contract into deterministic compiler validation before registry enforcement.

## Recommended Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-025 | Governance Decision CLI Validation | Phase 9 | P1 | `SPECS/Workplan.md` |

## Upcoming Stack

| Order | Task ID | Title | Depends On |
|-------|---------|-------|------------|
| 1 | ONT-025 | Governance Decision CLI Validation | ONT-024 |
| 2 | ONT-026 | Registry Publish Governance Gate | ONT-025 |

## Sequencing Notes

- ONT-025 should validate the ONT-024 schema contract deterministically through
  `ontologyc validate-governance-decision`.
- ONT-025 should not change registry publication behavior yet.
- ONT-026 should integrate the validator into publish flow after ONT-025 is merged.
- The policy boundary to decide in ONT-026: governance may be mandatory for trusted/stable
  publication while draft/candidate publication remains possible only if explicitly documented.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | Ontology governance protocol | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | Golden intent repeatability harness | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |
| ONT-021 | Golden intent semantic expectations | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |
| ONT-021 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/` |
