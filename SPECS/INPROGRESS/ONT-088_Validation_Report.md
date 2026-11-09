# ONT-088 validation report

- Before implementation, new tests reproduced missing inherited protocol
  fields in generated interfaces and Zod schemas, a missing-source warning
  gap for direct imports, and a supplied package's absent protocol being
  accepted. The corresponding regressions now pass.
- The local Swift quality gate (`RUN_COVERAGE=1 tools/swift-quality.sh`):
  292 tests, SwiftFormat and SwiftLint passed; aggregate line coverage 90.33%.
  SwiftPM outputs and caches were routed to the verified TB5 volume.
- `tools/typescript-smoke.sh` passed with the task compiler and dependencies
  on TB5. The new transitive-import consumer compiles under strict TypeScript
  and exercises Zod acceptance, retention and rejection of protocol fields.
- `tools/portable-contract-smoke.sh` passed with the task compiler. Eight
  package baselines and the existing advisory, instance and provenance smoke
  scenarios passed. Only warning comments changed in the tracked ExamCalc
  TypeScript baseline; its data schemas and normalized IR remain unchanged.
- Tests cover package-local alias scopes, missing/wrong-version sources,
  missing symbols, incompatible fields and source-attributed diagnostics.
  No network resolution is performed.

The result is locally validated. Hosted CI and independent PR review are
separate; the change has not yet been released or installed downstream.
