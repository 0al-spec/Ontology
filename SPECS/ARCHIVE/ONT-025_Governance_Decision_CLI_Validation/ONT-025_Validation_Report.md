# ONT-025 Validation Report

**Task:** Governance Decision CLI Validation  
**Date:** 2026-06-03  
**Verdict:** PASS

## Scope

ONT-025 adds deterministic validation for `OntologyGovernanceDecision` YAML through
`OntologyCompiler` and `ontologyc validate-governance-decision`. Registry publication is
not changed in this task.

## Deliverable Verification

| Deliverable | Path | Status |
|-------------|------|--------|
| Compiler governance validation API | `Sources/OntologyCompiler/GovernanceDecisionValidation.swift` | PASS |
| CLI command and help text | `Sources/OntologyC/main.swift`, `Sources/OntologyC/CLIArguments.swift` | PASS |
| Unit tests | `Tests/OntologyCompilerTests/GovernanceDecisionValidationTests.swift` | PASS |
| CLI regression tests | `Tests/OntologyCompilerTests/GovernanceDecisionCLITests.swift`, `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift` | PASS |
| Documentation updates | `SPECS/ontology/ontologyc.md`, `SPECS/ontology/governance-protocol.md` | PASS |

## Acceptance Criteria

| Criterion | Result |
|-----------|--------|
| Compiler API validates the ONT-024 decision contract without executing YAML | PASS |
| CLI accepts decision path and optional package/golden-report/out flags | PASS |
| Invalid actor authority, missing evidence, malformed kind/version, and package mismatch fail deterministically | PASS |
| Approved decision plus failing golden report fails | PASS |
| Valid decision plus matching package exits zero and can emit a report | PASS |
| Unit and CLI tests cover pass/fail behavior | PASS |
| Registry publish behavior remains unchanged | PASS |

## Commands

```bash
swift test --filter GovernanceDecisionValidationTests
swift test --filter OntologyCRegressionTests/testValidateGovernanceDecisionCliWritesReportAndRejectsInvalidActor
bash tools/swift-quality.sh
```

## Results

- `swift test --filter GovernanceDecisionValidationTests`: PASS, 4 tests.
- `swift test --filter OntologyCRegressionTests/testValidateGovernanceDecisionCliWritesReportAndRejectsInvalidActor`: PASS, 1 test.
- Initial `bash tools/swift-quality.sh`: FAIL due lint thresholds after adding the command.
  - Fixed by moving CLI parsing helpers from `main.swift` to `CLIArguments.swift`.
  - Fixed by moving governance CLI regression coverage to `GovernanceDecisionCLITests`.
- Final `bash tools/swift-quality.sh`: PASS.
  - SwiftFormat: 0/50 files require formatting.
  - SwiftLint: 0 violations.
  - Build: PASS.
  - Tests: 71 passed, 0 failed.

## Follow-Up

- ONT-026 should integrate governance decision validation into trusted registry publish flow.
- CI runtime could be optimized separately by improving SwiftPM cache reuse, but that is
  outside ONT-025.
