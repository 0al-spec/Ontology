# ONT-003 Validation Report

**Task:** ONT-003 - `examcalc` Golden Ontology Package  
**Date:** 2026-06-01  
**Verdict:** PASS

## Scope Validated

- Canonical `edu.university.examcalc@0.1.0` package materialized under `SPECS/ontology/packages/examcalc/`.
- Required domain classes, audit concepts, relations, policies, and `ExamModeSessionState` coverage checked through `validation-manifest.yaml`.
- SpecGraph requirement binding imports the canonical package and resolves all `examcalc:*` references.
- Canonical package is included in the ONT-002 fixture harness expected-valid set.

## Commands

```bash
test -f README.md
test -f SPECS/Workplan.md
diff -u SPECS/ontology/examples/examcalc.ontology.yaml SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
ruby SPECS/ontology/fixtures/validate-fixtures.rb
ruby SPECS/ontology/packages/examcalc/validate-golden.rb
```

## Results

| Gate | Result | Notes |
|---|---|---|
| Flow configured test gate | PASS | `README.md` exists |
| Flow configured lint gate | PASS | `SPECS/Workplan.md` exists |
| Example/package parity | PASS | Canonical package currently matches the ONT-001 example byte-for-byte |
| ONT-002 fixture harness | PASS | 7/7 expected outcomes matched |
| ONT-003 golden validator | PASS | Required symbols present and 25/25 semantic refs resolved |

Fixture harness output:

```text
PASS valid   SPECS/ontology/examples/examcalc.ontology.yaml
PASS valid   SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
PASS valid   SPECS/ontology/fixtures/valid/minimal-domain-ontology-package.yaml
PASS invalid SPECS/ontology/fixtures/invalid/invalid-inheritance.yaml
PASS invalid SPECS/ontology/fixtures/invalid/missing-metadata.yaml
PASS invalid SPECS/ontology/fixtures/invalid/unknown-relation-ref.yaml
PASS invalid SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml
Validated 7 fixtures: 7 passed, 0 failed
```

Golden validator output:

```text
PASS package metadata edu.university.examcalc@0.1.0
PASS classes 13/13
PASS audit concepts 2/2
PASS relations 8/8
PASS policies 4/4
PASS state machine ExamModeSessionState
PASS semantic refs 25/25 resolved
Validated examcalc golden package: PASS
```

## Acceptance Mapping

| Acceptance Criterion | Evidence |
|---|---|
| Ontology defines `Exam`, `ExamPolicyProfile`, `CalculatorFunction`, `FunctionSet`, `ExamModeSession`, and audit concepts. | `validation-manifest.yaml` + `validate-golden.rb` class and audit checks |
| Relations and policies match the PRD. | `validate-golden.rb` relation, policy, policy target, and state machine checks |
| Example SpecGraph requirement resolves all `examcalc:*` semantic refs. | `specgraph-requirement-binding.yaml` + `validate-golden.rb` semanticRef resolution |

## Residual Risks

- The canonical package intentionally duplicates the ONT-001 example for now. Future changes should either update both deliberately or retire the example path after downstream references move to `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`.
- The golden validator is a deterministic oracle for package coverage and semanticRef resolution, not a replacement for ONT-004 `ontologyc`.

