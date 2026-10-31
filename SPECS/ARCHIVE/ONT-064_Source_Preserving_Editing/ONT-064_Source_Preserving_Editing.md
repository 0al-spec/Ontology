# ONT-064 — Source-Preserving Ontology Editing

## Intent

Let a person edit the same YAML file an agent can inspect and modify, while
retaining its exact text unless deliberately edited. The standalone viewer is
still independently useful and no SpecSpace service is required.

## Contract

- An optional loopback-only local workspace opens an explicit package/profile,
  reads its existing YAML bytes and uses `ontologyc` and `ontologyviz` to
  report diagnostics and generate the selected graph.
- The browser edits the original source text without serializing the YAML AST.
  Saving preserves comments, formatting, line endings and BOM unless the user
  changed them; unmodified text is never rewritten.
- Compare the file's current byte digest with the last loaded digest before
  saving. A stale save is rejected; external changes refresh a clean buffer and
  leave an unsaved buffer visible for reconciliation. Atomic rename prevents a
  partial file, but an uncooperative external writer can still race between the
  last comparison and rename; do not claim a filesystem-wide atomic CAS.
- Run compiler diagnostics and refresh a validated graph after changes. Invalid
  draft text remains editable and may be saved; retain the last valid graph with
  an explicit stale indication. Unloaded and imported declarations remain honest.
- Bind only to `127.0.0.1`, restrict the service to the chosen source, verify
  request origin and a per-session token, and never offer a shell or arbitrary
  file browsing through the HTTP API.

## Checks and boundaries

Use disposable source/profile copies; cover untouched comments and bytes,
successful saves, stale writes, external edits, invalid drafts and loopback API
checks with real compiler/visualizer binaries and desktop Chromium. The scope is
source-text editing; graphical creation of declarations is a later layer.

## Archive

Implemented and validated locally on 2026-10-31. The validation report records
the tested conflict and filesystem boundaries. Hosted CI and independent review
remain separate; retain the worktree for stack review.
