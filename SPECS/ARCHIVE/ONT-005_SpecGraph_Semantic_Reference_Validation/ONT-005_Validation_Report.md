# ONT-005 Validation Report

**Task:** ONT-005 - SpecGraph Semantic Reference Validation  
**Date:** 2026-06-01  
**Verdict:** PASS

## Scope Validated

- `ontologyc validate-specgraph` resolves SpecGraph `examcalc:*` refs against compiled ontology IR.
- Known refs emit canonical URI-bearing `ConceptRef` records.
- Missing refs emit `OntologyGap` artifacts.
- `OntologyLockfile` output pins ontology id, namespace, version, digest, and aliases.
- `ontologyc diff` emits an `OntologyCompatibilityReport` and classifies relation range changes as breaking.

## Commands

```bash
test -f README.md
test -f SPECS/Workplan.md
swift build
.build/debug/ontologyc validate-specgraph SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json --out SPECS/specgraph/semantic-validation/out/valid
.build/debug/ontologyc validate-specgraph SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json --out SPECS/specgraph/semantic-validation/out/missing
.build/debug/ontologyc diff --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml --out SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
grep -q 'gaps: \\[\\]' SPECS/specgraph/semantic-validation/out/valid/ontology-gaps.yaml
grep -q 'missingConcept: examcalc:CASFunction' SPECS/specgraph/semantic-validation/out/missing/ontology-gaps.yaml
grep -q 'compatible: false' SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
grep -q 'change relation range examcalc:allows' SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

## Results

| Gate | Result | Notes |
|---|---|---|
| Flow configured test gate | PASS | `README.md` exists |
| Flow configured lint gate | PASS | `SPECS/Workplan.md` exists |
| Swift build | PASS | `swift build` completed |
| Valid semantic binding | PASS | `resolved=25 gaps=0` |
| Missing-ref semantic binding | PASS | `resolved=2 gaps=1` |
| OntologyGap creation | PASS | Gap contains `examcalc:CASFunction` |
| Lockfile output | PASS | Output includes digest and aliases |
| Compatibility diff | PASS | Report has `compatible: false` and `change relation range examcalc:allows` |
| Determinism | PASS | Repeated output tree hash: `5a06ee9502e19ddaa627f44208d20c38b38afb6d0bd4080e5ced7c0f749f25b8` |

Command output:

```text
ontologyc validate-specgraph: PASS SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml resolved=25 gaps=0
ontologyc validate-specgraph: PASS SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml resolved=2 gaps=1
ontologyc diff: PASS SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

## Generated Artifacts

| Artifact | Path |
|---|---|
| Valid concept refs | `SPECS/specgraph/semantic-validation/out/valid/concept-refs.yaml` |
| Valid lockfile | `SPECS/specgraph/semantic-validation/out/valid/ontology.lock.yaml` |
| Valid gap set | `SPECS/specgraph/semantic-validation/out/valid/ontology-gaps.yaml` |
| Missing-ref concept refs | `SPECS/specgraph/semantic-validation/out/missing/concept-refs.yaml` |
| Missing-ref lockfile | `SPECS/specgraph/semantic-validation/out/missing/ontology.lock.yaml` |
| Missing-ref gap set | `SPECS/specgraph/semantic-validation/out/missing/ontology-gaps.yaml` |
| Compatibility report | `SPECS/specgraph/semantic-validation/out/compatibility-report.yaml` |

## Acceptance Mapping

| Acceptance Criterion | Evidence |
|---|---|
| Known ontology refs resolve to canonical URIs. | `valid/concept-refs.yaml`, `resolved=25 gaps=0` |
| Missing refs create `OntologyGap`. | `missing/ontology-gaps.yaml` contains `examcalc:CASFunction` |
| Compatibility reports classify breaking ontology changes. | `compatibility-report.yaml` contains `compatible: false` and `change relation range examcalc:allows` |

## Residual Risks

- The SpecGraph parser is intentionally broad and recursive; it is not a full SpecGraph schema validator.
- Compatibility diff currently covers symbol add/remove and relation domain/range changes, which is enough for the Workplan acceptance criteria but not the full future compatibility matrix.
- Registry resolution is local-file based; network registry integration remains future work.

