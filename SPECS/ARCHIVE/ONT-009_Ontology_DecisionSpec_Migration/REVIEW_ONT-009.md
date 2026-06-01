## REVIEW REPORT - ONT-009 Ontology DecisionSpec Migration

**Scope:** `origin/main..HEAD`  
**Files:** 16

### Summary Verdict
- [x] Approve
- [ ] Approve with comments
- [ ] Request changes
- [ ] Block

### Critical Issues

None.

### Secondary Issues

None.

### Architectural Notes

- The migration is correctly limited to classification branches. Output ordering, de-duplication, gap ordinal assignment, and report materialization remain in `OntologyCompiler`, where the surrounding orchestration context exists.
- Decision specs use `SpecificationCore.DecisionSpec` directly and reuse ONT-008 boolean specs where useful. No local `DecisionSpec` clone or macro dependency was introduced.
- CLI command classification remains out of scope, which is appropriate for this slice because `Sources/OntologyC/main.swift` is already a thin dispatcher and changing it would add risk without improving the targeted compiler decisions.

### Tests

Commands reviewed:

```bash
swift build
swift build --explicit-target-dependency-import-check error
swift build --target OntologyRulesTests
swift build --target OntologyCompilerTests
swift test --build-system swiftbuild --scratch-path /tmp/ont009-swiftbuild-*
find SPECS/ontology/packages/examcalc/generated SPECS/specgraph/semantic-validation/out \
  -type f | sort | xargs shasum -a 256 | shasum -a 256
```

Results:

```text
swift test --build-system swiftbuild --scratch-path /tmp/ont009-swiftbuild-*: 22 tests, 0 failures
generated output hash: 1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19
manual CLI regression: PASS
no-Ruby audit: PASS
```

### Residual Risk

- Cached local `.build` XCTest runner still intermittently hangs in dyld before executing tests. A fresh scratch-path SwiftPM run executed the full suite successfully and is recorded in `ONT-009_Validation_Report.md`.

### Next Steps

- FOLLOW-UP skipped: no actionable review findings.
- Continue with ONT-010 final documentation and audit.
