# Next Task

## ONT-040 — Model Applicability And Structural Change Classification

Status: Complete
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
- ONT-040 — Model Applicability And Structural Change Classification completed
  locally on 2026-06-20; PR pending.
- SpecGraph has downstream layer consumers for package import, gap/diff review,
  and SpecAuthor layer context.
- SpecSpace has a read-only Ontology Workbench layer lens.

## Suggested Next Steps

- Open and merge the ONT-040 implementation PR.
- Start the downstream SpecGraph slice that imports `modelApplicability` and
  `changeClassification` into package index / gap-diff review artifacts.
- Then expose applicability and invalidation triggers in the SpecSpace
  Ontology Workbench.

## Deferred

- SpecGraph `LayeredConceptRef` persistence and validation.
- SpecAuthor prompt invocation behavior.
- Agent Passport behavior policy extensions.
- SpecSpace acknowledgement or mutation UI.
- Automatic ontology package writes from SpecGraph supervisor output.
