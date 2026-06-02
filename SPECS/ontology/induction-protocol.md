# SpecGraph Ontology Induction Protocol

## Purpose

The SpecGraph Ontology Induction Protocol (SG-OIP) defines how an ontology-authoring
agent turns a product or domain intent into a reviewed, validated `DomainOntologyPackage`.
The protocol treats intent analysis as ontology compilation, not as free-form LLM
interpretation.

The final YAML package is the last artifact in the flow. Earlier artifacts are candidate
hypotheses that must remain reviewable, challengeable, and explicitly uncertain.

## Source Alignment

This protocol materializes the raw roadmap in `SPECS/raw/`:

1. SpecGraph Ontology Induction Protocol.
2. Prompt contracts with strict inputs and outputs.
3. Rubric plus validators.
4. Golden intent set.
5. Ontology governance.

The first four stages are covered by documentation, prompt contracts, golden intents, and
repeatability checks. Governance state transitions such as approve, reject, merge, and
versioning are defined in [`governance-protocol.md`](governance-protocol.md), not
implemented as compiler behavior.

## Artifact Pipeline

```text
ProductIntent
  -> IntentClassification
  -> DomainFrame
  -> CandidateConceptSet
  -> BehaviorModel
  -> PolicyRiskModel
  -> ProductOntologyDraft
  -> OntologyCritiqueReport
  -> ClarificationQuestionSet
  -> DomainOntologyPackageDraft
  -> ValidationReport
  -> ApprovedOntologyPackage
```

## Stage Overview

| Stage | Owner Contract | Input | Output | Trust Level |
|---|---|---|---|---|
| 1. Intent intake | Human or upstream agent | Raw user/product intent | `ProductIntent` | Source claim |
| 2. Intent classification | `01_IntentClassifier` | `ProductIntent` | `IntentClassification` | Candidate |
| 3. Domain framing | `02_DomainFramer` | Intent plus classification | `DomainFrame` | Candidate |
| 4. Concept extraction | `03_ConceptExtractor` | Domain frame | `CandidateConceptSet` | Candidate |
| 5. Behavior extraction | `04_BehaviorExtractor` | Concepts plus frame | `BehaviorModel` | Candidate |
| 6. Policy/risk extraction | `05_PolicyRiskExtractor` | Concepts plus behavior | `PolicyRiskModel` | Candidate |
| 7. Draft synthesis | `06_OntologySynthesizer` | Prior stage artifacts | `ProductOntologyDraft` | Candidate |
| 8. Critique | `07_OntologyCritic` | Intent plus draft | `OntologyCritiqueReport` | Review evidence |
| 9. Competency questions | `08_CompetencyQuestionGenerator` | Draft plus critique | `CompetencyQuestionSet` | Review evidence |
| 10. YAML assembly | `09_YAMLAssembler` | Approved draft inputs | `DomainOntologyPackageDraft` | Candidate YAML |
| 11. Compiler validation | `ontologyc` | YAML draft | Diagnostics, IR, SDK | Deterministic evidence |
| 12. Promotion | Human or governance process | Validation report | Approved ontology version | Trusted artifact |

## Trust Boundary

Agents may propose:

- candidate concepts;
- candidate relations;
- candidate policies;
- candidate state machines;
- candidate competency questions;
- candidate YAML packages;
- candidate ontology deltas.

Agents must not directly:

- commit trusted ontology truth;
- delete existing trusted ontology concepts;
- mark assumptions as facts;
- approve generated ontology deltas;
- invent regulatory or institutional facts as certain;
- bypass `ontologyc check`.

## Core Meta-Model

Every induction run should reason with this stable vocabulary before producing
`DomainOntologyPackage` YAML:

