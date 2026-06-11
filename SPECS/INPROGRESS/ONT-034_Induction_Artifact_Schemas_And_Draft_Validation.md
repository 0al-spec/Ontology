# PRD: ONT-034 - Induction Artifact Schemas And Draft Validation

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** SpecGraph Value Loop Closure  
**Reasoning Effort:** high  
**Dependencies:** ONT-019, ONT-021, ONT-022, ONT-031  
**Branch:** `feature/ONT-034-induction-artifact-schemas`

## TL;DR

Turn the first ontology-induction prompt outputs into machine-readable, deterministic
candidate artifacts. Add schemas, fixtures, and `ontologyc validate-draft` so CI can reject
missing provenance, missing uncertainty handling, unsupported schema drift, and invalid
draft packages before any final governance or registry publication step.

## Conceptual Checklist

- Preserve the ONT-019 staged prompt-contract workflow; do not invent a new induction flow.
- Validate intermediate artifacts as untrusted candidates, not approved ontology truth.
- Require source/provenance and uncertainty fields where agents are likely to overclaim.
- Keep the final YAML draft compatible with existing `DomainOntologyPackage` compiler input.
- Emit deterministic reports that can be committed as CI evidence.
- Keep governance and registry publication out of scope.

## Objective

Give ontology-authoring agents a concrete artifact contract between prompt execution and
final `DomainOntologyPackage` validation. After this task, a staged induction run can write
four YAML files into a draft directory and use `ontologyc validate-draft` to check that the
candidate artifacts are structurally complete, versioned, provenance-carrying, and safe to
advance into ordinary compiler validation.

## Scope

### In Scope

- Machine-readable schema files for the first minimal artifact set:
  - `IntentClassification`
  - `ProductOntologyDraft`
  - `DraftCritique`
  - `DomainOntologyPackageDraft`
- Valid and invalid draft artifact fixtures.
- Swift validator API and deterministic report rendering.
- CLI command:
  - `ontologyc validate-draft <draft-directory> [--out <report.yaml>]`
- Documentation updates in the authoring/induction docs.
- Regression tests and Flow validation report.

### Out of Scope

- Running LLM agents or prompt orchestration.
- Approving, rejecting, merging, or publishing ontology truth.
- Full JSON Schema/YAML Schema engine integration.
- New registry behavior.
- New SpecGraph-side consumer behavior.
- Byte-exact comparison between different agent runs.

## Artifact Set Contract

`validate-draft` validates one directory containing these files:

| File | Artifact | Purpose |
|---|---|---|
| `intent-classification.yaml` | `IntentClassification` | Classifies the source intent before ontology synthesis |
| `product-ontology-draft.yaml` | `ProductOntologyDraft` | Carries candidate classes, relations, policies, states, assumptions, provenance, and uncertainty |
| `draft-critique.yaml` | `DraftCritique` | Records rubric review status, issues, questions, and YAML readiness |
| `domain-ontology-package-draft.yaml` | `DomainOntologyPackageDraft` | Ordinary `DomainOntologyPackage` YAML constrained to `metadata.approvalStatus: draft` |

`DomainOntologyPackageDraft` is a schema/profile name, not a new compiler package kind. The
YAML remains `kind: DomainOntologyPackage` so the existing compiler can validate it without
schema forks.

## Minimal Schema Rules

### Common Candidate Rules

- `apiVersion` MUST be `ontology-induction.specgraph.io/v1alpha1` for induction artifacts.
- `kind` MUST match the expected artifact.
- Candidate artifacts MUST carry explicit provenance.
- Candidate artifacts MUST carry uncertainty or questions fields, even when empty.
- Unsupported `apiVersion` or unexpected `kind` MUST fail validation.

### IntentClassification

Required fields:

- `intentType`
- `domain`
- `productType`
- `criticality`
- `primaryConcern`
- `requiresExistingOntology`
- `confidence`
- `uncertainties`
- `provenance`

Enumerations:

