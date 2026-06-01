# SpecGraph Semantic Validation Fixtures

This directory contains ONT-005 fixtures and generated outputs for validating SpecGraph semantic references against the canonical `examcalc` ontology package.

## Commands

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out SPECS/specgraph/semantic-validation/out/valid

swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out SPECS/specgraph/semantic-validation/out/missing

swift run ontologyc diff \
  --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml \
  --out SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

## Expected Results

| Fixture | Expected Result |
|---|---|
| `valid-semantic-binding.yaml` | All `examcalc:*` refs resolve to canonical `ConceptRef` records and no gaps are emitted |
| `missing-ref-semantic-binding.yaml` | `examcalc:CASFunction` emits one `OntologyGap` |
| `examcalc-0.2.0-breaking.yaml` | Compatibility report marks the relation range change as breaking |

