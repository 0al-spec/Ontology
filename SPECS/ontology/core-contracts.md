# Core Contracts

## Purpose

This document defines the boundary between the lower-level Ontology Layer and the SpecGraph Layer. SpecGraph MUST consume domain ontology packages as versioned semantic dependencies. It MUST NOT redefine product/domain concepts locally.

## Layer Boundary

| Layer | Owns | Must Not Own |
|---|---|---|
| Ontology Service | Domain concepts, ontology drafts, ontology deltas, relation definitions, policies, state machines, approval status, publication, versioning | Engineering requirements, test execution evidence, implementation tasks |
| Ontology Compiler (`ontologyc`) | Static parsing, schema validation, normalized IR, diagnostics, generated SDK files, lock metadata | User intent interpretation, human approval, runtime code execution |
| SpecGraph | Requirements, tests, decisions, evidence requirements, semantic bindings, ontology imports, ontology gaps | Product/domain class definitions, local pseudo-concepts for missing ontology terms |

## OntologyImport

An `OntologyImport` declares one semantic dependency of a SpecGraph project.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: SpecGraphProject
metadata:
  id: university-exam-calculator
spec:
  ontologyImports:
    - ontology: edu.university.examcalc
      namespace: examcalc
      version: 0.1.0
      source: registry://ontology/edu.university.examcalc/0.1.0
      digest: sha256:REPLACE_WITH_RESOLVED_DIGEST
```

Rules:

1. A SpecGraph project MUST declare ontology imports before using `semanticRefs`.
2. An import MUST pin an exact ontology version.
3. An import SHOULD include a content digest after resolution.
4. A SpecGraph validator MUST reject semantic references whose namespace is not imported.

## OntologyLockfile

The lockfile records resolved imports and protects older engineering artifacts from semantic drift.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: OntologyLockfile
metadata:
  project: university-exam-calculator
spec:
  resolved:
    - ontology: edu.university.examcalc
      namespace: examcalc
      version: 0.1.0
      digest: sha256:REPLACE_WITH_RESOLVED_DIGEST
      registryUri: registry://ontology/edu.university.examcalc/0.1.0
      aliases:
        ExamPolicyProfile: examcalc:ExamPolicyProfile
```

Rules:

1. The lockfile MUST be updated only after compatibility validation succeeds.
2. Changing an imported ontology version MUST produce an `OntologyCompatibilityReport`.
3. SpecGraph SHOULD fail validation when project imports and lockfile resolution disagree.

## ConceptRef

`ConceptRef` is the canonical resolved form of an ontology reference.

```yaml
kind: ConceptRef
ontology: edu.university.examcalc
version: 0.1.0
namespace: examcalc
concept: ExamPolicyProfile
kindOfConcept: DomainEntity
alias: examcalc:ExamPolicyProfile
uri: ontology://edu.university.examcalc/0.1.0/classes/ExamPolicyProfile
```

Rules:

1. A `ConceptRef` MUST include ontology id, version, namespace, concept, kind, alias, and URI.
2. The alias MUST resolve to exactly one canonical URI in the imported ontology registry.
3. SpecGraph MUST store or derive the canonical URI before validation passes.

## SemanticBinding

`SemanticBinding` links a SpecGraph engineering artifact to imported ontology concepts or relations.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: SemanticBinding
metadata:
  id: sb-REQ-001
spec:
  artifact:
    kind: Requirement
    id: REQ-001
  semanticRefs:
    - examcalc:Exam
    - examcalc:ExamPolicyProfile
    - examcalc:CalculatorFunction
    - examcalc:allows
    - examcalc:denies
```

Rules:

1. `semanticRefs` MUST be resolvable through `OntologyImport`.
2. A semantic binding MUST NOT define new domain concepts.
3. A semantic binding MAY reference classes, relations, policies, commands, events, and state machines.
4. If a semantic reference cannot be resolved, validation MUST emit an `OntologyGap`.

## OntologyGap

`OntologyGap` records a missing concept required by a SpecGraph artifact.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: OntologyGap
metadata:
  id: gap-001
spec:
  sourceArtifact:
    kind: Requirement
    id: REQ-001
  missingConcept: examcalc:CASFunction
  targetOntology: edu.university.examcalc
  requestedAction:
    type: proposeOntologyDelta
```

Rules:

1. SpecGraph MUST create `OntologyGap` instead of inventing local pseudo-concepts.
2. The gap MUST identify the source artifact and target ontology.
3. The gap SHOULD include a proposed action such as `proposeOntologyDelta`.

## OntologyDeltaRequest

`OntologyDeltaRequest` is the handoff from SpecGraph to the Ontology Service.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: OntologyDeltaRequest
metadata:
  id: odr-gap-001
spec:
  gap: gap-001
  targetOntology: edu.university.examcalc
  baseVersion: 0.1.0
  requestedConcepts:
    - examcalc:CASFunction
```

## OntologyCompatibilityReport

```yaml
apiVersion: ontology.specgraph.io/v1alpha1
kind: OntologyCompatibilityReport
metadata:
  from: edu.university.examcalc@0.1.0
  to: edu.university.examcalc@0.2.0
result:
  compatible: true
  requiredSpecGraphActions:
    - updateLockfile
    - regenerateSemanticBindings
changes:
  addedClasses:
    - examcalc:CASFunction
  breakingChanges: []
```

Compatibility rules:

| Change | Required Version Level |
|---|---|
| Add description, alias, or non-semantic metadata | patch |
| Add class, relation, optional property, or protocol | minor |
| Remove class or relation | major |
| Change relation domain or range | major |
| Make an optional field required | major |
| Change the meaning of a central concept | major |