- `intentType`: `ProductCreationIntent`, `FeatureIntent`, `ChangeIntent`,
  `ClarificationIntent`, `EvidenceIntent`, `ArchitectureIntent`, `PolicyIntent`
- `criticality`: `low`, `medium`, `high`

### ProductOntologyDraft

Required fields:

- `metadata.status: candidate`
- `metadata.sourceIntentId`
- `metadata.producedBy`
- `metadata.confidence`
- `metadata.provenance`
- `metadata.uncertainties`
- `spec.namespaceCandidate`
- `spec.governingConcept`
- `spec.classes`
- `spec.relations`
- `spec.policies`
- `spec.stateMachines`
- `spec.assumptions`
- `spec.validationNotes`

### DraftCritique

Required fields:

- `status`
- `summary`
- `scores`
- `issues`
- `questions`
- `provenance`

Enumerations:

- `status`: `approved_for_yaml`, `needs_clarification`, `needs_revision`, `rejected`
- issue severity: `low`, `medium`, `high`, `blocker`

### DomainOntologyPackageDraft

Required behavior:

- File MUST parse as an existing `DomainOntologyPackage`.
- `metadata.approvalStatus` MUST be `draft`.
- `ontologyc check` semantics MUST still apply through existing compiler validation.
- The draft artifact MUST NOT be treated as approved even when validation passes.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Artifact schemas | `SPECS/ontology/induction-artifacts/*.schema.yaml` | Four schema/profile files exist and document required fields/enums |
| D2 | Valid draft fixture | `SPECS/ontology/fixtures/induction-drafts/valid/voice-recorder/` | Fixture covers all four artifacts and passes `validate-draft` |
| D3 | Invalid draft fixtures | `SPECS/ontology/fixtures/induction-drafts/invalid/*/` | Fixtures cover missing required fields, missing provenance/uncertainty, unsupported apiVersion, and non-draft package status |
| D4 | Validator API | `Sources/OntologyCompiler/InductionDraftValidation.swift` | Loads a draft directory, validates artifacts, emits stable report text |
| D5 | CLI command | `Sources/OntologyC/main.swift` and `CLIArguments.swift` | `ontologyc validate-draft <draft-directory> [--out <report.yaml>]` prints PASS/FAIL and exits deterministically |
| D6 | Tests | `Tests/OntologyCompilerTests/InductionDraftValidationTests.swift` and CLI regression tests | Unit and CLI tests cover passing/failing fixtures and report output |
| D7 | Documentation | `SPECS/ontology/induction-protocol.md`, `authoring-guide.md`, README as needed | Docs explain where `validate-draft` fits before `ontologyc check` and governance |
| D8 | Validation report | `SPECS/INPROGRESS/ONT-034_Validation_Report.md` | Records local quality gates and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Schemas MUST exist for all four minimal artifacts. | Four `*.schema.yaml` files are committed. | File inventory test/review |
| FR-002 | Validator MUST reject unsupported schema drift. | Wrong `apiVersion` or `kind` fails. | Unit test |
| FR-003 | Validator MUST enforce provenance. | Missing provenance fails in candidate artifacts. | Unit test |
| FR-004 | Validator MUST enforce uncertainty/question surfaces. | Missing uncertainty/questions fields fail. | Unit test |
| FR-005 | Validator MUST validate `DomainOntologyPackageDraft` through existing compiler rules. | Invalid package YAML fails with compiler diagnostics. | Unit or CLI test |
| FR-006 | Draft package MUST remain unapproved. | `metadata.approvalStatus != draft` fails. | Unit test |
| FR-007 | CLI MUST emit deterministic report YAML. | Report ordering and diagnostic codes are stable. | Snapshot/string assertions |
| FR-008 | CLI MUST preserve trust boundary. | Passing report states candidate-only validation and no approval. | Unit/review |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Determinism | Reports MUST have stable ordering. | Artifacts checked in fixed order; diagnostics sorted by artifact/path/code |
| Maintainability | Validator SHOULD reuse existing compiler loading where package validation is needed. | No duplicate `DomainOntologyPackage` validation rules |
| Security | YAML is treated as inert data. | Reuse current package safety checks for the final draft package |
| Scope Control | Validation MUST NOT approve ontology truth. | No governance decision, registry publish, or trusted channel behavior |
| Agent Usability | Failure messages MUST be actionable for an authoring agent. | Diagnostics include artifact, path, code, and message |

