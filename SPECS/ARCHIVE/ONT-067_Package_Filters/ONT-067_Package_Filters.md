# ONT-067 — Package filters

## Intent
The NormLab graph combines multiple imported packages. Local/imported filters
cannot expose a chosen package while retaining context from selected others.

## Contract
- Package keys are exact package id/version, independent of namespace aliases.
- Loaded declarations, generated states and edges use source provenance.
  External placeholders use their declared dependency identity. Unattributed
  references remain a separate explicit bucket; do not invent ownership.
- Show loaded packages and declared unloaded dependencies, plus canvas
  node/visual-link counts independent of active filters.
- Nodes require their package/type/origin enabled. Edges require their own
  package/kind and both endpoints enabled.
- Compose with hide/dim, search, inspector and reset. Preserve positions and
  viewport. New package identities default enabled during workspace refresh;
  retained identities keep their choice. Opening a new file resets package choices.
- Only display state changes; no source mutation or package loading.

## Validation
Unit checks cover identity/version/alias independence, generated states,
known/unknown placeholders, edge ownership and counts. Chromium exercises
package hide/dim/reset, search/inspector, relayout avoidance, and refresh.
Build/unit/full existing viewer browser suite on TB5. No Swift source changes.
Open the updated full NormLab snapshot. Deliver as a focused PR above #91.
