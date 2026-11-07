# ONT-078 validation

**Verdict:** PASS locally; hosted CI and independent review are separate.
**Date:** 2026-11-07

## Checks

- `bash tools/swift-quality.sh`: SwiftFormat, SwiftLint, explicit import
  checking, 58 OntologyRules tests and 193 OntologyCompiler tests pass on
  macOS / Swift 6.4. No Swift source was changed by this UI slice.
- Ontology Viewer: `npm test` passes 40 tests, `npm run build` passes, and
  `npm run test:e2e -- tests/namespace-badge.spec.ts` passes in local Chrome.
  The new test failed first when the card still showed the qualified name.
- In SpecSpace, the same component and scoped CSS were synced from exact
  Ontology commit `195114d8ca32be2c7650bdc4d9c1319104906870`.
  `npm run check:ontology-viewer`, 630 frontend tests, FSD lint and production
  build pass. The existing UI catalog and actual Viewer were exercised at
  390 and 1280 pixels: node text, badge and type-label bounds do not overlap;
  full-ID search and inspection remain intact.
- Ten SpecSpace browser checks pass, including the existing five layout modes,
  action/ref ports, hierarchy arrows and the added badge and missing
  transitive-package scenarios.

## Boundaries

The full identifier and graph topology remain unchanged. Unqualified state
names have no namespace badge. Long badge text is truncated visually with the
full namespace in its title; the inspector retains the complete identifier.
No ontology, project data, release or deployed site was modified. Screenshots
and local browser runs are not evidence of a hosted deployment. Coverage was
not measured; Linux and hosted CI were not run locally.

## CI follow-up

The first hosted browser-smoke run exposed an existing test that searched for
`ext:Shared` as one text node inside a card. The namespace and name are now
separate, so the test selects the class and protocol using their distinct graph
IDs. With the ONT-077 review fix integrated, all 41 Viewer unit tests and all
28 Viewer browser tests pass locally, including the formerly failing scenario.
