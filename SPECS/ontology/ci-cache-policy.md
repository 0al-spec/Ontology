# CI Cache Policy

Ontology CI uses cache layers to reduce repeated setup and SwiftPM dependency build time
without relaxing quality gates.

## Cache Layers

| Layer | Workflow | Path | Purpose |
|-------|----------|------|---------|
| Quality tools | Swift Quality | `~/.ontology-ci/tools` | Reuse `swiftformat` and `swiftlint` binaries. |
| Quality SwiftPM build | Swift Quality | `.build/ci-quality` | Reuse the stable scratch path used by `tools/swift-quality.sh` in CI. |
| DocC SwiftPM dependencies | Deploy DocC Documentation | `.build/repositories`, `.build/checkouts`, `.build/artifacts`, `.build/plugins` | Reuse package and plugin artifacts used by DocC generation. |

## GitHub Actions Runtime Boundary

Workflow cache steps use `actions/cache@v5`, the Node24-native cache action release.
Do not downgrade cache steps to `actions/cache@v4`; v4 targets the Node20 action runtime
and produces GitHub Actions deprecation annotations even when runtime forcing is enabled.

`tools/check-github-actions-node24.sh` guards maintained official `actions/*` references
against known older runtime generations.

## Key Inputs

`tools/ci-cache-key.sh` includes:

- runner OS and architecture;
- Swift compiler version;
- `Package.swift`;
- `Package.resolved`;
- `.swiftformat`;
- `.swiftlint.yml`;
- `tools/ci-cache-key.sh`;
- `tools/swift-quality.sh`;
- `tools/install-quality-tools.sh`;
- `tools/check-github-actions-node24.sh`;
- workflow files for DocC cache keys.

These inputs intentionally invalidate caches when package resolution, quality rules,
tool installation logic, workflow wiring, or Swift runtime version changes.

## Local Behavior

`tools/swift-quality.sh` remains scratch-isolated by default. Local runs still use a fresh
temporary directory and delete it on exit.

CI opts into a stable scratch path:

```bash
ONTOLOGY_SWIFT_SCRATCH_PATH=.build/ci-quality RUN_COVERAGE=1 bash tools/swift-quality.sh
```

This keeps local developer behavior clean while making CI cacheable.

## Safety Boundary

Cache misses must fall back to ordinary installation and build behavior. Caches are an
optimization only; they are not correctness inputs.

The workflows do not cache broad mutable system directories such as Homebrew cellar or
Xcode toolchains. If a cached binary is missing, stale, or unusable,
`tools/install-quality-tools.sh` falls back to the system tool or Homebrew installation.

## Residual Risk

SwiftPM build-product reuse can still be conservative: a restored cache may contain stale
objects, but SwiftPM is responsible for incremental invalidation against the checked-out
sources. If CI ever shows suspicious behavior, remove the relevant GitHub Actions cache or
bump the key inputs by changing `tools/ci-cache-key.sh`.

## Potential Next Step

If standard `actions/cache` does not materially reduce runtime, add an explicit zip
pack/unpack layer for prebuilt system-like artifacts. That should be a separate task with
before/after CI timing evidence.
