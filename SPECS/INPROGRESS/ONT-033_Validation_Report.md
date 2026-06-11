# ONT-033 Validation Report

**Task:** ONT-033 File And Git Registry Transport
**Date:** 2026-06-11
**Verdict:** PASS

## Summary

ONT-033 adds `file://` registry support to the existing `publish`, `pull`, and
`compat-check` flows. HTTP(S) behavior remains routed through `RegistryClient`, while local
registries write deterministic normalized IR artifacts plus reviewable metadata files under
`ontologies/` and `channels/`.

The local registry is git-backed by convention: `ontologyc` writes files only, and users can
place the registry root inside a git repository for review and commits.

## Changed Areas

| Area | Result |
|------|--------|
| Registry URL/location parsing | PASS |
| Local registry artifact layout | PASS |
| `publish` file transport | PASS |
| `pull` file transport | PASS |
| `compat-check` file transport | PASS |
| Trusted publish governance gate before local writes | PASS |
| HTTP registry behavior preservation | PASS |
| CLI file-registry round trip | PASS |
| Documentation | PASS |

## Validation Commands

```bash
swift test --filter CompilerArgumentTypesTests
```

Result: PASS. `RegistryBaseURL` accepts HTTP(S) URLs and `file://` locations while rejecting
unsupported schemes and raw relative strings.

```bash
swift test --filter LocalRegistryTransportTests
```

Result: PASS. Local `publish -> pull -> compatCheckPackage` round trip works and trusted
publication rejects before writing when governance evidence is missing.

```bash
swift test --filter RegistryClientTests
```

Result: PASS. Existing HTTP client behavior remains covered.

```bash
swift test --filter RegistryPublishGovernanceGateTests
```

Result: PASS. Governance gate behavior remains intact.

```bash
swift test --filter OntologyCFileRegistryTests
```

Result: PASS. CLI `publish -> pull -> compat-check` works through a `file://` registry URL.

```bash
bash tools/swift-quality.sh
```

Result: PASS. SwiftFormat, SwiftLint, build, and all `89` Swift tests pass.

```bash
tmp_registry=$(mktemp -d /tmp/ontology-registry.XXXXXX)
tmp_pull=$(mktemp -d /tmp/ontology-pull.XXXXXX)
tmp_report=$(mktemp /tmp/ontology-compat.XXXXXX.yaml)
registry_url="file://${tmp_registry}"
swift run ontologyc publish SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --registry "$registry_url"
swift run ontologyc pull edu.university.examcalc@0.1.0 --registry "$registry_url" --out "$tmp_pull"
swift run ontologyc compat-check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --against edu.university.examcalc@0.1.0 --registry "$registry_url" --out "$tmp_report"
test -f "$tmp_registry/ontologies/edu.university.examcalc/0.1.0/ontology.normalized.json"
test -f "$tmp_registry/channels/candidate/edu.university.examcalc/0.1.0.yaml"
test -f "$tmp_pull/edu-university-examcalc-0.1.0.normalized.json"
rg -n "compatible: true" "$tmp_report"
```

Result: PASS. Manual CLI dogfood produced registry artifacts, pulled IR, and a compatible
report.

```bash
bash tools/typescript-smoke.sh
```

Result: PASS. Generated TypeScript smoke remains clean.

```bash
git diff --check
```

Result: PASS. No whitespace or patch-format issues.

## Acceptance Mapping

| Acceptance Criteria | Evidence |
|---------------------|----------|
| Registry location accepts `https://...` and `file://...` | `CompilerArgumentTypesTests` |
| Existing HTTP registry behavior remains unchanged | `RegistryClientTests`, `RegistryPublishGovernanceGateTests` |
| Local `publish` writes deterministic IR and metadata | `LocalRegistryTransportTests`, manual CLI round trip |
| Local `pull` resolves exact package refs | `LocalRegistryTransportTests`, `OntologyCFileRegistryTests` |
| Local `compat-check` compares against published IR | `LocalRegistryTransportTests`, manual CLI round trip |
| Trusted local publication rejects before writing without governance | `LocalRegistryTransportTests.testTrustedLocalPublishRejectsBeforeWritingWithoutDecision` |
| Docs explain git-backed registry workflow without git automation | `README.md`, `SPECS/ontology/ontologyc.md` |
| Full gates pass | `bash tools/swift-quality.sh`, `bash tools/typescript-smoke.sh`, `git diff --check` |

## Residual Risk

- Local registries use exact package references only; dependency resolution and semver ranges
  remain future work.
- Channel indexes are review metadata, not a channel-aware resolution API. `pull` and
  `compat-check` still resolve by exact `<id>@<version>`.
- The local registry does not perform signatures or content-addressed integrity checks.

## Potential Next Step

Run ONT-034 to make staged ontology-induction artifacts machine-validated before final
`DomainOntologyPackage` YAML assembly.
