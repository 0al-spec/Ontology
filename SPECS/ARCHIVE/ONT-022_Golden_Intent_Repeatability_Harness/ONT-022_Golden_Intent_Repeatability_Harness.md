# ONT-022: Golden Intent Repeatability Harness

**Status:** Archived PASS
**Created:** 2026-06-02
**Source:** `SPECS/Workplan.md`

## Summary

Add a deterministic `ontologyc` harness that compares one golden intent semantic expectation
file against one candidate `DomainOntologyPackage` YAML artifact. The harness is a regression
surface for ontology induction outputs: it checks minimum semantic criteria without treating
any single draft as byte-exact truth.

## Scope

### In Scope

- A CLI command for validating a candidate package against a golden intent expectation.
- YAML parsing for `GoldenIntentSemanticExpectation`.
- Candidate package validation through existing compiler loading and package validation.
- Deterministic pass/fail checks for concepts, governing concept centrality, relations,
  policies, lifecycle states, and forbidden core concepts.
- A stable YAML report suitable for CI artifacts and later corpus automation.
- Regression tests for pass and fail cases.
- Documentation that explains the harness boundary.

### Out of Scope

- LLM execution or prompt orchestration.
- Governance approval/rejection/merge decisions.
- Byte-exact comparison to expected ontology YAML.
- Full competency-question semantic proof. Competency question expectations are surfaced as
  deterministic manual-review anchors until candidate artifacts carry first-class competency
  question data.
- Expanding `DomainOntologyPackage` schema.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Harness API | `Sources/OntologyCompiler/GoldenIntentValidation.swift` | Exposes candidate-vs-expectation validation and stable report output |
| D2 | CLI command | `Sources/OntologyC/main.swift` | Adds `validate-golden-intent <expectation.yaml> --candidate <package.yaml> [--out <report.yaml>]` |
| D3 | Regression tests | `Tests/OntologyCompilerTests/GoldenIntentValidationTests.swift` and CLI regression tests | Covers passing and failing candidate outcomes |
| D4 | Documentation | `SPECS/ontology/golden-intents/README.md` and root docs if needed | Explains minimum semantic criteria and report interpretation |
| D5 | Validation report | `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/ONT-022_Validation_Report.md` | Records local checks and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Command MUST accept one expectation file and one candidate package file. | `ontologyc validate-golden-intent <expectation.yaml> --candidate <package.yaml>` works. | CLI regression test |
| FR-002 | Command MUST validate the candidate package before semantic comparison. | Package loader/validator errors fail the harness. | Unit or CLI test |
| FR-003 | Harness MUST check governing concept presence and `central: true` when required. | Missing or non-central governing concept fails. | Unit test |
| FR-004 | Harness MUST check required concepts grouped by expectation category. | Missing concepts are reported with category and id. | Unit test |
| FR-005 | Harness MUST check required relation id/domain/range. | Scalar and `oneOf` ranges are handled deterministically. | Unit test |
| FR-006 | Harness MUST check required policies and enforceability groups. | Missing policy or mismatched enforceability fails. | Unit test |
| FR-007 | Harness MUST check lifecycle state machine states. | Missing state machine or states fail. | Unit test |
| FR-008 | Harness MUST check forbidden core concepts are absent. | Present forbidden concept fails with reason. | Unit test |
| FR-009 | Harness MUST emit a stable YAML report. | Report includes overall result, checked sections, failures, and manual review anchors. | Snapshot/string test |
| FR-010 | Competency question expectations MUST be reported honestly. | Report marks them as `manual_review_required`, not automated pass/fail. | Unit test |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Determinism | Report ordering MUST be stable. | Sorted sections/failures where order is not source-significant |
| Maintainability | Harness should reuse existing compiler parsing/validation. | No duplicate package validator logic |
| Boundary clarity | Harness should not become governance. | No approve/reject/merge state |
| CI usability | CLI exit code should reflect automated pass/fail. | Pass exits 0, automated failure exits 1 |

## Report Shape

```yaml
apiVersion: ontology-induction.specgraph.io/v1alpha1
kind: GoldenIntentValidationReport
metadata:
  expectation: SPECS/ontology/golden-intents/expectations/example.expectation.yaml
  candidate: /path/to/candidate.yaml
result:
  passed: true
  automatedChecks:
    passed: 12
    failed: 0
checks:
  - section: concepts
    id: Exam
    status: pass
manualReview:
  competencyQuestions:
    status: manual_review_required
    mustCover:
      - allowed functions for a given exam
```

## Acceptance Criteria

- `ontologyc validate-golden-intent --help` documents the command.
- Passing fixture exits 0 and writes/prints a PASS report.
- Failing fixture exits 1 and writes/prints a FAIL report with actionable failures.
- `bash tools/swift-quality.sh` passes.
- ONT-022 is archived with PASS and `next.md` points to ONT-023.

## Risks

| Risk | Mitigation |
|---|---|
| Current golden expectations may not match the existing canonical examcalc package exactly. | Use dedicated pass/fail test fixtures and report this boundary; do not mutate canonical package in this PR. |
| Competency-question verification could be overclaimed. | Mark CQ coverage as manual review until the candidate format exposes first-class CQ data. |
| Harness could drift into governance. | Keep the command limited to validation report generation; ONT-023 owns governance protocol. |
