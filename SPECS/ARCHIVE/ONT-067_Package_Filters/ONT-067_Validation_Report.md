# ONT-067 validation

Date: 2026-10-31.
Verdict: PASS locally; hosted CI and independent review pending.

- Production TypeScript checking and Vite build passed.
- All 17 viewer unit tests passed. Package regressions cover source-based state
  ownership, alias-independent identity, two versions, unloaded/unattributed
  references, zero-count declared dependencies, owned-edge filtering and
  default-enabled newly appearing identities.
- All 18 Chromium scenarios passed with the real ONT-066 compiler/visualizer.
  Added browser cases exercise file-open reset, package hide/dim/reset,
  search/inspector, fixed counts, viewport/position preservation and retained
  choice after source refresh.
- NormLab full preview: disabling events-core leaves 72/104 nodes and 188/287
  links active. Its other packages remain enabled. Browser screenshot retained
  locally with the pilot data. NormLab sources were not edited.
- Git diff whitespace check passed. Artifacts/cache stayed on verified TB5.
- Swift production sources are unchanged relative to parent PR #91; this slice
  did not repeat its Swift quality suite. CI remains an independent result.

Counts are presentation counts, not a completeness/truth score. Only package
id/version selects ownership; source digests remain provenance, not a separate
filter dimension. No package fetch, source edit, saved preference profile or
performance/coverage claim is introduced.
