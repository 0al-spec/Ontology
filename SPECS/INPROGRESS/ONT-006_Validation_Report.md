# ONT-006 Validation Report

**Task:** ONT-006 - SpecificationCore Baseline and Regression Harness  
**Date:** 2026-06-01  
**Verdict:** PASS

## Scope

ONT-006 implemented the first behavior-preserving slice of the specification-driven `ontologyc` refactor:

- added Swift regression tests for the current `ontologyc` CLI behavior;
- added deterministic generated-output comparisons against the committed baseline;
- added `SpecificationCore` 1.0.0 as a SwiftPM dependency;
- added an `OntologyRules` target that imports and uses `SpecificationCore`;
- avoided production compiler behavior changes.

## Changed Areas

| Area | Files |
|---|---|
| SwiftPM manifest | `Package.swift`, `Package.resolved` |
| Rules scaffold | `Sources/OntologyRules/OntologyRuleScaffold.swift` |
| Rules tests | `Tests/OntologyRulesTests/OntologyRulesScaffoldTests.swift` |
| Compiler regression tests | `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift` |
| Planning artifacts | `SPECS/Workplan.md`, `SPECS/INPROGRESS/next.md`, `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md` |

## Dependency Audit

| Dependency | Version | Revision | License Evidence |
|---|---:|---|---|
| `SpecificationCore` | 1.0.0 | `af5b0642282541ae36baffd1328a5dd7c5e61146` | `.build/checkouts/SpecificationCore/LICENSE` says MIT License |
| `swift-syntax` | 510.0.3 | `2bc86522d115234d1f588efe2bcb4ce4be8f8b82` | Transitive dependency of `SpecificationCore` |
| `Yams` | 6.2.2 | `a27b21e0c81c5bf42049b897a62aaf387e80f279` | Existing dependency retained |

## Validation Commands

### Swift Build

```bash
swift build
```

Result: PASS.

### Swift Tests

```bash
swift test
```

Result: PASS.

Observed test summary:

```text
Executed 6 tests, with 0 failures (0 unexpected)
```

Coverage introduced by ONT-006:

- `ontologyc check` passes the canonical `examcalc` package.
- All ONT-002 invalid fixtures fail.
- `ontologyc compile` output matches committed generated artifacts byte-for-byte.
- `ontology.normalized.json` keeps hash `bb626c69bb0989ab6e7e5605e0dde73dee9e220b6b203d584924e22a6e20936d`.
- Valid SpecGraph fixture remains `resolved=25 gaps=0`.
- Missing-ref SpecGraph fixture remains `resolved=2 gaps=1`.
- Compatibility diff output matches the committed baseline.
- `OntologyRules` target imports and uses `SpecificationCore`.

### Flow File Gates

```bash
test -f README.md
test -f SPECS/Workplan.md
```

Result: PASS.

### Generated Output Hash

```bash
find SPECS/ontology/packages/examcalc/generated SPECS/specgraph/semantic-validation/out \
  -type f | sort | xargs shasum -a 256 | shasum -a 256
```

Result:

```text
1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19  -
```

This matches the PRD baseline.

### Ruby Audit

No new Ruby files or Ruby-based test tooling were added. Existing legacy Ruby validators remain untouched and are not used by the ONT-006 Swift test path.

## Acceptance Criteria Mapping

| Acceptance Criterion | Evidence | Result |
|---|---|---|
| Swift regression tests cover current CLI behavior. | `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift`; `swift test` PASS | PASS |
| Valid and invalid fixture behavior is locked. | `testCheckPassesCanonicalExamcalcPackage`, `testInvalidFixturesFail` | PASS |
| Generated outputs are hash-verified and byte-stable. | Compile test compares generated files byte-for-byte; generated output hash unchanged | PASS |
| `SpecificationCore` 1.0.0 is pinned. | `Package.resolved` records version and revision | PASS |
| `OntologyRules` target builds and imports `SpecificationCore`. | `OntologyRuleScaffold.swift`; `OntologyRulesScaffoldTests` PASS | PASS |
| No production compiler behavior changes are introduced. | Production `Sources/OntologyC/main.swift` unchanged; regression tests pass | PASS |
| New implementation and tests are Swift-native. | New files are Swift; no new Ruby tooling | PASS |

## Residual Risks

| Risk | Status | Follow-up |
|---|---|---|
| `OntologyRules` currently contains only a scaffold spec. | Accepted for ONT-006 baseline slice. | ONT-008 extracts real validation specifications. |
| `ontologyc` implementation remains monolithic. | Accepted for ONT-006. | ONT-007 performs the module split. |
| `SpecificationCore` adds SwiftPM build surface through `swift-syntax`. | Accepted by dependency decision. | ONT-010 documents final build/dependency audit. |
