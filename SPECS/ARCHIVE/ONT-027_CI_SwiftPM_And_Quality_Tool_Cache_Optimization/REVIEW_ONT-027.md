# REVIEW ONT-027: CI SwiftPM And Quality Tool Cache Optimization

**Date:** 2026-06-03
**Reviewer:** Codex
**Verdict:** PASS

## Findings

No remaining actionable correctness issues found.

## Fixed During Review

- `tools/ci-cache-key.sh` initially allowed local `swift --version` stderr to leak into
  GitHub Actions output. Fixed by suppressing stderr and emitting only `name=value` lines.
- `tools/install-quality-tools.sh` initially trusted any executable cached tool. Fixed by
  refreshing cached tools whose version command fails.

## Review Scope

- Reviewed GitHub Actions cache restore ordering.
- Reviewed GitHub output compatibility of `tools/ci-cache-key.sh`.
- Reviewed quality tool cache miss and invalid-cache behavior.
- Reviewed stable scratch behavior for `tools/swift-quality.sh`.
- Reviewed cache policy documentation and invalidation boundaries.

## Validation Reviewed

- `bash tools/ci-cache-key.sh`
- `bash tools/install-quality-tools.sh --check`
- Empty quality-tool cache population test
- Invalid cached `swiftlint` refresh test
- Repeated `ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=0 bash tools/swift-quality.sh`
- `ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=1 bash tools/swift-quality.sh`
- `git diff --check`

## Residual Risk

- GitHub Actions workflow syntax requires PR CI as the authoritative validation because
  `actionlint` is not installed locally.
- Standard `actions/cache` may not reduce runtime enough on the first run after key changes.
  Timing should be evaluated from PR and post-merge CI runs.

## Follow-Up

No immediate FOLLOW-UP task required. Potential next step remains a separate zip-pack
system build cache only if measured CI timings stay too high.
