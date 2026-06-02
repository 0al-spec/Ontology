# Ontology Governance Protocol

## Purpose

The Ontology Governance Protocol defines how generated ontology packages and ontology
deltas become accepted ontology versions. It sits after induction, critique, compiler
validation, and golden intent repeatability checks.

This protocol is a trust boundary. Agents may propose ontology changes, but they do not
approve ontology truth.

## Inputs

Every governance decision should reference the evidence used to decide:

| Evidence | Required | Notes |
|---|---|---|
| Source intent | yes | Original product/domain intent or change request |
| Candidate artifacts | yes | Domain frame, concept set, behavior model, policy/risk model, draft |
| Candidate package or delta | yes | `DomainOntologyPackage` YAML or explicit ontology delta |
| Critique report | yes | Human or `OntologyCriticAgent` review |
| Competency questions | yes | Questions the ontology must answer, including known gaps |
| Compiler validation | yes | `ontologyc check` and compile evidence where applicable |
| Repeatability report | yes for golden intents | `ontologyc validate-golden-intent` report |
| Compatibility report | yes for existing packages | `ontologyc diff` or equivalent compatibility evidence |
| Reviewer rationale | yes | Human-readable decision rationale |

## Lifecycle States

| State | Meaning | Trusted? |
|---|---|---|
| `candidate` | Generated or assembled package/delta awaiting validation. | no |
| `under_review` | Candidate has enough evidence for review. | no |
| `changes_requested` | Candidate needs targeted revision before a decision. | no |
| `rejected` | Candidate must not be promoted without a new proposal. | no |
| `approved` | Candidate is accepted as an ontology package or delta. | yes |
| `merged` | Approved delta has been incorporated into an accepted package line. | yes |
| `superseded` | Accepted artifact has been replaced by a newer accepted artifact. | historical |
| `withdrawn` | Proposer withdrew candidate before approval/rejection. | no |

## Allowed Transitions

| From | To | Actor | Required Evidence | Output |
|---|---|---|---|---|
| `candidate` | `under_review` | authoring agent or maintainer | source intent, candidate package, critique, compiler validation | review packet |
| `under_review` | `changes_requested` | human reviewer | review comments with required corrections | revision request |
| `changes_requested` | `candidate` | authoring agent or maintainer | revised candidate and changed evidence | revised candidate |
| `under_review` | `rejected` | human reviewer | hard reject reason or unresolved critical gaps | rejection decision |
| `under_review` | `approved` | human reviewer | passing validation and accepted residual risks | approval decision |
| `approved` | `merged` | human maintainer | compatibility/version decision and merge record | accepted package line update |
| `approved` | `superseded` | human maintainer | newer approved artifact | supersession record |
| `candidate` | `withdrawn` | proposer | withdrawal reason | withdrawal record |
| `changes_requested` | `withdrawn` | proposer | withdrawal reason | withdrawal record |

Invalid transition: generated agents must not move a candidate directly to `approved`,
`merged`, or `superseded`.

## Review Verdicts

| Verdict | Meaning | Required Action |
|---|---|---|
| `approve` | Candidate is fit for promotion. | Create approval decision record. |
| `request_changes` | Candidate is promising but incomplete. | Return targeted corrections. |
| `reject` | Candidate violates hard criteria or contradicts intent. | Record rejection and do not promote. |
| `withdraw` | Candidate is removed before final review. | Record withdrawal. |

## Decision Record Shape

Decision records are audit artifacts. They may live in a registry, repository, or governance
ledger, but must preserve the same fields.

The machine-readable contract is defined in
[`governance-decision.schema.yaml`](governance-decision.schema.yaml). Authors and agents
should use the examples under [`examples/governance/`](examples/governance/) when preparing
review packets:

- [`approved-decision.yaml`](examples/governance/approved-decision.yaml) shows a valid
  human approval record.
- [`invalid-agent-approval.yaml`](examples/governance/invalid-agent-approval.yaml) shows
  the trust-boundary violation future validators must reject.

```yaml
apiVersion: ontology-governance.specgraph.io/v1alpha1
kind: OntologyGovernanceDecision
metadata:
  id: decision-2026-06-02-examcalc-policy-profile
  createdAt: "2026-06-02T20:00:00Z"
  reviewUrl: https://github.com/0al-spec/Ontology/pull/example
spec:
  targetPackage:
    id: edu.university.examcalc
    namespace: examcalc
    version: 0.2.0
    source: candidates/examcalc-policy-profile.yaml
  priorVersion:
    version: 0.1.0
    digest: sha256:abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789
  decision:
    state: approved
    actor:
      id: human-reviewer-id
      kind: human
      role: reviewer
    decidedAt: "2026-06-02T20:00:00Z"
    versionChange: minor
    rationale:
      - Adds policy evidence without changing existing relation semantics.
    residualRisks:
      - Competency question coverage reviewed manually.
    followUp:
      goldenExpectations:
        action: no_change
        rationale: Candidate satisfies existing expectations.
  evidence:
    sourceIntent:
      uri: SPECS/ontology/golden-intents/exam-controlled-calculator.intent.md
    candidatePackage:
      uri: candidates/examcalc-policy-profile.yaml
    critiqueReport:
      uri: reports/examcalc-critique.yaml
    compilerValidation:
      uri: reports/ontologyc-check.txt
      result: pass
    repeatabilityReport:
      uri: reports/golden-intent-report.yaml
      result: pass
    compatibilityReport:
      uri: reports/compatibility-report.yaml
      result: pass
```

## Versioning Rules

Use compatibility evidence before assigning a version change:

| Change | Version Guidance | Required Evidence |
|---|---|---|
| Documentation, descriptions, aliases, metadata | patch | No semantic break in compatibility report |
| Additive concepts, relations, policies, states | minor | Existing refs remain valid |
| Remove or rename public ontology symbols | major | Breaking compatibility report accepted by reviewer |
| Change relation domain/range or policy enforceability | major unless proven compatible | Compatibility report and reviewer rationale |
| Reject generated concept as implementation leakage | no version | Rejection decision only |

Accepted deltas should not silently rewrite history. If an accepted artifact is replaced,
mark the old artifact `superseded` and preserve its decision record.

## Audit Requirements

An approval or rejection must be replayable from stored evidence. Preserve:

- source intent identifier and digest when available;
- candidate package or delta identifier and digest;
- prompt-contract artifacts used by the authoring pipeline;
- critique report;
- competency question set;
- compiler validation output;
- repeatability report for golden-intent candidates;
- compatibility report for existing package lines;
- reviewer identity, timestamp, verdict, rationale, and residual risks.

Do not store private keys or secrets in decision records. If signatures are added later,
store public verification material and detached signature references only.

## Golden Expectation Feedback

Golden expectations are review anchors, not automatically generated truth.

Governance may update golden intent expectations only when:

1. a candidate exposes a stable semantic requirement that is missing from the expectation;
2. a rejection reveals a recurring hard failure mode that should become a forbidden concept,
   relation, policy, or quality target;
3. a reviewer explicitly records why the expectation change is source-aligned.

Expectation updates require their own reviewable PR. Passing `ontologyc validate-golden-intent`
does not automatically update expectations.

## Boundary

This protocol does not implement registry, signing, UI workflow, or compiler enforcement.
It defines the governance contract that those systems can later enforce.

Until enforcement exists, repository PR review is the governance mechanism: the PR must
include decision evidence, validation results, and reviewer acceptance before a candidate
ontology becomes trusted.
