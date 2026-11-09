# ONT-084 validation

Verdict: PASS locally on 2026-11-09; hosted CI and external review are separate.

- `tools/swift-quality.sh` passed SwiftFormat, SwiftLint, explicit-import build,
  full Swift tests and coverage. The reported overall line coverage was 89.59%.
- `DiagramFoundationModelsTests` checks legacy identity, unchanged old output,
  duplicate, modified, missing and wrong-version models, deterministic order,
  and a transitive dependency using a rebased alias. CLI tests check profile
  paths, refusal to overwrite the model and rejection in image modes.
- The standalone Viewer passed 53 unit tests and the TypeScript/Vite build.
  Chromium passed 30 browser tests, including model inspection, a modified
  catalog and a symlink retarget; the latter was rerun after input-shape hardening.
- Tests used a disposable TB5 build and source snapshot. The local Viewer and
  catalog are not yet connected to the deployed SpecSpace or SpecGraph graph.
- Catalog digests are recorded by the producer; the Viewer does not authenticate
  an arbitrary user-provided projection. DOT/image catalog rendering is not part
  of this JSON Viewer slice and fails explicitly.
