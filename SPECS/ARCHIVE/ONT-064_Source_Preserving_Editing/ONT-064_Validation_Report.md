# ONT-064 Validation Report

**Date:** 2026-10-31

**Verdict:** PASS locally; hosted CI and independent review are pending.

## Result

The optional loopback workspace shares one explicitly selected YAML source with
the browser and external editors. It invokes the real compiler and visualizer,
keeps the previous graph visibly stale when the source is invalid, and refreshes
after changes to the source or explicitly selected imports. The browser preserves
the selected element, viewport and dragged node positions across graph updates.

The editor changes source text directly rather than serializing a YAML object.
It retains untouched comments, BOM and line endings, detects stale source digests,
and preserves an unsaved draft on external change. A no-op save does not rewrite
the file. Only the selected root package is writable through the local API.

## Checks

- `npm test`: five model/source-text tests PASS, including mixed line endings,
  BOM, comment preservation and projection validation.
- `npm run build`: TypeScript checking and production build PASS.
- `npm run test:e2e`: five Chromium tests PASS using real `ontologyc` and
  `ontologyviz` binaries and disposable YAML/profile copies. They exercise the
  desktop and narrow viewer, exact-byte editing, stale and no-op saves, compiler
  diagnostics and invalid-draft recovery, external edits, selected node/position
  retention, imported-package refresh, transition identity on refresh, and
  token/origin rejection.
- The conflict screenshot was inspected. Build, dependency and browser-test
  artifacts were placed on the verified TB5 volume.
- `node --check workspace.mjs`, workflow YAML parsing and a clean `npm ci`
  against the unchanged lockfile passed. Hosted CI is a separate check.

## Limits

This is a raw source editor; creating declarations on the canvas is not yet
implemented. Atomic rename prevents a partially written file and digest checks
reject stale saves, but there is no filesystem-wide compare-and-swap: an
uncooperative writer may race between the final check and rename. File mode is
preserved; ACLs, extended attributes and hard-link identity are not guaranteed.
The local workspace does not authenticate a person or approve an ontology.
