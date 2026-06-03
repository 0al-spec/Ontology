# ONT-027 Validation Report

**Task:** ONT-027 CI SwiftPM And Quality Tool Cache Optimization
**Date:** 2026-06-03
**Verdict:** PASS

## Scope Validated

- CI cache key script emits valid GitHub Actions output lines.
- Quality tool installer can reuse cached binaries and populate an empty cache directory.
- `tools/swift-quality.sh` still defaults to a temporary scratch path locally.
- CI can opt into `.build/ci-quality` via `ONTOLOGY_SWIFT_SCRATCH_PATH`.
- Repeated stable-scratch quality runs reuse the populated SwiftPM build graph.
- Swift Quality and DocC workflows restore cache layers before expensive setup/build steps.

## Commands

```bash
bash tools/ci-cache-key.sh
bash tools/install-quality-tools.sh --check
tmp=$(mktemp -d) && ONTOLOGY_CI_TOOLS_DIR="$tmp/tools" bash tools/install-quality-tools.sh && find "$tmp" -type f -maxdepth 3 -print && rm -rf "$tmp"
tmp=$(mktemp -d) && mkdir -p "$tmp/tools" && printf '#!/bin/sh\nexit 99\n' > "$tmp/tools/swiftlint" && chmod +x "$tmp/tools/swiftlint" && ONTOLOGY_CI_TOOLS_DIR="$tmp/tools" bash tools/install-quality-tools.sh && test -x "$tmp/tools/swiftformat" && test -x "$tmp/tools/swiftlint" && rm -rf "$tmp"
ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=0 bash tools/swift-quality.sh
ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=0 bash tools/swift-quality.sh
ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=1 bash tools/swift-quality.sh
git diff --check
```

## Results

| Gate | Result |
|------|--------|
| Cache key helper | PASS, valid `name=value` output |
| Quality tool check | PASS, found local SwiftFormat and SwiftLint |
| Empty tool cache population | PASS, copied both binaries into temp cache dir |
| Invalid cached tool refresh | PASS, replaced unusable cached `swiftlint` |
| Stable scratch quality, first run | PASS, 79 tests |
| Stable scratch quality, repeated run | PASS, 79 tests; build phases reused cache (`0.66s`, `0.31s`) |
| Stable scratch quality with coverage | PASS, 79 tests; coverage report emitted |
| SwiftFormat | PASS, 0 files require formatting |
| SwiftLint | PASS, 0 violations |
| Whitespace check | PASS |

## Local Limits

- `actionlint` is not installed locally, so workflow syntax is ultimately validated by
  GitHub Actions on the PR.
- The first stable-scratch run remains expensive because it populates the cache. The expected
  improvement appears on later runs after cache restore.

## Notes

- `tools/ci-cache-key.sh` initially leaked `swift --version` stderr into output on this
  machine. The script now suppresses stderr and emits only GitHub-output-safe lines.
- The implementation intentionally starts with `actions/cache@v4`; custom zip-pack/unpack
  remains a follow-up if standard cache behavior does not reduce CI time enough.
