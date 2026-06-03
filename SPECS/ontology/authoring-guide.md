# Ontology Authoring Guide

## Purpose

This guide explains how an ontology-authoring agent should produce
`DomainOntologyPackage` YAML. The YAML format is documented by
`SPECS/ontology/domain-ontology-package.schema.yaml`; this guide documents the authoring
process that happens before YAML assembly.

## TL;DR

Do not start by writing YAML. Start by inducing a domain model from intent, review it as a
candidate, then assemble YAML and validate it with `ontologyc`.

```text
intent -> staged prompt contracts -> reviewed draft -> YAML -> ontologyc check -> compile
```

## Authoring Steps

1. Classify the intent.
2. Frame the domain and identify the governing concept.
3. Extract domain concepts using the meta-model.
4. Extract behavior: commands, events, states, and lifecycle transitions.
5. Extract policies, invariants, risks, and evidence requirements.
6. Synthesize a candidate ontology draft.
7. Critique the draft using the quality rubric.
8. Generate competency questions.
9. Assemble `DomainOntologyPackage` YAML.
10. Run compiler validation.
11. Submit candidate output to ontology governance before treating it as trusted.

## Role Set

| Role | Responsibility | Output |
|---|---|---|
| `IntentClassifierAgent` | Determine intent type, domain, risk level, and dependency on existing ontology | `IntentClassification` |
| `DomainFramerAgent` | Find deep domain frame and governing concept | `DomainFrame` |
| `ConceptExtractorAgent` | Extract actors, entities, value objects, capabilities, commands, events | `CandidateConceptSet` |
| `BehaviorExtractorAgent` | Extract commands, events, state machines, transitions | `BehaviorModel` |
| `PolicyRiskExtractorAgent` | Extract policies, invariants, risks, and evidence requirements | `PolicyRiskModel` |
| `OntologySynthesizerAgent` | Combine staged artifacts into a candidate ontology draft | `ProductOntologyDraft` |
| `OntologyCriticAgent` | Find semantic gaps, inflation, leakage, ambiguity, and overconfidence | `OntologyCritiqueReport` |
| `CompetencyQuestionAgent` | Generate test questions the ontology must answer | `CompetencyQuestionSet` |
| `YAMLAssemblerAgent` | Convert reviewed draft artifacts into compiler YAML | `DomainOntologyPackageDraft` |

## Model Selection Guidance

Ontology authoring does not require every stage agent to use the strongest available
model. Prefer the cheapest and fastest model that satisfies the stage contract and keeps
downstream validation stable.

Use stronger models when the stage depends on judgment, ambiguity resolution, or
trust-sensitive synthesis:

- `DomainFramerAgent` in unfamiliar, high-risk, or cross-domain intents;
- `OntologySynthesizerAgent` when staged artifacts conflict or contain unresolved
  assumptions;
- `OntologyCriticAgent` when semantic gap detection, leakage detection, or overconfidence
  review is the main risk;
- governance-facing summaries where a human reviewer relies on the agent's rationale.

Cheaper or faster models are acceptable when the task is highly structured and downstream
checks are deterministic:

- `IntentClassifierAgent` for routine intent classification;
- `ConceptExtractorAgent`, `BehaviorExtractorAgent`, and `PolicyRiskExtractorAgent` when
  prompt contracts require explicit evidence and uncertainty;
- `CompetencyQuestionAgent` when questions are reviewed against the rubric;
- `YAMLAssemblerAgent` when it only translates reviewed artifacts into schema-shaped YAML.

Model choice is an operational decision, not a trust source. A model is acceptable for a
role only when its outputs:

- preserve golden intent expectations for the domain;
- pass the quality rubric without new hard rejects;
- keep assumptions and uncertainty explicit;
- produce YAML that passes `ontologyc check`;
- do not bypass governance for trusted publication.

## DomainOntologyPackage Skeleton

Use the current package shape:

```yaml
apiVersion: ontology.specgraph.io/v1alpha1
kind: DomainOntologyPackage
metadata:
  id: com.example.domain
  namespace: example
  version: 0.1.0
  publisher: ExampleOntologyAuthor
  source: path-or-source-id
  approvalStatus: draft
spec:
  imports:
    - id: specgraph.foundation
      namespace: sg
      version: 0.1.0
  classes: {}
  relations: {}
  protocols: {}
  policies: {}
  stateMachines: {}
```

