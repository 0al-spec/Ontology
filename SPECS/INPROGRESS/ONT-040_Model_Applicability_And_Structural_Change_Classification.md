# ONT-040: Model Applicability And Structural Change Classification PRD

**Status:** PRD Ready
**Priority:** P1
**Phase:** Layered Ontology Stack
**Reasoning Effort:** high
**Dependencies:** ONT-039
**Branch:** `codex/ont-040-model-applicability-plan`

## TL;DR

Add a minimal compiler-side contract for model applicability and structural
change classification. Ontology packages should be able to declare the context
where the model applies, the execution assumptions behind that model, and the
events that invalidate it. Compatibility reports should classify obvious
structural ontology changes separately from review-only annotation or data
changes.

This is not a strict formal type system. It is review data for SpecGraph and
SpecSpace so downstream agents know when a concept model is scoped, stale, or
structurally changed.

## Problem

ONT-039 made ontology entries layer-aware, but a layer alone does not say when a
model is valid. A claim can correctly reference a `mechanics` concept while
still applying outside the supported product domain, runtime assumption, or
agent context.

Downstream SpecGraph work needs a small compiler-backed shape for these
questions:

- What bounded context does this package or element apply to?
- Which execution assumptions must hold?
- Which events or environment changes invalidate the model?
- Is a compatibility diff a structural ontology change or only annotation/data
  drift?

Without this contract, downstream consumers must either infer applicability from
prose or treat every ontology change as equally meaningful.

## Goals

1. Define a minimal `ModelApplicabilityProfile` shape for ontology packages.
2. Keep the profile optional so existing packages remain valid.
3. Represent applicability as inert review data:
   - applies-to scopes;
   - exclusions;
   - assumptions;
   - invalidation triggers.
4. Preserve the profile in normalized IR.
5. Extend compatibility reports with deterministic, review-only change
   classification.
6. Add tests covering structural change, annotation/data-only change, and
   applicability-profile mismatch or invalidation-trigger drift.

## Non-Goals

- Runtime policy enforcement.
- SHACL/OWL-level reasoning.
- Required applicability profiles for all packages.
- SpecGraph persistence or write-gate behavior.
- SpecSpace UI changes.
- Automatic ontology package writes or governance decisions.
- Natural-language inference of applicability.

## Proposed Shape

The first version should prefer explicit package-level metadata. Element-level
applicability may follow later if downstream consumers prove they need it.

```yaml
spec:
  modelApplicability:
    appliesTo:
      domains:
        - specgraph_core
      lifecyclePhases:
        - draft_spec_authoring
      agentTypes:
        - SpecAuthorAgent
    excludes:
      domains:
        - unrelated_product_domain
    assumptions:
      - id: human_review_required
        layer: execution
        text: Generated ontology changes require owner review before acceptance.
      - id: project_local_authority
        layer: meta
        text: Project ontology packages remain workspace-owned unless published.
    invalidationTriggers:
      - id: package_layer_contract_changed
        layer: meta
        text: Re-review applicability when the layer vocabulary changes.
```

The compiler should treat these values as structured data. It should validate
shape and layer values where present, but it should not infer missing values.

## Change Classification

Compatibility output should keep existing breaking/compatible semantics, then
add a review-only classification layer where deterministic:

```yaml
changeClassification:
  structuralChanges:
    - kind: relationRangeChanged
      ref: sgcore:definesRequirement
  annotationChanges:
    - kind: layerChanged
      ref: sgcore:Spec
  applicabilityChanges:
    - kind: invalidationTriggerAdded
      ref: modelApplicability.package_layer_contract_changed
```

Definitions for this slice:

- `structuralChange`: a change that alters class presence, relation presence,
  required fields, relation domain/range, or other compiler-visible ontology
  structure.
- `annotationChange`: a change in descriptive metadata that does not alter
  reference resolution or structural relation shape.
- `applicabilityChange`: a change in model scope, assumptions, exclusions, or
  invalidation triggers.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Applicability schema | `SPECS/ontology/domain-ontology-package.schema.yaml` | Optional `modelApplicability` validates shape and layer values. |
| D2 | Compiler loading/validation | `Sources/OntologyCompiler/PackageLoading.swift`, `PackageValidation.swift`, `Sources/OntologyRules/` | Invalid applicability shape produces deterministic diagnostics. |
| D3 | Normalized IR | `Sources/OntologyCompiler/Normalization.swift` | IR preserves applicability data when present. |
| D4 | Compatibility classification | `Sources/OntologyCompiler/Compatibility*.swift` | Reports include review-only structural, annotation, and applicability classifications. |
| D5 | Tests and fixtures | `Tests/OntologyCompilerTests/` | Tests cover one structural change, one annotation/data-only change, and one applicability mismatch. |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-040_Validation_Report.md` | Records local checks and residual risks. |

## Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-001 | `modelApplicability` MUST be optional. | Existing packages and tests pass. |
| FR-002 | Applicability layer fields MUST reuse ONT-039 layer vocabulary. | Invalid-layer test. |
| FR-003 | Normalized IR MUST preserve applicability data exactly enough for downstream consumers. | IR regression test. |
| FR-004 | Compatibility reports MUST classify structural changes separately from annotation/applicability changes where deterministic. | Compatibility tests. |
| FR-005 | Applicability data MUST NOT change package approval, publication authority, or runtime enforcement. | Code review and validation report. |
| FR-006 | The compiler MUST NOT infer applicability from descriptions or free text. | Code review and fixture tests. |

## Implementation Notes

- Prefer additive schema fields and additive report fields.
- Keep older fixtures valid.
- Use existing `OntologyRules` specification/decision-spec style for validation
  and classification.
- Do not make `annotationChange` mean "unimportant"; it only means
  "not structurally changing according to compiler-visible rules."

## Risks

| Risk | Mitigation |
|------|------------|
| Applicability becomes fake precision. | Keep profile optional and require explicit authored values only. |
| Structural classification conflicts with existing compatibility decisions. | Add classification as review data; do not replace existing breaking/compatible result. |
| Downstream consumers treat assumptions as runtime enforcement. | Preserve explicit inert/review-only wording in docs and validation report. |
| Schema grows too broad. | Start package-level only; defer element-level profile until needed. |

## Follow-Ups

- SpecGraph `LayeredConceptRef` and `ModelApplicabilityProfile` import surface.
- SpecGraph SpecAuthor prompt behavior that emits active layer/applicability
  frame before drafting.
- SpecSpace Workbench support for applicability/invalidation review.
- Agent Passport behavioral policy extension once the runtime declaration
  format is ready.
