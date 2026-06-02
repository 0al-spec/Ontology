# PRD: ONT-019 - SpecGraph Ontology Induction Protocol and Prompt Contracts

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** 8 - Ontology Induction and Authoring  
**Reasoning Effort:** high  
**Dependencies:** ONT-001, ONT-002, ONT-003, ONT-004, ONT-015  
**Source Inputs:**
- `SPECS/raw/Агентная_Операционная_Система_-_Branch_SpecGraph_-_Онтологии.json`
- `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import.md`
- `SPECS/ontology/domain-ontology-package.schema.yaml`
- `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`
- `SPECS/ROLES/Architect.md`

## TL;DR

Materialize the missing ontology authoring layer: a staged SpecGraph Ontology Induction
Protocol that turns product/domain intent into candidate ontology artifacts, then into
validated `DomainOntologyPackage` YAML. The output must include stage-specific prompt
contracts, a quality rubric, authoring guidance, and golden intent seeds for future
stability tests.

## Conceptual Checklist

- Treat ontology authoring as a protocol, not a single free-form prompt.
- Keep LLM output as candidate hypotheses until reviewed and validated.
- Separate domain framing, concept extraction, behavior extraction, policy/risk modeling,
  YAML assembly, and review.
- Define prompt contracts with strict inputs, outputs, forbidden behavior, and failure modes.
- Define a rubric that catches implementation leakage, ontology inflation, weak relations,
  missing policies, and missing competency questions.
- Seed future golden tests with at least two domain intents.
- Keep compiler logic unchanged.

## Objective

Give ontology-authoring agents a repeatable operating procedure for producing valid,
reviewable ontology YAML. After this task, a new agent should be able to start from a
product intent, follow documented stage contracts, assemble a `DomainOntologyPackage`, and
validate it with `ontologyc check` and `ontologyc compile`.

## Scope

### In Scope

- Protocol documentation for the intent-to-ontology pipeline.
- Authoring guide for final `DomainOntologyPackage` YAML assembly.
- Stage-specific prompt contract files.
- Quality rubric and validator backlog.
- Golden intent seed files for future induction stability testing.
- FLOW validation report.

### Out of Scope

