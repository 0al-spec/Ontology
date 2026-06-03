# Next Tasks: CI Cache Follow-Up

**Status:** ONT-027 archived with PASS

## Description

ONT-024 defined the `OntologyGovernanceDecision` artifact contract, and ONT-025 added
deterministic CLI validation for that artifact. ONT-026 now wires that validation into
trusted registry publication.

ONT-027 adds standard GitHub Actions cache layers for stable SwiftPM, DocC, and
quality-tool artifacts.

## Current State

- Swift Quality restores cached `~/.ontology-ci/tools` and `.build/ci-quality`.
- DocC restores package/checkouts/artifacts/plugin cache paths before generation.
- `tools/swift-quality.sh` remains temporary-scratch by default locally.
- CI opts into `ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality`.

## Potential Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| TBD | Zip-Pack System Build Cache | Quality | P3 | Follow-up if ONT-027 timings are still too slow |

## Sequencing Notes

- First observe PR and post-merge CI timings with the standard cache layers.
- Add custom zip-pack/unpack only if `actions/cache` does not materially reduce repeated
  SwiftSyntax/DocC build time.
- Keep any future zip cache keyed by Swift version, runner OS/arch, package resolution, and
  tool/workflow scripts.

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
