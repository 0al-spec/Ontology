# ONT-026 Validation Report

**Task:** ONT-026 Registry Publish Governance Gate
**Date:** 2026-06-03
**Verdict:** PASS

## Scope Validated

- `ontologyc publish` accepts `--channel candidate|trusted`.
- Trusted publication requires `--decision`.
- Trusted publication rejects missing, non-approved, package-mismatched, and evidence-failing
  governance decisions before registry network calls.
- Candidate publication rejects `--golden-report` without `--decision` so evidence flags are
  not silently ignored.
- Candidate publication remains the default behavior.
- `pull` and `compat-check` code paths were not changed.

## Commands

```bash
swift test --filter RegistryClientTests
swift test --filter GovernanceDecisionCLITests
swift test --filter RegistryPublishGovernanceGateTests
bash tools/swift-quality.sh
git diff --check
```

## Results

| Gate | Result |
|------|--------|
| Registry client regression tests | PASS, 15 tests before test split |
| Governance decision CLI tests | PASS, 3 tests |
| Registry publish governance gate tests | PASS, 4 tests |
| SwiftFormat | PASS, 0 files require formatting |
| SwiftLint | PASS, 0 violations |
| Swift build | PASS |
| Swift tests | PASS, 79 tests |
| Whitespace check | PASS |

## Notes

- The first full quality run failed on SwiftLint hygiene (`function_parameter_count`,
  `file_length`, `type_body_length`).
- The implementation was adjusted by moving publish-gate arguments into
  `RegistryPublishRequest` and splitting governance publish tests into a dedicated test file.
- Full quality passed after that correction.
- Review follow-up added coverage for `--golden-report` without `--decision`.