- Compiler or validator implementation changes.
- New CLI commands for automated induction.
- Running live LLM agents against the prompt contracts.
- Building a full 10-20 item golden intent suite.
- Implementing ontology governance workflows for approve/reject/merge/versioning.
- Adding Hypercode transpilation or YAML/TOML conversion support.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Induction protocol | `SPECS/ontology/induction-protocol.md` | Defines staged pipeline from `ProductIntent` to approved ontology package |
| D2 | Authoring workflow guide | `SPECS/ontology/authoring-guide.md` | Explains how agents assemble and validate `DomainOntologyPackage` YAML |
| D3 | Prompt contracts | `SPECS/ontology/authoring-prompts/*.prompt.md` | Each contract has role, inputs, outputs, must/must-not rules, and quality checks |
| D4 | Quality rubric | `SPECS/ontology/ontology-quality-rubric.md` | Defines scoring criteria, hard reject criteria, and validator split |
| D5 | Golden intent seeds | `SPECS/ontology/golden-intents/*.intent.md` | At least two product/domain intents are available for future stability tests |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-019_Validation_Report.md` | Records executed checks and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | The protocol MUST define a staged ontology induction pipeline. | Stages include intake, classification, domain framing, concept extraction, behavior extraction, policy/risk extraction, draft synthesis, critique, clarification, YAML assembly, and validation. | Document review |
| FR-002 | Prompt contracts MUST be split by stage. | No single mega-prompt owns the entire flow. | File inventory review |
| FR-003 | Each prompt contract MUST define explicit inputs and outputs. | Contract files include structured input and output sections. | `rg` checks |
| FR-004 | Prompt contracts MUST forbid trusted writes by synthesis agents. | Contracts state that agents produce candidates/deltas, not approved ontology truth. | Document review |
| FR-005 | The rubric MUST define hard reject criteria. | Reject criteria include no governing concept, noun-only ontology, implementation leakage, missing policies in policy-heavy domains, and missing competency questions. | Document review |
| FR-006 | The authoring guide MUST map final assembly to current compiler commands. | Guide includes `ontologyc check` and `ontologyc compile` commands. | `rg` checks |
| FR-007 | Golden intent seeds MUST cover different domains. | At least examcalc and multi-speaker AI transcription recorder intents exist. | File inventory review |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Security | Prompt contracts MUST treat agent outputs as untrusted candidate artifacts. | Contracts forbid direct trusted commits and require review/validation |
| Maintainability | Files MUST be small enough to reuse independently. | Prompt contracts are separate files under `authoring-prompts/` |
| Traceability | Docs MUST cite raw roadmap concepts and existing ontology YAML contract. | Protocol and guide reference source docs and current schema |
| Stability | Future golden tests MUST have stable seed inputs. | Intent seed files are committed as plain Markdown |
| Scope Control | No compiler behavior changes. | Git diff contains docs/planning artifacts only |

## Implementation Roadmap

### Phase 1 - Protocol Doc

- Create `SPECS/ontology/induction-protocol.md`.
- Define pipeline stages, stage artifacts, trust boundaries, and promotion rules.
- Include relationship to `DomainOntologyPackage`.

### Phase 2 - Prompt Contracts

- Create `SPECS/ontology/authoring-prompts/`.
- Add stage contracts:
  - `01_IntentClassifier.prompt.md`
  - `02_DomainFramer.prompt.md`
  - `03_ConceptExtractor.prompt.md`
  - `04_BehaviorExtractor.prompt.md`
  - `05_PolicyRiskExtractor.prompt.md`
  - `06_OntologySynthesizer.prompt.md`
  - `07_OntologyCritic.prompt.md`
  - `08_CompetencyQuestionGenerator.prompt.md`
  - `09_YAMLAssembler.prompt.md`
- Keep each prompt contract independently reusable.

### Phase 3 - Rubric and Authoring Guide

- Create `SPECS/ontology/ontology-quality-rubric.md`.
- Create `SPECS/ontology/authoring-guide.md`.
- Separate deterministic compiler checks from agent/human semantic review.

### Phase 4 - Golden Intent Seeds

- Create `SPECS/ontology/golden-intents/`.
- Add at least:
  - `exam-controlled-calculator.intent.md`
  - `voice-recorder-ai-transcription.intent.md`
- Keep expected ontology output out of scope for this task.

### Phase 5 - Verification and Report

- Run Flow configured gates:
  - `test -f README.md`
  - `test -f SPECS/Workplan.md`
- Run repository quality gate:
  - `bash tools/swift-quality.sh`
- Run documentation inventory checks:
  - `test -f SPECS/ontology/induction-protocol.md`
  - `test -f SPECS/ontology/authoring-guide.md`
  - `test -f SPECS/ontology/ontology-quality-rubric.md`
  - `test -f SPECS/ontology/golden-intents/exam-controlled-calculator.intent.md`
  - `test -f SPECS/ontology/golden-intents/voice-recorder-ai-transcription.intent.md`
- Save results in `SPECS/INPROGRESS/ONT-019_Validation_Report.md`.

## Success Metrics

- Agents have a documented staged path from raw intent to validated YAML.
- Prompt contracts are usable independently and do not rely on hidden context.
- The rubric makes common ontology-authoring failures reviewable.
- Golden intent seeds establish the first corpus for future repeatability testing.
- All repository quality gates pass without compiler changes.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Prompt contracts become too broad | Agents revert to mega-prompt behavior | Split by stage and require strict inputs/outputs |
| Rubric becomes subjective prose | Review quality remains inconsistent | Use score levels, hard reject criteria, and explicit examples |
| Docs drift from compiler schema | Agents produce invalid YAML | Link authoring guide to `domain-ontology-package.schema.yaml` and `ontologyc check` |
| Golden intents imply completed expected outputs | Reviewers may expect full generated packages | State that expected ontology outputs are future work |
| Over-modeling governance too early | Scope creep | Defer approve/reject/merge/versioning implementation |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Protocol doc defines the staged intent-to-ontology pipeline. | D1, FR-001 |
| Prompt contracts are split by stage and have explicit inputs/outputs. | D3, FR-002, FR-003 |
| Quality rubric defines reviewer criteria and validator separation. | D4, FR-005 |
| Authoring guide explains final YAML check/compile. | D2, FR-006 |
| At least two golden intent seeds are included. | D5, FR-007 |
