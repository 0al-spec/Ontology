# ONT-027: CI SwiftPM And Quality Tool Cache Optimization

**Status:** Archived PASS
**Date:** 2026-06-03
**Priority:** P2
**Dependencies:** ONT-026

## Summary

Add deterministic cache layers to Ontology CI so repeated quality and DocC runs reuse
stable SwiftPM dependencies, plugin artifacts, and quality tool binaries when inputs have
not changed.

## Problem

CI runs repeatedly spend time reinstalling quality tools and rebuilding heavy SwiftPM
dependencies such as SwiftSyntax and DocC plugin packages. The current quality script
builds in a temporary scratch path, so a default `.build` cache would not cover the
actual build/test artifacts used by `tools/swift-quality.sh`.

## Goals

- Add explicit CI cache keys tied to Swift version, package resolution, and quality config.
- Cache SwiftFormat and SwiftLint binaries outside Homebrew when available.
- Let `tools/swift-quality.sh` use a stable CI scratch path so SwiftPM artifacts can be cached.
- Restore SwiftPM repository/checkouts/artifacts for DocC generation.
- Keep cache misses safe and deterministic.
- Document cache boundaries and invalidation inputs.

## Non-Goals

- No custom zip-pack/unpack cache archive yet.
- No caching of broad mutable system directories such as Homebrew cellar.
- No change to local default behavior of `tools/swift-quality.sh`.
- No relaxation of format, lint, build, coverage, or DocC gates.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | CI cache key helper | `tools/ci-cache-key.sh` |
| D2 | Cached quality tool installer | `tools/install-quality-tools.sh` |
| D3 | Cache-aware quality script support | `tools/swift-quality.sh` |
| D4 | Swift Quality workflow cache layers | `.github/workflows/swift-quality.yml` |
| D5 | DocC workflow cache layers | `.github/workflows/documentation.yml` |
| D6 | CI cache policy documentation | `SPECS/ontology/ci-cache-policy.md` |
| D7 | Validation report | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/ONT-027_Validation_Report.md` |

## Proposed Design

### Cache Key Helper

`tools/ci-cache-key.sh` emits stable key fragments:

- Swift compiler version;
- macOS runner OS/arch where available;
- hash of `Package.swift`, `Package.resolved`, `.swiftformat`, `.swiftlint.yml`,
  `tools/swift-quality.sh`, and `tools/install-quality-tools.sh`.

### Quality Tool Cache

Use `ONTOLOGY_CI_TOOLS_DIR` as the preferred tool cache root. The install script should:

1. use cached `swiftformat`/`swiftlint` binaries when present;
2. fall back to Homebrew install when missing;
3. copy resolved binaries into the cache directory for future runs;
4. prepend the cache directory to `GITHUB_PATH` in GitHub Actions.

### SwiftPM Cache

Use a stable CI scratch path:

```bash
ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality bash tools/swift-quality.sh
```

Cache path candidates:

- `.build/ci-quality`
- `.build/repositories`
- `.build/checkouts`
- `.build/artifacts`

DocC should restore the same repository/checkouts/artifacts cache before generation.

## Acceptance Criteria

- [ ] Swift Quality workflow restores quality-tool and SwiftPM cache layers.
- [ ] DocC workflow restores SwiftPM/plugin cache layers before generating docs.
- [ ] `tools/swift-quality.sh` remains scratch-isolated by default locally.
- [ ] CI can opt into a stable scratch path with `ONTOLOGY_SWIFT_SCRATCH_PATH`.
- [ ] Cache misses fall back to existing install/build behavior.
- [ ] Cache policy docs explain keys, invalidation, and residual risk.
- [ ] Local validations pass.

## Validation Plan

- `bash tools/install-quality-tools.sh --check`
- `ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=0 bash tools/swift-quality.sh`
- `git diff --check`
- Workflow syntax inspection
- Full `bash tools/swift-quality.sh` if runtime is acceptable after implementation

## Potential Follow-Up

- Add custom zip-pack/unpack for prebuilt system-like SwiftPM artifacts if standard
  `actions/cache` does not reduce CI time enough.
