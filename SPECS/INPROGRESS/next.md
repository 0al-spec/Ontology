# Next Task: ONT-027 CI SwiftPM And Quality Tool Cache Optimization

**Status:** ONT-027 selected

## Description

ONT-024 defined the `OntologyGovernanceDecision` artifact contract, and ONT-025 added
deterministic CLI validation for that artifact. ONT-026 now wires that validation into
trusted registry publication.

The next quality slice reduces repeated CI setup/build time by caching stable SwiftPM,
DocC, and quality-tool artifacts instead of rebuilding or reinstalling them on every run.

## Selected Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-027 | CI SwiftPM And Quality Tool Cache Optimization | Quality | P2 | `SPECS/Workplan.md` |

## Execution Notes

- Use ISOInspector as precedent for cached tool install directories and SwiftPM cache keys.
- Start with standard `actions/cache@v4` cache layers rather than custom zip archives.
- Keep cache misses safe: workflows must still pass from a clean runner.
- Do not cache broad mutable paths unless keys include Swift version and package state.

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
