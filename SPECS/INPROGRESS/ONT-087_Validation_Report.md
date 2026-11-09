# ONT-087 validation report

- Before the change, regression tests reproduced `check` and snapshot checking
  accepting cyclic and conflicting inheritance and omitting missing-source
  warnings. The tests pass with semantic validation enabled.
- `tools/swift-quality.sh` with coverage: 284 Swift tests passed, SwiftFormat and
  SwiftLint passed, aggregate line coverage 90.10% (including dependencies).
- Portable contract smoke passed on the local macOS Swift build: all eight
  tracked package outputs remained byte-identical, and existing staged advice,
  package, instance and provenance smoke controls passed.
- Added index-snapshot and strict CLI controls for cycles, including JSON and
  unavailable-source warnings. The source-attribution tests exercise a broken
  imported ancestor and a cycle spanning two explicit package sources.
- No network resolution is performed. Unavailable ancestor sources and
  imported protocol obligations remain warnings, not verified facts.

CI and review on the task PR are independent checks; this report records local
results only. The result has not been released or installed as a runtime.
