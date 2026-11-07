# ONT-077 — Explicit Transitive Diagram Imports

## Intent and source

The operator approved improving SpecGraph's composed ontology view without
forcing a root package to claim its dependencies' dependencies as direct
imports. In the reproduced SG-SPEC-0051 path, root A imports proposal B, and B
imports core C. Ontology 0.8.0 checks A but `ontologyviz --view full --import B`
fails to bind B's reference to C unless A also declares C. Supplying C with
`--import` alone is rejected as not directly imported by A.

## Outcome and boundary

Make explicitly supplied reachable transitive packages usable by the diagram
projection, while keeping declaration identity and version exact. No automatic
network, registry, directory search, package publication or canonical ontology
acceptance is introduced. This task changes the projection/viewer, not the
standalone compiler's external symbol-verification guarantee.

## Contract

1. Each `--import` remains an explicitly supplied local package. It may be a
   direct dependency or reachable through supplied dependency packages. Reject
   unreachable supplied identities and duplicate/conflicting supplied copies;
   exact declared package ID and version determine reachability.
2. Resolve a reference in the declaring package's own namespace bindings.
   Rebase for the flattened diagram using deterministic collision-safe aliases
   keyed by package identity and version. Preserve old root/direct aliases and
   original declaration source identities, pointers and byte digests.
3. Root `imports` remain its actual declared direct imports. Do not infer root
   dependencies from child declarations. Loaded sources remain explicit.
4. If a transitive dependency is not supplied, preserve its identity/version in
   an explicitly labelled external binding and render a placeholder; do not
   claim the referenced declaration exists. Do not silently bind equal aliases
   from different package scopes or versions. Reject ambiguous inputs where an
   exact binding cannot be established.
5. Keep full and selected relations views, JSON/DOT agreement, deterministic
   import ordering and legacy output unchanged when this feature is not used.
   Preserve the existing root/direct scope protection and source overwrite guard.
6. Document the additive projection metadata and display unloaded transitive
   package identity in the standalone Viewer. Existing v1 consumers must still
   parse the resulting projection; no SpecSpace deployment is part of this task.

## Validation

- Test A → B → C with C supplied, with C omitted, and with an unrelated file.
- Test aliases reused by different packages, same ID with different versions,
  duplicate/conflicting source inputs, diamond dependencies and cycles.
- Check preserved direct import byte baselines and import order determinism.
- Verify DOT/JSON targets and metadata; assert unloaded does not mean verified.
- Run compiler/rule/CLI regression tests and the Swift quality gate with Graphviz;
  verify the current Viewer accepts and displays the generated projection.
- Reproduce the SpecGraph candidate without modifying its root imports; retain
  exact local input provenance and distinguish this from a deployed version.

## Non-goals

Resolving remote registries, silently supplying missing packages, changing
ontology truth/authority, automatically approving terms, migrating SpecGraph
pins, or publishing a release.

---
**Archived:** 2026-11-07
**Verdict:** PASS (local; hosted CI and review are separate)
