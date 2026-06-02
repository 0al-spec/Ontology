# Ontology Quality Rubric

## Purpose

This rubric evaluates candidate ontology drafts before they are assembled into
`DomainOntologyPackage` YAML or promoted as trusted ontology deltas.

Scale:

- `0`: reject-level weakness;
- `1`: weak and requires major revision;
- `2`: acceptable with review comments;
- `3`: strong and ready for YAML assembly or approval.

## Scorecard

| Criterion | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Domain framing | Surface product noun only | Domain roughly identified | Deep domain frame identified | Deep frame plus governing concept identified |
| Concept coverage | Only entities | Entities and actors | Entities, actors, capabilities, commands, events | Full model includes states, policies, invariants, risks, evidence |
| Behavioral modeling | No behavior | Some actions listed | Commands/events present | State machines and lifecycle transitions included |
| Policy modeling | No policies | Implicit rules only | Explicit rules | Rules are enforceable, testable, and linked to concepts/events |
| Trust and evidence | No evidence | Audit mentioned vaguely | Evidence concepts included | Evidence requirements and verification paths modeled |
| Uncertainty handling | Overconfident | Some assumptions marked | Unclear points marked | Clarification questions link to affected concepts |
| Implementation leakage | UI/config/code dominates | Some leakage | Mostly domain-focused | Clean domain/implementation boundary |
| Relation quality | Generic links only | Some domain verbs | Typed meaningful relations | Relations support competency questions and retrieval |
| Competency questions | None | Generic questions | Questions cover some concepts | Questions test policy, lifecycle, evidence, and relation paths |
| YAML readiness | Cannot map to schema | Requires major schema interpretation | Mostly maps to schema | Maps cleanly to `DomainOntologyPackage` |

## Hard Reject Criteria

Reject the draft if any condition is true:

- Ontology contains only nouns and no behavior.
- No governing concept is identified in a domain that clearly has one.
- Policies are missing in a policy-heavy, security-heavy, trust-heavy, or compliance-heavy
  domain.
- States or lifecycles are missing for lifecycle-heavy entities.
- Implementation details are modeled as domain core without justification.
- No competency questions are generated.
- No uncertainty or assumptions are marked.
- Generated ontology contradicts explicit user intent.
- Regulatory, legal, institutional, or medical claims are invented as facts.
- YAML assembly requires schema fields not supported by `DomainOntologyPackage`.

## Review Verdicts

| Verdict | Condition | Action |
|---|---|---|
| `approved_for_yaml` | No hard reject and all key criteria are `2` or `3` | Assemble YAML and run `ontologyc check` |
| `needs_clarification` | No hard reject but important assumptions remain unresolved | Ask clarification questions before YAML |
| `needs_revision` | No hard reject but multiple criteria score `1` | Re-run affected prompt stages |
| `rejected` | Any hard reject criterion applies | Restart from domain framing or concept extraction |

## Validator Split

| Check Type | Examples | Owner |
|---|---|---|
| Deterministic compiler checks | YAML shape, known refs, state transition refs, unsafe YAML | `ontologyc` |
| Prompt contract checks | Required inputs/outputs, no trusted writes, explicit uncertainty | Stage prompt contracts |
| Rubric review | Domain framing, leakage, inflation, governing concept, competency quality | `OntologyCriticAgent` or human reviewer |
| Future golden tests | Intent stability, expected ontology shape, output drift | Future induction harness |
| Future governance | approve/reject/merge/versioning | Future ontology governance task |

## Expected Baseline for Examcalc

The exam-controlled calculator ontology should score:

```yaml
expectedScore:
  domainFraming: 3
  conceptCoverage: 3
  behavioralModeling: 2
  policyModeling: 3
  trustAndEvidence: 3
  uncertaintyHandling: 2
  implementationLeakage: 3
  relationQuality: 3
  competencyQuestions: 3
  yamlReadiness: 3
```

The governing concept is `ExamPolicyProfile`, not `CalculatorApplication`.
