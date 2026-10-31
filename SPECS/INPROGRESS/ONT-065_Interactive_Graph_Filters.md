# ONT-065 — Interactive Graph Filters

## Intent

Let a person examine a smaller view of the same ontology without losing their
spatial context. This is a presentation layer over the existing local viewer,
and does not change or approve ontology source files.

## Contract

- Provide independently selectable node types (classes, protocols, policies,
  machines, states), origin (local, imported, unresolved), and edge kinds
  (ontology relation, extends, implements, policy application, lifecycle,
  containment, transition). Class includes imported classes; unresolved
  placeholders keep their expected type and remain separately filterable.
- Offer **Hide** and **Dim** behavior for disabled categories. Hidden elements
  must not remain clickable or keyboard-focusable. Dimmed elements remain visible
  as context. An edge is inactive when its kind or either endpoint is inactive.
- Keep the complete source graph and existing node positions while filtering;
  toggles must not rerun layout, fit the viewport, reset pan/zoom or discard
  manually dragged positions. Showing a node returns it to its previous location.
- Make filtered search behavior and visible/total counts clear. Do not silently
  select an invisible search result; identify a selected element that is filtered.
- Filtering applies to the already loaded projection, not declarations omitted
  by an `ontologyviz` profile. Filter state is session-local in this slice.

## Verification and boundaries

Test the filter classifier and edge endpoint rules, plus real-browser interaction
on a generated projection and live workspace: drag, hide, restore at the same
position, retain viewport, dim and restore, filter relations independently, and
check search/keyboard behavior. Preserve the existing source editor and browser
tests. Cover desktop and narrow layouts. Use the verified TB5 build paths.

This slice does not add graphical source editing, persist display state across
browser restarts, alter CLI profile semantics or integrate SpecSpace.
