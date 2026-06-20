# ONT-040 Validation Report

**Task:** `ONT-040`  
**Ontology:** `DomainOntologyPackage` compiler contract  
**Input:** `SPECS/INPROGRESS/ONT-040_Model_Applicability_And_Structural_Change_Classification.md`  
**Verdict:** `PASS`

## Summary

| Check | Result | Notes |
|---|---|---|
| Schema validation | PASS | `domain-ontology-package.schema.yaml` accepts optional `spec.modelApplicability`. |
| Compiler validation | PASS | `ontologyc check` validates applicability scope arrays, assumptions, invalidation triggers, and layer values. |
| Normalized IR | PASS | `modelApplicability` is preserved as deterministic inert review metadata. |
| Compatibility | PASS | Reports include review-only `changeClassification` buckets. |
| Security | PASS | No execution, publication, mutation, or runtime enforcement path was added. |
| Regression suite | PASS | `swift test` passed. |
| Quality gate | PASS | `tools/swift-quality.sh` passed. |

## Test Mapping

| Test ID | Description | Evidence | Result |
|---|---|---|---|
| T-001 | Optional `modelApplicability` validates and normalizes. | `ModelApplicabilityPackageValidationTests.testModelApplicabilityValidatesAndNormalizes` | PASS |
| T-002 | Invalid applicability shape and layer values emit deterministic diagnostics. | `ModelApplicabilityPackageValidationTests.testModelApplicabilityRejectsInvalidShapeAndLayer` | PASS |
| T-003 | Compatibility reports classify structural changes. | `CompatibilityLayerDiffTests.testCompatibilityReportAddsReviewOnlyChangeClassification` | PASS |
| T-004 | Compatibility reports classify annotation/layer changes. | `CompatibilityLayerDiffTests.testCompatibilityReportAddsReviewOnlyChangeClassification` | PASS |
| T-005 | Compatibility reports classify applicability assumption / invalidation trigger drift. | `CompatibilityLayerDiffTests.testCompatibilityReportAddsReviewOnlyChangeClassification` | PASS |
| T-006 | Existing CLI compatibility report baseline is updated. | `SPECS/specgraph/semantic-validation/out/compatibility-report.yaml` | PASS |

## Commands

```bash
swift test --filter ModelApplicabilityPackageValidationTests
swift test --filter CompatibilityLayerDiffTests
.build/debug/ontologyc diff --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml --out SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
swift test
bash tools/swift-quality.sh
git diff --check
```

## Diagnostics

| Code | Severity | Path | Message | Hint |
|---|---|---|---|---|
| `modelApplicability.scope.array` | error | `spec.modelApplicability.appliesTo.domains` | Applicability scope field must be an array. | |
| `ontology.layer.invalid` | error | `spec.modelApplicability.assumptions[0].layer` | Ontology layer value is not supported. | |

## Generated / Updated Artifacts

| Artifact | Present | Notes |
|---|---|---|
| `ontology.normalized.json` | N/A | Existing package outputs are unchanged because existing packages do not declare `modelApplicability`. |
| `compatibility-report.yaml` | yes | Baseline now includes `changes.changeClassification`. |

## Security Notes

- `modelApplicability` is data-only review metadata.
- The compiler does not infer applicability from prose.
- The compiler does not grant runtime authority, publication trust, package writes, or SpecGraph mutations from this profile.

## Follow-Up

- SpecGraph should import `modelApplicability` and `changeClassification` into package index / gap-diff review artifacts.
- SpecSpace should expose applicability assumptions and invalidation triggers in the Ontology Workbench after SpecGraph publishes the artifacts.
