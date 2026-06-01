# PRD: ONT-003 - `examcalc` Golden Ontology Package

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Implementation Candidates  
**Reasoning Effort:** medium  
**Dependencies:** ONT-001  
**Source Inputs:**
- `SPECS/Workplan.md`
- `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import.md`
- `SPECS/ontology/examples/examcalc.ontology.yaml`
- `SPECS/ontology/examples/specgraph-semantic-binding.yaml`
- `SPECS/ontology/examples/examcalc.competency-questions.yaml`
- `SPECS/ontology/fixtures/validate-fixtures.rb`

## TL;DR

Materialize the exam-controlled calculator ontology as a canonical golden package under `SPECS/ontology/packages/examcalc/`. The package must preserve the ONT-001 ontology semantics, expose a SpecGraph requirement binding whose `examcalc:*` references all resolve, and add a focused validation command that checks required concepts, relations, policies, state machine semantics, and semanticRef resolution.

## Conceptual Checklist

- Promote `examcalc` from example-only YAML into a canonical package folder.
- Preserve ONT-001 source-aligned class, relation, policy, and state names.
- Keep audit concepts explicit: `PolicyViolation`, `AuditLogEntry`, `occurred_during`, and `records`.
- Validate requirement semantic references against package-local symbols.
- Keep package YAML inert; reuse ONT-002 fixture validation.
- Avoid implementing `ontologyc`; this task creates the golden input package and validation oracle.

## Objective

Create the first reusable golden `DomainOntologyPackage` for `edu.university.examcalc@0.1.0`. The package will serve as the canonical regression input for later compiler and SpecGraph semantic reference validation work.

## Scope

### In Scope

- Canonical `examcalc` package folder.
- Golden `DomainOntologyPackage` YAML copied from and aligned with the ONT-001 example.
- Package README that documents purpose, source, required concepts, and validation commands.
- SpecGraph requirement binding that imports the canonical package and uses `examcalc:*` semantic refs.
- Validation manifest that records required classes, relations, policies, state machine, and requirement binding files.
- Lightweight Ruby golden validator for package coverage and semanticRef resolution.
- Include the canonical package in the ONT-002 fixture harness valid set.
- ONT-003 validation report.

### Out of Scope

