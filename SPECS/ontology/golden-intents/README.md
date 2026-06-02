# Golden Intent Set

## Purpose

Golden intents are stable source inputs for ontology induction experiments. They are not
complete ontology packages by themselves. They let agents and future harnesses compare
candidate induction outputs against minimum semantic expectations.

## Files

| Intent | Expectation |
|---|---|
| `exam-controlled-calculator.intent.md` | `expectations/exam-controlled-calculator.expectation.yaml` |
| `voice-recorder-ai-transcription.intent.md` | `expectations/voice-recorder-ai-transcription.expectation.yaml` |

## Expectation Semantics

Expectation files are minimum semantic criteria. They define what a valid candidate output
must preserve, such as:

- deep domain frame;
- governing concept;
- minimum concept coverage;
- required relation paths;
- policy, lifecycle, trust, and evidence expectations;
- competency question review anchors;
- forbidden surface or implementation concepts.

They are intentionally not byte-exact expected ontology outputs. A candidate ontology may
use different names or add justified concepts and still be acceptable if it satisfies the
minimum semantics and avoids hard reject criteria.

## Repeatability Harness

Use `ontologyc validate-golden-intent` to compare an expectation file with a candidate
`DomainOntologyPackage` YAML artifact:

```bash
swift run ontologyc validate-golden-intent \
  SPECS/ontology/golden-intents/expectations/exam-controlled-calculator.expectation.yaml \
  --candidate Tests/fixtures/golden-intents/examcalc-pass.yaml \
  --out /tmp/golden-intent-report.yaml
```

Evaluation shape:

```text
golden intent + candidate ontology draft + expectation file -> repeatability report
```

The command performs automated pass/fail checks for:

- governing concept presence and `central: true` when required;
- minimum concept coverage;
- required relation id/domain/range shape;
- required policies and enforceability groups;
- lifecycle state machine state coverage;
- forbidden core concept absence.

Competency question expectations are included in the report as `manual_review_required`
anchors. The current `DomainOntologyPackage` format does not carry first-class competency
question data, so the harness does not overclaim automated CQ proof.

## Non-Goals

- No live LLM execution is required by this directory.
- No expected `DomainOntologyPackage` YAML is stored here yet.
- No ontology approval or governance decision is implied by satisfying an expectation file.
