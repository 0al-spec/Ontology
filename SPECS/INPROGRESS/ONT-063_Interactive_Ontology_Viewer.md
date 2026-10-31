# ONT-063 — Standalone Interactive Ontology Viewer

## Intent

Provide a useful browser-based way to explore an ontology without requiring
SpecSpace or an agent. The browser consumes ONT-062's versioned JSON graph;
future contexts can reuse its model and canvas components. Ontology YAML and
the compiler remain independent of the UI.

## Deliverables

- A standalone, locally runnable TypeScript/React viewer with an interactive
  graph, fit/zoom/pan, draggable nodes, search and an inspector.
- A reusable projection adapter and canvas component, preserving identities,
  owning package/source paths, relation metadata and grouped `oneOf` semantics.
- Show unloaded external references as explicit placeholders, not declarations.
  Display class, relation, protocol, policy and lifecycle data where selected.
- Load a local `ontology.diagram-projection/v1` JSON file; reject malformed or
  unsupported documents with actionable errors. The UI is usable without a
  compiler, server-side writes, a network connection or SpecSpace after build.
- Documentation for generating a graph with `ontologyviz`, running the viewer
  and understanding read-only boundaries.

## Acceptance and verification

1. A real `motivation-core` / `events-core` selected projection opens and allows
   navigation and inspection, including imported and unloaded references.
2. A oneOf relation has one semantic identity even if rendered as multiple
   arrows; every visible arrow can reach the same relation inspector.
3. Invalid graph/schema versions are rejected without replacing the current view.
4. A narrow-screen layout retains usable controls and inspector access.
5. Automated model and real-browser smoke checks cover the above. Build and
   dependency outputs follow TB5 rules. Existing Swift quality remains intact.

## Boundaries

This slice edits display state only. It does not mutate YAML, invoke agents,
approve ontology content, automatically resolve unloaded references, or alter
SpecSpace. Source-preserving editing and live shared files are ONT-064.
