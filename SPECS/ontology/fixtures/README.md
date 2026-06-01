# Domain Ontology Package Fixtures

This directory contains the ONT-002 validation corpus for `DomainOntologyPackage`.

## Fixture Groups

| Group | Expected Result | Purpose |
|---|---|---|
| `valid/*.yaml` | valid | Minimal packages that exercise required metadata, classes, relations, policies, and state machines |
| `invalid/missing-metadata.yaml` | invalid | Verifies required package metadata, especially `metadata.version` |
| `invalid/invalid-inheritance.yaml` | invalid | Verifies `extends` is a single scalar reference, not a multiple-inheritance list |
| `invalid/unknown-relation-ref.yaml` | invalid | Verifies relation `domain`/`range` references resolve to known classes or imported aliases |
| `invalid/unsafe-executable-looking-yaml.yaml` | invalid | Verifies YAML is treated as inert data and executable-looking hooks/expressions are rejected |

The golden `SPECS/ontology/examples/examcalc.ontology.yaml` package is also included in the valid validation set.

## Validation Command

```bash
ruby SPECS/ontology/fixtures/validate-fixtures.rb
```

The harness uses Ruby stdlib only. It is intentionally small and temporary; ONT-004 `ontologyc check` should replace it with the compiler validator while preserving this fixture corpus as regression coverage.

