# ONT-063 Validation Report

**Date:** 2026-10-31

**Verdict:** PASS locally; hosted CI and independent review are pending.

## Result

The standalone React Flow viewer loads `ontology.diagram-projection/v1` JSON,
provides pan, zoom, drag, search and an inspector, and can be used without
SpecSpace or a network after its dependencies are installed. Its adapter and UI
components are exposed at source level for a future host. Imported declarations
and unloaded references remain visibly distinct. Multiple arrows belonging to a
single `oneOf` retain the same semantic record and source pointer.

## Checks

- `npm test`: projection adapter tests PASS, including invalid version,
  malformed alternatives, duplicate records and mismatched source identity.
- `npm run build`: TypeScript strict checking and Vite production build PASS.
- `npm run test:e2e` with the real motivation-core/events-core JSON projection:
  two Chromium tests PASS at desktop and 390 px widths. They exercise file
  loading, node dragging, node/relation search, source inspection, unloaded
  references and preservation of the existing view after invalid input.
- The desktop and mobile screenshots were inspected. Build, dependency and
  browser-test artifacts were placed on the verified TB5 volume.
- The parent ONT-062 full Swift quality gate passed after its BOM and import-order
  fixes; this layer does not modify Swift sources. Hosted UI/Linux checks remain
  pending and are not represented as passed by the local browser test.

## Limits

This is a read-only schema viewer. Dragging changes only display state. It does
not modify YAML, resolve unloaded references, provide runtime instance evidence,
or imply approval of declarations. ONT-064 covers a separate editing layer.
