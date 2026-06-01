# `examcalc` Golden Ontology Package

This folder is the canonical golden package for `edu.university.examcalc@0.1.0`.

The package materializes the exam-controlled calculator ontology from ONT-001 and is used as a stable regression input for later `ontologyc` and SpecGraph semantic reference validation work.

## Files

| File | Purpose |
|---|---|
| `domain-ontology-package.yaml` | Canonical `DomainOntologyPackage` for the exam-controlled calculator domain |
| `specgraph-requirement-binding.yaml` | Example SpecGraph project and requirement that import this package and reference `examcalc:*` symbols |
| `validation-manifest.yaml` | Required class, relation, policy, state machine, and binding coverage for the golden package |
| `validate-golden.rb` | Dependency-free Ruby validator for package coverage and semanticRef resolution |

## Required Domain Coverage

Core concepts:

- `Exam`
- `ExamPolicyProfile`
- `CalculatorFunction`
- `FunctionSet`
- `ExamModeSession`

Audit concepts:

- `PolicyViolation`
- `AuditLogEntry`

Core relations:

- `requires_policy`
- `allows`
- `denies`
- `includes_function`
- `enforces`
- `occurred_during`
- `records`

Core policies:

- `DenyByDefaultPolicy`
- `PolicyMustBeSigned`
- `PolicyMustBeDeviceVerifiable`
- `NoNetworkDuringExam`

## Validation

Run structural validation through the ONT-002 fixture harness:

```bash
ruby SPECS/ontology/fixtures/validate-fixtures.rb
```

Run golden package validation:

```bash
ruby SPECS/ontology/packages/examcalc/validate-golden.rb
```

Both commands parse YAML as inert data and do not execute ontology content.

