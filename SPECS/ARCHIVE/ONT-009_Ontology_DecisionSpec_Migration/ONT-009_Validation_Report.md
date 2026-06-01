# ONT-009 Validation Report

**Task:** ONT-009 - Ontology DecisionSpec Migration  
**Date:** 2026-06-01  
**Branch:** `feature/ONT-009-ontology-decisionspec-migration`  
**Verdict:** PASS

## Summary

ONT-009 migrates current classification branches into typed `SpecificationCore.DecisionSpec` implementations under `OntologyRules`. The compiler now delegates relation range shape, concept ref resolution, SpecGraph resolved/gap classification, and compatibility breaking-change classification to decision specs without changing observable behavior.

## Quality Gates

| Gate | Command | Result |
|---|---|---|
| Build | `swift build` | PASS |
| Explicit dependency imports | `swift build --explicit-target-dependency-import-check error` | PASS |
| Rule test target compile | `swift build --target OntologyRulesTests` | PASS |
| Compiler test target compile | `swift build --target OntologyCompilerTests` | PASS |
| Full Swift test suite | `swift test --build-system swiftbuild --scratch-path /tmp/ont009-swiftbuild-*` | PASS, 22 tests, 0 failures |
| Flow file gates | `test -f README.md && test -f SPECS/Workplan.md` | PASS |
| Generated artifact hash | `find SPECS/ontology/packages/examcalc/generated SPECS/specgraph/semantic-validation/out -type f \| sort \| xargs shasum -a 256 \| shasum -a 256` | PASS |
| Manual CLI regression | `ontologyc check/compile/validate-specgraph/diff` against ONT-006 baseline fixtures | PASS |
| No-Ruby audit | `git diff --name-only --diff-filter=ACMRT origin/main..HEAD \| xargs rg -n "ruby|\\.rb"` | PASS, no matches |

## Test Details

`swift test --build-system swiftbuild --scratch-path /tmp/ont009-swiftbuild-*` completed successfully:

- `OntologyRulesTests`: 17 tests, 0 failures.
- `OntologyCompilerTests`: 5 tests, 0 failures.

The cached local `.build` XCTest runner hung in dyld before executing tests, matching the local runner issue observed during ONT-008. A fresh scratch-path SwiftPM build executed the same suite successfully and is the recorded passing gate.

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

- Decision specs are total classifiers that return explicit invalid/unresolved/compatible results instead of `nil`; this matches the current compiler need for deterministic branch outcomes.
- SpecGraph gap object materialization still lives in compiler orchestration because gap IDs depend on sorted/de-duplicated output order.