## Mapping Draft Concepts to YAML

| Draft Artifact | YAML Target | Notes |
|---|---|---|
| Actor | `spec.classes` with suitable foundation extension | Use actor classes only when they are domain-significant |
| Domain entity | `spec.classes` | Prefer identity-bearing concepts |
| Value object | `spec.classes` extending a value-object foundation type when available | Avoid primitive obsession in generated SDK semantics |
| Capability | `spec.classes` extending `sg:Capability` | Useful for permission and policy domains |
| Command | `spec.classes` extending `sg:Command` | Use for intentional state-changing actions |
| Event | `spec.classes` extending `sg:Event` | Use for meaningful occurrences |
| Policy | `spec.policies` | Include enforceability and affected concepts |
| State model | `spec.stateMachines` | Link lifecycle classes via `lifecycle` |
| Domain association | `spec.relations` | Use domain verbs, not generic links |
| Governing concept | class with `central: true` | Use one central concept unless multi-central semantics are justified |

## Quality Checklist Before YAML

- The deep domain frame is explicit.
- The governing concept is identified or intentionally absent.
- Concepts are domain concepts, not UI components or implementation tasks.
- Relations have meaningful domain verbs and typed domain/range.
- Policy-heavy domains include explicit policies.
- Lifecycle-heavy domains include state machines.
- Risks and evidence requirements are captured where trust or compliance matters.
- Competency questions cover relations, policies, lifecycle, and evidence.
- Assumptions are not converted into facts.

For golden intent experiments, compare candidate drafts against the minimum semantic
expectations in `SPECS/ontology/golden-intents/expectations/`. These expectations are
review anchors, not byte-exact ontology outputs.

## Compiler Validation

Run:

```bash
swift run ontologyc check <package.yaml>
```

Then compile:

```bash
swift run ontologyc compile <package.yaml> --target typescript --out <out-dir>
```

For compatibility checks against another YAML package:

```bash
swift run ontologyc diff --from <old.yaml> --to <new.yaml> --out <report.yaml>
```

## Common Failure Modes

| Failure | Symptom | Correction |
|---|---|---|
| Surface noun extraction | YAML contains only obvious nouns from the prompt | Re-run domain framing and concept extraction |
| Implementation leakage | `Screen`, `Button`, `APIEndpoint`, or `DatabaseTable` becomes core domain | Move implementation details out unless they are the domain |
| Missing governing concept | Many concepts look equally central | Identify what controls lifecycle, trust, money, policy, or value |
| Weak relations | Relations use `has`, `uses`, or `links_to` everywhere | Replace with domain verbs |
| Missing behavior | No commands, events, or lifecycle states | Run behavior extraction |
| Missing policies | Security/compliance domain has only entities | Run policy/risk extraction |
| Overconfidence | Draft invents facts not present in intent | Add assumptions and clarification questions |

## Example: Voice Recorder with AI Transcription

Intent summary:

```text
Build a voice recorder application with AI transcription for multi-speaker speech.
The app records audio, separates speakers, produces timestamped transcript segments,
and lets users review uncertain segments before exporting text.
```

Likely governing concept:

```yaml
governingConcept:
  id: TranscriptionSession
  rationale: Controls recording, speaker attribution, transcript lifecycle, review, and export.
```

Candidate classes might include:

- `RecordingSession`
- `AudioRecording`
- `SpeakerProfile`
- `TranscriptSegment`
- `TranscriptionSession`
- `SpeakerAttribution`
- `ReviewCorrection`
- `ExportTranscript`
- `TranscriptionCompleted`

The final YAML must still pass `ontologyc check`; this guide does not authorize new
schema fields.

Promotion from candidate YAML to trusted ontology version is governed by
[`governance-protocol.md`](governance-protocol.md). The review output should be captured
as an `OntologyGovernanceDecision` artifact using
[`governance-decision.schema.yaml`](governance-decision.schema.yaml); future compiler and
registry gates consume that decision record rather than free-form reviewer notes.
