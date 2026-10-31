# ONT-065 Validation Report

**Date:** 2026-10-31

**Verdict:** PASS locally; hosted CI and independent review are pending.

## Result

The standalone viewer filters loaded nodes by type and origin, and links by
relationship kind. Disabled elements can be hidden or dimmed. Linked edges are
also inactive when either endpoint is inactive. Hidden elements leave the DOM;
dimmed elements remain interactive. Search covers enabled elements, and an
inspector notice identifies a selection outside the filters.

Filtering operates on presentation state. It does not reconstruct the graph,
change YAML or trigger fit/layout; dragged positions and the viewport are kept.
The setting lasts for the lifetime of the page, not across page reloads.

## Checks

- `npm test`: eight unit tests PASS, including independent type/origin
  classification, unloaded placeholders, endpoint and edge-kind filtering, and
  proof the classifier does not mutate the source graph or positions.
- `npm run build`: TypeScript checking and Vite production build PASS.
- `npm run test:e2e`: seven Chromium tests PASS using real `ontologyc` and
  `ontologyviz` binaries, a generated motivation-core/events-core projection,
  and disposable workspace YAML. They cover hide/dim/reset, inactive search and
  inspector state, filtered links and minimap, independent imported/unresolved
  visibility, desktop/390 px controls, and an external source refresh while a
  dragged node is hidden. The tests assert the dragged position after that
  refresh, and both position and viewport during filter toggles.
- The mobile browser screenshot was inspected. Dependencies, build output and
  test artifacts were routed to the verified TB5 volume.
- The configured FLOW `test -f README.md` and `test -f SPECS/Workplan.md` checks
  passed. No Swift sources changed; parent #86's Swift/Linux CI was already green.
  The new branch's hosted checks are a separate, pending result.

## Limits

Filtering applies only to declarations already present in a loaded projection;
it does not restore items omitted by a CLI profile. Individual named relations,
saved filter/layout profiles, graphical ontology editing and SpecSpace
integration remain outside this slice.

## Review follow-up

The filter inspector uses the selected graph node ID, including for search
results, rather than matching a potentially ambiguous label and origin. A real
browser regression selects an unloaded protocol and a same-named unloaded class,
refreshes the source, then filters the two types separately. On the rebased
stack, 12 unit tests, the production build and 15 Chromium tests passed locally.
Hosted CI and review of the updated head remain separate.
