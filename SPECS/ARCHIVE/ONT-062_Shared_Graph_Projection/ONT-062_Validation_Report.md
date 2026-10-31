# ONT-062 Validation Report

**Date:** 2026-10-31

**Verdict:** PASS locally; hosted CI and independent review are pending.

## Result

`OntologyCompiler.diagramProjection` supplies one versioned declaration graph
used by the existing DOT renderer and exposed as JSON through `diagramJSON` and
`ontologyviz --format json`. Root and explicitly selected imported declarations
retain source package identity, logical YAML pointer and digests. OneOf remains
one relation with alternative ranges. Existing profile selection and import
binding are unchanged.

`sourceDigest` agrees with the existing compiled IR. `sourceByteDigest` captures
the exact bytes read for the projection, including a UTF-8 BOM. They are
different for BOM input because the existing compiler strips the BOM from its
loaded text. Both source parsing and the byte digest use one input snapshot.

## Checks

- Full `RUN_COVERAGE=1 bash tools/swift-quality.sh`: SwiftFormat, SwiftLint,
  explicit-dependency build and all tests PASS; test-bundle line coverage
  90.58%. Spawned CLI process coverage is outside that report.
- Focused projection, import selection and visualization tests PASS, including
  BOM parity with compiled IR, invalid UTF-8, aliases, grouped alternatives,
  input overwrite protection, JSON without Graphviz and real SVG/PNG rendering.
- Existing example and motivation profile DOT outputs match their tracked
  golden files byte-for-byte.
- Real motivation-core/events-core profile exported 11 visible classes and 19
  relation declarations. An independent PyYAML/SHA-256 check resolved all 49
  visible declaration and field pointers against the exact source bytes.
- TypeScript SDK typecheck/smoke PASS. The portable contract gate regenerated
  and compared all eight existing package baselines and passed its positive and
  negative structural controls.
- OntologyCompiler and OntologyRules DocC build PASS; `git diff --check` PASS.
- A read-only, offline `swift:6.3.3-bookworm` Linux/arm64 container probe
  confirmed that Foundation strips a UTF-8 BOM the same way as the projection
  loader. This is a decoding probe, not a Linux project build or full test run.
- Builds, caches, generated diagrams and DocC outputs were routed to the
  verified per-worktree TB5 paths. Swift 6.4 defaults to Swift Build, so the
  unchanged quality wrapper was run with a local shim selecting its expected
  native build system and external SwiftPM cache. A first coverage report found
  an unrelated non-instrumented binary in a mixed scratch directory; the clean
  isolated quality scratch passed. The native option is deprecated by Swift.

## Limits

No UI, YAML rewrite, editor state, agent integration, full Linux project run or
SpecSpace/SpecGraph change is claimed. A successful graph is not a diagnostics
report, an instance graph or evidence that manual policies are satisfied.
