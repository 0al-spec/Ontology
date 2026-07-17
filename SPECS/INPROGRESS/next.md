# Near-Term Applicability Roadmap

## ONT-040 — Model Applicability And Structural Change Classification

Status: Complete; merged in PR #61
Branch: `codex/ont-040-model-applicability`
Priority: P1
Dependencies: ONT-039

## Goal

Define the next compiler-side contract after ontology layers: a minimal
`ModelApplicabilityProfile` and review-only structural change classification
that downstream SpecGraph can consume before building stricter validation,
gap, and SpecAuthor write-gate behavior.

The slice should remain compiler-owned and inert. It should not add SpecGraph
runtime behavior, SpecSpace UI, automatic ontology package writes, or runtime
policy enforcement.

## Implementation Summary

- `DomainOntologyPackage` accepts optional package-level `spec.modelApplicability`.
- `ontologyc check` validates applicability scope, assumptions, invalidation
  triggers, and ONT-039 layer values where present.
- normalized IR preserves authored applicability data as inert review metadata.
- compatibility reports now include review-only `changeClassification` buckets:
  `structuralChanges`, `annotationChanges`, and `applicabilityChanges`.
- Existing authority boundaries remain unchanged: no runtime enforcement,
  publication decision, package write, or SpecGraph mutation is introduced.

## Recently Completed

- ONT-038 — SpecGraph Core Ontology Package merged in PR #57 on 2026-06-20.
- ONT-039 — Layered Ontology Model Contract merged in PR #59 on 2026-06-20.
- ONT-040 — Model Applicability And Structural Change Classification merged in
  PR #61 on 2026-06-20.
- SpecGraph has downstream layer consumers for package import, gap/diff review,
  and SpecAuthor layer context.
- SpecSpace has a read-only Ontology Workbench layer lens.

## Cross-Repo Delivery Order

1. Platform and SpecSpace first complete the external durable mutable-state
   backend and its production managed-mode migration/recovery evidence. This is
   operational sequencing, not a dependency of the Ontology compiler contract.
2. SpecGraph imports ONT-040 `modelApplicability` and
   `changeClassification` from compiler normalized IR and compatibility
   reports into package index, gap/diff, candidate overview, and review
   evidence.
3. SpecSpace exposes scopes, assumptions, exclusions, invalidation triggers,
   and classified changes in the Ontology Workbench and Product Workspace as
   read-only review evidence.
4. Feed concrete consumer gaps back into a new Ontology task only when the
   compiler contract lacks required provenance or deterministic structure.

## Consumer Acceptance Boundary

- Downstream consumers reuse the compiler vocabulary instead of defining a
  parallel applicability schema.
- Missing applicability remains unknown/not-published, not a zero score or
  implicit failure.
- Applicability and change classification remain review-only metadata.
- No consumer may treat the profile as runtime enforcement, ontology write
  authority, term acceptance, candidate approval, or promotion permission.

## Deferred

- SpecGraph `LayeredConceptRef` persistence and validation.
- SpecAuthor prompt invocation behavior.
- Agent Passport behavior policy extensions.
- SpecSpace acknowledgement or mutation UI.
- Automatic ontology package writes from SpecGraph supervisor output.
