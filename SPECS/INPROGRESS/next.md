# Next Task

## ONT-040 — Model Applicability And Structural Change Classification

Status: PRD Ready
Branch: `codex/ont-040-model-applicability-plan`
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

## Recently Completed

- ONT-038 — SpecGraph Core Ontology Package merged in PR #57 on 2026-06-20.
- ONT-039 — Layered Ontology Model Contract merged in PR #59 on 2026-06-20.
- SpecGraph has downstream layer consumers for package import, gap/diff review,
  and SpecAuthor layer context.
- SpecSpace has a read-only Ontology Workbench layer lens.

## Suggested Next Steps

- Implement
  `SPECS/INPROGRESS/ONT-040_Model_Applicability_And_Structural_Change_Classification.md`.
- Add a minimal `modelApplicability` shape to `DomainOntologyPackage`
  metadata or package spec in a way that stays optional for existing packages.
- Preserve applicability data in normalized IR without changing governance
  authority.
- Extend compatibility reports with review-only `changeClassification` records
  that distinguish structural ontology changes from non-structural data or
  annotation changes where the compiler can do so deterministically.
- Include invalidation triggers and execution assumptions as inert review data.
- Add tests for at least:
  - one data-only or annotation-only change;
  - one structural ontology change;
  - one applicability-profile mismatch or changed invalidation trigger.

## Deferred

- SpecGraph `LayeredConceptRef` persistence and validation.
- SpecAuthor prompt invocation behavior.
- Agent Passport behavior policy extensions.
- SpecSpace acknowledgement or mutation UI.
- Automatic ontology package writes from SpecGraph supervisor output.
