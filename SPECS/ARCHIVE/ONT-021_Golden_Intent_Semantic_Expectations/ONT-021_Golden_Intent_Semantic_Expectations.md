# PRD: ONT-021 - Golden Intent Semantic Expectations

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** 9 - Ontology Induction and Authoring  
**Reasoning Effort:** medium  
**Dependencies:** ONT-019  
**Source Inputs:**
- `SPECS/ontology/golden-intents/exam-controlled-calculator.intent.md`
- `SPECS/ontology/golden-intents/voice-recorder-ai-transcription.intent.md`
- `SPECS/ontology/induction-protocol.md`
- `SPECS/ontology/ontology-quality-rubric.md`
- `SPECS/ontology/authoring-guide.md`

## TL;DR

Add semantic expectation files for the initial golden intent seeds. These files define
minimum domain expectations that future induction outputs must satisfy. They are not
byte-exact ontology outputs and must not force every valid draft into one rigid shape.

## Objective

Make the golden intent set reviewable and eventually testable by recording expected
governing concepts, minimum concept coverage, policy/lifecycle/evidence expectations,
competency question expectations, and forbidden surface concepts.

## Scope

### In Scope

- Expectation files for the two existing golden intents.
- README explaining expectation semantics and future harness usage.
- Links from authoring documentation.
- Validation report.

### Out of Scope

- Automated harness implementation.
- LLM execution.
- Expected `DomainOntologyPackage` YAML outputs.
- Byte-for-byte comparison against generated ontology drafts.
- Governance approval protocol.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Examcalc semantic expectations | `SPECS/ontology/golden-intents/expectations/exam-controlled-calculator.expectation.yaml` | Defines minimum semantic expectations for exam-controlled calculator |
| D2 | Voice recorder semantic expectations | `SPECS/ontology/golden-intents/expectations/voice-recorder-ai-transcription.expectation.yaml` | Defines minimum semantic expectations for multi-speaker transcription recorder |
| D3 | Expectations README | `SPECS/ontology/golden-intents/README.md` | Explains expectation format, non-goals, and future harness usage |
| D4 | Documentation links | `SPECS/ontology/authoring-guide.md` or README | Makes expectations discoverable |
| D5 | Validation report | `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/ONT-021_Validation_Report.md` | Records checks and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Each expectation file MUST identify the source intent file. | `sourceIntent` points to the matching intent path. | `rg`/review |
| FR-002 | Each expectation file MUST define expected domain frame and governing concept. | `domainFrame` and `governingConcept` are present. | `rg`/review |
| FR-003 | Each expectation file MUST define minimum concept expectations. | `minimumConcepts` is grouped by semantic category. | `rg`/review |
| FR-004 | Each expectation file MUST define forbidden surface concepts. | `forbiddenCoreConcepts` is present and explains implementation leakage. | `rg`/review |
| FR-005 | Each expectation file MUST define competency question expectations. | `competencyQuestions.mustCover` is present. | `rg`/review |
| FR-006 | Expectation docs MUST state that outputs are minimum semantic criteria. | README says not byte-exact ontology truth. | `rg`/review |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Maintainability | Expectation files should be readable YAML. | Stable structure and concise comments |
| Testability | Structure should be easy for ONT-022 harness to parse. | Repeated sections and simple scalar/list values |
| Scope Control | No compiler behavior changes. | Diff contains docs/spec fixtures only |
| Semantic Safety | Expectations must not invent regulatory facts as truth. | Risk/policy assumptions remain generic or marked as review expectations |

## Implementation Roadmap

1. Create `SPECS/ontology/golden-intents/expectations/`.
2. Add expectation YAML for `exam-controlled-calculator`.
3. Add expectation YAML for `voice-recorder-ai-transcription`.
4. Add `SPECS/ontology/golden-intents/README.md`.
5. Link expectations from `SPECS/ontology/authoring-guide.md`.
6. Run validation:
   - file existence checks;
   - `rg` contract checks;
   - `git diff --check`;
   - `bash tools/swift-quality.sh`.
7. Save validation report.

## Success Metrics

- Both existing golden intents have expectation files.
- Future harness work has clear fields to parse.
- The expectations preserve semantic minimums without freezing one exact ontology draft.
- Repository quality gates pass.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Expectations become over-prescriptive | Valid alternative ontologies fail future checks | Define minimums and forbidden anti-patterns, not full outputs |
| Expectations are too vague | Harness cannot parse or evaluate them | Use structured YAML with repeated fields |
| Voice recorder expectations imply legal/consent facts not in intent | False domain authority | Treat consent/retention as policy expectations for review, not facts |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Expectations exist for both golden intents. | D1, D2 |
| Each expectation defines frame, governing concept, coverage, policies, lifecycle, evidence, competency questions, forbidden surface concepts. | D1, D2, FR-002..FR-005 |
| Expectations are minimum semantic criteria. | D3, FR-006 |
| README explains future repeatability checks. | D3 |
| Documentation makes expectations discoverable. | D4 |
