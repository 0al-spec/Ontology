# Next Tasks: GitHub Actions Maintenance Follow-Up

**Status:** ONT-028 archived with PASS

## Description

ONT-028 migrates Ontology workflows to the Node24-native cache action generation and
adds a local GitHub Actions maintenance guard modeled after the 0AL SpecPM policy.

## Current State

- Swift Quality uses `actions/cache@v5` for quality tool and SwiftPM caches.
- DocC uses `actions/cache@v5` for package/plugin caches.
- Temporary `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` env vars were removed.
- `tools/check-github-actions-node24.sh` is part of `tools/swift-quality.sh`.

## Potential Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| TBD | Broaden GitHub Actions Maintenance Policy | Quality | P3 | Optional follow-up if more official actions are added |

## Sequencing Notes

- Observe PR and post-merge CI logs for absence of Node20 cache action warnings.
- If Ontology adds more official `actions/*` references, extend
  `tools/check-github-actions-node24.sh` and `SPECS/ontology/ci-cache-policy.md`.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