| Meta-Class | Meaning |
|---|---|
| `Actor` | Human, organization, role, or external system that acts in the domain |
| `DomainEntity` | Object with identity and possible lifecycle |
| `ValueObject` | Structured value without independent identity |
| `Capability` | Something the product or system can do |
| `Command` | Intentional action initiated by an actor or system |
| `Event` | Meaningful occurrence in the domain |
| `State` | Lifecycle state of an entity or process |
| `Policy` | Rule controlling what is allowed, required, or forbidden |
| `Invariant` | Condition that must always hold |
| `Risk` | Failure, abuse, compliance, or trust concern |
| `EvidenceRequirement` | Proof needed to verify behavior, state, or compliance |
| `BoundedContext` | Semantic boundary where terms and rules are internally consistent |

The meta-model is not itself the product ontology. It is the induction vocabulary used to
decide what should become classes, relations, policies, state machines, and validation
questions.

## Governing Concept Rule

Each product ontology should identify a governing concept when the domain has one. A
governing concept usually controls permissions, lifecycle, money, trust, compliance, or the
primary user value.

Examples:

| Product Surface | Governing Concept |
|---|---|
| Exam calculator | `ExamPolicyProfile` |
| Equipment rental marketplace | `RentalContract` |
| B2B subscription SaaS | `Subscription` |
| Zero-trust agent runtime | `AgentPassport` |
| Healthcare appointment system | `CareEpisode` or `Appointment` |
| Banking transfer app | `AccountLedger` or `Transaction` |

Do not choose a UI object as the governing concept unless the UI itself is the product
domain.

## Candidate Artifact Shape

Intermediate draft artifacts should preserve rationale and uncertainty:

```yaml
kind: ProductOntologyDraft
schemaVersion: ontology-induction.specgraph.io/v1alpha1
metadata:
  sourceIntentId: string
  status: candidate
  producedBy: string
  confidence: 0.0
spec:
  domain:
    id: string
    label: string
    description: string
  classification:
    intentType: ProductCreationIntent
    criticality: low | medium | high
    primaryConcern: string
  governingConcept:
    id: string
    rationale: string
    confidence: 0.0
  boundedContexts:
    - id: string
      rationale: string
  concepts:
    - id: string
      metaClass: DomainEntity
      rationale: string
      confidence: 0.0
      needsClarification: false
  relations:
    - id: string
      domain: string
      range: string
      rationale: string
      confidence: 0.0
  policies: []
  stateMachines: []
  assumptions: []
  competencyQuestions: []
```

The `ProductOntologyDraft` format is a prompt-contract artifact, not the compiler input.
`DomainOntologyPackage` remains the compiler input.

## YAML Assembly Contract

The YAML assembler converts reviewed draft artifacts into `DomainOntologyPackage`:

- domain entities, capabilities, commands, and events become `spec.classes`;
- typed associations become `spec.relations`;
- governance, safety, and enforcement rules become `spec.policies`;
- lifecycle models become `spec.stateMachines`;
- the governing concept becomes the primary `central: true` class when justified;
- prompt rationale and uncertainty do not become unstructured implementation fields.

The assembled package must be validated with:

```bash
swift run ontologyc check <package.yaml>
swift run ontologyc compile <package.yaml> --target typescript --out <out-dir>
```

## Validation Layers

| Layer | Checks | Owner |
|---|---|---|
| Prompt contract | Required input/output sections, uncertainty, rationale | Stage agent |
| Rubric review | Semantic quality, leakage, inflation, missing behavior | Reviewer/Critic |
| Compiler validation | YAML shape, references, state-machine consistency, unsafe YAML | `ontologyc` |
| Regression validation | Golden intent stability and expected outputs | Future test harness |
| Governance validation | Approval, merge, versioning, provenance | `SPECS/ontology/governance-protocol.md` |

## Promotion Rule

Only a package that has:

1. a source intent;
2. candidate artifacts;
3. critique results;
4. competency questions;
5. successful `ontologyc check`;
6. successful `ontologyc compile`;
7. explicit approval;

may become an approved ontology version.

Until then, it remains a candidate ontology package or ontology delta.

The approval, rejection, merge, versioning, and audit process is defined by
[`governance-protocol.md`](governance-protocol.md).
