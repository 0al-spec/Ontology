# Next Task: ONT-028 Node24 Cache Action Migration

**Status:** INPROGRESS

## Description

ONT-027 added standard GitHub Actions cache layers for Swift Quality and DocC, but
post-merge CI still reports GitHub annotations because `actions/cache@v4` targets the
Node20 action runtime. The temporary `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` environment
switch runs the action on Node24, but the annotation remains.

ONT-028 migrates cache steps to the Node24-native cache action release and removes the
temporary runtime-forcing environment variables.

## Current State

- Swift Quality has two `actions/cache@v4` steps.
- DocC has one `actions/cache@v4` step.
- Both workflows currently set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.
- Official `actions/cache@v5` runs on Node.js 24 and keeps the v4-compatible inputs
  used by this repository.

## Selected Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-028 | Node24 Cache Action Migration | Quality | P2 | ONT-027 post-merge CI annotation |

## Sequencing Notes

- Keep scope limited to cache action versioning and related documentation.
- Do not change cache key semantics, cache paths, or Swift quality behavior.
- Verify `tools/ci-cache-key.sh` still emits valid GitHub output.
- PR CI must show both Swift Quality and DocC green.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
