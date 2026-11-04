# `examcalc`: exam-specific calculator functions

Start with the [rewritten package, 0.2.0-draft.1](versions/0.2.0-draft.1/domain-ontology-package.yaml)
and the [two-exam walkthrough](../../../../Examples/examcalc/README.md). A teacher selects
a set of functions for an exam; a calculator applies that very set for that exam.
The walkthrough shows how to distinguish the human's result from the agent's model
and how to execute the same function on two exams with different allowances.

## Historical golden (0.1.0)

The package at this directory's original path is the frozen `edu.university.examcalc@0.1.0`
benchmark. Its signed profiles, audit policies and state machine come from the expanded
[golden intent](../../golden-intents/exam-controlled-calculator.intent.md). Existing
compiler, Hypercode and SpecGraph regression inputs continue to refer to that version.

## Files

| File | Purpose |
|---|---|
| `domain-ontology-package.yaml` | Frozen 0.1.0 golden, not the new design |
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

