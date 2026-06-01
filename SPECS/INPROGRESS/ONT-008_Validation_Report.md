# ONT-008 Validation Report

**Task:** ONT-008 - OntologyRules Specification Extraction  
**Date:** 2026-06-01  
**Branch:** `feature/ONT-008-ontologyrules-specification-extraction`  
**Verdict:** PASS

## Summary

ONT-008 extracts current compiler validation predicates into named `SpecificationCore` specifications under `OntologyRules` and wires `OntologyCompiler` through those specs without changing CLI behavior or generated artifacts.

## Quality Gates

| Gate | Command | Result |
|---|---|---|
| Build | `swift build` | PASS |
| Explicit dependency imports | `swift build --explicit-target-dependency-import-check error` | PASS |
| Full Swift test suite | `swift test --build-system swiftbuild` | PASS, 16 tests, 0 failures |
| Rule test target compile | `swift build --target OntologyRulesTests` | PASS |
| Flow file gates | `test -f README.md && test -f SPECS/Workplan.md` | PASS |
| Generated artifact hash | `find SPECS/ontology/packages/examcalc/generated SPECS/specgraph/semantic-validation/out -type f \| sort \| xargs shasum -a 256 \| shasum -a 256` | PASS |
| Manual CLI regression | `ontologyc check/compile/validate-specgraph/diff` against ONT-006 baseline fixtures | PASS |

## Test Details

`swift test --build-system swiftbuild` completed successfully:

- `OntologyRulesTests`: 11 tests, 0 failures.
- `OntologyCompilerTests`: 5 tests, 0 failures.

The default native SwiftPM test runner was also tried, but hung while loading/running the local XCTest bundle in this environment. The `swiftbuild` build system completed the same test suite successfully and is the recorded passing test gate.

## Behavioral Regression Checks

Manual CLI regression covered:

- canonical `examcalc` package check;
- invalid fixtures for inheritance, metadata, unknown relation reference, and unsafe YAML;
- TypeScript/IR compile output byte comparison against committed generated artifacts;
- SpecGraph validation for resolved and missing semantic bindings;
- compatibility diff output byte comparison.

Observed command summaries:

```text
ontologyc check: PASS SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
ontologyc compile: PASS <temp-output>
ontologyc validate-specgraph: PASS ... resolved=25 gaps=0
ontologyc validate-specgraph: PASS ... resolved=2 gaps=1
ontologyc diff: PASS <temp-output>/compatibility-report.yaml
```

## Hashes

Combined generated output hash remains unchanged:

```text
1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19
```

Baseline IR hash remains covered by `OntologyCompilerTests.testCompileProducesBaselineGeneratedArtifacts`:

```text
bb626c69bb0989ab6e7e5605e0dde73dee9e220b6b203d584924e22a6e20936d
```

## Residual Risk

- ONT-008 intentionally extracts boolean predicates only. Typed `DecisionSpec` migration remains deferred to ONT-009.
- The specs preserve current edge behavior, including permissive relation `oneOf` shape handling before reference validation reports empty/invalid references.
