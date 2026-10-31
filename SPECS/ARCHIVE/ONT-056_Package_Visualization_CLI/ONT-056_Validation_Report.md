# ONT-056 Validation Report

**Date** 2026-10-31

**Verdict** PASS for local macOS implementation, real rendering and repository gates.
Hosted macOS/Linux checks and external review remain PR work.

## Implementation

The standalone `ontologyviz` product projects the existing compiler-normalized
package into deterministic DOT and invokes local Graphviz for SVG/PNG.
The library reuses package validation. Typed identities distinguish classes and
protocols with the same spelling. External placeholders preserve import identity
and version. Relations include declared cardinality and oneOf alternatives;
policies and lifecycle transitions are visible.

## Checks

- `swift build --explicit-target-dependency-import-check error` passed.
- Focused `PackageDiagramTests|OntologyVizCLITests` passed, 13 tests.
- `RUN_COVERAGE=1 bash tools/swift-quality.sh` passed, 179 tests across 45 rule
  tests and 134 compiler/CLI tests. SwiftFormat and strict SwiftLint passed.
- The quality report's test-bundle line coverage was 90.46%; PackageDiagram
  was 96.12%. Spawned CLI executable coverage is not represented by this report.
- `bash tools/portable-contract-smoke.sh` passed. Eight package generated-output
  baselines match; structural fixture checks include expected negative controls.
- `bash tools/typescript-smoke.sh` passed, including SDK typecheck and smoke.
- `swift package generate-documentation --target OntologyCompiler --warnings-as-errors`
  passed using the external scratch/cache/output paths.
- Real Graphviz 16.1.0 rendered the worked example and examcalc to SVG and PNG.
  Both raster images were visually inspected. The compact example is readable;
  examcalc's full graph needs zoom and is more practical as SVG.
- Real-renderer regression checks parse SVG XML, inspect expected graph labels,
  and verify PNG signature plus positive width/height. Both single formats,
  option order, explicit renderer path and paths with spaces are covered.
- Missing/failed rendering preserves existing output; a simulated PNG failure
  after SVG success leaves all three prior artifacts intact. Invalid packages
  create no output. Output cannot overwrite its input package.
- Quoting preserves literal Unicode, quotes, backslashes and newlines. Optional
  fields, missing cardinality bounds, oneOf alternatives and kind collisions
  have projection regressions.
- `git diff --check` passed.

## Local environment

All Swift build, test, documentation and temporary outputs were routed to the
verified TB5 paths for `.worktrees/Ontology-visualization`. SwiftPM used the TB5
cache. A temporary project `node_modules` symlink routed the TypeScript dependency
installation to TB5 and was removed by the validation wrapper. The documentation
sample's DOT/SVG/PNG files were copied from the verified render output into the
repository intentionally.

Graphviz was installed through Homebrew for this task, including Homebrew-managed
dependency installations/upgrades. Two dependency post-install hooks were retried
successfully. No renderer binary is bundled in this PR.

## Boundaries

The visualizer uses the compiler's current package validation. Imported symbols
remain explicitly external, with declarations unloaded. DOT is deterministic;
image layout and raster pixels depend on Graphviz/fonts. PNG and SVG use the same
DOT projection with separate local render operations. Publication writes are
atomic per file. Existing unselected image formats remain in the output directory.
Linux execution will be established by the PR matrix, which installs Graphviz.
