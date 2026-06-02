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
- competency question coverage;
- forbidden surface or implementation concepts.

They are intentionally not byte-exact expected ontology outputs. A candidate ontology may
use different names or add justified concepts and still be acceptable if it satisfies the
minimum semantics and avoids hard reject criteria.

## Future Harness Use

ONT-022 should use these files as inputs for a repeatability harness. The harness should
check minimum semantics and anti-patterns, not compare whole generated drafts
byte-for-byte.

Recommended evaluation shape:

```text
golden intent + candidate ontology draft + expectation file -> repeatability report
```

## Non-Goals

- No live LLM execution is required by this directory.
- No expected `DomainOntologyPackage` YAML is stored here yet.
- No ontology approval or governance decision is implied by satisfying an expectation file.
