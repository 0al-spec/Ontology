# ONT-062 — Shared Ontology Graph Projection

## Intent

Build the first bottom-up layer for a future interactive ontology editor in
Ontology itself. A consumer needs the same package declarations and selected
imports that the static visualizer sees, together with their source identities.
The independently useful files, compiler and visualizer remain usable alone.

## Deliverables

- Extract one validated, selected declaration projection consumed by the existing
  DOT renderer and exposed through a public compiler API and `ontologyviz` JSON.
- Version the JSON contract and document its declaration-oriented structure.
  Keep relation ranges, including `oneOf`, as one semantic relation rather than
  inferring independent relationships from drawing edges.
- Associate visible declarations and class fields with package identity, source
  digest and logical JSON pointer into the original YAML document. Make supplied
  import identities/digests explicit without embedding host-specific paths.
- Reuse existing selection, exact import identity checks and saved profiles.
  Unloaded references remain references, not fabricated declarations.
- Preserve existing DOT bytes and SVG/PNG behavior, error handling and input
  overwrite protection. JSON-only output must not require Graphviz.

## Boundaries

This first slice supplies a validated declaration graph, not an editor or a
round-trip YAML writer. It does not claim source line/column positions, runtime
instance evidence, ontological truth or validation of manual policies. A consumer
must map declared import identities to its own local paths and may construct
presentation nodes and edges from the documented declarations.

## Acceptance and validation

1. Use the real motivation-core/events-core profile; verify root/imported sources,
   selected declarations and relations, and declaration and field pointers.
2. Verify oneOf remains grouped, selected import aliases retain the owning
   package identity, imports and selectors are order-independent, and unloaded
   references do not become definitions.
3. Check invalid input and wrong import identity fail, JSON cannot overwrite a
   package/profile, and JSON export works without Graphviz in `PATH`.
4. Existing default and saved-profile DOT golden output remains byte-identical;
   run repository Swift quality checks and relevant real rendering tests.
5. Publish a focused PR and retain this task worktree through review.

---
**Archived:** 2026-10-31
**Verdict:** PASS locally; hosted review and CI pending.
