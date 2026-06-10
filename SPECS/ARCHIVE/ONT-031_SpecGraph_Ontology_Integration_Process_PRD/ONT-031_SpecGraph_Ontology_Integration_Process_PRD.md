# ONT-031: SpecGraph Ontology Integration Process PRD

**Status:** PRD Ready
**Priority:** P0
**Phase:** SpecGraph Value Loop Closure
**Reasoning Effort:** medium
**Dependencies:** ONT-005, ONT-019, ONT-026, ONT-030

## TL;DR

Define the first process contract for SpecGraph consuming Ontology artifacts without
copying ontology semantics into SpecGraph. The result is a reviewable bridge workflow from
Ontology package import to SpecGraph lockfile, resolved concept refs, ontology gaps, delta
requests, governance evidence, and registry pull/publish behavior.

This task is intentionally documentation-only. It prepares a future SpecGraph-side smoke
slice while keeping the source of truth for `DomainOntologyPackage`, normalized IR,
compatibility, governance decisions, and trusted publication inside the Ontology project.

## Problem

Ontology already has a compiler, generated IR/SDK artifacts, semantic validation fixtures,
golden intent validation, governance decisions, and trusted registry publication. SpecGraph
has proposal-level direction for an external ontology import plane, but no local
implementation process that says how the two repositories connect.

Without a concrete bridge process, future work can drift in two unsafe directions:

- Ontology may grow richer SDK and registry machinery without proving it serves the
  SpecGraph consumer path.
- SpecGraph may copy `DomainOntologyPackage` semantics or create local pseudo-concepts
  instead of importing versioned ontology authority.

## Goals

1. Define the minimal end-to-end bridge workflow for a SpecGraph consumer.
2. Split artifact ownership between Ontology and SpecGraph.
3. Include one concrete examcalc-style semantic binding example.
4. Define acceptance criteria for a future SpecGraph-side smoke slice.
5. Preserve the trust boundary: `ontologyc` and prompt agents must not write canonical
   SpecGraph truth directly.

## Non-Goals

- No SpecGraph repository code changes in ONT-031.
- No changes to `ontologyc` commands or output schemas.
- No new registry transport implementation.
- No class-field SDK expansion.
- No prompt-agent runtime, Agent Passport, SpecSpace UI, Docker packaging, or executor
  adapter implementation.
- No duplication of `DomainOntologyPackage` schema inside SpecGraph.

## Source Alignment

| Source | Relevant Contract |
|--------|-------------------|
| `SPECS/ontology/core-contracts.md` | Layer boundary, `OntologyImport`, `OntologyLockfile`, `ConceptRef`, `SemanticBinding`, `OntologyGap`, `OntologyDeltaRequest`. |
| `SPECS/ontology/ontologyc.md` | `validate-specgraph` output artifacts and compiler ownership. |
| `SPECS/specgraph/semantic-validation/` | Existing examcalc fixtures and generated `ConceptRefSet`, `OntologyLockfile`, and `OntologyGapSet` outputs. |
| SpecGraph proposal source `0060_external_ontology_import_plane.md` | Review-first external ontology import plane and explicit non-goals. |
| SpecGraph proposal `0062_proto_graph_recursive_refinement.md` | Proto-graph use of ontology seed material without canonical promotion. |
| `SPECS/ontology/governance-protocol.md` and ONT-026 | Governance evidence and trusted registry publication boundary. |

## Ownership Boundary

| Area | Ontology Owns | SpecGraph Owns |
|------|---------------|----------------|
| Package semantics | `DomainOntologyPackage` schema, source YAML, imports, classes, relations, policies, state machines, protocols. | Exact dependency declarations only; no local package semantic clone. |
| Compiler output | Normalized IR, TypeScript SDK, deterministic diagnostics, compatibility reports. | Consuming compiler reports as evidence; storing derived refs/gaps/locks. |
| Reference resolution | Canonical concept URI shape and source package authority. | Binding graph artifacts to imported concepts and failing on unresolved imports. |
| Missing concepts | Validation emits `OntologyGap` candidates. | Preserves the source artifact and creates reviewable delta requests instead of pseudo-concepts. |
| Governance | `OntologyGovernanceDecision`, validation, trusted publication gate. | Requires governance evidence before treating an ontology package as trusted input. |
| Canonical graph truth | Does not write SpecGraph canonical specs. | Promotes ontology-backed references only through SpecGraph review/proposal flow. |

## Bridge Workflow

```text
Ontology package source
  -> ontologyc check / compile
  -> normalized IR + generated SDK + digest
  -> registry candidate/trusted publication
  -> SpecGraph ontology import declaration
  -> ontology.lock.yaml resolution
  -> semantic binding validation
  -> concept-refs.yaml + ontology-gaps.yaml
  -> ontology delta request for gaps
  -> governance decision evidence
  -> trusted publish / pull / lockfile update
```

### Step Contract

| Step | Input | Output | Owner |
|------|-------|--------|-------|
| 1. Validate package | `domain-ontology-package.yaml` | `ontologyc check` diagnostics | Ontology |
| 2. Compile package | valid package YAML | `ontology.normalized.json`, SDK artifacts, digest | Ontology |
| 3. Publish candidate/trusted | package, registry URL, optional decision/golden report | registry record or trusted rejection | Ontology |
| 4. Declare import | package id, namespace, exact version, source, digest | `ontologyImports` in SpecGraph project/config | SpecGraph |
| 5. Resolve lock | import declaration and registry/source package | `ontology.lock.yaml` | SpecGraph consumer adapter |
| 6. Validate bindings | SpecGraph artifact `semanticRefs` and ontology IR | `concept-refs.yaml`, `ontology-gaps.yaml` | Ontology compiler invoked by SpecGraph |
| 7. Request delta | one or more `OntologyGap` records | `OntologyDeltaRequest` | SpecGraph |
| 8. Review/govern | candidate ontology delta, validation reports | `OntologyGovernanceDecision` | Ontology governance |
| 9. Update dependency | trusted package version and compatibility report | lockfile update or breaking-change review | SpecGraph |