## Report Shape

```yaml
apiVersion: ontology-induction.specgraph.io/v1alpha1
kind: InductionDraftValidationReport
metadata:
  draftDirectory: SPECS/ontology/fixtures/induction-drafts/valid/voice-recorder
result:
  passed: true
  artifactsChecked: 4
  errors: 0
  warnings: 0
trustBoundary:
  status: candidate_only
  message: validate-draft checks structure; approval requires compiler validation and governance
artifacts:
  - name: IntentClassification
    path: intent-classification.yaml
    status: pass
diagnostics: []
```

## Implementation Roadmap

### Phase 1 - Schema and Fixture Contract

- Add `SPECS/ontology/induction-artifacts/`.
- Add the four schema/profile files.
- Add one valid voice-recorder fixture using the existing golden intent domain.
- Add invalid fixtures for:
  - missing required field;
  - missing provenance;
  - missing uncertainty/questions field;
  - unsupported `apiVersion`;
  - `DomainOntologyPackage` with non-`draft` approval status.

### Phase 2 - Validator Core

- Add `InductionDraftValidation.swift`.
- Parse YAML with existing Yams dependency.
- Validate artifacts in fixed order.
- Reuse existing compiler package loading/validation for `domain-ontology-package-draft.yaml`.
- Render deterministic report YAML manually, matching existing project style.

### Phase 3 - CLI Integration

- Add help text and argument parsing for `validate-draft`.
- Print:
  - `ontologyc validate-draft: PASS <draft-directory>[ -> <report.yaml>]`
  - `ontologyc validate-draft: FAIL <draft-directory>[ -> <report.yaml>]`
- Exit 0 on pass, 1 on validation failure, and 2 on usage errors.

### Phase 4 - Docs and Validation

- Update authoring docs to place `validate-draft` before `ontologyc check`.
- Run:
  - `swift test --filter InductionDraftValidationTests`
  - `bash tools/swift-quality.sh`
  - `bash tools/typescript-smoke.sh`
  - `git diff --check`
- Save `ONT-034_Validation_Report.md`.

## Success Metrics

- Agent-produced staged artifacts have a concrete directory contract.
- CI can reject incomplete candidate outputs before final YAML approval.
- The final package remains compatible with the existing compiler and governance flow.
- Documentation makes clear that draft validation is structural evidence, not truth.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Schema files drift from Swift validator | Docs and CLI disagree | Keep schemas minimal and add tests that exercise matching fixture expectations |
| `validate-draft` becomes pseudo-governance | Agents may treat structural pass as approval | Report and docs explicitly state `candidate_only` trust boundary |
| Validator overfits to one fixture | Future agent outputs fail unnecessarily | Validate minimum structural fields, not full semantic content |
| Duplicate package validation diverges | Bugs in final YAML checks | Reuse existing compiler validation for package draft |
| Prompt contracts still use older names | Agent instructions may be inconsistent | Update prompt docs where needed to use `DraftCritique` and draft-validation terminology |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Schemas exist for `IntentClassification`, `ProductOntologyDraft`, `DraftCritique`, and `DomainOntologyPackageDraft`. | D1, FR-001 |
| Valid and invalid fixtures cover required fields, uncertainty/provenance fields, and unsupported schema drift. | D2, D3, FR-002, FR-003, FR-004 |
| `ontologyc validate-draft` validates the artifact set without approving ontology truth. | D4, D5, FR-005, FR-006, FR-008 |
| The validation report is deterministic and suitable for CI. | D4, D6, FR-007 |
| Authoring docs explain that final trust still comes from compiler validation and governance. | D7, FR-008 |
