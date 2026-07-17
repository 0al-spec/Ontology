# Model Applicability Consumer Roadmap

## Current Contract

Ontology ONT-040 is complete and merged in PR #61. The compiler contract is
additive and inert:

- `DomainOntologyPackage` accepts optional package-level
  `spec.modelApplicability`;
- `ontologyc check` validates applicability scope, assumptions, invalidation
  triggers, and ONT-039 layer values;
- normalized IR preserves authored applicability data;
- compatibility reports classify structural, annotation, and applicability
  changes as review-only evidence.

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

The compiler contract and consumer implementation may be inspected or developed
in parallel. The product-facing consumer release follows the durable-state
production rollout so semantic review work cannot hide unresolved state or
execution durability risks.

## Consumer Acceptance Boundary

- Downstream consumers reuse the compiler vocabulary instead of defining a
  parallel applicability schema.
- Missing applicability remains unknown or not published, not a zero score or
  implicit failure.
- Applicability and change classification remain review-only metadata.
- No consumer may treat the profile as runtime enforcement, ontology write
  authority, term acceptance, candidate approval, or promotion permission.

## Deferred

- SpecGraph `LayeredConceptRef` persistence and validation beyond the first
  consumer slice.
- SpecAuthor prompt behavior that turns applicability into generated authoring
  context.
- Agent Passport behavior-policy extensions.
- SpecSpace acknowledgement or mutation UI.
- Automatic ontology package writes from SpecGraph output.