- TypeScript SDK generation.
- `ontologyc check` or `ontologyc compile`.
- Registry publishing, lockfile digest calculation, or package signing.
- Instance/ABox policy documents.
- Real university legal policy verification.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Canonical package YAML | `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml` | Defines required classes, audit concepts, relations, policies, and `ExamModeSessionState` |
| D2 | Package README | `SPECS/ontology/packages/examcalc/README.md` | Explains package purpose, source, symbol coverage, and validation commands |
| D3 | SpecGraph requirement binding | `SPECS/ontology/packages/examcalc/specgraph-requirement-binding.yaml` | Requirement imports package and all `examcalc:*` refs resolve |
| D4 | Validation manifest | `SPECS/ontology/packages/examcalc/validation-manifest.yaml` | Lists required symbols and binding files checked by the validator |
| D5 | Golden validator | `SPECS/ontology/packages/examcalc/validate-golden.rb` | Fails on missing required symbols or unresolved semantic refs |
| D6 | Fixture harness inclusion | `SPECS/ontology/fixtures/validate-fixtures.rb` | Treats canonical package as an expected-valid ontology package |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-003_Validation_Report.md` | Records commands, outcomes, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | The golden package MUST define `Exam`, `ExamPolicyProfile`, `CalculatorFunction`, `FunctionSet`, and `ExamModeSession`. | Missing any required class fails validation. | `validate-golden.rb` |
| FR-002 | The golden package MUST define audit concepts `PolicyViolation` and `AuditLogEntry`. | Missing audit class fails validation. | `validate-golden.rb` |
| FR-003 | Relations MUST include `requires_policy`, `allows`, `denies`, `includes_function`, `enforces`, `occurred_during`, and `records`. | Missing relation fails validation. | `validate-golden.rb` |
| FR-004 | Policies MUST include `DenyByDefaultPolicy`, `PolicyMustBeSigned`, `PolicyMustBeDeviceVerifiable`, and `NoNetworkDuringExam`. | Missing policy fails validation. | `validate-golden.rb` |
| FR-005 | `ExamModeSessionState` MUST include source-aligned states, including `pending_device_verification`. | Missing state fails validation. | `validate-golden.rb` |
| FR-006 | SpecGraph requirement binding MUST resolve every `examcalc:*` reference to a class, relation, policy, state machine, command, or event in the package. | Any unresolved semanticRef fails validation. | `validate-golden.rb` |
| FR-007 | The canonical package MUST pass the ONT-002 structural fixture harness. | Harness treats canonical package as expected-valid. | `validate-fixtures.rb` |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Security | Validators MUST parse YAML as inert data only. | Ruby safe YAML loading, no eval/exec |
| Traceability | Package provenance MUST point back to raw source material and ONT-001 outputs. | README and metadata source references present |
| Reproducibility | Validation output MUST be deterministic. | Validators sort inputs and print stable lines |
| Maintainability | Required symbol list MUST be data-driven. | Validator reads `validation-manifest.yaml` |

## Implementation Roadmap

### Phase 1 - Package Materialization

- Create `SPECS/ontology/packages/examcalc/`.
- Copy the ONT-001 `examcalc` ontology into `domain-ontology-package.yaml`.
- Add README with source, package ID, validation commands, and symbol overview.

### Phase 2 - SpecGraph Binding

- Add a requirement binding that imports the canonical package path.
- Include semanticRefs for core concepts, relations, policies, and runtime commands/events.
- Ensure all refs use the `examcalc:` namespace.

### Phase 3 - Golden Validation

- Add `validation-manifest.yaml`.
- Implement `validate-golden.rb` with checks for:
  - required classes;
  - required relations;
  - required policies;
  - required state machine states and transitions;
  - resolved SpecGraph `semanticRefs`.
- Add the canonical package to the ONT-002 fixture harness valid list.

### Phase 4 - Verification and Report

- Run Flow configured gates:
  - `test -f README.md`
  - `test -f SPECS/Workplan.md`
- Run structural fixture validation:
  - `ruby SPECS/ontology/fixtures/validate-fixtures.rb`
- Run golden package validation:
  - `ruby SPECS/ontology/packages/examcalc/validate-golden.rb`
- Save results in `SPECS/INPROGRESS/ONT-003_Validation_Report.md`.

## Success Metrics

- Canonical package exists and passes fixture validation.
- Golden validator reports all required `examcalc` classes, relations, policies, and state machine symbols present.
- Requirement binding semantic refs resolve with zero unresolved refs.
- Workplan acceptance criteria are demonstrably covered by validation output.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Canonical package drifts from ONT-001 example | Confusing duplicate ontology source | Keep package copied from ONT-001, validate both with the fixture harness, and document canonical path |
| Golden validator becomes a mini compiler | Scope creep into ONT-004 | Limit validator to manifest coverage and semanticRef resolution |
| Requirement binding overfits one requirement | Poor SpecGraph coverage | Include refs for policy profile, function sets, runtime session, audit, and enforcement policies |
| Future package signing/digest is not represented | Later registry work may need metadata changes | Keep digest/signing out of scope and document as future registry responsibility |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Ontology defines `Exam`, `ExamPolicyProfile`, `CalculatorFunction`, `FunctionSet`, `ExamModeSession`, and audit concepts. | D1, D4, D5, FR-001, FR-002 |
| Relations and policies match the PRD. | D1, D4, D5, FR-003, FR-004, FR-005 |
| Example SpecGraph requirement resolves all `examcalc:*` semantic refs. | D3, D5, FR-006 |