## Required Artifacts

### `OntologyImport`

SpecGraph must declare exact ontology dependencies before using `semanticRefs`.

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
      digest: sha256:81cbad5a88e7d6f1b0479508e991638b40775b7be3341d0d1c8ada1ed2667a82
```

### `SemanticBinding`

SpecGraph may bind requirements, specs, decisions, evidence expectations, or tests to
imported ontology refs. It must not define new ontology concepts in the binding.

```yaml
apiVersion: specgraph.io/v1alpha1
kind: SemanticBinding
metadata:
  id: sb-REQ-EXAMCALC-001
spec:
  artifact:
    kind: Requirement
    id: REQ-EXAMCALC-001
  semanticRefs:
    - examcalc:Exam
    - examcalc:ExamSession
    - examcalc:ExamPolicyProfile
    - examcalc:CalculatorFunction
    - examcalc:FunctionSet
    - examcalc:StartExamMode
    - examcalc:VerifyDeviceAndPolicy
    - examcalc:LockCalculator
    - examcalc:requires_policy
    - examcalc:allows
    - examcalc:denies
    - examcalc:DenyByDefaultPolicy
    - examcalc:PolicyMustBeSigned
    - examcalc:PolicyMustBeDeviceVerifiable
```

Expected valid output:

- `ConceptRefSet` contains every listed `examcalc:*` ref with canonical ontology id,
  version, namespace, kind, alias, and URI.
- `OntologyLockfile` pins `edu.university.examcalc@0.1.0` with digest and alias map.
- `OntologyGapSet` is empty.

### Missing Concept Example

```yaml
apiVersion: specgraph.io/v1alpha1
kind: Requirement
metadata:
  id: REQ-EXAMCALC-CAS
spec:
  title: CAS function request
  semanticRefs:
    - examcalc:Exam
    - examcalc:ExamPolicyProfile
    - examcalc:CASFunction
```

Expected missing-ref output:

```yaml
apiVersion: specgraph.io/v1alpha1
kind: OntologyGap
metadata:
  id: gap-001
spec:
  sourceArtifact:
    kind: Requirement
    id: REQ-EXAMCALC-CAS
  missingConcept: examcalc:CASFunction
  targetOntology: edu.university.examcalc
  requestedAction:
    type: proposeOntologyDelta
```

SpecGraph must treat this as a follow-up request, not as permission to create
`CASFunction` locally.

## Future SpecGraph-Side Smoke Slice

The next implementation task should live in the SpecGraph repository. It should prove the
consumer path without changing ontology semantics.

Minimum acceptance criteria:

- A SpecGraph fixture declares one ontology import with exact id, namespace, version,
  source, and digest.
- A valid semantic binding fixture resolves through `ontologyc validate-specgraph` and
  stores or checks `ConceptRefSet` and `OntologyLockfile` outputs.
- A missing semantic binding fixture emits an `OntologyGapSet` and does not create a local
  pseudo-concept.
- A lockfile/import mismatch fails validation.
- The fixture references governance/trusted publication evidence when consuming a trusted
  package.
- SpecGraph docs state that `DomainOntologyPackage` schema remains owned by Ontology.
- The smoke can run in CI using checked-in fixtures and without a live HTTP registry.

## Acceptance Criteria

- [x] PRD describes the bridge workflow from ontology import to lockfile, semantic refs,
  gaps, delta request, governance evidence, and publish/pull.
- [x] PRD identifies Ontology-owned and SpecGraph-owned artifacts.
- [x] PRD includes one examcalc-style requirement/binding example and one gap example.
- [x] PRD defines minimum acceptance criteria for a future SpecGraph-side smoke slice.
- [x] PRD explicitly prevents SpecGraph from copying or redefining `DomainOntologyPackage`
  semantics.

## Validation Plan

- `git diff --check`
- Source-alignment grep for required bridge terms:
  - `OntologyImport`
  - `OntologyLockfile`
  - `ConceptRef`
  - `OntologyGap`
  - `OntologyDeltaRequest`
  - `OntologyGovernanceDecision`
  - `DomainOntologyPackage`
- Manual cross-check against `SPECS/Workplan.md` ONT-031 acceptance criteria.

## Risks

| Risk | Mitigation |
|------|------------|
| SpecGraph copies ontology package semantics for convenience | Make the PRD boundary explicit and require fixtures to consume compiler outputs instead. |
| Governance evidence is reduced to digest-only trust | Require decision/golden evidence references for trusted package consumption. |
| Gap handling becomes local pseudo-concept creation | Require `OntologyGap` and `OntologyDeltaRequest` flow before new ontology authority exists. |
| Cross-repo work becomes too large | Keep ONT-031 documentation-only and defer runnable SpecGraph smoke to a separate task. |

## Potential Next Step

Create the SpecGraph-side smoke slice described above, likely as a dedicated SpecGraph PR
that consumes the committed examcalc ontology IR and validates lock/ref/gap behavior in CI.
