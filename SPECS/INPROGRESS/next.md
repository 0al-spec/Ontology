# Next Tasks: Post-Governance Enforcement

**Status:** ONT-026 archived with PASS

## Description

ONT-024 defined the `OntologyGovernanceDecision` artifact contract, and ONT-025 added
deterministic CLI validation for that artifact. ONT-026 now wires that validation into
trusted registry publication.

## Current State

- `ontologyc publish` defaults to `--channel candidate`.
- `--channel trusted` requires an approved governance decision matching the package.
- Trusted publish rejects invalid or evidence-failing decisions before registry network calls.
- `pull` and `compat-check` remain unchanged.

## Potential Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| TBD | CI SwiftPM and DocC Cache Optimization | Quality | P2 | Follow-up from repeated quality/CI runs |

## Sequencing Notes

- The governance enforcement stack is complete through local schema, CLI validation, and
  trusted registry publish gating.
- A focused CI optimization slice could reduce repeated SwiftSyntax/DocC dependency
  materialization and build time.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | Ontology governance protocol | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
| ONT-023 | 2026-06-02 | PASS | `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/` |
