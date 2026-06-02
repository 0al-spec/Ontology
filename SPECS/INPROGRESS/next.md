# Next Tasks: Governance Enforcement

**Status:** ONT-025 archived with PASS

## Description

ONT-024 defined the `OntologyGovernanceDecision` artifact contract, and ONT-025 added
deterministic CLI validation for that artifact. The remaining stack item wires this
validation into trusted registry publication.

## Recommended Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-026 | Registry Publish Governance Gate | Phase 9 | P1 | `SPECS/Workplan.md` |

## Sequencing Notes

- ONT-026 should integrate `validateGovernanceDecision` into `ontologyc publish`.
- The policy boundary to decide in ONT-026: governance may be mandatory for trusted/stable
  publication while draft/candidate publication remains possible only if explicitly documented.
- Existing `pull` and `compat-check` behavior should remain unchanged.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | Ontology governance protocol | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | Golden intent repeatability harness | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
| ONT-022 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/` |
